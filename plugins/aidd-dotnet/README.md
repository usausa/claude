# aidd-dotnet - C#/.NET 標準ルール

対象ファイルを読むと `paths:` で自動適用されるアーキ規範(ライブラリ中立)。
序列は conventions.md(プロジェクト固有)> smart-* > dotnet-*。

## 🚀 導入

```
/plugin install aidd-dotnet@aidd
/aidd-dotnet:init   # rules 20 本を .claude/rules/ へ展開 (managed。プラグイン更新後は再実行)
```

## 📐 rules

| rule | 内容 |
|---|---|
| [dotnet-coding-principles](.claude/rules/dotnet-coding-principles.md) | コーディング原則(.NET 共通) |
| [dotnet-async](.claude/rules/dotnet-async.md) | 非同期処理の規約 |
| [dotnet-errors](.claude/rules/dotnet-errors.md) | 例外・異常系の扱い |
| [dotnet-logging](.claude/rules/dotnet-logging.md) | ログ設計 |
| [dotnet-security](.claude/rules/dotnet-security.md) | セキュリティ標準(.NET 共通) |
| [dotnet-data](.claude/rules/dotnet-data.md) | DB / データアクセス規約 |
| [dotnet-domain](.claude/rules/dotnet-domain.md) | Domain 実装規約 |
| [dotnet-http-client](.claude/rules/dotnet-http-client.md) | HTTP クライアント |
| [dotnet-testing](.claude/rules/dotnet-testing.md) | テストの書き方 |
| [dotnet-web](.claude/rules/dotnet-web.md) | アーキテクチャ(Web 全般) |
| [dotnet-api](.claude/rules/dotnet-api.md) | Web API(minimal API) |
| [dotnet-blazor](.claude/rules/dotnet-blazor.md) | Blazor(UI / コンポーネント) |
| [dotnet-blazor-e2e](.claude/rules/dotnet-blazor-e2e.md) | Blazor E2E テスト(Playwright) |
| [dotnet-grpc](.claude/rules/dotnet-grpc.md) | gRPC サーバ |
| [dotnet-worker](.claude/rules/dotnet-worker.md) | アーキテクチャ(Worker / 常駐サービス) |
| [dotnet-cli](.claude/rules/dotnet-cli.md) | CLI ツール |
| [dotnet-mvvm](.claude/rules/dotnet-mvvm.md) | MVVM アーキテクチャ(XAML 系共通) |
| [dotnet-desktop](.claude/rules/dotnet-desktop.md) | デスクトップ(Windows 環境固有) |
| [dotnet-wpf](.claude/rules/dotnet-wpf.md) | WPF(UI 技術固有) |
| [dotnet-maui](.claude/rules/dotnet-maui.md) | MAUI(プラットフォーム固有) |

## 🧰 その他

| 提供物 | 内容 |
|---|---|
| [init](skills/init/SKILL.md) | dotnet rules の展開 |
| hooks | 編集後の dotnet format 検証・UTF-8/CRLF 正規化 |
| MCP | 下表の 2 サーバーを同梱 |

| MCP サーバー | 種類 | 用途 |
|---|---|---|
| microsoft-learn | http(`learn.microsoft.com/api/mcp`) | Microsoft Learn ドキュメントの参照(API・設定の一次情報) |
| nuget | stdio(`dnx NuGet.Mcp.Server` — .NET 10 SDK が必要) | パッケージ検索・バージョン確認・脆弱性チェック |
