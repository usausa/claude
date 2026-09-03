---
name: pm-plan
description: feature 単位 (1 feature ≒ 1 SPEC) でイテレーション計画を作成・更新する。WBS/フェーズゲートは使わない。
---

> 引数: [イテレーションの狙い]

`pm` サブエージェントに、feature 単位のイテレーション計画を依頼する。

- `docs/spec/` の SPEC を backlog として、`docs/pm/iteration-plan.md` を更新する (feature 単位、状態付き)。`docs/pm/` が無ければ本 skill の references/iteration-plan-template.md / references/progress-template.md の雛形から初回生成する。
- 方針は本 skill の references/pm-policy.md が正。SDD レベル full-pm (`.claude/rules/aidd.md`) 専用。
