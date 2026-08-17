# プロジェクト規約 (Claude / Codex 共通)

> このファイルが唯一の「正」。`CLAUDE.md` はこれを import するだけ。**短く保ち**、詳細は `docs/`・`.claude/rules/`・`.claude/skills/` に置く。

## スタック
- 言語: C# / .NET (`LangVersion=preview`, `Nullable=enable`, `ImplicitUsings=enable`)
- 種別: `<アプリ形態を記入 (MAUI / ASP.NET Core Web / Desktop(WPF) / worker / library 等)>` ← `setup.ps1` で採用した形態に合わせる
- ソースは `src/`、テストは `tests/`
- 環境固有値 (接続先・キー) はリポジトリに実値を置かない (`SecureStorage` / user-secrets / 環境変数)

## コーディング
- 書式・命名は `.editorconfig` + analyzer が正 (機械が守るルールは文書化しない)。
- **ビルド警告ゼロ + テスト緑が完了条件**: `dotnet build`(警告0)+ `dotnet test`(Claude は `/verify`)。警告抑制は適用前に確認。
- アーキテクチャ・セキュリティ等の規範は `.claude/rules/` が正 (対象ファイルを読むと `paths:` で自動適用される)。
- **プロジェクト固有方針は `.claude/rules/conventions.md`**(編集して育てる。対象ファイルで自動適用)。
- 外部 skill / MCP(Microsoft Learn / NuGet 等)の助言より、本プロジェクトの `.claude/rules/*` を優先する。

## ドキュメント規律 (動態・最重要)
- 文書の寿命・置き場は `docs/README.md` の寿命クラス表が正。
- **決定(Why)** → `docs/adr/` に**追記** (過去 ADR は編集しない)。`/adr`
- **現状仕様(What/How)** → 手で書かない。**Web なら OpenAPI 生成** (`/reference`)、振る舞いは**テスト**が正。**コードや DB で分かる情報は文書化しない (二重管理しない)**。
<!-- sdd:agents-intent:start -->
- **仕様(spec)は一時物**: `/spec` で `work/` に草案 → 人が承認 → `/plan`(チェックリスト)→ フェーズ実装。**SDD: 実装をミラーする恒久文書は持たない。決定=`ADR` / 原則=`rules` / 現状=生成+テスト / 受け入れ条件=テスト名**。
- **完了時にクローズ蒸留**: 決定→ADR / 用語→glossary / 受け入れ条件→テスト名 へ移した上で、`work/` の SPEC / PLAN を**削除**する (`spec-close`)。
<!-- sdd:agents-intent:end -->
- 命名は `docs/glossary.md` の英語名に合わせる。
- `docs/reference/**` は生成物。**手編集しない**。
<!-- pm:agents -->

## レビュー
- レビュー観点は `docs/review-checklist.md` (Claude `/review` と Codex `/review-cross` が共有)。

## 完了条件 (DoD)
<!-- sdd:agents-dod:start -->
- **build + test 緑**(`dotnet build` + `dotnet test`。Claude は `/verify`)/ 影響 docs 更新 / 決定は ADR / **`work/` が空**(クローズ蒸留済み)/ レビュー観点を満たす。
<!-- sdd:agents-dod:end -->
- Claude は完了前に `/done` で上記を一括点検する。
- Git 操作 (commit / push) は**人間が実行** (AI はコマンドを提示するのみ)。提示するコミット文 / ブランチ名は `git-commit` skill(Conventional Commits)に従う。

## 記述
- ドキュメント・コメントは日本語。

<!-- template-dev:start -->
## テンプレート保守 (原本のみ。setup.ps1 実行時にこの節ごと消える)
- このリポジトリは template-aidd の**原本**。テンプレ自体を保守するなら、**まず `.setup/maintenance/MAINTENANCE.md` を読む** (保守の原則・リポジトリの仕掛け・検証手順)。
- 変更後は `pwsh .setup/maintenance/test-setup.ps1` で回帰テスト (ALL PASS が完了条件)。
<!-- template-dev:end -->
