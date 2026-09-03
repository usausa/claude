# モック方針

| 項目 | 内容 |
|---|---|
| ID | test-4 |
| 分類 | test |
| 関連 | test-5(Helper セクション方式) / test-6(サービス差し替え) / test-3(配置・命名) / structure-5(GlobalUsing) |

## 目的

モックの作り方を用途別に固定し、テスト毎に流儀が揺れることを防ぐ。

- 汎用モックは **NSubstitute** を使用する(**Moq は使用しない**)
- 振る舞い(状態・記録)を持つモックは NSubstitute で組み立てず、**手書きの `MockXxx` クラス**にする
- DB は **Usa.Smart.Mock.Data**(`MockDbConnection`)、ロガーは何もしない **`DebugLoggerFactory`** を使う
- **共有モックの名前空間は `Mocks` とする**(`Mocks/` フォルダ + GlobalUsing 登録)

## 標準形

### NSubstitute(戻り値の設定と呼び出し検証)

依存インターフェースの戻り値を固定するだけの用途は NSubstitute で完結させる。

```csharp
[Fact]
public async Task ListFilesReturnsStorageEntries()
{
    // Arrange
    var storage = Substitute.For<IStorage>();
    storage.ListAsync("data").Returns(["data/1.txt", "data/2.txt"]);
    var service = new FileService(storage);

    // Act
    var list = await service.ListFilesAsync("data");

    // Assert
    Assert.Equal(2, list.Count);
    await storage.Received(1).ListAsync("data");
}
```

なお、アクセサ(data-1)はソースジェネレータ生成の `sealed class` でありインターフェースモックの対象にしない。DB 境界のテストは `MockDbConnection`(後述)で行う。

### 手書きモック(振る舞いを持つもの)

呼び出し順序・蓄積状態・逐次応答などの振る舞いが必要なモックは、手書きの `sealed class MockXxx` にする。設定用の `SetupXxx` メソッドを持たせ、テスト本体からは宣言的に使う。

```csharp
namespace Template.Mocks;

public sealed class MockDataStorage : IDataStorage
{
    private readonly Queue<byte[]> readResults = new();

    public List<string> SavedKeys { get; } = [];

    // 次の Read が返す内容を積む
    public void SetupRead(byte[] value) => readResults.Enqueue(value);

    public ValueTask<byte[]> ReadAsync(string key, CancellationToken cancellationToken = default) =>
        ValueTask.FromResult(readResults.Dequeue());

    public ValueTask WriteAsync(string key, byte[] value, CancellationToken cancellationToken = default)
    {
        SavedKeys.Add(key);
        return ValueTask.CompletedTask;
    }
}
```

- テストクラス内でしか使わないものは `private sealed class MockXxx` としてネスト定義(structure-7 の⑧)、複数のテストクラスで共有するものは `Mocks/` フォルダへ昇格させる

### Usa.Smart.Mock.Data(DB アクセス)

Accessor / DAO 層のテストは `MockDbConnection` に列定義と行データを積んで実行する。実 DB を立てない。

```csharp
[Fact]
public async Task QueryDataListReturnsAllRows()
{
    // Arrange
    var con = new MockDbConnection();
    con.SetupCommand(static cmd => cmd.SetupResult(new MockDataReader(
        [new MockColumn(typeof(long), "Id"), new MockColumn(typeof(string), "Name")],
        [[1L, "Data-1"], [2L, "Data-2"]])));
    var accessor = CreateDataAccessor(con);

    // Act
    var list = await accessor.QueryDataListAsync();

    // Assert
    Assert.Equal(2, list.Count);
}
```

### ロガー

ロガーは検証対象にしない。何もしない(Debug 出力のみの)`DebugLoggerFactory` を `Mocks/` に置き、全テストで共有する。

```csharp
namespace Template.Mocks;

public sealed class DebugLoggerFactory : ILoggerFactory
{
    public void AddProvider(ILoggerProvider provider)
    {
    }

    public ILogger CreateLogger(string categoryName) => new DebugLogger(categoryName);

    public void Dispose()
    {
    }

    private sealed class DebugLogger : ILogger
    {
        private readonly string name;

        public DebugLogger(string name)
        {
            this.name = name;
        }

        public IDisposable? BeginScope<TState>(TState state)
            where TState : notnull => null;

        public bool IsEnabled(LogLevel logLevel) => true;

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter) =>
            System.Diagnostics.Debug.WriteLine($"{logLevel} {name} {formatter(state, exception)}");
    }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| 共有モック | `Mocks/` フォルダ、名前空間 `<RootNamespace>.Mocks` |
| GlobalUsing | `global using Template.Mocks;` をテストプロジェクトの GlobalUsing.cs に追加(structure-5) |
| クラス内専用モック | テストクラス末尾に `private sealed class MockXxx` をネスト定義 |

## バリエーションと使い分け

| 用途 | 手段 |
|---|---|
| 戻り値の固定・呼び出し検証のみ | NSubstitute |
| 状態・記録・逐次応答などの振る舞い | 手書き `MockXxx` |
| DB(ADO.NET 境界) | Usa.Smart.Mock.Data(`MockDbConnection`) |
| ロガー | `DebugLoggerFactory`(検証しない) |
| 時刻 | `TimeProvider` 注入 + 固定 TimeProvider(test-6 の `StaticTimeProvider`) |

NSubstitute で `When..Do` やコールバックを重ねて振る舞いを再現し始めたら、手書きモックへ切り替えるサイン。

## アンチパターン

- **Moq の使用** — ライブラリは NSubstitute に統一する。混在はテストコードの読み方を二重にする
- **NSubstitute での振る舞い再現** — コールバックの積み重ねはテストの Arrange を膨らませ、モック自身の正しさが読めなくなる。振る舞いは手書きモックのコードとして表現する
- **ロガー呼び出しの検証** — ログはテストの関心事にしない。ログ出力を仕様として検証したくなったら、それは戻り値・状態で表現すべきもの
- **共有モックの野良配置** — 共有するモックを個別テストファイル内に残さない。`Mocks/` へ昇格し名前空間 `Mocks` に置く
- **実 DB・実ファイルシステム依存の単体テスト** — 単体テストは Usa.Smart.Mock.Data / 手書きモックで閉じる。実インフラを使う検証は結合テスト(test-6、test-8)へ
