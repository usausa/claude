# 受信ループの定型

| 項目 | 内容 |
|---|---|
| ID | network-2 |
| 分類 | network |
| 関連 | network-1(TCP サーバ基盤) / network-3(アロケーションフリー処理) / guideline-1(エラー処理方針) / guideline-2(CancellationToken) |

## 目的

受信処理は `IDuplexPipe` を共通境界とした**同型のループ**で書く。

- `CancelAfter → ReadAsync → フレーム分割 → AdvanceTo → Reset` の順序を固定し、バッファ管理ミス(進め忘れ・未処理データの破棄)を構造的に防ぐ
- TCP はストリームであり「1回の Read = 1フレーム」ではない前提をループの形に織り込む
- タイムアウト・通信断でサービスを落とさない

## 標準形

### ループ全体

`ReusableCancellationTokenSource` をループ外で1つ確保し、読み取り毎に `CancelAfter`、正常受信後に `Reset` して再利用する(タイムアウト値はダミー)。

```csharp
public override async Task OnConnectedAsync(ConnectionContext connection)
{
    log.DebugHandlerConnected(connection.ConnectionId);

    try
    {
        var context = new CommandContext();

        using var timeout = new ReusableCancellationTokenSource();
        while (true)
        {
            timeout.CancelAfter(30_000);
            var result = await connection.Transport.Input.ReadAsync(timeout.Token);
            var buffer = result.Buffer;

            var running = true;
            while (!buffer.IsEmpty && ReadLine(ref buffer, out var line))
            {
                var commandResult = await ProcessLineAsync(context, line, connection.Transport.Output);
                if (commandResult == CommandResult.Unknown)
                {
                    connection.Transport.Output.WriteAndAdvanceNg();
                }
                else if (commandResult == CommandResult.Quit)
                {
                    running = false;
                    break;
                }

                await connection.Transport.Output.FlushAsync(CancellationToken.None);
            }

            if (!running || result.IsCompleted)
            {
                break;
            }

            connection.Transport.Input.AdvanceTo(buffer.Start, buffer.End);

            timeout.Reset();
        }
    }
    catch (OperationCanceledException)
    {
        // Ignore
    }
    finally
    {
        log.DebugHandlerDisconnected(connection.ConnectionId);
    }
}
```

### フレーム境界の検出

フレーム分割は `SequenceReader` を使う static ヘルパに切り出す。検出したフレーム分だけ `buffer` を進める(ref 渡し)。

```csharp
private static bool ReadLine(ref ReadOnlySequence<byte> buffer, out ReadOnlySequence<byte> line)
{
    var reader = new SequenceReader<byte>(buffer);
    if (reader.TryReadTo(out ReadOnlySequence<byte> l, "\r\n"u8))
    {
        buffer = buffer.Slice(reader.Position);
        line = l;
        return true;
    }

    line = default;
    return false;
}
```

### ループの要点

| 要素 | 規約 |
|---|---|
| 境界型 | `IDuplexPipe`(`connection.Transport`)。`Socket` / `Stream` を直接触らない |
| タイムアウト | `ReusableCancellationTokenSource` を接続で1つ。`CancelAfter` → 受信 → `Reset` で再利用する |
| フレーム分割 | 1回の `ReadAsync` に複数フレーム(または断片)が来る前提で、内側 `while` で取り切る |
| 読み進め | `AdvanceTo(buffer.Start, buffer.End)` — 消費した位置と検査済みの位置を分けて通知し、未完のフレームはパイプ側に残す |
| 応答 | `Transport.Output`(`IBufferWriter<byte>`)へ直接書き、フレーム処理毎に `FlushAsync` |
| 終了条件 | `result.IsCompleted`(相手切断)またはプロトコル上の quit |
| 例外 | `OperationCanceledException`(タイムアウト)は握りつぶして切断処理へ。**通信断でサービスを落とさない**(ログ+継続。guideline-1) |

## 配置ルール

| 対象 | 場所 |
|---|---|
| 受信ループ | `ConnectionHandler.OnConnectedAsync`(network-1)。クライアント側は接続クラス内の同型ループ |
| フレーム検出ヘルパ | 同一クラスの static メソッド、汎用化するなら `Handlers/` のヘルパクラス(`CommandHelper` 等) |

## バリエーションと使い分け

- **区切り文字プロトコル**: `SequenceReader.TryReadTo("\r\n"u8)`。トークン分割は同型の `Split` ヘルパ(区切りバイト指定)で行う
- **固定長 / 長さプレフィックス**: `buffer.Length` が必要長に達するまで `AdvanceTo(buffer.Start, buffer.End)` で待つ形にする。検出ヘルパの差し替えのみでループの骨格は変えない
- **クライアント側**: 応答待ちも同じループで書く(`CancelAfter → ReadAsync → ReadLine → AdvanceTo → Reset`)。受信結果は `PooledBufferWriter<byte>`(network-3)へ蓄積する

## アンチパターン

- `AdvanceTo` を呼ばずにループを継続する — パイプが進まず読み取りが停止する(または例外)。読めなかった場合も必ず `AdvanceTo(buffer.Start, buffer.End)` を通す
- consumed に `buffer.End` を渡す — 未処理の断片が破棄され、フレームが欠落する
- 「1回の Read = 1フレーム」前提の処理 — 断片化・連結の両方で壊れる。フレーム検出を必ず挟む
- 読み取り毎に `new CancellationTokenSource` — タイマー確保がループ毎に発生する。`ReusableCancellationTokenSource` で再利用する
- タイムアウト・通信断の例外を上位へ再スローする — 接続単位で閉じてログ+継続。サービス全体を落とさない
- 受信データの文字列化(`Encoding.GetString`)を挟んでからパースする — `ReadOnlySequence<byte>` のまま処理する(network-3)
