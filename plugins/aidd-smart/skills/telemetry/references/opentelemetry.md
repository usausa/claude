# OpenTelemetry

| 項目 | 内容 |
|---|---|
| ID | telemetry-1 |
| 分類 | telemetry |
| 関連 | telemetry-2(HealthChecks) / telemetry-3(公開エンドポイントの保護) / host-1(Program.cs の構成) / host-3(起動ログの儀式) / log-2(Serilog の構成方法) / solution-2(Aspire AppHost) / namespace-2(Application 名前空間) |

## 目的

メトリクス・トレース・ログの計装を**アプリ標準の3点セット(Source / ApplicationInstrument / 登録拡張)+ `ConfigureTelemetry()`** に固定する。

- **テレメトリ関連の設定は環境変数から取得する**(決定事項)。OTLP 出力は `OTEL_EXPORTER_OTLP_ENDPOINT` の有無だけで有効化が切り替わり、アプリは環境(開発の Aspire / 本番のコレクタ / スタンドアロン)を意識しない
- カスタム計装(Meter / ActivitySource / Counter)を DI 管理の1クラスに集約し、計装の追加箇所を1つにする

## 標準形

### Source — 計装ソースの識別子

Meter / ActivitySource の名前とバージョンはアセンブリから取得し、`Source` に集約する。

```csharp
namespace App.Host.Application.Telemetry;

using System.Reflection;

public static class Source
{
    private static readonly AssemblyName AssemblyName = typeof(Source).Assembly.GetName();

    public static string Name => AssemblyName.Name!;

    public static string Version => AssemblyName.Version!.ToString();
}
```

### ApplicationInstrument — カスタム計装の集約

Meter・ActivitySource・Counter 群を1クラスに持ち、**DI に Singleton 登録**する。Meter は `IMeterFactory` から生成する。

```csharp
namespace App.Host.Application.Telemetry;

using System.Diagnostics;
using System.Diagnostics.Metrics;

public sealed class ApplicationInstrument : IDisposable
{
    private readonly Meter meter;

    private readonly Counter<long> requestExecution;

    public ActivitySource ActivitySource { get; }

    public ApplicationInstrument(IMeterFactory meterFactory)
    {
        ActivitySource = new ActivitySource(Source.Name, Source.Version);
        meter = meterFactory.Create(Source.Name, Source.Version);

        meter.CreateObservableCounter("application.uptime", ObserveApplicationUptime);

        requestExecution = meter.CreateCounter<long>("api.request.execution", description: "API request count");
    }

    public void Dispose()
    {
        meter.Dispose();
    }

    private static long ObserveApplicationUptime() =>
        (long)(DateTime.Now - Process.GetCurrentProcess().StartTime).TotalSeconds;

    public void IncrementRequestExecution() => requestExecution.Add(1);
}
```

### 登録拡張 — AddApplicationInstrumentation / AddApplicationInstrument

Meter / Tracer への接続とインスツルメントの DI 登録を拡張メソッドに切り出す。

```csharp
namespace App.Host.Application.Telemetry;

using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;

public static class MeterProviderBuilderExtensions
{
    public static MeterProviderBuilder AddApplicationInstrumentation(this MeterProviderBuilder builder)
    {
        builder.AddMeter(Source.Name);
        return builder;
    }

    public static TracerProviderBuilder AddApplicationInstrumentation(this TracerProviderBuilder builder)
    {
        builder.AddSource(Source.Name);
        return builder;
    }

    public static IServiceCollection AddApplicationInstrument(this IServiceCollection services)
    {
        services.AddSingleton<ApplicationInstrument>();
        return services;
    }
}
```

### ConfigureTelemetry — 環境変数による有効化分岐

OTLP は `OTEL_EXPORTER_OTLP_ENDPOINT` の有無で有効化を分岐する。**判定は `IConfiguration` 拡張メソッドに隠蔽する**(`IConfiguration` は環境変数を設定ソースに含むため、環境変数がそのまま読める)。Prometheus は設定節(`Prometheus:Uri`)で制御する。

