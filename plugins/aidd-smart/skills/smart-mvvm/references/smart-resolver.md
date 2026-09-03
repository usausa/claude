# DI コンテナ差し替え(Smart.Resolver)

| 項目 | 内容 |
|---|---|
| ID | mvvm-3 |
| 分類 | mvvm |
| 関連 | mvvm-1(Smart.Mvvm 基盤) / mvvm-2(Smart.Navigation) / mvvm-4(クライアント起動ハブ) / host-4(DI 登録スタイル) / maui-1(MauiProgram チェーン) |

## 目的

XAML 系クライアントの DI コンテナを **Smart.Resolver に差し替え、XAML から ViewModel を直接解決する**。

- `SmartServiceProviderFactory` で Generic Host / MauiApp のコンテナを置き換え、`Microsoft.Extensions.DependencyInjection` の登録(`IServiceCollection`)と Smart.Resolver の登録(`ResolverConfig`)を同じコンテナに同居させる
- 自動バインディング(`UseAutoBinding` 等)により、ViewModel は登録なしでコンストラクタインジェクションできる
- XAML の `s:DataContextResolver.Type` で View と ViewModel を接続し、**code-behind を `InitializeComponent()` のみに保つ**

## 標準形

### ファクトリの適用

Generic Host では `ConfigureContainer` に `SmartServiceProviderFactory` を渡す。Smart.Resolver 側の登録は `ResolverConfig` を受けるメソッドに集約する(mvvm-4)。

```csharp
public static IHostApplicationBuilder ConfigureComponents(this IHostApplicationBuilder builder)
{
    builder.ConfigureContainer(new SmartServiceProviderFactory(), ConfigureContainer);

    // IServiceCollection ベースの登録もそのまま使える
    builder.Services.AddHttpClient();
    builder.Services.AddSingleton(TimeProvider.System);

    return builder;
}
```

MAUI では `MauiAppBuilder` に対して同じ形で適用する(maui-1)。

```csharp
builder.ConfigureContainer(new SmartServiceProviderFactory(), ConfigureContainer);
```

### ResolverConfig の基本形

冒頭で自動バインディング3点を有効化し、以降に明示登録を並べる。登録順はレイヤ順とし、区切りコメントで見せる(host-4 と同じ流儀)。

```csharp
private static void ConfigureContainer(ResolverConfig config)
{
    config
        .UseAutoBinding()
        .UseArrayBinding()
        .UseAssignableBinding();

    // Messenger
    config.BindSingleton<IReactiveMessenger>(ReactiveMessenger.Default);

    // Navigation
    config.BindSingleton<Navigator>(static resolver => /* mvvm-2 参照 */);

    // State
    config.BindSingleton<Session>();

    // Service
    config.BindSingleton<DataService>();

    // Usecase
    config.BindSingleton<OrderUsecase>();
}
```

- `UseAutoBinding`: 具象型を登録なしで解決する(ViewModel はこれで解決される)
- `UseArrayBinding`: 複数登録を配列・`IEnumerable<T>` で受ける
- `UseAssignableBinding`: 代入互換のあるインターフェースで解決する

### ResolveProvider への接続

ホスト構築後、`ResolveProvider.Default.Provider` にホストのサービスプロバイダを設定する。これが XAML からの解決経路になる。

```csharp
host = CreateHost();
ResolveProvider.Default.Provider = host.Services;
```

### XAML からの ViewModel 解決

View のルート要素に `s:DataContextResolver.Type` を指定すると、DataContext がコンテナから解決・設定される。`d:DataContext` はデザイナ用に併記する。

```xml
<UserControl xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
             xmlns:s="http://smart/windows"
             xmlns:local="clr-namespace:Template.App.Modules.Main"
             x:Class="Template.App.Modules.Main.MenuView"
             s:DataContextResolver.Type="{x:Type local:MenuViewModel}"
             d:DataContext="{d:DesignInstance Type={x:Type local:MenuViewModel}}">
    ...
</UserControl>
```

code-behind は次の形のみとする。

```csharp
[View(ViewId.Menu)]
public sealed partial class MenuView
{
    public MenuView()
    {
        InitializeComponent();
    }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| `SmartServiceProviderFactory` の適用 | `ApplicationExtensions.ConfigureComponents`(mvvm-4)。MAUI は `MauiProgram`(maui-1) |
| `ConfigureContainer(ResolverConfig)` | `ApplicationExtensions.cs` に1箇所のみ |
| `ResolveProvider.Default.Provider` の設定 | ホスト構築直後(App のコンストラクタ / `Initialize`。MAUI は `ApplicationInitializer` → maui-2) |

## バリエーションと使い分け

- **`IServiceCollection` と `ResolverConfig` の使い分け**: フレームワーク系拡張(`AddHttpClient` / `AddOptions` / `AddSerilog` 等)は `IServiceCollection` 側、アプリ部品(Messenger / Navigator / State / Service / Usecase)は `ResolverConfig` 側に寄せる
- **MAUI の追加オプション**: `UsePropertyInjector` / `UsePageContextScope` 等、モバイル向けのプラグインを追加する(maui-1)
- **サービスの一括登録**: 命名規約ベースの一括登録(`[ServiceRegistration(Lifetime.Singleton, "Service$")]` の partial メソッド生成)を併用してよい

## アンチパターン

- **code-behind での DataContext 手動設定** — `new MenuViewModel(...)` や `DataContext = ...` を書くと DI が効かず依存が固定される。`s:DataContextResolver.Type` に統一する
- **ViewModel を1件ずつコンテナ登録する** — `UseAutoBinding` で解決されるため不要。登録リストの肥大化と漏れの温床になる
- **ServiceLocator 的な `ResolveProvider` の乱用** — アプリコードから `ResolveProvider` で解決するのは XAML 接続のための機構に限る。依存はコンストラクタインジェクションで受ける
- **登録の分散** — DI 登録が App / View / 各所に散ると全体像が追えない。`ConfigureContainer(ResolverConfig)` 一箇所に集約する(mvvm-4)
