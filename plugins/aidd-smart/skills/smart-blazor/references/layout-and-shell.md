# レイアウト・シェル

| 項目 | 内容 |
|---|---|
| ID | blazor-6 |
| 分類 | blazor |
| 関連 | blazor-3(AppComponentBase) / blazor-7(認証 UI) / blazor-2(DialogServiceExtensions) / guideline-1(エラー処理方針) |

## 目的

レイアウト(シェル)にアプリ横断の UI 機構を集約し、各ページには**宣言だけ**を書かせる。

- ページ → シェルへの操作(タイトル・メニュー領域の差し込み)は、シェルが実装するインターフェイスを `CascadingValue` で配布して受け付ける
- 予期せぬ例外は `ErrorBoundary` + `ErrorDispatcher` でシェルが受け、`Error403/404/500` に振り分ける(ページ側では握らない → guideline-1)
- 横断的なプログレス表示は `ProgressState` + `ProgressStateScope`(IDisposable)で提供する

## 標準形

### シェル機能インターフェイスと CascadingValue 配布

シェルへの操作は機能単位のインターフェイス(`ITitleManager` / `IMenuSectionManager` 等)に切り、`MainLayout` が実装して自身を `CascadingValue` で配布する。

```csharp
namespace Template.Components.Shell;

public interface IMenuSectionManager
{
    void SetMenu(RenderFragment? value);
}
```

```csharp
public sealed partial class MainLayout : IMenuSectionManager, IDisposable
{
    private ErrorBoundary? errorBoundary;

    private RenderFragment? menu;

    private Account account = Account.Empty;

    [Inject]
    public required NavigationManager NavigationManager { get; set; }

    [CascadingParameter]
    public required Task<AuthenticationState> AuthenticationState { get; set; }

    protected override async Task OnParametersSetAsync()
    {
        // ナビゲーション毎にエラー状態を復帰させる
        errorBoundary?.Recover();

        account = await AuthenticationState.ToAccount();
    }

    public void SetMenu(RenderFragment? value)
    {
        menu = value;
        StateHasChanged();
    }
}
```

```razor
@inherits LayoutComponentBase

<CascadingValue Value="this">
    <ErrorBoundary @ref="errorBoundary">
        <ChildContent>
            <header>
                @menu
                <!-- 認証表示(AuthorizeView + ログイン/ログアウト → blazor-7) -->
            </header>
            <main>@Body</main>
        </ChildContent>
        <ErrorContent>
            <ErrorDispatcher Exception="context" RecoverRequest="() => errorBoundary?.Recover()" />
        </ErrorContent>
    </ErrorBoundary>
</CascadingValue>
```

ページ側はコンポーネントの宣言でシェルにメニューを差し込む。破棄時に自動で解除される。

```csharp
namespace Template.Components.Shell;

public sealed class MenuSection : ComponentBase, IDisposable
{
    [CascadingParameter]
    public required IMenuSectionManager Manager { get; set; }

    [Parameter]
    public required RenderFragment ChildContent { get; set; }

    protected override void OnInitialized()
    {
        Manager.SetMenu(ChildContent);
    }

    public void Dispose()
    {
        Manager.SetMenu(null);
    }
}
```

```razor
@page "/data"

<MenuSection>
    <MudIconButton Icon="@Icons.Material.Filled.Refresh" OnClick="OnClickReload" />
</MenuSection>
```

### ErrorDispatcher + Error403/404/500

例外の種類からエラーページを選ぶ振り分けコンポーネント。ステータスコードを持つ例外は該当ページへ、それ以外は 500 ページへ(復帰ボタン付き)。

```razor
@if (Exception is HttpStatusException httpStatusException)
{
    if (httpStatusException.StatusCode == 404)
    {
        <Error404 />
    }
    else if (httpStatusException.StatusCode == 403)
    {
        <Error403 />
    }
}
else
{
    <Error500 Exception="Exception" RecoverRequest="RecoverRequest" />
}
```

```csharp
public sealed partial class ErrorDispatcher
{
    [Parameter]
    public Exception? Exception { get; set; }

    [Parameter]
    public EventCallback RecoverRequest { get; set; }
}
```

### ProgressState + ProgressStateScope

横断的なプログレス表示は、状態クラス + using で括る IDisposable スコープの組で提供する。ルート(`App.razor`)で `ProgressView` がルーターを包み、`ProgressState` を `CascadingValue` で配布する。

```csharp
public sealed class ProgressState
{
    public event EventHandler<EventArgs>? StateChanged;

    public bool IsBusy { get; set; }

    public string Message { get; set; } = string.Empty;

    public void RaiseStateChanged()
    {
        StateChanged?.Invoke(this, EventArgs.Empty);
    }
}
```

```csharp
public readonly struct ProgressStateScope : IDisposable
{
    private readonly ProgressState state;

    public ProgressStateScope(ProgressState state, string message = "")
    {
        this.state = state;
        state.IsBusy = true;
        state.Message = message;
        state.RaiseStateChanged();
    }

    public void Dispose()
    {
        state.IsBusy = false;
        state.Message = string.Empty;
        state.RaiseStateChanged();
    }
}
```

利用側は `CascadingParameter` で受けて括るだけ(`Using` / `UsingAsync` 拡張メソッドを併設する)。

```csharp
[CascadingParameter]
public required ProgressState Progress { get; set; }

private async Task OnClickImport()
{
    await Progress.UsingAsync("Importing...", ImportAsync());
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| MainLayout / SimpleLayout(ログイン等の無装飾レイアウト) | `Components/Layout/` |
| シェル機能インターフェイス + MenuSection 等の部品 | `Components/Shell/` |
| ErrorDispatcher + Error403/404/500 | `Components/Shared/` |
| ProgressState / ProgressStateScope / ProgressView | `Components/Shared/Progress/` |

## バリエーションと使い分け

- **タイトル管理**: ページタイトルは標準の `<PageTitle>` で足りる。ヘッダ表示等シェル側の表示も変える場合に `ITitleManager` を同じ配布方式で追加する
- **レイアウトの使い分け**: 認証前・エラー表示は `SimpleLayout`(装飾なし)、通常ページは `MainLayout`。`@layout` で切り替える
- **Hybrid のシェル**: Blazor Hybrid では遷移がメッセージ駆動になる(`PageNavigator` が `Messenger` を購読して `NavigationManager.NavigateTo` → maui-5)。レイアウト構造自体は本トピックと同じ

## アンチパターン

- **ページから Layout 型への直接キャスト・参照** — ページはシェルの実装型を知らない。機能インターフェイス経由でのみ操作する
- **ページ毎の try/catch による例外画面遷移** — 予期せぬ例外はシェルの `ErrorBoundary` に任せる(guideline-1)。ページで握るのは業務上ハンドリングできるもののみ
- **`ErrorBoundary` の Recover 忘れ** — ナビゲーション時に `Recover()` を呼ばないと、一度エラーになったシェルがエラー表示のまま固定される
- **プログレス表示のページ個別実装** — ページ毎のオーバーレイ実装は見た目・挙動がぶれる。`ProgressState` のスコープで統一する
