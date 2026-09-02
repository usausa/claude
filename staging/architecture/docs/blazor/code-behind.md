# code-behind 分離

| 項目 | 内容 |
|---|---|
| ID | blazor-4 |
| 分類 | blazor |
| 関連 | structure-7(メンバ記述順序) / blazor-3(AppComponentBase) / blazor-5(State 管理) / blazor-8(バリデーション) |

## 目的

razor コンポーネントは **`.razor`(マークアップ)+ `.razor.cs`(partial クラス)の分離を必須**とし、マークアップとロジックの置き場を固定する。

- `.razor` にはマークアップと表示式のみを書き、`@code` ブロックは使わない
- ロジック・状態・DI はすべて `.razor.cs` 側に置く
- 依存の注入は `[Inject] public required T X { get; set; }` の形に統一する

## 標準形

### ファイル構成

```
Components/Pages/
├─ DataPage.razor      # マークアップのみ
└─ DataPage.razor.cs   # sealed partial クラス
```

### .razor.cs の定型

クラスは `sealed partial`。`[Inject]` は `public required` プロパティで受ける(コンストラクタは書かない)。

```csharp
namespace Template.Components.Pages;

public sealed partial class DataPage
{
    private List<DataView>? items;

    private bool loading = true;

    [Inject]
    public required DataService DataService { get; set; }

    [Inject]
    public required NavigationManager NavigationManager { get; set; }

    [Parameter]
    public int? Filter { get; set; }

    protected override async Task OnInitializedAsync()
    {
        items = await DataService.QueryAsync(Filter);
        loading = false;
    }

    private void OnSelect(DataView item)
    {
        NavigationManager.NavigateTo($"/data/{item.Id}");
    }
}
```

```razor
@page "/data"
@inherits AppComponentBase

<PageTitle>Data</PageTitle>

<Condition Value="!loading">
    ...
</Condition>
```

## 配置ルール

| 対象 | 扱い |
|---|---|
| マークアップ | `.razor`。ロジックは持たない(表示式・ループ・条件分岐まで) |
| ロジック・状態・DI | `.razor.cs` の `sealed partial` クラス |
| `@code` ブロック | 使用しない |
| DI の受け口 | `[Inject] public required T X { get; set; }` |
| ルートパラメータ・親からの入力 | `[Parameter]` / `[CascadingParameter]` プロパティ |

## メンバの記述順序

ビハインド内のメンバ順序は汎用のメンバ記述順序ガイドライン **structure-7(docs/structure/member-order.md)に従う**。Blazor では次の対応になる。

- private フィールド(ページ状態 → blazor-5)は②フィールド
- `[Inject]` → `[Parameter]` / `[CascadingParameter]` の順で④プロパティ
- `OnInitialized(Async)` / `OnParametersSet(Async)` / `OnAfterRender(Async)` / `Dispose` は⑥ライフサイクル
- イベントハンドラ(`OnClickXxx` 等)とヘルパーは⑦メソッド群として処理の種類単位にまとめる

参考実装には、ビハインドを `//----` 帯で `State → Data → Parameter → Lifecycle → Action → Helper` と区切る節構造が見られる。

```csharp
public sealed partial class DataPage
{
    //--------------------------------------------------------------------------------
    // State
    //--------------------------------------------------------------------------------

    private List<DataView>? items;
    private bool loading = true;

    //--------------------------------------------------------------------------------
    // Parameter
    //--------------------------------------------------------------------------------

    [Inject]
    public required DataService DataService { get; set; }

    //--------------------------------------------------------------------------------
    // Lifecycle
    //--------------------------------------------------------------------------------

    protected override async Task OnInitializedAsync() { ... }

    //--------------------------------------------------------------------------------
    // Action
    //--------------------------------------------------------------------------------

    private async Task OnClickReload() { ... }

    //--------------------------------------------------------------------------------
    // Helper
    //--------------------------------------------------------------------------------

    private static string FormatValue(double value) => ...;
}
```

**この節コメントの固定順は規約にはしない(参考パターン)**。structure-7 の順序と矛盾しない範囲で、大きなページの可読性向上に任意採用してよい。小さなページでは節を切らずに structure-7 の順序で並べれば十分である。

## バリエーションと使い分け

- **CSS 分離**: コンポーネント固有のスタイルは `.razor.css`(CSS isolation)を併置してよい。3ファイル1組(`.razor` / `.razor.cs` / `.razor.css`)になる
- **ロジックを持たないコンポーネント**: `ErrorDispatcher` のように `[Parameter]` 数個だけでも `.razor.cs` を作り、分離を崩さない
- **razor を持たないコンポーネント**: `RenderFragment` 制御のみの部品(`MenuSection` → blazor-6)は `.cs` 単独の `ComponentBase` 継承クラスでよい

## アンチパターン

- **`@code` ブロックへのロジック記述** — マークアップとロジックが同一ファイルで混ざり、diff・レビューの単位が崩れる。`.razor.cs` に出す
- **`[Inject] private T X { get; set; }`** — private + null 許容(または `= default!`)の組み合わせは required の検査が効かない。`public required` に統一する
- **コンストラクタインジェクション** — razor コンポーネントはフレームワークが生成するため、依存は `[Inject]` プロパティで受ける
- **節コメント順の規約化** — `State → Data → ...` の固定順をレビューで強制しない。順序の根拠は structure-7 に一本化する
