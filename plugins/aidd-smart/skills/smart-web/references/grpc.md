# gRPC サービス構成

| 項目 | 内容 |
|---|---|
| ID | web-4 |
| 分類 | web |
| 関連 | web-1(Minimal API) / web-6(エラー応答・OpenAPI) / namespace-1(サーバ側名前空間) / host-1(Program.cs の構成) / telemetry-2(HealthChecks) / guideline-1(エラー処理方針) |

## 目的

gRPC サービスは `Api/Protos/*.proto` + `Api/Handlers/<Name>Handler` の構成で統一する。

- 契約(proto)と実装(Handler)を `Api` 配下に近接配置し、サービス定義の全体を 1 フォルダで把握できる
- Handler は HTTP API のハンドラ(web-1)と同じく極薄とし、実処理は Service / Usecase へ委譲する
- Reflection は Development のみ有効化し、HealthChecks を必ず併設する

## 標準形

### proto 定義

`Api/Protos/<name>.proto` に置き、`csharp_namespace` をホストプロジェクトに合わせる。RPC の種類(Unary / streaming)をコメントで区分する。

```proto
syntax = "proto3";

import "google/protobuf/timestamp.proto";

option csharp_namespace = "Template.Server";

package data;

service Data {
  // Unary
  rpc GetData (GetDataRequest) returns (DataItem);
  rpc SetData (SetDataRequest) returns (SetDataReply);
  // Server streaming
  rpc ListData (ListDataRequest) returns (stream DataItem);
  // Client streaming
  rpc UploadData (stream SetDataRequest) returns (UploadDataReply);
}

message GetDataRequest {
  int64 id = 1;
}

message DataItem {
  int64 id = 1;
  string name = 2;
  int32 value = 3;
  google.protobuf.Timestamp created_at = 4;
}
```

### Handler

`Api/Handlers/<Name>Handler.cs` に生成基底クラス(`<Service>Base`)の継承として実装する。RPC 種別毎に罫線コメントでセクション化し、proto 型との詰め替えは `Helper` セクションに寄せる。

```csharp
namespace Template.Server.Api.Handlers;

using Google.Protobuf.WellKnownTypes;

using Grpc.Core;

public sealed class DataHandler : Data.DataBase
{
    private readonly DataService dataService;

    public DataHandler(DataService dataService)
    {
        this.dataService = dataService;
    }

    //--------------------------------------------------------------------------------
    // Unary
    //--------------------------------------------------------------------------------

    public override async Task<DataItem> GetData(GetDataRequest request, ServerCallContext context)
    {
        var entity = await dataService.QueryAsync(request.Id);
        if (entity is null)
        {
            throw new RpcException(new Status(StatusCode.NotFound, "Data not found."));
        }

        return MapToItem(entity);
    }

    //--------------------------------------------------------------------------------
    // Server streaming
    //--------------------------------------------------------------------------------

    public override async Task ListData(ListDataRequest request, IServerStreamWriter<DataItem> responseStream, ServerCallContext context)
    {
        var list = await dataService.QueryListAsync(String.IsNullOrEmpty(request.Name) ? null : request.Name);
        foreach (var entity in list)
        {
            await responseStream.WriteAsync(MapToItem(entity), context.CancellationToken);
        }
    }

    //--------------------------------------------------------------------------------
    // Helper
    //--------------------------------------------------------------------------------

    private static DataItem MapToItem(DataEntity entity) => new()
    {
        Id = entity.Id,
        Name = entity.Name,
        Value = entity.Value,
        CreatedAt = Timestamp.FromDateTime(DateTime.SpecifyKind(entity.CreatedAt, DateTimeKind.Utc))
    };
}
```

- 予期できる異常(未存在・重複・引数不正)は `RpcException` + 適切な `StatusCode`(`NotFound` / `AlreadyExists` / `InvalidArgument`)で応答する
- ストリーミングの読み書きには必ず `context.CancellationToken` を渡す(guideline-2)

### ApplicationExtensions への組み込み

gRPC の構成は `ConfigureGrpc()` として `ApplicationExtensions.cs` に集約する(host-1)。予期せぬ例外は Interceptor でグローバル処理する(web-6 の gRPC 版)。

```csharp
public static IHostApplicationBuilder ConfigureGrpc(this IHostApplicationBuilder builder)
{
    // gRPC
    builder.Services.AddGrpc(static options =>
    {
        options.Interceptors.Add<ExceptionInterceptor>();
        options.Interceptors.Add<LoggingInterceptor>();
    });

    // gRPC Reflection
    if (builder.Environment.IsDevelopment())
    {
        builder.Services.AddGrpcReflection();
    }

    // gRPC Health
    builder.Services.AddGrpcHealthChecks()
        .AddCheck("self", static () => HealthCheckResult.Healthy())
        .AddCheck<DatabaseHealthCheck>("database");

    return builder;
}

public static WebApplication MapEndpoints(this WebApplication app)
{
    // gRPC
    app.MapGrpcService<DataHandler>().RequireAuthorization();
    app.MapGrpcHealthChecksService();
    if (app.Environment.IsDevelopment())
    {
        app.MapGrpcReflectionService();
    }

    return app;
}
```

`ExceptionInterceptor` は RPC 種別 4 つ(Unary / ServerStreaming / ClientStreaming / Duplex)の継続をそれぞれ try で包み、`RpcException` はそのまま再スロー、それ以外はログ出力の上で `StatusCode.Internal` の `RpcException` に変換する(詳細を漏らさない)。

## 配置ルール

| 対象 | 場所 |
|---|---|
| proto 定義 | `Api/Protos/<name>.proto` |
| Handler | `Api/Handlers/<Name>Handler.cs` |
| Interceptor(例外・ログ) | `Infrastructure/Interceptors/` |
| HealthCheck 実装 | `Infrastructure/HealthChecks/` |
| 業務処理 | `Services` / `Usecase`(namespace-1。Core 分離時は Core 側) |

## バリエーションと使い分け

- **HTTP API との同居**: gRPC 主体のホストでも `app.MapGet("/", ...)` 程度の生存確認エンドポイントを持たせてよい。本格的な REST 併設が必要なら Minimal API(web-1)の作法をそのまま併用する
- **認可**: `MapGrpcService<T>().RequireAuthorization()` でサービス単位に掛ける。JWT Bearer 等の認証構成は HTTP API と共通(`ConfigureAuthentication`)
- **ストリーミングの選択**: 大量一覧は Server streaming、バルク投入は Client streaming を使い、Unary に巨大な repeated を詰めない

## アンチパターン

- **Reflection の本番有効化** — サービス定義の露出は Development のみに限定する
- **HealthChecks なしの運用** — `AddGrpcHealthChecks` + `MapGrpcHealthChecksService` を必ず併設する(Aspire / LB からの死活監視に使う)
- **Handler への業務ロジック混入** — 詰め替えと `StatusCode` 変換以外の処理が現れたら Service / Usecase へ移す
- **proto 生成型のレイヤ漏れ** — 生成型(`DataItem` 等)を Service / Core 層の引数・戻り値に使わない。境界で Entity / record に詰め替える
- **例外の素通し** — 予期せぬ例外をそのままクライアントへ伝播させない。Interceptor で `Internal` に変換し、詳細はサーバログにのみ残す
