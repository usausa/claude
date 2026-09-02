# プラグイン化・2段スタック構成の方針書(検討中・未決定)

> 本テンプレを Claude Code プラグインへ再編する構想の設計たたき台。**決定したら decisions.md へ移記し、本書は経緯記録に降格する**(refactor-lite-base.md / restructure-context.md と同じライフサイクル)。
> 前提調査(2026-08): プラグインは skills / agents / hooks / MCP / LSP / bin を配布できる。rules は配布不可だが **skill の `paths:` frontmatter で同等の自動発火**が可能。スキャフォールドは `${CLAUDE_PLUGIN_ROOT}` のスクリプト実行方式。CLAUDE.md / settings.json への直接改変は不可。

## 1. 全体像(2段スタック構成)

```
[利用プロジェクト]
  .claude/rules/conventions.md ほかプロジェクト固有 rule     ← 最優先(不変)
      ▲ 上書き・具体化
[第2段] stack プラグイン(スタック標準アドオン)              ← template-architecture から生成
  分類単位の paths 付き skill(スタック規範の要約)+ references/(詳細 docs)
  dependencies: [core]
      ▲ 上書き・具体化
[第1段] core プラグイン(中立コア)                           ← 本テンプレから生成
  SDD フロー(commands→skills / agents / hooks)+ 中立規律 skill(現 rules 21 本)
  + MCP(Learn / NuGet)+ init(スキャフォールド)
```

- **リポジトリの正は変えない**: 中立の正 = 本テンプレ、スタックの正 = template-architecture(decisions.md「template-architecture とは統合しない」は維持)。プラグインは両リポジトリからの**生成・梱包の形**であり、正の統合ではない。
- 序列は「プロジェクト rule > stack > core > 外部 skill / MCP」。AGENTS.md の既存原則(conventions 優先)の自然な拡張。

## 2. 責務分界

| 関心 | 第1段 core(中立) | 第2段 stack(標準断定) |
|---|---|---|
| プロセス(SDD / ADR / work / verify) | ✓ | — |
| 中立規律(async / errors / logging 原則 / domain / testing 等) | ✓ | — |
| ライブラリ選定を伴う規範 | 「選定は `/adr`」とだけ言う | **標準を断定**(Serilog・NSwag・Smart.Data 等)し具体形を示す |
| 詳細実装パターン(コード例・バリエーション) | — | references/(93 docs をオンデマンド参照) |
| 骨格ファイル(init) | 中立版一式 | 正典実物(ruleset / .editorconfig)での上書き(残差の扱いは backlog の個別再確認と連動) |
| MCP | Learn / NuGet | スタック固有に必要なら追加 |

- **中立例外の再編(Phase 4)**: 現在 rules に入れた「Smart.Mvvm + Smart.Navigation 標準」は中立方針の例外(decisions.md)。2段化の際は**例外を第2段へ移し、core の mvvm を純中立に戻す**再編ができる(decisions の当該項を置換する決定が必要)。

## 3. stack プラグインの設計(template-architecture 側)

- **束ね方 = 分類単位**(1 分類 = 1 skill、約 20 個)。1 doc = 1 skill は description 固定費が過大で採らない。
- skill 本文 = その分類の規範**要約**(core の同名 rule のスタック具体版。rules 並みの薄さに保つ)。詳細は references/ の docs を必要時に読む導線を本文に書く。
- `paths:` は core の対応 rule と同型(同時発火は「原則(core)+ 具体(stack)」の役割分担として併存)。
- リポジトリへの追加物は `.claude-plugin/plugin.json` + skills/ のみ(docs/ / TOPICS.md は不変)。**新たな管理点 = docs 更新時の skill 本文への同期**(要約に留めて同期面積を最小化する)。

## 4. 配布

- marketplace は 1 つ(専用リポジトリ or 本テンプレ同居)。plugin source は GitHub 参照(core = 本テンプレ repo / stack = template-architecture repo)。
- バージョンは更新毎にバンプ必須。stack は docs 改稿のたびに上がる想定でリリース粒度を決める。

## 5. 段階(Phase)

| Phase | 内容 | 出口条件 |
|---|---|---|
| 0(現行) | setup.ps1 テンプレート方式 | — (維持) |
| 1 | core 試作: rules→paths 付き skill 変換の検証(発火の同等性・ロード量)、commands の skills 寄せ | 変換した skill が rules と同等に発火する |
| 2 | init 取り込み: マーカー解決を init skill + スクリプトへ移植、templates/ 同梱 | setup.ps1 なしで新規プロジェクトを確定できる |
| 3 | stack 試作: 分類 skill 化 + references 同梱 + 序列検証。**テンプレ群 21 リポジトリへ導入してドッグフーディング**(arch 規範が AI に自動で効くようになる) | テンプレ群での実発火・干渉なしを確認 |
| 4 | 中立例外(Smart 標準)の第2段への移管、core の純中立化 | decisions.md 更新 + ALL PASS |

## 6. 未決・リスク

- **公開可否**: stack(日本語・組織スタック色)を public marketplace に載せるか、私有配布に留めるか。
- **二重管理の面積**: stack skill 本文 ↔ arch docs の同期(要約徹底で最小化。検証は Phase 3 で)。
- **ロード量**: skill description ×約 20 の固定費と発火時本文。Phase 1 / 3 で実測して判断(重ければ束ねを粗くする)。
- 実運用検証(backlog「template-drafts 取り込みの実運用検証」)が先。プラグイン化は検証で現行形を固めてから着手する。
