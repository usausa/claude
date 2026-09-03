# 起動ログの儀式

| 項目 | 内容 |
|---|---|
| ID | host-3 |
| 分類 | host |
| 関連 | host-1(Program.cs の構成) / log-1(Log.cs 定型) / log-2(Serilog 構成) / telemetry-1(OpenTelemetry) |

## 目的

起動直後のログに**実行環境の一次情報を必ず残す**。

- 障害調査は「いつ起動し、どのバージョンが、どの環境で動いていたか」の確認から始まる。起動ログがあれば、ログファイルだけで即答できる
- Server GC の未設定、ランタイムバージョン違い、配備先ディレクトリの誤り等の**環境ミスマッチを起動時点で検出できる**
- 書式が固定されているため、複数ホスト・複数世代のログを機械的に突き合わせられる

## 標準形

`Build()` 直後、パイプライン構成より前に `LogStartupInformation()` を呼ぶ(host-1)。出力項目は次の5行を基本とする。レベルは Information(本番でも必ず記録される)。

| 項目 | 内容 |
|---|---|
| ServiceStart | 起動の目印(ローテーション跨ぎでも起動点を特定できる) |
| Runtime | OS / FrameworkDescription / RID |
| Environment | アセンブリバージョン / カレントディレクトリ |
| GC | IsServerGC / LatencyMode / LargeObjectHeapCompactionMode |
| ThreadPool | 最小スレッド数(ワーカー / IOCP) |

### LogStartupInformation 拡張

`ApplicationExtensions.cs` の Information セクションに置く。

```csharp
public static void LogStartupInformation(this WebApplication app)
{
    ThreadPool.GetMinThreads(out var workerThreads, out var completionPortThreads);

    app.Logger.InfoServiceStart();
    app.Logger.InfoServiceSettingsRuntime(RuntimeInformation.OSDescription, RuntimeInformation.FrameworkDescription, RuntimeInformation.RuntimeIdentifier);
    app.Logger.InfoServiceSettingsEnvironment(typeof(Program).Assembly.GetName().Version, Environment.CurrentDirectory);
    app.Logger.InfoServiceSettingsGC(GCSettings.IsServerGC, GCSettings.LatencyMode, GCSettings.LargeObjectHeapCompactionMode);
    app.Logger.InfoServiceSettingsThreadPool(workerThreads, completionPortThreads);
}
```

### Log.cs の定義

メッセージは log-1 の規約どおり `[LoggerMessage]` で定義する。書式は `Xxx: key=[{value}]` 形式で統一する。

```csharp
namespace Template.ApiServer.Host.Application;

internal static partial class Log
{
    [LoggerMessage(Level = LogLevel.Information, Message = "Service start.")]
    public static partial void InfoServiceStart(this ILogger logger);

    [LoggerMessage(Level = LogLevel.Information, Message = "Runtime: os=[{osDescription}], framework=[{frameworkDescription}], rid=[{runtimeIdentifier}]")]
    public static partial void InfoServiceSettingsRuntime(this ILogger logger, string osDescription, string frameworkDescription, string runtimeIdentifier);

    [LoggerMessage(Level = LogLevel.Information, Message = "Environment: version=[{version}], directory=[{directory}]")]
    public static partial void InfoServiceSettingsEnvironment(this ILogger logger, Version? version, string directory);

    [LoggerMessage(Level = LogLevel.Information, Message = "GCSettings: serverGC=[{isServerGC}], latencyMode=[{latencyMode}], largeObjectHeapCompactionMode=[{largeObjectHeapCompactionMode}]")]
    public static partial void InfoServiceSettingsGC(this ILogger logger, bool isServerGC, GCLatencyMode latencyMode, GCLargeObjectHeapCompactionMode largeObjectHeapCompactionMode);

    [LoggerMessage(Level = LogLevel.Information, Message = "ThreadPool: workerThreads=[{workerThreads}], completionPortThreads=[{completionPortThreads}]")]
    public static partial void InfoServiceSettingsThreadPool(this ILogger logger, int workerThreads, int completionPortThreads);
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| `LogStartupInformation` | `Application/ApplicationExtensions.cs`(host-1) |
| `[LoggerMessage]` 定義 | `Application/Log.cs`(log-1) |
| 呼び出し位置 | `Build()` 直後・パイプライン構成の前(`Program.cs`) |

## バリエーションと使い分け

- **Generic Host**: `app.Logger` がないため、`host.Services.GetRequiredService<ILogger<Program>>()` で取得して同じ項目を出力する

```csharp
var host = builder.Build();

var log = host.Services.GetRequiredService<ILogger<Program>>();

ThreadPool.GetMinThreads(out var workerThreads, out var completionPortThreads);
log.InfoServiceStart();
log.InfoServiceSettingsEnvironment(typeof(Program).Assembly.GetName().Version, Environment.CurrentDirectory);
log.InfoServiceSettingsGC(GCSettings.IsServerGC, GCSettings.LatencyMode, GCSettings.LargeObjectHeapCompactionMode);
log.InfoServiceSettingsThreadPool(workerThreads, completionPortThreads);
```

- **Telemetry 行の追加**: OTLP エンドポイントや Prometheus URI を `InfoServiceSettingsTelemetry` として併記し、テレメトリの有効状態を可視化する(telemetry-1)
- **アプリ固有設定行の追加**: RateLimit 等、運用調整の対象となる設定値を `InfoServiceSettingsXxx` として追加してよい。命名・書式は log-1 に従う
- **項目の追加**: 必要に応じて `ThreadPool.GetMaxThreads` や `Environment.ProcessorCount` を加えてよいが、基本5行は削らない

## アンチパターン

- **起動ログを出さない** — 障害調査でバージョン・環境を配備記録から推定するはめになる。一次情報はログに残す
- **文字列補間・`Console.WriteLine` でのべた書き** — 構造化されず、log-1 の規約にも反する。必ず `[LoggerMessage]` 経由で出力する
- **Debug レベルでの出力** — 本番の最低レベル(Information)で消えてしまう。起動ログは Information で出す
- **書式の場当たり的な変更** — `Xxx: key=[{value}]` の形式を崩すと、ホスト間・世代間の突き合わせができなくなる
