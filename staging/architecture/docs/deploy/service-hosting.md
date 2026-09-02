# Windows / systemd 両対応のサービス化

| 項目 | 内容 |
|---|---|
| ID | deploy-1 |
| 分類 | deploy |
| 関連 | deploy-2(systemd unit の定石) / deploy-3(発行スクリプト) / host-1(Program.cs の構成) / host-2(起動の定型行) |

## 目的

サーバ系アプリケーションは**同一バイナリで「コンソール実行 / Windows サービス / systemd サービス」の3形態に対応する**。

- 実行形態は配置先の都合で決まる。ビルド成果物を分けず、実行環境の自動検出に任せる
- 開発時はコンソール、Windows 本番は Windows サービス、Linux 本番は systemd と、コードを変えずに移行できる

## 標準形

**`builder.Services.AddWindowsService().AddSystemd()` を無条件で両掛けする**。`IServiceCollection` 拡張の `AddWindowsService` / `AddSystemd` が現行 .NET の推奨 API であり、これに統一する。

```csharp
public static IHostApplicationBuilder ConfigureHost(this IHostApplicationBuilder builder)
{
    // Service
    builder.Services
        .AddWindowsService()
        .AddSystemd();

    return builder;
}
```

- `AddWindowsService()` は Windows サービスとしての実行を検出した場合のみ、ライフタイムをサービス制御(開始・停止要求)に応答する形へ差し替え、イベントログ出力を有効化する
- `AddSystemd()` は systemd 配下での実行を検出した場合のみ、ライフタイムを systemd 連携(`sd_notify` による Ready / Stopping 通知)へ差し替える
- どちらも**非該当環境では何もしない**。OS 判定の条件分岐は不要で、無条件の両掛けが正しい形になる

### 呼び出し位置

Web ホストでは `ApplicationExtensions.ConfigureHost()`(host-1)に置く。構成要素の少ない Generic Host(Worker 等)では `Program.cs` 直書きでよいが、区切りコメントは維持する。

```csharp
Directory.SetCurrentDirectory(AppContext.BaseDirectory);

var builder = Host.CreateApplicationBuilder(args);

// Service
builder.Services
    .AddWindowsService()
    .AddSystemd();
```

### パッケージ参照

ホストプロジェクトに両パッケージを参照する。

```xml
<PackageReference Include="Microsoft.Extensions.Hosting.Systemd" Version="10.0.0" />
<PackageReference Include="Microsoft.Extensions.Hosting.WindowsServices" Version="10.0.0" />
```

### ContentRoot / カレントディレクトリは別途解決する

`AddWindowsService().AddSystemd()` が担うのは**ライフタイム統合のみ**で、サービス実行時のパス問題は解決しない。host-2 の定型行(`Directory.SetCurrentDirectory(AppContext.BaseDirectory)`、Web ホストでは `ContentRootPath = WindowsServiceHelpers.IsWindowsService() ? AppContext.BaseDirectory : default`)とセットで初めてサービス化が完成する。

## 配置ルール

| 対象 | 場所 |
|---|---|
| `AddWindowsService().AddSystemd()` | `ApplicationExtensions.ConfigureHost()`(host-1)。Generic Host 直書き構成では `Program.cs` の `// Service` セクション |
| パスの定型行 | `Program.cs` 冒頭(host-2) |
| systemd unit 定義 | deploy-2 |

## バリエーションと使い分け

- **Windows サービスとしての登録**: `sc.exe create <ServiceName> binPath=<発行先のexe>` で登録する。アプリ側のコードは共通のまま
- **systemd サービスとしての登録**: unit ファイルを配置する(deploy-2)。`Type=notify` を使う場合、`AddSystemd()` が Ready 通知を送るため起動完了をより正確に検出できる
- **コンテナ実行**: 両拡張とも検出に該当せず素通りするため、そのままコンテナでも動作する

## アンチパターン

- **`builder.Host.UseWindowsService().UseSystemd()`(旧方式)** — `IHostBuilder` 拡張の旧 API。新規コードでは `Services.AddWindowsService().AddSystemd()` を使う
- **OS 判定による条件付き登録** — `if (OperatingSystem.IsWindows())` 等で登録を分岐しない。両拡張は非該当環境で no-op であり、分岐はノイズにしかならない
- **片方だけの登録** — 「今は Windows にしか置かない」場合でも両掛けする。配置先の変更をコード変更にしない
- **サービス化 API への過信** — `AddWindowsService()` はカレントディレクトリを解決しない。host-2 の定型行を省くと、サービス実行時に appsettings やログの相対パスが `C:\Windows\System32` 基準になる
