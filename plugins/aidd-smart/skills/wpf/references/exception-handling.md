# WPF の例外ハンドリング

| 項目 | 内容 |
|---|---|
| ID | wpf-3 |
| 分類 | wpf |
| 関連 | guideline-1(エラー処理方針) / log-1(Log.cs 定型) / mvvm-4(クライアント起動ハブ) / avalonia-1(Avalonia 側の相当処理) |

## 目的

予期せぬ例外を取りこぼさず、**ログ記録 + ユーザ通知(MessageBox)** に一元化する。

- `DispatcherUnhandledException`(UI スレッド)と `AppDomain.UnhandledException`(それ以外)の両方をフックする
- 個別の try/catch を散らさない。予期せぬ例外はグローバルフックで処理するという guideline-1(Fail-fast)のクライアント版
- 予期できる異常(入力エラー・通信タイムアウト等)は例外に頼らず結果で通知する(guideline-1)。本トピックが扱うのは「予期せぬ例外」のみ

## 標準形

App のコンストラクタ(ホスト構築後)で2系統のフックを登録し、共通の `HandleException` に集約する。

```csharp
public sealed partial class App
{
    private readonly IHost host;

    private readonly ILogger<App> log;

    public App()
    {
        InitializeComponent();

        host = CreateHost();
        log = host.Services.GetRequiredService<ILogger<App>>();

        // 例外フック(UI スレッド / それ以外)
        Current.DispatcherUnhandledException += (_, ea) => HandleException(ea.Exception);
        AppDomain.CurrentDomain.UnhandledException += (_, ea) => HandleException((Exception)ea.ExceptionObject);
    }

    private void HandleException(Exception ex)
    {
        log.ErrorUnknownException(ex);

        MessageBox.Show(ex.ToString(), "Unknown error.", MessageBoxButton.OK, MessageBoxImage.Error);
    }
}
```

ログ出力は `[LoggerMessage]` 定義(log-1)を使う。

```csharp
// Log.cs
[LoggerMessage(Level = LogLevel.Error, Message = "Unknown exception.")]
public static partial void ErrorUnknownException(this ILogger logger, Exception ex);
```

### フックの役割分担

| フック | 捕捉対象 | 継続可否 |
|---|---|---|
| `Application.DispatcherUnhandledException` | UI スレッド(イベントハンドラ・バインディング経由) | `ea.Handled = true` を設定すれば継続可能 |
| `AppDomain.UnhandledException` | 上記以外(ワーカスレッド等) | 通知のみ。プロセスはそのまま終了に向かう |

継続可能と判断できるアプリでは `DispatcherUnhandledException` 側で `ea.Handled = true` を設定して継続する。判断できない場合は既定のまま(記録・通知して終了)とし、中途半端な状態で走行を続けない(guideline-1 の Fail-fast)。

## 配置ルール

| 対象 | 場所 |
|---|---|
| フック登録 + `HandleException` | `App.xaml.cs`(コンストラクタでホスト構築直後に登録) |
| `ErrorUnknownException` 等のログ定義 | プロジェクト直下の `Log.cs`(log-1) |

フック登録はログ基盤の構築(ホスト構築)より後、ウィンドウ表示(`OnStartup`)より前に行う。

## バリエーションと使い分け

- **非同期の取りこぼし**: fire-and-forget な Task の例外まで拾う場合は `TaskScheduler.UnobservedTaskException` を追加し、ログ記録 + `SetObserved()` とする(そもそも guideline-2 により fire-and-forget を作らないことが前提)
- **Avalonia**: `Dispatcher.UIThread.UnhandledException` + `AppDomain.UnhandledException` + `TaskScheduler.UnobservedTaskException` の3系統をフックし、通知はダイアログサービス経由とする(avalonia-1)
- **通知 UI**: MessageBox が基本形。運用向けには通知欄・再起動誘導等アプリ特性に応じて差し替えてよいが、「ログ + 通知」の一元化構造は変えない

## アンチパターン

- **フック未登録** — 予期せぬ例外が無言のクラッシュになり、調査の手掛かりが残らない。2系統のフックを必ず登録する
- **業務コードへの try/catch 散布** — 予期せぬ例外を各所で握るとバグが隠れる。個別 catch はランタイムでしか検出できないもの(外部 I/O 等)に限る(guideline-1)
- **通知のみでログを残さない(またはその逆)** — 必ず `HandleException` でログと通知の両方を行う
- **`DispatcherUnhandledException` で常に `Handled = true` にする** — 状態が壊れたまま走行を続ける。継続可能と判断できる場合に限定する
- **フック内での複雑な処理** — フック自体が例外を出すと二重障害になる。ログ + 通知の最小構成に留める
