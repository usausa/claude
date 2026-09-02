# アーキテクチャ蒸留 — トピックカタログ(経緯記録)

> 旧 template-architecture でアーキ規範 93 本を蒸留した際のトピック候補一覧と決定事項。分類は aidd-smart の skill 20 分類(skills/<分類>/references/)にそのまま対応する。規範本体の改稿は staging/architecture/(移行完了後は各 references/)で行い、本ファイルは追補しない。

既存プロジェクト群から .NET アプリケーションのアーキテクチャパターンを蒸留するための、トピック候補の一覧。
これを元に「どのトピックを」「どの粒度で」ドキュメント化するかを決定する。決定済みの方針は「2. 決定事項」に集約。

- トピックは**分類タグ**でグループ化し、ID は `分類-連番` 形式。分類はそのままドキュメントのフォルダ構成になる想定(タグの増減・改名は自由)

## 分類一覧

| 分類 | 対象 | 件数 |
|---|---|---|
| `structure` | プロジェクト構造(リポジトリ骨格・ビルド設定・品質ゲート・スタイル) | 7 |
| `solution` | ソリューション・プロジェクト分割 | 4 |
| `namespace` | 名前空間辞書(どの名前空間に何を置くか) | 7 |
| `host` | 起動処理(Program.cs、DI 登録)— サーバ系 | 5 |
| `deploy` | サービス化・発行・systemd | 3 |
| `log` | ログ(Serilog、Log.cs) | 5 |
| `config` | 設定クラス | 4 |
| `data` | データアクセス | 3 |
| `web` | Web API(Minimal API / Controller / gRPC / 認証) | 6 |
| `blazor` | Blazor(ViewHelper、State、認証 UI) | 9 |
| `mvvm` | XAML 系クライアント共通(Smart.Mvvm / Navigation / Resolver) | 5 |
| `wpf` | WPF 固有 | 3 |
| `avalonia` | Avalonia 固有(desktop / embedded) | 3 |
| `maui` | MAUI 固有 | 5 |
| `worker` | バッチ・CLI | 3 |
| `network` | ソケット・プロトコル処理 | 3 |
| `test` | テスト | 8 |
| `telemetry` | OpenTelemetry・ヘルスチェック | 3 |
| `generator` | ソースジェネレータ | 4 |
| `guideline` | 横断ガイドライン(エラー処理・非同期 等) | 3 |

## 1. トピックカタログ(分類毎)

### structure — プロジェクト構造

ほぼ全プロジェクトで一致しており揺れが小さい。即ドキュメント化可能な確定事項に近い。

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| structure-1 | リポジトリ骨格 | `.slnx` + Solution Items フォルダ(.editorconfig / Analyzers.ruleset / Directory.Build.props 等を登録)、`AGENTS.md`(4行のコーディング規約) + `CLAUDE.md`(`@AGENTS.md` の1行参照)、`.sln.DotSettings` / `Settings.XamlStyler` | — |
| structure-2 | Directory.Build.props 標準 | `LangVersion=preview` / `Nullable=enable` / `WarningsAsErrors=nullable` / `AnalysisMode=All` + `AnalysisLevel=latest` / `EnforceCodeStyleInBuild` / `Deterministic` / `MSBuildWarningsAsMessages=SA0001` / StyleCop.Analyzers + Usa.Smart.Analyzers.JapaneseComment / Release 時のみ SourceLink + `ContinuousIntegrationBuild` / `Version` の一括管理。`Directory.Build.targets` は空の拡張点 | — |
| structure-3 | Analyzers.ruleset(決定: 共通化を基本) | 全 ruleset が `<IncludeAll Action="Warning"/>` からの減算方式で共通。**共通コア(全プロジェクト一致)**: `this.` 不要(SA1101)、メンバ順序系(SA1201/1202/1204/1214)、空行系(SA1512/1513/1515/1516)、ドキュメントコメント系(SA1600/1602/1633/1649)、SA1005/SA1121/SA1402/SA1413、CA1028/CA1062(準共通: SA1203/SA1601/CA1002/CA1716/CA1724)。**プロジェクトによる採用**: CA1873(新世代のみ)、CA1416/CA1303/CA1305(クライアント系)、SA1116/SA1117(引数レイアウト、約半数)、CA2007 を ruleset 側に置く例(クライアント系)。アプリ用/基盤用に2分割する構成例もあり(アプリ側は SA1116-1118/CA1034/CA2254、基盤側は SA1503/CA1512 を緩和する非対称構成)。**決定: 共通 ruleset への一本化を基本とし、層依存の規則は ruleset に含めない**(→ structure-4) | — |
| structure-4 | 警告抑止の三層 | ① ruleset = ソリューション全体・全アセンブリ共通のルール強度。② `GlobalSuppressions.cs` = アセンブリ(プロジェクト)単位の恒久抑止 — **標準ペアは CA1515(トップレベル型を internal にせよ) + CA2007(ConfigureAwait)**。プロジェクトにより CA1819(配列プロパティ)/CA1861/CA1707、SonarAnalyzer 併用側は S 系(S125/S1135 等)、LoggerMessage 不使用側は CA1848 を追加。③ `#pragma warning disable` = 局所抑止(クラス/メソッド単位で囲む、`[SuppressMessage]` には日本語で Justification)。②が ruleset と分かれているのは「ライブラリでは抑止しない」というアセンブリ粒度の判断のため。**決定: CA2007 のような層依存の規則は GlobalSuppressions でプロジェクト単位に無効化する**(Web プロジェクトでは意味をなさないが共通サービス用 DLL では意味をなす、という層依存性のため。ruleset には含めない) | — |
| structure-5 | 定型ファイル | 各プロジェクトに `GlobalUsing.cs`(先頭に ReSharper disable + pragma、System → サードパーティ → 自プロジェクトの順、将来の置き場をコメントアウトで予約) / `Assembly.cs`(`[assembly: CLSCompliant(false)]` + プラットフォーム属性) / `GlobalSuppressions.cs`(役割は structure-4) | — |
| structure-6 | コーディングスタイル (.editorconfig) | file-scoped namespace + **using は namespace の内側**、`sealed` 徹底、`_` プレフィックス禁止、区切りコメントによるセクション構造化(`// Log` 1行形式と `//---- 80桁罫線 ----` 帯形式)、ラムダへの `static` 付与。**統一状況(確認済み)**: 大半のリポジトリで単一の .editorconfig とバイト一致。一部に旧世代版(セクション構成、IDE 系 diagnostic 行、一部ルール強度の差)が残るが同一系統からの派生。**決定: .editorconfig は統一する方向**(本リポジトリ版を正典として管理) | — |
| structure-7 | メンバ記述順序ガイドライン(決定) | **① 定数(const / static readonly) → ② フィールド(static → インスタンス、readonly 優先) → ③ イベント → ④ プロパティ(VM の ObservableProperty・コマンド、Blazor の `[Inject]`/`[Parameter]` を含む) → ⑤ コンストラクタ(+ Dispose) → ⑥ ライフサイクルメソッド(OnInitialized / ExecuteAsync 等) → ⑦ メソッド群 → ⑧ ネスト型**。メソッド群の中は **public/private の順序よりも処理の種類単位のグルーピングを優先**する(公開メソッドの位置は固定しない)。グループは `//----` 区切りでセクション化し、関連メンバの近接配置(フィールドとプロパティの対、小さなヘルパーを利用箇所の近くに置く等)は優先してよい。ruleset のメンバ順序系(SA1201 等)は無効のままとし機械強制しない | — |

