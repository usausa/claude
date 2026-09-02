---
name: reference
description: コードから docs/reference を再生成する(Web API=OpenAPI・任意で DB スキーマ)。手書きしない。
---

`docs/reference/` は生成物。手編集せず、ここで再生成して現状仕様をコードに追随させる。

1. **Web API → OpenAPI**(`Microsoft.AspNetCore.OpenApi`):
   - ビルド時生成(`Microsoft.Extensions.ApiDescription.Server` + `OpenApiGenerateDocumentsOnBuild`)で JSON を得るか、
     アプリ起動後に `/openapi/v1.json` を取得して `docs/reference/api/openapi.json` に出力する。
   - 未導入なら導入手順を提示する(`sync-docs-from-code` スキル参照)。
2. **DB(任意)**: `dotnet ef migrations script` 等で `docs/reference/db/` にスキーマを出力。
3. 生成前後で `git diff --stat docs/reference` を確認し、変わった箇所を要約。
4. 差分が出た = コードと仕様がズレていた、ということ。関連する SPEC・テストの更新要否を指摘する。
