# src (アプリケーションの配置先)

> 現時点でソースは未配置。ここは将来の配置先。実装は仕様 (spec) を起点に skill の流れで作る。
> **採用形態に応じて該当の「想定構成」を使う**(不要なものは削ってよい)。

## 想定構成 (Web の場合)

```
src/
  <App>/                    Web アプリ本体 (Blazor Server + minimal API)  [Microsoft.NET.Sdk.Web]
  <App>.AppHost/            .NET Aspire AppHost (オーケストレーション)       [Aspire.AppHost.Sdk]
```

- **ServiceDefaults プロジェクトは作らない**。OpenTelemetry / ヘルスチェック / resilience / service discovery の共通設定は、**Web アプリ本体 (共有インフラプロジェクトがあればそちら) の `Application/` に拡張メソッドとして取り込む**。

## 想定構成 (MAUI の場合)

```
src/
  <App>/                    MAUI アプリ本体 (View / ViewModel / Usecase / Service / Domain / State)
```

## 想定構成 (Desktop の場合)

```
src/
  <App>/                    WPF アプリ本体 (View / ViewModel / Usecase / Service / Domain / State)
```

## 想定構成 (Worker の場合)

```
src/
  <App>/                    Worker Service 本体 (Worker / Usecase / Service / Domain)  [Microsoft.NET.Sdk.Worker]
```

## メモ
- レイヤ構成は `.claude/rules/`(採用形態の rule。対象ファイルを読むと自動適用)。上位層は薄く、組み立ては `Application/` / `Usecase/` へ。
- 各 `csproj` は root の `Directory.Build.props` から analyzer・`Analyzers.ruleset`・Nullable 等を継承する(個別設定は不要)。
- ソリューションは root の `.slnx`。
