---
name: dotnet-grpc
description: gRPC サーバの実装規約
paths:
  - "**/*.proto"
  - "**/Protos/**"
  - "**/*Handler.cs"
---

# gRPC サーバ

> Web アプリケーションの中で使う想定のオプション規範 (`setup.ps1 -Include grpc` で採用)。レイヤ・ログ・データ・セキュリティは Web 全般の規範と共通で、ここは gRPC 固有のみ。

## proto とサービス実装

- proto は `Api/Protos/**` に配置し、csproj で一括登録する (`<Protobuf Include="Api\Protos\**\*.proto" GrpcServices="Server" />`)。
- `csharp_namespace` はホストのルート名前空間に合わせる。
- サービス実装は生成基底を継承した **`XxxHandler` 命名** (minimal API の Endpoints に相当する薄い層)。実処理は Service / Usecase へ委譲する。

```csharp
public sealed class GreeterHandler(GreetService service) : Greeter.GreeterBase
{
    public override async Task<HelloReply> SayHello(HelloRequest request, ServerCallContext context) =>
        new() { Message = await service.GreetAsync(request.Name) };
}

app.MapGrpcService<GreeterHandler>();
```

## ヘルス / 開発支援

- ヘルスは標準の `grpc.health.v1` を提供する: `AddGrpcHealthChecks().AddCheck(...)` + `MapGrpcHealthChecksService()`。
- リフレクション (`AddGrpcReflection` / `MapGrpcReflectionService`) は **Development 限定**で有効化する (grpcurl 等の疎通用)。
- ブラウザ疎通用に `MapGet("/", () => "gRPC Server")` の生存確認ルートを置く。

## Kestrel

- `EndpointDefaults.Protocols = Http2` を既定にする (h2c)。TLS 終端を前段 (GW / LB) に置くかは構成で明示する。

## インターセプタ

- REST の「例外 → HTTP 変換」に相当する層として、**ログ + 例外変換インターセプタ**を必ず入れる (業務検証の一括例外 → `Status.InvalidArgument` にエラーを列挙、未知例外 → `Status.Internal` + エラーログ)。ハンドラに try/catch を書かない。
- 例外 → ステータスの対応は境界ごとに 1 箇所で管理し、REST 側の HTTP 変換表 (api) と整合させる。

## クライアント側

- クライアント登録は `AddGrpcClient<T>` (named HttpClient と同じ扱い)。トレースには gRPC クライアント計装を常設してよい。
