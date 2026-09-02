---
name: avalonia
description: Smart スタックの Avalonia 標準 (起動 3 段・組込み実行形態・入力抽象化)
paths:
  - "**/*.axaml"
  - "**/*.axaml.cs"
  - "**/Devices/**"
---

# Avalonia (Smart スタック標準)

> 詳細・コード例は references/ を必要時に読む。

- 起動は **Program (AppBuilder 構成のみ) → App.Initialize (ホスト構築 + `ResolveProvider` 接続 + 例外フック 3 系統) → OnFrameworkInitializationCompleted (ライフタイム分岐)** の 3 段。desktop は `IClassicDesktopStyleApplicationLifetime` + `desktop.Exit` にホスト停止を接続、実体は `ApplicationExtensions.cs` の `StartApplicationAsync` / `ExitApplicationAsync`。
- 組込み (Linux 直描画): ルートは Window ではなく **`MainView` (UserControl)**。Debug はデスクトップ実行 (`DebugWindow` がホスト)、Release は `StartLinuxDrm` (デバイスパスは appsettings から)。ホストのシグナル捕捉は `NopLifetime` で無効化し、フォントはアプリに同梱。
- 物理ボタン等の入力は `Devices/Input/IInputDevice` に抽象化 (`DebugInputDevice` を `#if DEBUG` で差し替え)、キーは `NavigationEvent` (Back / Forward) に正規化してルート VM の 1 箇所で意味付けし、各画面は基底の `OnNavigationBack/ForwardAsync` オーバーライドで応答する。

## references (詳細)

startup-and-lifetime / embedded-execution-model / embedded-input-abstraction
