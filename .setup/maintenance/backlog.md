# 検討事項(未決 TODO)

> 設計上まだ確定していない・今後見直す論点。**確定したら本体へ反映して [decisions.md](decisions.md) に記録を移し、ここから消す**。
> 注: プラグイン化(2 段スタック構成)以前に書かれた項は旧 setup.ps1 方式の語彙を含む。読み替え(rules → paths 付き skill / setup の採用リスト → プラグインのカタログ)は [plugin-plan.md](plugin-plan.md) を参照。

## 🚧 一覧

- **SPEC(機能単位)に何を残すか** — 「非復元の意図だけ残す」基準は確定済み。恒久的に持たせる中身の線引きは実運用で確定する(full の distill-in-place 対象)
- **SDD lite の実運用検証** — lite(仕様の一時化)は実装済み・未検証。クローズ蒸留の精度と既定(full)の妥当性を実運用で確認
- **lite の ceremony の厚み** — Spec Kit の `/clarify` / `/analyze` / 独立 `/tasks` 相当を lite は「未決事項 + 人レビュー」に畳んでいる。複雑機能で前捌きが薄くないか
- **`/done` クローズ蒸留の安全網** — 「テスト/ADR/glossary のどれにも載らず消える意図はないか」の確認を close に足すか(蒸留の情報損失リスク対策)
- **担保のハード強制** — `/done` ゲートを Husky.Net pre-commit / CI へ移設するか(slopwatch も部品候補)
- **非 Windows 対応** — `.claude/hooks/*.ps1`(source-normalize / dotnet-verify / done-check)は PowerShell 前提。macOS/Linux で使うなら代替が要る
- **ドキュメントの分離(AI / 人 / アセット)** — 人専用文書・画像が増えた場合の分離方針
- **Blazor E2E の残項目** — `/verify` での E2E 実行方針 / MAUI・Desktop 対称の UI テスト rule / review-checklist 観点(任意)
- **winui.md の執筆** — setup の採用リストに登録済み。ファイル追加のみで対応可
- **二重管理刈り込みの残項目** — doc-sync agent の役割整理 / README の `CLAUDE_CODE_USE_POWERSHELL_TOOL` 検証
- **Aaronontheweb/dotnet-skills の扱い** — 次に蒸留する skill の選定と時期(slopwatch / Aspire 系 / EF Core 系 ほか)
- **template-drafts 取り込みの実運用検証** — 取り込み自体は完了(2026-08-18。decisions.md 参照)。残りは実運用での検証: rules の paths が実プロジェクト構成で発火するか / setup.ps1 の実行結果 / docs/work フローの一巡(残作業はローカルメモで管理)
- **PreToolUse フック (作業フォルダの誤書き込み拒否)** — 現ブランチ以外の `docs/work/<slug>/` への書き込みを拒否する機械強制 (DrivenPlatform 申し送りの論点。`docs/work/` 直下は許容して両方式と両立する設計まで確定済み)。実装は見送り中 — hooks の非 Windows 対応と合わせて検討
- **generator 規約の執筆** — Source Generator の実装様式は骨子のみ確定済み (取り込みは見送り): IIncrementalGenerator 一択 / `ForAttributeWithMetadataName` で抽出 / パイプラインは equatable な record に正規化 (ISymbol を持ち回らない) / 検証エラーは throw せず Result 型でパイプラインに乗せ出力段冒頭で ReportDiagnostic / 診断は静的 DiagnosticDescriptor 集約 + ID 体系 / 生成名は `名前空間_クラス名.g.cs` / MSBuild プロパティは AnalyzerConfigOptionsProvider + CompilerVisibleProperty を対で配線 / 検証は EmitCompilerGeneratedFiles ハーネス + analyzer 適用テスト。採用プロジェクトが現れたら rule-create で `.setup/rules/` カタログに起こす
- **aws-lambda 規約の執筆** — 未執筆 (規範のない枠 doc は置かない)。扱う予定: ハンドラの属性 + Source Generator 宣言 / 環境変数設定・プラットフォームロガー + LoggerMessage 共通様式 / ウォームアップ ping 早期リターン・コールドスタート対策 (R2R + arm64) / SAM デプロイ。書けた時にオプション rule として新設
- **プラグイン化(2 段スタック構成)** — 実行中。私有配布の 2 プラグイン(aidd-dotnet + aidd-smart)モノレポへ転換し template-architecture を統合する。作業プランは [plugin-plan.md](plugin-plan.md) が正
- **検討事項の運用の Issues 化** — 複数人・複数 AI 体制になったら、この backlog の起票・クローズを GitHub Issues に移す選択肢
- **その他** — CPM(`Directory.Packages.props`)採用可否 / 旧参考資料の削除可否 / 汎用プロンプト集 / nested AGENTS.md / org での AGENTS.md 必須化

