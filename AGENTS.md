# プロジェクト規約 (Claude / Codex 共通)

> このリポジトリは **Claude Code プラグイン 4 本(aidd-dotnet / aidd-smart / aidd-flow / aidd-pm)の開発リポジトリ**。`CLAUDE.md` はこれを import するだけ。

- 保守はまず `docs/maintenance.md` を読む (原則・構成・検証・残る検証)。
- ドキュメントは日本語。文体・構成の原則は maintenance.md に従う。
- 決定は `docs/decisions.md` へ**追記** (覆すときは新項 + 旧項に取り消し注記)、未決は `docs/backlog.md` へ。
- 規範の改稿先: 要約 = 各プラグインの `.claude/rules/` / 詳細 = aidd-smart の器 skill の `references/`。変更後は `pwsh ./test-plugins.ps1` の ALL PASS が完了条件。
- Git 操作 (commit / push) は**人間が実行** (AI はコマンドを提示するのみ。Conventional Commits)。
