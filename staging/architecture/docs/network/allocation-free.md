# アロケーションフリー処理

| 項目 | 内容 |
|---|---|
| ID | network-3 |
| 分類 | network |
| 関連 | network-1(TCP サーバ基盤) / network-2(受信ループ) / guideline-2(非同期作法) |

## 目的

高頻度で流れるプロトコル処理のホットパスでは、**バイト列⇔文字列の変換と一時バッファの確保を避け、GC 負荷を抑える**。

- 受信データは `ReadOnlySequence<byte>` / `ReadOnlySpan<byte>` のまま比較・解析する
- 応答は `IBufferWriter<byte>` へ直接書き込み、中間の string / byte[] を作らない
- 再利用可能なバッファ(`PooledBufferWriter<T>` / `ArrayPool`)で接続・処理単位の確保を1回にする

## 標準形

### UTF-8 リテラルによる比較

プロトコル定数は `"..."u8` リテラルで持ち、受信バイト列と直接比較する。

```csharp
public bool Match(ReadOnlySequence<byte> command) => command.SequentialEqual("get"u8);
```

`ReadOnlySequence<byte>` はセグメント跨ぎがあるため、比較は拡張メソッドに切り出す。

```csharp
public static bool SequentialEqual<T>(this ReadOnlySequence<T> sequence, ReadOnlySpan<T> span)
{
    if (sequence.IsSingleSegment)
    {
        return sequence.FirstSpan.SequenceEqual(span);
    }

    foreach (var segment in sequence)
    {
        var length = segment.Length;
        if ((length > span.Length) || !segment.Span.SequenceEqual(span[..length]))
        {
            return false;
        }

        span = span[length..];
    }

    return span.Length == 0;
}
```

### IBufferWriter への直接書き込み

応答は文字列を経由せず `GetSpan` / `Advance` で書く。定型応答は拡張メソッド化する。

```csharp
public static void WriteAndAdvanceOk(this IBufferWriter<byte> writer)
{
    "ok\r\n"u8.CopyTo(writer.GetSpan(4));
    writer.Advance(4);
}

public static void WriteAndAdvanceNg(this IBufferWriter<byte> writer)
{
    "ng\r\n"u8.CopyTo(writer.GetSpan(4));
    writer.Advance(4);
}
```

数値は `Utf8Formatter` で直接書式化する(`int.ToString()` を作らない)。

```csharp
public static void WriteInt32(this IBufferWriter<byte> writer, int value)
{
    var span = writer.GetSpan(11);
    Utf8Formatter.TryFormat(value, span, out var written);
    writer.Advance(written);
}
```

### 数値の解析 — Utf8Parser

受信バイト列からの数値解析も文字列を経由しない。単一セグメントを高速パスとし、跨ぎのみフォールバックする。

```csharp
public static bool TryParse(this ReadOnlySequence<byte> sequence, out int value)
{
    return sequence.IsSingleSegment
        ? Utf8Parser.TryParse(sequence.FirstSpan, out value, out _)
        : Utf8Parser.TryParse(sequence.ToArray(), out value, out _);
}
```

### PooledBufferWriter&lt;T&gt;

蓄積が必要な場合(応答の受信バッファ等)は `ArrayPool` ベースの `PooledBufferWriter<T>` を**接続と同寿命で1つ確保し、`Clear` で使い回す**。

```csharp
private readonly PooledBufferWriter<byte> receiveBuffer = new(1024);

// 受信の度に再利用
receiveBuffer.Clear();
line.CopyTo(receiveBuffer.GetSpan(length));
receiveBuffer.Advance(length);

var success = receiveBuffer.WrittenSpan.StartsWith("ok"u8);
```

### 道具の対応表

| 道具 | 用途 |
|---|---|
| `"..."u8` リテラル | プロトコル定数(コマンド名・応答・区切り)を byte 列で持つ |
| `SequenceReader<T>` | フレーム境界検出・トークン分割(network-2) |
| `Utf8Parser` / `Utf8Formatter` | byte 列⇔数値の直接変換 |
| `IBufferWriter<byte>.GetSpan/Advance` | 応答の直接書き込み |
| `PooledBufferWriter<T>` | `ArrayPool` ベースの再利用可変長バッファ |
| `StringBuilderPool` | 文字列組み立てが必要な場合の StringBuilder 再利用 |

## 配置ルール

| 対象 | 場所 |
|---|---|
| プロトコルヘルパ(比較・解析・書き込み拡張) | `Handlers/` のヘルパクラス(`CommandHelper` 等)に static で集約 |
| 汎用のバッファ部品(`PooledBufferWriter<T>` 等) | アプリ非依存のインフラ(solution-4)。ライブラリ利用を基本とする |

## バリエーションと使い分け

- **文字列を返す必要がある場合**: 都度 `Substring` せず `ReadOnlySpan<char>` を返す ref 構造体パーサで切り出し、確定した値のみ string 化する。組み立ては `StringBuilderPool` を使う
- **XML 等のテキスト直書き**: シリアライザを使わず `PutStartTag` / `PutElement` / `PutEndTag` のような `IBufferWriter` 拡張で直接書き出す形もある(電文サイズ・頻度が大きい場合)
- **適用範囲**: この作法は受信ループ・コマンド処理のホットパスに限る。起動時処理や低頻度の管理コマンドでは可読性を優先してよい

## アンチパターン

- `Encoding.GetString` でフレーム全体を文字列化してから `string.Split` で解析する — 解析は byte 列のまま行う
- 応答の組み立てに文字列補間 + `Encoding.GetBytes` — `u8` リテラルと `Utf8Formatter` で直接書く
- ループ内での `new byte[]` / `MemoryStream` — 再利用バッファ(`PooledBufferWriter<T>` / `ArrayPool`)を使う
- ホットパスでの安易な `ToArray()` — セグメント跨ぎのフォールバック等、限定的な箇所に留める
- 計測なしの過剰最適化 — ホットパス以外まで ref / Span だらけにして可読性を落とさない。適用は頻度とサイズで判断する
