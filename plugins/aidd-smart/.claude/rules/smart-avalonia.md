---
paths:
  - "**/*.axaml"
  - "**/*.axaml.cs"
  - "**/Devices/**"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# Avalonia (Smart スタック標準)

> 詳細・コード例は `smart-avalonia` skill の references を必要時に読む。

- 物理ボタン等の入力は `Devices/Input/IInputDevice` に抽象化 (`DebugInputDevice` を `#if DEBUG` で差し替え)、キーは `NavigationEvent` (Back / Forward) に正規化してルート VM の 1 箇所で意味付けし、各画面は基底の `OnNavigationBack/ForwardAsync` オーバーライドで応答する。
