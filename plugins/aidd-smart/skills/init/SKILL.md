---
name: init
description: Smart スタック規範の rules (smart-*) を .claude/rules/ へ展開する初期化。aidd-smart の導入時とプラグイン更新後に使う。
disable-model-invocation: true
---

Smart スタック規範 (smart-*.md × 20) をプロジェクトへ展開する。

1. 前提を確認する: 第 1 段の骨格・rules が未展開なら、先に `/aidd-dotnet:init` を案内する。
2. 展開スクリプトを実行する:

```
pwsh "${CLAUDE_PLUGIN_ROOT}/scripts/init.ps1"
```

3. スクリプトの出力を報告する。managed rules は上書き更新されるため手編集しない (プロジェクト固有の上書きは `.claude/rules/conventions.md` へ)。
