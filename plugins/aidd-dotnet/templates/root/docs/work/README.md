# work(一時 spec / plan 置き場)

> ここは**一時物**の置き場(git 管理。完了時に削除するが履歴には残る = 仕様レビュー・worktree・別マシン再開・引き継ぎが成立する)。
> 恒久に残す先: 決定=`docs/adr/` / 用語=`docs/glossary.md` / 受け入れ条件=テスト名 / 現状仕様=生成+テスト。

## 作業フォルダの解決規則(中間フロー /spec /plan /impl /review が共有する正)

1. `docs/work/<現ブランチの slug>/` が存在する → それを使う(slug = ブランチ名の `/` を `-` に置換。例 `feature/foo-bar` → `feature-foo-bar`)
2. 存在しない → `docs/work/` 直下(従来形式)

- ブランチフォルダ方式: `SPEC.md` / `PLAN.md`(置き場がブランチ名から一意に決まる。`work-init` skill が作成)
- 直下方式: `SPEC-<topic>.md` / `PLAN-<topic>.md`(main 直下の小変更向け)
- 初期化(`work-init`)と完了(`work-close`)は**任意**。中間フローはこの規則だけに依存し、どちらの方式でも動く。
- 完了時は `work-close` で片付ける(蒸留漏れ確認 → SPEC / PLAN 削除 → 最終プッシュ・ブランチ削除の提示)。
