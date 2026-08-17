# 設計解説(構造と Claude 機構・Spec Kit 比較)

> テンプレ本体から読み取りにくい「なぜこの構造か」の解説。保守の入口は [MAINTENANCE.md](MAINTENANCE.md)。

## 🧩 1. 構造と Claude 機構

> **キモ**: 「毎回プロンプトで指示する」のではなく、**機構として一度定義して自動化 / 強制**している。プロンプトは忘れる・ブレる・毎回コストがかかるが、機構は反復・強制・省コンテキスト。

### 機構の一覧と「強制の強さ」

| 機構 | 実体 | 強制の強さ | template-aidd での役割 |
|---|---|---|---|
| **常時ロード規約** | `CLAUDE.md` → `@AGENTS.md` | 常時(必ず文脈に居る) | 規約・SDD・DoD を毎ターン適用 |
| **skill** | `.claude/skills/*/SKILL.md` | 自動適用(関連時に AI が読む) | 実装レイヤ順・蒸留・ADR・commit・E2E を"手順"化 |
| **command** | `.claude/commands/*.md` | 人トリガ + ツール限定 + 実行 | `/verify` `/done` 等のゲート・検査 |
| **subagent** | `.claude/agents/*.md` | 委譲(別コンテキスト) | `/review`→reviewer 等 |
| **hook** | `settings.json` + `hooks/*.ps1` | **ハード(AI の裁量外で必ず走る)** | 編集時に UTF-8/CRLF 正規化・format 検証 |
| **permission** | `settings.json` allow/ask/deny | **ハード(不可能化 / 確認)** | reference 手編集を deny、git push を ask |
| **MCP** | `.mcp.json` | 能力付与(知識/操作) | Learn=公式docs、NuGet=パッケージ知識 |

下に行くほど「AI がどう思おうと効く」強制になる。目的に応じて使い分けている:

- **常時効かせたい規約** → `AGENTS.md`(常時ロード。ただし薄く保つ=固定費)
- **作業手順の自動適用** → **skill**(description だけ常時、本文は関連時のみ=progressive disclosure)
- **反復する工程・ゲート** → **command**(`!` で実コマンド実行、`allowed-tools` で誤操作防止)
- **重い/隔離したい仕事** → **subagent**(別コンテキストへ委譲)
- **絶対にさせたくない / 必ずさせたい** → **permission deny** / **hook**(AI は回避できない)
- **外部の正しい知識** → **MCP**(Learn / NuGet。ツール定義は固定費なので絞る)

### 「1機能を追加する」ときに何が発火するか(SDD full の例)

1. `/spec`(command)→ `spec`(subagent)が SPEC 草案(`docs/spec/SPEC-NNNN`。lite は `docs/work/` の一時 SPEC)→ 人が承認。
2. `/plan`(command)→ 作業フォルダ(`docs/work/`)に PLAN チェックリスト(全レベルで一時物)→ 人が承認。
3. 決定があれば `/adr`(command)がドラフトの用意と index 再生成を支援(手動編集が基本)、`adr-guide`(skill)が内容・粒度を導く。日々守る制約になるなら `rule-create`(skill)で rules 化。
4. `/impl`(command)→ `csharp-layered-feature`(skill 自動ロード)がレイヤ順を強制。編集のたびに hook(`source-normalize`=UTF-8/CRLF、`dotnet-verify`=format)が走る。
5. `/verify`(command)→ `!dotnet build` / `!dotnet test` を実行して緑を確認。
6. `/reference`(command)→ `docs/reference` を再生成。`reference/**` は permission deny で手編集不可。
7. `/review` + `/review-cross` → `reviewer`(subagent)/ Codex が `review-checklist` で審査。
8. `/done`(command)→ DoD ゲート + `work-close`(skill。片付け = 作業フォルダ削除・最終プッシュ・ブランチ削除の提示。full は `spec-close` で SPEC を蒸留して残す)。応答終了で hook(`done-check`)がリマインド。
9. commit は `git-commit`(skill)の規約で AI が提示、`git push` は permission ask で人が実行。

### リポジトリ構造(注釈つき)

