# アーキテクチャ (Worker / 常駐サービス) 【Worker 形態で採用】

> **Worker Service(Generic Host の常駐バックグラウンドサービス)固有**。.NET 共通は [`common/`](common/)、プロジェクト方針は [`conventions.md`](conventions.md) を参照。

## 🧱 レイヤ (依存は上→下のみ)

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

## 🔄 実行モデル
- `BackgroundService.ExecuteAsync(CancellationToken)` を基本に、**CancellationToken を末端まで伝播**して graceful shutdown に応える ([common/async.md](common/async.md))。
- 周期実行は `PeriodicTimer`。`Timer` の多重発火・処理時間超過時の重複実行に注意する。
- DI スコープ: Worker は singleton なので、実行 1 回ごとに `IServiceScopeFactory` でスコープを切り、scoped 依存 (DbContext 等) を解決する。
- 同一ジョブの並行実行の可否 (多重起動・重複実行の制御) を設計時に決め、`/adr` に残す。

## 🛑 異常系の具体 ([common/errors.md](common/errors.md) の実装)
- 1 件の処理失敗でループ全体を止めない (件単位で捕捉してログ + 継続)。**継続不能な異常は Fail-fast** で落とし、再起動 (SCM / systemd / オーケストレータ) に任せる。
- リトライ・バックオフは要件で設計する (Polly 等)。

## 🪵 ログの具体 ([common/logging.md](common/logging.md) の実装)
- Serilog 等でファイル / コンソールへ。運用先に応じて Windows イベントログ / journald。
- 周期ジョブは開始・終了・処理件数を INFO で対にして残す (無音で動く常駐の可観測性)。

## 💾 データの具体 ([common/data.md](common/data.md) の実装)
- ORM / データアクセス方式は用途で選定 ([common/data.md](common/data.md))。接続文字列は `appsettings` / 環境変数。

## 🔐 セキュリティの具体 ([common/security.md](common/security.md) の実装)
- 実行アカウントは最小権限 (専用アカウント / gMSA、コンテナは非 root)。
- 秘匿値は環境変数 / user-secrets / Key Vault 等 (平文の `appsettings` に置かない)。

## 📦 ホスティング / 配置
- Windows Service (`builder.Services.AddWindowsService()`) / systemd (`AddSystemd()`) / コンテナのいずれか。要件で選定し `/adr` に残す。
  - `HostApplicationBuilder` (`Host.CreateApplicationBuilder`) では `IServiceCollection` 側の `AddXxx` を使う (`UseWindowsService()` / `UseSystemd()` は旧 `IHostBuilder` 用)。パッケージは `Microsoft.Extensions.Hosting.WindowsServices` / `.Systemd`。
- 停止要求 (SCM / SIGTERM) の猶予時間内に終える graceful shutdown を実装する。
