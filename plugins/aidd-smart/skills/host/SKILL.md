---
name: host
description: Smart スタックの起動処理標準 (ApplicationExtensions 方式・起動ログ・DI 登録スタイル)
paths:
  - "**/Program.cs"
  - "**/ApplicationExtensions*.cs"
  - "**/Application/**"
---

# 起動処理 (Smart スタック標準)

> サーバ系の Program.cs と DI。詳細・コード例は references/ を必要時に読む。

- **Program.cs は `builder.ConfigureXxx()` / `app.UseXxx()` の宣言列挙のみ**とし、実体は `Application/ApplicationExtensions.cs` に集約する。
- 起動の定型行: 冒頭 `Directory.SetCurrentDirectory(AppContext.BaseDirectory)`、Web は `ContentRootPath = WindowsServiceHelpers.IsWindowsService() ? AppContext.BaseDirectory : default`、`Configuration.SetBasePath(...)`。
- 起動ログの儀式: ビルド直後に ServiceStart / Version / Runtime / GC / ThreadPool (+ Telemetry 設定) を必ず出力する。
- DI 登録: **登録順 = レイヤ順** (Setting → Provider → Component → Service → Usecase → Worker) を区切りコメントで見せる。機能単位は `ServiceCollectionExtensions.AddXxx()` へ切り出し。複数実装は `AddSingleton<I,T>` 並記 → `IEnumerable<T>` 受け。**基本 Singleton** (Worker から Scoped 依存を使うときは実行毎に `IServiceScopeFactory` でスコープ)。
- `public partial class Program {}` を Program.cs 末尾に宣言 (`[ExcludeFromCodeCoverage]`。WebApplicationFactory 用)。

## references (詳細)

program-structure / startup-boilerplate / startup-logging / di-registration / partial-program
