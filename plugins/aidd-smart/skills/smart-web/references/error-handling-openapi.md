# エラー応答と OpenAPI

| 項目 | 内容 |
|---|---|
| ID | web-6 |
| 分類 | web |
| 関連 | web-1(Minimal API) / web-3(API 契約) / web-4(gRPC) / host-1(Program.cs の構成) / guideline-1(エラー処理方針) / telemetry-3(公開エンドポイントの保護) |

## 目的

API のエラー応答を RFC 7807(Problem Details)に統一し、OpenAPI 仕様を実装から自動生成する。

- **予期できる異常は例外ではなく `IResult` で応答する**(guideline-1 のエラー処理方針の Web 適用)
- **予期せぬ例外はグローバルに 1 箇所で処理**し、クライアントには定型の ProblemDetails、サーバログには詳細を残す
- OpenAPI は .NET 内蔵の `AddOpenApi()` / `MapOpenApi()` で「現状仕様」を生成し、手書きの仕様書と実装の乖離を作らない

## 標準形

### 予期できる異常は IResult で応答

ハンドラは業務上あり得る失敗(未存在・重複・不正パス等)を例外にせず、`TypedResults` で HTTP ステータスに変換する(web-1)。

```csharp
private static async ValueTask<IResult> HandleCreateAsync(
    DataService dataService,
    DataCreateRequest request)
{
    var id = await dataService.InsertAsync(request.Name, request.Value);
    return id.HasValue
        ? TypedResults.Created($"{ApiRoutes.Data}/{id.Value}", new DataCreateResponse(id.Value))
        : TypedResults.Problem(statusCode: StatusCodes.Status409Conflict, title: "Duplicate name.");
}
```

エラー本文も `TypedResults.Problem(...)` で生成し、独自のエラー JSON 形式を作らない。

### ProblemDetails + グローバル例外ハンドラ

予期せぬ例外は各ハンドラで握らず、`AddProblemDetails()` + `IExceptionHandler` + `UseExceptionHandler()` の 1 箇所で処理する。構成は `ApplicationExtensions.ConfigureApi()` / `UseErrorHandler()` に置く(host-1)。

```csharp
public static IHostApplicationBuilder ConfigureApi(this IHostApplicationBuilder builder)
{
    // Error handler
    builder.Services.AddProblemDetails(static options =>
    {
        options.CustomizeProblemDetails = static context =>
        {
            context.ProblemDetails.Extensions.TryAdd("traceId", Activity.Current?.Id ?? context.HttpContext.TraceIdentifier);
        };
    });
    builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

    return builder;
}

public static WebApplication UseErrorHandler(this WebApplication app)
{
    app.UseExceptionHandler();

    return app;
}
```

`GlobalExceptionHandler` はログ出力と定型応答のみを行う。例外の詳細(型・メッセージ・スタックトレース)はクライアントへ返さない。読めない本文(壊れた JSON・型違い)は Development では `ThrowOnBadRequest` の既定で、本文の上限超過(アップロード)はどの環境でも `BadHttpRequestException` になるので、500 にせず例外のステータス(400 / 413 など)で返し、エラーとしてログに出さない。

```csharp
public sealed class GlobalExceptionHandler : IExceptionHandler
{
    private readonly IProblemDetailsService problemDetailsService;

    private readonly ILogger<GlobalExceptionHandler> logger;

    public GlobalExceptionHandler(
        IProblemDetailsService problemDetailsService,
        ILogger<GlobalExceptionHandler> logger)
    {
        this.problemDetailsService = problemDetailsService;
        this.logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        if (exception is BadHttpRequestException badRequest)
        {
            httpContext.Response.StatusCode = badRequest.StatusCode;

            return await problemDetailsService.TryWriteAsync(new ProblemDetailsContext
            {
                HttpContext = httpContext,
                Exception = exception,
                ProblemDetails = new ProblemDetails
                {
                    Status = badRequest.StatusCode
                }
            });
        }

        logger.ErrorUnhandledException(exception);

        httpContext.Response.StatusCode = StatusCodes.Status500InternalServerError;

        return await problemDetailsService.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = httpContext,
            Exception = exception,
            ProblemDetails = new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "An unexpected error occurred."
            }
        });
    }
}
```

### 既知の例外境界は EndpointFilter で変換

ライブラリが例外で通知するもの(guideline-1: DB 一意制約、外部 I/O 等)のうちリソース単位で共通のものは、エンドポイントフィルタで ProblemDetails に変換し、グループに掛ける。

```csharp
public sealed class StorageExceptionFilter : IEndpointFilter
{
    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        try
        {
            return await next(context);
        }
        catch (StorageException)
        {
            return TypedResults.Problem(statusCode: StatusCodes.Status400BadRequest, title: "Invalid path.");
        }
    }
}
```

### OpenAPI(.NET 内蔵)

OpenAPI は `AddOpenApi()`(.NET 10 内蔵)で生成し、ドキュメント情報は DocumentTransformer で与える。

```csharp
public static IHostApplicationBuilder ConfigureOpenApi(this IHostApplicationBuilder builder)
{
    builder.Services.AddOpenApi(static options =>
    {
        options.AddDocumentTransformer(static (document, context, cancellationToken) =>
        {
            document.Info.Title = "Template API";
            document.Info.Version = "v1";
            document.Info.Description = "Template API server.";
            return Task.CompletedTask;
        });
    });

    return builder;
}
```

