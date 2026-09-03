# 非同期作法

| 項目 | 内容 |
|---|---|
| ID | guideline-2 |
| 分類 | guideline |
| 関連 | structure-4(CA2007 の層別方針) / guideline-1(エラー処理方針) / deploy-2(graceful shutdown) |

## 目的

**I/O は非同期を基本とし、UI スレッド / リクエストスレッドをブロックしない**。非同期コードの書き方を統一し、スレッドプール枯渇・デッドロック・キャンセル不能という3つの事故を構造的に防ぐ。

## 原則

| # | 原則 |
|---|---|
| 1 | **`Task.Wait()` / `Task.Result` / `GetAwaiter().GetResult()` を使わない**(sync over async 禁止) |
| 2 | **`async void` 禁止**(イベントハンドラを除く) |
| 3 | **`CancellationToken` を末端まで伝播**し、graceful shutdown に応える |
| 4 | 戻り値はフレームワークが `Task` を要求する箇所以外、**`ValueTask` を基本とする** |
| 5 | **`ConfigureAwait(false)` はライブラリ層のみ**。アプリ層は付けない(structure-4) |
| 6 | 自前の `Task.Run` は CPU バウンドの明示的オフロード等、根拠がある場合のみ |
| 7 | `Thread.Sleep` ではなく `Task.Delay`、周期実行は `PeriodicTimer` |
| 8 | 非同期初期化はコンストラクタで行わず、静的ファクトリ / 明示的 `InitializeAsync` で行う |

## 標準形

### sync over async 禁止

非同期メソッドの結果を同期的に待つと、スレッドプール枯渇・デッドロックの温床になる。呼び出し経路全体を async にする(async all the way)。

```csharp
// ✅ 良い例: 末端まで async
public async ValueTask<DataEntity?> QueryAsync(long id, CancellationToken cancellationToken) =>
    await dataAccessor.QueryAsync(id, cancellationToken);
```

```csharp
// ❌ 悪い例: sync over async
public DataEntity? Query(long id) =>
    dataAccessor.QueryAsync(id, default).AsTask().Result;                  // 禁止

public DataEntity? Query2(long id) =>
    dataAccessor.QueryAsync(id, default).GetAwaiter().GetResult();         // 禁止(例外が展開されるだけで本質は同じ)
```

同期 API しか持てない箇所(レガシー interface 実装等)に突き当たった場合は、interface 側を非同期化するのが正であり、ブリッジを書いて許容しない。

### async void 禁止

`async void` は例外が捕捉不能(プロセスをクラッシュさせる)で、完了も待てない。許されるのはイベントハンドラのみ。

```csharp
// ✅ 許容: イベントハンドラのみ
private async void OnClicked(object sender, EventArgs e)
{
    await viewModel.RefreshAsync();
}
```

```csharp
// ❌ 悪い例: Timer コールバックを async void にする
timer = new Timer(async void (_) => await ProcessAsync(), null, 0, 1000);
```

Timer コールバックも不可 — `Task` 返却メソッドにして結果を破棄する形にするか、`PeriodicTimer`(後述)のループに置き換える。

```csharp
// ✅ 良い例: Task 返却メソッドにして破棄を明示
timer = new Timer(_ => _ = ProcessAsync(), null, 0, 1000);

private async Task ProcessAsync()
{
    ...
}
```

### CancellationToken を末端まで伝播する

Host からの停止要求(`stoppingToken`)・リクエスト中断は、I/O の末端まで `CancellationToken` を渡して初めて機能する。途中で伝播を切ると graceful shutdown(deploy-2 の `KillSignal=SIGINT`)に応答できない。

```csharp
// ✅ 良い例: BackgroundService → Action → Accessor まで一気通貫
public interface IAction
{
    string Name { get; }

    ValueTask ExecuteAsync(string[] args, CancellationToken cancellationToken);
}

protected override async Task ExecuteAsync(CancellationToken stoppingToken)
{
    await action.ExecuteAsync(arguments.GetParameters(), stoppingToken);
}
```

```csharp
// ❌ 悪い例: 途中で default を渡して伝播を切る
public async ValueTask ExecuteAsync(string[] args, CancellationToken cancellationToken)
{
    await accessor.ProcessAsync(args, default);    // 停止要求が届かない
}
```

- 非同期メソッドは末尾引数に `CancellationToken cancellationToken` を取る(公開 API では既定値なし。呼び忘れをコンパイルエラーにする)
- キャンセルは例外(`OperationCanceledException`)で伝わってよい。停止要求時の中断は異常ではないため、グローバル側で静かに終息させる

### 戻り値は ValueTask を基本とする

フレームワークが `Task` を要求する箇所(`BackgroundService.ExecuteAsync`、イベント購読等)を除き、`ValueTask` / `ValueTask<T>` を基本とする(data-1 のアクセサ戻り値と同一方針)。

```csharp
// ✅ Service / Usecase / Action の標準形
public async ValueTask<PagedResult<DataEntity>> QueryPageAsync(string? name, int page, int size, CancellationToken cancellationToken)
```

`ValueTask` は**一度しか await しない**・`.Result` を読まない、という制約を守る(守れない箇所は `AsTask()` するのではなく設計を見直す)。

### ConfigureAwait(false) はライブラリ層のみ

`ConfigureAwait(false)` の要否は**アセンブリの層で決まる**(structure-4 の CA2007 層別方針)。