### solution — ソリューション・プロジェクト分割

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| solution-1 | プロジェクト分割の基本形 | `X.Core`(RootNamespace を短縮: `Template.Core` → `Template`) + ホスト + `X.Tests` の3点構成。クライアントは1ソリューション=1プロジェクト(フォルダ=名前空間でレイヤ分割) | RootNamespace 短縮規約の明文化 |
| solution-2 | Aspire AppHost(決定: 標準構成に含める) | オーケストレーション専用の極薄 AppHost(数行のみ、業務ロジックゼロ、`WithHttpHealthCheck`)を **Web の標準構成に含める**。**ServiceDefaults プロジェクトは作らない** — 相当機能(テレメトリ・ヘルスチェック等の既定)はアプリ側に実装し、複数プロジェクト構成では基盤層プロジェクト(solution-3)に組み込む | — |
| solution-3 | 基盤層プロジェクトの分離 | Filter/Binder/Json/Validation/Swagger/Telemetry/Worker を基盤プロジェクトに分離し複数ホストで共有。ASP.NET Core 標準機能の差し替え実装はさらに別プロジェクトに隔離。複数プロジェクト構成では ServiceDefaults 相当機能もここに組み込む(solution-2) | 単一/複数プロジェクト構成の分離基準の明文化 |
| solution-4 | Infrastructure の二段構え | アプリ非依存(別プロジェクト、BCL ミラー名前空間 `X.IO` / `X.Threading` 等、CLSCompliant(true))と、アプリ固有だが業務非依存(`Service/Infrastructure/`)の使い分け | 基盤層分離(solution-3)との関係整理 |

### namespace — 名前空間辞書(本リポジトリの中核)

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| namespace-1 | サーバ側の標準語彙 | **`Accessors`(複数形に決定)** / `Models.{Entity,View,Parameter}` / `Services` / **`Usecase`(`Services` と同階層の独立名前空間に決定)** / `Domain.{Code,Logic}` / `Settings` / `Application` / `Infrastructure` / `Providers` / `Contexts` / `Workers` / `Helpers` / `State` / `Endpoints` | — |
| namespace-2 | Application 名前空間(決定: アプリ固有の共通部品用) | **`Application` は「アプリ固有の共通部品」の置き場**(アプリ非依存のインフラ部品は `Infrastructure` → namespace-3)。例: `ApplicationExtensions` / `FeatureFlags` / `MappingProfile` / `NamingPolicy` / `CacheKey` / `LimitPolicy` / `StoragePath` / `Telemetry` / `Validation` / `RateLimiting` / `Logger` | — |
| namespace-3 | Components / Infrastructure(決定) | `Components` は **Blazor 標準ルール(UI コンポーネントの置き場)を優先**する。従来インフラ部品(`I<Name>` + `<Name>` + `<Name>Options` + `<Name>Exception` の4点セット。Storage/Security 等)に使っていた用法は **`Infrastructure` を優先して配置**する(`Application` は「アプリ固有の共通部品」用 → namespace-2) | — |
| namespace-4 | Domain の作法 | `Domain/Code` は enum ではなく `static class` + `const`(DB 数値と直結、判定メソッド同居)。`Domain/Logic` に純関数。`Length` に桁数定数集約。Domain は無依存 | enum を使わない理由と適用範囲の明文化 |
| namespace-5 | モデルのサフィックス規約 | `*Entity`(テーブル) / `*View`(SQL結果) / `*Parameter`(SQL引数) / `*Request`・`*Response`(API境界) / `*Setting` / `*Options` / `*Entry`(ネスト設定) | — |
| namespace-6 | Usecase 層(決定: 独立名前空間) | 一連の業務フロー・外部 SDK・複数 Service を束ねる層。**`Services` と同じ階層の独立した `Usecase` 名前空間に配置する**。戻り値は SDK 型を漏らさず record に詰め替え | — |
| namespace-7 | クライアント側の標準語彙 | `Modules/<機能>`(vertical slice: View+ViewModel 同居) / `State` / `Services`(I/O境界) / `Usecase` / `Components`(プラットフォーム機能) / `Behaviors` / `Messaging` / `Helpers` / `Shell` / `Devices.Input`。**クライアント側の `Components`(プラットフォーム機能ラッパ)はそのまま維持(決定)**。`Modules` の配置規則は MVVM のルールとして mvvm-5 に定義 | — |

