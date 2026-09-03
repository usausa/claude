---
paths:
  - "**/Log*.cs"
  - "**/Logging/**"
  - "**/appsettings*.json"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# ログ (Smart スタック標準)

> `dotnet-logging` rule を具体化する。詳細・コード例は `smart-log` skill の references を必要時に読む。

- `internal static partial class Log` + `[LoggerMessage]`、`Info*/Warn*/Error*` プレフィックス、書式 `Xxx. key=[{value}]`。名前空間 (フォルダ) 毎に `Log.cs` を分割配置する。
- **ロガーは Serilog**。コードは `builder.Logging.ClearProviders()` → `AddSerilog(o => o.ReadFrom.Configuration(builder.Configuration))` の定型のみとし、シンク / Enricher / レベルは **100% appsettings の `Serilog` セクションへ委譲** (OTLP 併用時のみ `writeToProviders: true`)。
- outputTemplate 基本形: `{Timestamp:HH:mm:ss.fff} {Level:u4} {MachineName} [{ThreadId}] - {Message:lj}{NewLine}{Exception}`。**Timestamp は時刻のみ (日付を含めない)**。Web は `[{SourceContext}]` `{TraceId}` `{RequestId}` `{RequestPath}` を追加。
- Enricher 3 点セット (FromLogContext / WithThreadId / WithMachineName)。File シンクは実行フォルダ外の Log ディレクトリへ日次ローテーション。本番 = File のみ、開発 = Console / Debug 追加。
- 調査用の冗長ログ 4 系統 (W3C / HTTP / Invoke / SQL) は `Log` セクションの bool トグルで個別 ON/OFF (再ビルドなしの調査)。
