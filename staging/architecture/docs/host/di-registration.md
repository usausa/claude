# DI 登録スタイル

| 項目 | 内容 |
|---|---|
| ID | host-4 |
| 分類 | host |
| 関連 | host-1(Program.cs の構成) / namespace-1(サーバ側の標準語彙) / namespace-6(Usecase 層) / config-2(設定バインドの定型) / worker-2(コマンドディスパッチ) / generator-4(DI 自動登録) |

## 目的

DI 登録を**アプリケーションの部品表として読める**状態に保つ。

- 登録順をレイヤ順に固定することで、登録一覧がそのまま依存の方向(下層→上層)を表す
- 機能単位の登録は機能フォルダ側の拡張メソッドに置き、ホスト側は1行にする。機能の追加・削除がフォルダ単位で完結する

## 標準形

### 登録順=レイヤ順

`ConfigureComponents()`(host-1)では **Setting → Provider → Component → Service → Usecase → Worker** の順に、区切りコメント付きで登録する。

```csharp
public static IHostApplicationBuilder ConfigureComponents(this IHostApplicationBuilder builder)
{
    // Setting
    builder.Services.Configure<ServerSetting>(builder.Configuration.GetSection("Server"));
    builder.Services.AddSingleton<ServerSetting>(static p => p.GetRequiredService<IOptions<ServerSetting>>().Value);

    // Provider
    builder.Services.AddSingleton(TimeProvider.System);
    builder.Services.AddSingleton<IDbProvider>(static p =>
    {
        var connectionString = p.GetRequiredService<IConfiguration>().GetConnectionString("Default");
        return new DelegateDbProvider(() => new SqliteConnection(connectionString));
    });

    // Component
    builder.Services.AddMemoryCache();
    builder.Services.AddSingleton<IStorage, FileStorage>();

    // Service
    builder.Services.AddSingleton<DataService>();

    // Usecase
    builder.Services.AddSingleton<OrderUsecase>();

    // Worker
    builder.Services.AddHostedService<QueueWorker>();

    return builder;
}
```

- Setting は config-2 の定型(`Configure<T>` + 値の Singleton 再登録)で、`IOptions<T>` を業務コードに漏らさない
- Usecase は `Services` と同階層の独立レイヤ(namespace-6)

### 機能フォルダ毎の登録拡張

まとまった数の登録を持つ機能は、機能フォルダに `ServiceCollectionExtensions`(`internal static partial class`)を置いて `AddXxx()` に切り出す。

```csharp
namespace Template.CommandServer.Handlers;

using Template.CommandServer.Handlers.Commands;

internal static partial class ServiceCollectionExtensions
{
    public static IServiceCollection AddCommands(this IServiceCollection services)
    {
        services.AddSingleton<ICommand, HealthCommand>();
        services.AddSingleton<ICommand, AuthorizeCommand>();
        services.AddSingleton<ICommand, SetCommand>();
        services.AddSingleton<ICommand, GetCommand>();
        return services;
    }
}
```

呼び出し側は1行になる。

```csharp
// Handler
builder.Services.AddCommands();
```

### 複数実装の並記と IEnumerable&lt;T&gt; 受け

ストラテジ・コマンド群は同一インターフェースで `AddSingleton<I, T>` を並記し、利用側は `IEnumerable<T>` で受ける。ディスパッチは線形探索で足りる(worker-2)。

```csharp
public sealed class CommandDispatcher
{
    private readonly ICommand[] commands;

    public CommandDispatcher(IEnumerable<ICommand> commands)
    {
        this.commands = commands.ToArray();
    }

    public ICommand? Resolve(string name) => Array.Find(commands, x => x.Match(name));
}
```

### ライフタイム

**基本は Singleton**。サーバ部品はステートレスに設計し、状態は Setting・キャッシュ・ストアに寄せる。

| ライフタイム | 使いどころ |
|---|---|
| Singleton | 既定。Setting / Provider / Component / Service / Usecase |
| Scoped | フレームワークがスコープを要求する場合のみ(Blazor の回路スコープで保持する認証状態等) |
| Transient | 原則使わない |

Scoped 依存(DbContext 等)を Singleton の Worker から使う場合は、フィールドに掴まず**実行1回ごとに `IServiceScopeFactory` でスコープを切って解決する**(captive dependency を作らない)。

## 配置ルール

| 対象 | 場所 |
|---|---|
| レイヤ順のまとめ登録 | `ApplicationExtensions.ConfigureComponents()`(host-1) |
| 機能単位の登録拡張 | 各機能フォルダの `ServiceCollectionExtensions.cs` |
| 設定バインド | config-2 の定型に従う(Setting セクション内) |

## バリエーションと使い分け

- **自動登録**: 登録数が多い場合はソースジェネレータで `AddSingleton` 群を生成し、登録漏れを構造的に防ぐ(generator-4)
- **条件付き登録**: 起動時に判定が必要な値は `GetSection("X").Get<T>()!` で即時取得してローカル変数化し(config-2)、分岐は `ConfigureComponents` 内に閉じる
- **クライアントアプリ**: DI 登録は `ConfigureContainer(ResolverConfig)` の一箇所に集約する(mvvm-3 / mvvm-4)。登録順をレイヤ順で固定する考え方は同じ(maui-1)

## アンチパターン

- **数十行のべた書き登録** — 区切りも切り出しもない羅列は部品表として読めず、機能の境界が消える
- **Transient の乱用** — 生成・破棄コストがかかるうえ、Singleton から掴むと captive dependency(事実上の Singleton 化)になる。既定は Singleton
- **ホストが機能の内部型を直接登録** — 機能フォルダ内部の実装型をホスト側に並べない。`AddXxx()` 拡張で隠蔽する
- **登録順が追加順** — レイヤ順を崩すと依存方向が読めなくなる。新規登録は該当セクションへ挿入する
