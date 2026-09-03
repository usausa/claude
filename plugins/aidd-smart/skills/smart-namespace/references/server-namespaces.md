# サーバ側の標準名前空間

| 項目 | 内容 |
|---|---|
| ID | namespace-1 |
| 分類 | namespace |
| 関連 | namespace-2(Application) / namespace-3(Components・Infrastructure) / namespace-4(Domain) / namespace-5(モデルサフィックス) / namespace-6(Usecase) / namespace-7(クライアント側) / web-1(Endpoints) / config-4(設定クラスの配置) / host-1(ApplicationExtensions) / solution-1(プロジェクト分割) |

## 目的

サーバ系プロジェクト(Web API / Blazor Server / バッチ・常駐サービス)で使用する名前空間の標準語彙を定義する。namespace 分類の入口となる総覧であり、個別の作法は各トピック(namespace-2〜6)に委ねる。

- 「どの名前空間に何を置くか」を全プロジェクトで一定にし、初見でも目的のコードに到達できるようにする
- フォルダ=名前空間とし、レイヤ構造を物理配置にそのまま写す
- 置き場に迷ったら語彙表の「置くもの/置かないもの」で判定する

## 標準形

### フォルダツリー

ホストプロジェクト直下の標準構成。使わない名前空間のフォルダは作らない(空フォルダを予約しない)。

```
Template.Server/
├─ Accessors/            # データアクセサ定義(Sql/ に 2-way SQL)
│  └─ Sql/
├─ Application/          # アプリ固有の共通部品(namespace-2)
├─ Contexts/             # リクエストスコープの横断状態
├─ Domain/               # 業務知識(namespace-4)
│  ├─ Code/
│  └─ Logic/
├─ Endpoints/            # Minimal API エンドポイント(web-1)
├─ Helpers/              # 純粋関数ヘルパ
├─ Infrastructure/       # アプリ非依存のインフラ部品(namespace-3)
├─ Models/               # データモデル(namespace-5)
│  ├─ Entity/
│  ├─ View/
│  └─ Parameter/
├─ Providers/            # 環境依存値の供給点
├─ Services/             # 業務サービス
├─ Settings/             # アプリ設定クラス(config-4)
├─ State/                # プロセス内共有の可変状態
├─ Usecase/              # 業務フロー(namespace-6)
├─ Workers/              # 常駐・周期処理
└─ Program.cs
```

### 語彙表

| 名前空間 | 置くもの / 置かないもの | 代表クラス |
|---|---|---|
| `Accessors` | 置く: `[DataAccessor]` インターフェース(実装はジェネレータ、data-1)と `Sql/` の 2-way SQL(data-2)。置かない: 業務判断(Service へ) | `IUserAccessor` |
| `Models` | 置く: `Entity` / `View` / `Parameter` のデータモデル(namespace-5)。置かない: 振る舞い(判定は Domain へ) | `UserEntity` / `UserSummaryView` |
| `Services` | 置く: DB・通信などプリミティブな I/O 操作単位の業務サービス。置かない: 複数 Service を束ねるフロー(Usecase へ) | `UserService` |
| `Usecase` | 置く: 一連の業務フロー・外部 SDK 操作の唯一の入口(namespace-6)。**`Services` と同階層の独立名前空間とする(決定)** | `OrderUsecase` |
| `Domain` | 置く: `Code`(コード値定数)と `Logic`(純粋ロジック)、桁数の `Length`(namespace-4)。置かない: I/O・他レイヤ参照 | `AlertLevel` / `Length` |
| `Settings` | 置く: `<セクション>Setting`(config-1)。置かない: コンポーネント付属の `*Options`(コンポーネントと同居、config-4) | `ServerSetting` |
| `Application` | 置く: アプリ固有の共通部品(namespace-2)。置かない: アプリ非依存の汎用部品(Infrastructure へ) | `ApplicationExtensions` / `FeatureFlags` |
| `Infrastructure` | 置く: アプリ非依存のインフラ部品を機能単位の4点セットで(namespace-3) | `IStorage` / `FileStorage` |
| `Providers` | 置く: 時刻・乱数・ID 採番など環境依存値の供給点となる抽象と実装。テストで固定実装に差し替える(test-6) | `ITimeProvider` |
| `Contexts` | 置く: リクエストスコープで引き回す横断状態(`AsyncLocal` ベース、web-5) | `SessionContext` / `LoggingContext` |
| `Workers` | 置く: `BackgroundService` 派生の常駐・周期処理(worker-1)。置かない: 業務処理の実体(Service / Usecase へ委譲) | `ActionWorker` / `DataCollectWorker` |
| `Helpers` | 置く: 状態を持たない純粋関数の static クラス。置かない: I/O を伴う処理(Service / Infrastructure へ) | `SqlHelper` / `ImageHelper` |
| `State` | 置く: プロセス内で共有する可変シングルトン状態 | `HealthCheckState`(telemetry-2) |
| `Endpoints` | 置く: Minimal API の `Map<Name>Endpoints` 拡張(web-1)。置かない: 業務処理(Service / Usecase へ委譲) | `UserEndpoints` |

ログメッセージ定義の `Log.cs` は特定の名前空間に集約せず、名前空間(フォルダ)毎に分割配置する(log-1)。

## 配置ルール

| 対象 | 場所 |
|---|---|
| 単一プロジェクト構成 | 全名前空間をホストプロジェクト直下に配置(フォルダ=名前空間) |
| Core 分離構成(solution-1) | 業務層(`Accessors` / `Models` / `Domain` / `Services` / `Usecase`)を `<App>.Core` へ。RootNamespace は短縮する(`Template.Core` → `Template`) |
| ホスト固有 | `Application` / `Settings` / `Endpoints` / `Workers` / `Contexts` はホストプロジェクト側 |
| アプリ非依存の基盤部品 | 部品が育ったら基盤層プロジェクトへ分離(solution-3 / solution-4) |

## バリエーションと使い分け

- 最小構成は `Accessors` / `Models` / `Services` / `Settings` / `Application` から始め、必要になった時点で語彙を追加する
- **Blazor Server**: 上記に加えて `Components` / `Pages` / `Shared` の Blazor 標準構成を併用する(namespace-3)
- **gRPC**: `Api`(Protos / Handlers)を追加する(web-4)
- **バッチ・CLI**: `Endpoints` の代わりに `Workers`(worker-1)が主役になる。語彙は同一
- `State` と `Contexts` の使い分け: プロセス全体で共有する状態=`State`、リクエスト単位の状態=`Contexts`
- クライアント側は共通語彙(`Services` / `Usecase` / `State` / `Helpers` / `Models` / `Domain`)に加えてクライアント固有語彙を使う(namespace-7)

## アンチパターン

- **単数形と複数形の揺れ** — `Accessors`(複数形)に統一する(決定)。`Accessor` は使わない
- `Common` / `Utils` / `Misc` のような役割を定義しないゴミ箱名前空間を作る
- フォルダと名前空間の不一致 — 移動・改名時に必ず両方を揃える
- Service への一極集中 — フロー・複数 Service の束ね・SDK 操作が現れたら `Usecase` に切り出す(namespace-6)
- 語彙にない名前空間を1プロジェクトだけで私設する — 必要なら語彙自体を拡張し、全プロジェクトで共有する
