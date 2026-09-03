# State 管理

| 項目 | 内容 |
|---|---|
| ID | blazor-5 |
| 分類 | blazor |
| 関連 | blazor-4(code-behind 分離) / blazor-3(AppComponentBase) / blazor-6(ProgressState) / blazor-2(NavigationManagerExtensions) / namespace-7(クライアントの State) |

## 目的

ページ状態の持ち方を統一する。**ページの状態はページ(code-behind)の private フィールドで保持することを基本とする(決定)**。

- 状態の所在がページ内に閉じ、ライフサイクルがページと一致する
- Scoped な State コンテナ方式は標準としない(明文化しない)。状態共有の仕組みを最初から導入せず、必要が生じた箇所にだけ限定的な手段を選ぶ

## 標準形

ページの状態は `.razor.cs` の private フィールドに置く。プロパティにはしない(バインドは `@bind-Value="field"` でフィールドに直接行える)。

```csharp
public sealed partial class DataPage
{
    // ページ状態(private フィールドで保持)
    private List<DataView>? items;

    private DataView? selected;

    private bool loading = true;

    private string searchText = string.Empty;

    [Inject]
    public required DataService DataService { get; set; }

    protected override async Task OnInitializedAsync()
    {
        items = await DataService.QueryAsync();
        loading = false;
    }

    private async Task OnSelect(DataView item)
    {
        selected = item;
        await LoadDetailAsync(item.Id);
    }
}
```

```razor
<MudTextField @bind-Value="searchText" Label="Search" />

<Condition Value="!loading">
    <MudTable Items="items" />
</Condition>
```

- 状態の変更はイベントハンドラ・ライフサイクルメソッド内で行う。Blazor が再レンダリングを行うため、通常 `StateHasChanged()` の明示呼び出しは不要
- フォーム入力は Form モデル(ページにネスト定義 → blazor-8)に、単発の UI 状態(表示切替フラグ等)は bool フィールドに持つ

## 配置ルール

| 状態の種類 | 置き場 |
|---|---|
| ページ固有の状態(一覧・選択・入力・表示フラグ) | ページの private フィールド(基本形) |
| ブックマーク・リロードで復元したい状態(検索条件・ページ番号等) | URL クエリパラメータ。`[Parameter] + [SupplyParameterFromQuery]` で受け、`UpdateParameter`(blazor-2)で反映 |
| 横断的な UI 状態(プログレス表示等) | レイアウトが `CascadingValue` で配布する専用部品(`ProgressState` → blazor-6) |
| 認証状態 | `AuthenticationStateProvider`(blazor-7)。自前の状態保持を作らない |
| クライアント(Hybrid)の永続的なアプリ状態(セッション・設定・デバイス状態) | `State/` 名前空間のクラス(namespace-7)。ページ状態とは区別する |

## バリエーションと使い分け

- **親子コンポーネント間の共有**: 親のフィールドを `[Parameter]` + `EventCallback` で受け渡す。2〜3階層を超えて配るものだけ `CascadingParameter` を検討する
- **ページを跨いで引き継ぐ値**: 第一選択は URL(ルート・クエリパラメータ)。URL に載らない一時データの受け渡しが必要な場合のみ、限定した Scoped サービスを個別判断で導入する(標準形としては定義しない)
- **Blazor Server の回線切断**: ページ状態は回線と共に消える。失われて困る入力は Form 単位で永続化(下書き保存等)を業務要件として設計する

## アンチパターン

- **Scoped State コンテナの標準装備** — 全ページの状態を汎用コンテナ(Store / StateContainer)に寄せる方式は採らない。状態の生存期間とページの対応が崩れ、破棄・初期化の管理が複雑化する
- **static フィールドでの状態保持** — Blazor Server では全ユーザー・全回線で共有されてしまう。ユーザー状態を static に置かない
- **ページ状態のプロパティ公開** — private フィールドで足りるものを `public` プロパティにしない。公開した時点で外部から変更される契約になる
- **検索条件のフィールド保持のみ** — 一覧の検索条件・ページングをフィールドだけに持つと、リロード・戻る操作で失われる。URL クエリに反映する(blazor-2)
