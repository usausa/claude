# クライアント起動ハブ(ApplicationExtensions)

| 項目 | 内容 |
|---|---|
| ID | mvvm-4 |
| 分類 | mvvm |
| 関連 | mvvm-2(Smart.Navigation) / mvvm-3(DI コンテナ差し替え) / host-1(サーバ側 Program.cs 構成) / host-3(起動ログの儀式) / maui-1(MauiProgram チェーン) / avalonia-1(起動とライフタイム分岐) / avalonia-3(組込みの実行形態) |

## 目的

クライアントの起動処理を `ApplicationExtensions.cs` に集約し、**App(App.xaml.cs / App.axaml.cs)を薄く保つ**。

- サーバ側の host-1(宣言列挙 + `ApplicationExtensions.cs` 集約)と同じ思想をクライアントに適用する
- App 側はホスト構築とライフサイクルフックのみとし、実体(ログ構成・DI 登録・起動/終了シーケンス)は拡張メソッドに置く
- DI 登録は `ConfigureContainer(ResolverConfig)` 一箇所に集約する(mvvm-3)

## 標準形

### ApplicationExtensions.cs の構成

次の拡張メソッド群を区切りコメント付きで1ファイルに集約する。

| メソッド | 役割 |
|---|---|
| `ConfigureLogging` | ログ構成(Serilog を appsettings 委譲で構成 → log-2) |
| `ConfigureComponents` | コンテナ差し替え + 設定バインド + サービス登録(mvvm-3) |
| `ConfigureLifetime` | (組込みのみ)ホストライフタイムの差し替え(avalonia-3) |
| `StartApplicationAsync` | ホスト開始 + 起動ログ + 初期画面遷移 |
| `ExitApplicationAsync` | ホスト停止(タイムアウト付き)+ 破棄 |

```csharp
namespace Template.App;

public static partial class ApplicationExtensions
{
    //--------------------------------------------------------------------------------
    // Logging
    //--------------------------------------------------------------------------------

    public static HostApplicationBuilder ConfigureLogging(this HostApplicationBuilder builder)
    {
        builder.Logging.ClearProviders();
        builder.Services.AddSerilog(options =>
        {
            options.ReadFrom.Configuration(builder.Configuration);
        });

        return builder;
    }

    //--------------------------------------------------------------------------------
    // Components
    //--------------------------------------------------------------------------------

    public static HostApplicationBuilder ConfigureComponents(this HostApplicationBuilder builder)
    {
        builder.ConfigureContainer(new SmartServiceProviderFactory(), ConfigureContainer);

        // Setting
        builder.Services.AddOptions<ClientSetting>().BindConfiguration("Client").ValidateDataAnnotations().ValidateOnStart();
        builder.Services.AddSingleton(static p => p.GetRequiredService<IOptions<ClientSetting>>().Value);

        return builder;
    }

    private static void ConfigureContainer(ResolverConfig config)
    {
        // DI 登録はここ一箇所に集約(mvvm-3)
    }

    //--------------------------------------------------------------------------------
    // Startup
    //--------------------------------------------------------------------------------

    public static async ValueTask StartApplicationAsync(this IHost host)
    {
        // Start host
        await host.StartAsync().ConfigureAwait(false);

        // Startup log
        var log = host.Services.GetRequiredService<ILogger<App>>();
        var environment = host.Services.GetRequiredService<IHostEnvironment>();
        ThreadPool.GetMinThreads(out var workerThreads, out var completionPortThreads);

        log.InfoStartup();
        log.InfoStartupSettingsRuntime(RuntimeInformation.OSDescription, RuntimeInformation.FrameworkDescription, RuntimeInformation.RuntimeIdentifier);
        log.InfoStartupSettingsGC(GCSettings.IsServerGC, GCSettings.LatencyMode, GCSettings.LargeObjectHeapCompactionMode);
        log.InfoStartupSettingsThreadPool(workerThreads, completionPortThreads);
        log.InfoStartupApplication(environment.ApplicationName, typeof(App).Assembly.GetName().Version);
        log.InfoStartupEnvironment(environment.EnvironmentName, environment.ContentRootPath);

        // Navigate to view
        var navigator = host.Services.GetRequiredService<Navigator>();
        await navigator.ForwardAsync(ViewId.Menu).ConfigureAwait(false);
    }

    public static async ValueTask ExitApplicationAsync(this IHost host)
    {
        // Stop host
        await host.StopAsync(TimeSpan.FromSeconds(5)).ConfigureAwait(false);
        host.Dispose();
    }
}
```

