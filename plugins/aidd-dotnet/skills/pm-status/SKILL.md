---
name: pm-status
description: SPEC/ADR/テストの有無から進捗ボードを更新する。feature 単位。
---

`pm` サブエージェントに進捗集計を依頼する。

- `docs/spec`・`docs/adr`・`tests/`・`docs/traceability/index.md` を走査。
- feature ごとに SPEC / ADR / 実装 / テスト の有無を集計し、`docs/pm/progress.md` を更新。
- 方針は `pm-plan` skill の references/pm-policy.md が正。SDD レベル full-pm (`.claude/rules/aidd.md`) 専用。