```csharp
public static IHostApplicationBuilder ConfigureTelemetry(this IHostApplicationBuilder builder)
{
    var useOtlpExporter = builder.Configuration.IsOtelExporterEnabled();

    var prometheusUri = builder.Configuration.GetSection("Prometheus").GetValue<string>("Uri")!;
    var usePrometheusExporter = !String.IsNullOrEmpty(prometheusUri);

    var telemetry = builder.Services.AddOpenTelemetry()
        .ConfigureResource(config =>
        {
            config.AddService(
                serviceName: builder.Environment.ApplicationName,
                serviceVersion: typeof(Program).Assembly.GetName().Version?.ToString(),
                serviceInstanceId: Environment.MachineName);
        });

    // Log
    if (useOtlpExporter)
    {
        builder.Logging.AddOpenTelemetry(logging =>
        {
            logging.IncludeFormattedMessage = true;
            logging.IncludeScopes = true;
        });
        builder.Services.Configure<OpenTelemetryLoggerOptions>(static logging =>
        {
            logging.AddOtlpExporter();
        });
    }

    // Metrics
    if (useOtlpExporter || usePrometheusExporter)
    {
        telemetry.WithMetrics(metrics =>
        {
            metrics
                .AddRuntimeInstrumentation()
                .AddHttpClientInstrumentation()
                .AddAspNetCoreInstrumentation()
                .AddApplicationInstrumentation();

            if (useOtlpExporter)
            {
                metrics.AddOtlpExporter();
            }

            if (usePrometheusExporter)
            {
                metrics.AddPrometheusHttpListener(config =>
                {
                    config.UriPrefixes = [prometheusUri];
                });
            }
        });
    }

    // Trace
    if (useOtlpExporter)
    {
        telemetry.WithTracing(tracing =>
        {
            tracing
                .AddSource(builder.Environment.ApplicationName)
                .AddAspNetCoreInstrumentation(static options =>
                {
                    options.Filter = static context =>
                    {
                        var path = context.Request.Path;
                        return !path.StartsWithSegments("/health", StringComparison.OrdinalIgnoreCase) &&
                               !path.StartsWithSegments("/alive", StringComparison.OrdinalIgnoreCase);
                    };
                })
                .AddHttpClientInstrumentation()
                .AddApplicationInstrumentation();

            tracing.AddOtlpExporter();
        });
    }

    // Custom instrument
    builder.Services.AddApplicationInstrument();

    return builder;
}
```

判定の拡張メソッドは `ApplicationExtensions` の末尾(Configuration セクション)に置く。

```csharp
private static bool IsOtelExporterEnabled(this IConfiguration configuration) =>
    !String.IsNullOrWhiteSpace(configuration.GetOtelExporterEndpoint());

private static string GetOtelExporterEndpoint(this IConfiguration configuration) =>
    configuration["OTEL_EXPORTER_OTLP_ENDPOINT"] ?? string.Empty;
```

- `AddOtlpExporter()` に引数は渡さない。エンドポイント・プロトコルは OTLP 標準の環境変数(`OTEL_EXPORTER_OTLP_ENDPOINT` 等)からエクスポータ自身が読む。アプリ側の環境変数参照は**有効/無効の判定のみ**
- ヘルスチェック等の定常アクセス(telemetry-2)はトレース収集から除外する
- Serilog との併用時は `writeToProviders: useOtlpExporter` を渡し、OTLP 有効時のみログを `ILoggerProvider` 側(OpenTelemetry ロガー)へも流す(log-2)
- 起動ログに OTLP エンドポイントと Prometheus URI を出力し、有効化状態を起動時に確認できるようにする(host-3)

## 配置ルール

| 対象 | 場所 |
|---|---|
| `Source.cs` / `ApplicationInstrument.cs` / 登録拡張 | `Application/Telemetry/`(namespace-2) |
| `ConfigureTelemetry()` | `ApplicationExtensions.cs`(host-1)。肥大化したら `ApplicationExtensions.Telemetry.cs` に partial 分割 |
| OTLP エンドポイント | 環境変数(`OTEL_EXPORTER_OTLP_ENDPOINT`)。systemd では unit の `Environment=`(deploy-2)、開発時は Aspire AppHost が自動注入(solution-2) |
| Prometheus の URI | 設定節 `Prometheus:Uri` |

## バリエーションと使い分け

- **非 Web 常駐(Generic Host)**: `AddAspNetCoreInstrumentation` を除き、Metrics 中心の構成にする。Prometheus の pull だけでよければ `WithMetrics` + `AddPrometheusHttpListener` のみの最小形も可
- **インスツルメントを Meter 側から解決する形**: `AddInstrumentation(static p => p.GetRequiredService<ApplicationInstrument>())` を登録拡張に含め、メトリクス有効時に確実に生成させる形もある。Web 標準形では起動時初期化(`InitializeApplicationAsync` での `GetRequiredService`)で代替する
- **複数プロジェクト構成**: Telemetry 一式は基盤層プロジェクト(solution-3)に置き、複数ホストで共有する

## アンチパターン

- **OTLP エンドポイントの appsettings 直書き** — テレメトリ設定は環境変数から取得する(決定事項)。設定ファイルに書くと環境差分が成果物・設定ファイル管理に染み出す
- **Meter / ActivitySource の分散 new** — 各クラスで `new ActivitySource(...)` を持つと名前がブレて計装の全体像が見えなくなる。`ApplicationInstrument` に集約する
- **エクスポータの無条件登録** — OTLP 出力先がない環境で `AddOtlpExporter()` を常時登録すると、接続リトライのノイズとコストだけが残る。有効化は必ず分岐させる
- **判定ロジックの散在** — `configuration["OTEL_EXPORTER_OTLP_ENDPOINT"]` を各所に書かない。`IsOtelExporterEnabled()` 拡張に隠蔽し、意味(有効化判定)で参照する
- **ヘルスチェックのトレース収集** — `/health` への定常ポーリングがトレースを埋め尽くす。`Filter` で除外する
