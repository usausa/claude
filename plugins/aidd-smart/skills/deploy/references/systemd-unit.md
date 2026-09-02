# systemd unit の定石

| 項目 | 内容 |
|---|---|
| ID | deploy-2 |
| 分類 | deploy |
| 関連 | deploy-1(Windows / systemd 両対応) / deploy-3(発行スクリプト) / telemetry-1(OpenTelemetry: 設定は環境変数) / log-4(Enricher / シンク構成: Syslog 出力) / guideline-2(非同期作法: CancellationToken の伝播) |

## 目的

Linux 配置のサービス定義を**同じ形の unit ファイル**に固定する。

- graceful shutdown・自動再起動・ログ識別子・環境変数の与え方をアプリ間で揃え、unit ファイルをコピーして名前を替えるだけで新サービスを配置できる
- アプリ側のシャットダウン処理(`CancellationToken` への応答、guideline-2)が確実に実行される停止経路を保証する

## 標準形

`/etc/systemd/system/<app>.service` に次の形で配置する。

```ini
[Unit]
Description=App
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/app
ExecStart=/opt/app/App
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=app
Environment=DOTNET_ENVIRONMENT=Production

[Install]
WantedBy=multi-user.target
```

各行の意図:

| 設定 | 内容 |
|---|---|
| `WorkingDirectory=/opt/<app>` | 発行物一式を `/opt/<app>` に配置し、作業ディレクトリも合わせる。アプリ側の `SetCurrentDirectory`(host-2)と併せて相対パスの基準を固定する |
| `ExecStart` | 単一ファイル発行(deploy-3)した実行ファイルを絶対パスで指定する |
| `Restart=always` + `RestartSec=10` | 異常終了時は 10 秒後に自動再起動する。継続不能な異常は落として再起動に任せる方針(guideline-1)の受け皿 |
| `KillSignal=SIGINT` | **graceful shutdown のために必須**。停止をコンソールの Ctrl+C と同じ経路に乗せ、ホストのシャットダウン処理(`CancellationToken` の発火 → 処理中の完了待ち)を確実に通す |
| `SyslogIdentifier` | journal / syslog 上の識別子をアプリ名に固定する(log-4 の Syslog 出力と対応) |
| `Environment=` | 環境変数はここで与える。環境名(`DOTNET_ENVIRONMENT`)のほか、テレメトリ設定(telemetry-1)もここに書く |

### 環境変数の付与

テレメトリ関連の設定は環境変数から取得する(telemetry-1)。OTLP 出力を有効化する場合は unit に追記する。

```ini
Environment=DOTNET_ENVIRONMENT=Production
Environment=OTEL_EXPORTER_OTLP_ENDPOINT=http://collector.example.com:4317
```

### 配置・起動手順

```bash
sudo cp app.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now app
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| unit ファイルの原本 | リポジトリのルート直下に `<app>.service` として管理する(配置先は `/etc/systemd/system/`) |
| 発行物 | `/opt/<app>/`(WorkingDirectory と一致させる) |
| 環境依存の値 | unit の `Environment=`。appsettings に環境別の値を焼き込まない |

## バリエーションと使い分け

- **`Type=notify`**: `AddSystemd()`(deploy-1)は sd_notify に対応しているため、起動完了の検出を厳密にしたい場合は `Type=simple` の代わりに `Type=notify` を使える。依存サービスの起動順制御が必要な場合に有効
- **専用ユーザでの実行**: 権限を絞る場合は `User=` / `Group=` を追加する。`/opt/<app>` と Log ディレクトリの所有権を合わせる
- **依存サービスの待ち合わせ**: DB 等のローカル依存がある場合は `After=` に追加する。ただしリモート依存はアプリ側のリトライで吸収し、unit の依存関係にしない

## アンチパターン

- **`KillSignal` の未指定** — シャットダウン経路が揃わず、処理中のジョブや接続のクリーンアップが保証されない。`SIGINT` を明示する
- **`Restart` の未指定** — 異常終了したまま停止し続ける。常駐サービスは `always` + `RestartSec` を必須とする
- **`WorkingDirectory` の未指定** — 作業ディレクトリがルート等になり、相対パス参照(ログ・設定)が壊れる
- **環境依存値の appsettings 直書き** — 環境の切り替えは `Environment=` で行う。特にテレメトリ設定を appsettings に書くのは決定事項(telemetry-1)に反する
- **`RestartSec` なしの即時再起動** — 起動直後に落ちる障害でリスタートループが暴走する。10 秒程度の間隔を置く