## 未決: SPEC(機能単位)に何を残すか

- **論点**: 「残す価値のあるものは `ADR` / `architecture` / コード + テストへ寄せる」方針は固まったが、**機能単位(SPEC)に恒久的に何を持たせるべきかが未確定**(full の distill-in-place の線引き)。
- 候補: 要求・受け入れ条件・スコープ・非機能要件・前提 / 制約 のうち、**コードから復元できないものだけを最小限**。
- 当面: SPEC テンプレは最小のまま運用し、実運用で「後から効いた情報 / 腐った情報」を観察して確定する。

## 検討: SDD lite の実運用検証

- **経緯**: 旧「Agile + ADR への更なる簡素化」案は **`setup.ps1 -Sdd lite` として実装済み**(2026-07。[decisions.md](decisions.md) 参照)。
- **未: 実運用検証**: lite を実プロジェクトで回し、(1) クローズ蒸留で意図が十分残るか(ADR の「背景」で足りるか)、(2) テスト名 = 受け入れ条件の規律が維持できるか、(3) full に戻したくなるケースは何か、を観察。結果次第で既定(full)を見直す。
- **未: lite での PM 代替**: PM は full 前提の加算層(`-Sdd full-pm`)で、lite には無い。必要になったら SPEC 名 / ブランチ単位の軽量な進捗管理を検討。

## 検討: lite の ceremony の厚み

- **論点**: lite フローは Spec Kit の `/clarify`(曖昧さ解消)・`/analyze`(成果物間の整合検査)・独立した `/tasks` を持たず、「SPEC の未決事項 + 人レビュー + AI 反復」に畳んでいる。速度と引き換えに、複雑機能では前捌き(実装前のリスク潰し)が薄い可能性。
- **当面**: 現状の「未決事項 + 承認」で足りるかを実運用で観察。曖昧さの多い機能向けに `/spec` 内で往復を 1 段強める案は保留。
- 関連: [refactor-lite-base.md](refactor-lite-base.md)(lite 基層化リファクタ)のスコープ外検討事項。

## 検討: /done クローズ蒸留の安全網

- **論点**: lite は完了時に SPEC を蒸留して削除する。蒸留の判断を誤ると、テスト/ADR/glossary に捕捉されない意図が恒久的に失われる(full の「蒸留して残す」より損失に弱い)。
- **案**: `/done`(または `spec-close`)に「今回、テスト/ADR/glossary のどれにも載らず消える意図はないか?」の明示チェックを 1 行足し、損失リスクを下げる。
- **トレードオフ**: 安全網 ↑ vs close 手順の重さ ↑。full を使えば損失リスクは回避できる(逃げ道は既にある)。
- 関連: [refactor-lite-base.md](refactor-lite-base.md) のスコープ外検討事項。

## 検討: 担保をハード強制に(Husky.Net / CI)

- **論点**: build+test 緑・蒸留・退役漏れ0 の担保は現状 `/done` ゲート依存(人 / AI が起動)。**`/done` を飛ばして commit すれば発火しない = バイパス可能**。
- **案**: 同じチェックを **Husky.Net の `pre-commit` / `commit-msg`(または Jenkins CI)** へ移設し、バイパス不能にする。`slopwatch`(LLM 報酬ハッキング検出 CLI)も部品候補。
- **トレードオフ**: 強制の確実性 ↑ vs pre-commit の重さ・人の最終判断の余地 ↓。現実解の候補: pre-commit は軽く(build のみ)+ CI で test / 蒸留 / 退役の二段。

## 検討: ドキュメントの分離(AI / 人 / アセット)

- **現状は妥当**(agents.md 標準と整合の「共存・二重消費」型): AI 指示は `.claude/` + root `AGENTS.md` / `CLAUDE.md`、エンジニアリング文書は `docs/`(人 + AI 共用)。
- **将来分離を検討**(人専用文書・重いアセットが増えた場合): 画像・図 → `docs/assets/`、人専用文書 → `docs/manual/` 等に分離 or `settings.json` の deny で AI に読ませない。ADR / glossary / reference は `docs/` のまま。
- 参照: agents.md 標準、GitHub「how to write a great agents.md」(stale な docs は context を毒する)。

