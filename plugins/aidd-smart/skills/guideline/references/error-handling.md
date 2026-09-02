# エラー処理方針

| 項目 | 内容 |
|---|---|
| ID | guideline-1 |
| 分類 | guideline |
| 関連 | web-6(エラー応答・ProblemDetails) / structure-4(CA1031 の局所抑止) / guideline-2(非同期作法) / worker-1(Batch の共通骨格) |

## 目的

**「どこで例外を捕捉するか」を層ごとに固定し、個別の try/catch を書く判断を各所に委ねない**。

- アプリ層の異常系は例外に頼らず結果で通知し、例外を制御フローに使わない
- 予期せぬ例外は各所で握らず **Fail-fast** — グローバルに1箇所で処理し、中途半端な状態で続行させない
- 「握ってよい例外」「握ってはならない例外」の基準を明文化し、防御的な catch の散在を防ぐ

## 原則

| # | 原則 |
|---|---|
| 1 | 発生が予期できる異常は**例外ではなく結果で通知する**(専用型 / タプル / nullable) |
| 2 | 発生が予期できるものは**例外を出さない書き方にする**(`Parse` ではなく `TryParse` 等) |
| 3 | 予期せぬ例外は各所で握らず **Fail-fast** — グローバルに処理し続行させない |
| 4 | 個別 try/catch を書いてよいのは、**ランタイムでしか検出できずライブラリが例外で通知するもののみ**(DB 一意制約違反、外部 I/O タイムアウト等) |
| 5 | 意図的な握りつぶし(ログのみで継続)には `#pragma warning disable CA1031` を明示する(structure-4) |
| 6 | 再スローは `throw;`(`throw ex;` 禁止)でスタックトレースを保つ |

## 標準形

### 予期できる異常は結果で通知する

業務上起こり得る異常(未存在・重複・検証エラー等)は例外ではなく戻り値で表現する。結果の形は状況に応じて選ぶ。

| 形 | 使いどころ | 例 |
|---|---|---|
| nullable | 成功/失敗の2値で、失敗理由が1つ | `ValueTask<long?> InsertAsync(...)` |
| bool | 副作用の成否のみ | `ValueTask<bool> DeleteAsync(...)` |
| 専用 enum | 失敗理由が複数 | `ValueTask<DataWriteStatus> UpdateAsync(...)` |
| タプル | 成否 + 値の組(局所的な用途) | `(bool Success, int Value)` |
| record(専用型) | 呼び出し側に複数の値を返す | `PagedResult<T>(Total, Page, Size, Items)` |

```csharp
public enum DataWriteStatus
{
    Success,
    NotFound,
    Duplicate
}
```

呼び出し側(API ハンドラ)は結果を分岐して `IResult` に変換する(web-6)。例外は関与しない。

```csharp
// ✅ 良い例: Service は結果を返し、ハンドラは分岐して応答に変換する
private static async ValueTask<IResult> HandleUpdateAsync(
    DataService dataService,
    long id,
    DataUpdateRequest request)
{
    var result = await dataService.UpdateAsync(id, request.Name, request.Value);
    return result switch
    {
        DataWriteStatus.Success => TypedResults.NoContent(),
        DataWriteStatus.NotFound => TypedResults.NotFound(),
        _ => TypedResults.Problem(statusCode: StatusCodes.Status409Conflict, title: "Duplicate name.")
    };
}
```

```csharp
// ❌ 悪い例: 業務上の異常を例外で通知し、呼び出し側の catch を制御フローにする
public async ValueTask UpdateAsync(long id, string name, int value)
{
    var rows = await dataAccessor.UpdateAsync(id, name, value);
    if (rows == 0)
    {
        throw new DataNotFoundException(id);    // 予期できる異常は例外にしない
    }
}
```

### 例外を出さない書き方を選ぶ

失敗が予期できる操作には、例外を投げない Try 形式の API を使う。catch で受けてから分岐するのは例外の制御フロー化であり禁止。

```csharp
// ✅ 良い例
if (!Int32.TryParse(input, out var value))
{
    return ValidationResult.Invalid;
}
```

```csharp
// ❌ 悪い例: 例外を制御フローに使っている
try
{
    var value = Int32.Parse(input);
}
catch (FormatException)
{
    return ValidationResult.Invalid;
}
```

