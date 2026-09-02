# WindowManager(用途限定)

| 項目 | 内容 |
|---|---|
| ID | wpf-1 |
| 分類 | wpf |
| 関連 | mvvm-2(Smart.Navigation) / mvvm-4(クライアント起動ハブ) / wpf-2(ウィンドウ配置永続化) / mvvm-1(BusyState) |

## 目的

**画面遷移を持つアプリは WPF でも Smart.Navigation を使用する(mvvm-2、決定)。WindowManager はツール的に子ウィンドウを管理するケースで使用する** — 業務フローの画面遷移をウィンドウの開閉で表現しない。

- メインウィンドウの生成・表示・配置復元(wpf-2)と、ツール的な子ウィンドウの開閉を `IWindowManager` に集約する
- App / ViewModel はウィンドウ型を直接 `new` せず、WindowManager 経由で扱う

## 標準形

### IWindowManager + WindowManager(同一ファイル)

`Views/IWindowManager.cs` にインターフェースと実装を同居させる。ウィンドウは DI(mvvm-3)から解決し、配置の保存・復元は `WindowSettings`(wpf-2)に委譲する。

```csharp
namespace Template.App.Views;

public interface IWindowManager
{
    Window Load();

    void Save();
}

public sealed class WindowManager : NotificationObject, IWindowManager
{
    private readonly IServiceProvider provider;

    private readonly WindowSettings settings = new();

    public WindowManager(IServiceProvider provider)
    {
        this.provider = provider;
    }

    public Window Load()
    {
        var mainWindow = provider.GetRequiredService<MainWindow>();

        if (settings.MainWindowPlacement is not null)
        {
            mainWindow.Left = settings.MainWindowPlacement.Left;
            mainWindow.Top = settings.MainWindowPlacement.Top;
            mainWindow.Width = settings.MainWindowPlacement.Width;
            mainWindow.Height = settings.MainWindowPlacement.Height;
            if (settings.MainWindowPlacement.Maximized)
            {
                mainWindow.WindowState = WindowState.Maximized;
            }
        }

        mainWindow.Show();

        return mainWindow;
    }

    public void Save()
    {
        var mainWindow = provider.GetRequiredService<MainWindow>();

        settings.MainWindowPlacement = new MainWindowPlacement
        {
            Left = (int)mainWindow.Left,
            Top = (int)mainWindow.Top,
            Width = (int)mainWindow.Width,
            Height = (int)mainWindow.Height,
            Maximized = mainWindow.WindowState == WindowState.Maximized
        };

        settings.Save();
    }
}
```

DI 登録は `ConfigureContainer(ResolverConfig)` に置く(mvvm-3)。

```csharp
// Window
config.BindSingleton<IWindowManager, WindowManager>();
config.BindSingleton<MainWindow>();
```

### App のライフサイクル接続

`OnStartup` で `windowManager.Load()`、`OnExit` で `host.StopAsync(5秒)` → `Dispose` とする(mvvm-4)。

```csharp
// ReSharper disable once AsyncVoidEventHandlerMethod
protected override async void OnStartup(StartupEventArgs e)
{
    MainWindow = windowManager.Load();

    await host.StartAsync().ConfigureAwait(true);

    await host.Services.GetRequiredService<INavigator>().ForwardAsync(ViewId.Menu).ConfigureAwait(true);
}

// ReSharper disable once AsyncVoidEventHandlerMethod
protected override async void OnExit(ExitEventArgs e)
{
    await host.StopAsync(TimeSpan.FromSeconds(5)).ConfigureAwait(false);
    host.Dispose();
}
```

### Closing 時の抑止と保存

処理実行中(`BusyState.IsBusy`)のクローズは `CancelEventAction` で抑止し、通常クローズ時のみ `WindowManager.Save` で配置を保存する。破棄は `Closed` の `DataContextDisposeAction` で行う。

```xml
<i:Interaction.Triggers>
    <i:EventTrigger EventName="Closing">
        <s:CancelEventAction Cancel="{Binding BusyState.IsBusy}" />
        <i:CallMethodAction IsEnabled="{Binding BusyState.IsBusy, Converter={StaticResource ReverseConverter}}"
                            MethodName="Save"
                            TargetObject="{Binding WindowManager}" />
    </i:EventTrigger>
    <i:EventTrigger EventName="Closed">
        <s:DataContextDisposeAction />
    </i:EventTrigger>
</i:Interaction.Triggers>
```

ViewModel 側は `IWindowManager` をプロパティとして公開し、バインド経由で `Save` を呼ばせる。

```csharp
public sealed class MainWindowViewModel : ExtendViewModelBase
{
    public IWindowManager WindowManager { get; }

    public INavigator Navigator { get; }

    public MainWindowViewModel(IWindowManager windowManager, INavigator navigator)
    {
        WindowManager = windowManager;
        Navigator = navigator;
    }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| `IWindowManager` + `WindowManager` | `Views/IWindowManager.cs`(同一ファイル) |
| `WindowSettings` / `MainWindowPlacement` | `Settings/WindowSettings.cs`(wpf-2) |
| DI 登録 | `ConfigureContainer(ResolverConfig)`(mvvm-3) |

## バリエーションと使い分け

- **画面遷移 vs 子ウィンドウ**: 業務フロー(一覧→詳細→確認)はシェル内の Smart.Navigation(mvvm-2)。並行して開いておくツール類(ログビューア・設定・モニタ等)のみ WindowManager で子ウィンドウとして管理する
- **子ウィンドウの追加**: 子ウィンドウ管理が必要になったら `IWindowManager` に `ShowXxx()` / `CloseXxx()` を追加し、ウィンドウ型は DI 登録して解決する
- **モーダルダイアログ**: 確認・入力程度のダイアログは WindowManager ではなく `IDialogService` 系のサービスで扱う

## アンチパターン

- **画面遷移をウィンドウ開閉で実装する** — 決定に反する。遷移はシェル + Smart.Navigation(mvvm-2)
- **ViewModel でウィンドウを `new` して `Show()` する** — View への直接依存かつ DI が効かない。ウィンドウ操作は `IWindowManager` を介す
- **`OnExit` でのホスト即時破棄** — `StopAsync(タイムアウト)` を経ないとバックグラウンド処理の graceful shutdown が効かない
- **Busy 中クローズの放置** — 実行中にウィンドウを閉じられると処理が中断される。`CancelEventAction` + `BusyState` で抑止する
