# 保守ガイド(最初に読む)

> **aidd プラグイン(aidd-dotnet / aidd-smart / aidd-flow / aidd-pm)の保守者(人 / AI)向け**。利用者は配布物の README を見る。

**本質(一言)**: 「GitHub Spec Kit の SDD フローを .NET × Claude Code に特化し、plan / tasks を一時物にして、ADR + 生成現状仕様 + 機械強制でドリフト対策を厚くした開発基盤」を、私有 Claude Code プラグイン 4 本(ルール = dotnet / smart、ワークフロー = flow / pm)として配布する。

## 原則(これに反する変更をしない)

1. **二重管理しない**: 規範は 1 箇所の「正」+ 参照に一本化する(要約の正 = 各プラグインの `.claude/rules/`、詳細の正 = aidd-smart の器 skill の `references/`)。複製・個名列挙は腐る。許容する重複は「原則 → 具体の階層で情報が増えるもの」と「入口の要約」のみ。
2. **機械が守るものは文書化しない**: analyzer / hook / 回帰テストが強制するルールを文書に書かない。
3. **プラグインは常に全部を持ち、必要分を選択展開する**: 展開はプロジェクトの `.claude/rules/` のみ(managed・init が上書き更新)。骨格・説明文書は配布しない(references 化 + 必要時生成)。
4. **定型は書かない**: テンプレ側に実物があり以後変更が発生しない定型(起動配線等)は規範に書かない。基準 = AI がそのコードを新規に書く・変更する場面が開発中に存在するか。
5. **命名**: 規範 rule は `dotnet-*` / `smart-*` prefix。系名(web / mvvm)= 系の全般、技術名(api / blazor / wpf)= 技術固有。
6. **文体**: 日本語。ASCII 記号・括弧は半角(中黒 `・` は全角)、`§` 不使用、冗長・自明な括弧補足を書かない。
7. **保守情報はリポジトリ内で管理**: 決定・未決・検証はこの docs/ に置き Git で同期する。外部(メモ・memory)には正を置かない(ポインタのみ)。

## 構成

| 場所 | 内容 |
|---|---|
| `plugins/` | 配布物の実体 4 本。規範 = `<plugin>/.claude/rules/`、詳細 = aidd-smart の `skills/smart-*/references/` |
| `.claude-plugin/marketplace.json` | 私有 marketplace 定義(4 プラグイン・相対パス source) |
| `test-plugins.ps1` | 回帰テスト(構造・frontmatter・rules 形式・init 実動スモーク) |
| `docs/` | 保守文書(本ファイル・decisions・backlog) |
| `.claude/settings.json` | 本リポジトリでの作業用 permissions |

## 保守のフロー

1. 変更する。**決定を伴うなら [decisions.md](decisions.md) に追記**(覆すときは新項 + 旧項に取り消し注記)、未決は [backlog.md](backlog.md) へ。
2. **検証**: `pwsh ./test-plugins.ps1` — **ALL PASS が完了条件**。
3. 変更したプラグインの `plugin.json` の version をバンプする(初回導入後から。references 1 本でも)。
4. コミットは Conventional Commits。commit / push は人が実行(AI はコマンド提示。work-close / git-commit skill として依頼されたときは AI 実行可)。

## 残る検証(実運用・未実施)

ドッグフーディング(導入操作は人・検証は AI と協働):

- [ ] `/plugin marketplace add usausa/template-spec` → install が私有認証込みで通る
- [ ] 各 init の実動(`/aidd-dotnet:init` = rules 20 / `/aidd-flow:init` = aidd.md / `/aidd-smart:init` = rules 19。${CLAUDE_PLUGIN_ROOT} 解決)
- [ ] rules の実発火: 対象ファイル(*.cs / *.razor / *.xaml.cs 等)の編集で該当規範が自動適用される
- [ ] dotnet-* と smart-* の同時発火で矛盾なし・smart の断定が優先される
- [ ] hooks(format 検証 / CRLF 正規化 / DoD リマインド)がプラグイン経由で発火する
- [ ] MCP(microsoft-learn / nuget)が接続できる
- [ ] rule 末尾の誘導から references をモデルが必要時に読みに行く
- [ ] 実プロジェクトでの一巡(init → /spec → /plan → /impl → /done)

完了後の人の判断: doc-template-architecture の GitHub アーカイブ化 / リポジトリ改名の要否。
