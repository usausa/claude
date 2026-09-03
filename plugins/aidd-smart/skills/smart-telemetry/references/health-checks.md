# HealthChecks

| 項目 | 内容 |
|---|---|
| ID | telemetry-2 |
| 分類 | telemetry |
| 関連 | telemetry-1(OpenTelemetry) / telemetry-3(公開エンドポイントの保護) / solution-2(Aspire AppHost: WithHttpHealthCheck) / host-1(Program.cs の構成) / web-4(gRPC) / guideline-1(エラー処理方針) |

## 目的

死活監視の口を**標準の HealthChecks 基盤に一本化**し、ホスト形態(Web / gRPC / 非 Web 常駐)ごとの公開方法を固定する。

- 監視系(ロードバランサ・systemd/コンテナオーケストレータ・Aspire ダッシュボード)からの稼働判定を、アプリ間で同じ URL・同じ意味論で提供する
- 依存先(DB 等)の疎通確認をチェッククラスに分離し、`ConfigureHealth()` は登録の列挙に保つ

## 標準形

### 登録 — ConfigureHealth()

self チェック(`live` タグ)と依存先チェックを登録する。

```csharp
public static IHostApplicationBuilder ConfigureHealth(this IHostApplicationBuilder builder)
{
    builder.Services
        .AddHealthChecks()
        .AddCheck("self", static () => HealthCheckResult.Healthy(), ["live"])
        .AddCheck<DatabaseHealthCheck>("database");

    return builder;
}
```

### エンドポイント — /health と /alive

`MapEndpoints()`(host-1)で2系統を公開する。レートリミッタを併用するアプリでは監視ポーリングが 429 にならないよう除外する。

```csharp
// Health
app.MapHealthChecks("/health").DisableRateLimiting();
app.MapHealthChecks("/alive", new HealthCheckOptions
{
    Predicate = static r => r.Tags.Contains("live")
}).DisableRateLimiting();
```

| エンドポイント | 意味 | 用途 |
|---|---|---|
| `/health` | 全チェック(依存先込み)の総合判定 | readiness。トラフィックを流してよいか |
| `/alive` | `live` タグ(self)のみ | liveness。プロセスの生死。依存先障害で再起動させない |

### 依存先チェックの実装

チェックは `IHealthCheck` 実装クラスに分離する。**失敗は例外を漏らさず `HealthCheckResult` で返す**(guideline-1 の「結果で通知する」と同じ方針)。

```csharp
namespace App.Host.Infrastructure.HealthChecks;

using Microsoft.Extensions.Diagnostics.HealthChecks;

public sealed class DatabaseHealthCheck : IHealthCheck
{
    private readonly IDbProvider dbProvider;

    public DatabaseHealthCheck(IDbProvider dbProvider)
    {
        this.dbProvider = dbProvider;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            await using var con = dbProvider.CreateConnection();
            await con.OpenAsync(cancellationToken);

            await using var command = con.CreateCommand();
            command.CommandText = "SELECT 1";
            await command.ExecuteScalarAsync(cancellationToken);

            return HealthCheckResult.Healthy();
        }
        catch (DbException e)
        {
            return HealthCheckResult.Unhealthy("Database connection failed.", e);
        }
    }
}
```

### 非 Web 常駐 — IHealthCheckPublisher で状態を吸い上げる

HTTP を持たないサービス(TCP サーバ・Worker)では、`IHealthCheckPublisher` で定期実行の結果を **`HealthCheckState` シングルトンに吸い上げ**、独自プロトコルのコマンド等から参照する。

```csharp
public sealed class HealthCheckState
{
    private readonly Lock sync = new();

    public HealthStatus HealthStatus
    {
        get { lock (sync) { return field; } }
        set { lock (sync) { field = value; } }
    }
}

public sealed class HealthCheckPublisher : IHealthCheckPublisher
{
    private readonly HealthCheckState healthState;

    public HealthCheckPublisher(HealthCheckState healthState)
    {
        this.healthState = healthState;
    }

    public Task PublishAsync(HealthReport report, CancellationToken cancellationToken)
    {
        healthState.HealthStatus = report.Status;
        return Task.CompletedTask;
    }
}
```

登録と実行周期の設定:

```csharp
// Health
builder.Services
    .AddHealthChecks()
    .AddCheck("self", static () => HealthCheckResult.Healthy());
builder.Services.AddSingleton<IHealthCheckPublisher, HealthCheckPublisher>();
builder.Services.AddSingleton<HealthCheckState>();
builder.Services.Configure<HealthCheckPublisherOptions>(static options =>
{
    options.Delay = TimeSpan.FromSeconds(5);
    options.Period = TimeSpan.FromSeconds(15);
});
```

### Aspire との接続

Aspire AppHost は `WithHttpHealthCheck("/health")` でアプリの `/health` をダッシュボードの稼働判定に接続する(solution-2)。アプリ側は本トピックの標準形のままでよい。

## 配置ルール

| 対象 | 場所 |
|---|---|
| チェック実装(`XxxHealthCheck`) | `Infrastructure/HealthChecks/`(namespace-3) |
| `HealthCheckState` / `HealthCheckPublisher` | `Application/Health/`(namespace-2) |
| 登録(`ConfigureHealth`) | `ApplicationExtensions.cs`(host-1) |
| エンドポイント | `/health` と `/alive` に固定(アプリ間で揃える) |

## バリエーションと使い分け

- **gRPC サーバ**: `AddGrpcHealthChecks()` + `MapGrpcHealthChecksService()` で gRPC 標準の Health プロトコルとして公開する(web-4)。チェック実装(self / database)は共通
- **チェックの粒度**: 依存先チェックはトラフィック受け入れの前提となるものに絞る。参照系の外部 API 等、部分縮退で動けるものは `/health` に含めず、メトリクス(telemetry-1)で監視する
- **公開範囲の制御**: `/health` を外部に出す場合は IP 制限等の保護を掛ける(telemetry-3)

## アンチパターン

- **liveness と readiness の混同** — 依存先チェック込みの `/health` を liveness に使うと、DB 障害でプロセス再起動ループに陥る。`/alive`(self のみ)を分ける
- **チェックからの例外送出** — 例外がそのまま監視側に 500 として見えるだけで情報が失われる。`HealthCheckResult.Unhealthy` に理由と例外を詰めて返す
- **重いチェック** — `/health` は高頻度で叩かれる。重い集計クエリや全依存先の直列確認を置かず、疎通確認(`SELECT 1` 相当)に留める
- **レートリミッタ・トレースへの巻き込み** — 監視ポーリングが 429 で落ちる、トレースが定常アクセスで埋まる。`DisableRateLimiting()` と収集除外(telemetry-1)を忘れない
- **アプリ独自の死活 API** — `/api/ping` のような独自実装を作らない。HealthChecks 基盤に乗せることで、タグ・Publisher・Aspire 連携がそのまま使える
