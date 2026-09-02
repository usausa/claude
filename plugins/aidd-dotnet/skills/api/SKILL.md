---
name: api
description: Web API (minimal API) の実装規約
paths:
  - "**/Endpoints/**"
  - "**/*Endpoint*.cs"
  - "**/ApiRoutes.cs"
---

# Web API (minimal API)

> **Web API 固有**。レイヤ全体・ログ・データ・サーバ側セキュリティは `web` skill、Blazor UI は `blazor` skill を参照。

## minimal API / エンドポイント
- `app.MapGroup("/api/<resource>")` でグルーピングし、拡張メソッド (`MapXxxEndpoints`) で定義。
- ハンドラは static メソッド。依存は引数で受け取り (DI)、戻り値は `IResult`。実処理は Service へ委譲。
- 大きいアップロードは `MaxRequestBodySize` / `WithRequestTimeout`。認可は `RequireAuthorization()`。

```csharp
public static void MapFileEndpoints(this WebApplication app)
{
    var group = app.MapGroup(ApiRoutes.Files);          // "/api/files"
    group.MapGet("/{id}", HandleGet);
}

private static IResult HandleGet(string id, FileStorageService storage)
    => storage.Find(id) is { } item ? Results.Ok(item) : Results.NotFound();
```

## API 命名・構造の方針
- リクエスト / レスポンスの型は `XxxRequest` / `YyyResponse` と命名する。
- **レスポンスは必ず専用の `YyyResponse` を用意し、トップレベルで配列を返さない** (将来の項目追加・メタ情報付与のためオブジェクトでラップする)。
- 一覧応答は件数上限を設け、`IAsyncEnumerable` の List 化境界で適用する。上限超過は黙って切らず、**業務エラーとして条件の絞り込みを促す**。全件出力 (CSV 等) は List 化せずストリームで返す。
- ルートは `Application/ApiRoutes.cs` に定数化する。
- ※ これらは機械化できないため、レビューで担保する (観点は [`../../docs/review-checklist.md`](../../docs/review-checklist.md))。

## 異常系の具体 (`errors` skill の実装)
- API は例外でなく `IResult`。予期せぬ例外は `AddProblemDetails()` + `UseExceptionHandler()` でグローバル処理 (RFC 7807)。
- 例外 → HTTP の変換は**グローバルの 1 箇所に一元化**し、ハンドラに try/catch を書かない。変換表は境界ごとに 1 つで管理する (gRPC 採用時はそちらの表と整合させる):

| 例外 | HTTP |
|---|---|
| NotFound 系 | 404 |
| BadRequest 系 | 400 |
| 業務検証エラー (蓄積器の一括例外) | 400 `ValidationProblemDetails` (エラーを列挙) |
| 一意制約違反 | 409 |
| 外部サービス例外 | 502 |
| その他 | 変換せず伝播 (500 = ProblemDetails) |

## OpenAPI (現状仕様の生成)
- `Microsoft.AspNetCore.OpenApi` (.NET 10 内蔵): `AddOpenApi()` / `MapOpenApi()`。
- 仕様書は手で書かず、`/reference` で `docs/reference/api/openapi.json` に生成する。エンドポイントに `.WithName()` / `.Produces<T>()` を付けて意味ある OpenAPI にする。
