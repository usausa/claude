---
description: アイディアの箇条書きから一時仕様 (SPEC) を作業フォルダ (docs/work) に草案化する。承認後 /plan へ。
argument-hint: [アイディアの箇条書き]
allowed-tools: Read, Grep, Glob, Write
---

`spec` サブエージェントに、次のアイディアから一時仕様 (SPEC) の草案を依頼する:

$ARGUMENTS

- 出力先: 作業フォルダ(`docs/work/<branch-slug>/SPEC.md`、ブランチフォルダが無ければ `docs/work/SPEC-<topic>.md`。解決規則は `docs/work/README.md`。様式はサブエージェント定義のとおり)
- 完了後、SPEC のパスと未決事項を人に提示し、レビューと修正指示を求める(**承認まで実装しない**)
- 承認されたら `/plan` で実装プランを作る
