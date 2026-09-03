# 組込みの実行形態

| 項目 | 内容 |
|---|---|
| ID | avalonia-3 |
| 分類 | avalonia |
| 関連 | avalonia-1(起動とライフタイム分岐) / avalonia-2(入力抽象化) / deploy-2(systemd unit) / deploy-3(発行スクリプト) / config-2(設定バインド) |

## 目的

Linux 組込み機器(パネル PC・キオスク等)で全画面動作する Avalonia アプリの実行形態を定義する。

- ルートを Window ではなく **`MainView`(UserControl)** にし、デスクトップ(開発)と DRM 直描画(実機)で同じ UI を使い回す
- Debug ビルドはデスクトップのウィンドウ内で実行し、Release ビルドは `StartLinuxDrm` でディスプレイに直接描画する
- systemd サービスとして常駐する前提で、ホストのシグナル処理・フォント・設定読み込みを調整する

## 標準形

### ルートは MainView(UserControl)

実機にはウィンドウという概念がないため、画面のルートは `UserControl` とする。ナビゲーションのコンテナもここに置く(mvvm-2)。

```xml
<UserControl xmlns="https://github.com/avaloniaui"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:s="http://smart/avalonia"
             xmlns:navigation="http://smart/navigation"
             xmlns:app="clr-namespace:Template.EmbeddedApp"
             x:Class="Template.EmbeddedApp.MainView"
             x:DataType="app:MainViewModel"
             s:DataContextResolver.Type="app:MainViewModel"
             d:DesignWidth="800" d:DesignHeight="480">

    <Canvas navigation:NavigationContainer.Navigator="{Binding Navigator}" />

</UserControl>
```

### Program.cs — Debug はデスクトップ、Release は DRM

Release では Avalonia 起動前に設定を直接読み(config-2 の②即時取得パターン)、DRM デバイスとスケーリングを決定する。

```csharp
public static class Program
{
    [STAThread]
    public static int Main(string[] args)
    {
        var builder = BuildAvaloniaApp();
#if DEBUG
        return builder.StartWithClassicDesktopLifetime(args);
#else
        var configuration = new ConfigurationBuilder()
            .SetBasePath(AppContext.BaseDirectory)
            .AddJsonFile("appsettings.json", optional: true)
            .Build();
        var display = configuration.GetSection("Display").Get<DisplaySetting>() ?? new DisplaySetting();
        return builder.StartLinuxDrm(args, display.Device, display.Scaling);
#endif
    }

    public static AppBuilder BuildAvaloniaApp() =>
        AppBuilder.Configure<App>()
            .UsePlatformDetect()
            .UseSkia()
            .WithInterFont()
            .LogToTrace();
}
```

```csharp
public sealed class DisplaySetting
{
    public string Device { get; set; } = "/dev/dri/cardN";   // 実機のデバイスパスに合わせる

    public double Scaling { get; set; } = 1d;
}
```

ライフタイムの受け側は avalonia-1 のとおり: DRM 実行時は `ISingleViewApplicationLifetime` に `MainView` を設定し、Debug のデスクトップ実行時は `IClassicDesktopStyleApplicationLifetime` に `DebugWindow` を設定する。

### DebugWindow — 開発時のホスト

Debug 実行では `DebugWindow` が実機の画面サイズで `MainView` をホストし、物理キーの模擬ボタンを併設する(avalonia-2)。DI 登録も `#if DEBUG` で限定する。

```csharp
// Window
config.BindSingleton<MainView>();
#if DEBUG
config.BindSingleton<DebugWindow>();
#endif
```

### NopLifetime — ホストのシグナル捕捉を無効化

Generic Host は既定で SIGINT/SIGTERM を捕捉してアプリを停止させようとするが、組込みではライフサイクルの主導権は Avalonia 側にある。`IHostLifetime` を無処理実装に差し替える。

```csharp
public static HostApplicationBuilder ConfigureLifetime(this HostApplicationBuilder builder)
{
    builder.Services.AddSingleton<IHostLifetime, NopLifetime>();

    return builder;
}

private sealed class NopLifetime : IHostLifetime
{
    public Task WaitForStartAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}
```

### フォント同梱

実機の OS にフォントがあることを期待せず、アプリに同梱する。基本は `WithInterFont()`、日本語表示が必要なら埋め込みフォントを `AvaloniaResource` として追加し `FontFamily` で指定する。

### 発行と systemd

- 発行は単一ファイル + self-contained(deploy-3)。`appsettings.*.json` は発行対象から除外する
- systemd unit は `WorkingDirectory=/opt/<app>`、`Restart=always`、`KillSignal=SIGINT` の定石に従う(deploy-2)

```ini
[Service]
WorkingDirectory=/opt/template-embeddedapp
ExecStart=/opt/template-embeddedapp/Template.EmbeddedApp
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=template-embeddedapp
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| `MainView` / `MainViewModel` | プロジェクト直下(ルート画面) |
| `DebugWindow` / `DebugWindowViewModel` | プロジェクト直下(Debug 専用) |
| `DisplaySetting` 等の設定クラス | `Settings/`(config-4) |
| `NopLifetime` | `ApplicationExtensions.cs` 内のネスト型 |
| systemd unit ファイル | リポジトリルート(`<app>.service`) |

## バリエーションと使い分け

- **タッチパネルのみの機器**: `Devices.Input`(avalonia-2)は不要。`MainView` + DRM 起動のみ適用する
- **ウィンドウシステムのある機器(X11/Wayland)**: `StartLinuxDrm` ではなく `StartWithClassicDesktopLifetime` で全画面ウィンドウにする選択肢もある。DRM 直描画はウィンドウシステム自体を持たない構成向け
- **スケーリング**: 液晶の解像度と UI 設計解像度が異なる場合は `DisplaySetting.Scaling` で吸収し、XAML 側は設計解像度で固定する

## アンチパターン

- **ルートを Window にする** — DRM 実行(`ISingleViewApplicationLifetime`)では Window を表示できない。ルートは UserControl とし、Window は Debug 用ホストに限定する
- **NopLifetime を入れずに systemd 常駐させる** — ホストが先にシグナルで停止し、Avalonia 側の終了処理と競合する。停止は systemd → SIGINT → Avalonia 経由で一本化する
- **実機デバイスパス(`/dev/dri/cardN`)のハードコード** — 機種によって番号が変わる。必ず `appsettings.json` から取得する
- **OS 側フォントへの依存** — 実機イメージの構成変更で表示が壊れる。フォントはアプリに同梱する
