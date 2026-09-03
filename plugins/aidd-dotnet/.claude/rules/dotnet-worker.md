---
paths:
  - "src/**"
---

<!-- managed by aidd-dotnet plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# アーキテクチャ (Worker / 常駐サービス)

> **Worker Service (Generic Host の常駐バックグラウンドサービス) 固有**。.NET 共通の規範は対象ファイルを読むと自動適用される。プロジェクト方針は プロジェクトの `.claude/rules/conventions.md` を参照。

## レイヤ (依存は上→下のみ)

```
Program.cs → Application (組み立て/DI)
                 │
                 ▼
             Worker (BackgroundService。薄く保つ)
                 │
                 ▼
             Usecase → Service → (DB / 外部通信)      Models=POCO, Domain=純粋ロジック
```

| レイヤ | 責務 |
|---|---|
| Program.cs | 合成起点。Host 構成・DI 登録。**薄く保つ** |
| Application | 起動の組み立てを Program から切り出す拡張群、共通ヘルパー |
| Worker | `BackgroundService`。実行ループ・スケジュールだけを持ち、実処理は Usecase へ委譲 |
| Usecase | 一連の流れ (取得→処理→保存 等)。ステートレス |
| Service | DB/ファイル/外部通信のプリミティブ。DI 登録。設定は注入で受ける (注入形は要件で選定) |
| Models / Domain | POCO / 純粋ロジック |

## 実行の 2 様式 (選定は `/adr`)

| | ワンショット型 | 常駐型 |
|---|---|---|
| 実行 | 外部スケジューラ (タスクスケジューラ / cron) が exe を起動 | サービスとして常駐 |
| スケジュール定義 | **アプリ外** (運用の管轄) | **アプリ内** (設定の cron 式等) |
| 成否通知 | 終了コード (成功 `0` / 失敗 `-1`) | ログ・メトリクス |
| 向き | ジョブ管理・リランを運用基盤に任せたい | 自己完結すべき / 高頻度・状態を持つ周期処理 |

- ワンショット型: 処理単位は小さなインターフェース (名前 + `ExecuteAsync`) で実装して DI に列挙登録し、実行対象は引数で選択する。**失敗は握りつぶさず伝播**させ、最外周が ExitCode に変換する。開始・終了・件数の対ログを INFO で残す。

## 実行モデル (常駐型)
- `BackgroundService.ExecuteAsync(CancellationToken)` を基本に、**CancellationToken を末端まで伝播**して graceful shutdown に応える (`dotnet-async` rule)。
- 周期実行は `PeriodicTimer` が既定。`Timer` の多重発火・処理時間超過時の重複実行に注意する。**処理時間によるドリフトを避けたい高頻度・絶対時刻同期の周期処理**は「絶対時刻 next を進めて差分 Delay」方式にする (ループ内の例外は握って継続し、1 回の失敗で常駐を殺さない)。
- cron 式の周期ジョブはジョブ抽象 (名前 + `ExecuteAsync`) + スケジューラ登録で追加し、**cron 式はコードに書かず設定から**注入する。ジョブ本体は薄く保つ (スケジュールの知識と業務処理を混ぜない)。
- DI スコープ: Worker は singleton なので、実行 1 回ごとに `IServiceScopeFactory` でスコープを切り、scoped 依存 (DbContext 等) を解決する。
- 同一ジョブの並行実行の可否 (多重起動・重複実行の制御) を設計時に決め、`/adr` に残す。

## 異常系の具体 (`dotnet-errors` rule の実装)
- 1 件の処理失敗でループ全体を止めない (件単位で捕捉してログ + 継続)。**継続不能な異常は Fail-fast** で落とし、再起動 (SCM / systemd / オーケストレータ) に任せる。
- リトライ・バックオフは要件で設計する (Polly 等)。

## ログの具体 (`dotnet-logging` rule の実装)
- 選定したロガーでファイル / コンソールへ。運用先に応じて Windows イベントログ / journald。
- 周期ジョブは開始・終了・処理件数を INFO で対にして残す (無音で動く常駐の可観測性)。

## 観測性の具体 (`dotnet-logging` rule の計装節の実装)
- 自動計装とエクスポートの構成は起動の組み立て側が担保する。機能側で足すのは業務単位のスパン (ジョブ 1 回) と業務量のメトリクス (処理件数・失敗数) だけ。

## データの具体 (`dotnet-data` rule の実装)
- ORM / データアクセス方式は用途で選定 (`dotnet-data` rule)。接続文字列は `appsettings` / 環境変数。

## セキュリティの具体 (`dotnet-security` rule の実装)
- 実行アカウントは最小権限 (専用アカウント / gMSA、コンテナは非 root)。
- 秘匿値は環境変数 / user-secrets / Key Vault 等 (平文の `appsettings` に置かない)。

## ホスティング / 配置
- Windows Service (`builder.Services.AddWindowsService()`) / systemd (`AddSystemd()`) / コンテナのいずれか。要件で選定し `/adr` に残す。
  - `HostApplicationBuilder` (`Host.CreateApplicationBuilder`) では `IServiceCollection` 側の `AddXxx` を使う (`UseWindowsService()` / `UseSystemd()` は旧 `IHostBuilder` 用)。パッケージは `Microsoft.Extensions.Hosting.WindowsServices` / `.Systemd`。
- 停止要求 (SCM / SIGTERM) の猶予時間内に終える graceful shutdown を実装する。
