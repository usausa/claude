# TCP サーバ基盤(Kestrel ConnectionHandler)

| 項目 | 内容 |
|---|---|
| ID | network-1 |
| 分類 | network |
| 関連 | network-2(受信ループ) / network-3(アロケーションフリー処理) / host-4(DI 登録) / worker-2(線形ディスパッチ) / deploy-1(サービス化) / log-1(Log.cs) |

## 目的

**独自プロトコルの TCP サービスは Kestrel の `ConnectionHandler` 継承で構築する(決定)**。ソケット直叩きの自作サーバ基盤は標準としない。

- 接続の受付・ソケット管理・バッファリング(`IDuplexPipe` の供給)を Kestrel に任せ、アプリはプロトコル処理だけを書く
- DI・ログ・graceful shutdown・テレメトリがホスト基盤とそのまま統合される
- HTTP / gRPC と同じ運用形(サービス化 deploy-1、起動ログ host-3)に乗る

## 標準形

### 待受の登録

Kestrel のリッスンオプションでポートとハンドラを結び付ける(ポートはダミー)。

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.WebHost.ConfigureKestrel(static options =>
{
    options.ListenAnyIP(12345, static listen => listen.UseConnectionHandler<CommandHandler>());
});
```

### ConnectionHandler

`ConnectionHandler` を継承し、`OnConnectedAsync` に接続単位の処理を書く。ハンドラは DI から生成される共有インスタンスであり、依存はコンストラクタ注入、**接続毎の状態はフィールドに持たずコンテキストクラスに持つ**。

```csharp
public sealed class CommandHandler : ConnectionHandler
{
    private readonly ILogger<CommandHandler> log;

    private readonly CommandSetting setting;

    private readonly ICommand[] commands;

    public CommandHandler(
        ILogger<CommandHandler> log,
        CommandSetting setting,
        IEnumerable<ICommand> commands)
    {
        this.log = log;
        this.setting = setting;
        this.commands = commands.ToArray();
    }

    public override async Task OnConnectedAsync(ConnectionContext connection)
    {
        log.DebugHandlerConnected(connection.ConnectionId);

        try
        {
            var context = new CommandContext
            {
                AllowAnonymous = setting.AllowAnonymous
            };

            // 受信ループ(network-2)
        }
        catch (OperationCanceledException)
        {
            // Ignore
        }
        finally
        {
            log.DebugHandlerDisconnected(connection.ConnectionId);
        }
    }
}
```

### 接続コンテキスト

認証状態などの接続毎の状態は `CommandContext` に集約し、コマンド処理へ引き回す。

```csharp
public sealed class CommandContext
{
    public bool AllowAnonymous { get; set; }

    public bool IsAuthorized { get; set; }

    public bool IsAllowed => AllowAnonymous || IsAuthorized;
}
```

### コマンドのディスパッチ

コマンドは `ICommand` で宣言し、複数 `AddSingleton<ICommand, T>` → `IEnumerable<ICommand>` 受けの線形ディスパッチとする(host-4。worker-2 と同型)。

```csharp
public interface ICommand
{
    string Name { get; }

    bool Match(ReadOnlySequence<byte> command);

    ValueTask<bool> ExecuteAsync(CommandContext context, ReadOnlySequence<byte> options, IBufferWriter<byte> writer);
}
```

```csharp
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddCommands(this IServiceCollection services)
    {
        services.AddSingleton<ICommand, ExitCommand>();
        services.AddSingleton<ICommand, HealthCommand>();
        services.AddSingleton<ICommand, GetCommand>();
        services.AddSingleton<ICommand, SetCommand>();
        return services;
    }
}
```

コマンド実装は薄く保ち、実処理は Service へ委譲する。応答は `IBufferWriter<byte>` に直接書く(network-3)。

```csharp
public sealed class GetCommand : ICommand
{
    private readonly DataService dataService;

    public GetCommand(DataService dataService)
    {
        this.dataService = dataService;
    }

    public string Name => "get";

    public bool Match(ReadOnlySequence<byte> command) => command.SequentialEqual("get"u8);

    public ValueTask<bool> ExecuteAsync(CommandContext context, ReadOnlySequence<byte> options, IBufferWriter<byte> writer)
    {
        if (!context.IsAllowed)
        {
            writer.WriteAndAdvanceNg();
            return ValueTask.FromResult(true);
        }

        writer.WriteAndAdvanceOk(dataService.QueryValue());

        return ValueTask.FromResult(true);
    }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| ハンドラ・コンテキスト・プロトコルヘルパ | `Handlers/` |
| コマンド群 | `Handlers/Commands/` |
| ハンドラ用ログ定義 | `Handlers/Log.cs`(名前空間毎の分割配置。log-1) |
| 待受ポート・許可設定 | `Settings/` の Setting クラス(config-4)。値は appsettings から |

## バリエーションと使い分け

- **汎用ホスト(`Host.CreateApplicationBuilder`)で組む場合**: Kestrel を内包する薄いラッパ拡張(`AddTcpService(options => options.ListenAnyIP<CommandHandler>(port))` の形)で同型にできる。ハンドラ・受信ループの書き方は変わらない
- **HTTP / gRPC との同居**: 同じ Kestrel に `ListenAnyIP` を並べ、ポート毎にプロトコルを分ける
- **メトリクス**: コマンド実行数・処理時間は `TimeProvider.GetTimestamp()` / `GetElapsedTime()` で計測し、`ApplicationInstrument`(telemetry-1)へ記録する

## アンチパターン

- `Socket` / `TcpListener` 直叩きの自作サーバ基盤 — 受付・パイプ管理・シャットダウンの再発明になる。Kestrel に任せる
- 接続毎の状態をハンドラのフィールドに持つ — ハンドラは全接続で共有される。状態は `CommandContext` へ
- コマンド名の判定に文字列化(`Encoding.GetString` → `switch`)を使う — `ReadOnlySequence<byte>` のまま比較する(network-3)
- コマンド実装への業務ロジック直書き — コマンドはプロトコル境界。実処理は Service / Usecase へ委譲する
- 通信例外でサービス全体を落とす — 接続単位で握りつぶしてログ+継続する(network-2)
