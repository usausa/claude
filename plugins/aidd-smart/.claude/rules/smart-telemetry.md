---
paths:
  - "**/Telemetry/**"
  - "**/*Instrument*.cs"
  - "**/Health*/**"
  - "**/appsettings*.json"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。dotnet-* と重なる規範は smart-* が優先。プロジェクト固有の上書きは conventions.md へ -->

# テレメトリ・ヘルスチェック (Smart スタック標準)

> 詳細・コード例は `smart-telemetry` skill の references を必要時に読む。

- カスタム計装は `ApplicationInstrument` (Meter + ActivitySource + Counter を DI Singleton) + `Source` (Assembly から Name/Version) + `AddApplicationInstrumentation` 拡張の 3 点セットに固定する。
- HealthChecks は `/health` (readiness = 依存先込み) と `/alive` (liveness = self のみ) の 2 系統 + `DisableRateLimiting()`。チェックは `IHealthCheck` 実装に分離し例外を漏らさず結果で返す。非 Web 常駐は `IHealthCheckPublisher` → `HealthCheckState` シングルトンへ吸い上げ。
