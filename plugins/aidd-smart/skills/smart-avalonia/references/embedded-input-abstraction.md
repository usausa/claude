# 組込みの入力抽象化

| 項目 | 内容 |
|---|---|
| ID | avalonia-2 |
| 分類 | avalonia |
| 関連 | avalonia-3(組込みの実行形態) / namespace-7(`Devices.Input` の語彙) / mvvm-2(Smart.Navigation) / maui-3(自前 Shell — 同じ発想の MAUI 版) |

## 目的

物理ボタン・GPIO・ゲームパッド等の入力デバイスを持つ組込みアプリで、**入力の発生源と画面側の処理を分離する**。

- デバイスは `IInputDevice` に抽象化し、実機がなくても `DebugInputDevice` で開発・デバッグできるようにする
- 物理キーは `NavigationEvent`(Back / Forward)に正規化してから ViewModel に届ける。ViewModel はどのデバイスから来たかを知らない
- 各画面の応答は基底クラスの virtual メソッド(`OnNavigationBackAsync` / `OnNavigationForwardAsync`)のオーバーライドで宣言的に書く

## 標準形

### IInputDevice — デバイス抽象

デバイスは「キーイベントを発生させるもの」とだけ定義する。キーは enum(`InputKey`)。

```csharp
public interface IInputDevice
{
    event EventHandler<EventArgs<InputKey>> Handle;
}
```

実装はデバイス毎に用意する。デバッグ実装は UI から発火できる `Trigger` を持つ。

```csharp
public sealed class DebugInputDevice : IInputDevice
{
    public event EventHandler<EventArgs<InputKey>>? Handle;

    public void Trigger(InputKey key)
    {
        Handle?.Invoke(this, new EventArgs<InputKey>(key));
    }
}

// 実機実装の例(ゲームパッド)。GPIO 実装も同型
public sealed class PadInputDevice : IInputDevice, IDisposable
{
    public event EventHandler<EventArgs<InputKey>>? Handle;

    private readonly GamepadController controller = new();

    public PadInputDevice()
    {
        controller.ButtonChanged += (_, args) =>
        {
            if (!args.Pressed)
            {
                var key = args.Button switch
                {
                    0 => InputKey.Button1,
                    1 => InputKey.Button2,
                    _ => InputKey.Unknown
                };
                Handle?.Invoke(this, new EventArgs<InputKey>(key));
            }
        };
    }

    public void Dispose() => controller.Dispose();
}
```

### DI 登録 — `#if DEBUG` で差し替え

デバッグはビルド時、実機のデバイス種別は設定で切り替える。切り替えは DI 登録の1箇所に閉じ込める。

```csharp
// Device
#if DEBUG
config.BindSingleton<DebugInputDevice>();
config.BindSingleton<IInputDevice>(static p => p.GetRequiredService<DebugInputDevice>());
#else
if (String.Equals(configuration.GetSection("Input").GetValue<string>("Type"), "Gpio", StringComparison.OrdinalIgnoreCase))
{
    config.BindSingleton<IInputDevice, GpioInputDevice>();
}
else
{
    config.BindSingleton<IInputDevice, PadInputDevice>();
}
#endif
```

`DebugInputDevice` を自身の型でも登録するのは、`DebugWindowViewModel` が `Trigger` を呼ぶためである。

### NavigationEvent への正規化

物理キーの意味付け(どのボタンが Back か)はルート ViewModel の1箇所で行い、`Navigator.NotifyAsync` で現在画面の ViewModel に配送する(mvvm-2)。

```csharp
public enum NavigationEvent
{
    Back,
    Forward
}

public class MainViewModel : ExtendViewModelBase
{
    public Navigator Navigator { get; set; }

    public MainViewModel(Navigator navigator, IInputDevice input)
    {
        Navigator = navigator;

        Disposables.Add(Observable
            .FromEvent<EventHandler<EventArgs<InputKey>>, EventArgs<InputKey>>(static h => (_, e) => h(e), h => input.Handle += h, h => input.Handle -= h)
            .ObserveOn(SynchronizationContext.Current!)
            .Subscribe(async void (x) =>
            {
                switch (x.Data)
                {
                    case InputKey.Button1:
                        await Navigator.NotifyAsync(NavigationEvent.Forward);
                        break;
                    case InputKey.Button2:
                        await Navigator.NotifyAsync(NavigationEvent.Back);
                        break;
                }
            }));
    }
}
```

### 画面側の応答 — ViewModel 基底クラス

`INotifySupportAsync<NavigationEvent>` を基底クラスで実装し、各画面は必要なイベントだけオーバーライドする。

```csharp
public abstract class AppViewModelBase : ExtendViewModelBase, INavigatorAware, INotifySupportAsync<NavigationEvent>
{
    public INavigator Navigator { get; set; } = default!;

    public async Task NavigatorNotifyAsync(NavigationEvent parameter)
    {
        switch (parameter)
        {
            case NavigationEvent.Back:
                await OnNavigationBackAsync();
                break;
            case NavigationEvent.Forward:
                await OnNavigationForwardAsync();
                break;
        }
    }

    protected virtual ValueTask OnNavigationBackAsync() => ValueTask.CompletedTask;

    protected virtual ValueTask OnNavigationForwardAsync() => ValueTask.CompletedTask;
}
```

### DebugWindow — デバッグ実行時のホスト

Debug ビルドでは `DebugWindow` が `MainView` をホストし、ボタンで `DebugInputDevice.Trigger` を呼んで物理キーを模擬する(avalonia-3)。

```xml
<Grid RowDefinitions="32,*">
    <StackPanel Grid.Row="0" Orientation="Horizontal">
        <Button Command="{Binding BackCommand}" Content="Back" />
        <Button Command="{Binding NextCommand}" Content="Next" />
    </StackPanel>
    <app:MainView Grid.Row="1" />
</Grid>
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| `IInputDevice` / `InputKey` / 各デバイス実装 | `Devices/Input/`(namespace-7) |
| `NavigationEvent` | `Shell/` |
| キー→イベントの正規化 | ルート ViewModel(`MainViewModel`) |
| 画面毎の応答 | `Views/` 配下の ViewModel(基底クラスのオーバーライド) |
| `DebugWindow` / `DebugWindowViewModel` | プロジェクト直下(Debug ビルド専用) |

## バリエーションと使い分け

- キー数が多い機器(ファンクションキー付きハンディ等)では `NavigationEvent` を拡張するのではなく、MAUI の `ShellEvent`(Back / Function1-4)型のイベント体系を使う(maui-3 と同型)
- タッチ操作のみのアプリでは本トピックは不要。`Devices.Input` フォルダ自体を作らない(namespace-7)
- デバイス種別が1つに固定されている機器では設定による切り替えを省略し、`#if DEBUG` の2分岐のみとする

## アンチパターン

- **ViewModel が実デバイス(GPIO / パッド)を直接参照する** — デバッグ不能になり、機種変更が全画面に波及する。参照は `IInputDevice` に限定する
- **各画面がキーコード(`InputKey`)を判定する** — キーの意味付けはルートの1箇所で行い、画面には正規化済みイベントのみ渡す
- **`#if DEBUG` をアプリ本体のロジックに散らす** — 差し替えは DI 登録の1箇所に閉じ込める
- **入力イベントを UI スレッドに載せずに画面遷移する** — `ObserveOn(SynchronizationContext.Current)` を挟んでから `Navigator` を呼ぶ
