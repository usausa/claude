---
name: init
description: 新規リポジトリに .NET プロジェクトの骨格 (ビルド設定・docs・AGENTS) を展開し、SDD レベルを確定する初期化。プロジェクトを始めるときに一度だけ使う。
disable-model-invocation: true
---

> 引数: [lite|full|full-pm] (SDD レベル。省略時 full)

新規プロジェクトの初期化を行う。

1. 展開先を確認する: カレントディレクトリがプロジェクトのルート (通常は空、または LICENSE / .git 程度) であることを確かめる。既存ファイルがある場合、スクリプトは上書きせずスキップして報告する。
2. 初期化スクリプトを実行する ($ARGUMENTS が空なら -Sdd は付けない = full):

```
pwsh "${CLAUDE_PLUGIN_ROOT}/scripts/init.ps1" -Sdd $ARGUMENTS
```

3. スクリプトの出力 (スキップされた既存ファイル・次の手順) をユーザーへ報告する。
4. 続けて AGENTS.md の「スタック」節の記入を促す (採用するアプリ形態を聞いて記入まで手伝ってよい)。
