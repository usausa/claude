# Cookie 認証一式

| 項目 | 内容 |
|---|---|
| ID | blazor-7 |
| 分類 | blazor |
| 関連 | blazor-6(レイアウト・シェル) / web-5(サーバ側の認証状態管理) / config-1(Setting 命名) / config-2(バインドの定型) |

## 目的

Blazor Server の認証を **JWT 入り Cookie + 自前 `AuthenticationStateProvider`** の定型一式で構成し、ログイン UI・認可・トークン更新の書き方を統一する。

- 認証状態の実体は署名付きトークン(JWT)を格納した Cookie。サーバ側セッションを持たない
- 認証状態の提供(`AuthenticationStateProvider`)とログイン操作(`ILoginProvider`)を1クラスで実装し、UI からは `LoginManager` 経由で使う
- 認可は Blazor 標準(`[Authorize]` / `AuthorizeView` / `AuthorizeRouteView`)に乗せる

## 標準形

### 構成要素

| 型 | 役割 |
|---|---|
| `CookieAuthenticationStateProvider` | `AuthenticationStateProvider` 実装 + `ILoginProvider` 実装。Cookie のトークンを検証して `ClaimsPrincipal` を復元(キャッシュ)し、ログイン/ログアウトで Cookie を更新して状態変更を通知する |
| `ILoginProvider` | `LoginAsync(ClaimsIdentity)` / `LogoutAsync()` / `UpdateToken()` の抽象 |
| `LoginManager` | UI から使うファサード。資格情報の検証と `ClaimsIdentity` の組み立てを行い `ILoginProvider` に委譲する |
| `Account` | 画面表示用のアカウント情報(Id / Name / Group)。`ClaimsPrincipalExtensions.ToAccount()` で変換 |
| `Claims` / `Roles` | アプリ固有のクレーム名・ロール名の定数 |
| `TokenHelper` | JWT の生成(`BuildToken`)と検証(`ParseToken`)の静的ヘルパ |
| `CookieAuthenticationSetting` | Cookie 名・署名鍵・Issuer・有効期限の設定(config-1 の `*Setting`) |

### CookieAuthenticationStateProvider

```csharp
public sealed class CookieAuthenticationStateProvider : AuthenticationStateProvider, ILoginProvider
{
    private static readonly ClaimsPrincipal Anonymous = new();

    private readonly IHttpContextAccessor httpContextAccessor;

    private readonly IJSRuntime jsRuntime;

    private readonly CookieAuthenticationSetting setting;

    private readonly byte[] secretKey;

    private ClaimsPrincipal? cachedPrincipal;

    public CookieAuthenticationStateProvider(IHttpContextAccessor httpContextAccessor, IJSRuntime jsRuntime, IOptions<CookieAuthenticationSetting> setting)
    {
        this.httpContextAccessor = httpContextAccessor;
        this.jsRuntime = jsRuntime;
        this.setting = setting.Value;
        secretKey = Convert.FromHexString(setting.Value.SecretKey);
    }

    public override Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        if (cachedPrincipal is not null)
        {
            return Task.FromResult(new AuthenticationState(cachedPrincipal));
        }

        // 初回はリクエストの Cookie からトークンを検証して復元する
        var value = httpContextAccessor.HttpContext?.Request.Cookies[setting.AccountKey];
        var principal = String.IsNullOrEmpty(value) ? null : TokenHelper.ParseToken(value, secretKey, setting.Issuer);
        if (principal is not null)
        {
            cachedPrincipal = principal;
            return Task.FromResult(new AuthenticationState(principal));
        }

        return Task.FromResult(new AuthenticationState(Anonymous));
    }

    public async Task LoginAsync(ClaimsIdentity identity)
    {
        var value = TokenHelper.BuildToken(identity, secretKey, setting.Issuer, setting.Expire);
        await UpdateCookie(value, DateTime.Now.AddMinutes(setting.Expire)).ConfigureAwait(false);

        cachedPrincipal = new ClaimsPrincipal(identity);
        NotifyAuthenticationStateChanged(Task.FromResult(new AuthenticationState(cachedPrincipal)));
    }

    public async Task LogoutAsync()
    {
        cachedPrincipal = null;
        await UpdateCookie(string.Empty, new DateTime(1970, 1, 1)).ConfigureAwait(false);

        NotifyAuthenticationStateChanged(Task.FromResult(new AuthenticationState(Anonymous)));
    }

    public Task UpdateToken()
    {
        // キャッシュ済み principal からトークンを再発行して有効期限を延長する
        if (cachedPrincipal is null)
        {
            return Task.CompletedTask;
        }

        var identity = cachedPrincipal.Identities.First();
        var value = TokenHelper.BuildToken(identity, secretKey, setting.Issuer, setting.Expire);
        return UpdateCookie(value, DateTime.Now.AddMinutes(setting.Expire));
    }

    private async Task UpdateCookie(string value, DateTime expire)
    {
        // 応答ヘッダを使えない回線接続後は JS 経由で Cookie を書き換える
        await jsRuntime.InvokeVoidAsync("eval", $"document.cookie = \"{setting.AccountKey}={value}; path=/; expires={expire.ToUniversalTime():R}\"").ConfigureAwait(false);
    }
}
```

