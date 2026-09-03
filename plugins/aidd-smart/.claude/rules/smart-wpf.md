---
paths:
  - "**/*.xaml"
  - "**/*.xaml.cs"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# WPF (Smart スタック標準)

> `dotnet-wpf` rule を具体化する。詳細・コード例は `smart-wpf` skill の references を必要時に読む。

- 画面遷移は WPF でも Smart.Navigation (`smart-mvvm` rule)。**`WindowManager` はツール的に子ウィンドウを管理するケースで使用**する: `Views/IWindowManager.cs` にインターフェースと実装を同居、`OnStartup` で `windowManager.Load()`、`OnExit` で `host.StopAsync(5s)`。Closing 時は `CancelEventAction` + `BusyState` で抑止し、`Closed` の `DataContextDisposeAction` で破棄。