### host — 起動処理(サーバ系)

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| host-1 | Program.cs の構成(決定済み) | **基本方針: `builder.ConfigureXxx()` / `app.UseXxx()` の宣言列挙のみとし、実体は `ApplicationExtensions.cs` に集約する方式**。旧方式(一枚岩トップレベル文 + `// Log` 等の区切りコメント)は移行元として扱う | 旧方式からの移行ガイドを書くか |
| host-2 | 起動の定型行 | 冒頭 `Directory.SetCurrentDirectory(AppContext.BaseDirectory)`、`ContentRootPath = WindowsServiceHelpers.IsWindowsService() ? AppContext.BaseDirectory : default`、`Configuration.SetBasePath(...)` | — |
| host-3 | 起動ログの儀式 | ビルド直後に `InfoServiceStart` / Version / Runtime / GC / ThreadPool (+Telemetry) を必ず出力 | — |
| host-4 | DI 登録スタイル | 登録順=レイヤ順を区切りコメントで見せる。機能フォルダ毎の `ServiceCollectionExtensions.AddXxx()` に切り出し、呼び出し側は1行。複数実装は `AddSingleton<I,T>` 並記 → `IEnumerable<T>` 受け。基本 Singleton | べた書きをアンチパターンとするか |
| host-5 | `public partial class Program {}` | WebApplicationFactory 用にファイル末尾で宣言(`[ExcludeFromCodeCoverage]` 付与) | テスト規約とセット |

### deploy — サービス化・発行

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| deploy-1 | Windows/systemd 両対応(決定: Services.Add 形式) | **`builder.Services.AddWindowsService().AddSystemd()` を無条件で両掛けする**。`IServiceCollection` 拡張の `AddWindowsService`/`AddSystemd` が現行 .NET の推奨(公式ドキュメント現行版のコード例。サービス実行検出時に lifetime 設定とイベントログ有効化を行う)。Web ホストの ContentRoot は従来どおりビルダー生成時に明示する(host-2)。`builder.Host.UseWindowsService().UseSystemd()`(`IHostBuilder` 拡張)は旧方式 | — |
| deploy-2 | systemd unit の定石 | `WorkingDirectory=/opt/<app>`、`Restart=always` + `RestartSec=10`、**`KillSignal=SIGINT`**(graceful shutdown 必須)、`SyslogIdentifier`、`Environment=` で環境変数 | — |
| deploy-3 | 発行スクリプト | 単一ファイル + self-contained、win のみ ReadyToRun。csproj 側は `DeploySingleFile` プロパティ有無で条件化、`IncludeNativeLibrariesForSelfExtract`、`appsettings.*.json` は `CopyToPublishDirectory="Never"`、`InvariantGlobalization` | — |

### log — ログ

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| log-1 | Log.cs 定型 | `internal static partial class Log` + `[LoggerMessage]` ソースジェネレータ、`Info*/Warn*/Error*` プレフィックス、書式 `Xxx. key=[{value}]`、名前空間(フォルダ)毎に `Log.cs` を分割配置。文字列補間ログは書かない。素の `LogInformation` を使う場合は `#pragma warning disable CA1848` を明示 | — |
| log-2 | Serilog の構成方法 | コードは `builder.Logging.ClearProviders()` → `AddSerilog(o => o.ReadFrom.Configuration(builder.Configuration))` のみ。**シンク/Enricher/レベルは 100% appsettings の `Serilog` セクションに委譲** | `writeToProviders` を渡す条件(OTLP併用時) |
| log-3 | outputTemplate の標準形 | 基本: `{Timestamp:HH:mm:ss.fff} {Level:u4} {MachineName} [{ThreadId}] - {Message:lj}{NewLine}{Exception}`。Web は `[{SourceContext}]` `{TraceId}` `{RequestId}` `{RequestPath}` を追加。業務フィールド(インスタンス ID / セッション系)の追加や、AsyncLocal なコンテキストから `CallbackEnricher` で値を供給する拡張形あり。**Timestamp は時刻のみ(`HH:mm:ss.fff`、日付を含めない)で確定**(現状の多数派に一致。日付はファイル名・実行文脈から判別) | 用途別テンプレート表(基本/Web/Batch/業務拡張)としてまとめる |
| log-4 | Enricher / シンク構成 | `FromLogContext, WithThreadId, WithMachineName`(+`WithSpan`)。File シンクは実行フォルダ外の Log ディレクトリに日次ローテーション(`<App>_.log`)。Development で Console/Debug 追加 + Debug レベル。Syslog 二重出し(UdpSyslog、Timestamp と Exception を落とした専用テンプレート)の形もあり | — |
| log-5 | ログ4系統の個別トグル | W3C アクセスログ / HTTP ログ / Invoke トレース / SQL トレースを `Log` セクションの bool で ON/OFF (`LogSetting` + 入れ子 Entry) | — |

