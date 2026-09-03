# C# × Claude Code AI駆動開発テンプレート(.NET 汎用)

**この README だけで、始め方・使い方・ドキュメント群の意図がわかる**ようにしてある。
> 注: この README は**テンプレ使用者向けの入口**で、Claude に自動ロードされない。**導入後は自プロジェクトの README に置き換え/削除してよい** — フレームワークの正は `AGENTS.md`(規律)・`docs/README.md`(寿命・永続化の契約)・`docs/guides/workflow.md`(手順)にあり、この README には依存しない。

## 🎯 3原則
- **レーンを固定**: C# + Claude 前提。標準は具体的で深い。
- **不変と可変を分離**: engine(`.claude` / `docs`)/ 生成物(`docs/reference`)/ 環境固有値 を分ける。
- **ドキュメントを腐らせない**: Why=ADR、What/How=生成・テスト、書式=analyzer、更新は hooks / `/done` で変更に埋め込む。

## 🚀 始め方(セットアップ)
1. aidd プラグインを導入する: `/plugin marketplace add <marketplace の URL>` → `/plugin install aidd-dotnet@aidd`(Smart スタック標準を使うなら `aidd-smart` も)。
2. **初期化**: 空のリポジトリで `/aidd-dotnet:init [lite|full|full-pm]`(SDD レベル。既定 `full`。**lite ⊂ full ⊂ full-pm の加算**)。`lite`=SPEC は `docs/work/` の一時物(完了時にクローズ蒸留して削除)/ `full`=SPEC を恒久化し蒸留(+`/trace`)/ `full-pm`=full + PM(feature 単位の計画・進捗)。アーキ規範はプラグインの skill が対象ファイルで自動適用されるため、規範ファイルの配置は不要。
3. `AGENTS.md` の「スタック」節を採用形態に記入。
4. LINT / ビルド設定(`.editorconfig` / `Directory.Build.props` / `Analyzers.ruleset` / `Settings.XamlStyler`[XAML 系])は**全形態の superset**。実プロジェクトのテンプレで置換してよい。
5. ソースを配置(詳細 `src/README.md` / `tests/README.md`):
   - **Web**: `src/<App>/`(Blazor / minimal API)+ Aspire(`AppHost`)。テスト `UnitTests` / `IntegrationTests`。OpenAPI 有効化。
   - **MAUI**: `src/<App>/`(MVVM)。テスト `UnitTests`(+ 任意 `UITests`)。
   - **Desktop**: `src/<App>/`(WPF、MVVM)。テスト `UnitTests`(+ 任意 `UITests`)。
   - **Worker**: `src/<App>/`(Worker Service、常駐)。テスト `UnitTests`(+ 任意 `IntegrationTests`)。
6. Claude Code 設定(`.claude/settings.json` = 権限のみ。フックと MCP = Microsoft Learn + NuGet はプラグインが提供)を確認。MCP は初回承認、NuGet は .NET 10 SDK の `dnx` が必要。
<!-- sdd:readme-start:start -->
7. 最初の仕様を `/spec <アイディアの箇条書き>` で作る。
<!-- sdd:readme-start:end -->

## 🔄 使い方(開発ループ)
<!-- sdd:readme-loop:start -->
```
/spec(箇条書き→仕様草案)→ 人がレビュー & 修正指示 → 承認
  → /plan(チェックリスト。大きければフェーズ分割)→ 承認
  → /impl(フェーズ実装 + チェック更新 + フェーズ末 /verify)
  → PostToolUse フックで dotnet format 検証(逆フィードバック)
  → /reference(Web=OpenAPI 再生成)→ /review + /review-cross(Codex)
  → /done(DoD + クローズ → docs/work/ の SPEC / PLAN を削除)→ 人間が git commit
```
- 仕様とプランは **`docs/work/` の一時物**(git 管理・完了時に削除)。恒久に残るのは 決定=ADR / 用語=glossary / 受け入れ条件=テスト名。
<!-- sdd:readme-loop:end -->
- **各段の具体プロンプト(コピペ可)とコマンド早見表**は `docs/guides/workflow.md`(正はそちら)。

## 📁 ファイルの役割(`.claude` = 動かす仕組み)
| ファイル | 主体 | 役割 |
|---|---|---|
| `settings.json` | 自動 | 権限。`reference/**` の手編集を deny |
| `rules/conventions.md` | 自動適用 | プロジェクト固有方針(編集して育てる) |
| (プラグイン提供) | 自動 | フック(format 検証・CRLF 正規化・DoD リマインド)/ アーキ規範 rule(init が `.claude/rules/` へ展開・`paths:` 自動適用)/ 開発ループの各段(`/aidd-dotnet:spec` 等)/ サブエージェント |
<!-- pm:guide-claude -->

## 🗂️ 寿命・永続化(何を編集し・生成し・残すか)
- **正の一覧(寿命クラス表)と退役・ID のルールは `docs/README.md`、AI 常時ルールは `AGENTS.md`**。

## 🧭 このドキュメント群の意図
- **SDD(Spec Kit 風)**: 仕様(spec)を中心に AI が実装。**実装を 1:1 でミラーする恒久設計書は持たない**。意図=spec / 決定=ADR / 原則=rules / 現状=生成+テスト。
- **腐らせない**: コード/DB で分かる情報は文書化しない(二重管理しない)。現状仕様は生成、意図は蒸留、一時物は破棄、不要は退役。
- **担保**: `/verify` → `/review` → `/done` の機械チェック連鎖(ゲート)。バイパス不能にするなら同じ検査を Husky.Net / CI へ寄せる(任意)。
- **コンテキスト**: 常時ロード(固定費)は `CLAUDE.md`(+ `AGENTS.md`)/ 各 skill の description / MCP ツール定義のみ。この README・`docs/**`・commands/skills 本文は**オンデマンド**。

## 🧩 MCP と skill(拡張)
- **MCP(プラグイン提供)**: aidd-dotnet が Microsoft Learn(docs grounding)+ NuGet(パッケージ・脆弱性)を提供。ツール定義は固定費なので **Learn / NuGet に絞る**(可視ツール ~50 上限)。
- **MCP の追加**: `.mcp.json` にサーバー定義を追記する(`claude mcp add <name> --scope project ...` でも可)。リモートは `{ "type": "http", "url": "..." }`、ローカル実行は `{ "type": "stdio", "command": "...", "args": [...] }`。追加後はセッション再起動と初回承認が必要。ツール定義は固定費のため、常用するものだけ残し使わなくなったら削除する。
- **skill**: 開発フロー・アーキ規範の skill は aidd プラグインが提供する(個名は列挙しない=腐らせない)。追加は MAUI=`davidortinau/maui-skills`、Web=公式 `dotnet/skills` 等を**選別**(plugin か vendor-copy)。**`conventions.md` が常に優先**。description は固定費なので入れすぎない。

## 🔗 リンク
- 各段の具体プロンプト: `docs/guides/workflow.md`
- アーキ規範: aidd プラグインの skill(対象ファイルを読むと自動適用)+ プロジェクト固有は `.claude/rules/conventions.md`
- PM(`/aidd-dotnet:init full-pm` で有効化)を使うと `/aidd-dotnet:pm-plan`・`/aidd-dotnet:pm-status` で feature の計画・進捗
