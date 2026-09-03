# API 契約の作法

| 項目 | 内容 |
|---|---|
| ID | web-3 |
| 分類 | web |
| 関連 | web-1(Minimal API) / web-2(Controller + Areas) / web-6(エラー応答・OpenAPI) / namespace-2(Application) / namespace-5(モデルサフィックス) / solution-3(基盤層プロジェクト) |

## 目的

API の入出力(JSON 契約)の形を全プロジェクトで統一する。次の 3 点は決定事項として断定する。

1. **JSON の命名は camelCase** とし、ポリシーは `NamingPolicy` に集約する
2. **DTO は `*Request` / `*Response` サフィックス**とする(namespace-5)
3. **トップ階層では配列を返さず、必ずクラス(オブジェクト)で包む**

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
});
```

### Request / Response DTO

DTO は `sealed record` で定義する。検証属性は record の property スコープに付ける。

```csharp
namespace Template.Server.Models.Data;

public sealed record DataCreateRequest(
    [property: Required][property: MaxLength(50)] string Name,
    [property: Range(0, 1_000_000)] int Value);

public sealed record DataResponse(long Id, string Name, int Value, DateTime CreatedAt);
```

### トップ階層はオブジェクトで包む

一覧応答は配列を直接返さず、必ず包むクラスを定義する。

```csharp
public sealed record DataListResponse(int Total, int Page, int Size, IReadOnlyList<DataResponse> Items);
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
- **Controller 方式**: `AddControllers().AddJsonOptions(...)` で同じ `NamingPolicy` を適用する(web-2)

## アンチパターン

- **トップ階層の配列返却** — `[{...}, {...}]` を返すと、メタデータ追加が破壊的変更になる。必ず `Items` を持つオブジェクトで包む
- **PascalCase のまま返す / 個別 DTO での命名指定** — 命名は `NamingPolicy` 一箇所で決める。`[JsonPropertyName]` の乱用は契約の一貫性を壊す
- **Entity / View の直接返却** — 永続化モデルの変更が API 契約の変更に直結してしまう。境界では必ず `*Request` / `*Response` に詰め替える(namespace-5)
- **サフィックスの揺れ** — `*Dto` / `*Model` / `*Input` 等を混在させない。API 境界は `*Request` / `*Response` に統一する
- **検証ロジックのハンドラ直書き** — 宣言的に表せる検証は属性へ、共通化できるものは基盤層の Annotations へ寄せる
