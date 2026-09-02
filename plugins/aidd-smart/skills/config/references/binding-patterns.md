# バインドの定型2パターン

| 項目 | 内容 |
|---|---|
| ID | config-2 |
| 分類 | config |
| 関連 | config-1(命名と2系統) / config-3(ネスト設定) / host-4(DI 登録スタイル) / telemetry-1(OpenTelemetry) |

## 目的

設定値の取り出し方を2パターンに固定し、**`IOptions<T>` を業務コードに漏らさない**。

- 業務コードは POCO の設定クラスをコンストラクタで受けるだけになり、フレームワーク型への依存が消える
- 設定不備は `ValidateOnStart` により起動時に fail-fast で検出される

## 標準形

### パターン① — DI 登録(実行時に使う値)

`AddOptions` + `BindConfiguration` + 検証を仕掛けたうえで、**`IOptions<T>` を剥がして `T` 自体を Singleton 登録**する。

```csharp
// Setting
builder.Services.AddOptions<AuthSetting>().BindConfiguration("Auth").ValidateDataAnnotations().ValidateOnStart();
builder.Services.AddSingleton(static p => p.GetRequiredService<IOptions<AuthSetting>>().Value);
```

利用側は設定クラスを直接受ける。`IOptions<T>` は登録の1行にしか現れない。

```csharp
public sealed class TokenService
{
    private readonly AuthSetting setting;

    public TokenService(AuthSetting setting)
    {
        this.setting = setting;
    }
}
```

- `ValidateDataAnnotations().ValidateOnStart()` により、検証属性(config-1)の違反は起動時に例外となる
- 複数の Setting はこの2行の対を `// Setting` セクションに列挙する(host-4)

### パターン② — 即時取得(起動処理で使う値)

`Build()` 前の起動処理で値が必要な場合は、`GetSection().Get<T>()!` で即時取得してローカル変数に留める。

```csharp
// Setting
var setting = builder.Configuration.GetSection("Server").Get<ServerSetting>()!;

builder.Services.AddTcpService(options =>
{
    options.ListenAnyIP<CommandHandler>(setting.Port);
});
```

DI 登録の条件分岐にも使う。

```csharp
if (args.Length > 0)
{
    // Batch mode
    builder.Services.AddHostedService<ActionWorker>();
}
else
{
    // Schedule mode
    var setting = builder.Configuration.GetSection("Worker").Get<WorkerSetting>()!;
    builder.Services.AddJobSchedulerService(options =>
    {
        options.UseJob<ScheduleJob>(setting.Schedule.Cron);
    });
}
```

- 取得値はローカル変数に留め、コンテナには登録しない。実行時にも同じ設定が必要なら①を併記する(同一セクションの併用は可)
- 設定値から組み立てた派生オブジェクトの登録(`AddSingleton(new XxxOption { ... })`)は可

## 使い分け基準

| 観点 | ①(DI 登録) | ②(即時取得) |
|---|---|---|
| 値を使う時点 | 実行時(サービス・ミドルウェアの中) | 起動時(DI 登録・ビルダー構成の分岐) |
| 検証 | `ValidateOnStart` で起動時検証 | `!` により欠落は即例外 |
| 受け手 | コンストラクタ引数の `T` | ローカル変数 |
| 寿命 | Singleton としてアプリ全体 | 起動処理のスコープ内 |

## バリエーションと使い分け

- **簡略形(検証なし)**: `Configure<T>(GetSection)` + `Value` 剥がしの2行。検証を仕掛けない従来形であり、**新規は `ValidateOnStart` 付きの `AddOptions` 形を基本**とする

```csharp
builder.Services.Configure<AuthSetting>(builder.Configuration.GetSection("Auth"));
builder.Services.AddSingleton(static p => p.GetRequiredService<IOptions<AuthSetting>>().Value);
```

- **環境変数系(テレメトリ)**: `OTEL_EXPORTER_OTLP_ENDPOINT` 等は Setting クラスを作らず、判定を `IConfiguration` 拡張メソッドに隠蔽する(telemetry-1)

## アンチパターン

- **`IOptions<T>` / `IOptionsMonitor<T>` を業務コードで受ける** — フレームワーク型が業務層に漏れ、テストでもラップが必要になる。ホットリロードが本当に必要な箇所(認証ハンドラ等のフレームワーク統合部)以外では使わない
- **`IConfiguration` の注入 + 都度 `GetSection`** — 型・検証・既定値がコード中に散らばる。バインドは起動処理の1箇所に集約する
- **②で取得したインスタンスの直接登録** — `AddSingleton(setting)` で済ませると `ValidateOnStart` が効かない。実行時に使う値は①で登録する
- **Setting の Scoped / Transient 登録** — 設定は不変値であり Singleton とする(host-4 の「基本 Singleton」と整合)
