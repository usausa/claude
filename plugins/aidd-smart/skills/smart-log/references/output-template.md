# outputTemplate の標準形

| 項目 | 内容 |
|---|---|
| ID | log-3 |
| 分類 | log |
| 関連 | log-2(Serilog の構成方法) / log-4(Enricher / シンク構成) / log-1(Log.cs 定型) / host-3(起動ログの儀式) |

## 目的

ログ1行のレイアウトを固定し、**複数ホスト・複数世代のログを同じ目と同じツールで読める**ようにする。

- 列の位置が固定されるため、目視でもスクリプトでも機械的に切り出せる
- 用途(基本 / Web / Syslog)毎のテンプレートを表で規定し、場当たりな変更を防ぐ

## 標準形

基本形は次のとおり。

```text
{Timestamp:HH:mm:ss.fff} {Level:u4} {MachineName} [{ThreadId}] - {Message:lj}{NewLine}{Exception}
```

- **Timestamp は時刻のみ(`HH:mm:ss.fff`)とし、日付を含めない**(決定事項)。日付は日次ローテーションされたファイル名(`Template.Worker_20260820.log` 等 → log-4)と実行文脈から判別する。行が短くなり、桁が完全に揃う
- `{Level:u4}` — レベルを大文字4文字固定幅(`INFO` / `WARN` / `EROR` 等)で出力し、桁を揃える
- `{MachineName}` / `[{ThreadId}]` — Enricher 供給(log-4)。複数台構成・マルチスレッドの突き合わせ用
- `{Message:lj}` — 文字列はリテラル、構造化データは JSON で出力
- `{Exception}` — 改行後にスタックトレースを出力(例外は log-1 の規約どおり `Exception` 引数で渡す)

## 用途別テンプレート

| 用途 | テンプレート |
|---|---|
| 基本(Batch / CLI / TCP サーバ) | `{Timestamp:HH:mm:ss.fff} {Level:u4} {MachineName} [{ThreadId}] - {Message:lj}{NewLine}{Exception}` |
| Web(API / Blazor Server) | `{Timestamp:HH:mm:ss.fff} {Level:u4} {MachineName} [{SourceContext}] [{ThreadId}] {TraceId} {RequestId} {RequestPath} - {Message:lj}{NewLine}{Exception}` |
| Syslog 送信用(log-4) | `{Level:u4} {MachineName} [{ThreadId}] - {Message:lj}` |

- **Web** は基本形に対して `[{SourceContext}]`(出力元クラス)、`{TraceId}`(分散トレースとの突き合わせ)、`{RequestId}` / `{RequestPath}`(リクエスト単位の突き合わせ)を追加する
- **Syslog 送信用**は syslog 側がタイムスタンプを持つため `{Timestamp}` を落とし、1行運用のため `{Exception}` も落とす(専用テンプレート)

## バリエーションと使い分け

### 業務フィールドの拡張形

インスタンス ID・セッション系など、**全行に出したい業務フィールド**はテンプレートにプロパティを追記し、値は `AsyncLocal` なコンテキストから `CallbackEnricher` で供給する(コード側 Enricher 登録 → log-2)。

```text
{Timestamp:HH:mm:ss.fff} {Level:u4} {MachineName} [{ThreadId}] {UserId} - {Message:lj}{NewLine}{Exception}
```

```csharp
// 登録(log-2 の ConfigureLogging 内)
options.Enrich.With(new CallbackEnricher("UserId", static () => LoggingContext.UserId));
```

```csharp
namespace Template.Host.Infrastructure.Logging;

using Serilog.Core;
using Serilog.Events;

public sealed class CallbackEnricher : ILogEventEnricher
{
    private readonly string name;

    private readonly Func<object?> resolver;

    public CallbackEnricher(string name, Func<object?> resolver)
    {
        this.name = name;
        this.resolver = resolver;
    }

    public void Enrich(LogEvent logEvent, ILogEventPropertyFactory propertyFactory)
    {
        var enrichProperty = propertyFactory.CreateProperty(name, resolver());
        logEvent.AddOrUpdateProperty(enrichProperty);
    }
}
```

使い分けの基準:

- **全行に出す値**(誰の・どのインスタンスの処理か) → テンプレート + Enricher
- **その行だけの値**(処理対象・件数等) → log-1 の `key=[{value}]` としてメッセージに含める

## アンチパターン

- **日付入り Timestamp** — 決定に反する。日付分だけ全行が長くなり、得られる情報はファイル名と重複する
- **ホスト間・シンク間のテンプレート不揃い** — 同一ホストでは Console / Debug / File とも同じテンプレートを使う(Syslog のみ専用形)。切り替えたツールで列位置が変わる状態を作らない
- **業務値のメッセージ直書き** — 全行に必要な値をメッセージ側に手で足すと、書き忘れが発生する。Enricher で機械的に供給する
- **`{Message}`(`lj` なし)** — 構造化データが `"..."` 引用付きで出力され、JSON として読めなくなる
