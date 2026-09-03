# Helper セクション方式

| 項目 | 内容 |
|---|---|
| ID | test-5 |
| 分類 | test |
| 関連 | test-1(AAA パターン) / test-4(モック方針) / test-3(partial 分割) / structure-6(区切りコメント) / structure-7(メンバ記述順序) |

## 目的

テストクラスの共通部品(生成ヘルパ)をクラス冒頭の Helper セクションに集約し、**テスト本体を3〜10行に保つ**。

- Arrange の重複(オブジェクト生成・モック組み立て)をファクトリメソッドに寄せ、各テストには「そのテストで意味のある差分」だけを書く
- AAA(test-1)と Helper セクションは階層が異なる: **AAA は各テストメソッド内の区切り、Helper セクションはクラス構造**である。Helper に生成を寄せた上で、テスト本体は AAA で区切る(併用が標準形)
- テストクラスは通常のメンバ順序(structure-7)の例外として、Helper セクションをクラス冒頭に置く

## 標準形

クラス冒頭に `Helper` セクション、以降は機能毎のセクションで区切る(区切りコメントは structure-6 の帯形式)。

```csharp
public sealed class OrderServiceTest
{
    //--------------------------------------------------------------------------------
    // Helper
    //--------------------------------------------------------------------------------

    // 既定値付きパラメータオブジェクト。テスト側は差分のみ指定する
    private static OrderParameter CreateParameter(int quantity = 1, decimal unitPrice = 100m) => new()
    {
        ProductCode = "P-0001",
        Quantity = quantity,
        UnitPrice = unitPrice
    };

    private static OrderService CreateOrderService(IOrderAccessor? accessor = null) =>
        new(accessor ?? Substitute.For<IOrderAccessor>(),
            new DebugLoggerFactory().CreateLogger<OrderService>());

    //--------------------------------------------------------------------------------
    // Calculate
    //--------------------------------------------------------------------------------

    [Fact]
    public void CalculateTotalBulkQuantityReturnsDiscountedPrice()
    {
        // Arrange
        var service = CreateOrderService();

        // Act
        var total = service.CalculateTotal(CreateParameter(quantity: 10));

        // Assert
        Assert.Equal(900m, total);
    }

    //--------------------------------------------------------------------------------
    // Register
    //--------------------------------------------------------------------------------

    [Fact]
    public async Task RegisterOrderSucceededReturnsSuccessStatus()
    {
        // Arrange
        var accessor = Substitute.For<IOrderAccessor>();
        accessor.InsertOrderAsync(Arg.Any<OrderEntity>()).Returns(1);
        var service = CreateOrderService(accessor);

        // Act
        var status = await service.RegisterOrderAsync(CreateParameter());

        // Assert
        Assert.Equal(OrderWriteStatus.Success, status);
    }
}
```

要点:

- **`CreateParameter`(パラメータオブジェクト)**: 既定値は「正常系で通る値」とし、テスト側は optional 引数でシナリオの差分だけを指定する
- **`CreateXxx()` ファクトリ**: テスト対象と依存モックの組み立てを1箇所に集約する。依存を差し替えたいテストだけが引数で渡す(`accessor ?? Substitute.For<...>()` の形)
- **機能セクション**: テストメソッドは対象の機能(メソッド)毎に `//---- Xxx ----` セクションでグルーピングする。セクション名は対象メソッド名に合わせる

## 配置ルール

| 対象 | 場所 |
|---|---|
| Helper セクション | クラス冒頭(structure-7 の順序に対する、テストクラスの例外) |
| ファクトリメソッド | `private static`。状態を持たせない |
| 機能セクション | Helper の後に、対象の機能単位で並べる |
| partial 分割時(test-3) | Helper セクションは主ファイル側に置き、分割ファイルは機能セクションのみ持つ |

## バリエーションと使い分け

- **`IClassFixture` / コンストラクタ初期化**: 全テストで共有する重い初期化(`WebApplicationFactory` 等)は fixture に置き、Helper セクションは「テスト毎に新しく作るもの」の生成に限定する
- **Builder が必要なほど複雑な生成**: optional 引数が増えすぎたら `CreateParameter` を分割する(`CreateBulkParameter` 等、シナリオ名を持つファクトリ)。汎用 Builder パターンまでは持ち込まない
- **小さなテストクラス**: テストが数個で生成も1行なら、Helper セクションを作らずベタ書きでよい。重複が出た時点で昇格する

## アンチパターン

- **Arrange のコピー増殖** — 同じ生成コードが3テストに現れたら Helper へ集約する。生成仕様の変更が全テスト修正になる状態を作らない
- **Helper への閾値なしの押し込み** — テストの意図に関わる値(そのテストが検証する入力)まで Helper の既定値に隠さない。「差分がテスト本体に見える」ことが原則
- **SetUp 的な共有可変状態** — コンストラクタでフィールドにモックを保持し全テストで共有すると、テスト間の独立性が崩れる。ファクトリで毎回生成する
- **Helper セクションの後置** — 末尾に置くと読み手が本体→ヘルパの往復を強いられる。クラス冒頭に固定する(この点がテストクラスを structure-7 の例外とする理由)