| 層 | 方針 | CA2007 |
|---|---|---|
| アプリ層(ホスト・Core) | 付けない(SynchronizationContext を持たないため意味をなさない) | GlobalSuppressions.cs で抑止 |
| 汎用ライブラリ(共通サービス用 DLL) | **全 await に付ける** | 抑止しない(検査させる) |

```csharp
// ✅ アプリ層: 付けない
var entity = await dataAccessor.QueryAsync(id, cancellationToken);
```

```csharp
// ✅ ライブラリ層: 必ず付ける
var response = await client.SendAsync(request, cancellationToken).ConfigureAwait(false);
```

判断を個々の await に委ねず、プロジェクト単位で機械的に統一する。アプリ層に `ConfigureAwait(false)` が混ざるのも、ライブラリ層で省略されるのも、どちらも誤り。

### Task.Run・待機・周期実行

- **自前の `Task.Run` は根拠がある場合のみ** — CPU バウンド処理をリクエストスレッド / UI スレッドから明示的にオフロードするケース等。I/O を `Task.Run` で包むのは無意味(スレッドを1本浪費するだけ)
- **`Thread.Sleep` ではなく `Task.Delay`** — 待機中にスレッドを解放し、`CancellationToken` で中断できる
- **周期実行は `PeriodicTimer`** — コールバック型 Timer と違い async ループで書け、再入(前回実行中の再発火)が構造的に起きない

```csharp
// ✅ 良い例: PeriodicTimer による周期実行
protected override async Task ExecuteAsync(CancellationToken stoppingToken)
{
    using var timer = new PeriodicTimer(TimeSpan.FromSeconds(10));
    while (await timer.WaitForNextTickAsync(stoppingToken))
    {
        await ProcessAsync(stoppingToken);
    }
}
```

### TaskCompletionSource とタイムアウト

`TaskCompletionSource` は必ず `RunContinuationsAsynchronously` を指定する。指定しないと `SetResult` 呼び出しスレッド上で継続が同期実行され、デッドロックの原因になる。

```csharp
var tcs = new TaskCompletionSource<Response>(TaskCreationOptions.RunContinuationsAsynchronously);
```

タイムアウト用の `CancellationTokenSource` は必ず破棄する(破棄しないと Timer がリークする)。

```csharp
using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
cts.CancelAfter(TimeSpan.FromSeconds(30));
await client.SendAsync(request, cts.Token);
```

.NET 6+ では `WaitAsync` によるタイムアウト付き待機も可。

```csharp
await tcs.Task.WaitAsync(TimeSpan.FromSeconds(30), cancellationToken);
```

### 非同期初期化はコンストラクタで行わない

コンストラクタは await できないため、sync over async か未初期化状態の公開のどちらかに陥る。静的ファクトリ、または明示的な `InitializeAsync` に分離する。

```csharp
// ✅ 良い例: 静的ファクトリ
public sealed class CacheProvider
{
    private readonly Dictionary<string, Entry> entries;

    private CacheProvider(Dictionary<string, Entry> entries)
    {
        this.entries = entries;
    }

    public static async ValueTask<CacheProvider> CreateAsync(DataAccessor accessor, CancellationToken cancellationToken)
    {
        var entries = await accessor.QueryEntriesAsync(cancellationToken);
        return new CacheProvider(entries.ToDictionary(static x => x.Key));
    }
}
```

```csharp
// ❌ 悪い例: コンストラクタ内で sync over async
public CacheProvider(DataAccessor accessor)
{
    entries = accessor.QueryEntriesAsync(default).AsTask().Result;
}
```

DI 管理のサービスであれば、`IHostedService` / `IMauiInitializeService` 等の起動フックで初期化するのも可。

## アンチパターン

- **`Task.Wait()` / `Task.Result` / `GetAwaiter().GetResult()`** — sync over async。スレッドプール枯渇・デッドロックの温床
- **`async void`(イベントハンドラ以外)** — 例外が捕捉できずプロセスが落ちる。Timer コールバックも不可
- **`CancellationToken` の伝播切れ** — 途中で `default` / `CancellationToken.None` を渡す。graceful shutdown に応答できなくなる
- **fire-and-forget の暗黙化** — `_ =` なしで `ValueTask` / `Task` を捨てる(CS4014 / CA2012)。破棄する場合は `_ =` で意図を明示し、例外の行き先(ログ)を確保する
- **I/O の `Task.Run` ラップ** — 非同期 API があるのにスレッドを1本潰して包む。「async 風」になるだけで何も改善しない
- **`Thread.Sleep` / コールバック型 Timer の周期実行** — `Task.Delay` / `PeriodicTimer` に置き換える
- **アプリ層への `ConfigureAwait(false)` の混入** — 層別方針(structure-4)に反する。機械的な一括付与・一括省略をプロジェクト単位で保つ
- **タイムアウト用 CancellationTokenSource の破棄漏れ** — Timer リーク。`using` で確実に破棄する
- **コンストラクタでの非同期初期化** — 静的ファクトリ / 明示的 Initialize / 起動フックに分離する

## 参考

- [AsyncGuidance (davidfowl/AspNetCoreDiagnosticScenarios)](https://github.com/davidfowl/AspNetCoreDiagnosticScenarios/blob/master/AsyncGuidance.md)
