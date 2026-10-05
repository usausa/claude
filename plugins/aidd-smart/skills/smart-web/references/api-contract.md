# API 契約の作法

| 項目 | 内容 |
|---|---|
| ID | web-3 |
| 分類 | web |
| 関連 | web-1(Minimal API) / web-2(Controller + Areas) / web-6(エラー応答・OpenAPI) / namespace-2(Application) / namespace-5(モデルサフィックス) / solution-3(基盤層プロジェクト) |

## 目的

API の入出力(JSON 契約)の形を全プロジェクトで統一する。次の 4 点は決定事項として断定する。

1. **JSON の命名は camelCase** とし、ポリシーは `NamingPolicy` に集約する
2. **DTO は `*Request` / `*Response` サフィックス**とし、名前は**機能名 + 操作名**にする(namespace-5)
3. **トップ階層では配列を返さず、必ずクラス(オブジェクト)で包む**
4. **受け付ける JSON は厳しくする**(文字列の数値・重複したキー・知らない項目は 400)

- 契約の形が固定されるため、クライアント生成・スキーマ検証・後方互換の判断が機械的にできる
- トップ階層をオブジェクトにしておくことで、件数・ページ情報等のメタデータ追加が破壊的変更にならない

## 標準形

### NamingPolicy(命名の一元化)

命名ポリシーは `Application/NamingPolicy.cs` に集約し、シリアライザ設定はここだけを参照する。

```csharp
namespace Template.Server.Application;

using System.Text.Json;

public static class NamingPolicy
{
    public static JsonNamingPolicy JsonPropertyNaming => JsonNamingPolicy.CamelCase;

    public static JsonNamingPolicy JsonDictionaryKeyNaming => JsonNamingPolicy.CamelCase;
}
```

`ApplicationExtensions.ConfigureApi()`(host-1)でシリアライザに適用する。

```csharp
builder.Services.ConfigureHttpJsonOptions(static options =>
{
    options.SerializerOptions.PropertyNamingPolicy = NamingPolicy.JsonPropertyNaming;
    options.SerializerOptions.DictionaryKeyPolicy = NamingPolicy.JsonDictionaryKeyNaming;
    options.SerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
    options.SerializerOptions.Encoder = JavaScriptEncoder.Create(UnicodeRanges.All);
    options.SerializerOptions.NumberHandling = JsonNumberHandling.Strict;
    options.SerializerOptions.AllowDuplicateProperties = false;
    options.SerializerOptions.UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow;
});
```

- `NumberHandling.Strict`: 数値は数値の JSON だけを受け付ける。Web の既定は文字列の数値も受け付け、OpenAPI の整数も `integer` / `string` の両方になる
- `AllowDuplicateProperties = false`: 同じキーが 2 回ある JSON を 400 にする
- `UnmappedMemberHandling.Disallow`: 知らない項目を 400 にする(誤字の項目が既定値のまま保存されるのを防ぐ)。OpenAPI の型には `additionalProperties: false` が付く。緩めたい型だけ `[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Skip)]` を付ける
- 項目名の大文字・小文字は区別しない(`PropertyNameCaseInsensitive` は既定の `true` のまま)

### 命名(機能名 + 操作名)

エンドポイント名(`WithName`、web-6)と DTO は、機能名(`<Feature>Endpoints` の `<Feature>`)と操作名(ハンドラ名 `Handle<操作>Async` の `<操作>`)から作る。

| 操作 | エンドポイント名 | DTO |
|---|---|---|
| 一覧 | `DataList` | `DataListResponse` / 要素 `DataListEntry` |
| 取得 | `DataGet` | `DataGetResponse` |
| 作成 | `DataCreate` | `DataCreateRequest` / `DataCreateResponse` |
| 更新 | `DataUpdate` | `DataUpdateRequest` |
| 削除 | `DataDelete` | なし |
| ログイン | `AuthLogin` | `AuthLoginRequest` / `AuthLoginResponse` |

中身が同じでも操作ごとに型を分ける(取得の応答と一覧の要素、ログインとリフレッシュの応答など)。

### Request / Response DTO

DTO は `sealed record` で定義する。検証属性は record の property スコープに付ける。

