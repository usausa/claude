---
paths:
  - "**/*.slnx"
  - "**/*.sln"
  - "**/*.csproj"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# ソリューション分割 (Smart スタック標準)

> 詳細・コード例は `smart-solution` skill の references を必要時に読む。

- 基本形は `X.Core` (RootNamespace 短縮: `Template.Core` → `Template`) + ホスト + `X.Tests`。クライアントは 1 ソリューション = 1 プロジェクト (フォルダ = 名前空間)。
- **Aspire AppHost を Web の標準構成に含める** (極薄・業務ロジックゼロ・`WithHttpHealthCheck`)。**ServiceDefaults プロジェクトは作らない** — 相当機能はアプリ側 / 基盤層へ。
- 基盤層プロジェクト: Filter / Binder / Json / Validation / Telemetry 等を分離して複数ホストで共有。アプリ非依存の Infrastructure (BCL ミラー名前空間) と、アプリ固有だが業務非依存 (`Infrastructure/`) を使い分ける。
