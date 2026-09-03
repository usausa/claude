# プロジェクト規約 (Claude / Codex 共通)

> このファイルが唯一の「正」。`CLAUDE.md` はこれを import するだけ。**短く保ち**、詳細は `docs/`・`.claude/rules/`・`.claude/skills/` に置く。

## スタック
- 言語: C# / .NET (`LangVersion=preview`, `Nullable=enable`, `ImplicitUsings=enable`)
- 種別: `<アプリ形態を記入 (MAUI / ASP.NET Core Web / Desktop(WPF) / worker / library 等)>` ← 採用した形態に合わせて記入する
- ソースは `src/`、テストは `tests/`
- 環境固有値 (接続先・キー) はリポジトリに実値を置かない (`SecureStorage` / user-secrets / 環境変数)

## コーディング
- 書式・命名は `.editorconfig` + analyzer が正 (機械が守るルールは文書化しない)。
- **ビルド警告ゼロ + テスト緑が完了条件**: `dotnet build`(警告0)+ `dotnet test`(Claude は `/verify`)。警告抑制は適用前に確認。
- アーキテクチャ・セキュリティ等の規範は **aidd プラグインが `.claude/rules/` へ展開する managed rule** が正 (対象ファイルを読むと `paths:` で自動適用される。プラグイン更新後は init の再実行で上書き更新)。
- **プロジェクト固有方針は `.claude/rules/conventions.md`**(編集して育てる。対象ファイルで自動適用)。
- 規範の序列: **プロジェクト rule (`.claude/rules/*`) > aidd-smart > aidd-dotnet > 外部 skill / MCP** (Microsoft Learn / NuGet 等)。

## ドキュメント規律 (動態・最重要)
- 文書の寿命・置き場は `docs/README.md` の寿命クラス表が正。
- **決定(Why)** → `docs/adr/` に**追記**(手動が基本・タイミング任意。`/adr` はドラフト支援。過去 ADR は編集しない)。日々守る書き方の制約になるなら `.claude/rules/` へ (`rule-create`)。
- **現状仕様(What/How)** → 手で書かない。**Web なら OpenAPI 生成** (`/reference`)、振る舞いは**テスト**が正。**コードや DB で分かる情報は文書化しない (二重管理しない)**。
<!-- sdd:agents-intent:start -->
- **仕様(spec)は一時物**: `/spec` で作業フォルダ(`docs/work/`。解決規則は同 README)に草案 → 人が承認 → `/plan`(チェックリスト)→ フェーズ実装。**SDD: 実装をミラーする恒久文書は持たない。決定=`ADR` / 原則=`rules` / 現状=生成+テスト / 受け入れ条件=テスト名**。
- **完了時にクローズ (片付け)**: 蒸留漏れ(決定→ADR / 用語→glossary / 受け入れ条件→テスト名)を確認した上で、作業フォルダの SPEC / PLAN を**削除**し、最終プッシュ・ブランチ削除を提示する (`work-close`)。
<!-- sdd:agents-intent:end -->
- 命名は `docs/glossary.md` の英語名に合わせる。
- `docs/reference/**` は生成物。**手編集しない**。
<!-- pm:agents -->

## レビュー
- レビュー観点は `docs/review-checklist.md` (Claude `/review` と Codex `/review-cross` が共有)。

## 完了条件 (DoD)
<!-- sdd:agents-dod:start -->
- **build + test 緑**(`dotnet build` + `dotnet test`。Claude は `/verify`)/ 影響 docs 更新 / 決定は ADR / **自分の作業フォルダが片付いている**(`docs/work/` にクローズ済み = SPEC / PLAN 削除済み)/ レビュー観点を満たす。
<!-- sdd:agents-dod:end -->
- Claude は完了前に `/done` で上記を一括点検する。
- Git 操作 (commit / push) は**人間が実行** (AI はコマンドを提示するのみ)。提示するコミット文 / ブランチ名は `git-commit` skill(Conventional Commits)に従う。

## 記述
- ドキュメント・コメントは日本語。
