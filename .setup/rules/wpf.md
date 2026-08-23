---
paths:
  - "**/*.xaml"
  - "**/*.xaml.cs"
---

# WPF (UI 技術固有)

> **WPF 固有**。MVVM レイヤ・UI 原則は [`mvvm.md`](mvvm.md)、Windows 環境固有は [`desktop.md`](desktop.md) を参照。

## セットアップ
- Generic Host (`Microsoft.Extensions.Hosting`) で DI / 設定 / ログを構成し、`App.xaml.cs` は起動の合成に徹する (薄く保つ)。
- MVVM 基盤・画面遷移は [`mvvm.md`](mvvm.md) の標準 (Smart.Mvvm + Smart.Navigation) に従う。ツール的に子ウィンドウを管理するケースに限り `WindowManager` 方式 (`Views/IWindowManager`) を使ってよい。

## XAML / UI
- スタイルはリソースディクショナリへ分離し `App.xaml` で統合。色・サイズはセマンティックなリソース名で参照する。
- バインディングは `INotifyPropertyChanged` ベース。`UpdateSourceTrigger` を明示し、入力系は `PropertyChanged` を基本にする。
- 一覧は仮想化 (`VirtualizingStackPanel`) を既定で有効に保つ (大量データで無効化しない)。

## スレッド / 非同期
- UI 更新は UI スレッドで行う。ワーカーからは `Dispatcher` / `IProgress<T>` 経由 (async/await は [async.md](async.md)。UI 層は `ConfigureAwait` 既定)。
- 長時間処理は ViewModel から Usecase へ委譲し、UI をブロックしない。

## ライフサイクル
- 起動 / 終了は `App.xaml.cs` → Host の `StartAsync` / `StopAsync` に対応させ、終了時に State / ユーザー設定を保存する。
