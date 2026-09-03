# aidd — C# × Claude Code プラグイン

私有配布の Claude Code プラグイン marketplace。C# / .NET の AI 駆動開発を「ルール 2 + ワークフロー 2」の 4 プラグインで支援する。

| プラグイン | 役割 | 依存 |
|---|---|---|
| [aidd-dotnet](#-aidd-dotnet--cnet-標準ルール) | C# / .NET 標準のルール(ライブラリ中立) | — |
| [aidd-smart](#-aidd-smart--smart-アーキテクチャルール) | Smart ライブラリを使用したアーキテクチャのルール | aidd-dotnet |
| [aidd-flow](#-aidd-flow--基本ワークフロー) | spec / plan / 実装の基本ワークフロー | —(.NET では aidd-dotnet 併用推奨) |
| [aidd-pm](#-aidd-pm--プロジェクト管理) | 基本ワークフロー + PM(イテレーション計画・進捗) | aidd-flow |

## 🚀 導入

前提: 私有リポジトリのため git 認証(SSH または `gh auth login`)を済ませておく。

```
/plugin marketplace add usausa/template-spec
/plugin install aidd-smart@aidd   # ルール一式 (依存で aidd-dotnet も入る)
/plugin install aidd-pm@aidd      # ワークフロー一式 (依存で aidd-flow も入る)
```

導入後に各 init を実行する(展開先は `.claude/rules/` のみ。managed = 再実行で上書き更新):

```
/aidd-dotnet:init            # dotnet rules 20 本を展開
/aidd-flow:init [lite|full]  # SDD レベルを宣言 (aidd.md)
/aidd-smart:init             # smart rules 19 本を展開
```

更新は `/plugin marketplace update aidd` → `/plugin update <plugin>@aidd` → rules 系の init を再実行。更新検知は plugin.json の version 比較のみ(内容を変えたら必ずバンプ)。

## 📐 aidd-dotnet — C#/.NET 標準ルール

対象ファイルを読むと `paths:` で自動適用されるアーキ規範。序列は **conventions.md(プロジェクト固有)> smart-* > dotnet-* > 外部**。

| rule | 内容 |
|---|---|
| dotnet-coding-principles | コーディング原則(.NET 共通) |
| dotnet-async | 非同期処理の規約 |
| dotnet-errors | 例外・異常系の扱い |
| dotnet-logging | ログ設計 |
| dotnet-security | セキュリティ標準(.NET 共通) |
| dotnet-data | DB / データアクセス規約 |
| dotnet-domain | Domain 実装規約 |
| dotnet-http-client | HTTP クライアント |
| dotnet-testing | テストの書き方 |
| dotnet-web | アーキテクチャ(Web 全般) |
| dotnet-api | Web API(minimal API) |
| dotnet-blazor | Blazor(UI / コンポーネント) |
| dotnet-blazor-e2e | Blazor E2E テスト(Playwright) |
| dotnet-grpc | gRPC サーバ |
| dotnet-worker | アーキテクチャ(Worker / 常駐サービス) |
| dotnet-cli | CLI ツール |
| dotnet-mvvm | MVVM アーキテクチャ(XAML 系共通) |
| dotnet-desktop | デスクトップ(Windows 環境固有) |
| dotnet-wpf | WPF(UI 技術固有) |
| dotnet-maui | MAUI(プラットフォーム固有) |

| その他 | 内容 |
|---|---|
| init | dotnet rules の展開 |
| hooks | 編集後の dotnet format 検証・UTF-8/CRLF 正規化 |
| MCP | Microsoft Learn + NuGet(.NET 10 SDK の `dnx` が必要) |

## 🧠 aidd-smart — Smart アーキテクチャルール

`dotnet-*` の中立規律を上書き具体化し、ライブラリを断定する(Smart.Mvvm / Smart.Navigation / Smart.Data.Accessor / Serilog / NSwag ほか)。各 rule と対になる同名の器 skill がコード例付き詳細(references 69 本)を持ち、必要時に読まれる。

| rule | 内容 |
|---|---|
| smart-structure | プロジェクト構造(警告抑止三層・定型ファイル・メンバ順序) |
| smart-solution | ソリューション分割 |
| smart-namespace | 名前空間辞書 |
| smart-host | DI 登録(登録順・切り出し・スコープ) |
| smart-config | 設定クラス |
| smart-log | ログ(LoggerMessage 定型・Serilog・調査用トグル) |
| smart-data | データアクセス(Smart.Data.Accessor・2-way SQL) |
| smart-web | Web API(Minimal API・契約・NSwag) |
| smart-blazor | Blazor(code-behind 分離・基底・検証) |
| smart-mvvm | MVVM(Smart.Mvvm / Navigation / Resolver・Modules 構成) |
| smart-wpf | WPF(WindowManager 方式) |
| smart-avalonia | Avalonia(組込み向け入力抽象化) |
| smart-maui | MAUI(自前 Shell・Components 分割・Blazor Hybrid) |
| smart-worker | バッチ・CLI(IAction + ActionWorker・System.CommandLine) |
| smart-network | TCP サーバ(Kestrel ConnectionHandler・アロケーションフリー) |
| smart-test | テスト(xunit.v3 + MTP・AAA・モック方針) |
| smart-telemetry | テレメトリ・ヘルスチェック(ApplicationInstrument) |
| smart-generator | ソースジェネレータ(IIncrementalGenerator・実ビルドテスト) |
| smart-guideline | 横断ガイドライン詳細(エラー処理・非同期・HTTP クライアント) |

## 🔁 aidd-flow — 基本ワークフロー

SDD フロー(lite = 一時 SPEC / full = 恒久 SPEC + 蒸留。`.claude/rules/aidd.md` の宣言で実行時分岐)。人向けの回し方は spec skill の references/workflow.md。

| skill | 区分 | 内容 |
|---|---|---|
| spec | ループ | アイディアの箇条書きから SPEC を草案化(承認まで実装しない) |
| plan | ループ | SPEC から実装プラン(チェックリスト・フェーズ分割) |
| impl | ループ | フェーズ単位の実装 + PLAN チェック更新 |
| verify | ループ | build + test の実行と自己修正フィードバック |
| review | ループ | reviewer サブエージェントで観点レビュー |
| done | ループ | Definition of Done ゲート + クローズ |
| adr | 随時 | 設計上の決定を ADR ドラフト化 |
| reference | 随時 | docs/reference の再生成(OpenAPI 等) |
| trace | 随時(full) | SPEC↔ADR↔test↔code の ID 整合検査 |
| review-cross | 随時 | 別ベンダー(Codex)でのクロスレビュー手順 |
| work-init | 補助 | 作業ブランチ + 作業フォルダの用意(解決規則の正) |
| work-close | 補助 | 作業のクローズ(一時物削除・最終プッシュ提示) |
| spec-close | 補助(full) | SPEC のクローズ蒸留(非復元の意図だけ残す) |
| adr-guide | 補助 | ADR の内容・構成・粒度のガイド(見本 4 本同梱) |
| rule-create | 補助 | プロジェクト固有 rule の追加手順 |
| git-commit | 補助 | コミットメッセージ / ブランチ命名の規約 |
| csharp-layered-feature | 補助 | 層構成に沿った C# 機能追加の手順 |
| sync-docs-from-code | 補助 | reference 生成の初期導入と CI ドリフト検知 |
| init | 初期化 | aidd.md(SDD レベル宣言)の生成 |

| その他 | 内容 |
|---|---|
| agents | spec(仕様草案)/ reviewer(レビュー)/ doc-sync(reference 同期) |
| hooks | 応答終了時の DoD リマインド |

## 📊 aidd-pm — プロジェクト管理

feature 単位(1 feature ≒ 1 SPEC)のイテレーション管理。**SDD full 前提**(WBS / フェーズゲートは使わない)。

| skill | 内容 |
|---|---|
| pm-plan | SPEC を backlog にイテレーション計画を作成・更新(docs/pm は初回生成) |
| pm-status | SPEC / ADR / 実装 / テストの有無から進捗ボードを更新 |

| その他 | 内容 |
|---|---|
| agents | pm(計画・集計の実行担当。方針の正は references/pm-policy.md) |
