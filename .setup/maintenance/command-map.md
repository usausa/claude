# 最終形リファレンス: コマンド / エージェント / スキル体系

> lite 基層化後の**目標状態のみ**(旧記述は含まない)。層 = 基層(lite) ⊂ +full ⊂ +PM。
> 変更の意図・移行・影響は [refactor-lite-base.md](refactor-lite-base.md)。**実装済み(2026-07)**(本書は最終形リファレンス)。
> 値名・パラメータ名は `-Sdd lite|full|full-pm`(既定 `full`)で確定。

## 🧱 基層(lite) — 常に存在

### ループ定常段(順に打つ)
| コマンド | 役割 | 生成物 | 委譲 / skill | model |
|---|---|---|---|---|
| `/spec <箇条書き>` | 一時仕様の草案 | `docs/work/`(作業フォルダ) | `spec` agent | 継承 |
| `/plan` | 実装プラン(チェックリスト・フェーズ分割) | `docs/work/`(作業フォルダ) | ― | 継承 |
| `/impl` | フェーズ実装 | `src/` | `csharp-layered-feature` | 継承(安価に切替可・opt-in) |
| `/verify` | build(警告0)+ 静的解析 + test + 自己修正 | ― | ― | 継承 |
| `/review` | 観点レビュー | ― | `reviewer` agent | 継承 |
| `/review-cross` | 別ベンダー(Codex)クロスレビュー | ― | ― | ― |
| `/done` | DoD ゲート + クローズ (片付け) + コミット提示 | 作業フォルダ削除 | `work-close`, `git-commit` | 継承 |

### オンデマンド(トリガが立ったら随時)
| コマンド | いつ | 生成物 | 委譲 / skill |
|---|---|---|---|
| `/adr <決定>` | 設計上の決定をした (ドラフト支援 + index 再生成) | `docs/adr/NNNN-*.md` | `adr-guide`, `rule-create` |
| `/reference` | Web API / 型 / DB を変えた | `docs/reference/`(生成物) | `doc-sync` agent / `sync-docs-from-code` |

### エージェント / スキル(基層)
- **agents**: `spec` / `reviewer` / `doc-sync`
- **skills**: `work-init`(初期化・任意)/ `work-close`(完了 = 片付け)/ `adr-guide` / `rule-create`(プロジェクト固有 rule の追加)/ `csharp-layered-feature` / `sync-docs-from-code` / `git-commit`(全て形態非依存)
- **rules**: `.claude/rules/`(アーキ規範。setup が `.setup/rules/` カタログから共通 + 採用形態分をコピー。旧 blazor-playwright skill は `blazor-e2e` rule 化)
- **一時領域**: `docs/work/`(git 管理・完了時に削除。SPEC / PLAN を外部化 → 別セッション・別マシン・worktree から現在地を復元できる。解決規則は `docs/work/README.md`)

## ➕ full 差分(-Sdd full)

spec を「足場」から「恒久の軽量意図」に変える層。ループの形は基層と同一。

| 変わる/増える | 内容 |
|---|---|
| `/spec` の出力 | `docs/work/` の一時 SPEC → **`docs/spec/SPEC-NNNN-<title>.md`**(恒久・採番)。`spec` agent は恒久版で上書き |
| `/done` の close | `spec-close`(SPEC を蒸留して残す。full で追加)+ `work-close` は full 版(PLAN 片付け)に上書き |
| 追加コマンド | **`/trace`**(SPEC↔ADR↔test↔code の整合検査 → `docs/traceability/index.md`) |
| 追加成果物 | `docs/spec/`(+ `_template.md`)/ `docs/traceability/` |
| 不変 | `/plan`・`/impl`・`/verify`・`/review`・`/reference`・`/adr`。PLAN は full でも一時物 |

## ➕ PM 差分(-PM 相当・full 前提)

1 機能ループの 1 段上に、複数 feature の計画・進捗を足す層。恒久 SPEC 群を台帳にするため full 必須。

| コマンド | 役割 | 生成物 | 委譲 |
|---|---|---|---|
| `/pm-plan <狙い>` | feature 単位のイテレーション計画(恒久 SPEC を backlog に) | `docs/pm/iteration-plan.md` | `pm` agent |
| `/pm-status` | SPEC/ADR/test/traceability から feature 単位で進捗集計 | `docs/pm/progress.md` | `pm` agent |

方針は `docs/pm/README.md`。WBS / フェーズゲートは使わない。

## 🔤 命名原則

- **接頭辞グルーピング**: コマンド + 補助 skill/agent は共通接頭辞 — `spec-*`(spec, spec-close)/ `work-*`(work-init, work-close)/ `adr-*`(adr, adr-guide)/ `review-*`(review, review-cross)。横断 skill(`git-commit` 等)は対象外。
- **taxonomy**: 「ループ定常段」と「オンデマンド」の 2 分類。オンデマンドは機能開発中に随時起動する(`/adr` を全体方針限定としない)。
- **`/plan`(機能の中の実装計画) ≠ `/pm-plan`(機能をまたぐ計画)**。

## 🎚️ setup オプション(排他選択)

- `-Form maui|web|desktop|worker`(必須・直交軸)。
- `-Sdd lite|full|full-pm`(単一排他・既定 `full`)。`lite ⊂ full ⊂ full-pm` の加算。
- `-Include grpc,cli`(任意・複数可)。オプション rules を追加配置。
