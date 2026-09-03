---
name: smart-telemetry
description: Smart スタックの観測標準 (ApplicationInstrument・OTLP 環境変数分岐・HealthChecks・保護)
paths:
  - "**/Telemetry/**"
  - "**/*Instrument*.cs"
  - "**/Health*/**"
  - "**/appsettings*.json"
---

# テレメトリ・ヘルスチェック (Smart スタック標準)

> 詳細・コード例は references/ を必要時に読む。

- カスタム計装は `ApplicationInstrument` (Meter + ActivitySource + Counter を DI Singleton) + `Source` (Assembly から Name/Version) + `AddApplicationInstrumentation` 拡張の 3 点セットに固定する。
- **OTLP は `OTEL_EXPORTER_OTLP_ENDPOINT` の有無だけで有効化を分岐** (判定は `IConfiguration` 拡張に隠蔽。`AddOtlpExporter()` に引数を渡さない)。Prometheus は設定節 (`Prometheus:Uri`) で `AddPrometheusHttpListener`。
- HealthChecks は `/health` (readiness = 依存先込み) と `/alive` (liveness = self のみ) の 2 系統 + `DisableRateLimiting()`。チェックは `IHealthCheck` 実装に分離し例外を漏らさず結果で返す。非 Web 常駐は `IHealthCheckPublisher` → `HealthCheckState` シングルトンへ吸い上げ。
- `/metrics` `/swagger` は環境・機能トグルで無効化を第一に、公開時は IP 制限 (事前パース済み `IPNetwork[]` + `UseWhenFrom`) を重ねる。ヘルスチェックはトレース収集から除外する。

## references (詳細)

opentelemetry / health-checks / endpoint-protection
