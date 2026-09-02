# API 方式(Minimal API)

| 項目 | 内容 |
|---|---|
| ID | web-1 |
| 分類 | web |
| 関連 | web-2(Controller + Areas) / web-3(API 契約) / web-5(認証状態管理) / web-6(エラー応答・OpenAPI) / namespace-1(Endpoints) / namespace-2(Application) / host-1(Program.cs の構成) / host-4(DI 登録スタイル) |

## 目的

Web API は **Minimal API を優先する(決定)**。エンドポイント定義を `Endpoints` 名前空間の static クラスに集約し、全プロジェクトで同じ形に揃える。

- リソース単位の 1 ファイルを見れば、ルート・認可・フィルタ・ハンドラの全体が把握できる
- ハンドラは static メソッドとし、依存は引数 DI で受ける。インスタンス状態を持たないため、テスト・レビューの単位が小さく保てる
- ルート文字列は `ApiRoutes` に定数化し、リンク生成・テストコードと定義がずれない

## 標準形

### Endpoints クラス

リソース毎に `Endpoints/<Resource>Endpoints.cs` を作り、`Map<Resource>Endpoints(this WebApplication)` 拡張メソッドでエンドポイント群を定義する。ファイル内は `Mapping` / `Handler` / `Mapper` の 3 セクションを罫線コメントで区切る。

```csharp
namespace Template.Server.Endpoints;

public static class DataEndpoints
{
    //--------------------------------------------------------------------------------
    // Mapping
    //--------------------------------------------------------------------------------

    public static void MapDataEndpoints(this WebApplication app)
    {
        var group = app.MapGroup(ApiRoutes.Data)
            .RequireAuthorization()
            .AddEndpointFilter<CredentialEndpointFilter>();

        group.MapGet("/", HandleListAsync);
        group.MapGet("/{id:long}", HandleGetAsync);
        group.MapPost("/", HandleCreateAsync);
        group.MapPut("/{id:long}", HandleUpdateAsync);
        group.MapDelete("/{id:long}", HandleDeleteAsync).RequireAuthorization(Policies.Administrator);
    }

    //--------------------------------------------------------------------------------
    // Handler
    //--------------------------------------------------------------------------------

    private static async ValueTask<IResult> HandleListAsync(
        DataUsecase dataUsecase,
        string? name,
        [Range(0, Int32.MaxValue)] int page = 0,
        [Range(1, 100)] int size = 20)
    {
        var result = await dataUsecase.QueryPageAsync(name, page, size);
        return TypedResults.Ok(new DataListResponse(
            result.Total,
            result.Page,
            result.Size,
            result.Items.Select(MapToResponse).ToList()));
    }

    private static async ValueTask<IResult> HandleGetAsync(
        DataService dataService,
        long id)
    {
        var entity = await dataService.QueryAsync(id);
        return entity is not null
            ? TypedResults.Ok(MapToResponse(entity))
            : TypedResults.NotFound();
    }

    private static async ValueTask<IResult> HandleCreateAsync(
        DataService dataService,
        DataCreateRequest request)
    {
        var id = await dataService.InsertAsync(request.Name, request.Value);
        return id.HasValue
            ? TypedResults.Created($"{ApiRoutes.Data}/{id.Value}", new DataCreateResponse(id.Value))
            : TypedResults.Problem(statusCode: StatusCodes.Status409Conflict, title: "Duplicate name.");
    }

    //--------------------------------------------------------------------------------
    // Mapper
    //--------------------------------------------------------------------------------

    private static DataResponse MapToResponse(DataEntity entity) =>
        new(entity.Id, entity.Name, entity.Value, entity.CreatedAt);
}
```

- `MapGroup("/api/<resource>")` でグルーピングし、認可(`RequireAuthorization`)・フィルタ(`AddEndpointFilter`)・レート制限(`RequireRateLimiting`)はグループに掛ける。個別エンドポイントで強める場合のみ追記する
- ハンドラは **static メソッド**とし、依存(Service / Usecase)・ルート値・クエリ・ボディをすべて引数で受ける。戻り値は `IResult`(`TypedResults` で生成)
- ハンドラは入出力の詰め替えと HTTP ステータスへの変換のみを行い、**実処理は Service / Usecase へ委譲する**。Response への詰め替えは `Mapper` セクションの private メソッドに寄せる
- 異常系はハンドラ内で例外を投げず `IResult` で応答する(web-6)

### ApiRoutes(ルート定数)

ルートのプレフィックスは `Application/ApiRoutes.cs` に定数化する。

```csharp
namespace Template.Server.Application;

public static class ApiRoutes
{
    public const string Auth = "/api/auth";

    public const string Data = "/api/data";

    public const string Files = "/api/files";
}
```

### Program への組み込み

エンドポイント登録は `ApplicationExtensions.MapEndpoints()` に集約し、`Program.cs` からは `app.MapEndpoints()` の 1 行で呼ぶ(host-1)。

```csharp
public static WebApplication MapEndpoints(this WebApplication app)
{
    // API
    app.MapAuthEndpoints();
    app.MapDataEndpoints();
    app.MapFileEndpoints();

    // Health
    app.MapHealthChecks("/health").DisableRateLimiting();

    return app;
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| エンドポイント定義 | `Endpoints/<Resource>Endpoints.cs`(namespace-1) |
| ルート定数 | `Application/ApiRoutes.cs`(namespace-2) |
| Request / Response DTO | `Models/<Resource>/`(web-3) |
| エンドポイントフィルタ | `Infrastructure/Filters/`(web-5 / web-6) |
| 認可ポリシー名定数 | `Application/Policies.cs` |

## バリエーションと使い分け

- **匿名アクセス**: 認証系エンドポイント(login 等)はグループに `RequireRateLimiting` を掛けた上で、個別に `AllowAnonymous()` を付ける
- **Mapper の独立クラス化**: 詰め替えを複数のエンドポイント・レイヤで共有する場合は、`Mapper` セクションではなく `Mappers/<Resource>Mapper.cs` の独立 static クラスへ昇格させる
- **ファイル入出力**: アップロードは `DisableAntiforgery()` + `WithRequestTimeout()`、ダウンロードは `TypedResults.Stream(...)` を使う
- **既存資産が Controller の場合**: Controller + Areas 方式(web-2)を代替として使用する。新規は Minimal API とする

## アンチパターン

- **Program.cs へのラムダ直書き** — `app.MapGet("/api/data", async (...) => ...)` をホスト起動コードに書かない。エンドポイントは必ず `Endpoints` クラスへ
- **ハンドラへの業務ロジック混入** — 条件分岐・複数 Service の束ねが現れたら Usecase(namespace-6)へ切り出す。ハンドラは詰め替えと HTTP 変換のみ
- **ルート文字列の散在** — グループ外に生文字列でルートを書くと、リンク生成やテストと不整合を起こす。プレフィックスは `ApiRoutes` に一元化する
- **インスタンスハンドラ** — ハンドラをインスタンスメソッドにしてフィールドで依存を持たない。static + 引数 DI に統一する
- **Minimal API と Controller の無方針な混在** — 1 プロジェクト内で両方式を使う場合は役割分担(web-2 の適用条件)を明確にする
