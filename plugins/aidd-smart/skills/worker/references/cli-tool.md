# CLI ツール

| 項目 | 内容 |
|---|---|
| ID | worker-3 |
| 分類 | worker |
| 関連 | worker-1(Batch の共通骨格) / worker-2(コマンドディスパッチ) / log-1(Log.cs 定型) / config-2(設定バインドの定型) / deploy-3(発行スクリプト) / guideline-1(エラー処理方針) |

## 目的

サブコマンド・オプション解析・ヘルプ表示を持つ対話的な CLI ツールは、**System.CommandLine + Smart.CommandLine.Hosting** で構築する。

- コマンドは `[Command]` / `[Option]` の属性宣言 + DI コンストラクタ注入の通常クラスとして書け、パーサ API を直接触らない
- 横断関心事(ログ・例外処理)は `ICommandFilter` パイプラインに集約し、各コマンドは正常系に集中する
- 終了コードは `context.ExitCode` → `host.RunAsync()` の戻り値として一貫して扱う

## 標準形

### Program.cs

`CommandHost.CreateBuilder(args).UseDefaults()` でホストを構成し、DI 登録 → コマンド構成 → `return await host.RunAsync()` の3段で固定する。

```csharp
var builder = CommandHost.CreateBuilder(args)
    .UseDefaults();

builder.Services.AddSingleton(TimeProvider.System);

builder.Services.AddSingleton<CommandClientFactory>();
builder.Services.AddSingleton<CommandUsecase>();

builder.Services.AddSingleton(static p => p.GetRequiredService<IConfiguration>().GetSection("Connection").Get<ConnectionSetting>() ?? new ConnectionSetting());

builder.ConfigureCommands(commands =>
{
    commands.ConfigureRootCommand(root =>
    {
        root.WithDescription("Template");
    });

    commands.AddGlobalFilters();
    commands.AddCommands();
});

var host = builder.Build();
return await host.RunAsync();
```

- 設定は `GetSection(...).Get<T>()` で即時取得し値として登録する(config-2)。CLI では未設定でも起動できるようフォールバック(`?? new`)を許容し、必須チェックはコマンド実行時に行う
- コマンド・フィルタの登録は `Commands/` / `Filters/` 側の拡張メソッド(`AddCommands` / `AddGlobalFilters`)に切り出し、Program.cs は1行にする(host-4 と同じ考え方)

### コマンド定義 — 属性宣言 + ICommandHandler

コマンドは `[Command("名前", "説明")]` を付けたクラスとし、オプションは `[Option<T>]` 属性のプロパティで宣言する。実行本体は `ICommandHandler.ExecuteAsync` に書く。

```csharp
namespace Template.CommandTool.Commands;

using Smart.CommandLine.Hosting;

[Command("hash", "Calculate file hash")]
public sealed class HashCommand : ICommandHandler
{
    [Option<string>("--file", "-f", Description = "target file", Required = true)]
    public required string FilePath { get; set; }

    [Option<OutputFormat>("--output", "-o", Description = "output format", DefaultValue = OutputFormat.Text)]
    public OutputFormat Output { get; set; }

    public async ValueTask ExecuteAsync(CommandContext context)
    {
        if (!File.Exists(FilePath))
        {
            Console.WriteLine("NG: File not found.");
            context.ExitCode = -1;
            return;
        }

        await using var stream = File.OpenRead(FilePath);
        var hash = await SHA256.HashDataAsync(stream);

        OutputWriter.Write(Output, new { File = FilePath, Hash = Convert.ToHexString(hash) }, static x => $"OK {x.Hash}");
    }
}
```

- 業務エラーは例外ではなく **メッセージ出力 + `context.ExitCode = -1` + return** で通知する(guideline-1)
- 実処理が重いコマンドは Usecase / Component へ委譲し、コマンドは入出力の変換に徹する

### サブコマンド階層

グループは中身のない親コマンドとして宣言し、登録側でネストを組み立てる。

```csharp
[Command("data", "Data operation")]
public sealed class DataCommand
{
}
```

```csharp
public static class CommandExtensions
{
    public static void AddCommands(this ICommandBuilder commands)
    {
        commands.AddCommand<DataCommand>(data =>
        {
            data.AddSubCommand<DataGetCommand>();
            data.AddSubCommand<DataSetCommand>();
        });

        commands.AddCommand<HashCommand>();
    }
}
```

### 基底クラスによる共通オプション共有

兄弟コマンドで共通のオプション(接続先・出力形式等)は抽象基底クラスに宣言し、設定ファイル値とのフォールバック解決も基底側に置く。

