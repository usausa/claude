---
name: guideline
description: Smart スタックの横断ガイドライン詳細 (エラー処理・非同期・HTTP クライアント) のリファレンス
paths:
  - "**/*.cs"
---

# 横断ガイドライン (Smart スタック)

> `aidd-dotnet` の errors / async / http-client と同じ原則の**詳細版** (コード例・境界の判断基準・アンチパターン) を references/ に持つ。深掘りが要るときに読む。

- エラー処理: 結果通知の型の使い分け表 (nullable / bool / enum / record)・DbException + IsDuplicate の境界変換・CA1031 の局所抑止の書き方。
- 非同期: sync over async / async void / CancellationToken 伝播 / ValueTask / ConfigureAwait 層別 / PeriodicTimer / TaskCompletionSource / 非同期初期化の各具体形。
- HTTP クライアント: named client + `SocketsHttpHandler` (`PooledConnectionLifetime`) + `ApiDelegatingHandler` + `ApiContext` 一元化 + Rester (REST 抽象) の標準形。

## references (詳細)

error-handling / async-guideline / http-client
