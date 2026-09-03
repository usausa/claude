---
name: init
description: プロジェクト宣言 aidd.md (SDD レベル) を .claude/rules/ へ生成する初期化。aidd-flow の導入時と SDD レベル変更時に使う。
disable-model-invocation: true
---

> 引数: [lite|full] (SDD レベル。省略時: 既存宣言を維持、初回は full)

基本ワークフローを有効化する。生成されるのは `.claude/rules/aidd.md`(SDD レベルの宣言)のみ。

1. カレントディレクトリがプロジェクトのルートであることを確かめる。
2. 生成スクリプトを実行する ($ARGUMENTS が空でもそのまま実行してよい = 既存レベル維持 / 初回 full):

```
pwsh "${CLAUDE_PLUGIN_ROOT}/scripts/init.ps1" -Sdd $ARGUMENTS
```

3. スクリプトの出力を報告する。aidd.md は managed のため手編集しない。
4. docs 骨格 (adr / work / spec / reference) は各フロー skill が必要時に生成することを伝え、回し方 (人向け) として spec skill の references/workflow.md を案内する。
