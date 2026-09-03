# 起動の定型行

| 項目 | 内容 |
|---|---|
| ID | host-2 |
| 分類 | host |
| 関連 | host-1(Program.cs の構成) / deploy-1(サービス化 API) / deploy-2(systemd unit) / deploy-3(発行スクリプト) |

## 目的

起動形態(コンソール / Windows サービス / systemd)によらず、**実行ファイルのあるディレクトリを基準に動作させる**。

- Windows サービスとして起動されるとカレントディレクトリは `C:\Windows\System32` になり、相対パス(設定・ログ・データファイル)の解決が全て破綻する
- 単一ファイル発行(deploy-3)でも `AppContext.BaseDirectory` は実行ファイルの場所を指すため、これを唯一の基準点とする
- 毎回同じ定型で書くことで、配備形態の変更(コンソール→サービス→コンテナ)にコード変更なしで耐える

## 標準形

### Generic Host(非 Web)

```csharp
Directory.SetCurrentDirectory(AppContext.BaseDirectory);

var builder = Host.CreateApplicationBuilder(args);
```

### Web ホスト

```csharp
Directory.SetCurrentDirectory(AppContext.BaseDirectory);
var builder = WebApplication.CreateBuilder(new WebApplicationOptions
{
    Args = args,
    ContentRootPath = WindowsServiceHelpers.IsWindowsService() ? AppContext.BaseDirectory : default
});
```

`WindowsServiceHelpers` は `Microsoft.Extensions.Hosting.WindowsServices` 名前空間(同名パッケージ)にある。

### 設定の基準パス

`ConfigureSystem()`(host-1)の先頭で設定の探索位置も固定する。

```csharp
builder.Configuration.SetBasePath(AppContext.BaseDirectory);
```

### 各行の理由

| 定型行 | 理由 |
|---|---|
| `Directory.SetCurrentDirectory(AppContext.BaseDirectory)` | サービス起動時のカレントディレクトリを実行ファイル位置へ矯正する。以降の相対パス I/O(ログの `../Log`、SQLite の相対 DataSource 等)が起動形態に依存しなくなる |
| `ContentRootPath = IsWindowsService() ? BaseDirectory : default` | ContentRoot(静的ファイル・設定の基準)の既定はカレントディレクトリ由来。サービス実行を検出した場合のみ実行ファイル位置を明示し、それ以外は既定の解決に任せる |
| `Configuration.SetBasePath(AppContext.BaseDirectory)` | `appsettings.json` の探索位置を実行ファイル位置に固定する。単一ファイル発行でも実行ファイル隣接の設定が確実に読まれる |

### deploy-1 との関係

`builder.Services.AddWindowsService().AddSystemd()`(deploy-1)は**ライフタイム統合**(サービス制御への応答・イベントログ・sd_notify)を担い、パス問題は解決しない。本トピックの定型行とセットで初めてサービス化が完成する。ホスティング登録は `ConfigureHost()`(host-1)に置く。

## 配置ルール

| 対象 | 場所 |
|---|---|
| `SetCurrentDirectory` + ビルダー生成 | `Program.cs` 先頭(他のどのコードよりも前) |
| `SetBasePath` | `ApplicationExtensions.ConfigureSystem()`(host-1) |
| `AddWindowsService().AddSystemd()` | `ApplicationExtensions.ConfigureHost()`(deploy-1) |

## バリエーションと使い分け

- **Generic Host**: `WebApplicationOptions` がないため `ContentRootPath` 分岐は不要。`SetCurrentDirectory` 後にビルダーを生成すれば ContentRoot も実行ファイル位置になる
- **静的コンテンツ中心の Web(Blazor Server 等)**: 開発時のカレントディレクトリ移動を避けたい場合、`SetCurrentDirectory` を省略し `ContentRootPath` 分岐のみとする形もある。ただし相対パス I/O を行うなら標準どおり全て入れる
- **コンテナ配備**: サービス検出は false になり既定動作のまま。定型行は無害なので削らずに残す(配備形態の変更に強くなる)
- **systemd 側の保険**: unit ファイルの `WorkingDirectory=`(deploy-2)も併せて指定するが、コード側の定型行を省略する理由にはしない

## アンチパターン

- **定型行なしでサービス配備** — 開発機のコンソール起動でしか動かない。サービス化した途端に設定が読めない・ログが出ない
- **`ContentRootPath` の無条件固定** — 常に `AppContext.BaseDirectory` を渡すと、開発時の静的ファイル・Razor の解決が `bin` 配下へ向く
- **カレントディレクトリ前提の自前解決** — `Directory.GetCurrentDirectory()` を基準にパスを組み立てない。基準は常に `AppContext.BaseDirectory`
- **`builder.Host.UseWindowsService().UseSystemd()`** — `IHostBuilder` 拡張の旧方式。新規は `Services.AddWindowsService().AddSystemd()`(deploy-1)
- **ビルダー生成後の `SetCurrentDirectory`** — 設定読み込みや ContentRoot 決定の後では効果が不完全になる。必ず先頭で行う
