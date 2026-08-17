# 開発ワークフロー (人が読む運用手順書)

> この文書は**人向けの運用手順書**。**機能を 1 つ作る/直すたびに開き**、各段階で下の「打つもの」を実行する。
> SDD lite 方針: **仕様 (SPEC) と実装プラン (PLAN) は作業フォルダ `docs/work/` の一時物** (git 管理・完了時に削除)。
> 恒久に残すのは 決定=`ADR` / 用語=`glossary` / 受け入れ条件=**テスト名** / 現状仕様=生成+テスト。

## 📚 読む文書の使い分け
- **AI が常時従う**: `CLAUDE.md`→`AGENTS.md` (規約) / `docs/README.md`(寿命表)
- **対象ファイルを読むと自動適用**: `.claude/rules/*` (アーキ規範。`paths:` で発火)
- **AI は呼ばれた時だけ動く**: `.claude/commands`・`skills`・`agents`・`hooks`
- **人が読む (この文書・`README`)**: どの順で何を打つか

---

## 🔄 全体像 (ループ)

```
0. (任意) work-init ──▶ 作業ブランチ + docs/work/<branch-slug>/ を用意
決定が要る？ ──yes──▶ /adr (Why を残す・過去 ADR は編集しない)
    │no
    ▼
1. /spec <アイディアの箇条書き>  ──▶ 作業フォルダに SPEC 草案
2. 人がレビュー & AI に修正指示 ──▶ OK なら承認
3. /plan  ──▶ 作業フォルダに PLAN (チェックリスト。大きければフェーズ分割) → 人が承認
4. /impl でフェーズ単位に実装 + チェック更新 + フェーズ末 /verify
5. /reference (Web API・型・DB を変えたら reference 再生成)
6. /review (+ /review-cross) で観点チェック。途中で他者レビューを受けるならコミット + push (git-commit skill)
7. /done  ──▶ DoD + クローズ (work-close) → SPEC / PLAN 削除・最終プッシュ・ブランチ削除の提示
8. 人間が git commit / push (AI はコマンド提示のみ)
```

---

## 📌 各段階: 具体的に何を打つか

> 例文はコピペしてそのまま使える。`<...>` は置き換える。

### 1. 仕様を作る (SPEC)
- **打つもの**: `/spec <アイディアの箇条書き>`
- **例**: `/spec ファイルにタグを付けられる。タグで絞り込み検索。タグは複数付与可`
- **触るファイル**: 作業フォルダの SPEC (`docs/work/<branch-slug>/SPEC.md` または `docs/work/SPEC-<topic>.md`。解決規則は `docs/work/README.md`)
- **ポイント**: 出てきた「未決事項」に答える。

### 2. レビュー & 修正指示
- SPEC を人が読み、AI に修正指示 (会話でよい)。OK なら「承認」と伝える。**承認まで実装しない**。

### 3. 実装プランを作る (PLAN)
- **打つもの**: `/plan`
- **触るファイル**: 作業フォルダの PLAN (チェックリスト。大きければフェーズ分割)
- **ポイント**: 人がレビューして承認。フェーズ = 独立して `/verify` が緑になる単位。

### 4. フェーズ単位で実装する
- **打つもの**: `/impl`(または自然文。`csharp-layered-feature` スキルが自動ロード)
- **例**: `/impl SPEC-tags のフェーズ 1`
- **自動**: 編集のたびに hooks が format / 正規化を検証 (逆ループ)
- フェーズ完了ごとに PLAN のチェックを `- [x]` に更新し、`/verify` (build + test) で緑を確認する。

### 5. 現状仕様を同期する (reference) ※Web API・型・DB を変えたら
- **打つもの**: `/reference`
- **触るファイル**: `docs/reference/` (生成物・手編集禁止)

### 6. レビュー
- **打つもの**: `/review` (Claude) + 必要に応じて `/review-cross` (Codex)
- **ポイント**: 指摘ごとの次アクション (`/adr`・`/reference` 等) に従い、両者 (Claude / Codex) の Critical が消えるまで完了としない。

### 7. 完了ゲート + クローズ (片付け)
- **打つもの**: `/done`
- **やること**: build + test 緑 / reference / ADR / テスト名への受け入れ条件反映 を一括判定 →
  `work-close` の手順で蒸留漏れ (決定→ADR / 用語→glossary) を確認し、作業フォルダの SPEC / PLAN を**削除** → 最終プッシュ・ブランチ削除を提示する。

### 8. コミット (人が実行)
- AI が提示した git コマンドを人が実行。commit / push は必ず人。

---

## 🧩 コマンド早見表

| コマンド | いつ | 主体 |
|---|---|---|
| `/spec <箇条書き>` | 一時仕様 (SPEC) の草案 | 人 |
| `/plan` | 実装プラン (チェックリスト) | 人 |
| `/impl` | フェーズ実装 | 人 |
| `/adr <決定>` | 決定・トレードオフを残す | 人 |
| `/verify` | build + test 実行(自己修正) | 人 / AI |
| `/reference` | Web API/型/DB を変えた | 人 |
| `/review` / `/review-cross` | レビュー(Claude / Codex) | 人 |
| `/done` | DoD ゲート + クローズ (work-close) | 人 |

---

## 🔁 途中参加・別セッションからの再開

- 新しいチャットでも `CLAUDE.md` (→ `AGENTS.md`) は自動で効き、`.claude/rules/*` も対象ファイルを読んだ時点で自動適用されるので、規約・原則は引き継がれる。
- まず現在地を掴む: `docs/work/` の SPEC / PLAN (チェックリスト) を見る。工程の状態は git 管理のファイルに外部化されるため、新セッション・別マシン・worktree でも clone すれば現在地を復元できる。
- `docs/work/` に SPEC / PLAN が無い = 仕掛かりなし。
