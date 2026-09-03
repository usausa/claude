# Smart.Navigation による画面遷移

| 項目 | 内容 |
|---|---|
| ID | mvvm-2 |
| 分類 | mvvm |
| 関連 | mvvm-1(Smart.Mvvm 基盤) / mvvm-3(DI コンテナ差し替え) / mvvm-4(クライアント起動ハブ) / mvvm-5(Modules 構成) / wpf-1(WindowManager の用途限定) / maui-5(Blazor Hybrid での代替) |

## 目的

**画面遷移を持つアプリはプラットフォーム(WPF / Avalonia / MAUI)を問わず Smart.Navigation を使用する(決定)**。

- 画面 ID(enum)ベースの遷移により、遷移先を型・ウィンドウではなく論理 ID で表現する
- View の登録は属性 + ソースジェネレータで自動化し、登録漏れ・手書きマッピングを排除する
- シェル(単一ウィンドウ)+ コンテンツ切替の構成に統一し、ウィンドウを増やさない。ツール的な子ウィンドウ管理のみ WindowManager を使う(wpf-1)

## 標準形

### 画面 ID は enum

画面は `ViewId`、ダイアログ(ポップアップ)は `DialogId` の enum で定義する。機能グループ毎にコメントで区切る。

```csharp
namespace Template.App.Modules;

public enum ViewId
{
    Menu,
    Setting,

    // Order
    OrderList,
    OrderDetail
}
```

### View への属性付与と自動登録

View には `[View(ViewId.X)]` を付与する。code-behind は `InitializeComponent()` のみとする(mvvm-3)。

```csharp
namespace Template.App.Modules.Main;

[View(ViewId.Menu)]
public sealed partial class MenuView
{
    public MenuView()
    {
        InitializeComponent();
    }
}
```

ID と View のマッピングは `[ViewSource]` partial メソッド(ソースジェネレータ)で自動収集する。

```csharp
public static partial class ApplicationExtensions
{
    [ViewSource]
    public static partial IEnumerable<KeyValuePair<ViewId, Type>> ViewSource();
}
```

### Navigator の構築

Navigator は DI コンテナ(mvvm-3)に Singleton で登録する。プロバイダのみプラットフォーム別で、構成は共通。**DEBUG 時のみ遷移トレースを仕込む**。

```csharp
// ConfigureContainer(ResolverConfig) 内
config.BindSingleton<Navigator>(static resolver =>
{
    var navigator = new NavigatorConfig()
        .UseWindowsNavigationProvider()   // Avalonia: UseAvaloniaNavigationProvider / MAUI: UseMauiNavigationProvider
        .UseServiceProvider(resolver)
        .UseIdViewMapper(static m => m.AutoRegister(ViewSource()))
        .ToNavigator();
#if DEBUG
    navigator.Navigated += static (_, args) =>
    {
        // for debug
        System.Diagnostics.Debug.WriteLine($"Navigated: [{args.Context.FromId}]->[{args.Context.ToId}]");
    };
#endif

    return navigator;
});
```

### シェルは NavigationContainer

メインウィンドウは遷移コンテナ(`Canvas` 等)を1つ持つだけのシェルとし、`NavigationContainer.Navigator` に Navigator をバインドする。

```xml
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:navigation="http://smart/navigation"
        x:Class="Template.App.Views.MainWindow">

    <Grid>
        <Canvas navigation:NavigationContainer.Navigator="{Binding Navigator}" />
    </Grid>

</Window>
```

### 起動末尾で初期画面へ遷移

ホスト起動後、起動処理の末尾で初期画面へ `ForwardAsync` する(mvvm-4)。

```csharp
// 起動処理の末尾
var navigator = host.Services.GetRequiredService<Navigator>();
await navigator.ForwardAsync(ViewId.Menu).ConfigureAwait(false);
```

### ViewModel からの遷移

ViewModel 基底(mvvm-1)が `INavigatorAware` を実装し、`Navigator` プロパティ経由で遷移する。遷移はコマンドから呼ぶ。

```csharp
public sealed partial class MenuViewModel : AppViewModelBase
{
    public IObserveCommand ForwardCommand { get; }

    public MenuViewModel()
    {
        // CommandParameter に ViewId を渡す形
        ForwardCommand = MakeAsyncCommand<ViewId>(x => Navigator.ForwardAsync(x));
    }
}
```

遷移前後の処理は `INavigationEventSupport`(または Async 版)の `OnNavigatingFrom` / `OnNavigatingTo` / `OnNavigatedTo` に書く。

## 配置ルール

| 対象 | 場所 |
|---|---|
| `ViewId` / `DialogId` | `Modules/` 直下(mvvm-5)。`Views/` 平置き構成では `Views/` 直下 |
| `[ViewSource]` / `[PopupSource]` partial | `ApplicationExtensions.cs`(mvvm-4)または `MauiProgram.cs`(maui-1) |
| Navigator の登録 | `ConfigureContainer(ResolverConfig)` 内(mvvm-3) |
| シェル(MainWindow / MainPage) | プロジェクト直下または `Views/` 直下 |

## バリエーションと使い分け

- **プラットフォーム差分はプロバイダのみ**: `UseWindowsNavigationProvider` / `UseAvaloniaNavigationProvider` / `UseMauiNavigationProvider` を差し替える。それ以外の構成・書き方は共通
- **ダイアログ**: MAUI では `[PopupSource]` + `DialogId` で同じ仕組みに乗せる。デスクトップではダイアログは `IDialogService` 等のサービス経由でよい
- **Blazor Hybrid(maui-5)**: Smart.Navigation は使わず、メッセージ駆動(`NavigationManager`)の遷移に置き換える
- **画面遷移のないツール系アプリ**: Navigator を持たず、ウィンドウ管理のみ(wpf-1 の WindowManager)で構成してよい

## アンチパターン

- **ウィンドウを開いて画面遷移の代わりにする** — 画面遷移はシェル内のコンテンツ切替(Smart.Navigation)で行う。子ウィンドウはツール用途に限定する(wpf-1)
- **ID と View のマッピングを手書きで登録する** — 登録漏れ・重複の温床。`[ViewSource]` + `AutoRegister` に統一する
- **画面 ID を文字列や Type で扱う** — タイプミス・リネーム漏れを検出できない。enum に統一する
- **ViewModel が遷移先 View の型を参照する** — View への依存が生まれる。遷移は `ViewId` 経由とする
- **Release ビルドに遷移トレースを残す** — トレースは `#if DEBUG` で囲む