```
template-aidd/
├─ CLAUDE.md              [常時ロード] @AGENTS.md を import するだけ
├─ AGENTS.md              [常時ロード] 規約の"正"(SDD/DoD/git。末尾に原本専用の保守ブロック)
├─ README.md              [人向け・非依存] 入口。導入後は置換/削除可
├─ setup.ps1              [セットアップ] -Form maui|web|desktop|worker [-Sdd lite|full|full-pm]
├─ .setup/                [原本専用] sdd full ステージ + pm 差分 + maintenance/(保守メモリ)。setup 後に削除
├─ .mcp.json              [MCP] microsoft-learn(http)+ nuget(dnx)
├─ .editorconfig / Directory.Build.{props,targets} / Analyzers.ruleset /
│  Settings.XamlStyler / App.slnx                          [LINT/ビルド superset]
├─ .claude/
│  ├─ settings.json       [権限+hooks] deny(reference手編集)/ ask(git push)/ hooks 登録
│  ├─ hooks/              [PostToolUse] source-normalize / dotnet-verify、[Stop] done-check
│  ├─ commands/           [人が /呼ぶ] ループ定常段 = spec/plan/impl/verify/review/review-cross/done、
│  │                       オンデマンド = adr/reference (+ full: trace / full-pm: pm-plan・pm-status)
│  ├─ agents/             [委譲] spec/reviewer/doc-sync (+ pm)
│  ├─ rules/              [自動適用] アーキ規範(setup が .setup/rules から共通 + 採用系分をコピー。paths で発火)
│  └─ skills/             [自動ロード] csharp-layered-feature/
│                          adr-guide/sync-docs-from-code/git-commit/spec-close
├─ docs/
│  ├─ README.md           [契約] 寿命・永続化の正
│  ├─ work/               [一時] SPEC(lite)と PLAN(全レベル)。git 管理・完了時に削除
│  ├─ spec/               [意図] SPEC(full のみ。lite は docs/work/ の一時 SPEC)
│  ├─ adr/                [決定] 追記のみ・不変
│  ├─ reference/          [現状仕様] 生成・手編集 deny
│  ├─ glossary.md / review-checklist.md / traceability/(full のみ)
│  └─ guides/workflow.md  [手順] 各段の具体プロンプト
└─ src/ tests/            アプリ/テスト配置先(README で形態別)
```

## 🔀 2. GitHub Spec Kit との比較

> template-aidd の方針(spec = REQ / plan / tasks、DES 廃止)は **GitHub Spec Kit**(`github/spec-kit`)の Spec-Driven Development に強く影響を受けている。

### 概念の対応

| GitHub Spec Kit | template-aidd | 備考 |
|---|---|---|
| `constitution.md`(不可侵の原則) | `.claude/rules/*` + `docs/adr/` | 原則=rules(paths で自動適用)、決定=ADR(追記式)、方針=conventions(rules 内・編集可)に分割 |
| `spec.md`(何を・なぜ) | `docs/spec/SPEC-*`(full)/ `docs/work/` の一時 SPEC(lite) | ほぼ同じ役割 |
| `/speckit.clarify`(曖昧さ解消) | `/spec` の「未決事項(質問)」 | 要求段階に内包 |
| `plan.md`(技術プラン) | `docs/work/` の PLAN(全レベルで一時物) | **Spec Kit は永続ファイル / template-aidd は一時物**(git 履歴には残る) |
| `tasks.md`(タスク分解) | タスクリスト / PLAN のチェックリスト | 同上: 永続 vs 一時(実装後に破棄) |
| `/speckit.implement` | 実装(`csharp-layered-feature` skill) | フェーズ実装 + 段階レビュー |
| `specify` CLI / `.specify/` | クローンする .NET テンプレ + `.claude/` | 配布形態が違う |

### 主な違い(意図的な diverge)

1. **plan / tasks を永続化しない**(最大の違い): Spec Kit はリポジトリにコミットする成果物、template-aidd は一時物(「ソースから復元できるものは残さない」)。lite は spec 自体も一時物にする。
2. **原則の持ち方**: Spec Kit は `constitution.md` 一枚。template-aidd は rules(原則。対象ファイルで自動適用)+ ADR(決定・不変)+ conventions(編集可)に分割し、決定の履歴を不変で残す。
3. **現状仕様とドリフト対策の機械化**: 生成(OpenAPI)+ テスト = 現状仕様、`/spec-sync`、reference 手編集禁止、`/trace`、逆フィードバック hook。Spec Kit はこの機械化が薄い。
4. **.NET 特化** + **Claude ネイティブ配布**(CLI ブートストラップ無し)+ Codex クロスレビュー。

### 出典

- [github/spec-kit](https://github.com/github/spec-kit) / [Spec Kit Documentation](https://github.github.com/spec-kit/)
- [Spec-driven development with AI (GitHub Blog)](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)

## 🔗 3. 関連資料(ローカル)

> リポジトリ外の資料。**実在パスは環境依存**なのでここには書かない(絶対パスは環境間移動で腐る)。在り処は保守者のローカル memory 側に持つ。

- `dotnet-mcp-skills-カタログ.md` — .NET 向け MCP / skill のカタログ(Aaronontheweb/dotnet-skills の個別評価は 2.4 節)。
