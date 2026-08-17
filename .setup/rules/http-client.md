---
paths:
  - "**/*Client*.cs"
  - "**/Clients/**"
---

# HTTP クライアント

> .NET 共通。named client の登録・ハンドラ構成 (圧縮・接続寿命・認証) は起動の組み立て側が担保する。ここは **API 呼び出し機能を作るときの使い方**のみ。

- `new HttpClient()` を書かない。必ず `IHttpClientFactory` の named client を使う (ソケット枯渇・DNS 更新問題の回避)。
- 認証・共通ヘッダを呼び出し側で操作しない。Bearer 付与などは登録済みの `DelegatingHandler` に任せる。
- 接続先 (BaseAddress)・トークンの差し替えは 1 箇所に集約する (呼び出し側に分散させない)。
- シリアライズは REST クライアント抽象に寄せ、`HttpContent` の手組み・手動 JSON 化をしない (ライブラリはプロジェクトで選定し `/adr` に残す)。
- URL は定数クラスに集約する (文字列直書きしない。サーバ側 `ApiRoutes` に対応するクライアント側の置き場)。
- タイムアウト・リトライは呼び出し要件で個別に設計する (既定で盛らない。共通の resilience を組み立て側に持つ場合はそちらへ寄せる)。
- 失敗の扱いは [`errors.md`](errors.md) に従う (想定内 = 結果で返す / 想定外 = 伝播)。
