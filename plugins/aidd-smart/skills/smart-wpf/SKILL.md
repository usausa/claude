---
name: smart-wpf
description: Smart スタックの WPF 標準 (WindowManager 用途限定・配置永続化・例外フック)
paths:
  - "**/*.xaml"
  - "**/*.xaml.cs"
---

# WPF (Smart スタック標準)

> `aidd-dotnet` の dotnet-wpf を具体化する。詳細・コード例は references/ を必要時に読む。

- 画面遷移は WPF でも Smart.Navigation (`smart-mvvm` skill)。**`WindowManager` はツール的に子ウィンドウを管理するケースで使用**する: `Views/IWindowManager.cs` にインターフェースと実装を同居、`OnStartup` で `windowManager.Load()`、`OnExit` で `host.StopAsync(5s)`。Closing 時は `CancelEventAction` + `BusyState` で抑止し、`Closed` の `DataContextDisposeAction` で破棄。
- ウィンドウ配置の永続化は `Settings/WindowSettings : ApplicationSettingsBase` + `[UserScopedSetting]` の `MainWindowPlacement` (user.config)。最大化は `Maximized` フラグを分けて保持。
- 予期せぬ例外は `DispatcherUnhandledException` + `AppDomain.UnhandledException` の 2 系統をフックし、ログ + MessageBox の `HandleException` に一元化する。

## references (詳細)

window-manager / window-placement / exception-handling
