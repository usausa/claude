# 2-way SQL 外部ファイル

| 項目 | 内容 |
|---|---|
| ID | data-2 |
| 分類 | data |
| 関連 | data-1(Smart.Data.Accessor) / data-3(接続・方言・トレース) / namespace-1(`Accessors`) |

## 目的

SQL は C# に埋め込まず、**そのまま SQL クライアントで実行できる 2-way SQL 形式の外部ファイル**で管理する。

- パラメータや動的条件をコメント形式(`/*@ */` / `/*% */`)で埋め込むため、ファイルの内容をコピーしてそのまま実行・実行計画確認ができる
- SQL レビュー・チューニングが C# コードから独立して行える
- ファイル名の規約でアクセサメソッドと 1対1 に対応し、探す必要がない

## 標準形

### ファイル命名

`Accessors/Sql/` 配下に **`<クラス名>.<メソッド名>.sql`** で置く(メソッド名は `Async` サフィックスを含めそのまま)。アクセサ(data-1)のメソッドと 1対1。

```
Accessors/
├─ DataAccessor.cs
└─ Sql/
   ├─ DataAccessor.Create.sql
   ├─ DataAccessor.CountAsync.sql
   ├─ DataAccessor.QueryAsync.sql
   ├─ DataAccessor.QueryPageAsync.sql
   ├─ DataAccessor.InsertAsync.sql
   ├─ DataAccessor.UpdateAsync.sql
   └─ DataAccessor.DeleteAsync.sql
```

### パラメータ — `/*@ param */ダミー値`

パラメータはコメント `/*@ 引数名 */` の直後にダミー値を書く。実行時はダミー値がバインドパラメータに置き換わり、SQL クライアントで直接実行する時はダミー値がそのまま使われる。

```sql
SELECT * FROM Data WHERE Id = /*@ id */0
```

```sql
SELECT * FROM Data
WHERE (/*@ name */'' IS NULL) OR (Name LIKE '%' || /*@ name */'' || '%')
ORDER BY Id
LIMIT /*@ size */10 OFFSET /*@ offset */0
```

ダミー値は列の型に合わせる(数値は `0`、文字列は `''`、日付は `'2000-01-01'` 等)。

### 動的条件 — `/*% if */`

条件の有無で WHERE 句が変わる場合はコードブロックコメント `/*% %*/` で囲む。この形式でもコメント扱いのため、そのまま実行すると全件側の SQL として動く。

```sql
SELECT
    *
FROM
    Data
WHERE
    1 = 1
/*% if (flag.HasValue) { */
    AND Flag = /*@ flag */0
/*% } */
ORDER BY
    Id
OFFSET /*@ offset */0 ROWS
FETCH NEXT /*@ limit */10 ROWS ONLY
```

- 動的条件を足しやすくするため `WHERE 1 = 1` を置き、各条件は `AND` から書く
- 条件式は C# の式(引数を参照)をそのまま書く

### 複文と採番

複文も1ファイルに書ける。INSERT + 採番値の取得はアクセサ側を `[ExecuteScalar]` にして受ける。

```sql
INSERT INTO Data (Name, Value, CreatedAt) VALUES (/*@ name */'', /*@ value */0, /*@ createdAt */'');
SELECT last_insert_rowid();
```

## 配置ルール

| 対象 | 規約 |
|---|---|
| 置き場 | `Accessors/Sql/`(アクセサクラスと同じフォルダ配下) |
| ファイル名 | `<クラス名>.<メソッド名>.sql`(1メソッド=1ファイル) |
| パラメータ名 | アクセサメソッドの引数名と一致させる |

## バリエーションと使い分け

- ページング構文(`LIMIT/OFFSET` / `OFFSET FETCH`)や採番(`last_insert_rowid()` / `SCOPE_IDENTITY()`)は対象 DB の方言で書く。方言差の吸収は SQL ファイル側で行い、C# 側(data-3 の `IDialect`)は例外判定・エスケープに限定する
- 単純な PK 引き 1行取得のような SQL は1行で書いてよい。動的条件を含む SQL は句毎に改行した縦書きレイアウトにする

## アンチパターン

- C# 内の SQL 文字列(補間・連結)— 2-way SQL 外部ファイルに置く。文字列連結による条件組み立てはインジェクションの温床
- そのまま実行できない SQL — ダミー値の欠落や独自プレースホルダ(`@name` 直書き等)は 2-way 性が失われる
- 動的条件の分だけメソッドと SQL を複製する — `/*% if */` で1ファイルに束ねる
- 1ファイルに複数メソッド分の SQL を混在させる — 1メソッド=1ファイルを崩さない
- SQL 内へのロジック過積載 — 業務判断は Service / Usecase 側へ。SQL は取得・更新の宣言に徹する