### config — 設定クラス

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| config-1 | 命名と2系統 | アプリ設定は `<セクション>Setting`(単数形)、再利用コンポーネント付属は `<Name>Options`。全て `sealed`、`{ get; set; } = default!` / `required` | Setting/Options の使い分け基準の明文化 |
| config-2 | バインドの定型2パターン | ① `Configure<T>(GetSection)` + `AddSingleton(p => p.GetRequiredService<IOptions<T>>().Value)` — **IOptions を業務コードに漏らさない**。② 起動時に使う値は `GetSection("X").Get<T>()!` で即時取得しローカル変数化(DI 登録の条件分岐に使用) | ①②の使い分け基準 |
| config-3 | ネスト設定 | 入れ子 sealed class(`~Entry`)。ネスト子を `AddSingleton(parent.Lock)` で**分解して個別 DI 登録**し、利用側は子 Setting を直接受ける | — |
| config-4 | 配置場所(決定済み) | **アプリケーションの設定クラスは `Settings/` 配下に配置。コンポーネント固有の設定(`<Name>Options`)はコンポーネントと同じ場所に配置** | — |

### data — データアクセス

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| data-1 | Smart.Data.Accessor | `[DataAccessor]` interface のみ宣言(実装はジェネレータ)。`[Query]`/`[Execute]`/`[Insert]` 等。`IAccessorResolver<T>` 注入 → `.Accessor` 保持。戻りは `ValueTask<List<T>>` / `IAsyncEnumerable<T>` | — |
| data-2 | 2-way SQL 外部ファイル | `Accessors/Sql/<Interface>.<Method>.sql`。`/*@ param */'ダミー'` 形式でそのまま SQL クライアント実行可能。動的条件は `/*% if */` | — |
| data-3 | 接続・方言・トレース | `DelegateDbProvider` / `DelegateDialect`(重複キー判定等) / `MiniDataProfiler`(SqlTrace トグル) / TypeMap 調整(AnsiString, DateTime2, StringBool) | — |

### web — Web API

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| web-1 | API 方式(決定済み: Minimal API 優先) | **Minimal API を優先する**。`Endpoints` 名前空間に `MapXxxEndpoints(this WebApplication)` の static クラスでエンドポイント群を定義。`MapGroup("/api/<resource>")` でグルーピングし、ルートは `Application/ApiRoutes.cs` に定数化。ハンドラは static メソッド(依存は引数 DI、戻り値は `IResult`)とし、実処理は Service へ委譲 | — |
| web-2 | Controller + Areas(代替方式) | Controller を使う場合の作法: Area 毎に `Base<Area>Controller` へ属性集約(`[ApiController]` `[Route("[area]/[controller]/[action]")]` 等)。Request/Response は `Areas/<Area>/Models/`。Controller は mapper.Map + service 呼び出しのみの極薄 | 適用条件(既存資産・大規模 API 等)の整理 |
| web-3 | 契約の作法(明文化対象) | JSON の命名は **camelCase** を基本とし `NamingPolicy` に集約。**DTO は `*Request` / `*Response` サフィックス**。**トップ階層では配列を返さず必ずクラス(オブジェクト)で包む**。外部仕様固定時のみ `[JsonPropertyName]` 明示。カスタム検証属性群は基盤層の Validation/Annotations に集約。マッピング定義(`[MapConfig]`)は利用箇所の近くに併記 | — |
| web-4 | gRPC | `Api/Protos/*.proto` + `Api/Handlers/<Name>Handler`。Reflection は Development のみ、HealthChecks 併設 | — |
| web-5 | アプリケーション固有の認証状態管理 | **アプリ固有に認証状態を管理する場合**のパターン: `Credential` + ModelBinder/Filter でアクション引数に注入、`[Permission]` 属性。横断状態は `AsyncLocal` な Context(SessionContext/LoggingContext) + Binder | — |
| web-6 | エラー応答・OpenAPI | API は例外ではなく `IResult` で応答し、予期せぬ例外は `AddProblemDetails()` + `UseExceptionHandler()` でグローバル処理(RFC 7807)。OpenAPI は `AddOpenApi()`/`MapOpenApi()`(.NET 10 内蔵)で現状仕様を生成する | — |

### blazor — Blazor

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| blazor-1 | ViewHelper / ViewExtensions | `ViewHelper` = 値→表示の静的純関数(`_Imports.razor` で `@using static` して razor から裸で呼ぶ)。`ViewExtensions` = 書式化の拡張メソッド。ラムダ型推論用 `FilterBy<T>/SortBy<T>` | 両者の境界基準を明文化 |
| blazor-2 | フレームワーク拡張群 | `JSRuntimeExtensions` / `NavigationManagerExtensions` / `SnackbarExtensions` / `DialogServiceExtensions` を `Infrastructure` に集約 | — |
| blazor-3 | AppComponentBase | `ComponentBase, IDisposable` + 遅延 `Disposables`。Hybrid 版は `Execute/ExecuteAsync` + `BusyState` ガード内蔵 | — |
| blazor-4 | code-behind 分離と節構造 | `.razor` + `.razor.cs` partial 必須。`[Inject] public required T X { get; set; }`。ビハインド内の節コメント(`// State → Data → Parameter → Lifecycle → Action → Helper`)は**規約にはしない**(参考パターン) | メンバの一般的な記述順序ガイドラインを別途作成(structure-7) |
| blazor-5 | State 管理(決定済み) | **ページの private フィールドで保持を基本とする**(Scoped な State コンテナ方式は明文化しない) | — |
| blazor-6 | レイアウト・シェル | `MainLayout` が `ITitleManager`/`IMenuSectionManager` を実装し CascadingParameter で配布。`ErrorDispatcher` + `Error403/404/500`。`ProgressState` + `ProgressStateScope`(IDisposable) | — |
| blazor-7 | Cookie 認証一式 | `CookieAuthenticationStateProvider` / `LoginManager` / `ILoginProvider` / `Account` / `Claims` / `Roles` / `TokenHelper` + `CookieAuthenticationSetting` | — |
| blazor-8 | バリデーション | FluentValidation: `FluentValueValidator` + `InlineValidator<Form>` を static readonly で保持、Form はページにネスト定義 | — |
| blazor-9 | UI ライブラリ(決定: 共通要件で規定しない) | UI ライブラリはプロジェクト固有の選定とし、共通要件では規定しない | — |

