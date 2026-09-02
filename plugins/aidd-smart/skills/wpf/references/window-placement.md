# ウィンドウ配置の永続化

| 項目 | 内容 |
|---|---|
| ID | wpf-2 |
| 分類 | wpf |
| 関連 | wpf-1(WindowManager) / config-4(設定クラスの配置) / avalonia-1(Avalonia 側の相当処理) |

## 目的

メインウィンドウの位置・サイズ・最大化状態をユーザ毎に保存し、次回起動時に復元する。

- 保存は .NET 標準の `ApplicationSettingsBase`(user.config)を使い、独自のファイル管理を持たない
- 保存・復元のロジックは WindowManager(wpf-1)に集約し、App / ViewModel には書かない

## 標準形

### WindowSettings : ApplicationSettingsBase

`Settings/WindowSettings.cs` に、配置を表す POCO(`MainWindowPlacement`)と設定クラスを同居させる。プロパティには `[UserScopedSetting]` を付与し、ユーザスコープ(user.config)に保存する。

```csharp
namespace Template.App.Settings;

using System.Configuration;

public sealed class MainWindowPlacement
{
    public int Left { get; set; }

    public int Top { get; set; }

    public int Width { get; set; }

    public int Height { get; set; }

    public bool Maximized { get; set; }
}

public sealed class WindowSettings : ApplicationSettingsBase
{
    [UserScopedSetting]
    public MainWindowPlacement? MainWindowPlacement
    {
        get => (MainWindowPlacement)this[nameof(MainWindowPlacement)];
        set => this[nameof(MainWindowPlacement)] = value;
    }
}
```

### 復元と保存(WindowManager 側)

初回起動(保存値なし)は XAML 既定のサイズをそのまま使う。復元は表示前、保存はクローズ時に行う(wpf-1 の `Load` / `Save` 参照)。

```csharp
// 復元(Load 内)
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

// 保存(Save 内)
settings.MainWindowPlacement = new MainWindowPlacement
{
    Left = (int)mainWindow.Left,
    Top = (int)mainWindow.Top,
    Width = (int)mainWindow.Width,
    Height = (int)mainWindow.Height,
    Maximized = mainWindow.WindowState == WindowState.Maximized
};

settings.Save();
```

保存の呼び出しは Closing トリガーから `WindowManager.Save` をバインド経由で呼ぶ(wpf-1)。Busy 中は保存もクローズも抑止される。

## 配置ルール

| 対象 | 場所 |
|---|---|
| `WindowSettings` + `MainWindowPlacement` | `Settings/WindowSettings.cs`(config-4: アプリ設定は `Settings/` 配下) |
| 復元・保存ロジック | `Views/IWindowManager.cs` の `WindowManager`(wpf-1) |

appsettings.json 系の設定クラス(`<セクション>Setting` → config-1)とは役割が異なる。`WindowSettings` は**ユーザ毎に書き戻す状態**であり、読み取り専用のアプリ構成とは分離して扱う。

## バリエーションと使い分け

- **保存項目の追加**: グリッド列幅・スプリッタ位置等も保存する場合は `MainWindowPlacement` と同様の POCO + `[UserScopedSetting]` プロパティを `WindowSettings` に追加する
- **複数ウィンドウ**: 子ウィンドウ(wpf-1)の配置も保存する場合はウィンドウ毎のプロパティを追加し、保存・復元は WindowManager の対応メソッドに置く
- **Avalonia**: `ApplicationSettingsBase` は使わず、JSON ベースのユーザ設定ストアに `WindowPlacement`(X/Y/Width/Height/Maximized)を保存する同型のパターンとする(avalonia-1)

## アンチパターン

- **App.xaml.cs / code-behind への保存ロジックべた書き** — 復元・保存は WindowManager に集約する(wpf-1)
- **Busy 中の保存・クローズ許可** — 実行中の状態で保存されると中途半端な配置が残る。`CancelEventAction` + `BusyState` で抑止する(wpf-1)
- **最大化状態のまま Left/Top/Width/Height を保存する** — 最大化時の座標を素で保存すると復元が壊れる。`Maximized` フラグを分けて保持する
- **appsettings.json への書き戻し** — アプリ構成ファイルはデプロイ単位・読み取り専用。ユーザ状態は user.config(`ApplicationSettingsBase`)に分離する
