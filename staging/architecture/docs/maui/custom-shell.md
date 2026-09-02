# 自前 Shell(共通ヘッダ・ファンクションキー)

| 項目 | 内容 |
|---|---|
| ID | maui-3 |
| 分類 | maui |
| 関連 | mvvm-2(Smart.Navigation) / mvvm-5(Modules 構成) / namespace-7(`Shell` の語彙) / avalonia-2(組込みの入力抽象化 — 同じ発想の Avalonia 版) |

## 目的

MAUI 標準の Shell を使わず、**単一 `MainPage` 上に共通ヘッダ・ビューコンテナ・ファンクションキーを持つ自前シェル**を構築する。

- 業務端末(ハンディ・POS 等)で必要な「画面共通のヘッダ + 物理/画面ファンクションキー」を、各画面の XAML から**宣言的に**制御する
- キー押下は `ShellEvent` に正規化して現在画面の ViewModel に配送する。画面側は virtual メソッドのオーバーライドで応答する
- 開発時は FPS・GC 等を表示する `DiagnosticPanel` をシェルに組み込む

## 標準形

`Shell/` フォルダに次の部品を置く。

| 部品 | 役割 |
|---|---|
| `IShellControl` | シェルが公開する状態(タイトル・キー表示/活性)の契約 |
| `ShellEvent` | キーイベントの正規化 enum(Back / Function1-4) |
| `ShellProperty` | 各画面が宣言する attached BindableProperty 群 |
| `ShellUpdateBehavior` | 画面遷移時に View の宣言をシェルへ反映する Behavior |
| `DiagnosticPanel` | 開発用診断パネル(FPS / CPU / GC / メモリ) |

### IShellControl / ShellEvent

```csharp
public interface IShellControl
{
    string Title { get; set; }

    bool HeaderVisible { get; set; }

    bool FunctionVisible { get; set; }

    string Function1Text { get; set; }
    // Function2-4 も同様

    bool Function1Enabled { get; set; }
    // Function2-4 も同様
}

public enum ShellEvent
{
    Back,
    Function1,
    Function2,
    Function3,
    Function4
}
```

### ShellProperty — 画面側の宣言(attached property)

各画面はヘッダタイトルやキーの表示・活性を XAML の属性で宣言するだけでよい。

```csharp
public static class ShellProperty
{
    public static readonly BindableProperty TitleProperty = BindableProperty.CreateAttached(
        "Title",
        typeof(string),
        typeof(ShellProperty),
        null,
        propertyChanged: PropertyChanged);

    public static string GetTitle(BindableObject bindable) => (string)bindable.GetValue(TitleProperty);

    public static void SetTitle(BindableObject bindable, string value) => bindable.SetValue(TitleProperty, value);

    // HeaderVisible / FunctionVisible / FunctionNText / FunctionNEnabled も同型

    public static void UpdateShellControl(IShellControl shell, BindableObject? bindable)
    {
        if (bindable is null)
        {
            shell.Title = string.Empty;
            shell.HeaderVisible = true;
            shell.FunctionVisible = false;
            // 以降、既定値へリセット
        }
        else
        {
            shell.Title = GetTitle(bindable);
            shell.HeaderVisible = GetHeaderVisible(bindable);
            shell.FunctionVisible = GetFunctionVisible(bindable);
            shell.Function1Text = GetFunction1Text(bindable);
            shell.Function1Enabled = GetFunction1Enabled(bindable);
            // Function2-4 も同様
        }
    }
}
```

```xml
<!-- 各画面(Modules/ 配下の View)はヘッダとキーを属性で宣言する -->
<ContentView x:Class="Template.MobileApp.Modules.Main.SettingView"
             shell:ShellProperty.Title="Setting"
             shell:ShellProperty.Function1Text="Back"
             shell:ShellProperty.Function1Enabled="True">
```

### ShellUpdateBehavior — 遷移時の反映

Navigator の `Navigating` を購読し、遷移先 View の宣言を `MainPageViewModel`(= `IShellControl` 実装)へ反映する。

```csharp
public sealed class ShellUpdateBehavior : BehaviorBase<ContentPage>
{
    public INavigator? Navigator { get; set; }   // BindableProperty(略)

    private void NavigatorOnNavigating(object? sender, NavigationEventArgs e)
    {
        UpdateShell(e.ToView as Element);
    }

    private void UpdateShell(BindableObject? view)
    {
        if (AssociatedObject?.BindingContext is IShellControl shell)
        {
            ShellProperty.UpdateShellControl(shell, view);
        }
    }
}
```

### MainPage — シェルの実体

ヘッダ・ビューコンテナ・ファンクションキーの3段 Grid。ビューコンテナには Smart.Navigation のコンテナ Behavior を付ける(mvvm-2)。