起動ログの内容(Version / Runtime / GC / ThreadPool)はサーバ側の儀式(host-3)と同一とする。

### App 側 — 宣言列挙のみ

App 側はビルダーへの宣言列挙と、プラットフォームのライフサイクルへの接続のみを書く。

```csharp
// Avalonia 版の例
public override void Initialize()
{
    AvaloniaXamlLoader.Load(this);

    host = Host.CreateApplicationBuilder()
        .ConfigureLogging()
        .ConfigureComponents()
        .Build();
    ResolveProvider.Default.Provider = host.Services;
}

public override async void OnFrameworkInitializationCompleted()
{
    if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
    {
        desktop.Exit += async (_, _) => await host.ExitApplicationAsync();
        desktop.MainWindow = host.Services.GetRequiredService<MainWindow>();

        await host.StartApplicationAsync();
    }

    base.OnFrameworkInitializationCompleted();
}
```

WPF では `OnStartup` / `OnExit` から同じ拡張メソッドを呼ぶ(ウィンドウ表示は WindowManager → wpf-1)。

## 配置ルール

| 対象 | 場所 |
|---|---|
| `ApplicationExtensions.cs` | プロジェクト直下(サーバ側 host-1 と同じ) |
| `Log.cs`(`[LoggerMessage]` 定義) | プロジェクト直下(log-1) |
| App のライフサイクルフック | `App.xaml.cs` / `App.axaml.cs`(実体を書かない) |

## バリエーションと使い分け

- **WPF**: `Host.CreateApplicationBuilder` を App コンストラクタで構築し、`OnStartup` で WindowManager の `Load` + `StartAsync` + 初期遷移、`OnExit` で `ExitApplicationAsync` 相当を呼ぶ(wpf-1)
- **Avalonia desktop**: `Initialize` でホスト構築、`OnFrameworkInitializationCompleted` でライフタイム分岐と起動(avalonia-1)
- **Avalonia embedded**: `ConfigureLifetime`(`NopLifetime` によるシグナル捕捉の無効化)を追加する(avalonia-3)
- **MAUI**: ビルダーが `MauiAppBuilder` であるため、起動ハブは `MauiProgram.cs` の宣言的チェーンが担う(maui-1)。役割分担は次のとおり — チェーンの各実体(private static 拡張メソッド)が本トピックの `ConfigureXxx` に相当し、起動後処理(`StartApplicationAsync` 相当)は `IMauiInitializeService`(`ApplicationInitializer` → maui-2)に置く

## アンチパターン

- **App.xaml.cs への実体べた書き** — ログ構成・DI 登録・RestConfig 等を App に直接書くと肥大化し、プラットフォーム間でパターンが崩れる。実体は `ApplicationExtensions.cs` へ
- **DI 登録の分散** — `ConfigureContainer(ResolverConfig)` 以外の場所(App / View / 個別クラス)での登録は追跡不能になる。一箇所に集約する
- **起動ログの省略** — 障害調査の起点情報が失われる。クライアントでも host-3 と同じ起動ログを必ず出す
- **終了時の即時 Dispose** — `StopAsync` を経ずに終了するとホステッドサービスの graceful shutdown が効かない。`ExitApplicationAsync`(タイムアウト付き `StopAsync` → `Dispose`)を経由する
