---
id: SAMPLE-02
title: 公開 API は ValueTask に統一し、CancellationToken は伝播しない
status: accepted
date: 20XX-XX-XX
tags: [async]
related: []
superseded-by:
---

> **サンプル ADR**(一般則から**意図的に外れる決定**を記録する見本)。テンプレの既定(CT を下位まで伝播)から外れる場合はこの形で残す。

## 背景 / 課題

.NET の一般的なガイダンスは「async メソッドは `Task` を返し、`CancellationToken` を受け取り下位まで伝播する」。一方このシステムの Service / Accessor 層は短時間の DB 操作が大半で、全メソッドに CT 引数を生やすとシグネチャが肥大し、実際に中断したい場面もない。呼び出しの多くは完了済み同期パス(キャッシュ・軽い委譲)を通る。

## 決定

- 公開 API(Service / Accessor / Controller)の戻り値は **`ValueTask` / `ValueTask<T>` に統一**する(逐次読みは `IAsyncEnumerable<T>`)
- **`CancellationToken` は Service / Accessor 層に伝播しない**。受け取るのは次の層だけ:
  - Worker(`BackgroundService` の stoppingToken — graceful shutdown)
  - 機器通信・外部 I/O クライアント(実際に中断が意味を持つ長い I/O)

## 検討した代替案

- **案A: Task + CT 全伝播(一般則)** / 却下理由: 全シグネチャ + 全呼び出し箇所に CT が波及するコストに対し、得られるのは「短時間 DB 操作の中断」のみ。Web ではリクエスト中断時も DB 操作は完了させた方が整合が単純
- **案B: ValueTask + CT 全伝播** / 却下理由: 同上(CT の波及コストが主因)

## 結果(トレードオフ・影響)

- **得たもの**: シグネチャと呼び出しの簡潔さ、完了済みパスのアロケーション回避
- **捨てたもの**: 長時間クエリの途中中断
- **将来への注意**: 長時間クエリ・大量エクスポートの中断要件が出たら、その API に限り CT を追加する(全面導入はしない)。`ValueTask` は「await 一回・即時消費」の制約に従う