### mvvm — XAML 系クライアント共通

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| mvvm-1 | Smart.Mvvm 基盤 | `ExtendViewModelBase` + `[ObservableGeneratorOption(Reactive, ViewModel)]` + `[ObservableProperty] partial` プロパティ。`MakeAsyncCommand`/`MakeDelegateCommand`、`BusyState`、`Disposables`、`IReactiveMessenger`。CommunityToolkit は明示的に排除 | — |
| mvvm-2 | Smart.Navigation(決定: 画面遷移の標準) | **画面遷移を持つアプリはプラットフォームを問わず Smart.Navigation を使用する**。画面 ID は enum(`ViewId`/`DialogId`)、View に `[View(ViewId.X)]`、`[ViewSource]` partial で自動登録、シェルは `NavigationContainer`、起動末尾に `ForwardAsync(初期画面)`。DEBUG 時のみ遷移トレース | — |
| mvvm-3 | DI コンテナ差し替え | `SmartServiceProviderFactory`(Smart.Resolver) + `UseAutoBinding/ArrayBinding/AssignableBinding`、`ResolveProvider.Default.Provider = host.Services` で XAML(`s:DataContextResolver.Type`)から VM 解決(code-behind は InitializeComponent のみ) | — |
| mvvm-4 | クライアント起動ハブ | `ApplicationExtensions.cs` に `ConfigureLogging` / `ConfigureComponents` / (embedded)`ConfigureLifetime` / `StartApplicationAsync` / `ExitApplicationAsync` を集約し App を薄く保つ。DI 登録は `ConfigureContainer(ResolverConfig)` 一箇所 | MAUI 版は MauiProgram チェーン(maui-1)と役割分担 |
| mvvm-5 | Modules 構成(決定) | **多数の画面を用意しナビゲーションを行うアプリケーションでは、`Modules/<機能>` フォルダに機能単位で View と ViewModel を同居配置する**(vertical slice)。クライアント一般ではなく MVVM に関するルールとして定義する | — |

### wpf — WPF 固有

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| wpf-1 | WindowManager(決定: 用途限定) | **画面遷移を持つアプリは WPF でも Smart.Navigation を使用し(mvvm-2)、WindowManager はツール的に子ウィンドウを管理するケースで使用する**。`Views/IWindowManager` + `WindowManager`(同一ファイル)。`OnStartup` で `windowManager.Load()`、`OnExit` で `host.StopAsync(5s)`。Closing 時は `CancelEventAction` + `BusyState` で抑止 | — |
| wpf-2 | ウィンドウ配置永続化 | `Settings/WindowSettings : ApplicationSettingsBase` + `MainWindowPlacement` でウィンドウ位置を保存・復元 | — |
| wpf-3 | 例外ハンドリング | `DispatcherUnhandledException` + `AppDomain.UnhandledException` をフックし MessageBox 表示 | — |

### avalonia — Avalonia 固有

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| avalonia-1 | 起動とライフタイム分岐 | `AppBuilder.Configure<App>().UsePlatformDetect().WithInterFont()`。`App.Initialize()` でホスト構築、`OnFrameworkInitializationCompleted` で `IClassicDesktopStyleApplicationLifetime` / `ISingleViewApplicationLifetime` を分岐、`desktop.Exit` → `ExitApplicationAsync()` | — |
| avalonia-2 | 組込みの入力抽象化 | `Devices/Input/IInputDevice`(実機デバイス / `DebugInputDevice` を `#if DEBUG` 切替) + `Shell/NavigationEvent`(Back/Forward に正規化) + `INotifySupportAsync<NavigationEvent>` で現在 VM の `OnNavigationBack/ForwardAsync` へ。Debug 時は `DebugWindow` が `MainView` をホストしボタンで `Trigger` | — |
| avalonia-3 | 組込みの実行形態 | ルートは Window ではなく `MainView`(UserControl)。`#if DEBUG` は desktop 実行、Release は `StartLinuxDrm("/dev/dri/cardN")` 全画面。`NopLifetime : IHostLifetime` でホストのシグナル捕捉を無効化。組込みフォント同梱 | — |

