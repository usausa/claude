# Enricher / シンク構成

| 項目 | 内容 |
|---|---|
| ID | log-4 |
| 分類 | log |
| 関連 | log-2(Serilog の構成方法) / log-3(outputTemplate の標準形) / deploy-3(発行スクリプト) / telemetry-1(OpenTelemetry) |

## 目的

シンクと Enricher の構成を appsettings の `Serilog` セクションに集約し、**本番 = File のみ、開発 = Console / Debug 追加**という標準構成を固定する。

- ログファイルの場所・ローテーション・レベルが全ホストで同じ規則になる
- 開発時の冗長出力は `appsettings.Development.json` の上書きだけで実現し、コードに差分を持たない

## 標準形

`appsettings.json`(本番構成)は次を基本とする。

```json
{
  "Serilog": {
    "Using": [
      "Serilog.Enrichers.Environment",
      "Serilog.Sinks.File"
    ],
    "Enrich": [ "FromLogContext", "WithThreadId", "WithMachineName" ],
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning"
      }
    },
    "WriteTo": [
      {
        "Name": "File",
        "Args": {
          "path": "../Log/Template.Host_.log",
          "rollingInterval": "Day",
          "outputTemplate": "{Timestamp:HH:mm:ss.fff} {Level:u4} {MachineName} [{ThreadId}] - {Message:lj}{NewLine}{Exception}"
        }
      }
    ]
  }
}
```

- **Enricher は3点セット**: `FromLogContext` / `WithThreadId` / `WithMachineName`。テンプレート(log-3)の `{MachineName}` `[{ThreadId}]` に対応する
- **File シンクは実行フォルダ外の Log ディレクトリ**(`../Log/`)に出力し、`rollingInterval: Day` で日次ローテーションする。パスは `<App>_.log` とし、実ファイル名は `<App>_20260820.log` の形になる(Timestamp に日付を含めない根拠 → log-3)
- **最低レベルは Information**、`Microsoft` カテゴリは `Warning` に抑制する(必要に応じてカテゴリ単位の `Override` を追加)
- シンクや Enricher を追加したら `Using` にパッケージ名を追記する

### 開発環境(appsettings.Development.json)

Console / Debug シンクを追加し、レベルを Debug に下げる。テンプレートは File と同一(log-3)。

```json
{
  "Serilog": {
    "Using": [
      "Serilog.Enrichers.Environment",
      "Serilog.Sinks.Console",
      "Serilog.Sinks.File"
    ],
    "Enrich": [ "FromLogContext", "WithThreadId", "WithMachineName" ],
    "MinimumLevel": {
      "Default": "Debug",
      "Override": {
        "Microsoft": "Warning",
        "Microsoft.AspNetCore.Hosting.Diagnostics": "Error"
      }
    },
    "WriteTo": [
      {
        "Name": "Debug",
        "Args": {
          "outputTemplate": "{Timestamp:HH:mm:ss.fff} {Level:u4} {MachineName} [{ThreadId}] - {Message:lj}{NewLine}{Exception}"
        }
      },
      {
        "Name": "Console",
        "Args": {
          "outputTemplate": "{Timestamp:HH:mm:ss.fff} {Level:u4} {MachineName} [{ThreadId}] - {Message:lj}{NewLine}{Exception}"
        }
      },
      {
        "Name": "File",
        "Args": {
          "path": "../Log/Template.Host_.log",
          "rollingInterval": "Day",
          "outputTemplate": "{Timestamp:HH:mm:ss.fff} {Level:u4} {MachineName} [{ThreadId}] - {Message:lj}{NewLine}{Exception}"
        }
      }
    ]
  }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| 本番構成 | `appsettings.json` の `Serilog` セクション |
| 開発時の上書き | `appsettings.Development.json`(発行対象外 → deploy-3) |
| コード側 | `ClearProviders` + `AddSerilog` の定型のみ(log-2) |
| ログ出力先 | 実行フォルダ外の `../Log/`(発行・更新の影響を受けない) |

## バリエーションと使い分け

- **`WithSpan`**: 分散トレースを有効にした Web ホストで、Span 情報(`{TraceId}` 等)をテンプレートに供給する場合に Enricher へ追加する
- **Syslog 二重出し**: 集中監視へ送る場合、`UdpSyslog` シンクを `WriteTo` に併記する。テンプレートは Timestamp と Exception を落とした専用形(log-3)を使う

```json
{
  "Name": "UdpSyslog",
  "Args": {
    "outputTemplate": "{Level:u4} {MachineName} [{ThreadId}] - {Message:lj}",
    "host": "192.0.2.10",
    "port": 514,
    "appName": "template-host",
    "facility": "Local0",
    "restrictedToMinimumLevel": "Information"
  }
}
```

## アンチパターン

- **実行フォルダ配下へのログ出力** — 発行・更新時に消える。単一ファイル発行(deploy-3)の展開物とも混ざる。必ず `../Log/` 等の外部ディレクトリに出す
- **本番での Console シンク常設** — サービス実行では出力が捨てられるか、systemd 環境では journal と File の二重管理になる。本番は File(+必要なら Syslog)に限定する
- **本番 `MinimumLevel: Debug`** — ログ量が破綻する。冗長ログが必要な系統は log-5 のトグルで個別に有効化する
- **`Using` の更新漏れ** — シンクを追加しても `Using` にパッケージがないと黙って無視される
- **ローテーションなしの単一ファイル** — 肥大化し、日付の判別手段(log-3)も失われる
