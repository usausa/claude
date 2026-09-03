---
paths:
  - "**/Handlers/**"
  - "**/*Handler.cs"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# TCP サーバ (Smart スタック標準)

> 詳細・コード例は `smart-network` skill の references を必要時に読む。

- **独自プロトコルの TCP サービスは Kestrel の `ConnectionHandler` 継承で構築する** (ソケット直叩きの自作基盤は使わない)。接続毎の状態は `CommandContext` へ、コマンドは `ICommand` の複数登録 + `Match` 委譲の線形ディスパッチ。
- 受信ループの定型: `ReusableCancellationTokenSource` を接続で 1 つ、`CancelAfter → ReadAsync → フレーム分割 (内側 while で取り切る) → AdvanceTo(buffer.Start, buffer.End) → Reset`。通信断・タイムアウトは握りつぶしてログ + 継続 (サービスを落とさない)。
- ホットパスはアロケーションフリー: `"..."u8` リテラル比較 (`SequentialEqual`)・`SequenceReader` でフレーム検出・`IBufferWriter<byte>` へ直接書き込み (`Utf8Formatter`)・`PooledBufferWriter<T>` の再利用。文字列化してから解析しない。
