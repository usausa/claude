# Program.cs の構成

| 項目 | 内容 |
|---|---|
| ID | host-1 |
| 分類 | host |
| 関連 | host-2(起動の定型行) / host-3(起動ログ) / host-4(DI 登録スタイル) / host-5(partial Program) / log-2(Serilog 構成) / namespace-2(Application 名前空間) / deploy-1(サービス化 API) / web-1(Minimal API) |

## 目的

`Program.cs` は**構成の宣言列挙(目次)に徹し、実体は `Application/ApplicationExtensions.cs` に集約する**。

- `Program.cs` を読むだけで、アプリケーションの構成要素(ホスティング・ログ・API・ヘルスチェック・テレメトリ)の全体像を1画面で把握できる
- 個別の構成変更は `ApplicationExtensions.cs` の該当セクションに閉じ、`Program.cs` は安定する
- サーバ系プロジェクト間で `Program.cs` の形が揃い、横断的な読み書きが容易になる

## 標準形

### Program.cs

`builder.ConfigureXxx()` / `app.UseXxx()` / `app.MapXxx()` の**宣言列挙のみ**を書く。ラムダ・条件分岐・`Services` への直接登録は書かない。

```csharp
using Microsoft.Extensions.Hosting.WindowsServices;

using Template.ApiServer.Host.Application;

//--------------------------------------------------------------------------------
// Configure builder
//--------------------------------------------------------------------------------
Directory.SetCurrentDirectory(AppContext.BaseDirectory);
var builder = WebApplication.CreateBuilder(new WebApplicationOptions
{
    Args = args,
    ContentRootPath = WindowsServiceHelpers.IsWindowsService() ? AppContext.BaseDirectory : default
});

// System
builder.ConfigureSystem();
// Host
builder.ConfigureHost();
// Logging
builder.ConfigureLogging();

// Http
builder.ConfigureHttp();
// API
builder.ConfigureApi();

// Health
builder.ConfigureHealth();
// Telemetry
builder.ConfigureTelemetry();

// Components
builder.ConfigureComponents();

//--------------------------------------------------------------------------------
// Configure the HTTP request pipeline
//--------------------------------------------------------------------------------
var app = builder.Build();

// Startup information
app.LogStartupInformation();

// Error handler
app.UseErrorHandler();

// End point
app.MapEndpoints();

// Initialize
await app.InitializeApplicationAsync();

// Run
await app.RunAsync();
```

- builder 構成とパイプライン構成を 80 桁罫線コメントで二分し、各呼び出しに1行コメントを付けて目次性を保つ
- 冒頭の定型行(`SetCurrentDirectory` / `ContentRootPath` 分岐)の理由は host-2、`LogStartupInformation()` は host-3
- 末尾に統合テスト用の `public partial class Program {}` を置く(host-5)

### ApplicationExtensions.cs

セクションを `//----` 罫線コメントで区切り、`Configure` 系は **`IHostApplicationBuilder` を受けて返し、連鎖可能**にする(Kestrel 等 Web 固有の構成を行うメソッドのみ受けを `WebApplicationBuilder` にしてよい)。`Use` / `Map` 系は `WebApplication` を受けて返す。セクションの並び順は `Program.cs` の呼び出し順に合わせる。

```csharp
namespace Template.ApiServer.Host.Application;

public static class ApplicationExtensions
{
    //--------------------------------------------------------------------------------
    // System
    //--------------------------------------------------------------------------------

    public static IHostApplicationBuilder ConfigureSystem(this IHostApplicationBuilder builder)
    {
        // Path
        builder.Configuration.SetBasePath(AppContext.BaseDirectory);

        return builder;
    }

    //--------------------------------------------------------------------------------
    // Host
    //--------------------------------------------------------------------------------

    public static IHostApplicationBuilder ConfigureHost(this IHostApplicationBuilder builder)
    {
        // Service
        builder.Services
            .AddWindowsService()
            .AddSystemd();

        return builder;
    }

    // 以下、ConfigureLogging(log-2)/ ConfigureHttp / ConfigureApi / ConfigureHealth /
    // ConfigureTelemetry / ConfigureComponents(host-4)/ LogStartupInformation(host-3)/
    // UseErrorHandler / MapEndpoints / InitializeApplicationAsync を同じ形式で並べる
}
```

標準メソッドの一覧:

| メソッド | 内容 |
|---|---|
| `ConfigureSystem` | 設定の基準パス(host-2)・エンコーディング等のプロセスレベル設定 |
| `ConfigureHost` | `AddWindowsService().AddSystemd()`(deploy-1) |
| `ConfigureLogging` | Serilog への一本化(log-2) |
| `ConfigureHttp` | HttpContextAccessor・Kestrel 制限・ルーティング・ForwardedHeaders |
| `ConfigureApi` | JSON オプション(web-3)・OpenAPI・ProblemDetails(web-6) |
| `ConfigureHealth` / `ConfigureTelemetry` | ヘルスチェック(telemetry-2)・OpenTelemetry(telemetry-1) |
| `ConfigureComponents` | アプリ部品の DI 登録(host-4) |
| `LogStartupInformation` | 起動ログ(host-3) |
| `UseErrorHandler` / `MapEndpoints` | 例外ハンドラ(web-6)・エンドポイント(web-1) |
| `InitializeApplicationAsync` | 起動前初期化(データ準備・インスツルメント準備) |

## 配置ルール

| 対象 | 場所 |
|---|---|
| `Program.cs` | ホストプロジェクト直下(トップレベル文) |
| `ApplicationExtensions.cs` | `Application/`(namespace-2: アプリ固有の共通部品) |
| 起動ログの `Log.cs` | `Application/Log.cs`(host-3 / log-1) |
| 機能単位の DI 登録拡張 | 各機能フォルダの `ServiceCollectionExtensions.cs`(host-4) |

## バリエーションと使い分け

- **Generic Host(非 Web 常駐)**: `Host.CreateApplicationBuilder(args)` で同じ方針を適用する。構成要素が少ない場合は `Program.cs` 直書きも許容するが、セクション順と区切りコメント(host-4)は維持する
- **ファイル分割**: `ApplicationExtensions.cs` が肥大化したら `partial` にして `ApplicationExtensions.Telemetry.cs` 等へ分割する。`Program.cs` 側の見た目は変えない
- **クライアントアプリ**: 同じ「宣言列挙 + 実体集約」を mvvm-4(ApplicationExtensions)・maui-1(MauiProgram チェーン)として適用する

## アンチパターン

- **一枚岩トップレベル文 + 区切りコメント(旧方式)** — `// Log` 等のコメントで区切りながら全構成を `Program.cs` にべた書きする形。**移行元であり、新規には採用しない**
- **`Program.cs` へのロジック混入** — ラムダ内の分岐や `Services` 直接登録を書き始めると目次性が失われ、旧方式へ逆戻りする
- **`ConfigureXxx` が `void` を返す** — 連鎖できず、呼び出し形が揃わない
- **構成の置き場の分散** — 一部を `Program.cs`、一部を拡張メソッド、とする折衷をしない。実体は必ず `ApplicationExtensions.cs` 側に置く