### maui — MAUI 固有

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| maui-1 | MauiProgram 宣言的チェーン | `CreateMauiApp()` は 20+ の `ConfigureXxx()`/`UseXxx()` を1本のチェーンで宣言、各実体は private static 拡張メソッド + 区切りコメント。`ConfigureContainer(ResolverConfig)` の登録順を Components→Messenger→Navigator→State→Service→Usecase→Startup で固定 | — |
| maui-2 | ApplicationInitializer | 起動後処理を `IMauiInitializeService` に隔離(ResolveProvider 設定→Settings 既定値→Navigator 購読→DB Rebuild→ApiContext)。`CrashReport.Start()` で前回クラッシュを `App.OnStart` で表示。App.xaml.cs は Window 生成 + 権限要求 + 初期遷移のみ | — |
| maui-3 | 自前 Shell | `Shell/` に `IShellControl` / `ShellEvent`(Back/Function1-4) / `ShellProperty`(attached BindableProperty) / `ShellUpdateBehavior` / `DiagnosticPanel`。物理キー・共通ヘッダを VM から宣言的に制御 | — |
| maui-4 | プラットフォーム機能ラッパ | `Components/`(NFC・OCR・Bluetooth 等を partial `.android.cs` で分割) / `Behaviors/`(`.android.cs`/`.ios.cs`) / `Messaging/`(EntryController, CameraController 等 View↔VM 命令用コントローラ) | 名称は namespace-3 の決定と整合させる |
| maui-5 | Blazor Hybrid への置換 | Smart.Navigation を捨て `Views/` + `AppComponentBase`(Execute + BusyState)。遷移はメッセージ駆動(`PageNavigator` が `Messenger.Observe<SelectPage>()` を購読し `NavigationManager.NavigateTo`)。ネイティブ橋渡しは `Interop/`(`IPlatformInterop` + MAUI 側ダイアログ) | — |

### worker — バッチ・ジョブ・CLI

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| worker-1 | Batch の共通骨格 | `IAction { Name, ExecuteAsync }` + `ActionWorker : BackgroundService`(コマンドライン引数と Name 突合 → 実行 → 例外時 `ExitCode=-1` → finally で `StopApplication()`)。Program/GlobalUsing/Log/appsettings の定型セット | — |
| worker-2 | コマンドディスパッチ | 複数 `AddSingleton<IAction,T>` → `IEnumerable<T>` 受け → `Array.Find(x => x.Match(...))` の線形ディスパッチ(ステートマシンは持たない) | — |
| worker-3 | CLI ツール | System.CommandLine + Smart.CommandLine.Hosting。`[Command]`/`[Option]` 属性宣言、基底クラスで共通オプション共有、`ICommandFilter` パイプライン(Logging→Exception 最外殻)、`return await host.RunAsync()` で終了コード返却 | — |

### network — ソケット・プロトコル処理

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| network-1 | TCP サーバ基盤(決定: Kestrel) | **TCP サービスは Kestrel の `ConnectionHandler` 継承で構築する**(`CommandHandler` + `CommandContext`)。ソケット直叩きの自作サーバ基盤は標準としない | — |
| network-2 | 受信ループの定型 | `IDuplexPipe` を共通境界に、`ReusableCancellationTokenSource` で `CancelAfter → ReadAsync → フレーム分割 → AdvanceTo → Reset` の同型ループ。フレーム境界検出は static ヘルパ(`SequenceReader.TryReadTo("\r\n"u8)` 等)。通信断は握りつぶしてログ+継続(サービスを落とさない) | — |
| network-3 | アロケーションフリー処理 | `PooledBufferWriter<T>` / `ArrayPool` 拡張 / UTF-8 リテラル `"..."u8` / `ReadOnlySpan<char>` を返す ref パーサ / `StringBuilderPool`。XML 直書きは `PutStartTag/PutElement/PutEndTag` 拡張 | — |

### test — テスト

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| test-1 | AAA パターン(規約決定済み) | **テストは AAA(`// Arrange` / `// Act` / `// Assert`)パターンで記述する**ことを規約とする。**AAA コメントは区切り行として使用し、処理内容に関する和文コメントは区切りとは別に記述する** | — |
| test-2 | テスト基盤(決定済み) | **xunit.v3 + Microsoft.Testing.Platform ランナー(`OutputType=Exe`) + CodeCoverage.runsettings(cobertura、`.g.cs` 除外)を正とする** | — |
| test-3 | 配置・命名(決定) | テストの RootNamespace = 対象と同一、フォルダは対象構造をミラー、クラス名 `<対象>Test`(Tests ではない)、partial 分割可。**テスト名は「対象メソッド + シナリオ + 期待結果」の3部構成をアンダースコアなしの PascalCase で連結する**。例: `DailyAuthorizeFailedReturns403` / `AddEmptyStringReturnsZero`(アンダースコアを含まないため CA1707 の抑止も不要) | — |
| test-4 | モック方針 | NSubstitute(Moq 不使用) + 振る舞い持ちは手書き `private sealed class MockXxx` + `Usa.Smart.Mock.Data`。ロガーは何もしない `DebugLoggerFactory`。**共有モックの名前空間は `Mocks` に決定**(`Mocks/` フォルダ + GlobalUsing) | — |
| test-5 | Helper セクション方式 | クラス冒頭 `// ---- Helper ----` に `CreateParameter`(パラメータオブジェクト) + `CreateXxx()` ファクトリを集約、テスト本体は3〜10行。機能毎に `// ---- Xxx ----` で区切り | AAA(test-1)と併用する形の整理 |
| test-6 | シナリオ結合テスト | `WebApplicationFactory` + `extern alias`、属性で `Scenario/NNXxxTest.cs` ⇔ `data/NNXxx/` を1対1対応、サービス差し替えヘルパ(`RemoveService`)、時刻固定 `StaticTimeProvider`、`[IntegrationFact]` でスキップ制御、リクエスト/レスポンスの JSON 記録(エビデンス化) | — |
| test-7 | bunit | Blazor コンポーネントテスト | — |
| test-8 | テストプロジェクト構成 | **一般方針: `<App>.UnitTests`(単体) + `<App>.IntegrationTests`(`WebApplicationFactory` ベースの結合。任意で E2E/UITests を追加)**。4分割(単体 / シナリオ / テスト部品ライブラリ / データ投入CLI)は大規模向けの発展形であり、一般方針とはしない | — |

