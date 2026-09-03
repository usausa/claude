# 開発ワークフロー (人が読む運用手順書)

> 機能を 1 つ作る / 直すたびに、各段階で「打つもの」を実行する。
> SDD レベルはプロジェクトの `.claude/rules/aidd.md` の宣言で決まる (/aidd-flow:init が確定)。
> **lite**: SPEC / PLAN は作業フォルダ `docs/work/` の一時物 (完了時に削除)。**full**: SPEC は `docs/spec/` の恒久文書 (蒸留して残す)。PLAN は全レベルで一時物。

## ループ

```
0. (任意) work-init ──▶ 作業ブランチ + docs/work/<branch-slug>/ を用意
決定が要る？ ──yes──▶ /adr (Why を残す・過去 ADR は編集しない)
    │no
    ▼
1. /spec <アイディアの箇条書き> ──▶ SPEC 草案 (lite: 作業フォルダ / full: docs/spec/SPEC-NNNN 採番)
2. 人がレビュー & AI に修正指示 ──▶ OK なら承認 (承認まで実装しない)
3. /plan ──▶ 作業フォルダに PLAN (チェックリスト。大きければフェーズ分割) → 人が承認
4. /impl でフェーズ単位に実装 + チェック更新 + フェーズ末 /verify
5. /reference (Web API・型・DB を変えたら再生成。full: SPEC の意図が変わったら同じ変更内で更新)
6. /review (+ /review-cross) で観点チェック。途中で他者レビューを受けるならコミット + push (git-commit skill)
7. /done ──▶ DoD ゲート + クローズ (lite: work-close で SPEC / PLAN 削除 / full: spec-close で SPEC を蒸留して残し + /trace 整合 + work-close で PLAN 削除)
8. 人間が git commit / push (AI はコマンド提示のみ)
```

## 各段階の要点

| 段階 | 打つもの | 要点 |
|---|---|---|
| 仕様 | `/spec <箇条書き>` | 未決事項に答えてから承認。lite = 作業フォルダの SPEC.md / full = `docs/spec/SPEC-NNNN-*.md` |
| 決定 | `/adr <決定の一言>` | 決定・トレードオフがあれば。過去 ADR は編集しない |
| プラン | `/plan` | フェーズ = 独立して `/verify` が緑になる単位。小変更は省略可 |
| 実装 | `/impl` | フェーズ毎に PLAN のチェック更新 + `/verify`。参考実装・外部情報があれば依頼に添える |
| 現状仕様 | `/reference` | `docs/reference/` は生成物・手編集禁止 |
| レビュー | `/review` / `/review-cross` | 指摘ごとの次アクションに従い、Critical が消えるまで完了としない |
| 完了 | `/done` | DoD 一括判定 → クローズ。full は蒸留 (spec-close)・`/trace` 込み |

## docs の寿命クラス (何を手で守り・生成し・追記するか)

| 場所 | 種別 | 寿命 | 維持 |
|---|---|---|---|
| `docs/adr/` | Why (決定理由) | 不変 | 追記のみ。過去 ADR は編集しない。`index.md` は frontmatter からの生成物 |
| `.claude/rules/` | 原則・方針 | 長 | `dotnet-*` / `smart-*` は managed (init が上書き更新)。プロジェクト固有は `conventions.md` |
| `docs/work/` | SPEC (lite) / PLAN (一時物) | 破棄 | 完了時にクローズ蒸留 (決定→ADR / 用語→glossary / 受け入れ条件→テスト名) して削除。git 履歴には残る |
| `docs/spec/` (full) | 意図 (恒久) | 長 | 蒸留して軽量に保つ (spec-close)。実装詳細は書かない |
| `docs/reference/` | What/How (現状仕様) | 短 (生成) | 手書き禁止。Web=OpenAPI、振る舞い=テストが正 |
| `docs/glossary.md` | 語彙 | 長 | 語彙・意味・英語名のみ |
| コード書式・品質 | What | — | `.editorconfig` + analyzer で機械強制・警告 0 |

原則: **Why は残す・What/How は生成する・書式は機械が守る**。コードや DB で分かる情報は文書化しない。一時物は完了後に破棄する。

## 途中参加・別セッションからの再開

- 規約・規範は `.claude/rules/` が自動適用されるため引き継がれる。
- 現在地は git 管理のファイルから復元する: `docs/work/` の SPEC / PLAN (チェックリスト)、full なら `docs/spec/` と `/trace` の結果。
- `docs/work/` に SPEC / PLAN が無い = 仕掛かりなし。
