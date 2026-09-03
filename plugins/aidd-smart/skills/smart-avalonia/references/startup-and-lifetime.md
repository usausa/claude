# Avalonia の起動とライフタイム分岐

| 項目 | 内容 |
|---|---|
| ID | avalonia-1 |
| 分類 | avalonia |
| 関連 | mvvm-2(Smart.Navigation) / mvvm-3(DI コンテナ差し替え) / mvvm-4(クライアント起動ハブ) / avalonia-3(組込みの実行形態) / wpf-3(例外ハンドリング) / host-3(起動ログの儀式) |

## 目的

Avalonia アプリケーションの起動を **Program(AppBuilder)→ App.Initialize(ホスト構築)→ OnFrameworkInitializationCompleted(ライフタイム分岐)** の3段に固定する。

- Program.cs は AppBuilder の構成のみとし、ホスト構築・DI・ログの実体は `ApplicationExtensions.cs` に集約する(mvvm-4)
- desktop / single view のライフタイム差はこの1メソッドの分岐に閉じ込め、以降のコードをプラットフォーム非依存に保つ
- ホストの開始・終了(`StartApplicationAsync` / `ExitApplicationAsync`)を Avalonia のライフサイクルイベントに正しく接続する

## 標準形

### Program.cs — AppBuilder の構成のみ

```csharp
public static class Program
{
    [STAThread]
    public static int Main(string[] args) => BuildAvaloniaApp()
        .StartWithClassicDesktopLifetime(args);

    // Avalonia configuration, don't remove; also used by visual designer.
    public static AppBuilder BuildAvaloniaApp() =>
        AppBuilder.Configure<App>()
            .UsePlatformDetect()
            .WithInterFont()
            .LogToTrace();
}
```

`BuildAvaloniaApp()` はビジュアルデザイナからも使用されるため、この形のまま残す。

### App.Initialize — ホスト構築と例外フック

XAML ロード直後にホストを構築し、`ResolveProvider` に接続する(mvvm-3)。グローバル例外フックもここで仕掛ける(wpf-3 と同型)。

```csharp
public partial class App : Application
{
    private IHost host = default!;

    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
#if DEBUG
        this.AttachDeveloperTools();
#endif

        host = Host.CreateApplicationBuilder()
            .ConfigureLogging()
            .ConfigureComponents()
            .Build();
        ResolveProvider.Default.Provider = host.Services;

        // Exception hook
        var log = host.Services.GetRequiredService<ILogger<App>>();
        AppDomain.CurrentDomain.UnhandledException += (_, args) => log.ErrorUnknownException((Exception)args.ExceptionObject);
        TaskScheduler.UnobservedTaskException += (_, args) =>
        {
            log.ErrorUnknownException(args.Exception);
            args.SetObserved();
        };
    }
}
```

### OnFrameworkInitializationCompleted — ライフタイム分岐

`IClassicDesktopStyleApplicationLifetime`(デスクトップ)と `ISingleViewApplicationLifetime`(組込み・モバイル)をここで分岐する。デスクトップでは `desktop.Exit` にホスト停止を接続する。

```csharp
public override async void OnFrameworkInitializationCompleted()
{
    if (ApplicationLifetime is ISingleViewApplicationLifetime singleViewPlatform)
    {
        // Main view
        singleViewPlatform.MainView = host.Services.GetRequiredService<MainView>();

        // Start
        await host.StartApplicationAsync();
    }
    else if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
    {
        // Exit hook
        desktop.Exit += async (_, _) => await host.ExitApplicationAsync();

        // Main window
        desktop.MainWindow = host.Services.GetRequiredService<MainWindow>();

        // Start
        await host.StartApplicationAsync();
    }

    base.OnFrameworkInitializationCompleted();
}
```

### StartApplicationAsync / ExitApplicationAsync

起動・終了の実体は `ApplicationExtensions.cs` に置く(mvvm-4)。ホスト開始 → 起動ログ(host-3 のクライアント版)→ 初期画面遷移(mvvm-2)の順で固定する。

```csharp
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
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| AppBuilder 構成 | `Program.cs`(構成のみ、ロジックなし) |
| ホスト構築・例外フック | `App.axaml.cs` の `Initialize()` |
| ライフタイム分岐・メインウィンドウ設定 | `App.axaml.cs` の `OnFrameworkInitializationCompleted()` |
| `ConfigureXxx` / `StartApplicationAsync` / `ExitApplicationAsync` | `ApplicationExtensions.cs`(mvvm-4) |

## バリエーションと使い分け

- **デスクトップ専用アプリ**: `IClassicDesktopStyleApplicationLifetime` の分岐のみでよい。ウィンドウ位置の保存・復元(wpf-2 相当)は `desktop.MainWindow` 設定の前後で `UserSettingStore` を介して行う
- **組込みアプリ**: Debug はデスクトップ実行、Release は DRM 直描画となるため両分岐を実装する(avalonia-3)。`ConfigureLifetime()`(`NopLifetime`)がチェーンに加わる
- UI スレッドの未処理例外を通知したい場合は `Dispatcher.UIThread.UnhandledException` をフックし、`args.Handled = true` としたうえでダイアログ表示する

## アンチパターン

- **Program.cs へのロジック記述** — AppBuilder が完了するまで Avalonia API・サードパーティ API は使用できない。構成宣言以外を書かない
- **App.axaml.cs への DI 登録べた書き** — 登録の実体は `ApplicationExtensions.cs` に集約し、App は宣言列挙のみとする(mvvm-4)
- **`desktop.Exit` にホスト停止を接続しない** — BackgroundService や ログのフラッシュが走らないままプロセスが終了する
- **ライフタイム分岐を各所に散らす** — `ApplicationLifetime` の型判定は `OnFrameworkInitializationCompleted` の1箇所に限定する
