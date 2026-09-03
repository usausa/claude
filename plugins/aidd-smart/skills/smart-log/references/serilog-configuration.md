# Serilog の構成方法

| 項目 | 内容 |
|---|---|
| ID | log-2 |
| 分類 | log |
| 関連 | log-1(Log.cs 定型) / log-3(outputTemplate の標準形) / log-4(Enricher / シンク構成) / host-1(Program.cs の構成) / telemetry-1(OpenTelemetry) |

## 目的

ロガーの構成を**コードから appsettings に完全委譲する**。

- シンク・Enricher・レベルの変更を、再ビルドなしに環境毎の設定ファイルだけで行える
- コード側は全ホスト共通の定型2行に固定され、Web / Worker / TCP サーバで差分が出ない
- 「ログの挙動を知りたければ appsettings の `Serilog` セクションを見る」が常に成立する

## 標準形

コードに書くのは次の2行のみ。シンク / Enricher / レベルは **100% appsettings の `Serilog` セクション(log-4)に委譲**し、コード側に `WriteTo` / `MinimumLevel` を書かない。

```csharp
// Log
builder.Logging.ClearProviders();
builder.Services.AddSerilog(options =>
{
    options.ReadFrom.Configuration(builder.Configuration);
});
```

- `ClearProviders()` で既定プロバイダ(Console 等)を除去し、二重出力を防ぐ
- `AddSerilog`(`IServiceCollection` 拡張)を使う。`builder.Host.UseSerilog()`(`IHostBuilder` 拡張)は旧方式(deploy-1 のサービス化 API と同じ「現行 .NET は Services 拡張」方針)
- `ApplicationExtensions.cs` 方式(host-1)では `ConfigureLogging()` 拡張メソッドの中に置く

## 配置ルール

| 対象 | 場所 |
|---|---|
| 上記2行 | `Application/ApplicationExtensions.cs` の `ConfigureLogging`(host-1)。旧方式では `Program.cs` の `// Log` セクション |
| シンク・Enricher・レベル定義 | `appsettings.json` / `appsettings.<Environment>.json` の `Serilog` セクション(log-4) |

## バリエーションと使い分け

### OTLP 併用時 — `writeToProviders` を渡す

OpenTelemetry の OTLP エクスポータでログも送信する場合のみ、`writeToProviders: true` を渡す。Serilog が受けたログイベントを、登録済みの他の `ILoggerProvider`(OpenTelemetry ロガー)へも転送するためのフラグである。判定は環境変数 `OTEL_EXPORTER_OTLP_ENDPOINT` の有無とし、`IConfiguration` 拡張メソッドに隠蔽する(telemetry-1)。

```csharp
public static IHostApplicationBuilder ConfigureLogging(this IHostApplicationBuilder builder)
{
    var useOtlpExporter = builder.Configuration.IsOtelExporterEnabled();

    // Application log
    builder.Logging.ClearProviders();
    builder.Services.AddSerilog(
        options =>
        {
            options.ReadFrom.Configuration(builder.Configuration);
        },
        writeToProviders: useOtlpExporter);

    return builder;
}
```

- **既定は `false`(引数省略)**: Serilog が唯一の出力者であり、転送のオーバーヘッドを避ける
- **OTLP 併用時のみ `true`**: ファイル(Serilog)と OTLP(OpenTelemetry)の双方へ同じログが流れる

### コードでしか登録できない Enricher

設定ファイルで表現できない Enricher(`AsyncLocal` なコンテキストから値を供給する `CallbackEnricher` 等 → log-3)に限り、コード側で追加する。それ以外の標準 Enricher は appsettings に書く(log-4)。

```csharp
builder.Services.AddSerilog(
    options =>
    {
        options.ReadFrom.Configuration(builder.Configuration);
        options.Enrich.With(new CallbackEnricher("UserId", static () => LoggingContext.UserId));
    },
    writeToProviders: useOtlpExporter);
```

## アンチパターン

- **コードへのシンク・レベルのべた書き** — `options.WriteTo.File(...)` 等をコードに書くと、環境毎の調整に再ビルドが必要になり、appsettings との二重定義で挙動が追えなくなる
- **`ClearProviders()` の欠落** — 既定の Console プロバイダと Serilog の二重出力になる
- **無条件の `writeToProviders: true`** — OTLP を使わない構成では無駄な転送が走るだけ。条件は OTLP エンドポイントの有無に紐付ける
- **`UseSerilog`(旧 `IHostBuilder` 拡張)の新規使用** — 現行の `AddSerilog` に統一する
