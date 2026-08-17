---
paths:
  - "**/*.cs"
---

# 非同期処理の規約

> .NET 共通 (全形態で同一)。

- I/O は非同期を基本とする。UI スレッド / リクエストスレッドをブロックしない。
- `CancellationToken` を下位まで伝播させる。
- `Thread.Sleep()` を使わない。待ちが要るなら `Task.Delay()`。
- フレームワークが `Task` を要求する箇所以外は、より軽量な `ValueTask` を使う。
- ライブラリは `ConfigureAwait(false)` が基本、UI 層は既定 (`true`)。
- **`Task.Wait()` / `Task.Result` を使わない** (`await` する)。デッドロック・スレッド枯渇の温床。
- 自前の `Task.Run()` は原則不要。CPU バウンドを明示的にオフロードする等、根拠があるときのみ。

参考: davidfowl/AspNetCoreDiagnosticScenarios の AsyncGuidance。
