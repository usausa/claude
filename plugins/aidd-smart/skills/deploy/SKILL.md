---
name: deploy
description: Smart スタックの配置標準 (Windows / systemd 両対応・unit 定石・単一ファイル発行)
paths:
  - "**/publish*"
  - "**/*.service"
  - "**/*.csproj"
---

# サービス化・発行 (Smart スタック標準)

> 詳細・コード例は references/ を必要時に読む。

- サーバ系は **`builder.Services.AddWindowsService().AddSystemd()` を無条件で両掛け**し、同一バイナリでコンソール / Windows サービス / systemd の 3 形態に対応する (`UseWindowsService()` 等の IHostBuilder 拡張は旧方式)。
- systemd unit の定石: `WorkingDirectory=/opt/<app>` / `Restart=always` + `RestartSec=10` / **`KillSignal=SIGINT`** (graceful shutdown 必須) / `SyslogIdentifier` / 環境変数 (テレメトリ含む) は `Environment=`。
- 発行は**単一ファイル + self-contained**。csproj は DeploySingleFile プロパティ有無の条件ブロックに `PublishSingleFile` + `SelfContained` の 2 行、`appsettings.*.json` は `CopyToPublishDirectory="Never"`。発行スクリプト (publish.ps1 / .sh) は出力先を削除してから発行し、**ReadyToRun は win のみ**。
- `appsettings.json` は `ExcludeFromSingleFile` で実行ファイルの隣に置き、発行後も編集可能に保つ。

## references (詳細)

service-hosting / systemd-unit / publish-script
