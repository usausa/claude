# Smart.Mvvm 基盤

| 項目 | 内容 |
|---|---|
| ID | mvvm-1 |
| 分類 | mvvm |
| 関連 | mvvm-2(Smart.Navigation) / mvvm-3(DI コンテナ差し替え) / mvvm-5(Modules 構成) / namespace-7(クライアント名前空間) / guideline-2(非同期作法) |

## 目的

XAML 系クライアント(WPF / Avalonia / MAUI)の ViewModel 実装基盤を **Smart.Mvvm に統一する**。

- 変更通知・コマンド・ビジー状態・リソース破棄・メッセージングを1つの基底クラス(`ExtendViewModelBase`)に集約し、ViewModel の書き方をプラットフォーム間で同一にする
- 変更通知プロパティはソースジェネレータ(`[ObservableProperty]` + partial プロパティ)で生成し、手書きの `INotifyPropertyChanged` 実装を排除する
- **MVVM 基盤としての CommunityToolkit.Mvvm は明示的に排除する**。基盤が混在すると変更通知・コマンドの流儀が二重化するため、Smart.Mvvm に一本化する

## 標準形

### アプリ共通の ViewModel 基底

アプリ毎に `ExtendViewModelBase` を継承した基底クラスを1つ定義し、ナビゲーション連携(mvvm-2)等の横断機能を持たせる。`[ObservableGeneratorOption]` はこの基底に付与し、派生クラス全体の生成方式(Reactive / ViewModel)を固定する。

```csharp
namespace Template.App.Modules;

[ObservableGeneratorOption(Reactive = true, ViewModel = true)]
public abstract class AppViewModelBase : ExtendViewModelBase, INavigatorAware, INavigationEventSupport
{
    public INavigator Navigator { get; set; } = default!;

    public void OnNavigatingFrom(INavigationContext context)
    {
    }

    public void OnNavigatingTo(INavigationContext context)
    {
    }

    public void OnNavigatedTo(INavigationContext context)
    {
    }
}
```

### 画面 ViewModel

変更通知プロパティは `[ObservableProperty]` + `partial` プロパティで宣言する。コマンドは `MakeDelegateCommand` / `MakeAsyncCommand` ファクトリで生成し、プロパティとして公開する。

```csharp
namespace Template.App.Modules.Main;

public sealed partial class MenuViewModel : AppViewModelBase
{
    [ObservableProperty]
    public partial string Message { get; set; }

    public ICommand NavigateCommand { get; }

    public MenuViewModel(GreetService greetService)
    {
        Message = greetService.MakeMessage();
        NavigateCommand = MakeDelegateCommand(() => Navigator.Forward(ViewId.Sub));
    }
}
```

### BusyState — 実行中ガード

時間のかかる処理は `MakeAsyncCommand` とし、`BusyState` で多重実行を抑止する。View 側は `BusyState.IsBusy` をプログレス表示やクローズ抑止(wpf-1)にバインドする。

```csharp
public sealed partial class MainViewModel : AppViewModelBase
{
    public ICommand ExecuteCommand { get; }

    public MainViewModel()
    {
        ExecuteCommand = MakeAsyncCommand(Execute, () => !BusyState.IsBusy);
    }

    private async Task Execute()
    {
        // 実行中は BusyState.IsBusy が true になり再実行が抑止される
        await Task.Delay(3000).ConfigureAwait(true);
    }
}
```

### Disposables — 購読の寿命管理

イベント購読や Observable の購読は `Disposables` に登録し、ViewModel の破棄と同時に解放する。View 側の破棄タイミング(WPF なら `Closed` の `DataContextDisposeAction` 等)で `Dispose` が呼ばれる。

```csharp
public sealed partial class SensorViewModel : AppViewModelBase
{
    [ObservableProperty]
    public partial double Value { get; set; }

    public SensorViewModel(ISensorService sensorService)
    {
        Disposables.Add(sensorService.ReadingChangedAsObservable()
            .ObserveOnCurrentContext()
            .Subscribe(x => Value = x.Reading));
    }
}
```

### IReactiveMessenger — 疎結合メッセージング

ViewModel 間・サービスからの通知は `IReactiveMessenger` を介する。DI には既定インスタンスを Singleton で登録する(mvvm-3)。

```csharp
// DI 登録(ConfigureContainer 内)
config.BindSingleton<IReactiveMessenger>(ReactiveMessenger.Default);
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| アプリ共通の ViewModel 基底(`AppViewModelBase`) | `Modules/` 直下(mvvm-5)。`Views/` 平置き構成では `Views/` 直下 |
| 画面 ViewModel | View と同居(`Modules/<機能>/`) |
| Smart.Mvvm 系の global using(`Smart.Mvvm` / `Smart.Mvvm.Messaging` 等) | `GlobalUsing.cs`(structure-5) |

## バリエーションと使い分け

- **`MakeDelegateCommand` / `MakeAsyncCommand`**: 同期の軽い操作(画面遷移・値の設定)は `MakeDelegateCommand`、I/O や待ちを伴う処理は `MakeAsyncCommand` + `BusyState` ガードとする
- **ナビゲーションイベントの同期/非同期**: デスクトップ系は `INavigationEventSupport`(同期)、モバイル系は `INavigationEventSupportAsync`(非同期)を基底に実装する
- **Blazor Hybrid(maui-5)**: Smart.Mvvm の ViewModel は使わず `AppComponentBase`(Execute + BusyState)方式に置き換える

## アンチパターン

- **CommunityToolkit.Mvvm の導入** — `[ObservableProperty]` フィールド方式や `[RelayCommand]` が混在し、変更通知・コマンドの流儀が二重化する。明示的に排除する
- **手書きの `INotifyPropertyChanged` 実装** — `SetProperty` のボイラープレートはジェネレータで生成できる。`[ObservableProperty]` + partial プロパティに統一する
- **コマンド処理を `async void` で書く** — 例外が捕捉できない。`MakeAsyncCommand` に Task 返却メソッドを渡す(guideline-2)
- **購読解除の書き忘れ** — イベント・Observable の購読を素で行うとリークする。必ず `Disposables` に登録する
- **ViewModel から View への直接参照** — フォーカス移動等の命令は `Messaging` のコントローラを介す(namespace-7)
