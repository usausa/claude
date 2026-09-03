---
name: smart-worker
description: Smart スタックのバッチ / CLI 標準 (IAction + ActionWorker・System.CommandLine + Smart.CommandLine.Hosting)
paths:
  - "src/**"
---

# バッチ・CLI (Smart スタック標準)

> `aidd-dotnet` の dotnet-worker / dotnet-cli を具体化する。詳細・コード例は references/ を必要時に読む。

- バッチの共通骨格: 処理は `IAction { Name, ExecuteAsync }`、実行エンジンは `ActionWorker : BackgroundService` の 1 つ (引数と Name を突合 → 実行 → 例外時 `ExitCode = -1` → finally で `StopApplication()`)。末尾 `return Environment.ExitCode`。
- ディスパッチは **DI の複数登録 + 線形探索** (`AddSingleton<IAction, T>` 並記 → `IEnumerable<T>` 受け)。判定が文字列一致でないものは `Match` をコマンド側へ委譲。ディスパッチテーブルを別途持たない。
- 対話的な CLI ツールは **System.CommandLine + Smart.CommandLine.Hosting**: `[Command]` / `[Option<T>]` 属性宣言 + `ICommandHandler`、共通オプションは抽象基底クラスへ、横断関心事は `ICommandFilter` (Exception フィルタを最外殻 `Int32.MaxValue`)。業務エラーは `context.ExitCode = -1` + メッセージで通知。

## references (詳細)

batch-skeleton / command-dispatch / cli-tool
