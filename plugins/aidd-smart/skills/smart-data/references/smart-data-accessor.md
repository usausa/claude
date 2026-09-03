# Smart.Data.Accessor

| 項目 | 内容 |
|---|---|
| ID | data-1 |
| 分類 | data |
| 関連 | data-2(2-way SQL 外部ファイル) / data-3(接続・方言・トレース) / namespace-1(`Accessors`) / namespace-5(モデルサフィックス) / guideline-2(非同期作法) |

## 目的

データアクセス層は Smart.Data.Accessor で構築する。

- **partial class + 属性 + 外部 SQL の宣言だけでアクセサが完成する**(partial 実装はソースジェネレータが生成し、手書きしない)
- 接続の開閉・コマンド組み立て・パラメータバインド・マッピングのボイラープレートを書かない
- SQL は外部ファイル(data-2)に置き、C# 側は型付きのシグネチャのみを持つ

## 標準形

### アクセサクラス

`Accessors/` に `[DataAccessor]` を付けた **`sealed partial class`** を宣言し、メソッドを `public partial` で宣言する。実装(partial 実装部)はソースジェネレータが生成する。

```csharp
namespace Template.Accessors;

using Template.Models.Entity;

[DataAccessor]
public sealed partial class DataAccessor
{
    [Execute]
    public partial void Create();

    [ExecuteScalar]
    public partial ValueTask<int> CountAsync(string? name);

    [Query]
    public partial ValueTask<List<DataEntity>> QueryPageAsync(string? name, int offset, int size);

    [QueryFirst]
    public partial ValueTask<DataEntity?> QueryAsync(long id);

    [ExecuteScalar]
    public partial ValueTask<long> InsertAsync(string name, int value, DateTime createdAt);

    [Execute]
    public partial ValueTask<int> UpdateAsync(long id, string name, int value);

    [Execute]
    public partial ValueTask<int> DeleteAsync(long id);
}
```

### 属性の使い分け

| 属性 | 用途 | 戻り値の型 |
|---|---|---|
| `[Query]` | 複数行の SELECT | `ValueTask<List<T>>` / `IAsyncEnumerable<T>` |
| `[QueryFirst]` | 1行取得(存在しない場合は null) | `ValueTask<T?>` |
| `[ExecuteScalar]` | スカラ値(COUNT・採番値の取得) | `ValueTask<int>` / `ValueTask<long>` 等 |
| `[Execute]` | INSERT / UPDATE / DELETE / DDL | `ValueTask<int>`(影響行数) |
| `[Insert]` | エンティティ挿入(SQL 自動生成) | `ValueTask` |

### DI 登録と Service からの利用

アクセサはアセンブリ単位で一括 DI 登録し(`AddDataAccessors`)、Service は**アクセサクラスを直接コンストラクタで受ける**。

```csharp
// Data(ホスト側の登録。接続構成は data-3)
builder.Services.AddDataAccessors(typeof(DataAccessor).Assembly);
```

```csharp
namespace Template.Services;

using Template.Accessors;
using Template.Models.Entity;

public sealed class DataService
{
    private readonly DataAccessor dataAccessor;

    public DataService(DataAccessor dataAccessor)
    {
        this.dataAccessor = dataAccessor;
    }

    public ValueTask<DataEntity?> QueryAsync(long id) =>
        dataAccessor.QueryAsync(id);

    public ValueTask<List<DataEntity>> QueryPageAsync(string? name, int offset, int size) =>
        dataAccessor.QueryPageAsync(name, offset, size);
}
```

### 戻り値の型

- 非同期メソッドの戻り値は `ValueTask` を基本とする(guideline-2)
- 一覧は `ValueTask<List<T>>`。大量データを逐次処理する場合のみ `IAsyncEnumerable<T>` を使う

```csharp
[Query]
IAsyncEnumerable<DataEntity> QueryAllAsync();
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| アクセサクラス | `Accessors/`(複数形。namespace-1) |
| SQL ファイル | `Accessors/Sql/<クラス名>.<メソッド名>.sql`(data-2) |
| 結果エンティティ | `Models/Entity` の `*Entity`、SELECT 結果専用は `*View`(namespace-5) |
| SQL 引数オブジェクト | `Models/Parameter` の `*Parameter`(namespace-5) |
| DI 登録・接続構成 | ホスト側の `AddDataAccessors()` + `IDbProvider`(data-3) |

## バリエーションと使い分け

- 引数が多い検索条件は個別引数ではなく `*Parameter` クラス(namespace-5)にまとめて受ける
- テーブル1本の CRUD はエンティティ + `[Insert]` 等の SQL 自動生成で済ませ、SELECT や複雑な更新のみ外部 SQL(data-2)を書く
- 同期メソッド(`void` / `int` 戻り)はテーブル生成などの起動時処理に限定し、業務処理は非同期とする
- **旧世代(2.x)の形**: `[DataAccessor]` interface を宣言し(実装は実行時生成)、`IAccessorResolver<T>` を注入してコンストラクタで `.Accessor` を取り出して保持する。1行取得の属性は `[QueryFirstOrDefault]`。移行元として扱い、新規はソースジェネレータ方式(3.x)とする

## アンチパターン

- アクセサの実装を手書きする — 宣言と SQL だけで完結させる。手続きが必要な処理は Service 側に置く
- ADO.NET / 生 SQL 文字列の直書きが Service に散在する — データアクセスの入口をアクセサに一本化する
- アクセサに業務判断を持たせる — 分岐・組み合わせは Service / Usecase(namespace-6)の仕事。アクセサは SQL 実行の型付き境界に徹する
- 一覧を `Task<IEnumerable<T>>` 等の曖昧な型で返す — 実体は `List<T>`、ストリームは `IAsyncEnumerable<T>` と明示する
