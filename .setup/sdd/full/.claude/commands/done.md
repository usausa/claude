---
description: 変更完了前の Definition of Done ゲート。未達なら未達項目を列挙して停止する。
allowed-tools: Bash(dotnet:*), Read, Grep, Glob
---

以下を順に検査し、結果を表 (`[項目 | 状態 | 対応]`) で示す。**1 つでも未達なら「未完了」**と結論する。

1. **ビルド警告ゼロ + テスト緑**か  →  !`dotnet build`  →  !`dotnet test`  (= `/verify`)
2. 公開 API / 型に変更があるか。あれば `docs/reference` が再生成済みか (要なら `/reference`)
3. この変更は**意図** (SPEC) を変えるか。変えるなら更新 + **蒸留**済みか (`spec-close`。復元可能な情報が SPEC に残っていないか)。作業フォルダ (`docs/work/`) の PLAN の削除と最終プッシュ・ブランチ削除は `work-close` の手順で片付けたか
4. **設計上の決定**をしたか。したなら該当 ADR が追記されているか (要なら `/adr`)
5. トレーサビリティ整合 (`/trace`)。**退役漏れ**が無いか (機能削除に伴う SPEC/ADR の `status` 未更新・退役候補が 0 か)
6. **レビュー観点** (`docs/review-checklist.md`) を満たすか (`/review`、必要なら Codex で `/review-cross`)

最後に:
- 「今回の変更で影響を受ける docs」チェックリスト
- 人間が実行する git コマンド案
