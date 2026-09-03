---
paths:
  - "**/Accessors/**"
  - "**/*.sql"
  - "**/Services/**"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# データアクセス (Smart スタック標準)

> `dotnet-data` rule を具体化する。詳細・コード例は `smart-data` skill の references を必要時に読む。

- **Smart.Data.Accessor** で構築する。`Accessors/` に `[DataAccessor]` を付けた `sealed partial class` + `public partial` メソッド (実装はソースジェネレータ)。属性 = `[Query]` / `[QueryFirst]` / `[ExecuteScalar]` / `[Execute]` / `[Insert]`。登録は `AddDataAccessors(typeof(DataAccessor).Assembly)`、Service はアクセサクラスを直接注入。戻り値は `ValueTask` 基本。
- SQL は **2-way SQL 外部ファイル** `Accessors/Sql/<クラス名>.<メソッド名>.sql` (1 メソッド = 1 ファイル)。パラメータは `/*@ name */ダミー値`、動的条件は `/*% if %*/` — そのまま SQL クライアントで実行できる形を保つ。
- 接続は `DelegateDbProvider`、方言 (重複キー判定・LIKE エスケープ) は `DelegateDialect` へ隔離。Service は `DbException` + `IsDuplicate` で受けて**結果で通知**する。
- SQL トレースは `MiniDataProfiler` (`ProfileDbConnection` ラップ) を設定トグルで有効化し、ログ + OpenTelemetry の二重掛け。