### telemetry — テレメトリ・ヘルスチェック

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| telemetry-1 | OpenTelemetry | `ApplicationInstrument`(Meter + ActivitySource + Counter を DI Singleton)、`Source`(Assembly から Name/Version)、`AddApplicationInstrumentation` 拡張。**テレメトリ関連の設定は環境変数から取得する**(OTLP は `OTEL_EXPORTER_OTLP_ENDPOINT` の有無で有効化を分岐、判定は `IConfiguration` 拡張メソッドに隠蔽)。Prometheus は設定節 | — |
| telemetry-2 | HealthChecks | `IHealthCheckPublisher` → `HealthCheckState` シングルトンに吸い上げ。Aspire は `WithHttpHealthCheck("/health")` | — |
| telemetry-3 | 公開エンドポイントの保護 | `/metrics` `/swagger` を IP 制限(`RestrictBuilder` / `UseWhenFrom`)、機能トグル(`EnableSwagger` 等) | — |

### generator — ソースジェネレータ

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| generator-1 | プロジェクト構成と配布 | 本体(属性同居) + Generator(netstandard2.0, IsRoslynComponent) + Tests + Develop ハーネス。パッケージングは `TargetsForTfmSpecificContentInPackage` で `analyzers/dotnet/cs` + `build/<Id>.props` 同梱、依存 DLL は `GeneratePathProperty` | — |
| generator-2 | 実装作法 | `IIncrementalGenerator` + `ForAttributeWithMetadataName`、`// ---- Initialize/Parser/Generator/Helper ----` 4区画、model は `internal sealed record`、`Diagnostics` クラス(ID 体系)、SourceGenerateHelper(SourceBuilder/Result<T>) | — |
| generator-3 | テスト方式 | スナップショットではなく実ビルド方式: `OutputItemType="analyzer"` 参照 + `EmitCompilerGeneratedFiles=true`、Develop プロジェクトで即時確認 | — |
| generator-4 | 応用: AOP + DI 自動登録 | `[Service(typeof(I))]` → ログ/トレース Proxy 生成 + `[ServiceRegistry]` partial メソッドに全 `AddSingleton` を生成。実体/Proxy は実行時切替(登録漏れが構造的に起きない) | — |

### guideline — 横断ガイドライン

