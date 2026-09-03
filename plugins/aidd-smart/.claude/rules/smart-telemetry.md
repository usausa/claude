---
paths:
  - "**/Telemetry/**"
  - "**/*Instrument*.cs"
  - "**/Health*/**"
  - "**/appsettings*.json"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# テレメトリ・ヘルスチェック (Smart スタック標準)

> 詳細・コード例は `smart-telemetry` skill の references を必要時に読む。

- カスタム計装は `ApplicationInstrument` (Meter + ActivitySource + Counter を DI Singleton) + `Source` (Assembly から Name/Version) + `AddApplicationInstrumentation` 拡張の 3 点セットに固定する。
- **OTLP は `OTEL_EXPORTER_OTLP_ENDPOINT` の有無だけで有効化を分岐** (判定は `IConfiguration` 拡張に隠蔽。`AddOtlpExporter()` に引数を渡さない)。Prometheus は設定節 (`Prometheus:Uri`) で `AddPrometheusHttpListener`。
- HealthChecks は `/health` (readiness = 依存先込み) と `/alive` (liveness = self のみ) の 2 系統 + `DisableRateLimiting()`。チェックは `IHealthCheck` 実装に分離し例外を漏らさず結果で返す。非 Web 常駐は `IHealthCheckPublisher` → `HealthCheckState` シングルトンへ吸い上げ。
- `/metrics` `/swagger` は環境・機能トグルで無効化を第一に、公開時は IP 制限 (事前パース済み `IPNetwork[]` + `UseWhenFrom`) を重ねる。ヘルスチェックはトレース収集から除外する。
