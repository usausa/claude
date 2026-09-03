# aidd-pm — AIDD Project Management

feature 単位のプロジェクト管理アドオンプラグイン。**1 feature ≒ 1 SPEC** を単位にイテレーション計画と進捗集計を行う (WBS / フェーズゲートは使わない)。

| 提供物 | 内容 |
|---|---|
| pm-plan | `/aidd-pm:pm-plan [狙い]` — `docs/spec/` の SPEC を backlog にイテレーション計画を作成・更新。`docs/pm/` が無ければ references の雛形から初回生成 |
| pm-status | `/aidd-pm:pm-status` — SPEC / ADR / 実装 / テストの有無から進捗ボードを更新 |
| agents | pm (計画・集計の実行担当) |

## 導入

```
/plugin install aidd-pm@aidd
```

- `aidd-dotnet` に依存する (自動で併せて有効化される)。**SDD レベル full が前提** (SPEC の恒久文書 `docs/spec/` を backlog として使うため。`.claude/rules/aidd.md` の宣言が lite の場合は full への切替を案内する)。
- rules・init は持たない (規範を提供しないアドオン。`docs/pm/` は pm-plan が必要時に生成する)。
- 回し方への組み込み: イテレーション開始時に `/aidd-pm:pm-plan`、`/done` 後や定期確認に `/aidd-pm:pm-status`。方針の正は pm-plan skill の references/pm-policy.md。
