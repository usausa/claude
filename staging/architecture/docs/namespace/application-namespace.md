# Application 名前空間

| 項目 | 内容 |
|---|---|
| ID | namespace-2 |
| 分類 | namespace |
| 関連 | namespace-1(総覧) / namespace-3(Infrastructure との使い分け) / host-1(ApplicationExtensions) / web-1(ApiRoutes) / web-3(NamingPolicy) / telemetry-1(Telemetry) / log-1(Log.cs) |

## 目的

**`Application` は「アプリ固有の共通部品」の置き場とする(決定)。**

- 特定の機能・画面には属さないが、このアプリの知識(URL、キー名、業務ポリシー)を含む部品を集約する
- アプリ全体の構成とポリシーがこの名前空間を見れば分かる状態にする
- アプリ非依存の汎用部品(`Infrastructure` → namespace-3)との境界を明確にする

## 標準形

### 判定基準

**「このアプリの知識(URL、キー名、業務ポリシー)を含むか」**で判定する。

| 判定 | 置き場 |
|---|---|
| アプリの知識を含む(このアプリでしか使えない) | `Application` |
| アプリの知識を含まない(他アプリへコピーしてそのまま使える) | `Infrastructure`(namespace-3) |
| 特定の機能・レイヤに属する | 各レイヤの名前空間(namespace-1) |

### 代表部品

| クラス | 内容 |
|---|---|
| `ApplicationExtensions` | `ConfigureXxx()` / `UseXxx()` 拡張メソッド群。起動処理の実体(host-1) |
| `FeatureFlags` | 機能トグルの定数・判定(`EnableSwagger` 等) |
| `MappingProfile` | オブジェクトマッピング定義の集約 |
| `NamingPolicy` | JSON 命名ポリシー(camelCase)の一元定義(web-3) |
| `CacheKey` | キャッシュキー文字列の定数・組み立ての集約(衝突・タイポ防止) |
| `LimitPolicy` | 業務上の上限値ポリシー(ページサイズ・件数上限等) |
| `StoragePath` | アプリが使用するストレージパス構成の定数・組み立て |
| `ApiRoutes` | API ルートの定数化(web-1) |
| `Telemetry/` | `ApplicationInstrument` / `Source` 等の計装部品(telemetry-1) |
| `Validation/` | このアプリの検証規約・検証構成 |
| `RateLimiting/` | レート制限のポリシー定義 |
| `Log`(Log.cs) | Application 層のログメッセージ定義(log-1) |

### コード例

アプリの知識(キー体系・ルート体系)を定数・純関数として一元化する。

```csharp
namespace Template.Server.Application;

public static class CacheKey
{
    public const string UserList = "user/list";

    public static string UserById(int id) => $"user/{id}";
}
```

```csharp
namespace Template.Server.Application;

public static class ApiRoutes
{
    public const string User = "/api/user";
    public const string Order = "/api/order";
}
```

サブフォルダは部品が複数ファイルになる場合にのみ切る(`Application/Telemetry/`、`Application/Validation/`)。単一クラスならフォルダを作らず直下に置く。

## 配置ルール

| 対象 | 場所 |
|---|---|
| アプリ固有の共通部品 | `Application/`(複数ファイルの部品はサブフォルダ) |
| アプリ非依存のインフラ部品 | `Infrastructure/`(namespace-3) |
| アプリ設定クラス(`*Setting`) | `Settings/`(config-4)。`Application` には置かない |
| 機能単位の業務コード | `Services` / `Usecase` / `Endpoints` 等の各レイヤ(namespace-1) |

## バリエーションと使い分け

- 迷った部品は「他アプリへコピーしてそのまま動くか」を問う。動く → `Infrastructure`、URL・キー名・ポリシーの書き換えが必要 → `Application`
- マッピング定義を利用箇所の近くに併記する方式(web-3)を採る場合、`MappingProfile` は置かない
- 基盤層プロジェクトを分離する構成(solution-3)では、汎用寄りの部品は基盤層へ昇格していく。`Application` には最後まで「このアプリの知識」だけが残る

## アンチパターン

- `Application` を「その他」フォルダにする — 判定基準(アプリの知識を含むか)を通らないものは置かない
- 汎用ユーティリティを `Application` に置く — アプリ非依存なら `Infrastructure`(namespace-3)
- `*Setting` を `Application` に置く — 設定クラスは `Settings/`(config-4)
- URL・キャッシュキーのリテラルを利用箇所に直書きして散らす — `ApiRoutes` / `CacheKey` に定数として集約する
- `Application` 配下に業務ロジックを書く — 業務は `Domain` / `Services` / `Usecase` へ(namespace-1)
