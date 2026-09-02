# aidd — C# × Claude Code プラグイン(2 段スタック構成)

私有配布の Claude Code プラグイン marketplace。C# / .NET の AI 駆動開発を 2 段のプラグインで支援する。

| プラグイン | 内容 |
|---|---|
| `aidd-dotnet`(AIDD for .NET) | .NET 全般のライブラリ中立規律 + SDD フロー + プロジェクト初期化(init) |
| `aidd-smart`(AIDD Smart Architecture) | Smart 系スタック標準の断定 + 詳細リファレンス。`aidd-dotnet` に依存 |

序列: **プロジェクト rule > aidd-smart > aidd-dotnet > 外部 skill / MCP**。

## 状態(プラグイン化の移行中)

旧 setup.ps1 テンプレート方式は退役した。作業プランと進捗は [.setup/maintenance/plugin-plan.md](.setup/maintenance/plugin-plan.md)。

| 場所 | 内容 |
|---|---|
| `.claude/` | 第 1 段の素材(rules / skills / commands / agents / hooks。Phase 2 で `plugins/` へ変換) |
| `staging/architecture/` | 旧 template-architecture の写し(第 2 段の原本。docs 93 本 + TOPICS + 正典実物) |
| `staging/templates-neutral/` | 旧テンプレ骨格(init の素材。src / tests / docs / ルート定型一式) |
| `docs/` | 旧テンプレの配布 docs(Phase 2 で templates へ再編) |

利用者向けの導入手順(marketplace add → install → init)は Phase 2 以降に各プラグインの README で提供する。

## 保守

保守者(人 / AI)は、まず [.setup/maintenance/MAINTENANCE.md](.setup/maintenance/MAINTENANCE.md) を読む(原則・構成・検証・作業プラン)。
