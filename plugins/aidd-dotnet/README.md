# aidd-dotnet — AIDD for .NET

**C# / .NET 標準のルール**プラグイン。ライブラリ中立のアーキ規範 rules と、コード品質の hooks・MCP を提供する。

| 提供物 | 内容 |
|---|---|
| アーキ規範 rule (20) | `dotnet-*` prefix: coding-principles / async / errors / logging / security / data / domain / http-client / testing / web / api / blazor / blazor-e2e / grpc / worker / cli / mvvm / desktop / wpf / maui。**init が `.claude/rules/` へ managed 展開し、対象ファイルを読むと `paths:` で自動適用** |
| init | `/aidd-dotnet:init` — dotnet rules の展開のみ。プラグイン更新後の再実行で上書き更新 |
| hooks | 編集後の dotnet format 検証・UTF-8/CRLF 正規化 (コード品質の逆フィードバック) |
| MCP | Microsoft Learn (docs grounding) + NuGet (パッケージ・脆弱性。.NET 10 SDK の `dnx` が必要) |

## 導入

```
/plugin marketplace add <この marketplace の Git URL>
/plugin install aidd-dotnet@aidd
```

- 私有リポジトリのため、git 認証 (SSH または `gh auth login`) を事前に済ませておく (`GITHUB_TOKEN` 環境変数からの自動認証はない)。
- 導入後に `/aidd-dotnet:init` で規範 rules をプロジェクトへ展開する (既存プロジェクトへの追加を想定。AGENTS.md / README / ビルド設定はアプリ側で用意)。

## 規範の序列

**プロジェクト rule (`.claude/rules/conventions.md`) > aidd-smart > aidd-dotnet > 外部 skill / MCP**。

本プラグインはライブラリ選定を断定しない (選定は ADR に残す)。Smart 系スタック標準 (推奨ライブラリの断定 + 詳細リファレンス) を使う場合は `aidd-smart` を、spec / plan / 実装の基本ワークフローは `aidd-flow` を併せて導入する。
