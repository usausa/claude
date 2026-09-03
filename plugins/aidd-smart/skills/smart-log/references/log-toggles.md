# ログ4系統の個別トグル

| 項目 | 内容 |
|---|---|
| ID | log-5 |
| 分類 | log |
| 関連 | log-2(Serilog の構成方法) / config-1(命名と2系統) / config-2(バインドの定型) / config-3(ネスト設定) / data-3(接続・方言・トレース) |

## 目的

調査用の冗長ログ4系統(**W3C アクセスログ / HTTP ログ / Invoke トレース / SQL トレース**)を、設定ファイルの bool で**個別に ON/OFF** できるようにする。

- 本番は常時 OFF とし、障害調査時に「設定変更 + 再起動」だけで有効化できる(再ビルド・再発行が不要)
- Serilog の `MinimumLevel` とは独立させる。レベル調整ではなく、ミドルウェア・リスナーの登録自体を切り替える

## 標準形

appsettings の `Log` セクションに bool を並べ、`LogSetting` にバインドする(config-2 パターン①)。

```json
"Log": {
  "W3CLog": false,
  "HttpLog": false,
  "InvokeTrace": false,
  "SqlTrace": false
}
```

```csharp
namespace Template.Host.Settings;

public sealed class LogSetting
{
    public bool W3CLog { get; set; }

    public bool HttpLog { get; set; }

    public bool InvokeTrace { get; set; }

    public bool SqlTrace { get; set; }
}
```

### 消費側 — 登録の条件分岐

各トグルは、ミドルウェア登録やコンポーネント構築の条件分岐で消費する。

| 系統 | 内容 | 消費箇所 |
|---|---|---|
| W3C アクセスログ | W3CLogger によるアクセスログ | `UseW3CLogging()` |
| HTTP ログ | HttpLogging ミドルウェア | `UseHttpLogging()` |
| Invoke トレース | アクション / メソッド呼び出しの時間計測フィルタ | フィルタ登録(TimeLogging 等) |
| SQL トレース | MiniDataProfiler による SQL ログ | `IDbProvider` の構築(data-3) |

```csharp
public static WebApplication UseLogging(this WebApplication app)
{
    var setting = app.Services.GetRequiredService<LogSetting>();

    if (setting.W3CLog)
    {
        app.UseW3CLogging();
    }

    if (setting.HttpLog)
    {
        app.UseHttpLogging();
    }

    return app;
}
```

SQL トレースは接続ファクトリの構築時に分岐する(data-3)。

```csharp
builder.Services.AddSingleton<IDbProvider>(static p =>
{
    var configuration = p.GetRequiredService<IConfiguration>();
    var connectionString = configuration.GetConnectionString("Default");

    var setting = p.GetRequiredService<LogSetting>();
    if (setting.SqlTrace)
    {
        var listener = new LoggingListener(p.GetRequiredService<ILogger<LoggingListener>>(), new LoggingListenerOption());
        return new DelegateDbProvider(() => new ProfileDbConnection(listener, new SqliteConnection(connectionString)));
    }

    return new DelegateDbProvider(() => new SqliteConnection(connectionString));
});
```

### 入れ子 Entry — パラメータ付きのトグル

閾値等のパラメータを持つ系統は、bool ではなく入れ子の `~Entry`(config-3)にする。

```json
"Log": {
  "HttpLog": false,
  "InvokeTrace": {
    "Enable": false,
    "Threshold": 10000
  }
}
```

```csharp
public sealed class LogSetting
{
    public bool HttpLog { get; set; }

    [Required]
    public InvokeTraceEntry InvokeTrace { get; set; } = default!;

    public sealed class InvokeTraceEntry
    {
        public bool Enable { get; set; }

        [Range(0, Int32.MaxValue)]
        public int Threshold { get; set; }
    }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| `LogSetting` | `Settings/LogSetting.cs`(config-4) |
| バインド | config-2 パターン①(`AddOptions` + `Value` の Singleton 登録) |
| セクション | appsettings の `Log`(`Serilog` セクションとは別) |

## バリエーションと使い分け

- **使う系統だけ定義する** — TCP サーバに W3C アクセスログは存在しない。プロジェクトが持つ系統のみを `LogSetting` に持たせる(bool 1個でも同じ形とする)
- **SqlTrace を `Profiler` セクションに分ける構成** — プロファイリング全般の設定(`ProfilerSetting`)と同居させる例もある。系統が少ないうちは `Log` セクションへの集約を基本とする
- **開発環境での既定 ON** — `appsettings.Development.json` で該当 bool を `true` に上書きし、開発時は常時トレースを見る

## アンチパターン

- **`MinimumLevel` での代用** — カテゴリレベルを下げてもミドルウェア・リスナーの登録コストは消えず、W3C / SQL トレースはそもそも Serilog のレベルと独立している。登録自体をトグルで切る
- **`#if DEBUG` での切り替え** — 本番バイナリで調査ログを有効化できず、トグルの目的(再ビルドなしの調査)が失われる
- **トグルなしの常時 ON** — HTTP ログ・SQL トレースはログ量と性能への影響が大きい。本番既定は OFF とする
- **`Serilog` セクションへの混載** — Serilog 構成(log-4)はロガーの構成、`Log` セクションはアプリの振る舞い。役割が違うため分離する
