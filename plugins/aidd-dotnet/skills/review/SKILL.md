---
name: review
description: reviewer サブエージェントを起動し、原則適合・意図との整合・トレーサビリティでレビューする。
---

`reviewer` サブエージェントに、現在の変更のレビューを依頼する。

- 観点は `docs/review-checklist.md` が単一の基準。
- 結果(Critical / Major / Minor の指摘と、各指摘の次アクション)を受け取り、人に提示する。
