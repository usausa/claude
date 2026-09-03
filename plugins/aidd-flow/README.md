# aidd-flow — AIDD Flow

**spec / plan / 実装の基本ワークフロー**プラグイン。SDD フロー (lite = 一時 SPEC / full = 恒久 SPEC + 蒸留) と ADR・作業フォルダ運用・DoD ゲートを提供する。

| 提供物 | 内容 |
|---|---|
| ループ skill | `/aidd-flow:spec` → `plan` → `impl` → `verify` → `review` → `done`。SDD レベル (lite / full) は `.claude/rules/aidd.md` の宣言で実行時分岐 |
| オンデマンド skill | `adr` / `reference` / `trace` (full) / `review-cross`、work-init / work-close / spec-close (full) / adr-guide / rule-create / git-commit / csharp-layered-feature / sync-docs-from-code |
| agents (3) | spec / reviewer / doc-sync |
| hooks | 応答終了時の DoD リマインド (フル判定は `/aidd-flow:done`) |
| init | `/aidd-flow:init [lite\|full]` — aidd.md (SDD レベル宣言) の生成のみ。docs 骨格は各 skill が必要時に生成 |

## 導入

```
/plugin install aidd-flow@aidd
```

- 導入後に `/aidd-flow:init [lite|full]` で SDD レベルを確定する。
- 依存プラグインは無いが、**C# / .NET プロジェクトでは `aidd-dotnet` との併用を推奨**する (verify / done は dotnet build・test を、reference は OpenAPI を前提とした手順のため)。
- 回し方 (人向け・docs の寿命クラス込み) は spec skill の references/workflow.md。イテレーション計画・進捗管理を足す場合は `aidd-pm` を導入する。
