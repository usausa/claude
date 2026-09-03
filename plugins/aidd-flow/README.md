# aidd-flow - 基本ワークフロー

spec / plan / 実装の開発用ワークフロー。SDD レベル(lite = 一時 SPEC / full = 恒久 SPEC + 蒸留)は `.claude/rules/aidd.md` の宣言で実行時分岐する。
人向けのドキュメントは [references/workflow.md](skills/spec/references/workflow.md)。

## 🚀 導入

```
/plugin install aidd-flow@aidd
/aidd-flow:init [lite|full]   # SDD レベルを宣言 (aidd.md。省略時は既存維持・初回 full)
```

.NET プロジェクトでは `aidd-dotnet` の併用を推奨(verify / done は dotnet build・test を前提とした手順のため)。

## 🔁 skills

| skill | 区分 | 内容 |
|---|---|---|
| [spec](skills/spec/SKILL.md) | ループ | アイディアの箇条書きから SPEC を草案化(承認まで実装しない) |
| [plan](skills/plan/SKILL.md) | ループ | SPEC から実装プラン(チェックリスト・フェーズ分割) |
| [impl](skills/impl/SKILL.md) | ループ | フェーズ単位の実装 + PLAN チェック更新 |
| [verify](skills/verify/SKILL.md) | ループ | build + test の実行と自己修正フィードバック |
| [review](skills/review/SKILL.md) | ループ | reviewer サブエージェントで観点レビュー |
| [done](skills/done/SKILL.md) | ループ | Definition of Done ゲート + クローズ |
| [adr](skills/adr/SKILL.md) | 随時 | 設計上の決定を ADR ドラフト化 |
| [reference](skills/reference/SKILL.md) | 随時 | docs/reference の再生成(OpenAPI 等) |
| [trace](skills/trace/SKILL.md) | 随時(full) | SPEC↔ADR↔test↔code の ID 整合検査 |
| [review-cross](skills/review-cross/SKILL.md) | 随時 | 別ベンダー(Codex)でのクロスレビュー手順 |
| [work-init](skills/work-init/SKILL.md) | 補助 | 作業ブランチ + 作業フォルダの用意(解決規則の正) |
| [work-close](skills/work-close/SKILL.md) | 補助 | 作業のクローズ(一時物削除・最終プッシュ提示) |
| [spec-close](skills/spec-close/SKILL.md) | 補助(full) | SPEC のクローズ蒸留(非復元の意図だけ残す) |
| [adr-guide](skills/adr-guide/SKILL.md) | 補助 | ADR の内容・構成・粒度のガイド(見本 4 本同梱) |
| [rule-create](skills/rule-create/SKILL.md) | 補助 | プロジェクト固有 rule の追加手順 |
| [git-commit](skills/git-commit/SKILL.md) | 補助 | コミットメッセージ / ブランチ命名の規約 |
| [csharp-layered-feature](skills/csharp-layered-feature/SKILL.md) | 補助 | 層構成に沿った C# 機能追加の手順 |
| [sync-docs-from-code](skills/sync-docs-from-code/SKILL.md) | 補助 | reference 生成の初期導入と CI ドリフト検知 |
| [init](skills/init/SKILL.md) | 初期化 | aidd.md(SDD レベル宣言)の生成 |

SDD レベルの選択で、生成物の扱い(残る / 完了時に削除)が変わる:

| 生成物 | lite | full |
|---|---|---|
| SPEC(docs/work/) | 一時物(work-close が**削除**。クローズ蒸留で決定→ADR / 用語→glossary / 受け入れ条件→テスト名へ) | 使わない |
| SPEC(docs/spec/SPEC-NNNN) | 作られない | 恒久文書(spec-close で蒸留して**残す**) |
| PLAN(docs/work/) | 一時物(完了時に**削除**) | 一時物(完了時に**削除**) |
| docs/traceability/ | 作られない | /trace が生成・維持 |

## 🧰 その他

| 提供物 | 内容 |
|---|---|
| agents | [spec](agents/spec.md)(仕様草案)/ [reviewer](agents/reviewer.md)(レビュー)/ [doc-sync](agents/doc-sync.md)(reference 同期) |
| hooks | 応答終了時の DoD リマインド |
