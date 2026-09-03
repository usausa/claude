# aidd-pm - プロジェクト管理

feature 単位(1 feature = 1 SPEC)のイテレーション管理。SDD full 前提(WBS / フェーズゲートは使わない)。

## 🚀 導入

```
/plugin install aidd-pm@aidd   # 依存で aidd-flow も入る
```

init は不要(docs/pm は pm-plan が初回生成する)。

## 📊 skills

| skill | 内容 |
|---|---|
| [pm-plan](skills/pm-plan/SKILL.md) | SPEC を backlog にイテレーション計画を作成・更新(docs/pm は初回生成) |
| [pm-status](skills/pm-status/SKILL.md) | SPEC / ADR / 実装 / テストの有無から進捗ボードを更新 |

## 🧰 その他

| 提供物 | 内容 |
|---|---|
| agents | [pm](agents/pm.md)(計画・集計の実行担当。方針の正は [references/pm-policy.md](skills/pm-plan/references/pm-policy.md)) |
