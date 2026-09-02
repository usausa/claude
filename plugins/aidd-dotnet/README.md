# aidd-dotnet — AIDD for .NET

C# / .NET の AI 駆動開発基盤プラグイン。**ライブラリ中立の規律 + SDD フロー + プロジェクト初期化**を提供する。

| 提供物 | 内容 |
|---|---|
| アーキ規範 skill (20) | coding-principles / async / errors / logging / security / data / domain / http-client / testing / web / api / blazor / blazor-e2e / grpc / worker / cli / mvvm / desktop / wpf / maui。**対象ファイルを読むと `paths:` で自動適用** |
| 開発フロー skill (18) | `/aidd-dotnet:spec` → `plan` → `impl` → `verify` → `review` → `done` のループ、`adr` / `reference` / `review-cross` / `pm-plan` / `pm-status`、work-init / work-close / adr-guide / rule-create / git-commit / csharp-layered-feature / sync-docs-from-code |
| init | `/aidd-dotnet:init [lite\|full\|full-pm]` — 骨格 (ビルド設定・docs・AGENTS) を展開し SDD レベルを確定 |
| agents (4) | spec / reviewer / doc-sync / pm |
| hooks | 編集後の dotnet format 検証・UTF-8/CRLF 正規化、応答終了時の DoD リマインド |
| MCP | Microsoft Learn (docs grounding) + NuGet (パッケージ・脆弱性。.NET 10 SDK の `dnx` が必要) |

## 導入

```
/plugin marketplace add <この marketplace の Git URL>
/plugin install aidd-dotnet@aidd
```

- 私有リポジトリのため、git 認証 (SSH または `gh auth login`) を事前に済ませておく (`GITHUB_TOKEN` 環境変数からの自動認証はない)。
- 新規プロジェクトでは続けて `/aidd-dotnet:init` を実行し、AGENTS.md の「スタック」節を記入する。以降の始め方・使い方は展開された README.md が入口。

## 規範の序列

**プロジェクト rule (`.claude/rules/*`) > aidd-smart > aidd-dotnet > 外部 skill / MCP**。

本プラグインはライブラリ選定を断定しない (選定は `/adr` に残す)。Smart 系スタック標準 (推奨ライブラリの断定 + 詳細リファレンス) を使う場合は `aidd-smart` を併せて導入する。
