# 接続・方言・トレース

| 項目 | 内容 |
|---|---|
| ID | data-3 |
| 分類 | data |
| 関連 | data-1(Smart.Data.Accessor) / data-2(2-way SQL) / config-2(設定バインド) / log-5(SQL トレースのトグル) / telemetry-1(OpenTelemetry) / guideline-1(結果による通知) |

## 目的

DB 接続の生成・DB 方言差の吸収・SQL トレースを **DI 境界(`IDbProvider` / `IDialect`)に集約**し、業務コードから接続文字列とプロバイダ差異を隔離する。

- 接続の生成は `DelegateDbProvider` の1箇所に閉じ、業務コードは接続を意識しない
- 重複キー判定・LIKE エスケープ等の方言差は `DelegateDialect` に閉じる
- SQL トレースは設定トグルで接続ラップの有無を切り替え、業務コードを変えずに ON/OFF する

## 標準形

### 接続 — DelegateDbProvider

接続ファクトリを `IDbProvider` として Singleton 登録する。接続文字列は appsettings の `ConnectionStrings` から取得する(値はダミー)。

```csharp
// Data
var connectionString = builder.Configuration.GetConnectionString("Default");
builder.Services.AddSingleton<IDbProvider>(new DelegateDbProvider(() => new SqliteConnection(connectionString)));
builder.Services.AddDataAccessors(typeof(DataAccessor).Assembly);
```

### 方言 — DelegateDialect

プロバイダ固有の例外判定(重複キー)と LIKE エスケープを `IDialect` に閉じる。

```csharp
builder.Services.AddSingleton<IDialect>(new DelegateDialect(
    static ex => ex is SqliteException { SqliteErrorCode: 19 } or SqliteException { SqliteExtendedErrorCode: 1555 or 2067 },
    static x => Regex.Replace(x, "[%_]", "[$0]")));
```

利用側の Service は `DbException` を受けて `IsDuplicate` で判定し、**例外ではなく結果で通知する**(guideline-1)。プロバイダ固有の例外型は Service に現れない。

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
            // 重複は結果(null)で通知する
            return null;
        }

        throw;
    }
}
```

### SQL トレース — MiniDataProfiler

`SqlTrace` トグル(log-5)が ON の時のみ `ProfileDbConnection` で接続をラップする。リスナーはログ出力と OpenTelemetry の二重掛け。

```csharp
builder.Services.AddSingleton<IDbProvider>(static p =>
{
    var configuration = p.GetRequiredService<IConfiguration>();
    var connectionString = configuration.GetConnectionString("Default");

    var setting = p.GetRequiredService<ProfilerSetting>();
    if (setting.SqlTrace)
    {
        var logListener = new LoggingListener(p.GetRequiredService<ILogger<LoggingListener>>(), new LoggingListenerOption());
        var telemetryListener = new OpenTelemetryListener(new OpenTelemetryListenerOption());
        var listener = new ChainListener(logListener, telemetryListener);
        return new DelegateDbProvider(() => new ProfileDbConnection(listener, new SqliteConnection(connectionString)));
    }

    return new DelegateDbProvider(() => new SqliteConnection(connectionString));
});
```

OpenTelemetry 側はトレース構成に `AddMiniDataProfilerInstrumentation()` を追加する(telemetry-1)。

### TypeMap 調整

DB とドライバの既定マッピングが合わない場合は調整を掛ける。旧世代(2.x)は登録時の `EngineOption` で一括構成する(3.x 系は `[TypeMap]` / `[TypeHandler]` 属性による宣言に移行)。

```csharp
// 2.x の構成例
builder.Services.AddDataAccessor(static c =>
{
    c.EngineOption.ConfigureTypeMap(static map =>
    {
        map[typeof(DateTime)] = DbType.DateTime2;
    });
});
```

代表的な調整:

| 調整 | 目的 |
|---|---|
| `AnsiString` | char / varchar 列に NVARCHAR 変換(暗黙変換によるインデックス不使用)を避ける |
| `DateTime2` | SQL Server の datetime2 列に合わせる |
| StringBool | `'1'` / `'0'` 文字列列と bool の相互変換 |

## 配置ルール

| 対象 | 場所 |
|---|---|
| `IDbProvider` / `IDialect` / `AddDataAccessors` の登録 | `ApplicationExtensions` の Components 構成(host-1 / host-4)の Data 節 |
| 接続文字列 | appsettings の `ConnectionStrings`(コードにハードコードしない) |
| `ProfilerSetting`(SqlTrace トグル) | `Settings/`(config-4)。`Profiler` セクションからバインド(config-2) |

## バリエーションと使い分け

- **SQLite(開発・小規模)**: 接続文字列は `SqliteConnectionStringBuilder` で組み立ててよい(`Pooling = true`、`Cache = SqliteCacheMode.Shared`)
- **SQL Server**: `SqlConnection` + `DateTime2` の TypeMap 調整を基本セットとする
- **組込みクライアント(MAUI 等)の軽量 ORM 直叩き**: `SqlMapperConfig.Default.ConfigureTypeHandlers` で TypeHandler(Guid → 文字列、DateTime → Ticks 等)を差し替える同型の調整を行う

## アンチパターン

- 業務コードでの `new SqliteConnection(...)` — 接続の生成は `IDbProvider` に閉じる
- Service でプロバイダ例外型(`SqliteException` 等)を直接判定する — 判定は `IDialect` に隔離し、Service は `DbException` + `IsDuplicate` で書く
- 重複キーを事前 SELECT で回避する — 一意制約違反はランタイムでしか検出できない代表例であり、catch + 結果通知で扱う(guideline-1)
- トレース用の接続ラップを業務コード側で分岐する — トグル判定は `IDbProvider` の登録箇所1箇所に閉じる
- 接続文字列・認証情報のハードコード — 設定(および環境変数)から取得する
