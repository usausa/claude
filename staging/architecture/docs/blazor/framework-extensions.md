# フレームワーク拡張群

| 項目 | 内容 |
|---|---|
| ID | blazor-2 |
| 分類 | blazor |
| 関連 | blazor-1(ViewHelper / ViewExtensions) / blazor-6(レイアウト・シェル) / blazor-9(UI ライブラリ) / namespace-3(Components と Infrastructure) |

## 目的

Blazor のフレームワーク型・UI ライブラリのサービス型に対する拡張メソッド群を **`Infrastructure` に集約**し、定型操作の書き方をアプリ内で統一する。

- 対象は `IJSRuntime` / `NavigationManager` / `ISnackbar` / `IDialogService` 等、フレームワークと UI ライブラリのサービス型
- razor / code-behind 側は拡張メソッド1行で呼べる状態にし、JS 呼び出し文字列やダイアログパラメータの組み立てを各ページに書かせない
- 値の書式化(blazor-1)とは区別する。ここに置くのは**フレームワーク型への操作**である

## 標準形

型ごとに `<型名>Extensions` の static クラスを1ファイルずつ作る。

### JSRuntimeExtensions

JS 相互運用の呼び出しを名前付きメソッドに固める。JS 関数名の文字列はここに閉じ込める。

```csharp
namespace Template.Infrastructure;

using Microsoft.JSInterop;

public static class JSRuntimeExtensions
{
    public static ValueTask ClickUrl(this IJSRuntime runtime, string url) =>
        runtime.InvokeVoidAsync("clickUrl", url);
}
```

### NavigationManagerExtensions

クエリパラメータの取得・更新の定型を提供する。`UpdateParameter` は履歴を汚さない置換遷移(`replace: true`)で URL にページ状態を反映する。

```csharp
namespace Template.Infrastructure;

using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Extensions.Primitives;

public static class NavigationManagerExtensions
{
    public static Dictionary<string, StringValues> ExtractQuery(this NavigationManager manager)
    {
        var uri = manager.ToAbsoluteUri(manager.Uri);
        return QueryHelpers.ParseQuery(uri.Query);
    }

    public static void UpdateParameter(this NavigationManager navigationManager, string name, int value) =>
        navigationManager.NavigateTo(navigationManager.GetUriWithQueryParameter(name, value), false, true);

    public static void UpdateParameter(this NavigationManager navigationManager, string name, string? value) =>
        navigationManager.NavigateTo(navigationManager.GetUriWithQueryParameter(name, value), false, true);

    // bool / DateTime / DateOnly / decimal / Guid 等、使用する型のオーバーロードを同型で並べる

    public static void UpdateParameters(this NavigationManager navigationManager, IReadOnlyDictionary<string, object?> parameters) =>
        navigationManager.NavigateTo(navigationManager.GetUriWithQueryParameters(parameters), false, true);
}
```

### SnackbarExtensions / DialogServiceExtensions(UI ライブラリのサービス型)

UI ライブラリ(例は MudBlazor。選定は規定しない → blazor-9)の通知・ダイアログ呼び出しを意図名のメソッドに固める。

```csharp
namespace Template.Infrastructure;

public static class SnackbarExtensions
{
    public static Snackbar? AddInfo(this ISnackbar snackbar, string message) =>
        snackbar.Add(message, Severity.Info);

    public static Snackbar? AddSuccess(this ISnackbar snackbar, string message) =>
        snackbar.Add(message, Severity.Success);

    public static Snackbar? AddWarning(this ISnackbar snackbar, string message) =>
        snackbar.Add(message, Severity.Warning);

    public static Snackbar? AddError(this ISnackbar snackbar, string message) =>
        snackbar.Add(message, Severity.Error);
}
```

```csharp
namespace Template.Infrastructure;

public static class DialogServiceExtensions
{
    public static async ValueTask<bool> ShowConfirm(this IDialogService dialog, string title, string message)
    {
        var reference = await dialog.ShowAsync<AppMessageBox>(
            string.Empty,
            new DialogParameters
            {
                { nameof(AppMessageBox.Type), MessageBoxType.Confirm },
                { nameof(AppMessageBox.Title), title },
                { nameof(AppMessageBox.Message), message }
            },
            null);
        var result = await reference.Result;
        return (bool?)result!.Data == true;
    }
}
```

利用側は1行になる。

```csharp
if (!await DialogService.ShowConfirm("Logout", "Are you sure you want to logout ?"))
{
    return;
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| フレームワーク型への拡張(`JSRuntimeExtensions` / `NavigationManagerExtensions` 等) | `Infrastructure/`(namespace-3 の決定。UI コンポーネントではないため `Components` には置かない) |
| UI ライブラリのサービス型への拡張(`SnackbarExtensions` / `DialogServiceExtensions` 等) | `Infrastructure/` |
| 拡張先が使う共通ダイアログコンポーネント(`AppMessageBox` 等) | `Components/`(UI コンポーネント本体のため) |
| razor からの参照 | `_Imports.razor` に `@using Template.Infrastructure` を登録 |

旧世代の参考実装ではこれらが `Components` 配下に置かれているが、移行元の用法として扱う(namespace-3)。

## バリエーションと使い分け

- **値の書式化との境界**: 第一引数がフレームワーク型なら本トピック(`Infrastructure`)、値型・業務モデルなら `ViewExtensions`(blazor-1)
- **JS 側の実装**: `JSRuntimeExtensions` が呼ぶ JS 関数は `wwwroot` のアプリスクリプトに集約し、`eval` による都度組み立ては認証 Cookie 操作(blazor-7)のような限定用途に留める
- **拡張が状態を要する場合**: 拡張メソッドでは表現できないため、通常のサービスクラスとして `Infrastructure`(4点セット → namespace-3)に昇格させる

## アンチパターン

- **ページへの `InvokeVoidAsync` 直書き** — JS 関数名の文字列が各ページに散り、リネーム漏れの温床になる
- **Severity・DialogParameters の都度指定** — 通知の見た目がページごとにぶれる。意図名(`AddSuccess` / `ShowConfirm`)の拡張に固める
- **`Components` への拡張メソッド配置(旧用法)** — Blazor 標準の UI コンポーネント置き場と衝突する(namespace-3)。`Infrastructure` へ移す
- **拡張メソッドへの業務ロジック混入** — ここはフレームワーク操作の定型化のみ。業務フローは Service / Usecase に置く