```csharp
namespace Template.Server.Models.Data;

public sealed record DataCreateRequest(
    [property: Required][property: MaxLength(50)] string Name,
    [property: Range(0, 1_000_000)] int Value);

public sealed record DataGetResponse(long Id, string Name, int Value, DateTime CreatedAt);
```

### トップ階層はオブジェクトで包む

一覧応答は配列を直接返さず、必ず包むクラスを定義する。

```csharp
public sealed record DataListResponse(int Total, int Page, int Size, IReadOnlyList<DataListEntry> Items);

public sealed record DataListEntry(long Id, string Name, int Value, DateTime CreatedAt);
```

```json
{
  "total": 42,
  "page": 0,
  "size": 20,
  "items": [
    { "id": 1, "name": "example", "value": 100, "createdAt": "2026-01-01T00:00:00" }
  ]
}
```

### 外部仕様固定時のみ `[JsonPropertyName]`

外部システム側の JSON 仕様が固定で camelCase 変換に載らない場合のみ、`[JsonPropertyName]` で明示する。自プロジェクト内の契約には使わない。

```csharp
public sealed record ExternalCallbackRequest(
    [property: JsonPropertyName("txn_id")] string TransactionId,
    [property: JsonPropertyName("result_code")] int ResultCode);
```

### 検証とマッピング

- 標準の検証属性(`[Required]` / `[MaxLength]` / `[Range]` 等)で表せない検証は、カスタム検証属性として基盤層の `Validation/Annotations` に集約する(solution-3)。エンドポイント個々に ad-hoc な検証コードを書かない
- Entity ⇔ DTO のマッピング定義(`[MapConfig]` 等のマッパー構成)は**利用箇所の近くに併記する**。少数の詰め替えならマッパーを使わず、Endpoints クラスの `Mapper` セクション(web-1)に手書きの変換メソッドを置いてよい

## 配置ルール

| 対象 | 場所 |
|---|---|
| `NamingPolicy` | `Application/NamingPolicy.cs`(namespace-2) |
| Request / Response DTO | Minimal API: `Models/<Resource>/`、Controller 方式: `Areas/<Area>/Models/`(web-2) |
| カスタム検証属性 | 基盤層プロジェクトの `Validation/Annotations`(solution-3) |
| マッピング定義 | 利用箇所(Endpoints / Controller / Service)の近く |

## バリエーションと使い分け

- **null の扱い**: `DefaultIgnoreCondition = WhenWritingNull` を既定とし、null プロパティは出力しない。「キーはあるが null」を契約として区別したい API のみ個別に外す
- **作成応答**: 採番 ID のみ返す場合も `DataCreateResponse(long Id)` のようにオブジェクトで包む。素の数値・文字列をトップ階層で返さない
- **Controller 方式**: `AddControllers().AddJsonOptions(...)` で同じ `NamingPolicy` と受け付けの設定を適用する。OpenAPI のスキーマは `ConfigureHttpJsonOptions` の設定から作られるので、共通のメソッドで両方に同じ設定を入れる(web-2)

## アンチパターン

- **トップ階層の配列返却** — `[{...}, {...}]` を返すと、メタデータ追加が破壊的変更になる。必ず `Items` を持つオブジェクトで包む
- **PascalCase のまま返す / 個別 DTO での命名指定** — 命名は `NamingPolicy` 一箇所で決める。`[JsonPropertyName]` の乱用は契約の一貫性を壊す
- **Entity / View の直接返却** — 永続化モデルの変更が API 契約の変更に直結してしまう。境界では必ず `*Request` / `*Response` に詰め替える(namespace-5)
- **サフィックスの揺れ** — `*Dto` / `*Model` / `*Input` 等を混在させない。API 境界は `*Request` / `*Response` に統一する
- **操作をまたぐ DTO の共有** — 取得の応答を一覧の要素や別の操作の応答に流用しない。操作ごとに型を分ける
- **Web の既定のままの受け付け** — 文字列の数値・重複したキー・知らない項目を黙って受け付けると、誤字の項目が既定値で保存される
- **検証ロジックのハンドラ直書き** — 宣言的に表せる検証は属性へ、共通化できるものは基盤層の Annotations へ寄せる
