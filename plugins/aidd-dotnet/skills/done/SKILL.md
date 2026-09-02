---
name: done
description: 変更完了前の Definition of Done ゲート。未達なら未達項目を列挙して停止する。
---

以下を順に検査し、結果を表 (`[項目 | 状態 | 対応]`) で示す。**1 つでも未達なら「未完了」**と結論する。

1. **ビルド警告ゼロ + テスト緑**か  →  !`dotnet build`  →  !`dotnet test`  (= `/verify`)
2. 公開 API / 型に変更があるか。あれば `docs/reference` が再生成済みか (要なら `/reference`)
3. **設計上の決定**をしたか。したなら該当 ADR が追記されているか (要なら `/adr`)
4. SPEC の**受け入れ条件がテスト名に反映**されているか (SPEC 削除後はテストが恒久の受け皿)
5. **レビュー観点** (`docs/review-checklist.md`) を満たすか (`/review`、必要なら Codex で `/review-cross`)
6. **クローズ (片付け)**: `work-close` の手順で、作業フォルダ (`docs/work/`) の SPEC / PLAN を蒸留漏れ確認の上**削除**したか (自ブランチの作業フォルダが残っていないか)

最後に:
- 「今回の変更で影響を受ける docs」チェックリスト
- 人間が実行する git コマンド案
