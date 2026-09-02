---
name: logging
description: ログ設計 (.NET 共通)
paths:
  - "**/*.cs"
---

# ログ設計

> .NET 共通。**ロガーのプロバイダ / シンクはアーキ固有**なので、採用形態の rule の「ログの具体」を参照。プロバイダ構成・起動時ログ・リクエスト文脈の付与は起動の組み立て側が担保する。ここは機能を作るときの「どのレベルで・何を・どう書くか」のみ。

## 書き方 (LoggerMessage 全面採用)

- ログ出力は**すべて `[LoggerMessage]` ソース生成の拡張メソッド**で行う (`ILogger` 経由。自前実装・文字列補間・`LogInformation("...")` 直書きをしない)。
- **命名 = レベル略称 + 事象**: `Info~ / Warn~ / Error~ / Debug~`。
- **メッセージ書式 = 英文 + `key=[{value}]`** (値は角括弧で明示。grep と構造化検索の両方に効く)。
- **配置は適宜分割して定義**する (アセンブリ集約の `Log.cs` でも、使うクラスと同一ファイルへの同居でもよい。読みやすい単位で分割し、散在しすぎたらまとめる)。

```csharp
internal static partial class Log
{
    [LoggerMessage(Level = LogLevel.Warning, Message = "Duplicate log. id=[{id}], collectAt=[{collectAt}]")]
    public static partial void WarnDuplicateLog(this ILogger logger, string id, DateTime collectAt);

    [LoggerMessage(Level = LogLevel.Error, Message = "Unknown exception.")]
    public static partial void ErrorUnknownException(this ILogger logger, Exception ex);
}
```

## ログレベルと「何を出すか」

| レベル | 出す事象 | 例 |
|---|---|---|
| ERROR | 想定外の例外・継続不能 (必ず `Exception` を渡しスタックトレースを残す) | 未知例外・接続不能で処理断念 |
| WARN | **想定内の異常** (コードが想定して備えた事象。発生は異常だが処理は継続する) | 重複キーのスキップ・リトライ発生・不正データの読み飛ばし |
| INFO | 業務イベントの**節目** | 処理の開始 / 終了 (+件数・elapsed)・状態変更・外部連携の重要な結果 |
| DEBUG | 開発者のトレース | 送信 / 受信・生成 / 破棄 (**対で揃える**)・分岐の判断材料 |

- ERROR の出力箇所は**基盤部分** (グローバルハンドラ・ホスト層) が基本。FW・ライブラリの制約で下層から出すのは例外として許容し、中間のロジック層では直接扱わない。
- ログには**特定に必要な識別子** (ID・キー) を `key=[{value}]` で必ず含める。**個人情報・秘匿値 (トークン・パスワード・接続文字列) は出さない**。
- 例外を WARN で扱う場合も、どの想定内かが分かるメッセージにする (握りつぶしの禁止は `errors` skill)。
- ログは「誰が・どう使うか」を決めてから内容とレベルを決める (運用者向け / 開発者向けで異なる)。

## 計装 (メトリクス・トレース) との分担

- 「起きたことの記録」= ログ、「量と時間の観測」= メトリクス / トレース。同じ情報を両方に書かない (件数を INFO ログに出しているなら、メトリクス化は観測要件が出たときでよい)。
- 観測基盤は要件で選定する (OpenTelemetry が既定候補。選定は `/adr` に残す)。計装の定義 (Meter / ActivitySource) はアプリ共通の 1 箇所に集約し、機能側はメソッドを呼ぶだけにする。
- 観測基盤の接続先・有効化は**環境変数から与える** (OTLP は `OTEL_EXPORTER_OTLP_ENDPOINT` の有無で有効化を分岐。接続先を `appsettings` に書かない)。
- スパンは**業務の意味単位** (ユースケース・ジョブ 1 回・外部連携 1 回) にだけ張る (HTTP / DB の自動計装は起動の組み立て側が担保)。メトリクス命名は `application.<対象>.<事象>` の snake_case。タグ・値に個人情報・秘匿値を入れない (ログと同じ)。

## Debug ログのコスト管理

- 引数生成にコストがある Debug ログは、呼び出し側で `IsEnabled` ガード + 定義側 `SkipEnabledCheck = true` (二重チェック回避)。

```csharp
if (log.IsEnabled(LogLevel.Debug))
{
    log.DebugCheckElapsed(id, elapsed);
}

[LoggerMessage(Level = LogLevel.Debug, SkipEnabledCheck = true, Message = "Check. id=[{id}], elapsed=[{elapsed}]")]
public static partial void DebugCheckElapsed(this ILogger logger, string id, TimeSpan elapsed);
```
