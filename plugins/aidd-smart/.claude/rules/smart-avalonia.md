---
paths:
  - "**/*.axaml"
  - "**/*.axaml.cs"
  - "**/Devices/**"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# Avalonia (Smart スタック標準)

> 詳細・コード例は `smart-avalonia` skill の references を必要時に読む。

- 起動は **Program (AppBuilder 構成のみ) → App.Initialize (ホスト構築 + `ResolveProvider` 接続 + 例外フック 3 系統) → OnFrameworkInitializationCompleted (ライフタイム分岐)** の 3 段。desktop は `IClassicDesktopStyleApplicationLifetime` + `desktop.Exit` にホスト停止を接続、実体は `ApplicationExtensions.cs` の `StartApplicationAsync` / `ExitApplicationAsync`。
- 組込み (Linux 直描画): ルートは Window ではなく **`MainView` (UserControl)**。Debug はデスクトップ実行 (`DebugWindow` がホスト)、Release は `StartLinuxDrm` (デバイスパスは appsettings から)。ホストのシグナル捕捉は `NopLifetime` で無効化し、フォントはアプリに同梱。
- 物理ボタン等の入力は `Devices/Input/IInputDevice` に抽象化 (`DebugInputDevice` を `#if DEBUG` で差し替え)、キーは `NavigationEvent` (Back / Forward) に正規化してルート VM の 1 箇所で意味付けし、各画面は基底の `OnNavigationBack/ForwardAsync` オーバーライドで応答する。
