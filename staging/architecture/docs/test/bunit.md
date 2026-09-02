# bunit によるコンポーネントテスト

| 項目 | 内容 |
|---|---|
| ID | test-7 |
| 分類 | test |
| 関連 | test-8(テストプロジェクト構成) / test-4(モック方針) / test-1(AAA パターン) / blazor-4(code-behind 分離) |

## 目的

Blazor コンポーネントの描画・イベント処理を、ブラウザなしで **bunit** によりテストする。

- コンポーネントを実レンダリングし、マークアップと状態遷移を検証する(E2E より速く、ロジック単体テストより UI に近い)
- 依存サービスは DI コンテナ経由で NSubstitute / 手書きモック(test-4)に差し替える
- テスト基盤(test-2)・配置命名(test-3)・AAA(test-1)の規約はコンポーネントテストにもそのまま適用する

## 標準形

テストクラスは `BunitContext` を継承し、`Services` に依存を登録して `Render` する。

```csharp
public sealed class DataListPageTest : BunitContext
{
    //--------------------------------------------------------------------------------
    // Helper
    //--------------------------------------------------------------------------------

    private void SetupDataService(params DataView[] views)
    {
        var service = Substitute.For<IDataService>();
        service.QueryDataListAsync().Returns(views.ToList());
        Services.AddSingleton(service);
    }

    //--------------------------------------------------------------------------------
    // Render
    //--------------------------------------------------------------------------------

    [Fact]
    public void DataListPageRenderedShowsRows()
    {
        // Arrange
        SetupDataService(new DataView { Id = 1, Name = "Data-1" }, new DataView { Id = 2, Name = "Data-2" });

        // Act
        var cut = Render<DataListPage>();

        // Assert
        cut.WaitForAssertion(() => Assert.Equal(2, cut.FindAll("tr.data-row").Count));
    }

    [Fact]
    public void DataListPageEmptyShowsNoDataMessage()
    {
        // Arrange
        SetupDataService();

        // Act
        var cut = Render<DataListPage>();

        // Assert
        cut.WaitForAssertion(() => cut.Find(".no-data"));
    }

    //--------------------------------------------------------------------------------
    // Action
    //--------------------------------------------------------------------------------

    [Fact]
    public void DataListPageReloadClickedRequeriesService()
    {
        // Arrange
        SetupDataService();
        var cut = Render<DataListPage>();

        // Act
        cut.Find("button.reload").Click();

        // Assert
        cut.WaitForAssertion(() => _ = Services.GetRequiredService<IDataService>().Received(2).QueryDataListAsync());
    }
}
```

要点:

- **`Render<TComponent>()`** が実レンダリングの起点。パラメータは `Render<DataCard>(static p => p.Add(x => x.Title, "Card-1"))` の形で渡す
- **非同期描画は `WaitForAssertion`** で待つ。`OnInitializedAsync` 完了前のマークアップを直接 Assert しない
- **JS 相互運用**: JS 呼び出しを持つコンポーネントは `JSInterop.Mode = JSRuntimeMode.Loose;`(コンストラクタで設定)で許容するか、`JSInterop.SetupVoid(...)` で個別にスタブする
- 認証 UI は bunit の `AddAuthorization()`(TestAuthorizationContext)でロール・認証状態を設定する

## 配置ルール

| 対象 | 場所 |
|---|---|
| コンポーネントテスト | `<App>.UnitTests`(単体テストの一種として扱う。test-8) |
| フォルダ | 対象の `Components/` / `Pages/` 構造をミラー、クラス名 `<コンポーネント>Test`(test-3) |
| パッケージ | `bunit`(xunit.v3 構成の csproj に追加。test-2) |

## バリエーションと使い分け

| 検証したいもの | 手段 |
|---|---|
| 値→表示の変換ロジック(ViewHelper。blazor-1) | 静的純関数の通常単体テスト(bunit 不要) |
| コンポーネントの描画・イベント・状態遷移 | bunit(本トピック) |
| ブラウザ実挙動・CSS・JS 込みの画面フロー | E2E(Playwright 等。test-8 の任意追加) |

bunit で CSS の見た目やブラウザ固有挙動は検証できない。マークアップ構造と DOM イベントまでを守備範囲とする。

## アンチパターン

- **セレクタでのマークアップ全文比較** — `MarkupMatches` による全文一致はスタイル変更で壊れる。検証対象の要素を `Find` で絞り、意味のある属性・テキストのみ Assert する
- **描画完了を `Task.Delay` で待つ** — 不安定テストの典型。`WaitForAssertion` / `WaitForState` を使う
- **コンポーネント内ロジックの bunit 経由テスト** — 表示に関わらない計算・変換は ViewHelper / Service へ抽出して通常の単体テストにする(blazor-1)。bunit テストは UI の関心事に限定する
- **実サービス登録での描画** — `Services` に実装を登録して DB 依存のテストにしない。依存は test-4 の方針でモック化する
