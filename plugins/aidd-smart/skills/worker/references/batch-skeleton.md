# Batch の共通骨格

| 項目 | 内容 |
|---|---|
| ID | worker-1 |
| 分類 | worker |
| 関連 | worker-2(コマンドディスパッチ) / worker-3(CLI ツール) / host-1(Program.cs の構成) / host-3(起動ログの儀式) / deploy-1(サービス化 API) / log-1(Log.cs 定型) / config-2(設定バインドの定型) / guideline-1(エラー処理方針) |

## 目的

バッチ処理を **Generic Host + `BackgroundService` の1つの骨格**に統一し、処理の追加を「`IAction` 実装を1つ足す」だけにする。

- ホスト・ログ・設定・終了コードの扱いはすべて骨格側が持ち、業務処理(`IAction`)は純粋なロジックに集中できる
- コマンドライン引数で処理を選択する形に固定することで、1バイナリに複数のバッチ処理を同居させられる(タスクスケジューラ / cron からは引数違いで起動する)
- Web ホストと同じ定型セット(Program / GlobalUsing / Log / appsettings)を踏襲し、サーバ系と横断的に読み書きできる

## 標準形

### IAction — 業務処理の単位

処理は `Name`(引数と突合するキー)と `ExecuteAsync` のみを持つ `IAction` として実装する。

```csharp
namespace Template.Worker.Actions;

public interface IAction
{
    string Name { get; }

    ValueTask ExecuteAsync(string[] args, CancellationToken cancellationToken);
}
```

実装は DI から依存(ロガー・`TimeProvider`・Setting)を受け取る通常のクラスとする。

```csharp
namespace Template.Worker.Actions;

public sealed class HelloAction : IAction
{
    private readonly ILogger<HelloAction> log;

    private readonly TimeProvider timeProvider;

    public string Name => "hello";

    public HelloAction(ILogger<HelloAction> log, TimeProvider timeProvider)
    {
        this.log = log;
        this.timeProvider = timeProvider;
    }

    public ValueTask ExecuteAsync(string[] args, CancellationToken cancellationToken)
    {
        log.InfoHello(timeProvider.GetLocalNow(), String.Join(' ', args));
        return ValueTask.CompletedTask;
    }
}
```

### ActionArguments — 引数の分解

第1引数をアクション名、残りをアクションへのパラメータとして分解するだけの小さなクラスを DI に登録する。

```csharp
namespace Template.Worker.Actions;

public sealed class ActionArguments
{
    private readonly string[] args;

    public string Name => args[0];

    public ActionArguments(string[] args)
    {
        this.args = args;
    }

    public string[] GetParameters() => args[1..];
}
```

### ActionWorker — 実行エンジン

`BackgroundService` を1つだけ置き、**突合 → 実行 → 例外時 `ExitCode = -1` → finally で `StopApplication()`** の流れを固定する。

```csharp
namespace Template.Worker.Workers;

using Template.Worker.Actions;

public sealed class ActionWorker : BackgroundService
{
    private readonly ILogger<ActionWorker> log;

    private readonly IHostApplicationLifetime lifetime;

    private readonly IEnumerable<IAction> actions;

    private readonly ActionArguments arguments;

    public ActionWorker(
        ILogger<ActionWorker> log,
        IHostApplicationLifetime lifetime,
        IEnumerable<IAction> actions,
        ActionArguments arguments)
    {
        this.log = log;
        this.lifetime = lifetime;
        this.actions = actions;
        this.arguments = arguments;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
#pragma warning disable CA1031
        try
        {
            var action = actions.FirstOrDefault(x => String.Equals(x.Name, arguments.Name, StringComparison.OrdinalIgnoreCase));
            if (action is null)
            {
                log.WarnActionUnknown(arguments.Name);
                Environment.ExitCode = -1;
                return;
            }

            log.InfoActionStart(action.Name);
            await action.ExecuteAsync(arguments.GetParameters(), stoppingToken);
            log.InfoActionEnd(action.Name);
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
}
```

