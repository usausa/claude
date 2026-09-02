# プロジェクト規約 (Claude / Codex 共通)

> このリポジトリは **Claude Code プラグイン(aidd-dotnet / aidd-smart)の開発リポジトリ**。`CLAUDE.md` はこれを import するだけ。

- 保守はまず `.setup/maintenance/MAINTENANCE.md` を読む (原則・構成・検証・作業プラン)。作業プランの正は `.setup/maintenance/plugin-plan.md`。
- ドキュメントは日本語。文体・構成の原則は MAINTENANCE.md に従う。
- 決定は `.setup/maintenance/decisions.md` へ**追記** (覆すときは新項 + 旧項に取り消し注記)、未決は `backlog.md` へ。
- `staging/` は移行中の原本の写し (architecture = 第 2 段の原本 / templates-neutral = init の素材)。第 2 段に関わる規範の改稿は staging 側で行う (旧 template-architecture リポジトリは凍結)。
- Git 操作 (commit / push) は**人間が実行** (AI はコマンドを提示するのみ。Conventional Commits)。
