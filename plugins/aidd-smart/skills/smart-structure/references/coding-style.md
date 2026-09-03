# コーディングスタイル(.editorconfig)

| 項目 | 内容 |
|---|---|
| ID | structure-6 |
| 分類 | structure |
| 関連 | structure-1(.sln.DotSettings) / structure-2(EnforceCodeStyleInBuild) / structure-3(SA1101・SA1121) / structure-5(GlobalUsing.cs) / structure-7(メンバ順序) |

## 目的

コーディングスタイルを**.editorconfig に機械可読な形で定義し、スタイルの指摘と判断を人手からツールへ移す**。

- `EnforceCodeStyleInBuild`(structure-2)により、スタイル違反はビルド警告として検出される(警告ゼロが規約 → structure-1)
- **.editorconfig は本リポジトリ版を正典として統一する**。各リポジトリへ同一内容を配布し、リポジトリ固有の改変は行わない

## 標準形

スタイルの全量は .editorconfig 本体が定義する。ここでは方針を特徴付ける主要ルールを挙げる。

### file-scoped namespace + using は namespace の内側

```ini
csharp_style_namespace_declarations = file_scoped:warning
csharp_using_directive_placement = inside_namespace:warning
dotnet_separate_import_directive_groups = true:warning
dotnet_sort_system_directives_first = true:warning
```

```csharp
namespace Template.ApiServer.Services;

using System.Text.Json;

using Template.ApiServer.Models;

public sealed class ProfileService
{
}
```

- ファイルは namespace 宣言で始まり、ファイル固有の using をその内側に置く(プロジェクト共通の using は GlobalUsing.cs → structure-5)
- using は System 系を先頭に、グループ間を空行で区切る

### sealed 徹底

継承を前提としない型はすべて `sealed` とする。`AnalysisMode=All`(structure-2)の CA1852 が internal 型の閉じ忘れを検出する。

### インスタンスフィールドの命名

`_` プレフィックスは使わず camelCase とする(規約 → structure-1。検査は .sln.DotSettings の命名規則)。参照時の `this.` も付けない(SA1101 無効 → structure-3)。`this.` を書くのはコンストラクタ代入等で引数と同名になる場合のみとする。

```csharp
public sealed class ProfileService
{
    private readonly IProfileRepository repository;

    public ProfileService(IProfileRepository repository)
    {
        this.repository = repository;
    }
}
```

### 区切りコメント2種

```csharp
// Cache
builder.Services.AddMemoryCache();
```

```csharp
//--------------------------------------------------------------------------------
// Helper
//--------------------------------------------------------------------------------
```

- **1行形式(`// Xxx`)**: 数行のかたまりに前置する小見出し。DI 登録列(host-4)や設定の列挙で多用する
- **帯形式(`//----` 80桁罫線)**: クラス内の大きなセクション区切り。メンバのグルーピングに使う(structure-7)

### ラムダ・ローカル関数への static 付与

```ini
csharp_prefer_static_anonymous_function = true:warning
csharp_prefer_static_local_function = true:warning
```

```csharp
builder.Services.Configure<RouteOptions>(static options =>
{
    options.AppendTrailingSlash = true;
});
```

キャプチャしないラムダには `static` を付け、意図しないキャプチャの混入を防ぐ。

### その他の代表的な方針

- `var` を全面使用する(`csharp_style_var_*` 系はすべて `true:warning`)
- 宣言は言語キーワード(`int` / `string`)、静的メンバ参照は CLR 型名(`Int32.MaxValue` / `String.IsNullOrEmpty`)を許容する(`dotnet_style_predefined_type_for_member_access = false`。SA1121 無効 → structure-3)
- 連続する空行は禁止する(`dotnet_style_allow_multiple_blank_lines_experimental = false`)

## 配置ルール

| 対象 | 場所 |
|---|---|
| .editorconfig | ルート直下に1ファイル(`root = true`)。Solution Items に登録(structure-1) |
| IDE 固有の補完設定 | `<ソリューション名>.sln.DotSettings`(structure-1) |
| XAML フォーマット | Settings.XamlStyler(XAML 系のみ → structure-1) |

インデントはファイル種別セクションで定義する(cs / razor / xaml = 4、csproj / props / json / xml = 2、sln = tab)。

## バリエーションと使い分け

- バリエーションは設けない。**スタイルはソリューション・リポジトリを越えて同一とする**のがこのトピックの主旨である
- ルール自体の変更が必要になった場合は正典側を更新し、各リポジトリへ再配布する(個別リポジトリでの先行改変をしない)

## アンチパターン

- **リポジトリ個別の .editorconfig 改変** — 正典から乖離した亜種が生まれ、リポジトリ間でスタイルが割れる
- **`_` プレフィックス付きフィールド** — 規約違反(structure-1)。命名検査にも掛かる
- **using をファイル先頭(namespace の外)に置く** — `csharp_using_directive_placement` 違反。テンプレート生成コードは取り込み時に修正する
- **スタイル指摘の人力レビュー** — .editorconfig で表現できる指摘はルール化する。レビューは設計と意図の確認に使う
- **severity 緩和による回避** — 警告が出た箇所を直すのが原則。ルール側に問題があるなら正典の変更として提起する
