# AAA パターン

| 項目 | 内容 |
|---|---|
| ID | test-1 |
| 分類 | test |
| 関連 | test-3(配置・命名) / test-5(Helper セクション方式) / structure-6(区切りコメント) |

## 目的

すべてのテストを **AAA(`// Arrange` / `// Act` / `// Assert`)パターンで記述する**ことを規約とする。

- どのテストを開いても「準備」「実行」「検証」の3段が同じ形で現れ、テストの意図を読む速度が一定になる
- 1テスト=1シナリオの構造が強制され、複数の Act が混在する肥大テストを構造的に防ぐ
- AAA コメントは**区切り行**であり、処理内容の説明ではない。処理内容に関する和文コメントは区切りとは別に記述する

## 標準形

各テストメソッドの本文を `// Arrange` / `// Act` / `// Assert` の3コメントで区切る(`CreateProvider` は Helper セクションのファクトリ → test-5)。

```csharp
[Fact]
public async Task CountAsyncReturnsScalar()
{
    // Arrange
    await using var con = new MockDbConnection();
    con.SetupCommand(static cmd => cmd.SetupResult(3));
    await using var provider = CreateProvider(con);
    var service = provider.GetRequiredService<DataService>();

    // Act
    var count = await service.CountAsync(null);

    // Assert
    Assert.Equal(3, count);
}
```

- 各セクションの前は空行で区切る(コメント行自体が視覚的な区切りになる)
- Arrange が不要なほど単純な場合でも、`// Act` / `// Assert` の区切りは維持する

### AAA コメントと和文コメントの分離

AAA コメントの行にシナリオ説明を書き足さない。説明が必要な行には、和文コメントを対象行の直前に別途書く。

```csharp
[Fact]
public async Task UpdateAsyncWithoutAffectedRowsReturnsNotFound()
{
    // Arrange
    await using var con = new MockDbConnection();
    // 影響行数 0(対象行なし)を模擬する
    con.SetupCommand(static cmd => cmd.SetupResult(0));
    await using var provider = CreateProvider(con);
    var service = provider.GetRequiredService<DataService>();

    // Act
    var result = await service.UpdateAsync(1, "name", 100);

    // Assert
    Assert.Equal(DataWriteStatus.NotFound, result);
}
```

## バリエーションと使い分け

- **例外検証(`Assert.Throws` 系)**: Act と Assert が1式に融合するため、`// Act & Assert` の1コメントにまとめてよい

```csharp
[Fact]
public void CreateContextInvalidNameThrowsArgumentException()
{
    // Arrange
    var factory = new ContextFactory();

    // Act & Assert
    Assert.Throws<ArgumentException>(() => factory.Create(string.Empty));
}
```

- **Theory によるパラメタライズ**: 入力バリエーションは `[Theory]` + `[InlineData]` に寄せ、本文は単一の AAA を保つ。入力毎に分岐する本文を書かない
- **共通の準備処理**: Arrange が複数テストで重複する場合は、Arrange をコピーして育てるのではなく Helper セクションのファクトリ(test-5)へ集約する。AAA は**各テストメソッド内の区切り**、Helper セクションは**クラス構造**であり、両者は階層が異なる(併用が標準形)

## アンチパターン

- **AAA コメントの省略** — 区切りのないテストは準備と検証の境界を読み手が推測することになる。3行(または例外系の2行)を必ず書く
- **AAA コメントへの説明の同居** — `// Arrange - ユーザを準備` のような書き方をしない。区切り行は固定文言とし、説明は別の和文コメントに書く
- **複数の Act** — 1テストに Act → Assert → Act → Assert を繰り返さない。シナリオが複数あるならテストメソッドを分ける(連続した状態遷移の検証はシナリオ結合テスト test-6 の領分)
- **Assert のない(または Act に混ざった)検証** — モックの呼び出し検証(`Received()` 等)も Assert セクションに置く
