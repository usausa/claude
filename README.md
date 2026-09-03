# 開発用 Claude Code プラグイン

| プラグイン | 役割 | 依存 |
|---|---|---|
| [aidd-dotnet](#-aidd-dotnet--cnet-標準ルール) | C# / .NET 標準のルール(ライブラリ中立) | - |
| [aidd-smart](#-aidd-smart--smart-アーキテクチャルール) | Smart ライブラリを使用したアーキテクチャのルール | aidd-dotnet |
| [aidd-flow](#-aidd-flow--基本ワークフロー) | spec / plan / 実装の基本ワークフロー | -(.NET では aidd-dotnet 併用推奨) |
| [aidd-pm](#-aidd-pm--プロジェクト管理) | 基本ワークフロー + PM(イテレーション計画・進捗) | aidd-flow |

## 🚀 導入

```
/plugin marketplace add usausa/template-spec
/plugin install aidd-smart@aidd   # ルール一式 (依存で aidd-dotnet も入る)
/plugin install aidd-pm@aidd      # ワークフロー一式 (依存で aidd-flow も入る)
```

導入後に各 init を実行する。

```
/aidd-dotnet:init            # dotnet rules 20 本を展開
/aidd-flow:init [lite|full]  # SDD レベルを宣言 (aidd.md)
/aidd-smart:init             # smart rules 19 本を展開
```

init が展開するファイル(`.claude/rules/` の dotnet-* / smart-* / aidd.md)は managed で、**init 再実行時に上書きされる**(手編集しない。プロジェクト固有の上書きは conventions.md へ)。

更新は `/plugin marketplace update aidd` → `/plugin update <plugin>@aidd` → rules 系の init を再実行。  
更新検知は plugin.json の version 比較のみ(内容を変えたら必ずバンプ)。

## 📐 aidd-dotnet - C#/.NET 標準ルール

対象ファイルを読むと `paths:` で自動適用されるアーキ規範。

| rule | 内容 |
|---|---|
| [dotnet-coding-principles](plugins/aidd-dotnet/.claude/rules/dotnet-coding-principles.md) | コーディング原則(.NET 共通) |
| [dotnet-async](plugins/aidd-dotnet/.claude/rules/dotnet-async.md) | 非同期処理の規約 |
| [dotnet-errors](plugins/aidd-dotnet/.claude/rules/dotnet-errors.md) | 例外・異常系の扱い |
| [dotnet-logging](plugins/aidd-dotnet/.claude/rules/dotnet-logging.md) | ログ設計 |
| [dotnet-security](plugins/aidd-dotnet/.claude/rules/dotnet-security.md) | セキュリティ標準(.NET 共通) |
| [dotnet-data](plugins/aidd-dotnet/.claude/rules/dotnet-data.md) | DB / データアクセス規約 |
| [dotnet-domain](plugins/aidd-dotnet/.claude/rules/dotnet-domain.md) | Domain 実装規約 |
| [dotnet-http-client](plugins/aidd-dotnet/.claude/rules/dotnet-http-client.md) | HTTP クライアント |
| [dotnet-testing](plugins/aidd-dotnet/.claude/rules/dotnet-testing.md) | テストの書き方 |
| [dotnet-web](plugins/aidd-dotnet/.claude/rules/dotnet-web.md) | アーキテクチャ(Web 全般) |
| [dotnet-api](plugins/aidd-dotnet/.claude/rules/dotnet-api.md) | Web API(minimal API) |
| [dotnet-blazor](plugins/aidd-dotnet/.claude/rules/dotnet-blazor.md) | Blazor(UI / コンポーネント) |
| [dotnet-blazor-e2e](plugins/aidd-dotnet/.claude/rules/dotnet-blazor-e2e.md) | Blazor E2E テスト(Playwright) |
| [dotnet-grpc](plugins/aidd-dotnet/.claude/rules/dotnet-grpc.md) | gRPC サーバ |
| [dotnet-worker](plugins/aidd-dotnet/.claude/rules/dotnet-worker.md) | アーキテクチャ(Worker / 常駐サービス) |
| [dotnet-cli](plugins/aidd-dotnet/.claude/rules/dotnet-cli.md) | CLI ツール |
| [dotnet-mvvm](plugins/aidd-dotnet/.claude/rules/dotnet-mvvm.md) | MVVM アーキテクチャ(XAML 系共通) |
| [dotnet-desktop](plugins/aidd-dotnet/.claude/rules/dotnet-desktop.md) | デスクトップ(Windows 環境固有) |
| [dotnet-wpf](plugins/aidd-dotnet/.claude/rules/dotnet-wpf.md) | WPF(UI 技術固有) |
| [dotnet-maui](plugins/aidd-dotnet/.claude/rules/dotnet-maui.md) | MAUI(プラットフォーム固有) |

| その他 | 内容 |
|---|---|
| [init](plugins/aidd-dotnet/skills/init/SKILL.md) | dotnet rules の展開 |
| hooks | 編集後の dotnet format 検証・UTF-8/CRLF 正規化 |
| MCP | 下表の 2 サーバーを同梱 |

| MCP サーバー | 種類 | 用途 |
|---|---|---|
| microsoft-learn | http(`learn.microsoft.com/api/mcp`) | Microsoft Learn ドキュメントの参照(API・設定の一次情報) |
| nuget | stdio(`dnx NuGet.Mcp.Server` — .NET 10 SDK が必要) | パッケージ検索・バージョン確認・脆弱性チェック |

## 🧠 aidd-smart - Smart アーキテクチャルール

Smartライブラリを使用したアプリケーションテンプレートで使用する。

| rule | 内容 |
|---|---|
| [smart-structure](plugins/aidd-smart/.claude/rules/smart-structure.md) | プロジェクト構造(警告抑止三層・定型ファイル・メンバ順序) |
| [smart-solution](plugins/aidd-smart/.claude/rules/smart-solution.md) | ソリューション分割 |
| [smart-namespace](plugins/aidd-smart/.claude/rules/smart-namespace.md) | 名前空間辞書 |
| [smart-host](plugins/aidd-smart/.claude/rules/smart-host.md) | DI 登録(登録順・切り出し・スコープ) |
| [smart-config](plugins/aidd-smart/.claude/rules/smart-config.md) | 設定クラス |
| [smart-log](plugins/aidd-smart/.claude/rules/smart-log.md) | ログ(LoggerMessage 定型・Serilog・調査用トグル) |
| [smart-data](plugins/aidd-smart/.claude/rules/smart-data.md) | データアクセス(Smart.Data.Accessor・2-way SQL) |
| [smart-web](plugins/aidd-smart/.claude/rules/smart-web.md) | Web API(Minimal API・契約・NSwag) |
| [smart-blazor](plugins/aidd-smart/.claude/rules/smart-blazor.md) | Blazor(code-behind 分離・基底・検証) |
| [smart-mvvm](plugins/aidd-smart/.claude/rules/smart-mvvm.md) | MVVM(Smart.Mvvm / Navigation / Resolver・Modules 構成) |
| [smart-wpf](plugins/aidd-smart/.claude/rules/smart-wpf.md) | WPF(WindowManager 方式) |
| [smart-avalonia](plugins/aidd-smart/.claude/rules/smart-avalonia.md) | Avalonia(組込み向け入力抽象化) |
| [smart-maui](plugins/aidd-smart/.claude/rules/smart-maui.md) | MAUI(自前 Shell・Components 分割・Blazor Hybrid) |
| [smart-worker](plugins/aidd-smart/.claude/rules/smart-worker.md) | バッチ・CLI(IAction + ActionWorker・System.CommandLine) |
| [smart-network](plugins/aidd-smart/.claude/rules/smart-network.md) | TCP サーバ(Kestrel ConnectionHandler・アロケーションフリー) |
| [smart-test](plugins/aidd-smart/.claude/rules/smart-test.md) | テスト(xunit.v3 + MTP・AAA・モック方針) |
| [smart-telemetry](plugins/aidd-smart/.claude/rules/smart-telemetry.md) | テレメトリ・ヘルスチェック(ApplicationInstrument) |
| [smart-generator](plugins/aidd-smart/.claude/rules/smart-generator.md) | ソースジェネレータ(IIncrementalGenerator・実ビルドテスト) |
| [smart-guideline](plugins/aidd-smart/.claude/rules/smart-guideline.md) | 横断ガイドライン詳細(エラー処理・非同期・HTTP クライアント) |

## 🔁 aidd-flow - 基本ワークフロー

開発用ワークフロー。  
人向けのドキュメントは [references/workflow.md](plugins/aidd-flow/skills/spec/references/workflow.md)。

| skill | 区分 | 内容 |
|---|---|---|
| [spec](plugins/aidd-flow/skills/spec/SKILL.md) | ループ | アイディアの箇条書きから SPEC を草案化(承認まで実装しない) |
| [plan](plugins/aidd-flow/skills/plan/SKILL.md) | ループ | SPEC から実装プラン(チェックリスト・フェーズ分割) |
| [impl](plugins/aidd-flow/skills/impl/SKILL.md) | ループ | フェーズ単位の実装 + PLAN チェック更新 |
| [verify](plugins/aidd-flow/skills/verify/SKILL.md) | ループ | build + test の実行と自己修正フィードバック |
| [review](plugins/aidd-flow/skills/review/SKILL.md) | ループ | reviewer サブエージェントで観点レビュー |
| [done](plugins/aidd-flow/skills/done/SKILL.md) | ループ | Definition of Done ゲート + クローズ |
| [adr](plugins/aidd-flow/skills/adr/SKILL.md) | 随時 | 設計上の決定を ADR ドラフト化 |
| [reference](plugins/aidd-flow/skills/reference/SKILL.md) | 随時 | docs/reference の再生成(OpenAPI 等) |
| [trace](plugins/aidd-flow/skills/trace/SKILL.md) | 随時(full) | SPEC↔ADR↔test↔code の ID 整合検査 |
| [review-cross](plugins/aidd-flow/skills/review-cross/SKILL.md) | 随時 | 別ベンダー(Codex)でのクロスレビュー手順 |
| [work-init](plugins/aidd-flow/skills/work-init/SKILL.md) | 補助 | 作業ブランチ + 作業フォルダの用意(解決規則の正) |
| [work-close](plugins/aidd-flow/skills/work-close/SKILL.md) | 補助 | 作業のクローズ(一時物削除・最終プッシュ提示) |
| [spec-close](plugins/aidd-flow/skills/spec-close/SKILL.md) | 補助(full) | SPEC のクローズ蒸留(非復元の意図だけ残す) |
| [adr-guide](plugins/aidd-flow/skills/adr-guide/SKILL.md) | 補助 | ADR の内容・構成・粒度のガイド(見本 4 本同梱) |
| [rule-create](plugins/aidd-flow/skills/rule-create/SKILL.md) | 補助 | プロジェクト固有 rule の追加手順 |
| [git-commit](plugins/aidd-flow/skills/git-commit/SKILL.md) | 補助 | コミットメッセージ / ブランチ命名の規約 |
| [csharp-layered-feature](plugins/aidd-flow/skills/csharp-layered-feature/SKILL.md) | 補助 | 層構成に沿った C# 機能追加の手順 |
| [sync-docs-from-code](plugins/aidd-flow/skills/sync-docs-from-code/SKILL.md) | 補助 | reference 生成の初期導入と CI ドリフト検知 |
| [init](plugins/aidd-flow/skills/init/SKILL.md) | 初期化 | aidd.md(SDD レベル宣言)の生成 |

SDD レベルの選択で、生成物の扱い(残る / 完了時に削除)が変わる:

| 生成物 | lite | full |
|---|---|---|
| SPEC(docs/work/) | 一時物(work-close が**削除**。クローズ蒸留で決定→ADR / 用語→glossary / 受け入れ条件→テスト名へ) | 使わない |
| SPEC(docs/spec/SPEC-NNNN) | 作られない | 恒久文書(spec-close で蒸留して**残す**) |
| PLAN(docs/work/) | 一時物(完了時に**削除**) | 一時物(完了時に**削除**) |
| docs/traceability/ | 作られない | /trace が生成・維持 |

| その他 | 内容 |
|---|---|
| agents | [spec](plugins/aidd-flow/agents/spec.md)(仕様草案)/ [reviewer](plugins/aidd-flow/agents/reviewer.md)(レビュー)/ [doc-sync](plugins/aidd-flow/agents/doc-sync.md)(reference 同期) |
| hooks | 応答終了時の DoD リマインド |

## 📊 aidd-pm - プロジェクト管理

feature 単位(1 feature = 1 SPEC)のイテレーション管理。

| skill | 内容 |
|---|---|
| [pm-plan](plugins/aidd-pm/skills/pm-plan/SKILL.md) | SPEC を backlog にイテレーション計画を作成・更新(docs/pm は初回生成) |
| [pm-status](plugins/aidd-pm/skills/pm-status/SKILL.md) | SPEC / ADR / 実装 / テストの有無から進捗ボードを更新 |

| その他 | 内容 |
|---|---|
| agents | [pm](plugins/aidd-pm/agents/pm.md)(計画・集計の実行担当。方針の正は [references/pm-policy.md](plugins/aidd-pm/skills/pm-plan/references/pm-policy.md)) |
