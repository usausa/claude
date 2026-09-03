# aidd — C# × Claude Code プラグイン(2 段スタック構成)

私有配布の Claude Code プラグイン marketplace。C# / .NET の AI 駆動開発を 2 段のプラグインで支援する。

| プラグイン | 内容 |
|---|---|
| [aidd-dotnet](plugins/aidd-dotnet/README.md)(AIDD for .NET) | C# / .NET 標準のアーキ規範 rules(ライブラリ中立)+ コード品質 hooks + MCP |
| [aidd-smart](plugins/aidd-smart/README.md)(AIDD Smart Architecture) | Smart 系スタック標準の断定 + 詳細リファレンス 69 本。`aidd-dotnet` に依存 |
| [aidd-flow](plugins/aidd-flow/README.md)(AIDD Flow) | spec / plan / 実装の基本ワークフロー(SDD フロー + ADR + DoD)。単独導入可・.NET では aidd-dotnet 併用を推奨 |
| [aidd-pm](plugins/aidd-pm/README.md)(AIDD Project Management) | 基本ワークフローに加えて feature 単位の PM(イテレーション計画 + 進捗)。`aidd-flow` に依存・SDD full 前提 |

序列: **プロジェクト rule > aidd-smart > aidd-dotnet > 外部 skill / MCP**。第 1 段はライブラリ選定を断定せず(選定は `/adr`)、第 2 段が標準スタックを断定する。

## 導入

私有リポジトリのため、事前に git 認証を済ませておく(SSH キー、または `gh auth login`。`GITHUB_TOKEN` 環境変数からの自動認証はない)。

```
/plugin marketplace add usausa/template-spec
```

導入パターンは 2 つ:

```
# Smart スタック標準で開発する場合(依存で aidd-dotnet も有効化される)
/plugin install aidd-smart@aidd

# ライブラリ中立の規律だけ使う場合
/plugin install aidd-dotnet@aidd

# spec / plan / 実装の基本ワークフローを使う場合
/plugin install aidd-flow@aidd

# 基本ワークフローに加えて PM (イテレーション計画・進捗) も使う場合
/plugin install aidd-pm@aidd
```

導入後に各プラグインの init を実行する: `/aidd-dotnet:init`(dotnet rules 展開)/ `/aidd-flow:init [lite|full]`(SDD レベル宣言 aidd.md の生成)/ `/aidd-smart:init`(smart rules 展開)。**展開されるのは `.claude/rules/` のみ**で、規範 rules は managed(init 再実行で上書き更新)・対象ファイルを読むと `paths:` で自動適用される。AGENTS.md / README / ビルド設定はアプリ側で用意し、docs 骨格(adr / work / spec / reference / pm)は各フロー skill が必要時に生成する。

更新は以下(version が上がったときに反映される):

```
/plugin marketplace update aidd
/plugin update aidd-dotnet@aidd
/plugin update aidd-smart@aidd
/plugin update aidd-flow@aidd
/plugin update aidd-pm@aidd
```

更新後は **rules 系の init を再実行**して規範を最新化する(`/aidd-dotnet:init` + smart 利用時 `/aidd-smart:init`。上書きされるのは `.claude/rules/` の managed ファイルだけで、他には触れない)。フロー skill・agents・hooks・MCP・references はプラグイン本体から直接提供されるため update だけで最新になる。

## バージョン運用

利用側の更新検知は `plugin.json` の `version` 比較のみ。**内容を変えたら必ずバンプする**(references 1 本の改稿でも)。2 プラグインは独立にバンプし、目安はパッチ = 既存内容の改稿・修正 / マイナー = skill・展開内容・hooks / MCP 構成の増減 / メジャー = 構成の転換。詳細は [decisions.md](.setup/maintenance/decisions.md)。

## リポジトリ構成

| 場所 | 内容 |
|---|---|
| `.claude-plugin/marketplace.json` | marketplace 定義(2 プラグイン・相対パス source) |
| `plugins/aidd-dotnet/` | .NET 標準ルール(`.claude/rules/` 20 / init / 品質 hooks / MCP) |
| `plugins/aidd-smart/` | Smart アーキルール(`.claude/rules/` 19 / references の器 skills 19 + references 69 / init) |
| `plugins/aidd-flow/` | 基本ワークフロー(フロー skills 19 / agents 3 / DoD hook / init = aidd.md 生成) |
| `plugins/aidd-pm/` | PM アドオン(pm-plan + references 3 / pm-status / pm agent) |
| `.setup/maintenance/` | 保守文書・回帰テスト(利用者には不要) |
| `staging/` | 統合移行中の原本の写し(Phase 5 で削除予定) |

## 保守

保守者(人 / AI)は、まず [.setup/maintenance/MAINTENANCE.md](.setup/maintenance/MAINTENANCE.md) を読む(原則・構成・検証・作業プラン)。検証は `pwsh .setup/maintenance/test-plugins.ps1` の ALL PASS が完了条件。
