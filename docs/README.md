# docs の地図と「寿命クラス」

ドキュメントは**寿命(腐りやすさ)で維持方針を分ける**。何を手で守り・生成し・追記だけするか — この表が人にも AI にも効く契約。
> README.md(入口)が置き換えられても、この契約と `AGENTS.md`(規律)は残る。**フレームワークの正はここと `AGENTS.md`**。

| 場所 | 種別 | 寿命 | 誰が維持 | 腐り対策 (延命方針) |
|---|---|---|---|---|
| `adr/` | **Why (決定理由)** | 不変 | 人 (AI 草案) | **追記のみ。過去 ADR は編集しない** |
| `../.claude/rules/` | **原則・方針** | 長 | 人 | 対象ファイルを読むと `paths:` で自動適用。変更時のみ編集。機械化できる分は `.editorconfig` / analyzer へ。`conventions.md` は編集可 |
<!-- sdd:lifespan-spec:start -->
| `work/` (SPEC / PLAN) | **意図 + 実装プラン (一時物)** | 破棄 | 人 (AI 草案→承認) | 実装完了時に**クローズ蒸留** (決定→ADR / 用語→glossary / 受け入れ条件→テスト名) して**削除** |
<!-- sdd:lifespan-spec:end -->
| `reference/` | **What/How (現状仕様)** | 短 (生成) | **生成** | **手書き禁止**。Web=OpenAPI、振る舞い=テストが正 |
| `glossary.md` | **語彙** | 長 | 人 | 語彙・意味・英語名のみ。コード/DB で分かる情報は書かない |
| `review-checklist.md` | レビュー基準 | 中 | 人 | reviewer と Codex が共有 |
| コード書式・品質 | What | — | **ツール** | `.editorconfig` + analyzer、**警告0** |
<!-- pm:readme-lifespan -->

## 📌 原則
- **Why は残す** (`adr/`)。**What/How は生成する** (`reference/`)。**書式は機械が守る** (analyzer)。→ 手で守る面積を最小化。
- **コードや DB で分かる情報は文書化しない・二重管理しない**。
- **SDD**: 実装をミラーする恒久設計書は持たない。意図=`spec` / 決定=`ADR` / 原則=`rules` / 現状=生成+テスト。
- **一時物は残さない**: 実装プラン / タスク等の一時文書は実装完了後に破棄。
<!-- sdd:principle-retire:start -->
- **退役**: 覆された決定は `ADR`=`superseded` で残す (恒久の機能文書は元々持たない)。
<!-- sdd:principle-retire:end -->

## 📌 ID 体系
<!-- sdd:principle-id:start -->
- `ADR-NNNN` (決定)。手書き文書は frontmatter (`id` / `status` / `related`)。一時 spec は `work/SPEC-<topic>.md` (連番 ID は使わない)。
<!-- sdd:principle-id:end -->

## 🔄 進め方
`guides/workflow.md` を参照。
