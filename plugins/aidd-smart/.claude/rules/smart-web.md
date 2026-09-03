---
paths:
  - "src/**"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。dotnet-* と重なる規範は smart-* が優先。プロジェクト固有の上書きは conventions.md へ -->

# Web API (Smart スタック標準)

> `dotnet-web` rule / `dotnet-api` rule を具体化する。詳細・コード例は `smart-web` skill の references を必要時に読む。

- **Minimal API を優先**する。`Endpoints/<Resource>Endpoints.cs` に `Map<Resource>Endpoints(this WebApplication)`、ファイル内は Mapping / Handler / Mapper の 3 セクション。ルートは `Application/ApiRoutes.cs` に定数化。ハンドラは static + 引数 DI + `IResult` (`TypedResults`)、実処理は Service / Usecase へ委譲。
- 契約: JSON は **camelCase** (`NamingPolicy` に集約)、DTO は `*Request` / `*Response` の `sealed record`、**トップ階層は配列を返さず必ずオブジェクトで包む**。
- OpenAPI は .NET 内蔵 (`AddOpenApi`) で生成し、UI は **NSwag** (配線はテンプレート済み・公開は Development のみ)。
- エラー応答: 予期できる異常は `IResult` で返し、予期せぬ例外は ProblemDetails (RFC 7807) の一元ハンドラに任せる (配線はテンプレート済み。ハンドラを増やさない)。
- アプリ固有の認証状態: `Credential` record + `CredentialEndpointFilter` (ロールは `identity.RoleClaimType` で解決)、横断状態は `AsyncLocal` の Context + `CallbackEnricher`。
