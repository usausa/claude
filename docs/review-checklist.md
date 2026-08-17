# レビュー観点 (Claude reviewer / Codex 共有)

> このファイルは `reviewer` サブエージェント (Claude) と、別途 codex で行うクロスレビューが**共有する単一の基準**。
> 変更のたびにこれらの観点で確認し、指摘は Critical / Major / Minor に分類する。

## 📐 1. アーキ・原則
- `.claude/rules/` の規範に反していないか (レイヤ責務、上位層は薄く下位へ委譲、async 規約)。

## 📏 2. プロジェクト方針
- `.claude/rules/conventions.md` の方針に沿っているか (具体例はそちらが正)。

<!-- sdd:review-intent:start -->
## 📌 3. 意図との整合
- 実装が作業フォルダ (`docs/work/`) の SPEC の意図・スコープに一致しているか (不一致は「ドリフト」として報告)。
- **受け入れ条件がテスト名に反映されているか** (SPEC はクローズ時に削除されるため、テストが恒久の受け皿)。
<!-- sdd:review-intent:end -->

## 🧭 4. 決定の記録
- 設計上の決定をしたのに ADR が無い、を検出する (→ `/adr`)。

## 📌 5. 現状仕様の鮮度
- 公開 API / 型 / スキーマを変えたのに `docs/reference` (OpenAPI 等) が古い (→ `/reference`)。

## 🔐 6. セキュリティ
- `.claude/rules/security.md` と採用形態のセキュリティ観点 (秘匿情報・入力検証・認証認可・通信) を満たすか。

## 🔤 7. 用語
- 命名が `docs/glossary.md` の英語名と一致しているか。

## 📌 8. 品質
- **`build` + `test` が緑か** (`/verify`)。警告ゼロ。テストが受け入れ条件を表現しているか。
