# プラグイン化 2 段スタック構成 — 作業プラン(フェーズ・チェックリスト)

> 方針は決定済み(2026-09-02)、名称ほか一部未決。本書が実行プランの正。フェーズ完了ごとにチェックを付け、全完了後に decisions.md へ経緯を移して本書は経緯記録に降格する。
> 機構の前提調査(プラグインで配布できるもの・rules 非対応と `paths:` skill での代替・スキャフォールドはスクリプト方式・私有 marketplace)は 2026-09 に実施済み。

## 決定済み方針

- **私有配布**(private GitHub + `/plugin marketplace add`。public には出さない)
- **本リポジトリを 2 プラグインのモノレポへ転換**し、template-architecture の内容(docs 93 本・TOPICS.md・正典実物)も**本リポジトリへ統合**する(従来の「統合しない・上流維持」決定は置換する)
- **2 段構成**: 第 1 段 = dotnet 全般(ライブラリ中立)/ 第 2 段 = Smart アーキテクチャ(スタック標準の断定 + 詳細リファレンス)。序列 =「プロジェクト rule > 第 2 段 > 第 1 段 > 外部 skill / MCP」
- ルート直置きのプロジェクト骨格(src / tests / App.slnx / Analyzers.ruleset / App.sln.DotSettings / Directory.Build.* / Settings.XamlStyler)は**廃止**し、雛形は各プラグインの `templates/` へ移す
- 進め方: architecture の内容を **staging ディレクトリへコピーし、以降の改稿は本リポジトリ側で行う**(元リポジトリは凍結)

## 名称(確定 2026-09-02)

| 対象 | 名称 |
|---|---|
| 第 1 段プラグイン | `aidd-dotnet`(displayName: AIDD for .NET) |
| 第 2 段プラグイン | `aidd-smart`(displayName: AIDD Smart Architecture) |
| marketplace | `aidd` |
| リポジトリ | `template-spec` のまま(改名は保留) |

## 参考リポジトリ(2026-09 実在確認済み)

| リポジトリ | 何の手本か |
|---|---|
| anthropics/claude-plugins-official | 公式 marketplace。marketplace.json / plugin.json スキーマと version 管理の正典 |
| jmanhype/claude-code-plugin-marketplace | **モノレポの最有力参考**(19 プラグイン・`source: "./plugins/<name>"` の相対パス・共有コードの置き方) |
| dotnet/skills | **本構成と同型**: `.claude-plugin/` + `plugins/` 配下に 15+ サブプラグイン(公式 .NET) |
| davidortinau/maui-skills | 1 プラグイン + 41 skills の集約(第 2 段の「分類 skill 束ね」の手本) |
| Aaronontheweb/dotnet-skills | flat skills 30 + agents 5(カテゴリ接頭辞での整理) |
| cooco119/claude-plugin-private-marketplace-helper | private marketplace の認証まわりのヘルパー実例 |

- 私有配布の認証: SSH(`git@github.com:...`)または `gh auth login` による git credentials が前提。**`GITHUB_TOKEN` 環境変数からの自動認証は無い**(CI では `gh auth setup-git`)。

## 注意点(方針レビューで確認済み)

1. **決定の置換**: 旧決定「template-architecture とは統合しない」はコミット済みで履歴に入っていたため、decisions.md は運用ルールどおり**旧項に取り消し注記 + 新項追記**の形で再編した(Phase 0 で対応済み)。MAINTENANCE.md 原則 6・architecture 側 README の役割行(凍結の明記)も整合済み
2. **テンプレ機能の空白期間**: 骨格削除で setup.ps1 / test-setup.ps1 は成立しなくなる。**削除前に templates/ 素材として退避**し(原本消失を防ぐ)、setup.ps1 方式は Phase 1 で退役と割り切る(以後の新規プロジェクトは init skill が動く Phase 2 完了まで既存 clone を使う)
3. **テンプレ群 21 リポジトリの正典参照先**: Analyzers.ruleset / .editorconfig の正典実物は第 2 段の `templates/` が新しい置き場になる(architecture 直下参照からの付け替え)
4. **骨格の 2 系統**: 第 1 段 templates = 中立 safety 版(現 spec 同梱の ruleset = 正典 +3 ルール)、第 2 段 templates = 正典版。進行中の .editorconfig / DotSettings 調整(人の仕掛かり)を**どちらの版に載せるか**は取り込み時に判断
5. **commands → skills 移行で起動方法が変わる**(`/spec` 等の使用感)。Phase 2 の検証項目に含める

## Phase 0: 準備・整地