```xml
<ContentPage x:Class="Template.MobileApp.MainPage"
             s:BindingContextResolver.Type="{x:Type local:MainPageViewModel}">

    <ContentPage.Behaviors>
        <shell:ShellUpdateBehavior Navigator="{Binding Navigator, Mode=OneTime}" />
    </ContentPage.Behaviors>

    <Grid RowDefinitions="Auto,*,Auto">
        <!-- overlay(BusyState 中の操作抑止) -->
        <Rectangle Grid.RowSpan="3"
                   shell:ShellProperty.BusyOverlay="True"
                   IsVisible="{Binding BusyState.IsBusy}" />

        <!-- header -->
        <Grid Grid.Row="0" IsVisible="{Binding HeaderVisible}">
            <Label Text="{Binding Title}" />
        </Grid>

        <!-- diagnostic -->
        <shell:DiagnosticPanel Grid.Row="1" IsVisible="{Binding DiagnosticVisible}" />

        <!-- view container -->
        <AbsoluteLayout Grid.Row="1">
            <AbsoluteLayout.Behaviors>
                <navigation:NavigationContainerBehavior Navigator="{Binding Navigator}" />
            </AbsoluteLayout.Behaviors>
        </AbsoluteLayout>

        <!-- function -->
        <Grid Grid.Row="2" ColumnDefinitions="*,*,*,*" IsVisible="{Binding FunctionVisible}">
            <Button Grid.Column="0" Command="{Binding Function1Command}" Text="{Binding Function1Text}" />
            <!-- Function2-4 も同様 -->
        </Grid>
    </Grid>

</ContentPage>
```

`MainPageViewModel` は `IShellControl` を実装し、キー押下を `Navigator.NotifyAsync(ShellEvent.Xxx)` で現在画面へ配送する。

```csharp
public sealed partial class MainPageViewModel : ExtendViewModelBase, IShellControl
{
    public INavigator Navigator { get; }

    [ObservableProperty]
    public partial string Title { get; set; } = default!;
    // HeaderVisible / FunctionVisible / FunctionNText / FunctionNEnabled も [ObservableProperty]

    public IObserveCommand Function1Command { get; }

    public MainPageViewModel(INavigator navigator)
    {
        Navigator = navigator;
        Function1Command = MakeAsyncCommand(() => Navigator.NotifyAsync(ShellEvent.Function1), () => Function1Enabled);
    }
}
```

### 画面側の応答 — ViewModel 基底クラス

`INotifySupportAsync<ShellEvent>` を基底クラスで実装し、各画面は必要なキーのみオーバーライドする(avalonia-2 の `NavigationEvent` と同型)。

```csharp
public abstract class AppViewModelBase : ExtendViewModelBase, INavigatorAware, INotifySupportAsync<ShellEvent>
{
    public INavigator Navigator { get; set; } = default!;

    public async Task NavigatorNotifyAsync(ShellEvent parameter)
    {
        var task = parameter switch
        {
            ShellEvent.Back => OnNotifyBackAsync(),
            ShellEvent.Function1 => OnNotifyFunction1(),
            ShellEvent.Function2 => OnNotifyFunction2(),
            ShellEvent.Function3 => OnNotifyFunction3(),
            ShellEvent.Function4 => OnNotifyFunction4(),
            _ => Task.CompletedTask
        };

        await task.ConfigureAwait(true);
    }

    protected virtual Task OnNotifyBackAsync() => Task.CompletedTask;

    protected virtual Task OnNotifyFunction1() => Task.CompletedTask;
    // Function2-4 も同様
}
```

物理キー(Android の Back キー・ハード Function キー)は `Platforms/Android/MainActivity` 等でフックし、同じ `ShellEvent` に変換して `NotifyAsync` に流す。

## 配置ルール

| 対象 | 場所 |
|---|---|
| `IShellControl` / `ShellEvent` / `ShellProperty` / `ShellUpdateBehavior` / `DiagnosticPanel` | `Shell/`(namespace-7) |
| `MainPage` / `MainPageViewModel` | プロジェクト直下(シェルの実体) |
| `AppViewModelBase` | `Modules/` 直下(namespace-7) |
| 各画面のヘッダ・キー宣言 | 各 View の XAML 属性(`shell:ShellProperty.*`) |

## バリエーションと使い分け

- **一般的なモバイルアプリ**(タブ・フライアウトが欲しい場合)は MAUI 標準 Shell やタブ UI を使ってよい。自前 Shell は「全画面共通のヘッダ+ファンクションキー」という業務端末型 UI 向け
- ファンクションキー数は端末に合わせて増減する(`ShellEvent` と Grid 列を対で変更)
- `DiagnosticPanel` は DEBUG のみ表示トグルを有効にする(`#if DEBUG` で `DiagnosticEnabled = true`)

## アンチパターン

- **各画面がシェル(MainPageViewModel)を直接参照して書き換える** — 画面はシェルの存在を知らない。宣言は attached property、応答は `ShellEvent` 経由に限定する
- **キー処理を View のイベントハンドラに書く** — キーの意味は画面の ViewModel が持つ。`ShellEvent` → virtual メソッドの経路に一本化する
- **画面毎にヘッダ・キー UI を複製する** — シェル UI は MainPage の1箇所のみ。画面側は宣言だけを持つ
- **BusyState 中の操作抑止を画面毎に実装する** — オーバーレイ(`ShellProperty.BusyOverlay`)でシェルが一括して抑止する
