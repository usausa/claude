# テストの配置・命名

| 項目 | 内容 |
|---|---|
| ID | test-3 |
| 分類 | test |
| 関連 | test-8(テストプロジェクト構成) / test-2(テスト基盤) / structure-3(Analyzers.ruleset) / solution-1(プロジェクト分割) |

## 目的

テストコードの置き場と名前を機械的に決められるようにし、**対象コードからテストへ(またはその逆へ)迷わず辿れる**状態を保つ。

- テストプロジェクトの RootNamespace はテスト対象と同一にし、フォルダ構造は対象をミラーする
- クラス名は `<対象>Test`(`Tests` ではない)
- **テスト名は「対象メソッド + シナリオ + 期待結果」の3部構成を、アンダースコアなしの PascalCase で連結する**

## 標準形

### 配置

```
App.Core/
├─ Domain/
│   └─ SalesLogic.cs
└─ Services/
    └─ DataService.cs

App.UnitTests/
├─ Domain/
│   └─ SalesLogicTest.cs          … RootNamespace = Template(対象と同一)
└─ Services/
    └─ DataServiceTest.cs
```

- csproj の `RootNamespace` を対象プロジェクトと同一にする(test-2 の csproj 例)。テストファイルの namespace 宣言は対象クラスと完全に一致し、using なしで対象を参照できる
- フォルダは対象プロジェクトの構造をミラーする。テスト側にしかないフォルダは `Mocks/`(test-4)等の横断部品のみ
- テストが肥大した場合は partial でファイル分割してよい(`DataServiceTest.cs` + `DataServiceTest.Query.cs` 等)。クラス名は変えない

### テスト名

「対象メソッド + シナリオ + 期待結果」の3部を PascalCase で連結する。

```csharp
public sealed class SalesLogicTest
{
    [Fact]
    public void AddEmptyStringReturnsZero() { ... }        // Add + EmptyString + ReturnsZero

    [Fact]
    public void AddOverflowThrowsException() { ... }        // Add + Overflow + ThrowsException
}

public sealed class AuthEndpointTest
{
    [Fact]
    public async Task DailyAuthorizeFailedReturns403() { ... }   // DailyAuthorize + Failed + Returns403
}
```

- アンダースコアを含まないため、CA1707(識別子にアンダースコアを含めない)の抑止が不要になる
- シナリオ部は入力・状態・条件を表す(`Found` / `NotFound` / `Duplicated` / `EmptyString` / `Failed` 等)。期待結果部は `Returns~` / `Throws~` / `Updates~` 等の動詞句で始める
- 対象メソッドが自明な単純クラス(1メソッドの Logic 等)では対象メソッド部を省略してよいが、3部構成を基本形とする

## 配置ルール

| 対象 | 規約 |
|---|---|
| RootNamespace | テスト対象プロジェクトと同一 |
| フォルダ | 対象プロジェクトの構造をミラー |
| クラス名 | `<対象クラス>Test`(単数形。`Tests` にしない) |
| ファイル分割 | partial 可。`<対象>Test.<区分>.cs` |
| テストメソッド名 | 対象メソッド + シナリオ + 期待結果(PascalCase 連結、アンダースコアなし) |

## バリエーションと使い分け

- **シナリオ結合テスト(test-6)**: 対象構造のミラーではなく `Scenario/` フォルダにシナリオ番号順で置く(`Scenario/01LoginTest.cs` 等)。単体テストの配置規約とは体系が異なる
- **1クラスに複数の対象を寄せない**: ヘルパー的な小クラス群であっても、テストクラスは対象クラスと1対1を保つ

## アンチパターン

- **`<対象>_<シナリオ>_<期待>` のアンダースコア区切り** — CA1707 に反し、全テストで抑止が必要になる。PascalCase 連結に統一する
- **`XxxTests`(複数形)や `TestXxx`(接頭辞)** — 対象からテストクラス名を機械的に導出できなくなる。`<対象>Test` に固定する
- **テスト専用 namespace(`Template.Tests.~`)** — 対象と namespace がずれると using が必要になり、ミラー構造の利点(対比のしやすさ)が失われる
- **`Test1` / `ItWorks` 等の無意味な名前** — 失敗時のテスト名だけで「何がどう壊れたか」が読めることをテスト名の要件とする