- [x] 名称の確定(2026-09-02: aidd-dotnet / aidd-smart / marketplace `aidd`)
- [x] decisions.md の「template-architecture とは統合しない」を新決定(私有 2 プラグインのモノレポへ統合・2 段構成・序列)に書き換え。MAINTENANCE.md 原則 6 と architecture README の役割行も整合(いずれも未コミットのまま修正)
- [x] template-architecture リポジトリを凍結(以後の改稿は本リポジトリの staging 側で行う。README に凍結を明記)
- [x] `staging/architecture/` へコピー: docs/** / README.md(索引)/ TOPICS.md / Analyzers.ruleset / .editorconfig / Directory.Build.props / Directory.Build.targets(architecture 側の未コミット変更 = 逆輸入 4 件を含む状態で)
- [ ] 保留中のコミット(spec / architecture / テンプレ群 15 件)の扱いを確定し実行(人)

## Phase 1: リポジトリ転換(テンプレ方式の退役)— 完了 2026-09-02

- [x] ルート骨格を `staging/templates-neutral/` へ退避(src / tests / docs / App.slnx / Analyzers.ruleset / App.sln.DotSettings / Directory.Build.* / Settings.XamlStyler / .mcp.json / .editorconfig / .gitattributes / .gitignore / .markdownlint.jsonc / AGENTS.md / CLAUDE.md)
- [x] 退避後、ルートから骨格を削除(人の指定 8 項目。docs / .mcp.json / dotfiles はリポジトリ用としてルートにも残置)
- [x] setup.ps1 / .setup/sdd / test-setup.ps1 を退役(削除。復元は git 履歴から可能)
- [x] README / AGENTS.md を「プラグイン開発リポジトリ」として書き換え
- [x] .setup/maintenance/ の洗い出し: MAINTENANCE.md を新構成へ全面更新(原則 3 = プラグイン加算方式・構成表・暫定検証)。decisions / design / refactor-lite-base / restructure-context / drivenplatform-handover は歴史記録として不変更、backlog は冒頭に読み替え注記を追加
- [x] 検証方式の再定義: 移行中の暫定 = リンク・参照の整合確認。機械検証は Phase 2 で `test-plugins.ps1`(plugin.json / marketplace.json の妥当性・skill frontmatter 検査)として整備(MAINTENANCE.md フローに記載)

## Phase 2: 第 1 段プラグイン(dotnet 全般)

- [x] `plugins/aidd-dotnet/.claude-plugin/plugin.json` 骨格(name / version 0.1.0 / description / mcpServers)
- [x] rules → `paths:` frontmatter 付き skill へ変換(20 本。conventions はプロジェクト側ファイルのため templates 行き)。frontmatter に name / description を付与、skill 間参照は `xxx` skill 表記へ変換。**中立化 = mvvm(Smart.Mvvm / Smart.Navigation / Modules 断定 → 基盤選定は `/adr`)/ wpf(WindowManager 方式 → マネージャ抽象へ一般化)/ web・worker(Serilog 断定 → ロガー選定は `/adr`)** — 外した断定は第 2 段が上書き提供する(Phase 3 で確認)
- [x] commands 11 本 → skills へ移行(description 移植・argument-hint は本文冒頭の「引数:」行へ・`$ARGUMENTS` 維持)。既存 skills 7 本(adr-guide の references 込み)も移設し、`.claude/rules/` 参照は二義に応じて字句修正(自動適用の規範 → 「アーキ規範 skill」/ conventions・rule-create の出力先 → プロジェクトの `.claude/rules/` のまま)
- [x] agents 4 本 / hooks の移設(hooks.json 化、ps1 は `${CLAUDE_PLUGIN_ROOT}/hooks/` 参照へ)。settings.json の permissions / deny はプラグインで配布できないため init の templates で配る(残バッチ)
- [x] MCP: Learn / NuGet を `mcp-servers.json` として同梱(ルートの .mcp.json はリポジトリ自身の作業用に残置、退役は Phase 2 完了時に判断)
- [ ] init skill + `templates/`(staging/templates-neutral から再構成。form / SDD の確定ロジック = 旧マーカー解決をスクリプトへ移植)
- [ ] 検証: paths 発火が rules と同等か / ロード量(description 固定費)/ `/名前:skill` の使用感
- [ ] プラグイン README(導入手順: marketplace add → install → init)

## Phase 3: 第 2 段プラグイン(Smart アーキテクチャ)

- [ ] `plugins/<第2段>/` 骨格 + `dependencies: [<第1段>]`
- [ ] staging/architecture の docs を**分類単位の skill(約 20 個)**へ再編: 本文 = スタック規範の要約(第 1 段の同名 skill の具体版・薄く保つ)、`references/` = docs 本体(オンデマンド参照)
- [ ] 正典実物(Analyzers.ruleset / .editorconfig / Directory.Build.props)を第 2 段 `templates/` へ(テンプレ群の新正典)
- [ ] TOPICS.md を保守文書として移設(.setup/maintenance/ 配下)
- [ ] 第 1 段の中立化で外した断定(Smart.Mvvm / Smart.Navigation / Modules / WindowManager / Serilog 構成)を第 2 段の対応 skill が上書き提供していることを確認
- [ ] 序列検証: 第 1・2 段の同時発火で干渉なし / conventions 優先が保たれる
- [ ] スタック固有 MCP の要否判断(必要になったときに追加でよい)

## Phase 4: marketplace・配布・検証

- [ ] `.claude-plugin/marketplace.json`(2 プラグイン・相対パス source)
- [ ] 私有配布の導入手順を文書化(private repo + marketplace add。認証は SSH or `gh auth login` — `GITHUB_TOKEN` 直接は非対応)
- [ ] バージョン運用の決定(更新毎バンプ。stack は docs 改稿とリリース粒度の関係を決める)
- [ ] ドッグフーディング: テンプレ群 21 リポジトリへ導入し実発火を検証(旧「実運用検証」をこの形で実施)
- [ ] 実プロジェクトでの一巡(init → /spec 相当 → 実装 → done のフロー確認)

## Phase 5: 片付け

- [ ] staging/ の削除(全内容が第 2 段へ再編済みであることを確認してから)
- [ ] template-architecture リポジトリのアーカイブ化(README に移設先を明記)— 人の判断
- [ ] decisions.md へ完了の経緯を記録し、本書を経緯記録へ降格
- [ ] ローカルメモ・memory の更新(資産地図の正典参照先ほか)

## 未決

- リポジトリ改名の要否(GitHub: usausa/template-spec のまま使うか)
- docs 配布物(adr 雛形 / glossary / guides / work README)を第 1 段 templates にどこまで含めるか(Phase 1 の退避時に棚卸し)
- 検証方式(Phase 1 で枠決め): プラグインのスモークテストをスクリプト化するか、ドッグフーディングで代替するか
