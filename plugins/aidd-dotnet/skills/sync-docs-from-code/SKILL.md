---
name: sync-docs-from-code
description: docs/reference 生成(Web API=OpenAPI・任意で DB スキーマ)の初期導入と CI ドリフト検知の設定手順。OpenAPI 生成が未導入のとき、CI に組み込むときに使う。
---

# docs/reference 生成の導入(初回セットアップと CI)

**原則: 現状仕様は手で書かない。ズレようがない生成物にする。** 再生成の実行手順は `/reference` が正。ここは**未導入時のセットアップと CI 連携**のみ。

## Web API → OpenAPI(`Microsoft.AspNetCore.OpenApi`, .NET 10 内蔵)
- アプリに登録:
  ```csharp
  builder.Services.AddOpenApi();
  app.MapOpenApi();            // 開発時に /openapi/v1.json を公開
  ```
- ビルド時生成にする場合: `Microsoft.Extensions.ApiDescription.Server` を参照し
  `<OpenApiGenerateDocumentsOnBuild>true</OpenApiGenerateDocumentsOnBuild>` を設定 → build 時に JSON 生成 → `docs/reference/api/` へコピー。
- 代替: アプリ起動後に `/openapi/v1.json` を取得、または NSwag CLI(`nswag run`)。

## CI(ドリフト検知)
- CI では生成後に `git diff --exit-code docs/reference` を実行し、差分が出たら失敗させる(手編集・古い状態を物理的に禁止)。
