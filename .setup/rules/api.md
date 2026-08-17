---
paths:
  - "**/Endpoints/**"
  - "**/*Endpoint*.cs"
  - "**/ApiRoutes.cs"
---

# Web API (minimal API)

> **Web API 固有**。レイヤ全体・ログ・データ・サーバ側セキュリティは [`web.md`](web.md)、Blazor UI は [`blazor.md`](blazor.md) を参照。

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
- ルートは `Application/ApiRoutes.cs` に定数化する。
- ※ これらは機械化できないため、レビューで担保する (観点は [`../../docs/review-checklist.md`](../../docs/review-checklist.md))。

## 異常系の具体 ([errors.md](errors.md) の実装)
- API は例外でなく `IResult`。予期せぬ例外は `AddProblemDetails()` + `UseExceptionHandler()` でグローバル処理 (RFC 7807)。

## OpenAPI (現状仕様の生成)
- `Microsoft.AspNetCore.OpenApi` (.NET 10 内蔵): `AddOpenApi()` / `MapOpenApi()`。
- 仕様書は手で書かず、`/reference` で `docs/reference/api/openapi.json` に生成する。エンドポイントに `.WithName()` / `.Produces<T>()` を付けて意味ある OpenAPI にする。
