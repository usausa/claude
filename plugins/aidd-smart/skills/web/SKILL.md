---
name: web
description: Smart スタックの Web API 標準 (Minimal API・契約・NSwag UI・ProblemDetails・認証状態)
paths:
  - "src/**"
---

# Web API (Smart スタック標準)

> `aidd-dotnet` の web / api を具体化する。詳細・コード例は references/ を必要時に読む。

- **Minimal API を優先**する。`Endpoints/<Resource>Endpoints.cs` に `Map<Resource>Endpoints(this WebApplication)`、ファイル内は Mapping / Handler / Mapper の 3 セクション。ルートは `Application/ApiRoutes.cs` に定数化。ハンドラは static + 引数 DI + `IResult` (`TypedResults`)、実処理は Service / Usecase へ委譲。
- 契約: JSON は **camelCase** (`NamingPolicy` に集約)、DTO は `*Request` / `*Response` の `sealed record`、**トップ階層は配列を返さず必ずオブジェクトで包む**。
- OpenAPI は `AddOpenApi()` / `MapOpenApi()` (.NET 内蔵) で生成し、UI は **NSwag** (`app.UseSwaggerUi(o => o.DocumentPath = "/openapi/v1.json")`)。公開は Development のみ。
- エラー応答: 予期できる異常は `IResult`、予期せぬ例外は `AddProblemDetails()` + `IExceptionHandler` + `UseExceptionHandler()` の 1 箇所 (RFC 7807。traceId を拡張フィールドへ)。
- アプリ固有の認証状態: `Credential` record + `CredentialEndpointFilter` (ロールは `identity.RoleClaimType` で解決)、横断状態は `AsyncLocal` の Context + `CallbackEnricher`。
- 運用系エンドポイント (`/metrics` `/swagger`) は環境・機能トグルで無効化を第一に、公開時は IP 制限 (`UseWhenFrom`) を重ねる。

## references (詳細)

minimal-api / api-contract / controller-areas / grpc / auth-state / error-handling-openapi
