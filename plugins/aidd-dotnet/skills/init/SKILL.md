---
name: init
description: アーキ規範 rules (managed) とプロジェクト宣言 (SDD レベル) を .claude/rules/ へ展開する初期化。導入時とプラグイン更新後に使う。
disable-model-invocation: true
---

> 引数: [lite|full] (SDD レベル。省略時: 既存宣言を維持、初回は full)

既存プロジェクトへ AI 開発基盤を導入する。**展開されるのは `.claude/rules/` のみ**(規範 rules 20 本 + プロジェクト宣言 aidd.md)。

1. カレントディレクトリがプロジェクトのルートであることを確かめる。
2. 展開スクリプトを実行する ($ARGUMENTS が空でもそのまま実行してよい = 既存レベル維持 / 初回 full):

```
pwsh "${CLAUDE_PLUGIN_ROOT}/scripts/init.ps1" -Sdd $ARGUMENTS
```

3. スクリプトの出力を報告する。managed rules と aidd.md は init 再実行で上書き更新されるため手編集しない (プロジェクト固有の上書きは `.claude/rules/conventions.md` へ)。
4. docs 骨格 (adr / work / spec / reference / pm) は各フロー skill が必要時に生成することを伝え、回し方 (人向け) として spec skill の references/workflow.md を案内する。aidd-smart 併用時は続けて `/aidd-smart:init` を案内する。