## 検討: Blazor E2E(blazor-playwright skill)の残項目

`blazor-e2e` rule(旧 blazor-playwright skill)は rules カタログに同梱済み。setup.ps1 の form gate(web のみコピー)は実装済み。残項目:

- **未: /verify での E2E 実行方針**: 既定は全テスト実行(テスト=正、DoD=test 緑)。ブラウザ未導入環境や実行時間が問題化したら `[Trait("Category", "E2E")]` で分離(既定除外 + 明示実行)を検討。
- **未: MAUI・Desktop 対称**: maui 形態向け(`maui-appium` 等)/ desktop 形態向け(`wpf-uitest`=FlaUI 等)の UI テスト rule を同じイディオム(カタログ同梱 + 採用形態のみコピー)で用意するか。
- **未: winui.md の執筆**: desktop 系の採用リスト(setup.ps1 の `$formRules.desktop`)には登録済み。WinUI 対応時に `.setup/rules/winui.md` を追加するだけでよい。
- **任意: review-checklist**: UI 変更時の観点(data-testid の破壊、クリティカルパスの E2E 要否)を足すか。

## 検討: 二重管理の刈り込みの残項目

- **未: doc-sync agent の役割整理**: /reference command が手順を直接持ち、doc-sync agent はどこからも呼ばれていない。command から agent へ委譲に一本化するか、agent を廃止するか。
- **未: README のセットアップ記述の検証**: 「PowerShell フックに `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`」(README 始め方 6) — hooks は powershell.exe を直接起動するため不要の可能性。実機で要否を確認し修正 or 削除。

## 実行中: プラグイン化(2 段スタック構成)

- **方針決定済み(2026-09-02)・作業プランは [plugin-plan.md](plugin-plan.md) が正**(フェーズ・チェックリスト)。骨子: 私有配布 / 本リポジトリを 2 プラグイン(dotnet 全般 + Smart アーキテクチャ)のモノレポへ転換し template-architecture の内容も統合 / rules は `paths:` 付き skill へ変換 / スキャフォールドは init skill + templates。
- 実運用検証はプラン Phase 4 のドッグフーディングとして実施する。

## 検討: Aaronontheweb/dotnet-skills の扱い

- **現状**: 個別評価(33 skill + 5 agent。2026-07 調査)は実施済みで、結論は本項に集約している。`playwright-blazor` は `blazor-e2e` rule として蒸留採用済み。導入方針(plugin 一括導入はせず cherry-pick + 日本語蒸留)は確定。
- **未決: 次に蒸留する skill の選定と時期**: `slopwatch`(ハード強制と連動・hook / CI 部品として評価)/ `aspire-service-defaults`・`aspire-integration-testing`(Aspire 実装開始時)/ `efcore-patterns` + `database-performance`(EF Core 採用時)/ `dotnet-devcert-trust` / `package-management`(CPM 検討の先行資料)。
- **導入しないと確定**: `project-structure`(テンプレが構造の正)・`docfx-specialist` agent(リファレンスサイトを作らない方針と衝突)。`csharp-coding-standards` は差分を conventions へ蒸留する形のみ。

## その他の保留事項

- DotNet 命名の CPM(`Directory.Packages.props`)/ `global.json` 採用可否(現状: ドキュメントのみ反映、ファイルは未追加)。
- 旧参考資料(`AI駆動開発ガイド.md` / `ディレクトリ構成案(旧).md` / `テンプレート案(旧).md` / `DotNetプロジェクト名.md`)の取り込み後の削除可否。
- 汎用プロンプト集(bug-fix / test-gen 等)の扱い(現状: レビュー出力の拡充のみ想定)。
- **nested `AGENTS.md`**(agents.md 標準機能)= マルチプロジェクト構成なら有用だが単一アプリには過剰、で保留。
- **org での AGENTS.md 必須化**: `mackowski/10xGitHubPolicies` の `has_agents_md` は「担保のハード強制」の組織レベル版。導入するなら org 側。
- **aidd.md(常時適用のプロジェクト宣言)の撤廃検討**: 現在は SDD レベル + 序列の 2 行の極小 rule。常時適用 rule は最小限に保つ方針のため、SDD レベルの持ち方(フロー skill が都度読む設定ファイル化等)を再確認して撤廃できるか判断する(2026-09 templates 全廃時の仮置き)。
