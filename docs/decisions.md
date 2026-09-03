# 確定した設計方針(開発の決定記録)

> **追記式**(覆すときは新しい項で上書きし、旧項に取り消し注記)。未決は [backlog.md](backlog.md)。
> 2026-09-03 に整理: プラグイン化で失効した旧機構(setup.ps1 / SDD マーカー / -Form / paths 付き skill 化 等)の決定は削除した(経緯は git 履歴)。

## 構成・配布の決定

- **4 プラグイン構成(2026-09)**: ルール系 = `aidd-dotnet`(C#/.NET 標準・ライブラリ中立)/ `aidd-smart`(Smart スタック標準の断定 + 詳細リファレンス。dotnet に依存)、ワークフロー系 = `aidd-flow`(spec / plan / 実装の基本フロー。独立)/ `aidd-pm`(PM アドオン。flow に依存・SDD full 前提)。規範の序列は「プロジェクト rule(conventions.md)> smart-* > dotnet-* > 外部」。旧 full-pm レベルは廃止し、PM の有効化はプラグイン導入で表現(レベルとアドオンの直交化)。hooks の分割基準 = コード品質(dotnet 側)/ フロー補助(flow 側)。
- **規範の配布は rules 展開(2026-09)**: skill の `paths:` は rules と同等の強制注入をしないことをカナリア実験で実証(`.claude/rules/` はパスマッチで本文注入・発火、paths 付き skill は description 常駐のみで注入ゼロ)。規範は**プラグイン内の `.claude/rules/` を原本**とし、**init がプロジェクトの `.claude/rules/` へ managed 上書き展開**する(手編集禁止・プラグイン update + init 再実行で更新。プロジェクト固有の上書きは conventions.md)。第 2 段は rule(要約 = 強制注入)+ 器 skill(references = オンデマンド詳細)の 2 層 — references 69 本 ≒ 20 万トークンのため rule 本文への統合は不成立(実測)。詳細の置き場としてプラグインを維持することで、導入先リポジトリを rules だけに保つ。
- **既存プロジェクトへの追加型に徹する(2026-09)**: プラグインがプロジェクトへ展開するのは `.claude/rules/`(規範 + aidd.md)のみ。AGENTS.md / README / ビルド設定(正典実物含む)は**アプリ側テンプレートが用意**し、正典の正もアプリ側へ移った。説明文書・雛形はフロー skill の references、docs 骨格(adr / work / spec / reference / pm)は各フロー skill が必要時に生成。skill / references から「テンプレ側に実物があり以後変更が発生しない定型」は削除する — 判断基準 = **AI がそのコードを新規に書く・変更する場面が開発中に存在するか**。
- **SDD レベルは lite | full の 2 値(2026-09)**: aidd.md(flow の init が生成する managed 宣言・SDD レベル 1 行のみ)をフロー skill が実行時に読んで分岐する。lite = SPEC / PLAN は docs/work の一時物(完了時にクローズ蒸留して削除)/ full = SPEC は docs/spec の恒久文書(spec-close で蒸留して残す + /trace)。PLAN は全レベルで一時物。
- **規範 rule は所属 prefix 付きで命名する(2026-09)**: `dotnet-*` / `smart-*`(例: dotnet-async / smart-mvvm)。一覧での出自判別と同名衝突の解消。フロー skill は短い名前を維持(プラグイン修飾は機構が付与)。
- **template-architecture を統合し凍結(2026-09)**: 旧上流リポジトリの内容(規範 93 本 → 削減後 69 本・正典実物)は本リポジトリの plugins へ統合済み。元リポジトリは凍結し、Phase 4 完了後に GitHub アーカイブ化(人の判断)。
- **バージョン運用は「内容を変えたら必ずバンプ」(2026-09)**: 更新検知は plugin.json の version 比較のみ。references 1 本の改稿でもバンプ(漏れ = 配布されない改稿)。パッチ = 改稿 / マイナー = skill・展開内容・hooks / MCP の増減 / メジャー = 構成転換。4 プラグインは独立バンプ、コミット = リリース。運用開始は初回導入後(それまで 0.1.0 固定)。
- **外部 skill / MCP の扱い**: 標準のみ同梱。外部(dotnet-skills 等)はプラグイン導入 / vendor せず、必要な要点を**日本語で蒸留した自前の規範・skill** にして出典をリンクする。本プラグインの規範が常に優先。
- **プラグイン化の完了と移行素材の削除(2026-09)**: 全フェーズ完了。移行素材(staging / 旧原本 / 旧配布 docs / .claude 旧素材 / 保守の経緯文書)は削除済み(git 履歴から復元可能)。残る実運用検証(ドッグフーディング・実プロジェクト一巡)の観点は [maintenance.md](maintenance.md)。

## 規範内容の決定(rules に反映済みの why)

- **データアクセスは EF Core を既定にしない**: ORM / データアクセス方式は用途で選定(Micro-ORM・生 SQL も対等)。選定は ADR に残す。第 2 段は Smart.Data.Accessor を標準として断定。
- **XAML 系の MVVM 基盤は Smart.Mvvm + Smart.Navigation を標準とする(第 2 段)**: 蒸留済みの実績標準を採用。CommunityToolkit.Mvvm は導入しない。多画面は `Modules/<機能>` の vertical slice、WindowManager はツール的な子ウィンドウ管理に限定。第 1 段は中立(選定は ADR)。
- **ServiceDefaults プロジェクトを作らない**: Aspire の ServiceDefaults 相当は独立プロジェクトにせず、Web アプリ本体の `Application/` に拡張メソッドとして取り込む(AppHost は残す)。
- **ホスティング API は `HostApplicationBuilder` 系に追随**: `builder.Services.AddWindowsService()` / `AddSystemd()` を正とする。
- **設定の注入形は明示しない**: `IOptions<Setting>` と設定実体のどちらを注入するかは要件次第。既定を決めない。
- **Analyzers.ruleset から層・プラットフォーム依存規則を除去**: CA2007 / CA1303 / CA1305 / CA1416 は ruleset に含めず、必要なプロジェクトの `GlobalSuppressions.cs` で扱う(警告抑止の三層)。
- **時刻の扱い**: `DateTime.Now` を直参照しない。業務の処理日時はコンテキストに確定値として保持し、「今」を確定する境界だけ `TimeProvider` を注入してテストで差し替える。
- **Worker は 2 様式**: 常駐型とワンショット型(外部スケジューラ + ExitCode)を対等な様式とする(選定は ADR)。周期実行の既定は `PeriodicTimer`、絶対時刻同期は「next + 差分 Delay」方式。
- **ログレベルの定義と LoggerMessage 全面採用**: WARN = 想定内の異常(処理は継続)、ERROR の出力箇所は基盤部分が基本。ログ出力は `[LoggerMessage]` ソース生成を全面採用(直書き禁止)。
- **ADR と rules は独立して保管する**: `docs/adr` = なぜの履歴(不変・追記のみ・`index.md` は生成物)、`.claude/rules` = 決定の機械制約面。相互リンクは持たない(発見はタグ・語彙の一致)。レビューが見るのは ADR 準拠(rules は paths で効くため再確認しない)。
- **作業フォルダは docs/work/ で git 管理する**: 一時物だが履歴に残す(仕様レビュー・worktree・別マシン再開・引き継ぎが成立)。解決規則 =「ブランチ slug フォルダ優先・無ければ直下」(正は work-init skill)。git 操作の型は git-commit skill に一元化(提示のみ・実行は人。work-close / git-commit skill として依頼されたときは AI 実行可)。
- **Blazor / domain / testing の残決定**: Blazor は code-behind 常時分離(Server / WASM 共通)・フォーム検証はライブラリ選定を ADR に。domain の Code 定数は DB 格納型と同型・Subcase は Usecase 層の DI 部品に限る。テストのモックは NSubstitute 標準・テスト名は英語 PascalCase 3 部構成。
- **文体**: 日本語。ASCII 記号・括弧は半角(中黒 `・` は全角)、`§` 不使用、冗長・自明な括弧補足を書かない。