```csharp
public abstract class DataCommandBase
{
    private readonly ConnectionSetting setting;

    [Option<string>("--host", "-h", Description = "host (default: config)")]
    public string? Host { get; set; }

    [Option<int?>("--port", "-p", Description = "port (default: config)")]
    public int? Port { get; set; }

    protected DataCommandBase(ConnectionSetting setting)
    {
        this.setting = setting;
    }

    protected ConnectionParameter? ResolveConnection()
    {
        var host = Host ?? setting.Host;
        var port = Port ?? setting.Port;
        if (String.IsNullOrEmpty(host) || (port is null or 0))
        {
            return null;
        }

        return new ConnectionParameter(host, port.Value);
    }
}
```

### ICommandFilter パイプライン

ログ・例外処理はグローバルフィルタとして全コマンドに適用する。**Exception フィルタを最外殻**(優先度 `Int32.MaxValue`)に置き、未処理例外を必ずログ + `ExitCode = -1` に変換する。

```csharp
public static class CommandExtensions
{
    public static void AddGlobalFilters(this ICommandBuilder command)
    {
        command.AddGlobalFilter<LoggingFilter>();
        command.AddGlobalFilter<ExceptionFilter>(Int32.MaxValue);
    }
}
```

```csharp
public sealed class LoggingFilter : ICommandFilter
{
    private readonly ILogger<LoggingFilter> log;

    private readonly TimeProvider timeProvider;

    public LoggingFilter(ILogger<LoggingFilter> log, TimeProvider timeProvider)
    {
        this.log = log;
        this.timeProvider = timeProvider;
    }

    public async ValueTask ExecuteAsync(CommandContext context, CommandDelegate next)
    {
        log.InfoCommandStart(context.CommandType.Name);

        var timestamp = timeProvider.GetTimestamp();
        try
        {
            await next(context);
        }
        finally
        {
            var elapsed = (long)timeProvider.GetElapsedTime(timestamp).TotalMilliseconds;
            log.InfoCommandEnd(context.CommandType.Name, elapsed);
        }
    }
}
```

```csharp
public sealed class ExceptionFilter : ICommandFilter
{
    private readonly ILogger<ExceptionFilter> log;

    public ExceptionFilter(ILogger<ExceptionFilter> log)
    {
        this.log = log;
    }

    public async ValueTask ExecuteAsync(CommandContext context, CommandDelegate next)
    {
#pragma warning disable CA1031
        try
        {
            await next(context);
        }
        catch (Exception ex)
        {
            log.ErrorUnknownException(ex, context.CommandType.Name);

            context.ExitCode = -1;
        }
#pragma warning restore CA1031
    }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| コマンド定義 + 登録拡張(`AddCommands`) | `Commands/` |
| フィルタ + 登録拡張(`AddGlobalFilters`)+ フィルタ用 `Log.cs` | `Filters/`(log-1: 名前空間毎に分割) |
| 出力・クライアント等の部品 | `Components/` |
| 外部 SDK・複数手順を束ねる処理 | `Usecase/`(namespace-6) |
| 設定クラス | `Settings/`(config-4) |

## バリエーションと使い分け

- **定期バッチ**: ヘルプもオプション解析も不要でスケジューラから固定引数で叩くだけなら worker-1(`IAction` + `ActionWorker`)で足りる。ヒトが対話的に使う配布ツールは本形式
- **出力形式の切替**: `--output`(Text / Json)を共通オプションとし、`OutputWriter` で一元化する。スクリプトからのパース用途には Json を返す
- **配布**: 単一ファイル + self-contained で発行する(deploy-3)。`appsettings.json` は `ExcludeFromSingleFile` で外部に置き、接続先等を利用側で編集可能にする

## アンチパターン

- **`Main` での手動引数解析** — `args[0]` の switch で分岐する自作パーサは、ヘルプ・検証・サブコマンドの再発明になる。System.CommandLine に乗せる
- **各コマンドへの try/catch コピー** — 例外処理は `ExceptionFilter` の1箇所に集約する。コマンド内に書いてよいのは業務判断を伴う捕捉のみ(guideline-1)
- **例外による業務エラー通知** — 入力不備・接続失敗などの予期できる失敗で例外を投げない。メッセージ + `ExitCode` で返す
- **終了コードの不統一** — 成功 0 / 失敗 -1(非 0)を守らないと、呼び出し側スクリプトが失敗を検知できない
- **共通オプションのコピー宣言** — 兄弟コマンドに同じ `[Option]` を複製しない。基底クラスに一元化する
