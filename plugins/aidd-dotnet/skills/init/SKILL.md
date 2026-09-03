---
name: init
description: C#/.NET 標準のアーキ規範 rules (managed) を .claude/rules/ へ展開する初期化。導入時とプラグイン更新後に使う。
disable-model-invocation: true
---

既存プロジェクトへ C#/.NET 標準の規範を導入する。展開されるのは `.claude/rules/` の dotnet-*.md (20 本) のみ。

1. カレントディレクトリがプロジェクトのルートであることを確かめる。
2. 展開スクリプトを実行する:

```
pwsh "${CLAUDE_PLUGIN_ROOT}/scripts/init.ps1"
```

3. スクリプトの出力を報告する。managed rules は init 再実行で上書き更新されるため手編集しない (プロジェクト固有の上書きは `.claude/rules/conventions.md` へ)。
4. 基本ワークフローを使う場合は `aidd-flow` の導入と `/aidd-flow:init` を、Smart スタック標準を使う場合は `aidd-smart` の導入と `/aidd-smart:init` を案内する。
