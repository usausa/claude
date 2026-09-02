# Blazor Hybrid への置換

| 項目 | 内容 |
|---|---|
| ID | maui-5 |
| 分類 | maui |
| 関連 | maui-1(MauiProgram) / maui-4(プラットフォーム機能ラッパ) / blazor-3(AppComponentBase) / blazor-5(State 管理) / namespace-7(クライアント側の標準語彙) / mvvm-2(Smart.Navigation — 本構成では不使用) |

## 目的

画面を Web UI(Blazor)で作りたい MAUI アプリの構成を定義する。XAML + Smart.Navigation の構成(mvvm-2 / mvvm-5)を**置換**するバリエーションであり、併用はしない。

- 画面は `Views/` 配下の Razor コンポーネントとし、`Modules/` と Smart.Navigation は使わない
- 画面遷移はメッセージ駆動(`IReactiveMessenger` → `NavigationManager`)に置き換える
- ネイティブ機能(バーコードスキャン・ダイアログ等)は `Interop/` の橋渡し層を介して呼び出す

## 標準形

### MauiProgram — UseBlazor の追加

チェーン形式は maui-1 と同一。`UseBlazor()` が加わり、Navigator の登録が不要になる。

```csharp
private static MauiAppBuilder UseBlazor(this MauiAppBuilder builder)
{
    builder.Services.AddMauiBlazorWebView();
#if DEBUG
    builder.Services.AddBlazorWebViewDeveloperTools();
#endif
    return builder;
}
```

### MainPage — BlazorWebView とネイティブ UI の併存

`MainPage` は BlazorWebView をホストし、ボトムナビゲーション等の常設 UI はネイティブ(XAML)側に残す。

```xml
<ContentPage x:Class="Template.MobileApp.MainPage"
             s:BindingContextResolver.Type="{x:Type local:MainPageViewModel}">

    <Grid RowDefinitions="*,Auto">
        <!-- overlay -->
        <Rectangle Grid.RowSpan="2"
                   shell:ShellProperty.BusyOverlay="True"
                   IsVisible="{Binding BusyState.IsBusy}" />

        <!-- web -->
        <BlazorWebView Grid.Row="0" HostPage="wwwroot/index.html">
            <BlazorWebView.RootComponents>
                <RootComponent ComponentType="{x:Type views:Routes}" Selector="#app" />
            </BlazorWebView.RootComponents>
        </BlazorWebView>

        <!-- bottom navigation(ネイティブ側) -->
        <Grid Grid.Row="1" ColumnDefinitions="*,*,*,*">
            <!-- 各タブは PageCommand + SelectPage パラメータで遷移要求を発行する -->
        </Grid>
    </Grid>

</ContentPage>
```

### 遷移はメッセージ駆動 — SelectPage + PageNavigator

ネイティブ側(ViewModel)は `Messenger.Send(SelectPage.Xxx)` で遷移要求を発行するだけとし、Blazor 側の `PageNavigator` が購読して `NavigationManager.NavigateTo` を呼ぶ。

```csharp
// Views/SelectPage.cs — 画面 ID(ViewId に相当)
public enum SelectPage
{
    Home,
    Search,
    Notifications,
    Account
}
```

```csharp
// Views/Layout/PageNavigator.cs — Blazor 側の購読者
public sealed class PageNavigator : ComponentBase, IDisposable
{
    private IDisposable? subscription;

    [Inject]
    public required IReactiveMessenger Messenger { get; set; }

    [Inject]
    public required NavigationManager NavigationManager { get; set; }

    protected override void OnInitialized()
    {
        subscription = Messenger.Observe<SelectPage>().Subscribe(x =>
        {
            switch (x)
            {
                case SelectPage.Home:
                    NavigationManager.NavigateTo("/");
                    break;
                case SelectPage.Search:
                    NavigationManager.NavigateTo("/search");
                    break;
                // ...
            }
        });
    }

    public void Dispose()
    {
        subscription?.Dispose();
        subscription = null;
    }
}
```

### AppComponentBase — Execute + BusyState

ページ基底は blazor-3 の Hybrid 版。`Execute/ExecuteAsync` で `BusyState` ガード(多重実行防止)を内蔵し、ネイティブ側のオーバーレイと連動する。

