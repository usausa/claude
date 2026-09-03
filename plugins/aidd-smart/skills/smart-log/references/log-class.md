# Log.cs 定型

| 項目 | 内容 |
|---|---|
| ID | log-1 |
| 分類 | log |
| 関連 | log-2(Serilog の構成方法) / log-3(outputTemplate の標準形) / host-3(起動ログの儀式) / structure-4(警告抑止の三層) / structure-7(メンバ記述順序) |

## 目的

ログ出力を **`[LoggerMessage]` ソースジェネレータによる強い型付きメッセージに一本化する**。

- 文字列補間やボックス化のコストがなく、レベル判定込みで最速のログ出力になる
- メッセージ書式が `Log.cs` に集約され、grep・レビュー・世代間の突き合わせが容易になる
- パラメータ名がそのまま構造化ログのプロパティ名になり、シンク側での検索・集計に使える

## 標準形

`internal static partial class Log` に、`this ILogger` 拡張の partial メソッドを `[LoggerMessage]` 付きで列挙する。

```csharp
namespace Template.Worker;

internal static partial class Log
{
    // Startup

    [LoggerMessage(Level = LogLevel.Information, Message = "Service start.")]
    public static partial void InfoServiceStart(this ILogger logger);

    // Action

    [LoggerMessage(Level = LogLevel.Information, Message = "Action start. action=[{action}]")]
    public static partial void InfoActionStart(this ILogger logger, string action);

    [LoggerMessage(Level = LogLevel.Information, Message = "Action end. action=[{action}]")]
    public static partial void InfoActionEnd(this ILogger logger, string action);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Unknown action. action=[{action}]")]
    public static partial void WarnActionUnknown(this ILogger logger, string action);

    [LoggerMessage(Level = LogLevel.Error, Message = "Action failed. action=[{action}]")]
    public static partial void ErrorActionFailed(this ILogger logger, Exception ex, string action);
}
```

呼び出し側はメソッド1つで完結する。

```csharp
logger.InfoActionStart(action.Name);
```

### 規約

- クラスは `internal static partial class Log`、メソッドは `this ILogger` の拡張メソッドとする
- メソッド名は **`Info*` / `Warn*` / `Error*` プレフィックス**で始め、`Level` と必ず一致させる
- 書式は **`Xxx. key=[{value}]`**(短い文 + パラメータの `key=[{value}]` 列挙)。値を `[]` で囲むことで、空文字・前後空白を目視で判別できる
- 例外は `ILogger` の直後の引数 `Exception ex` として渡す(メッセージ文字列には埋め込まない)
- メッセージは機能単位の区切りコメント(`// Startup` / `// Action` 等)でグルーピングする(structure-7 の「処理の種類単位のグルーピング」と同じ思想)

### ログレベルの使い分け

| レベル | 出す事象 | 例 |
|---|---|---|
| ERROR | 想定外の例外・継続不能(必ず `Exception` を渡しスタックトレースを残す) | 未知例外・接続不能で処理断念 |
| WARN | **想定内の異常**(コードが想定して備えた事象。発生は異常だが処理は継続する) | 重複キーのスキップ・リトライ発生・不正データの読み飛ばし |
| INFO | 業務イベントの節目 | 処理の開始 / 終了(+件数・elapsed)・状態変更・外部連携の重要な結果 |
| DEBUG | 開発者のトレース | 送信 / 受信・生成 / 破棄(対で揃える)・分岐の判断材料 |

- ERROR の出力箇所は**基盤部分**(グローバルハンドラ・ホスト層)が基本(guideline-1 の Fail-fast と対応)。FW・ライブラリの制約で下層から出すのは例外として許容し、中間のロジック層では直接扱わない
- ログには特定に必要な識別子(ID・キー)を `key=[{value}]` で必ず含める。個人情報・秘匿値(トークン・パスワード・接続文字列)は出さない

### Debug ログのコスト管理

引数生成にコストがある Debug ログは、呼び出し側の `IsEnabled` ガードと定義側の `SkipEnabledCheck = true`(二重チェック回避)を対で使う。

```csharp
if (log.IsEnabled(LogLevel.Debug))
{
    log.DebugCheckElapsed(id, elapsed);
}

[LoggerMessage(Level = LogLevel.Debug, SkipEnabledCheck = true, Message = "Check. id=[{id}], elapsed=[{elapsed}]")]
public static partial void DebugCheckElapsed(this ILogger logger, string id, TimeSpan elapsed);
```

## 配置ルール

`Log.cs` は一枚岩にせず、**名前空間(フォルダ)毎に分割配置**する。namespace はフォルダに一致させるため、同一アセンブリ内に複数の `Log` クラスが共存しても衝突しない(internal + 名前空間分離)。

| 対象 | 場所 |
|---|---|
| 起動系・ホスト全体のメッセージ | ルートの `Log.cs`、または `Application/Log.cs`(host-1 構成) |
| 機能固有のメッセージ | 各機能フォルダの `Log.cs`(例: `Handlers/Log.cs`) |

```csharp
namespace Template.CommandServer.Handlers;

internal static partial class Log
{
    [LoggerMessage(Level = LogLevel.Information, Message = "Handler connected. connectionId=[{connectionId}]")]
    public static partial void InfoHandlerConnected(this ILogger logger, string connectionId);
}
```

## バリエーションと使い分け

- **素の `LogInformation` 等を使う場合**: 例外的にソースジェネレータを使わない箇所では、`#pragma warning disable CA1848` を局所的に明示する(黙って書かない)
- **プロジェクト全体で LoggerMessage を使わない場合**: `GlobalSuppressions.cs` で CA1848 をアセンブリ単位に抑止する(structure-4)。ただし標準は LoggerMessage 使用
- **EventId**: 既定では指定しない。外部監視システムがイベント ID で突き合わせる要件がある場合のみ付与する

## アンチパターン

- **文字列補間ログ** — `logger.LogInformation($"Action start. action={name}")` は構造化されず、レベル判定前にフォーマットコストが発生する(CA2254 にも抵触)。書かない
- **メッセージ書式の場当たり的な変更** — `Xxx. key=[{value}]` 形式を崩すと、ホスト間・世代間の機械的な突き合わせができなくなる
- **Log クラスの一枚岩化** — 全メッセージを1ファイルに集めると肥大化し、機能とメッセージの対応が追えなくなる。名前空間毎に分割する
- **例外のメッセージ埋め込み** — `ex.Message` をパラメータとして渡すとスタックトレースが失われる。`Exception` 引数として渡し、テンプレートの `{Exception}` に出力させる(log-3)
