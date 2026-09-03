# aidd-smart — AIDD Smart Architecture

Smart 系スタック標準のアドオンプラグイン。`aidd-dotnet` の中立規律を**上書き具体化**し、ライブラリの断定 (Smart.Mvvm / Smart.Navigation / Smart.Data.Accessor / Serilog / NSwag ほか) と詳細リファレンス (69 ドキュメント) を提供する。

| 提供物 | 内容 |
|---|---|
| 分類 rule (19) | `smart-*` prefix: structure / solution / namespace / host / log / config / data / web / blazor / mvvm / wpf / avalonia / maui / worker / network / test / telemetry / generator / guideline。**init が `.claude/rules/` へ managed 展開し、対象ファイルを読むと `paths:` で自動適用** |
| references の器 skill (19) | 分類毎の薄い skill が references (69 ドキュメント) を保持。rule 本文から誘導され、コード例付き詳細を必要時に読む |
| init | `/aidd-smart:init` — smart rules の展開。プラグイン更新後の再実行で上書き更新 |

## 導入

```
/plugin install aidd-smart@aidd
```

- 導入後に `/aidd-smart:init` で規範 rules をプロジェクトへ展開する (`/aidd-dotnet:init` が未実施ならそちらが先)。
- `aidd-dotnet` に依存する (自動で併せて有効化される)。
- 規範の序列: **プロジェクト rule > aidd-smart > aidd-dotnet > 外部 skill / MCP** — 本プラグインは第 1 段が「選定は `/adr`」とした箇所の標準を断定する。プロジェクトの事情で外れる場合は `/adr` に決定を残し、`.claude/rules/conventions.md` で上書きする。

## 保守

- 規範本体はプラグイン内 `.claude/rules/`(rule = 要約・強制注入)、詳細は各器 skill の references/ が正 (器の一覧と実ファイルの同期は回帰テストで機械検査される)。
- 規範の改稿は開発リポジトリの `staging/architecture/`(原本)→ references へ反映する。
