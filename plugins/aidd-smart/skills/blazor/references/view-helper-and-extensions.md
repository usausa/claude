# ViewHelper と ViewExtensions

| 項目 | 内容 |
|---|---|
| ID | blazor-1 |
| 分類 | blazor |
| 関連 | blazor-2(フレームワーク拡張群) / blazor-9(UI ライブラリ) / namespace-3(Components と Infrastructure) / structure-6(区切りコメント) |

## 目的

razor マークアップから呼ぶ「値 → 表示」の変換ロジックの置き場を **`ViewHelper` と `ViewExtensions` の2ファイルに固定**し、razor 内に書式化式・三項演算子が散らばるのを防ぐ。

- `ViewHelper` = 表示を**選択・生成**する静的純関数。`_Imports.razor` で `@using static` し、razor からクラス名なしの裸の関数として呼ぶ
- `ViewExtensions` = 値の**書式化**の拡張メソッド。`値.Method()` の後置形で読ませる
- razor 側は「何を表示するか」だけを書き、「どう変換するか」は C# 側に寄せる

## 標準形

### ViewHelper(静的純関数 + ラムダ型推論補助)

```csharp
namespace Template.Components;

public static class ViewHelper
{
    // --------------------------------------------------------------------------------
    // Functions
    // --------------------------------------------------------------------------------

    // ラムダの型推論補助。コンポーネントパラメータに渡すラムダを簡潔に書くために使う
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Func<T, bool> FilterBy<T>(Func<T, bool> func) => func;

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Func<T, object?> SortBy<T>(Func<T, object?> func) => func;

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Func<T, string> TextBy<T>(Func<T, string> func) => func;

    // --------------------------------------------------------------------------------
    // Switch
    // --------------------------------------------------------------------------------

    // UI 状態 → 表示属性の選択(例は MudBlazor の場合。UI ライブラリは規定しない → blazor-9)
    public static Variant SelectedVariant(bool value) =>
        value ? Variant.Filled : Variant.Outlined;

    public static InputType PasswordInputType(bool visible) =>
        visible ? InputType.Text : InputType.Password;

    public static string PasswordInputIcon(bool visible) =>
        visible ? Icons.Material.Filled.VisibilityOff : Icons.Material.Filled.Visibility;
}
```

`_Imports.razor` に `@using static` を登録し、razor からは裸で呼ぶ。

```razor
@using Template.Components
@using static Template.Components.ViewHelper
```

```razor
<MudTextField InputType="PasswordInputType(passwordVisible)"
              AdornmentIcon="@PasswordInputIcon(passwordVisible)" />

<MudTable Filter="FilterBy<DataView>(x => x.Name.Contains(searchText))" />
```

### ViewExtensions(書式化の拡張メソッド)

```csharp
namespace Template.Components;

public static class ViewExtensions
{
    public static string Then(this bool value, string text) =>
        value ? text : string.Empty;

    public static string DateTime(this DateTime value) =>
        value.ToString("MM/dd HH:mm:ss", CultureInfo.InvariantCulture);
}
```

```razor
<td>@entry.Timestamp.DateTime()</td>
<tr class="@entry.IsError.Then("row-error")">
```

## 境界基準(どちらに置くか)

「razor 上でどう読ませたいか」で決める。

| 観点 | ViewHelper | ViewExtensions |
|---|---|---|
| 呼び出し形 | 関数形 `Xxx(値)` | 後置形 `値.Xxx()` |
| 役割 | UI 状態から表示属性(アイコン・色・Variant 等)を**選択・生成**する | 単一の値そのものを**書式化**する |
| 引数 | bool フラグ・enum・複数引数の組み合わせ | 拡張対象の値のみ(+書式指定程度) |
| 典型例 | `PasswordInputType(visible)` / `FilterBy<T>(...)` | `value.DateTime()` / `flag.Then("css-class")` |

- 迷った場合、**第一引数の型に対する自然な操作として読めるなら `ViewExtensions`**、そうでなければ `ViewHelper`
- ラムダ型推論補助(`FilterBy<T>` / `SortBy<T>` / `TextBy<T>`)は拡張メソッドにできないため常に `ViewHelper`
- どちらも**静的純関数に限定**する。DI・I/O・状態を要するものはここには置かない(フレームワーク型への拡張は blazor-2 へ)

## 配置ルール

| 対象 | 場所 |
|---|---|
| ViewHelper.cs / ViewExtensions.cs | UI コンポーネントのルート直下(`Components/`。Blazor Hybrid では `Views/` → maui-5)に各1ファイル |
| `@using static` の登録 | `_Imports.razor` |
| フレームワーク型(IJSRuntime / NavigationManager 等)への拡張 | `Infrastructure`(blazor-2)。ViewHelper / ViewExtensions には置かない |

## アンチパターン

- **razor への書式化式の直書き** — `@(value ? "A" : "B")` や `ToString(...)` がマークアップ中に増殖する。2箇所以上で使う変換は必ず ViewHelper / ViewExtensions に出す
- **ViewHelper への状態・依存の持ち込み** — DI 注入・I/O・キャッシュを持った時点で純関数ではない。Service か Infrastructure の部品にする
- **ViewExtensions への業務判定の混入** — 「この値のときは警告表示」といった業務ルールは Domain のロジック(namespace-4)に置き、View 側は結果の書式化のみを担う
- **`@using static` を使わずクラス名で呼ぶ** — `ViewHelper.PasswordInputType(...)` はマークアップの雑音になる。`_Imports.razor` に登録して裸で呼ぶ
