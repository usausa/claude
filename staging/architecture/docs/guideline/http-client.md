# HTTP クライアント

| 項目 | 内容 |
|---|---|
| ID | guideline-3 |
| 分類 | guideline |
| 関連 | guideline-1(エラー処理方針) / guideline-2(非同期作法) / web-3(API 契約) / config-2(設定バインドの定型) / maui-2(ApiContext の初期化) |

## 目的

外部 API 呼び出しの**接続管理・横断関心事・シリアライズの置き場**を固定し、呼び出し側を業務の関心だけにする。

- `HttpClient` の生成・寿命は `IHttpClientFactory` に任せ、ソケット枯渇・DNS 更新問題を構造的に避ける
- 認証・共通ヘッダ・接続先の知識をハンドラ・Context に集約し、呼び出し側に分散させない
- シリアライズは REST クライアント抽象に寄せ、`HttpContent` の手組みを書かない

## 標準形

### named client の登録

**`new HttpClient()` を書かない**。named client を `IHttpClientFactory` に登録し、名前は定数クラス(`ApiNames`)に集約する。プライマリハンドラは `SocketsHttpHandler` とし、**`PooledConnectionLifetime` を必ず設定**する(DNS 変更への追従)。

```csharp
public static class ApiNames
{
    public const string Default = "api";
}
```

```csharp
builder.Services
    .AddHttpClient(ApiNames.Default, (p, client) =>
    {
        client.BaseAddress = p.GetRequiredService<ApiContext>().BaseAddress;
        client.Timeout = TimeSpan.FromSeconds(30);
        client.DefaultRequestHeaders.AcceptEncoding.Add(new StringWithQualityHeaderValue("gzip"));
        client.DefaultRequestHeaders.AcceptEncoding.Add(new StringWithQualityHeaderValue("deflate"));
    })
    .ConfigurePrimaryHttpMessageHandler(static () => new SocketsHttpHandler
    {
        AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate,
        PooledConnectionLifetime = TimeSpan.FromMinutes(1)
    })
    .AddHttpMessageHandler<ApiDelegatingHandler>();

builder.Services.AddTransient<ApiDelegatingHandler>();

builder.Services.AddSingleton<ApiContext>();
```

### 横断関心事は DelegatingHandler へ

Bearer 付与・共通ヘッダ・リクエストログは登録済みの `DelegatingHandler` が担う。**呼び出し側でヘッダを操作しない**。`DelegatingHandler` は Transient で登録する(Factory がパイプラインを構築するため)。

```csharp
public sealed class ApiDelegatingHandler : DelegatingHandler
{
    private readonly ApiContext apiContext;

    public ApiDelegatingHandler(ApiContext apiContext)
    {
        this.apiContext = apiContext;
    }

    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        if (!String.IsNullOrEmpty(apiContext.Token))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiContext.Token);
        }

        return base.SendAsync(request, cancellationToken);
    }
}
```

### 接続先・トークンは Context に一元化

`BaseAddress`・認証トークンの差し替えは `ApiContext`(Singleton)に集約する。登録時は Context から読み、実行時の切替(設定画面での接続先変更・ログインでのトークン取得)も Context 経由で行う(初期値の投入は maui-2 の `ApplicationInitializer` 等の起動後処理)。

### 呼び出し側 — Factory から取得し REST 抽象で呼ぶ

Service は `IHttpClientFactory` を注入し、named client を取得して呼ぶ。シリアライズは REST クライアント抽象(Rester)の拡張メソッドに寄せ、**`HttpContent` の手組み・手動 JSON 化をしない**。

```csharp
public sealed class HttpService
{
    private readonly IHttpClientFactory httpClientFactory;

    public HttpService(IHttpClientFactory httpClientFactory)
    {
        this.httpClientFactory = httpClientFactory;
    }

    public async ValueTask<IRestResponse<DataListResponse>> GetDataListAsync()
    {
        using var client = httpClientFactory.CreateClient(ApiNames.Default);
        return await client.GetAsync<DataListResponse>("api/data/list");
    }
}
```

- 失敗は例外ではなく**結果(`IRestResponse<T>` の成否)で受けて分岐する**(guideline-1)。想定外のみ伝播させる
- URL は文字列直書きせず定数に集約する(サーバ側 `ApiRoutes`(web-1)に対応するクライアント側の置き場)
- シリアライザのグローバル設定(camelCase・Converter)は起動時に 1 箇所で構成する(`RestConfig.Default.UseJsonSerializer(...)`。web-3 の契約と揃える)

## 配置ルール

| 対象 | 場所 |
|---|---|
| named client の登録・ハンドラ構成 | 起動の組み立て(`ConfigureHttpClient()` 拡張。host-1 / maui-1) |
| `ApiNames` / URL 定数 | `Services/` または `Application/` の定数クラス |
| `ApiDelegatingHandler` / `ApiContext` | `Services/`(クライアント)または `Infrastructure/`(サーバ。namespace-3) |
| API 呼び出し Service | `Services/`(I/O 境界。namespace-1 / namespace-7) |

## バリエーションと使い分け

- **複数 API の呼び分け**: 接続先毎に named client を追加し、`ApiNames` に定数を並べる。ハンドラ・Context も接続先単位で分ける
- **タイムアウト・リトライ**: 呼び出し要件で個別に設計する(既定で盛らない)。共通の resilience を持つ場合は組み立て側のハンドラ構成に寄せ、呼び出し側に分岐を書かない
- **サーバ側での利用**: 同じ作法が Web ホスト・Worker にも適用される。トレースは `AddHttpClientInstrumentation()`(telemetry-1)が自動計装する

## アンチパターン

- **`new HttpClient()` の都度生成 / static 保持** — ソケット枯渇(都度生成)と DNS 更新非追従(static 保持)の二重の罠。`IHttpClientFactory` + `PooledConnectionLifetime` に統一する
- **呼び出し側での認証ヘッダ操作** — トークン付与が分散し、更新漏れ・重複が生じる。`DelegatingHandler` に集約する
- **`HttpContent` の手組み・手動 JSON 化** — シリアライズ設定(命名・Converter)が呼び出し毎にぶれる。REST クライアント抽象に寄せる
- **URL 文字列の直書き** — サーバ側のルート変更に追従できない。定数集約する
- **HTTP ステータスの例外化** — 予期できる失敗(404・409 等)を例外で扱わない。結果で受けて分岐する(guideline-1)
