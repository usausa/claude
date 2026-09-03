---
name: adr
description: 設計上の決定の ADR ドラフトを docs/adr に用意する (手動編集が基本・作製タイミングは任意。過去の ADR は編集しない)。
---

> 引数: [決定のタイトル]

`docs/adr/` に Architecture Decision Record のドラフトを**追記**する。ADR は**手動編集が基本**で、このコマンドは枠の用意とドラフト作製の支援。

手順:
0. `docs/adr/` が無ければ作成し、references/0001-record-architecture-decisions.md(ADR 導入の初期決定)を最初の ADR として置く
1. `docs/adr/*.md` を Glob し、既存の最大連番 +1 を採番
2. 本 skill の references/adr-template.md を雛形に、`$ARGUMENTS` をタイトルとして `NNNN-<kebab-title>.md` を作成
3. 本文の「背景 / 決定 / 検討した代替案 / 結果 (得たもの / 捨てたもの / 将来への注意)」を、直近の会話・変更内容から**ドラフトとして**埋める (確定は人の編集・承認)
4. frontmatter に `tags` (1〜3 個。語彙はアーキ規範 rule の分類語 (data / api / logging 等) を第一候補に、足りなければ `docs/glossary.md`) と `related` (関連 ADR / SPEC) を付ける
5. `docs/adr/index.md` を**全 ADR の frontmatter から再生成**する (index は生成物。手編集しない。時系列表 + タグ別の 2 部構成)
6. **過去の ADR は絶対に編集しない** (追記のみ。メタデータ行の追加・更新のみ許容)。決定を覆す場合は:
   - 新しい ADR を起こして決定を記述
   - 旧 ADR の `status` を `superseded` にし、`superseded-by` に新 ID を記す
   - 覆した決定に関連するプロジェクト rule (`.claude/rules/`) の見直しも検討する
7. この決定から日々守る**書き方の制約**が生じたなら、`rule-create` の手順で rules 化を提案する (ADR と rules は独立保管・相互リンクなし)
8. 生成したドラフトの要点を提示し、人の編集・承認を求める
