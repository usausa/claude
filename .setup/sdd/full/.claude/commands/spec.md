---
description: 機能の仕様 (SPEC) を草案化する。恒久 spec として docs/spec/ に採番作成。承認後 /plan へ。
argument-hint: [機能の一言またはアイディアの箇条書き]
allowed-tools: Read, Grep, Glob, Write
---

`spec` サブエージェントに、次の機能の仕様 (SPEC) 草案を依頼する:

$ARGUMENTS

- 出力先: `docs/spec/SPEC-NNNN-<title>.md`(採番は既存の最大 +1。様式はサブエージェント定義のとおり)
- 起案時に `docs/adr/index.md` を確認し、関連する既存決定と矛盾する場合は SPEC に明記して人に確認する
- 完了後、作成された SPEC-ID と未決事項を人に提示し、レビューと修正指示を求める(**承認まで実装しない**)
- 承認されたら `/plan` で実装プランを作る