| ID | トピック | 内容 | 揺れ・論点 |
|---|---|---|---|
| guideline-1 | エラー処理方針 | **アプリ層の異常系は例外に頼らず結果で通知する**(エラーコードと値はタプル / 専用型)。発生が予期できるものは例外を出さない書き方にする(`Parse` ではなく `TryParse` 等)。予期せぬ例外は各所で握らず **Fail-fast** — グローバルに処理し続行させない(API は `IResult` + ProblemDetails → web-6。常駐処理は件単位で捕捉してログ+継続し、継続不能な異常は落として再起動に任せる)。個別 try/catch を書いてよいのは、ランタイムでしか検出できずライブラリが例外で通知するもののみ(DB 一意制約違反、外部 I/O タイムアウト等)。意図的な握りつぶし(ログのみで継続)には `#pragma warning disable CA1031` を明示。再スローは `throw;`(`throw ex;` 禁止)でスタックトレースを保つ | — |
| guideline-2 | 非同期作法 | I/O は非同期を基本とし、UI スレッド / リクエストスレッドをブロックしない。**`Task.Wait()` / `Task.Result` / `GetAwaiter().GetResult()` を使わない**(sync over async はスレッドプール枯渇・デッドロックの温床)。**`async void` 禁止**(イベントハンドラを除く。Timer コールバックも不可 — Task 返却メソッドにして結果を破棄)。**`CancellationToken` を末端まで伝播**し graceful shutdown に応える。戻り値はフレームワークが `Task` を要求する箇所以外は `ValueTask` を基本とする。`ConfigureAwait(false)` はライブラリ層のみ・アプリ層は付けない(structure-4 の CA2007 層別方針と整合)。自前の `Task.Run` は CPU バウンドの明示的オフロード等の根拠がある場合のみ。`Thread.Sleep` ではなく `Task.Delay`、周期実行は `PeriodicTimer`。`TaskCompletionSource` は `RunContinuationsAsynchronously` を指定。タイムアウト用 CancellationTokenSource は破棄する(.NET 6+ は `WaitAsync` も可)。非同期初期化はコンストラクタで行わず静的ファクトリ / 明示的 Initialize で行う。参考: [AsyncGuidance (davidfowl/AspNetCoreDiagnosticScenarios)](https://github.com/davidfowl/AspNetCoreDiagnosticScenarios/blob/master/AsyncGuidance.md) | — |
| guideline-3 | HTTP クライアント | **`new HttpClient()` を書かず `IHttpClientFactory` の named client を使う**(名前は `ApiNames` 定数に集約)。プライマリハンドラは `SocketsHttpHandler` + **`PooledConnectionLifetime`**(DNS 追従)。認証・共通ヘッダは `DelegatingHandler`(Transient 登録)、接続先・トークンは `ApiContext`(Singleton)に一元化。シリアライズは REST クライアント抽象(Rester)に寄せ `HttpContent` を手組みしない。URL は定数集約(サーバ側 ApiRoutes と対応)。失敗は結果で受けて分岐(guideline-1)。template-spec からの逆輸入(2026-08) | — |

## 2. 決定事項

1. **Program.cs** — `ConfigureXxx()` 宣言列挙 + `ApplicationExtensions.cs` 集約方式を基本とする (host-1)
2. **API 方式** — Minimal API を優先する (web-1)
3. **API 契約** — JSON は camelCase、DTO は `*Request`/`*Response` サフィックス、トップ階層は配列を返さず必ずクラスで包む (web-3)
4. **テスト記述** — AAA パターンを規約とする (test-1)
5. **テスト基盤** — xunit.v3 + Microsoft.Testing.Platform を正とする (test-2)
6. **名前空間** — `Accessors`(複数形)に統一 (namespace-1)
7. **Components** — Blazor 標準ルールを優先(UI コンポーネントの置き場) (namespace-3)
8. **Blazor の State** — ページの private フィールド保持を基本とする (blazor-5)
9. **設定クラスの配置** — アプリ設定は `Settings/` 配下、コンポーネント固有設定はコンポーネントと同居 (config-4)
10. **テレメトリ設定** — 環境変数から取得する (telemetry-1)
11. **Analyzers.ruleset** — 共通化を基本とし、CA2007 のような層依存の規則は GlobalSuppressions でプロジェクト単位に無効化する (structure-3, structure-4)
12. **インフラ部品の置き場** — `Infrastructure` を優先。`Application` は「アプリ固有の共通部品」用 (namespace-2, namespace-3)
13. **UI ライブラリ** — プロジェクト固有の選定とし、共通要件では規定しない (blazor-9)
14. **ログの Timestamp** — 時刻のみ(`HH:mm:ss.fff`)、日付は含めない (log-3)
15. **モックの名前空間** — `Mocks` (test-4)
16. **Aspire** — Web の標準構成に含める。ServiceDefaults プロジェクトは作らず、相当機能はアプリ側/(複数プロジェクト構成では)基盤層プロジェクトへ (solution-2, solution-3)
17. **Usecase** — `Services` と同じ階層の独立名前空間とする (namespace-1, namespace-6)
18. **クライアント側の Components** — プラットフォーム機能ラッパとしてそのまま維持 (namespace-7)
19. **画面遷移** — 画面遷移を持つアプリはプラットフォームを問わず Smart.Navigation を使用。ツール的な子ウィンドウ管理は WindowManager (mvvm-2, wpf-1)
20. **TCP サービス** — Kestrel `ConnectionHandler` で構築する (network-1)
21. **サービス化 API** — `builder.Services.AddWindowsService().AddSystemd()`(現行 .NET の推奨形式)に統一 (deploy-1)
22. **テストプロジェクト構成** — UnitTests + IntegrationTests(+任意 E2E/UITests)を一般方針とする。4分割は大規模向けの発展形 (test-8)
23. **メンバ記述順序** — razor.cs の節コメント固定順は規約にせず、汎用のメンバ記述順序ガイドラインを別途作成する (blazor-4, structure-7)
24. **.editorconfig** — 統一する(本リポジトリ版を正典として管理) (structure-6)
25. **AAA コメントの運用** — AAA コメントは区切り行として使用し、処理内容に関する和文コメントは区切りとは別に記述する (test-1)
26. **Modules 構成** — 多数の画面を用意しナビゲーションを行うアプリは `Modules/<機能>` に View と ViewModel を機能単位で配置(MVVM のルール) (mvvm-5)
27. **横断ガイドの作成** — エラー処理方針・非同期作法・メンバ記述順序のガイドを作成する (guideline-1, guideline-2, structure-7)
28. **メンバ記述順序** — structure-7 の順序(定数 → フィールド → イベント → プロパティ → コンストラクタ → ライフサイクル → メソッド群は処理の種類単位グルーピング優先 → ネスト型)を承認 (structure-7)
29. **テスト名** — 「対象メソッド + シナリオ + 期待結果」の3部構成をアンダースコアなしの PascalCase で連結する(例: `DailyAuthorizeFailedReturns403`) (test-3)
30. **層・プラットフォーム依存の CA ルール** — CA1303 / CA1305 / CA1416 は共通 ruleset に含めない(CA2007 と同様に決定11の三層方針へ帰着)。必要になったプロジェクトで GlobalSuppressions によるプロジェクト単位の抑止を再検討する(既存実績: CA1305 / CA1416 はクライアント系で多数、CA1303 は少数) (structure-3, structure-4)

## 3. 主要な残論点

なし(全項目決定済み。ドキュメント執筆に着手可能)

## 4. ドキュメント構成案

分類タグ = フォルダ、トピック = 1ファイル(順序は README の索引で制御):

```
README.md                 … 索引(分類毎の目次)
docs/
  structure/  solution/   namespace/   host/       deploy/
  log/        config/     data/        web/        blazor/
  mvvm/       wpf/        avalonia/    maui/       worker/
  network/    test/       telemetry/   generator/  guideline/
```

各ドキュメントの標準フォーマット案: **目的 → 標準形(コード例) → 配置ルール(名前空間/ファイル) → バリエーションと使い分け → アンチパターン**。

## 5. 注意事項

- コード例は固有名詞を汎用名に置換し、接続文字列・鍵などの値は必ずダミー化して掲載する