### エンドポイントの記述(WithName / Produces)

`IResult` を返すハンドラは応答の型が推測されないため、全エンドポイントに名前(web-3 の機能名 + 操作名)と実際に返す応答を宣言する。全 API に共通の応答はグループに付ける。

```csharp
public static RouteGroupBuilder MapApiGroup(this IEndpointRouteBuilder endpoints, string prefix) =>
    endpoints.MapGroup(prefix)
        .ProducesProblem(StatusCodes.Status429TooManyRequests)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

var group = app.MapApiGroup(ApiRoutes.Data)
    .RequireAuthorization()
    .ProducesProblem(StatusCodes.Status401Unauthorized);

group.MapGet("/{id:long}", HandleGetAsync)
    .WithName("DataGet")
    .Produces<DataGetResponse>()
    .ProducesProblem(StatusCodes.Status404NotFound);
group.MapPost("/", HandleCreateAsync)
    .WithName("DataCreate")
    .Produces<DataCreateResponse>(StatusCodes.Status201Created)
    .ProducesValidationProblem()
    .ProducesProblem(StatusCodes.Status409Conflict);
group.MapDelete("/{id:long}", HandleDeleteAsync)
    .RequireAuthorization(Policies.Administrator)
    .WithName("DataDelete")
    .Produces(StatusCodes.Status204NoContent)
    .ProducesProblem(StatusCodes.Status403Forbidden)
    .ProducesProblem(StatusCodes.Status404NotFound);
```

- 全 API に共通の応答(500、レート制限の 429)は `MapApiGroup`、認証の 401 は認証を掛けたグループ、管理者だけの 403 などはエンドポイントに付ける
- 本文が ProblemDetails の応答は `ProducesProblem` / `ProducesValidationProblem` で書く。`UseStatusCodePages` を使わない構成で本文の無い 401 / 404 などは `Produces(StatusCodes.Status404NotFound)` で書き、グループには `WithMetadata(new ProducesResponseTypeMetadata(StatusCodes.Status401Unauthorized, typeof(void)))` で付ける(非汎用の `Produces` はグループに付かず、型を省くと文書に出ない)
- ファイルの応答は `Produces<Stream>(StatusCodes.Status200OK, "application/octet-stream")` で書く(型を省くと content type が文書から落ちる)
- 1 つのステータスには 1 つの形しか載らない(同じステータスに別の型を宣言すると後の宣言で上書きされる)
- `WithRequestTimeout` は汎用でない型を返すので、`Produces<T>` より後ろに書く
- `WithName` の名前はアプリ全体で一意にする。版ごとに別のハンドラを登録するときは名前に版を付ける

公開は Development のみとし、UI が必要なら生成された仕様を NSwag の Swagger UI(`NSwag.AspNetCore`)から参照する。

```csharp
public static WebApplication MapEndpoints(this WebApplication app)
{
    // Develop
    if (app.Environment.IsDevelopment())
    {
        app.MapOpenApi();

        // NSwag UI (MapOpenApi が生成した仕様を参照)
        app.UseSwaggerUi(static options =>
        {
            options.DocumentPath = "/openapi/v1.json";
        });
    }

    return app;
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| `GlobalExceptionHandler` | `Infrastructure/ExceptionHandling/` |
| 例外変換の EndpointFilter | `Infrastructure/Filters/` |
| ProblemDetails / OpenAPI の構成 | `Application/ApplicationExtensions.cs`(`ConfigureApi` / `ConfigureOpenApi` / `UseErrorHandler`) |
| gRPC の例外処理 | `Infrastructure/Interceptors/ExceptionInterceptor.cs`(web-4) |

## バリエーションと使い分け

- **traceId の付与**: `CustomizeProblemDetails` で `traceId`(`Activity.Current?.Id`)を必ず拡張フィールドに載せ、クライアント報告からサーバログ・トレースを突合できるようにする
- **検証エラー**: モデルバインド・検証属性(web-3)による 400 応答はフレームワークの ValidationProblem(ProblemDetails 互換)に任せ、自前で整形しない
- **OpenAPI を本番でも公開する場合**: 無条件公開はせず、IP 制限や機能トグルで保護する(telemetry-3)
- **gRPC**: 同じ方針を Interceptor で実現する — 予期できる異常は `RpcException` + `StatusCode`、予期せぬ例外は `ExceptionInterceptor` で `Internal` に変換(web-4)

## アンチパターン

- **例外による業務フロー制御** — 未存在・重複のような予期できる結果を例外で表現しない。Service は結果(null / ステータス enum)を返し、ハンドラが `IResult` に変換する(guideline-1)
- **ハンドラ毎の try/catch 散在** — 予期せぬ例外を各所で握るとログの重複・応答形式の揺れが生じる。グローバルハンドラに一本化する
- **独自エラー JSON** — `{ "error": "..." }` のような独自形式を作らない。エラー応答は常に ProblemDetails(RFC 7807)
- **例外詳細のクライアント露出** — スタックトレースや例外メッセージを応答に含めない。詳細はサーバログ、クライアントには traceId のみ渡す
- **手書き OpenAPI 仕様の並走** — 実装と乖離した YAML を別管理しない。仕様は `AddOpenApi()` による生成物を正とする
