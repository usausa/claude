# プロジェクト規約 (Claude / Codex 共通)

> このリポジトリは **Claude Code プラグイン(aidd-dotnet / aidd-smart)の開発リポジトリ**。`CLAUDE.md` はこれを import するだけ。

- 保守はまず `.setup/maintenance/MAINTENANCE.md` を読む (原則・構成・検証・作業プラン)。作業プランの正は `.setup/maintenance/plugin-plan.md`。
- ドキュメントは日本語。文体・構成の原則は MAINTENANCE.md に従う。
- 決定は `.setup/maintenance/decisions.md` へ**追記** (覆すときは新項 + 旧項に取り消し注記)、未決は `backlog.md` へ。
- 規範の改稿先: 要約 = プラグイン内 `.claude/rules/` / 詳細 = 器 skill の `references/` (旧 template-architecture リポジトリは凍結・staging/architecture は削除済み)。`staging/templates-neutral` は旧テンプレ骨格の退避 (templates 縮小で整理予定)。
- Git 操作 (commit / push) は**人間が実行** (AI はコマンドを提示するのみ。Conventional Commits)。
