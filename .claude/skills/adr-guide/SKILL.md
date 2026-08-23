---
name: adr-guide
description: Architecture Decision Record(ADR)に何をどう書くか(内容・構成・粒度)。設計上の決定をした/迷ったとき、なぜその選択をしたかを残すために使う。
---

# ADR の書き方(内容と粒度)

> 作成手続き(採番・`index.md` 再生成・superseded の付け替え)は `/adr` コマンドが正。ここは**何をどう書くか**のみ。ADR は手動編集が基本・作製タイミングは任意。

- **1 ADR = 1 決定**。「なぜこの選択をし、何を捨てたか」を残す(現状仕様は書かない)。
- 構成(`_template.md` 準拠): 背景 / 決定 / 検討した代替案 / 結果は **3 点セット**(得たもの / 捨てたもの / 将来への注意)。
- 粒度の目安: 「後から誰かが『なぜこうなってる?』と聞く」ものは ADR にする。
  例: 認証方式の選定、DI コンテナの選定、例外を戻り値にする方針、DB を SQLite にした理由。
- 迷い(trade-off があった判断)は、結論が平凡でも残す価値がある。
- `tags` は 1〜3 個。語彙は `.claude/rules/` のファイル名(data / api / logging 等)を第一候補に、足りなければ `docs/glossary.md` のドメイン語。何でも入るタグ(「共通」等)は使わない。
- ADR と `.claude/rules/` は**独立して保管**する(相互リンクを持たない)。決定から日々守る書き方の制約が生じたなら `rule-create` で rules 化する。決定を覆した(supersede)ときは、関連するタグの rules の見直しも検討する。

作成後、関連する SPEC の `related` に ADR-ID を追記する。

## 見本 ([references/](references/))

性格の違う 4 本のサンプルを同梱。書き出しに迷ったら近い性格のものを参照する (利用時は採番・実日付にして `docs/adr/` へ):

- [sample-01](references/sample-01-microorm-2way-sql.md) — 技術選定 (Micro-ORM + 2-way SQL)
- [sample-02](references/sample-02-valuetask-no-ct.md) — **一般則からの意図的逸脱** (CancellationToken 非伝播。async rule の「非伝播は /adr」の実例)
- [sample-03](references/sample-03-singleton-asynclocal.md) — プロジェクト方針 (DI 全 Singleton + AsyncLocal)
- [sample-04](references/sample-04-realdb-scenario-test.md) — テスト戦略 (実 DB シナリオテスト opt-in)
