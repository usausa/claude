# モデルのサフィックス規約

| 項目 | 内容 |
|---|---|
| ID | namespace-5 |
| 分類 | namespace |
| 関連 | namespace-1(総覧) / namespace-4(コード値) / namespace-6(Usecase の戻り値) / web-3(Request・Response 契約) / config-1(Setting・Options 命名) / config-3(Entry) / config-4(配置) / data-1(アクセサ) / data-2(2-way SQL) |

## 目的

データを運ぶクラスの役割をサフィックスで宣言し、名前だけで「どこで生まれ、どこへ渡るか」が分かるようにする。

- 同じ「ユーザー」でも DB 行・SQL 結果・API 応答は別クラスにする。境界毎に独立して変更できる
- サフィックスと配置名前空間を 1:1 に対応させ、置き場の迷いをなくす

## 標準形

### サフィックス表

| サフィックス | 役割 | 配置名前空間 | 例 |
|---|---|---|---|
| `*Entity` | DB テーブルと 1:1 の行モデル | `Models.Entity` | `UserEntity` |
| `*View` | SQL 結果(JOIN・集計)の読み取りモデル | `Models.View` | `UserSummaryView` |
| `*Parameter` | SQL への引数(検索条件等) | `Models.Parameter` | `UserSearchParameter` |
| `*Request` / `*Response` | API 境界の入出力(web-3) | `Models.Api` | `UserListRequest` / `UserListResponse` |
| `*Setting` | アプリ設定(config-1) | `Settings` | `ServerSetting` |
| `*Options` | 再利用コンポーネント付属の設定(config-1) | コンポーネントと同居(config-4) | `FileStorageOptions` |
| `*Entry` | ネスト設定の入れ子要素(config-3) | 親 `*Setting` と同居 | `HttpLogEntry` |

### コード例

```csharp
// DB テーブルと 1:1。カラム型そのまま、コード値カラムは Domain.Code 参照(namespace-4)
namespace Template.Models.Entity;

public sealed class UserEntity
{
    public int Id { get; set; }

    public string Name { get; set; } = default!;

    public sbyte AlertLevel { get; set; }
}
```

```csharp
// JOIN・集計の結果を受ける読み取りモデル
namespace Template.Models.View;

public sealed class UserSummaryView
{
    public int Id { get; set; }

    public string Name { get; set; } = default!;

    public int OrderCount { get; set; }
}
```

```csharp
// 2-way SQL(data-2)へ渡す検索条件
namespace Template.Models.Parameter;

public sealed class UserSearchParameter
{
    public string? Name { get; set; }

    public sbyte? AlertLevel { get; set; }
}
```

- すべて `sealed`。プロパティは `{ get; set; }`、非 null 参照型は `= default!` または `required` で初期化する(config-1 と同作法)
- `*Entity` / `*View` / `*Parameter` はアクセサ(data-1)の戻り値・引数として使う

### 変換の方向

`*Entity` / `*View` を API へそのまま返さない。境界では必ず `*Response` に詰め替える(web-3)。詰め替えは Endpoint / Service 側のマッピングで行い、DB 都合の変更が API 契約へ波及しないようにする。

## 配置ルール

| 対象 | 場所 |
|---|---|
| `*Entity` / `*View` / `*Parameter` | `Models/Entity/` / `Models/View/` / `Models/Parameter/` |
| `*Request` / `*Response` | `Models/Api/`(Controller + Areas 方式では `Areas/<Area>/Models/` → web-2) |
| `*Setting` | `Settings/`(config-4) |
| `*Options` | 付属先コンポーネントと同じ場所(config-4) |
| `*Entry` | 親 `*Setting` と同じ場所(config-3) |

## バリエーションと使い分け

- 単純 CRUD で読み取りが Entity と完全一致する間は `*View` を作らず Entity を読み取りにも使ってよい。SELECT に JOIN・計算列が入った時点で `*View` を切る
- `*Parameter` は引数が増えてきた場合に導入する。単一キーの取得はメソッド引数のままでよい
- クライアント側のローカル DB(SQLite 等)でも同じサフィックスを使う(`Models/Entity`)
- Usecase の戻り値 record(namespace-6)はこの表の対象外。`*Result` のような役割名を付ける

## アンチパターン

- 1クラスの使い回し — Entity を API 応答・画面バインドまで流用すると、DB 変更が全境界へ波及する
- 別語彙の混入 — SQL 結果に `*Dto`、API 応答に `*Model` 等、表にないサフィックスを持ち込まない
- `*Entity` に振る舞い(業務判定)を持たせる — 判定は `Domain` へ(namespace-4)
- API のトップ階層で配列を返す — 必ず `*Response` のオブジェクトで包む(web-3)
- `*Setting` と `*Options` の混用 — アプリ設定か部品付属設定かで使い分ける(config-1)
