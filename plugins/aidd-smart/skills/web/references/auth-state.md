# アプリケーション固有の認証状態管理

| 項目 | 内容 |
|---|---|
| ID | web-5 |
| 分類 | web |
| 関連 | web-1(Minimal API) / web-2(Controller + Areas) / namespace-1(Contexts) / log-3(outputTemplate) / blazor-7(Cookie 認証一式) |

## 目的

フレームワークの認証(JWT / Cookie)とは別に、**アプリケーション固有に認証状態(ユーザ ID・ロール等)を管理する場合**のパターンを定義する。

- `ClaimsPrincipal` の解釈をフィルタ / Binder の 1 箇所に集約し、ハンドラや Service に `HttpContext` を引き回さない
- 横断的な状態(ログ用ユーザ ID、セッション情報)は `AsyncLocal` ベースの Context に置き、リクエストスコープで安全に参照できるようにする

## 標準形

### Credential + AsyncLocal Context

認証済みユーザの情報はアプリ固有の `Credential` record に写し、`AsyncLocal` の Context で保持する。

```csharp
namespace Template.Server.Application;

public sealed record Credential(string Id, IReadOnlyList<string> Roles);

public static class CredentialContext
{
    private static readonly AsyncLocal<Credential?> Local = new();

    public static Credential? Current
    {
        get => Local.Value;
        set => Local.Value = value;
    }
}
```

### EndpointFilter による注入(Minimal API)

`ClaimsPrincipal` から `Credential` への変換はエンドポイントフィルタに集約し、グループに掛ける(web-1)。設定は try/finally で必ずクリアする。

```csharp
namespace Template.Server.Infrastructure.Filters;

public sealed class CredentialEndpointFilter : IEndpointFilter
{
    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        // スキームごとにクレーム型が異なるため、ロールはIdentityのRoleClaimTypeで解決する
        if (context.HttpContext.User is { Identity: ClaimsIdentity { IsAuthenticated: true } identity } user)
        {
            var id = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? identity.Name ?? string.Empty;
            var roles = user.FindAll(identity.RoleClaimType).Select(static x => x.Value).ToArray();
            CredentialContext.Current = new Credential(id, roles);
        }

        try
        {
            return await next(context);
        }
        finally
        {
            CredentialContext.Current = null;
        }
    }
}
```

```csharp
var group = app.MapGroup(ApiRoutes.Data)
    .RequireAuthorization()
    .AddEndpointFilter<CredentialEndpointFilter>();
```

### ModelBinder による注入(Controller 方式)

Controller 方式(web-2)では ModelBinder でアクション引数に直接注入できる。`Account`(アプリ固有のユーザ型)を引数に書くだけで受け取れる。

```csharp
public sealed class AccountModelBinderProvider : IModelBinderProvider
{
    private static readonly AccountModelBinder Binder = new();

    public IModelBinder? GetBinder(ModelBinderProviderContext context)
    {
        return context.Metadata.ModelType == typeof(Account) ? Binder : null;
    }

    public sealed class AccountModelBinder : IModelBinder
    {
        public Task BindModelAsync(ModelBindingContext bindingContext)
        {
            bindingContext.Result = ModelBindingResult.Success(bindingContext.HttpContext.User.ToAccount());
            return Task.CompletedTask;
        }
    }
}
```

権限判定を宣言的に行いたい場合は `[Permission]` のようなアプリ固有属性(Authorization Filter / Policy)を用意し、アクションに付ける。判定ロジックは属性・フィルタ側に閉じ、アクション本体には書かない。

### ログ用の横断状態(LoggingContext + CallbackEnricher)

ログに全行ユーザ ID を出す等の横断要件は、`AsyncLocal` の `LoggingContext` + Serilog の `CallbackEnricher`(log-3)で実現する。

```csharp
public static class LoggingContext
{
    private static readonly AsyncLocal<string?> UserIdLocal = new();

    public static string? UserId
    {
        get => UserIdLocal.Value;
        set => UserIdLocal.Value = value;
    }
}
```

値の設定はミドルウェアで行い、Enricher が出力時に解決する。

```csharp
public static WebApplication UseLoggingContext(this WebApplication app)
{
    app.Use(static (context, next) =>
    {
        LoggingContext.UserId = context.User.FindFirstValue(ClaimTypes.NameIdentifier);
        return next(context);
    });

    return app;
}
```

```csharp
builder.Services.AddSerilog(options =>
{
    options.ReadFrom.Configuration(builder.Configuration);
    options.Enrich.With(new CallbackEnricher("UserId", static () => LoggingContext.UserId));
});
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| `Credential` / `CredentialContext` | `Application/`(アプリ固有の共通部品、namespace-2) |
| セッション系の横断 Context | `Contexts/`(namespace-1)。`Application` 直下と迷ったら、複数の Context が育った時点で `Contexts/` へ |
| EndpointFilter / ModelBinder | `Infrastructure/Filters/` / `Infrastructure/`(MVC 拡張) |
| `LoggingContext` / `CallbackEnricher` | `Infrastructure/Logging/` |

## バリエーションと使い分け

- **引数注入と AsyncLocal の使い分け**: ハンドラ・アクションが明示的に使う情報は引数注入(EndpointFilter で `Credential` を引数解決する形や ModelBinder)を優先する。ログ・監査のような「どの層からも暗黙に参照される」情報のみ `AsyncLocal` Context を使う
- **Blazor Server**: 認証 UI・状態は Cookie 認証一式(blazor-7)を使う。本トピックの Context パターンは API リクエストスコープの管理に適用する
- **フレームワーク認可で足りる場合**: ロール判定が `RequireAuthorization(Policies.Xxx)` で表せる間はアプリ固有の権限属性を作らない

## アンチパターン

- **`HttpContext` / `IHttpContextAccessor` の下層引き回し** — Service / Usecase が `HttpContext` に依存すると、テスト不能かつ Web 以外のホストで再利用できなくなる。境界で `Credential` に写す
- **static な可変状態(非 AsyncLocal)での保持** — リクエスト間で値が混線する。横断状態は必ず `AsyncLocal` にする
- **クリア漏れ** — フィルタで設定した Context を finally でクリアしない形にしない(コネクション再利用時に前リクエストの値が残る)
- **Claims 解釈の散在** — `FindFirstValue(ClaimTypes.NameIdentifier)` のような解釈コードを各ハンドラに書かない。フィルタ / Binder / 拡張メソッドの 1 箇所に集約する
- **認証そのものの自作** — 本トピックは「認証済み後の状態管理」のパターンであり、トークン検証・サインインはフレームワークの認証(JWT / Cookie / ApiKey ハンドラ)に任せる
