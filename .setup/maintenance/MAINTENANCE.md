# 保守ガイド(最初に読む)

> このディレクトリは **aidd プラグイン(aidd-dotnet / aidd-smart / aidd-flow / aidd-pm)の保守者(人 / AI)向け**。利用者には配布されない。
> 移行中: 旧 setup.ps1 テンプレート方式は退役済み。**作業プランの正は [plugin-plan.md](plugin-plan.md)**(フェーズ・チェックリスト)。

## 🎯 この成果物の本質(一言)

**「GitHub Spec Kit の SDD フロー(spec → plan → tasks → implement)を .NET × Claude Code に特化し、plan / tasks を一時物にして、ADR + 生成現状仕様 + 機械強制でドリフト対策を厚くした開発基盤」を、私有 Claude Code プラグイン 4 本(ルール = aidd-dotnet / aidd-smart、ワークフロー = aidd-flow / aidd-pm)として配布する**(解説と外部比較は [design.md](design.md))

## 📌 保守の原則(これに反する変更をしない)

1. **二重管理しない**: 規範は 1 箇所の「正」+ 参照に一本化する。複製・個名列挙は腐る(列挙が腐った実績あり)。意図的に許容する重複の基準は [decisions.md](decisions.md)。
2. **機械が守るものは文書化しない**: analyzer(SA1309 等)/ permission deny / hook が強制するルールを文書に書かない。
3. **プラグインは常に全部を持ち、必要分を選択展開する**: 配布物(プラグイン)に superset を持たせ、プロジェクトへの確定は init(skill + スクリプト)が行う。利用者向けでない情報は `.setup/` と `staging/` に置く(プラグインに含めない)。
4. **命名原則**: 系名(web / desktop / mvvm)= 系の全般、技術名(api / blazor / wpf / winui)= 技術固有。規範はプラグイン内 `.claude/rules/` の managed rule(`dotnet-*` / `smart-*`。init が `.claude/rules/` へ上書き展開 — skill の `paths:` は強制注入しないため rules 配布に回帰、経緯は decisions)。skill はフロー・手順と references の器のみ。
5. **文体**: 日本語。ASCII 記号・括弧は半角(中黒 `・` は全角のまま)、`§` 不使用、冗長・自明な括弧補足を書かない。h2 絵文字は docs 系のみ(`.claude/` と AGENTS / CLAUDE には付けない)。
6. **4 プラグイン構成(ルール 2 + ワークフロー 2)**: ルール系 = 第 1 段 `aidd-dotnet`(ライブラリ中立)/ 第 2 段 `aidd-smart`(Smart スタック標準の断定 + 詳細リファレンス。dotnet に依存)、ワークフロー系 = `aidd-flow`(spec / plan / 実装の基本フロー。独立)/ `aidd-pm`(PM アドオン。flow に依存)。規範の序列は「プロジェクト rule > smart > dotnet > 外部」。旧上流 template-architecture の内容は本リポジトリへ統合済み(要約の正 = プラグイン内 `.claude/rules/`、詳細の正 = 器 skill の references/)。

## 🗺️ リポジトリの構成(どこを触ると何が起きるか)

| 場所 | 内容 |
|---|---|
| `.claude/` | 第 1 段の素材(rules / skills / commands / agents / hooks)。Phase 2 で `plugins/aidd-dotnet/` へ変換する。それまで本リポジトリでの Claude 作業にもそのまま効く |
| `.setup/rules/` | 規範カタログ(第 1 段 rules の原本) |
| `.setup/pm/` | 旧 SDD full-pm の挿入素材(init の確定ロジックで使う予定) |
| `staging/templates-neutral/` | 旧テンプレ骨格 = **init の素材**(src / tests / docs / ルート定型一式) |
| `docs/` | 旧テンプレの配布 docs(Phase 2 で templates へ再編し整理) |
| `plugins/`(Phase 2〜) | 配布物の実体(aidd-dotnet / aidd-smart / aidd-flow / aidd-pm) |
| `.claude-plugin/marketplace.json`(Phase 4) | 私有 marketplace 定義 |

## 🔄 保守のフロー

1. 変更する(上の原則と [plugin-plan.md](plugin-plan.md) のフェーズに従う)。**決定を伴うなら [decisions.md](decisions.md) に追記**(覆すときは新項 + 旧項に取り消し注記)、保留・未決は [backlog.md](backlog.md) へ。
2. **検証**: `pwsh .setup/maintenance/test-plugins.ps1` — プラグイン構造(plugin.json・参照 JSON・skill frontmatter・hooks)と init の実動スモークを検証する。**ALL PASS が完了条件**。
3. コミットは Conventional Commits。commit / push は人が実行。

## 📁 このディレクトリの構成

- `MAINTENANCE.md` — 本ファイル(入口)
- [decisions.md](decisions.md) — 確定した設計方針(開発の決定記録・追記式)
- [backlog.md](backlog.md) — 未決の検討事項(TODO)
- [plugin-plan.md](plugin-plan.md) — プラグイン化 2 段スタック構成の作業プラン(フェーズ・チェックリスト。実行中)
- [test-plugins.ps1](test-plugins.ps1) — プラグイン構造 + init 実動スモークの回帰テスト(ALL PASS が完了条件)
- [architecture-topics.md](architecture-topics.md) — アーキ規範 93 本のトピックカタログと蒸留時の決定事項(第 2 段 20 分類の対応表・経緯記録)
- [design.md](design.md) — 設計解説(構造と Claude 機構・GitHub Spec Kit 比較。テンプレ時代の記述を含む)
- [command-map.md](command-map.md) — lite 基層化後のコマンド/エージェント/スキル最終形リファレンス(テンプレ時代の経緯記録)
- [refactor-lite-base.md](refactor-lite-base.md) — lite 基層化リファクタの方針書(実装済み・経緯記録)
- [restructure-context.md](restructure-context.md) — コンテキスト構造再設計(発火条件ベース)の方針書(実装済み・経緯記録)
- [drivenplatform-handover.md](drivenplatform-handover.md) — その入力(DrivenPlatform 検討からの申し送り・調査結果)
