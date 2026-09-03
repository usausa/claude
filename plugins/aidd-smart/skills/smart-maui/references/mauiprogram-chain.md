# MauiProgram 宣言的チェーン

| 項目 | 内容 |
|---|---|
| ID | maui-1 |
| 分類 | maui |
| 関連 | mvvm-3(DI コンテナ差し替え) / mvvm-4(クライアント起動ハブ) / host-1(Program.cs の構成 — サーバ版の同型) / host-4(DI 登録スタイル) / maui-2(ApplicationInitializer) |

## 目的

`MauiProgram.CreateMauiApp()` を **`ConfigureXxx()` / `UseXxx()` の宣言列挙1本のチェーン**に固定する(host-1 のクライアント版)。

- 何を構成しているかがチェーンを読むだけで分かる。実体は private static 拡張メソッドに切り出し、区切りコメントでセクション化する
- DI 登録は `ConfigureContainer(ResolverConfig)` の1箇所に集約し、登録順をレイヤ順で固定する
- Debug 専用・プラットフォーム専用の構成も各拡張メソッドの内側に閉じ込め、チェーン本体を分岐させない

## 標準形

### CreateMauiApp — チェーン1本

```csharp
public static partial class MauiProgram
{
    public static MauiApp CreateMauiApp() =>
        MauiApp.CreateBuilder()
            .UseMauiApp<App>()
            .ConfigureDebug()
            .ConfigureFonts(ConfigureFonts)
            .ConfigureLifecycleEvents(ConfigureLifecycleEvents)
            .ConfigureEssentials(ConfigureEssentials)
            .ConfigureLogging()
            .ConfigureGlobalSettings()
            .UseSkiaSharp()
            .UseMauiCommunityToolkit(ConfigureMauiCommunityToolkit)
            .UseMauiServices()
            .UseMauiComponents()
            .UseCustomView()
            .ConfigureComponents()
            .ConfigureHttpClient()
            .ConfigureContainer()
            .Build();
}
```

使用ライブラリ(バーコード・地図・PDF 等)の `UseXxx()` はプロジェクトに応じて増減するが、**チェーンに1行足すだけ**という形式は変えない。

### 実体は private static 拡張メソッド + 区切りコメント

```csharp
// ------------------------------------------------------------
// Logging
// ------------------------------------------------------------

private static MauiAppBuilder ConfigureLogging(this MauiAppBuilder builder)
{
    // Debug
#if DEBUG
    builder.Logging.AddDebug();
#endif

    // Android
#if ANDROID
    builder.Logging.AddAndroidLogger(static options => options.ShortCategory = true);
#endif
    // File
    builder.Logging.AddFileLogger(static options =>
        {
#if ANDROID
            options.Directory = Path.Combine(AndroidHelper.GetExternalFilesDir(), "log");
#endif
            options.RetainDays = 7;
        })
        .AddFilter(typeof(MauiProgram).Namespace, LogLevel.Debug);

    return builder;
}
```

`#if DEBUG` / `#if ANDROID` の分岐は拡張メソッドの内側に閉じ、チェーン本体には現れない。

### ConfigureContainer — DI 登録の一元化と登録順

コンテナは Smart.Resolver に差し替え(mvvm-3)、登録順を **Components → Messenger → Navigator → State → Service → Usecase → Startup** のレイヤ順で固定する(host-4 と同じ「登録順=レイヤ順」の思想)。

```csharp
private static MauiAppBuilder ConfigureContainer(this MauiAppBuilder builder)
{
    builder.ConfigureContainer(new SmartServiceProviderFactory(), ConfigureContainer);

    return builder;
}

private static void ConfigureContainer(ResolverConfig config)
{
    config
        .UseAutoBinding()
        .UseArrayBinding()
        .UseAssignableBinding()
        .UsePropertyInjector()
        .UsePageContextScope();

    // Components
    config.AddComponentsDialog(static c => ConfigureDialogDesign(c));
    config.AddComponentsPopup(static c => c.AutoRegister(DialogSource()));
    config.AddComponentsScreen();
    config.AddComponentsLocation();

    // Messenger
    config.BindSingleton<IReactiveMessenger>(ReactiveMessenger.Default);

    // Navigator
    config.AddNavigator(static c =>
    {
        c.UseMauiNavigationProvider();
        c.AddResolverPlugin();
        c.UseIdViewMapper(static m => m.AutoRegister(ViewSource()));
    });

    // Components(プラットフォーム機能ラッパ → maui-4)
    config.BindSingleton<IStorageManager, StorageManager>();
    config.BindSingleton<INfcReader, NfcReader>();
    config.BindSingleton<IOcrReader, OcrReader>();

    // State
    config.BindSingleton<DeviceState>();
    config.BindSingleton<Session>();
    config.BindSingleton<Settings>();

    // Service
    config.BindSingleton<DataService>();
    config.BindSingleton<HttpService>();

    // Usecase
    config.BindSingleton<OrderUsecase>();

    // Startup
    config.BindSingleton<IMauiInitializeService, ApplicationInitializer>();
}
```

### View / Dialog の自動登録

画面登録はソースジェネレータの `[ViewSource]` / `[PopupSource]` partial メソッドで宣言し、手動登録リストを持たない(mvvm-2)。

```csharp
// ------------------------------------------------------------
// View & Dialog
// ------------------------------------------------------------

[ViewSource]
public static partial IEnumerable<KeyValuePair<ViewId, Type>> ViewSource();

[PopupSource]
public static partial IEnumerable<KeyValuePair<DialogId, Type>> DialogSource();
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| チェーン本体 + 各 `ConfigureXxx` 拡張メソッド | `MauiProgram.cs`(`public static partial class`) |
| DI 登録 | `MauiProgram.ConfigureContainer(ResolverConfig)` の1箇所 |
| 起動後処理 | `ApplicationInitializer.cs`(maui-2)。MauiProgram には登録行のみ置く |
| グローバル設定(シリアライザ・SqlMapper 等) | `ConfigureGlobalSettings()` 内 |

## バリエーションと使い分け

- **Blazor Hybrid 構成(maui-5)**: `UseBlazor()`(`AddMauiBlazorWebView` 等)がチェーンに加わり、Navigator 登録が不要になる。形式は同一
- **セクション区切り**: MauiProgram では `// ---- 60桁 ----` 帯形式を使う。Debug / Logging / Application / Design / Components / View & Dialog が標準の区画
- サーバ系の `ApplicationExtensions.cs`(host-1)・Avalonia の `ApplicationExtensions.cs`(mvvm-4)と役割は同じ。MAUI では `MauiAppBuilder` 拡張として MauiProgram 内に置く点だけが異なる

## アンチパターン

- **CreateMauiApp へのべた書き** — 登録・設定のロジックをチェーンに直接書かない。必ず拡張メソッドに切り出す
- **DI 登録の分散** — `builder.Services.AddXxx` を各所に散らさない。登録は `ConfigureContainer` に集約し、登録順=レイヤ順を保つ
- **チェーン本体の `#if` 分岐** — プラットフォーム・ビルド構成の分岐は拡張メソッドの内側に閉じ込める
- **画面の手動登録** — `ViewId` と View の対応表を手書きしない。`[ViewSource]` の自動登録に任せ、登録漏れを構造的に防ぐ
