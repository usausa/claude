# aidd-dotnet — AIDD for .NET

C# / .NET の AI 駆動開発基盤プラグイン。**ライブラリ中立の規律 + SDD フロー + プロジェクト初期化**を提供する。

| 提供物 | 内容 |
|---|---|
| アーキ規範 rule (20) | `dotnet-*` prefix: coding-principles / async / errors / logging / security / data / domain / http-client / testing / web / api / blazor / blazor-e2e / grpc / worker / cli / mvvm / desktop / wpf / maui。**init が `.claude/rules/` へ managed 展開し、対象ファイルを読むと `paths:` で自動適用** |
| 開発フロー skill (18) | `/aidd-dotnet:spec` → `plan` → `impl` → `verify` → `review` → `done` のループ、`adr` / `reference` / `trace` / `review-cross`、work-init / work-close / spec-close / adr-guide / rule-create / git-commit / csharp-layered-feature / sync-docs-from-code。SDD レベル (lite / full) は aidd.md の宣言で実行時分岐。プロジェクト管理は `aidd-pm` プラグイン |
| init | `/aidd-dotnet:init [lite\|full]` — `.claude/rules/` のみ展開 (規範 rules + プロジェクト宣言 aidd.md)。docs 骨格は各フロー skill が必要時に生成 |
| agents (3) | spec / reviewer / doc-sync |
| hooks | 編集後の dotnet format 検証・UTF-8/CRLF 正規化、応答終了時の DoD リマインド |
| MCP | Microsoft Learn (docs grounding) + NuGet (パッケージ・脆弱性。.NET 10 SDK の `dnx` が必要) |

## 導入

```
/plugin marketplace add <この marketplace の Git URL>
/plugin install aidd-dotnet@aidd
```

- 私有リポジトリのため、git 認証 (SSH または `gh auth login`) を事前に済ませておく (`GITHUB_TOKEN` 環境変数からの自動認証はない)。
- 導入後に `/aidd-dotnet:init` を実行する (既存プロジェクトへの追加を想定。AGENTS.md / README / ビルド設定はアプリ側で用意)。回し方 (人向け) は spec skill の references/workflow.md。

## 規範の序列

**プロジェクト rule (`.claude/rules/*`) > aidd-smart > aidd-dotnet > 外部 skill / MCP**。

本プラグインはライブラリ選定を断定しない (選定は `/adr` に残す)。Smart 系スタック標準 (推奨ライブラリの断定 + 詳細リファレンス) を使う場合は `aidd-smart` を併せて導入する。
