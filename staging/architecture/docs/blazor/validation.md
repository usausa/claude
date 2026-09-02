# バリデーション(FluentValidation)

| 項目 | 内容 |
|---|---|
| ID | blazor-8 |
| 分類 | blazor |
| 関連 | blazor-4(code-behind 分離) / blazor-7(LoginPage) / namespace-4(Length 定数) / web-3(API 境界の検証) |

## 目的

Blazor のフォーム検証を **FluentValidation + `EditForm` 連携コンポーネント**で構成し、検証ルールの書き方と置き場を統一する。

- 検証ルールは属性(DataAnnotations)ではなく **`InlineValidator<Form>` を `static readonly` で保持**する
- Form クラスは**ページにネスト定義**し、画面入力の形をページに閉じる
- `EditContext` との橋渡しは共通コンポーネント `FluentValidationValidator` が担い、ページは宣言するだけにする

## 標準形

### FluentValidationValidator(EditForm 連携コンポーネント)

`EditContext` の検証イベントを購読し、FluentValidation の結果を `ValidationMessageStore` に反映する共通コンポーネント。全体検証(`OnValidationRequested`)とフィールド単位検証(`OnFieldChanged`)の両方に応答する。

```csharp
public sealed class FluentValidationValidator : ComponentBase, IDisposable
{
    private ValidationMessageStore? messageStore;

    [CascadingParameter]
    private EditContext? EditContext { get; set; }

    [Parameter]
    public IValidator? Validator { get; set; }

    protected override void OnInitialized()
    {
        if (EditContext is null)
        {
            throw new InvalidOperationException($"{nameof(EditContext)} is required.");
        }

        messageStore = new(EditContext);

        EditContext.OnValidationRequested += OnValidationRequested;
        EditContext.OnFieldChanged += OnFieldChanged;
    }

    public void Dispose()
    {
        if (EditContext is not null)
        {
            EditContext.OnValidationRequested -= OnValidationRequested;
            EditContext.OnFieldChanged -= OnFieldChanged;
        }
    }

    // OnValidationRequested → モデル全体を ValidateAsync し messageStore に反映
    // OnFieldChanged → MemberNameValidatorSelector で該当フィールドのみ検証
    // (実装の全体は参考実装を利用する)
}
```

### ページ側の定型(Form ネスト + static readonly InlineValidator)

Form はページにネスト定義し、検証ルールは `InlineValidator<Form>` をコレクション初期化子で組んで `static readonly` に保持する。桁数は Domain の `Length` 定数(namespace-4)を参照する。

```csharp
[AllowAnonymous]
public sealed partial class LoginPage
{
    private static readonly IValidator Validator = new InlineValidator<Form>
    {
        v => v.RuleFor(x => x.Id).NotEmpty().MaximumLength(Length.Id),
        v => v.RuleFor(x => x.Password).NotEmpty().MaximumLength(Length.Password)
    };

    private readonly Form form = new();

    [Inject]
    public required LoginManager LoginManager { get; set; }

    private async Task OnValidSubmit()
    {
        if (!await LoginManager.LoginAsync(form.Id, form.Password))
        {
            // サーバ側判定のエラー表示(バリエーション参照)
        }
    }

    public sealed class Form
    {
        [DisplayName("ID")]
        public string Id { get; set; } = default!;

        [DisplayName("Password")]
        public string Password { get; set; } = default!;
    }
}
```

```razor
<EditForm Model="form" OnValidSubmit="OnValidSubmit">
    <FluentValidationValidator Validator="Validator" />

    <MudTextField @bind-Value="form.Id" For="() => form.Id" MaxLength="Length.Id" Label="ID" />
    <MudTextField @bind-Value="form.Password" For="() => form.Password" MaxLength="Length.Password" Label="Password" />

    <MudButton ButtonType="ButtonType.Submit">Login</MudButton>
</EditForm>
```

- エラーメッセージの表示名は `[DisplayName]` を使い、FluentValidation のグローバル設定(`ValidatorOptions.Global`)で表示名・メッセージのローカライズを一括構成する
- カスケードモードは「クラス間は Continue・ルール内は Stop」を既定にする

```csharp
// Program.cs(起動時に一度だけ)
ValidatorOptions.Global.DefaultClassLevelCascadeMode = CascadeMode.Continue;
ValidatorOptions.Global.DefaultRuleLevelCascadeMode = CascadeMode.Stop;
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| `FluentValidationValidator`(共通コンポーネント) | `Components/Validation/` |
| Form クラス | 使用するページにネスト定義(`public sealed class Form`) |
| 検証ルール(`InlineValidator<Form>`) | 同ページの `static readonly` フィールド |
| 桁数等の定数 | `Domain/Length`(namespace-4)。ルールと `MaxLength` 属性の両方から参照し、二重定義しない |

## バリエーションと使い分け

- **サーバ側判定のエラー表示**: 入力形式は正しいが認証・業務判定で弾かれた場合は、`ValidationMessageStore` を持つ `CustomValidator` コンポーネント(`DisplayError(() => form.Id, message)` / `ClearErrors()`)で該当フィールドにエラーを注入する
- **複数モデルのフォーム**: `FluentValidationValidator` に `Validators`(型 → IValidator の辞書)を渡し、ネストモデル毎の検証を束ねる形に拡張できる
- **専用 Validator クラス**: ルールが大きく再利用されるものは `AbstractValidator<T>` 派生クラスに昇格させてよい。ページ限りのルールは `InlineValidator` のまま保つ
- **API 境界の検証との関係**: 本トピックは画面入力の検証。API の Request 検証は基盤層の Validation(web-3)で行い、Form → Request の変換後に二重の砦とする

## アンチパターン

- **DataAnnotations 属性による検証** — `[Required]` / `[StringLength]` 等の属性方式は条件付きルール・複合ルールで破綻する。検証は FluentValidation に一本化する(`[DisplayName]` 等の表示用属性は使用してよい)
- **Validator のインスタンスをページ毎に生成** — ルールは不変なので `static readonly` で共有する
- **Form クラスの共有・公開** — 画面入力の形はページ固有。Models へ出したり複数ページで共有したりせず、ページにネストする(API へ送る形は別途 `*Request` → web-3)
- **桁数のマジックナンバー** — ルール・入力欄の `MaxLength` に直接数値を書かない。`Length` 定数(namespace-4)に集約する
