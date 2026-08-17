---
description: 承認済み SPEC から実装プラン (チェックリスト) を作業フォルダ (docs/work) に作る。大きければフェーズ分割。
argument-hint: [対象 SPEC (省略時は直近の SPEC)]
allowed-tools: Read, Grep, Glob, Write
---

承認済みの SPEC から実装プランを作る。

1. 対象 SPEC を読む($ARGUMENTS 指定があればそれ。無ければ直近の SPEC — 作業フォルダ(解決規則は `docs/work/README.md`)または `docs/spec/SPEC-*.md`)
2. 作業フォルダに PLAN(ブランチフォルダなら `PLAN.md`、直下なら `PLAN-<topic>.md`)を**チェックリスト形式**で作成:
   - 大きい場合は**フェーズ分割**する(フェーズ = 独立して `/verify` が緑になる単位)
   - 各項目は `- [ ]`。レイヤ順と責務は `csharp-layered-feature` / `.claude/rules/` の採用形態 rule に沿う
   - 受け入れ条件 → テスト項目の対応を含める(テスト名 = 仕様)
3. プランを人に提示して承認を得る(**承認まで実装しない**)
4. 実装中はフェーズ完了ごとに `- [x]` へ更新する
