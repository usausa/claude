# aidd-smart — AIDD Smart Architecture

Smart 系スタック標準のアドオンプラグイン。`aidd-dotnet` の中立規律を**上書き具体化**し、ライブラリの断定 (Smart.Mvvm / Smart.Navigation / Smart.Data.Accessor / Serilog / NSwag ほか) と詳細リファレンス (93 ドキュメント) を提供する。

| 提供物 | 内容 |
|---|---|
| 分類 skill (20) | `smart-*` prefix: structure / solution / namespace / host / deploy / log / config / data / web / blazor / mvvm / wpf / avalonia / maui / worker / network / test / telemetry / generator / guideline。**本文 = スタック標準の要約 (対象ファイルで `paths:` 自動適用)、references/ = コード例付き詳細 (必要時に読む)** |
| templates | 正典実物 (Analyzers.ruleset / .editorconfig / Directory.Build.props / .targets)。テンプレ群リポジトリの正典参照先 |

## 導入

```
/plugin install aidd-smart@aidd
```

- `aidd-dotnet` に依存する (自動で併せて有効化される)。
- 規範の序列: **プロジェクト rule > aidd-smart > aidd-dotnet > 外部 skill / MCP** — 本プラグインは第 1 段が「選定は `/adr`」とした箇所の標準を断定する。プロジェクトの事情で外れる場合は `/adr` に決定を残し、`.claude/rules/conventions.md` で上書きする。

## 保守

- 各 skill の本文は**要約に保ち**、詳細は references/ のドキュメントが正 (本文と references 一覧の同期は回帰テストで機械検査される)。
- 規範の改稿は開発リポジトリの `staging/architecture/`(原本)→ references へ反映する。
