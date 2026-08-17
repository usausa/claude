# 開発ワークフロー (人が読む運用手順書)

> この文書は**人向けの運用手順書**。**機能を 1 つ作る/直すたびに開き**、各段階で下の「打つもの」を実行する。
> AI 側の振る舞いは、`/`コマンド・skill・hook が呼ばれたときにそれぞれのファイルが駆動する。

## 📚 読む文書の使い分け
- **AI が常時従う**: `CLAUDE.md`→`AGENTS.md` (規約) / `docs/README.md`(寿命表)
- **対象ファイルを読むと自動適用**: `.claude/rules/*` (アーキ規範。`paths:` で発火)
- **AI は呼ばれた時だけ動く**: `.claude/commands`・`skills`・`agents`・`hooks`
- **人が読む (この文書・`README`)**: どの順で何を打つか

---

## 🔄 全体像 (ループ)

```
決定が要る？ ──yes──▶ /adr (Why を残す・過去 ADR は編集しない)
    │no
    ▼
1. /spec <機能の一言>  ──▶ docs/spec/SPEC-NNNN-*.md 草案(採番)
2. 人がレビュー & AI に修正指示 ──▶ OK なら承認
3. /plan  ──▶ work/PLAN-*.md (チェックリスト。大きければフェーズ分割) → 人が承認
4. /impl でフェーズ単位に実装 + チェック更新 + フェーズ末 /verify
5. /reference (Web API・型・DB を変えたら reference 再生成)
6. SPEC の意図が変わったなら同じ変更内で更新
7. /review (+ /review-cross) で観点チェック
8. /done ──▶ DoD ゲート + クローズ蒸留 (spec-close: SPEC を蒸留して残す・PLAN を削除)
9. 人間が git commit (AI はコマンド提示のみ)
```

---

## 📌 各段階: 具体的に何を打つか

> 例文はコピペしてそのまま使える。`<...>` は置き換える。

### 1. 仕様を作る (SPEC)
- **打つもの**: `/spec <機能の一言説明>`
- **例**: `/spec ファイルのタグ付けと、タグでの絞り込み検索`
- **触るファイル**: `docs/spec/SPEC-NNNN-*.md` (新規草案) / 雛形 `_template.md`
- **ポイント**: 出てきた「未決事項」に答えてから承認。**承認まで実装しない**。

### 2. 決定を残す (ADR) ※決定・トレードオフがあれば
- **打つもの**: `/adr <決定の一言>`
- **例**: `/adr タグ検索は DB の全文検索でなく LIKE + インデックスで実装する`
- **触るファイル**: `docs/adr/000X-*.md` (追記) / `docs/adr/index.md`

### 3. 実装プランを作る (PLAN)
- **打つもの**: `/plan`
- **触るファイル**: `work/PLAN-*.md`(チェックリスト。git 管理外の一時物)
- **ポイント**: 人がレビューして承認。フェーズ = 独立して `/verify` が緑になる単位。小さな変更はプランを省略してよい。

### 4. フェーズ単位で実装する
- **打つもの**: `/impl`(または自然文。`csharp-layered-feature` スキルが自動ロード)
- **例**: `/impl SPEC-0002 のフェーズ 1`
- **参考にする既存実装・外部情報(参照プロジェクト、Microsoft Learn MCP 等)があれば依頼に添える**。
- **自動**: 編集のたびに `hooks/dotnet-verify.ps1` が `dotnet format` 検証→差分を返す (逆ループ)
- フェーズ完了ごとに PLAN のチェックを更新し、`/verify`(build + test)で緑を確認する。大きな手戻りは早期に潰す(フェーズの区切りで人が確認)。

### 5. 現状仕様を同期する (reference) ※Web API・型・DB を変えたら
- **打つもの**: `/reference`
- **触るファイル**: `docs/reference/` (生成物・手編集禁止)

### 6. 意図の更新 ※SPEC の意図が変わったら
- **同じ変更(PR)の中で** `docs/spec/SPEC-*.md` を更新する(蒸留は `/done` の段で `spec-close` が行う)。

### 7. レビュー
- **打つもの**: `/review` (Claude) + 必要に応じて `/review-cross` (別ベンダー Codex で観点を共有してクロスレビュー)
- **触るファイル**: 読込 `docs/review-checklist.md` (観点)・SPEC・`docs/reference`
- **ポイント**: 指摘ごとの次アクション (`/adr`・`/reference` 等) に従い、両者 (Claude / Codex) の Critical が消えるまで完了としない。

### 8. 完了ゲート + クローズ蒸留
- **打つもの**: `/done`
- **やること**: build + test 緑(`/verify`) / `docs` 更新 / ADR 有無 / `/trace` 整合(退役漏れ)を一括判定 →
  `spec-close` の手順で SPEC を**蒸留して残し**(status 更新)、`work/` の PLAN を削除する。最後に AI が git コマンドを提示。

### 9. コミット (人が実行)
- AI が提示した git コマンドを人が実行。commit / push は必ず人。

---

## 🧩 コマンド早見表

| コマンド | いつ | 主体 |
|---|---|---|
| `/spec <一言>` | 仕様 (SPEC) の草案 | 人 |
| `/plan` | 実装プラン (チェックリスト) | 人 |
| `/impl` | フェーズ実装 | 人 |
| `/adr <決定>` | 決定・トレードオフを残す | 人 |
| `/verify` | build + test 実行(自己修正) | 人 / AI |
| `/reference` | Web API/型/DB を変えた | 人 |
| `/review` / `/review-cross` | レビュー(Claude / Codex) | 人 |
| `/trace` | ID 整合・決定漏れ・退役候補の検査 | 人 |
| `/done` | DoD ゲート + クローズ蒸留 | 人 |

---

<!-- pm:workflow-iteration -->

## 🔁 途中参加・別セッションからの再開

- 新しいチャットでも `CLAUDE.md` (→ `AGENTS.md`) は自動で効き、`.claude/rules/*` も対象ファイルを読んだ時点で自動適用されるので、規約・原則は引き継がれる。
- まず現在地を掴む: `docs/README.md`(寿命表)・`work/`(PLAN)・`docs/traceability/index.md` (対応表) を見る。
- 続きから: `/trace` で未整合・決定漏れを洗い出し、該当段階のコマンドを打つ。
- このドキュメントフレームワークは**会話履歴を前提とした短い引き継ぎに依存しない**設計思想を採る。工程の状態は成果物ファイル (SPEC/PLAN/ADR/trace) に外部化されるため、履歴が無い新セッションでも現在地をファイルから復元できる。
