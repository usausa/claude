---
paths:
  - "**/*.cs"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# 横断ガイドライン (Smart スタック)

> `dotnet-errors` rule / `dotnet-async` rule / `dotnet-http-client` rule と同じ原則の**詳細版** (コード例・境界の判断基準・アンチパターン) を `smart-guideline` skill の references に持つ。深掘りが要るときに読む。

- エラー処理: 結果通知の型の使い分け表 (nullable / bool / enum / record)・DbException + IsDuplicate の境界変換・CA1031 の局所抑止の書き方。
- 非同期: sync over async / async void / CancellationToken 伝播 / ValueTask / ConfigureAwait 層別 / PeriodicTimer / TaskCompletionSource / 非同期初期化の各具体形。
- HTTP クライアント: named client + `SocketsHttpHandler` (`PooledConnectionLifetime`) + `ApiDelegatingHandler` + `ApiContext` 一元化 + Rester (REST 抽象) の標準形。
