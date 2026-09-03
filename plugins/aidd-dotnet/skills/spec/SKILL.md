---
name: spec
description: アイディアの箇条書きから仕様 (SPEC) を草案化する。lite = 作業フォルダの一時物 / full = docs/spec の恒久文書。承認後 /plan へ。
---

> 引数: [アイディアの箇条書き]

`spec` サブエージェントに、次のアイディアから仕様 (SPEC) の草案を依頼する:

$ARGUMENTS

- 出力先は SDD レベル (`.claude/rules/aidd.md` の宣言) で分岐:
  - **lite**: 作業フォルダ (`docs/work/<branch-slug>/SPEC.md`、ブランチフォルダが無ければ `docs/work/SPEC-<topic>.md`。解決規則は `work-init` skill)
  - **full**: `docs/spec/SPEC-NNNN-<title>.md` (採番は既存の最大 +1。雛形は references/spec-template.md。docs/spec が無ければ作成する)
- 起案時に `docs/adr/index.md` を確認し、関連する既存決定と矛盾する場合は SPEC に明記して人に確認する
- 完了後、SPEC のパスと未決事項を人に提示し、レビューと修正指示を求める (**承認まで実装しない**)
- 承認されたら `/plan` で実装プランを作る
- フロー全体の説明 (人向け・docs の寿命クラス込み) は references/workflow.md