同様に、辞書は `TryGetValue`、ファイル存在は事前判定より open の失敗を「ランタイム検出のみ」(後述)として扱う、など**例外に到達しない経路を優先する**。

### 予期せぬ例外はグローバルに処理する(Fail-fast)

予期せぬ例外(バグ・環境異常)は各所で握らない。処理の種類ごとにグローバルな捕捉点を1つだけ置く。

**API サーバ** — `AddProblemDetails()` + `UseExceptionHandler()` で RFC 7807 応答に集約する(web-6)。ハンドラ・Service には catch を書かない。

```csharp
builder.Services.AddProblemDetails();
...
app.UseExceptionHandler();
```

**常駐処理(Worker / 監視ループ)** — 件単位で捕捉してログ+継続し、サービス全体を落とさない。意図的な握りつぶしのため `CA1031` の局所抑止を明示する(structure-4)。

```csharp
protected override async Task ExecuteAsync(CancellationToken stoppingToken)
{
#pragma warning disable CA1031
    try
    {
        await action.ExecuteAsync(arguments.GetParameters(), stoppingToken);
    }
    catch (Exception ex)
    {
        log.ErrorActionFailed(ex, arguments.Name);
        Environment.ExitCode = -1;
    }
    finally
    {
        lifetime.StopApplication();
    }
#pragma warning restore CA1031
}
```

**継続不能な異常**(初期化失敗・回復不能な環境異常)は捕捉せずプロセスを落とし、再起動に任せる。サービス定義側の `Restart=always`(deploy-2)が受け皿であり、アプリ内でのリトライ・自己修復を作り込まない。

### ランタイムでしか検出できない例外は境界で結果に変換する

個別 try/catch を書いてよい唯一のケース。事前判定が不可能で、ライブラリが例外で通知するもの(DB 一意制約違反、外部 I/O タイムアウト等)は、**発生箇所に最も近い境界で捕捉して結果に変換する**。上位層には例外を漏らさない。

```csharp
public async ValueTask<long?> InsertAsync(string name, int value)
{
    try
    {
        return await dataAccessor.InsertAsync(name, value, timeProvider.GetLocalNow().DateTime);
    }
    catch (DbException ex)
    {
        if (dialect.IsDuplicate(ex))
        {
            return null;    // 一意制約違反は「予期できる結果」に変換する
        }

        throw;              // それ以外は予期せぬ例外 — 握らず再スロー
    }
}
```

このとき捕捉するのは**特定の例外型のみ**とし、想定外(ここでは重複以外の `DbException`)は必ず再スローしてグローバル処理(Fail-fast)に委ねる。

### 再スローは `throw;` で行う

```csharp
// ✅ 良い例: スタックトレースを保つ
catch (DbException ex)
{
    log.ErrorQueryFailed(ex);
    throw;
}
```

```csharp
// ❌ 悪い例: スタックトレースが捕捉地点で切れる
catch (DbException ex)
{
    log.ErrorQueryFailed(ex);
    throw ex;
}
```

## アンチパターン

- **例外の制御フロー化** — `Parse` + catch、未存在チェックを例外で受ける等。Try 形式・結果通知に置き換える
- **防御的 catch の散在** — 「念のため」の `catch (Exception)` を各層に書く。予期せぬ例外の捕捉点はグローバルの1箇所のみ
- **例外のラップ再送(例外ラダー)** — 各層で catch して独自例外に詰め替えて再スロー。層をまたぐたびに情報が薄まりスタックトレースが分断される。予期できるものは結果に変換し、それ以外は素通しする
- **暗黙の握りつぶし** — 空 catch、ログなし継続、`CA1031` 抑止の省略。握りつぶしは「意図的である」ことを pragma + ログで可視化する(structure-4)
- **`throw ex;`** — スタックトレースが失われる。再スローは常に `throw;`
- **アプリ内リトライ・自己修復の作り込み** — 継続不能な異常はプロセスを落とし、サービス基盤の再起動(deploy-2)に任せる
- **業務例外階層の構築** — `XxxBusinessException` 系の型階層を設けて上位で catch 分岐する設計。結果型で表現すれば例外は不要になる