- 例外はここで一括捕捉してログ + 終了コードに変換する(guideline-1: 予期せぬ例外はグローバルに処理する。意図的な捕捉には `#pragma warning disable CA1031` を明示)
- `finally` の `StopApplication()` により、成功・失敗いずれでもホストが確実に終了する

### Program.cs — 定型セット

Generic Host(`Host.CreateApplicationBuilder`)で構成する。構成要素が少ないため直書きを許容するが、セクション順と区切りコメントは host-1 に合わせる。

```csharp
Directory.SetCurrentDirectory(AppContext.BaseDirectory);

var builder = Host.CreateApplicationBuilder(args);

// Service
builder.Services
    .AddWindowsService()
    .AddSystemd();

// Logging
builder.Logging.ClearProviders();
builder.Services.AddSerilog(options =>
{
    options.ReadFrom.Configuration(builder.Configuration);
});

// System
builder.Services.AddSingleton(TimeProvider.System);

// Setting
builder.Services.AddOptions<WorkerSetting>().BindConfiguration("Worker").ValidateDataAnnotations().ValidateOnStart();
builder.Services.AddSingleton(static p => p.GetRequiredService<IOptions<WorkerSetting>>().Value);

// Action
builder.Services.AddSingleton<IAction, HelloAction>();
builder.Services.AddSingleton<IAction, CleanupAction>();

// Worker
builder.Services.AddSingleton(new ActionArguments(args));
builder.Services.AddHostedService<ActionWorker>();

// Build
var host = builder.Build();

var log = host.Services.GetRequiredService<ILogger<Program>>();

// Startup information
log.InfoServiceStart();

// Run
await host.RunAsync();

return Environment.ExitCode;
```

- 冒頭の `Directory.SetCurrentDirectory(AppContext.BaseDirectory)`(host-2)、`AddWindowsService().AddSystemd()`(deploy-1)、起動ログの儀式(host-3)はサーバ系と共通
- 末尾は **`return Environment.ExitCode`** で終了コードを呼び出し元(スケジューラ / シェル)へ返す
- Log.cs(log-1)/ GlobalUsing.cs / appsettings.json(Serilog セクション委譲 = log-2)の定型セットも Web ホストと同一形式で持つ

## 配置ルール

| 対象 | 場所 |
|---|---|
| `IAction` / `ActionArguments` / 各アクション実装 | `Actions/` |
| `ActionWorker` | `Workers/`(namespace-1) |
| 設定クラス(`WorkerSetting`) | `Settings/`(config-4) |
| `Log.cs` | プロジェクト直下(ルート名前空間) |

## バリエーションと使い分け

- **スケジュールモードの同居**: 引数なし起動をスケジュールモードとし、cron 定義に基づき `IAction` を周期実行するジョブ(`ISchedulerJob` 実装がアクションを解決して実行)を登録する形に拡張できる。`args.Length > 0` で Batch / Schedule を分岐し、`IAction` 群は両モードで共有する
- **常駐ジョブとの違い**: 定期実行が主目的で外部スケジューラを使わない場合はスケジュールモード(またはキュー監視型の常駐 `BackgroundService`)を選ぶ。単発実行して終了コードを返すのが Batch モード
- **対話的な CLI ツール**: サブコマンド・オプション解析・ヘルプ表示が必要なものは worker-3(System.CommandLine)を使う。本骨格は「スケジューラから叩く定期バッチ」向け

## アンチパターン

- **Main への処理べた書き** — ホスト骨格なしに `Main` へ業務処理を書くと、ログ・設定・graceful shutdown・終了コードの扱いが処理毎にばらつく
- **アクション毎に実行エンジンを複製** — 突合・例外処理・`StopApplication` の流れを各所にコピーしない。エンジンは `ActionWorker` の1つに固定する
- **例外の放置** — `ExecuteAsync` から例外が漏れると終了コードに反映されずスケジューラが成功と誤認する。必ずエンジン側で捕捉して `ExitCode = -1` に変換する
- **`StopApplication()` 忘れ** — 処理完了後もホストが常駐し続け、スケジューラ側がタイムアウトする。`finally` で必ず呼ぶ
- **1バッチ=1バイナリの乱造** — 定型セットの複製が増える。処理は `IAction` として1バイナリに集約し、引数で選択する
