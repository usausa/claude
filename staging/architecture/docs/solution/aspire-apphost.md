# Aspire AppHost

| 項目 | 内容 |
|---|---|
| ID | solution-2 |
| 分類 | solution |
| 関連 | solution-1(プロジェクト分割の基本形) / solution-3(基盤層プロジェクト) / host-1(ApplicationExtensions) / telemetry-1(OpenTelemetry) / telemetry-2(HealthChecks) / deploy-3(発行スクリプト) |

## 目的

Web の標準構成に Aspire AppHost を含め、開発時のオーケストレーション(起動・接続・ダッシュボードでのログ / トレース / メトリクス確認)を1プロジェクトに集約する。

- AppHost は**オーケストレーション専用**とし、業務ロジックは一切置かない。数行の宣言だけの極薄プロジェクトを保つ
- アプリ本体は AppHost なしでも単体起動できる形を維持する。テレメトリの有効化は環境変数の有無で分岐するため(telemetry-1)、AppHost 経由なら OTLP 出力が有効になり、単体起動なら従来どおり動く
- **ServiceDefaults プロジェクトは作らない**。相当機能はアプリ側に実装する(後述)

## 標準形

### AppHost.cs

宣言は `AddProject` + `WithHttpHealthCheck` の数行のみ。これ以上増やさない。

```csharp
var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.Template_Server>("server")
    .WithHttpHealthCheck("/health");

builder.Build().Run();
```

- `WithHttpHealthCheck("/health")` は、アプリ側のヘルスチェックエンドポイント(telemetry-2)をダッシュボードの稼働判定に接続する
- リソース名(`"server"`)は小文字の短い名前にする

### csproj

```xml
<Project Sdk="Aspire.AppHost.Sdk/13.3.2">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <CodeAnalysisRuleSet>..\Analyzers.ruleset</CodeAnalysisRuleSet>
    <UserSecretsId>00000000-0000-0000-0000-000000000000</UserSecretsId>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\Template.Server\Template.Server.csproj" />
  </ItemGroup>

</Project>
```

- Analyzers.ruleset はソリューション共通のものを参照し、AppHost だけ品質ゲートを緩めない

### ServiceDefaults プロジェクトは作らない

公式テンプレートが生成する `X.ServiceDefaults`(`AddServiceDefaults()` 拡張)は採用しない。相当機能(テレメトリ・ヘルスチェック・HttpClient の既定など)は次の場所に実装する。

| 構成 | 相当機能の置き場 |
|---|---|
| 単一プロジェクト構成 | アプリ側の `ApplicationExtensions`(host-1)。テレメトリは telemetry-1、ヘルスチェックは telemetry-2 の標準形 |
| 複数プロジェクト構成 | 基盤層プロジェクト(solution-3) |

- アプリの起動構成は `ConfigureXxx()` 列挙(host-1)に一本化されており、ServiceDefaults という第二の置き場を作ると構成が分散する
- `AddServiceDefaults()` 前提のコードを作らないことで、開発形態(AppHost 経由)と本番形態(サービス化 + 単体起動、deploy-1)の差を設定だけに保つ

## 配置ルール

| 対象 | 場所 |
|---|---|
| AppHost プロジェクト | `X.AppHost`。ソリューションの `Aspire/` フォルダ(solution-1) |
| ヘルスチェックエンドポイント | アプリ側の `/health`(telemetry-2)。AppHost は参照するだけ |
| テレメトリ・ヘルスチェックの既定 | `ApplicationExtensions`(host-1)または基盤層プロジェクト(solution-3) |
| 接続文字列等の設定 | アプリ側の appsettings。AppHost からの注入は開発時の上書きに限定する |

## バリエーションと使い分け

- **複数サービス構成**: `AddProject` を並べ、`WithReference` で参照関係(接続情報の注入)を宣言する

```csharp
var api = builder.AddProject<Projects.Template_ApiServer>("apiserver")
    .WithHttpHealthCheck("/health");

builder.AddProject<Projects.Template_Web>("web")
    .WithReference(api)
    .WithHttpHealthCheck("/health");
```

- **ミドルウェア依存**: 開発用の DB 等はコンテナリソースとして AppHost に宣言し、ローカル環境の手動構築を排除する
- **発行**: AppHost は開発時の道具であり、本番の発行対象はホスト単体(deploy-3)。サービス化(deploy-1)の形態に AppHost は登場しない

## アンチパターン

- **AppHost への業務ロジック・環境分岐の持ち込み** — AppHost はリソース宣言のみ。設定の加工や条件分岐が現れたら、それはアプリ側(host-1)の責務
- **ServiceDefaults プロジェクトを作る** — 公式テンプレート追従でプロジェクトを増やさない。相当機能の置き場は上表のとおり
- **AppHost 前提のアプリ** — AppHost からの注入が無いと起動しない構成。単体起動と本番形態が壊れる
- **AppHost を本番の起動手段にする** — 本番はサービス化 + 単体発行(deploy-1, deploy-3)
- **既定構成のコピペ増殖** — 複数プロジェクト構成で ServiceDefaults 相当を各ホストに複製しない。基盤層に集約する(solution-3)
