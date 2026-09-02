# 公開エンドポイントの保護

| 項目 | 内容 |
|---|---|
| ID | telemetry-3 |
| 分類 | telemetry |
| 関連 | telemetry-1(OpenTelemetry: Prometheus) / telemetry-2(HealthChecks) / web-6(エラー応答・OpenAPI) / host-1(Program.cs の構成) / config-2(設定バインドの定型) |

## 目的

業務 API と同じポートに同居する**運用系エンドポイント(`/metrics` `/swagger` `/health` 等)を、業務トラフィックと同じ公開範囲にしない**。

- メトリクスは内部構成の情報(依存先・処理量・エラー率)を露出する。API 仕様(Swagger / OpenAPI)は攻撃の下調べ材料になる
- 保護は「環境・機能トグルで出さない」を第一とし、出す場合は「IP 制限で範囲を絞る」を重ねる

## 標準形

### 第一段: 環境・機能トグルで無効化する

開発用エンドポイントは Development 環境に限定するのが既定形(web-6)。環境と独立して制御したい場合は、設定の bool トグル(`EnableSwagger` 等)を重ねる。トグルは起動時に即時取得する(config-2 の②)。

```csharp
public static WebApplication MapEndpoints(this WebApplication app)
{
    // Develop
    var enableSwagger = app.Configuration.GetValue<bool>("Feature:EnableSwagger");
    if (app.Environment.IsDevelopment() || enableSwagger)
    {
        app.MapOpenApi();

        // NSwag UI (MapOpenApi が生成した仕様を参照)
        app.UseSwaggerUi(static options =>
        {
            options.DocumentPath = "/openapi/v1.json";
        });
    }

    // ...

    return app;
}
```

### 第二段: IP 制限(RestrictBuilder / UseWhenFrom)

公開したままにするパス(検証環境の `/swagger`、Kestrel 同居の `/metrics` 等)は、`UseWhen` によるパス分岐 + 接続元 IP 判定のミドルウェアで保護する。判定を拡張メソッドに切り出し、呼び出し側を宣言的に保つ。

```csharp
namespace App.Host.Infrastructure.Restriction;

using System.Net;

public static class RestrictExtensions
{
    public static IApplicationBuilder UseWhenFrom(this IApplicationBuilder app, PathString path, RestrictSetting setting)
    {
        // 判定はリクエスト毎に走るため、許可リストは登録時に一度だけパースする
        var networks = setting.AllowedNetworks.Select(IPNetwork.Parse).ToArray();

        app.UseWhen(
            context => context.Request.Path.StartsWithSegments(path),
            branch => branch.Use(async (context, next) =>
            {
                var remote = context.Connection.RemoteIpAddress;
                if ((remote is null) || !IsAllowed(networks, remote))
                {
                    context.Response.StatusCode = StatusCodes.Status403Forbidden;
                    return;
                }

                await next();
            }));

        return app;
    }

    private static bool IsAllowed(IPNetwork[] networks, IPAddress remote)
    {
        foreach (var network in networks)
        {
            if (network.Contains(remote))
            {
                return true;
            }
        }

        return false;
    }
}
```

`IPNetwork` は `System.Net` のもの(.NET 8+)。許可リストは設定クラスに持ち、appsettings で環境毎に与える(値は例)。ローカルホストからのアクセスは IPv6(`::1`)で届くことがあるため、IPv4 と併せて許可する。

```json
{
  "Restrict": {
    "AllowedNetworks": ["127.0.0.1/32", "::1/128", "10.0.0.0/8", "192.0.2.0/24"]
  }
}
```

```csharp
public sealed class RestrictSetting
{
    public string[] AllowedNetworks { get; set; } = default!;
}
```

呼び出し側は保護対象パス毎に列挙する。

```csharp
// Restrict
var restrictSetting = app.Configuration.GetSection("Restrict").Get<RestrictSetting>()!;
app.UseWhenFrom("/metrics", restrictSetting);
app.UseWhenFrom("/swagger", restrictSetting);
```

- リバースプロキシ配下では `UseForwardedHeaders()` の**後段**に置き、`RemoteIpAddress` が実クライアント IP に解決された状態で判定する
- 判定 NG は 403 で即時終了し、後続パイプラインに入れない

### Prometheus HttpListener の場合

`AddPrometheusHttpListener`(telemetry-1)は Kestrel と別ポート(既定 9464)で listen するため、上記のミドルウェアは通らない。この形では **URI プレフィックスの bind 先とファイアウォールで保護する**(localhost bind + 同居する収集エージェント、または内部ネットワークのみ開放)。

## 配置ルール

| 対象 | 場所 |
|---|---|
| `RestrictExtensions`(UseWhenFrom) | `Infrastructure/Restriction/`(namespace-3)。複数プロジェクト構成では基盤層(solution-3) |
| `RestrictSetting` | `Settings/`(config-4) |
| 機能トグル | 設定の `Feature` 節等の bool。起動時に即時取得(config-2) |
| 保護の宣言 | `MapEndpoints()` / パイプライン構成(host-1)に列挙 |

## バリエーションと使い分け

- **保護対象の選定**: `/metrics` `/swagger`(`/openapi`)は保護必須。`/health` は監視元(ロードバランサ等)が外部にある場合のみ許可リストへ追加する(telemetry-2)
- **ポート分離**: 運用系エンドポイントを管理用ポートに分けて listen し、ポート単位でネットワーク制御する形も取れる。Kestrel 同居 + パス保護を基本とし、要件が厳しい場合に選択する
- **認証との併用**: 社外公開の検証環境等では IP 制限に加えて Basic 認証等を重ねてよい。ただし業務側の認証基盤(web-5 / blazor-7)と混ぜない

## アンチパターン

- **本番での Swagger 無防備公開** — API 仕様・スキーマ・認証方式が丸見えになる。本番は無効化が既定、必要なら IP 制限とセットでのみ公開する
- **`/metrics` の全公開** — 内部構成とトラフィック特性が露出する。IP 制限またはネットワーク制御を必ず掛ける
- **`X-Forwarded-For` の無検証な信頼** — ForwardedHeaders の処理前に判定したり、任意のクライアントヘッダで許可判定すると、ヘッダ偽装で素通りする。信頼できるプロキシ経由の `RemoteIpAddress` で判定する
- **許可 IP のコード直書き** — 環境の差し替えがビルドになる。設定(`RestrictSetting`)に出す
- **保護しすぎによる監視不能** — `/health` まで一律に閉じてロードバランサやオーケストレータの稼働判定を壊さない。保護対象と監視経路をセットで設計する
