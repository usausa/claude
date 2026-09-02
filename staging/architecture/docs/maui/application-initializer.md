# ApplicationInitializer(起動後処理の隔離)

| 項目 | 内容 |
|---|---|
| ID | maui-2 |
| 分類 | maui |
| 関連 | maui-1(MauiProgram 宣言的チェーン) / mvvm-2(Smart.Navigation) / mvvm-3(ResolveProvider) / host-3(起動ログの儀式) |

## 目的

DI コンテナ構築後に必要な起動処理を **`IMauiInitializeService` 実装(`ApplicationInitializer`)に隔離**し、`App.xaml.cs` を薄く保つ。

- 「コンテナ完成後・画面表示前」に走る初期化(プロバイダ設定・設定値の既定化・DB 再構築等)の置き場を1つに固定する
- App は「Window 生成 + 権限要求 + 初期遷移」のみとし、業務的な初期化を持たない
- 前回クラッシュの報告(`CrashReport`)を起動シーケンスに組み込む

## 標準形

### ApplicationInitializer — IMauiInitializeService

MauiProgram で `IMauiInitializeService` として登録すると(maui-1 の Startup 区画)、`MauiApp.Build()` 直後にフレームワークが `Initialize` を呼ぶ。処理順は **ResolveProvider 設定 → Settings 既定値 → Navigator 購読 → DB Rebuild → ApiContext** で固定する。

```csharp
public sealed class ApplicationInitializer : IMauiInitializeService
{
    public async void Initialize(IServiceProvider services)
    {
        // Setup provider(XAML からの VM 解決を有効化 → mvvm-3)
        ResolveProvider.Default.Provider = services;

        // Initial setting(未設定値に既定値を投入)
        var settings = services.GetRequiredService<Settings>();
        if (String.IsNullOrEmpty(settings.UniqueId))
        {
            settings.UniqueId = Guid.NewGuid().ToString();
        }

        // Setup navigator(DEBUG 向け遷移トレース → mvvm-2)
        var navigator = services.GetRequiredService<INavigator>();
        navigator.Navigated += (_, args) =>
        {
            // for debug
            System.Diagnostics.Debug.WriteLine(
                $"Navigated: [{args.Context.FromId}]->[{args.Context.ToId}] : stacked=[{navigator.StackedCount}]");
        };

        // Service(ローカル DB の再構築)
        var dataService = services.GetRequiredService<DataService>();
        await dataService.RebuildAsync();

        // API 接続先の反映
        var apiContext = services.GetRequiredService<ApiContext>();
        if (!String.IsNullOrEmpty(settings.ApiEndPoint))
        {
            apiContext.BaseAddress = new Uri(settings.ApiEndPoint);
        }
    }
}
```

登録は MauiProgram の `ConfigureContainer` 末尾に1行。

```csharp
// Startup
config.BindSingleton<IMauiInitializeService, ApplicationInitializer>();
```

### App.xaml.cs — Window 生成 + 権限要求 + 初期遷移のみ

```csharp
public sealed partial class App
{
    private readonly IServiceProvider serviceProvider;

    public App(IServiceProvider serviceProvider, ILogger<App> log)
    {
        this.serviceProvider = serviceProvider;

        InitializeComponent();

        // Start
        log.InfoApplicationStart(typeof(App).Assembly.GetName().Version, Environment.Version);
    }

    protected override Window CreateWindow(IActivationState? activationState)
    {
        return new Window(serviceProvider.GetRequiredService<MainPage>());
    }

    protected override async void OnStart()
    {
        // Report previous exception
        await CrashReport.ShowReport();

        // Permissions
        await Permissions.RequestCameraAsync();
        await Permissions.RequestLocationAsync();

        // Navigate
        var navigator = serviceProvider.GetRequiredService<INavigator>();
        await navigator.ForwardAsync(ViewId.Menu);
    }
}
```

### CrashReport — 前回クラッシュの記録と表示

未処理例外の捕捉開始は MauiProgram の `ConfigureGlobalSettings()` で行い(`CrashReport.Start()`)、記録されたレポートは次回起動の `App.OnStart` で表示する。捕捉はプラットフォーム毎の partial 実装(maui-4 と同じ分割方式)。

```csharp
public static partial class CrashReport
{
    public static void Start() => PlatformStart();

    private static partial void PlatformStart();

    public static async ValueTask ShowReport()
    {
        var path = ResolveCrashLogPath();
        if (!File.Exists(path))
        {
            return;
        }

        var log = await File.ReadAllTextAsync(path);
        var page = Application.Current?.Windows[0].Page;
        if (page is not null)
        {
            await page.DisplayAlertAsync("Crash report", log, "Close");
        }

        File.Move(path, ResolveOldCrashLogPath(), true);
    }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| `ApplicationInitializer` | プロジェクト直下(App / MauiProgram と同じ階層) |
| `CrashReport` | `Helpers/`(`.android.cs` 等の partial 分割) |
| 権限要求ヘルパ(`Permissions`) | プロジェクト直下 |
| 初期遷移(`ForwardAsync(初期画面)`) | `App.OnStart` の末尾 |

## バリエーションと使い分け

- **Blazor Hybrid(maui-5)**: Navigator が存在しないため、初期化は ResolveProvider 設定 + Settings 既定値 + DB Rebuild + ApiContext のみ。`OnStart` の初期遷移も不要(ルーティングは Blazor 側)
- 起動時に必ず完了している必要がある初期化(DB マイグレーション等)と、遅延可能な初期化(バックグラウンド同期)を分け、後者は `Initialize` に入れず画面側・サービス側で行う
- 権限要求は初期画面の表示前にまとめて行う形を標準とするが、機能利用時要求に切り替えてもよい(ストア審査要件に応じて)

## アンチパターン

- **App コンストラクタでの業務初期化** — App は生成タイミング・例外時の挙動が制御しにくい。初期化は `ApplicationInitializer` に寄せる
- **MauiProgram のチェーン内での初期化実行** — チェーンは構成の宣言のみ(maui-1)。「実行」が必要な処理は `IMauiInitializeService` に置く
- **初期化処理の散在** — 「どこまで終わっていれば画面を出してよいか」が追えなくなる。順序に意味がある初期化は `Initialize` 内に一列で書く
- **クラッシュレポートの握りつぶし** — 前回異常終了の情報は必ず次回起動で表示(または送信)し、現場での不具合解析手段を確保する
