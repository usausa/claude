# テンプレート保守ガイド(原本のみ・最初に読む)

> このディレクトリは **template-aidd 原本の保守者(人 / AI)向け**。利用者には配布されない(`setup.ps1` が `.setup/` ごと削除する)。
> テンプレの利用方法は root の `README.md`、利用時の規約は `AGENTS.md`(いずれも配布物)。ここは**テンプレ自体を変更する**ときの正。

## 🎯 このテンプレートの本質(一言)

**「GitHub Spec Kit の SDD フロー(spec → plan → tasks → implement)を .NET × Claude Code に特化し、plan / tasks を一時物にして、ADR + 生成現状仕様 + 機械強制でドリフト対策を厚くしたテンプレート」**(解説と外部比較は [design.md](design.md))

## 📌 保守の原則(これに反する変更をしない)

1. **二重管理しない**: 規範は 1 箇所の「正」+ 参照に一本化する。複製・個名列挙は腐る(列挙が腐った実績あり)。意図的に許容する重複の基準は [decisions.md](decisions.md)。
2. **機械が守るものは文書化しない**: analyzer(SA1309 等)/ permission deny / hook が強制するルールを文書に書かない。
3. **superset + 確定時削除**: オプション(form / SDD / PM)は原本に全部置き、`setup.ps1` が非採用分の削除とマーカー解決で確定する。原本に「利用者向けでない情報」を置くときは、setup で消える場所(この `.setup/` か `template-dev` ブロック)に置く。
4. **命名原則**: 系名(web / desktop / mvvm)= 系の全般、技術名(api / blazor / wpf / winui)= 技術固有。skill はアプリ形態に依存しないフローのみとし、形態固有の規範・手順は rules に置く(`<platform>-xxx`、例: `blazor-e2e`)。
5. **文体**: 日本語。ASCII 記号・括弧は半角(中黒 `・` は全角のまま)、`§` 不使用、冗長・自明な括弧補足を書かない。h2 絵文字は docs 系のみ(`.claude/` と AGENTS / CLAUDE には付けない)。
6. **2 段プラグイン構成**: アーキ規範は 2 段で持つ — 第 1 段 `aidd-dotnet`(ライブラリ中立)/ 第 2 段 `aidd-smart`(Smart スタック標準の断定 + 詳細リファレンス)。序列は「プロジェクト rule > 第 2 段 > 第 1 段 > 外部」。旧上流 template-architecture の内容は本リポジトリへ統合する(移行中は `staging/` が原本の写し。作業プランは [plugin-plan.md](plugin-plan.md))。

## 🗺️ リポジトリの仕掛け(どこを触ると何が起きるか)

| 仕掛け | 場所 | 内容 |
|---|---|---|
| アーキ規範 rules | `setup.ps1` の `$commonRules` / `$formRules` / `$optionRules` | カタログ `.setup/rules/` から共通 + 採用系分 (+ `-Include grpc,cli` のオプション) を `.claude/rules/` へコピー(`paths:` で自動適用)。**winui.md は登録済み**(カタログに置くだけで採用される) |
| SDD ブロック | `<!-- sdd:xxx:start/end -->` × 9(AGENTS / docs/README / README / review-checklist / csharp-layered-feature) | **base は lite 本文をインライン保持**。lite=マーカー行のみ除去 / full=ブロックを `.setup/sdd/xxx-full.md` で置換 |
| SDD full 加算 | `.setup/sdd/full/`(リポジトリのミラーツリー) | full / full-pm 時に配置。spec・work-close・done・workflow・docs/work は**上書き**、spec-close・trace・docs/spec・traceability は**追加** |
| PM マーカー | `<!-- pm:xxx -->` × 4 | `-Sdd full-pm` で `.setup/pm/` から挿入、それ以外は除去 |
| 保守ブロック | `<!-- template-dev:start/end -->`(AGENTS.md / README.md) | setup が節ごと除去(原本専用の記述はここに書く) |
| 常時ロード | `CLAUDE.md` = `@AGENTS.md` の 1 行のみ | 固有メモを足さない(AGENTS が正) |

## 🔄 保守のフロー

1. 変更する(上の原則に従う)。**決定を伴うなら [decisions.md](decisions.md) に追記**、保留・未決は [backlog.md](backlog.md) へ(確定したら backlog から消して decisions へ)。
2. **検証**: `pwsh .setup/maintenance/test-setup.ps1` — form × SDD × PM の全シナリオで、マーカー解決・ファイル配置/削除・保守痕跡ゼロを確認する。**ALL PASS が完了条件**。
3. マーカー・オプション・form を増やしたら、`test-setup.ps1` にチェックを追加する。
4. `docs/reference/**` は deny で保護されている。保守で修正が必要なときは `settings.json` の deny を**一時解除 → 修正 → 即復元**する(生成物ガードは恒久維持)。
5. コミットは Conventional Commits(`.claude/skills/git-commit/` 準拠)。commit / push は人が実行。

## 📁 このディレクトリの構成

- `MAINTENANCE.md` — 本ファイル(入口)
- [decisions.md](decisions.md) — 確定した設計方針(テンプレ開発の決定記録・追記式)
- [backlog.md](backlog.md) — 未決の検討事項(TODO)
- [design.md](design.md) — 設計解説(構造と Claude 機構・GitHub Spec Kit 比較)
- [test-setup.ps1](test-setup.ps1) — `setup.ps1` の回帰テスト
- [plugin-plan.md](plugin-plan.md) — プラグイン化 2 段スタック構成の作業プラン(フェーズ・チェックリスト。方針決定済み・実行中)
- [refactor-lite-base.md](refactor-lite-base.md) — lite 基層化リファクタの方針書(実装済み・経緯記録)
- [command-map.md](command-map.md) — lite 基層化後のコマンド/エージェント/スキル最終形リファレンス
- [restructure-context.md](restructure-context.md) — コンテキスト構造再設計(発火条件ベース)の方針書(実装済み・経緯記録)
- [drivenplatform-handover.md](drivenplatform-handover.md) — その入力(DrivenPlatform 検討からの申し送り・調査結果)