```csharp
public abstract class AppComponentBase : ComponentBase, IDisposable
{
    private CompositeDisposable? disposables;

    protected ICollection<IDisposable> Disposables => disposables ??= [];

    [Inject]
    public required IReactiveMessenger Messenger { get; set; }

    [Inject]
    public required IBusyState BusyState { get; set; }

    protected async Task ExecuteAsync(Func<Task> func)
    {
        if (BusyState.IsBusy)
        {
            return;
        }

        using (BusyState.Begin())
        {
            await func().ConfigureAwait(true);
        }
    }

    // 同期版 Execute / パラメータ付き / 戻り値付きのオーバーロードを併設(Dispose パターンは省略)
}
```

### Interop — ネイティブ機能への橋渡し

Blazor 側からネイティブ機能を使う境界は `Interop/` に置く。契約(`IPlatformInterop`)を Razor 側が注入し、実装は MAUI 側のダイアログ(`IPopupNavigator`)等に委譲する。

```csharp
// Interop/IPlatformInterop.cs
public interface IPlatformInterop
{
    ValueTask<string?> ScanBarcodeAsync();

    ValueTask DisplayBarcodeAsync(string barcode);
}

// Interop/PlatformInterop.cs — MAUI 側ダイアログへの委譲
public sealed class PlatformInterop : IPlatformInterop
{
    private readonly IPopupNavigator popupNavigator;

    public PlatformInterop(IPopupNavigator popupNavigator)
    {
        this.popupNavigator = popupNavigator;
    }

    public ValueTask<string?> ScanBarcodeAsync()
    {
        return popupNavigator.PopupAsync<string?>(DialogId.BarcodeScan);
    }

    public ValueTask DisplayBarcodeAsync(string barcode)
    {
        return popupNavigator.PopupAsync(DialogId.BarcodeDisplay, barcode);
    }
}
```

```csharp
// Views/Pages/HomePage.razor.cs — ページからの利用(blazor-4 の code-behind 分離)
public sealed partial class HomePage : AppComponentBase
{
    private string? barcode;

    [Inject]
    public required IPlatformInterop PlatformInterop { get; set; }

    private async Task OnClickScan()
    {
        barcode = await PlatformInterop.ScanBarcodeAsync();
    }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| Razor ページ・レイアウト | `Views/Pages/` / `Views/Layout/`(`.razor` + `.razor.cs` 分離 → blazor-4)。`Modules/` は使わない |
| `AppComponentBase` / `SelectPage` / `ViewHelper・ViewExtensions` | `Views/` 直下 |
| ネイティブ橋渡し | `Interop/`(契約 + 実装)。MAUI 側ダイアログは `Interop/Dialogs/` |
| プラットフォーム機能ラッパ | `Components/`(XAML 構成と共通 → maui-4) |
| `State` / `Services` / `Usecase` | XAML 構成と同一(namespace-7) |

## バリエーションと使い分け

- **XAML 構成(mvvm-2 / mvvm-5)との選択**: リッチな Web UI 資産・Web 系メンバー主体なら Hybrid、デバイス密着の業務端末 UI なら XAML 構成。1アプリ内での混在はさせない
- ページ内の状態はページの private フィールドで保持する(blazor-5 と同方針)。画面間の共有状態は `State/` に置く
- ボトムナビゲーションを Blazor 側で実装し、`MainPage` を BlazorWebView のみにする構成も可(ネイティブ UI との連動が不要な場合)

## アンチパターン

- **Smart.Navigation と Blazor ルーティングの併用** — 遷移体系が二重になる。Hybrid 構成では Navigator を登録しない
- **Razor 側からネイティブ API を直接呼ぶ** — 橋渡しは `Interop/` の契約に集約する。ページはプラットフォームを知らない
- **ネイティブ⇔Blazor の直接参照による連携** — 双方向の連携は `IReactiveMessenger` のメッセージで行い、参照を持ち合わない
- **BusyState ガードなしのボタン連打許容** — I/O を伴う操作は必ず `ExecuteAsync` 経由とし、ネイティブ側オーバーレイで操作を抑止する