### LoginManager(UI 向けファサード)

資格情報の検証(実装はアプリ固有)とクレームの組み立てを担い、ページからは `LoginAsync(id, password)` の1呼び出しにする。

```csharp
public sealed class LoginManager
{
    private readonly ILoginProvider loginProvider;

    public LoginManager(ILoginProvider loginProvider)
    {
        this.loginProvider = loginProvider;
    }

    public async Task<bool> LoginAsync(string id, string password)
    {
        // 資格情報の検証はアプリ固有に実装する(Service / IPasswordProvider 等へ委譲)
        if (!VerifyCredential(id, password))
        {
            return false;
        }

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, id),
            new(ClaimTypes.Name, id),
            new(Claims.Group, "00")
        };

        await loginProvider.LoginAsync(new ClaimsIdentity(claims, "custom"));

        return true;
    }

    public Task LogoutAsync() => loginProvider.LogoutAsync();

    public Task UpdateToken() => loginProvider.UpdateToken();
}
```

### DI 登録と設定

`AuthenticationStateProvider` と `ILoginProvider` は**同一インスタンス**を共有する(転送登録)。

```csharp
builder.Services.AddHttpContextAccessor();

builder.Services.Configure<CookieAuthenticationSetting>(builder.Configuration.GetSection("Authentication"));
builder.Services.AddScoped<AuthenticationStateProvider, CookieAuthenticationStateProvider>();
builder.Services.AddScoped(static p => (ILoginProvider)p.GetRequiredService<AuthenticationStateProvider>());
builder.Services.AddScoped<LoginManager>();
```

```json
{
  "Authentication": {
    "SecretKey": "0000000000000000000000000000000000000000000000000000000000000000",
    "Issuer": "app",
    "Expire": 1440
  }
}
```

署名鍵(`SecretKey`)は hex 文字列。**リポジトリにはダミー値のみを置き、実値は環境側(環境変数・シークレットストア)で供給する。**

### ルーティングへの組み込み(App.razor)

未認証は `LoginPage`、権限不足は `Error403`(blazor-6)に振り分ける。

```razor
<CascadingAuthenticationState>
    <Router AppAssembly="@typeof(App).Assembly">
        <Found Context="routeData">
            <AuthorizeRouteView RouteData="@routeData" DefaultLayout="@typeof(MainLayout)">
                <NotAuthorized>
                    @if (context.User.Identity?.IsAuthenticated != true)
                    {
                        <LoginPage Reload="true" />
                    }
                    else
                    {
                        <Error403 />
                    }
                </NotAuthorized>
            </AuthorizeRouteView>
        </Found>
        <NotFound>
            <LayoutView Layout="@typeof(SimpleLayout)">
                <Error404 />
            </LayoutView>
        </NotFound>
    </Router>
</CascadingAuthenticationState>
```

ページ側は Blazor 標準の属性・コンポーネントを使う。

```razor
@page "/user"
@attribute [Authorize]
```

### トークンのスライド更新

長時間接続する Blazor Server では、レイアウト(blazor-6)がタイマーで `LoginManager.UpdateToken()` を定期実行し、操作中のセッション切れを防ぐ。

```csharp
private readonly System.Timers.Timer updateTimer = new(3600_000);

protected override void OnInitialized()
{
    updateTimer.Elapsed += (_, _) => _ = InvokeAsync(() => LoginManager.UpdateToken());
    updateTimer.Enabled = true;
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| 認証一式(Provider / LoginManager / Account / Claims / TokenHelper) | `Components/Authentication/`(UI コンポーネントと連動する認証部品として1フォルダに集約) |
| `CookieAuthenticationSetting` | 認証部品と同居(コンポーネント付属設定 → config-4) |
| ログインページ | `Components/Pages/LoginPage.razor(.cs)`。`[AllowAnonymous]` + 無装飾レイアウト(blazor-6) |

## バリエーションと使い分け

- **表示用アカウント情報**: `CascadingParameter` の `Task<AuthenticationState>` を `ToAccount()` 拡張で `Account` に変換して使う。ページに `ClaimsPrincipal` の解析コードを書かない
- **API との併用**: 同一アプリの Web API 側で認証状態が必要な場合は、Credential + ModelBinder 方式(web-5)と組み合わせる
- **WASM / 外部 IdP**: 本トピックは Blazor Server の自前認証の定型。OIDC 等の外部 IdP を使う場合はフレームワーク標準の認証ハンドラに乗せ、本方式は使わない

## アンチパターン

- **署名鍵・接続情報の実値コミット** — `SecretKey` はダミーのみ。実値は環境側で供給する
- **`AuthenticationStateProvider` と `ILoginProvider` の別インスタンス登録** — 状態変更通知が届かなくなる。転送登録で同一インスタンスを共有する
- **自前のログイン状態フラグ** — `bool loggedIn` のような独自状態を作らない。状態は `AuthenticationStateProvider` に一本化し、UI は `AuthorizeView` で分岐する
- **有効期限の放置** — スライド更新(`UpdateToken`)なしでは長時間利用中にトークンが失効する。レイアウトの定期更新をセットで実装する
- **Cookie への生データ格納** — アカウント情報を平文・独自形式で Cookie に置かない。署名付きトークン(JWT)で改竄を検出できる形にする
