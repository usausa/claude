# 📮 template-spec への申し送り

> DrivenPlatform 再構築（Claude Code 専用版）の検討過程で、**template-spec 側に反映したい**と判断した内容。
> このファイルは受け渡し用。**template-spec へ移動したら本リポジトリからは削除する**。
>
> 作成日: 2026-08-15

---

## 1. 🔀 作業フォルダをブランチと一致させる

### 現状（template-spec）

`work/` 配下にトピック単位でフラットに置いている。

```
work/
├── README.md
├── SPEC-<topic>.md
└── PLAN-<topic>.md
```

### 変更したい形

**作業フォルダ名を現在の git ブランチから決定的に導出する。**

```
work/
├── README.md
└── <branch-name>/          ← ブランチ名から導出
    ├── SPEC.md
    └── PLAN.md
```

### 理由

| # | 内容 |
|---|---|
| 1 | **AI が置き場所を推測する余地がなくなる** — `git branch --show-current` からパスが一意に決まる。トピック名は AI が命名するため揺れる（`SPEC-tags.md` / `SPEC-tagging.md` / `SPEC-file-tags.md` のどれになるか予測できない） |
| 2 | **機械的に強制できる** — PreToolUse フックで「現在のブランチ以外の作業フォルダへの書き込み」を拒否できる。トピック単位では判定条件を書けない |
| 3 | **蒸留し忘れを検出できる** — マージ済みブランチに対応する作業フォルダが残っていれば、クローズ蒸留の漏れ。回帰チェックで機械的に検出可能 |
| 4 | **並行作業が混ざらない** — 複数機能を並行で進めるとき、トピック単位のフラット構成では作業中のファイルが同一階層に混在する。ブランチ単位なら物理的に分離される |
| 5 | **先例がある** — github/spec-kit が `specs/<branch-name>/` を採用している |

### 実装時の論点

1. **ブランチ名の変換** — `feature/foo-bar` のようにスラッシュを含む場合、ディレクトリを掘るか（`work/feature/foo-bar/`）、置換するか（`work/feature-foo-bar/`）
2. **ブランチのリネーム・付け替え** — 追従させるか、手動で移動させるか
3. **ブランチを切らない小変更** — `main` 直下で作業する場合の扱い（`work/main/` を許容するか、ブランチ作成を促すか）
4. **複数ブランチを横断する作業** — 参照のみ許可するか、禁止するか
5. **既存の `SPEC-<topic>.md` からの移行** — 移行スクリプトの要否

---

## 2. 🧩 `docs/architecture/` を「発火条件」で3つに分離する

### 現状（template-spec）

`docs/architecture/` に性質の異なる3種類が同居し、`AGENTS.md` の1行と `/impl`・`/plan` からの名指しで参照されている。

```
docs/architecture/
├── web.md / maui.md / wpf.md / worker.md   # FW固有の実装知識
├── common/*.md                              # 技術共通の原則
└── conventions.md                           # プロジェクト固有の意味ルール
```

### 変更したい形

**「何の知識か」ではなく「いつ読まれてほしいか」で置き場を分ける。**

| 現 architecture の中身 | 移す先 | 発火条件 |
|---|---|---|
| **FW固有の実装知識**（Blazor の書き方・MVVM の作法） | `.claude/skills/<形態>-*/references/` | タスクの種類（description マッチ） |
| **レイヤー固有の規範**（Controller はこう・VM はこう） | **`.claude/rules/*.md` + `paths:` グロブ** | **そのファイルを読んだ時**（機械的） |
| **プロジェクト固有の意味ルール**（conventions.md） | `.claude/rules/conventions.md` + `paths: ["**/*.cs"]` | 対象言語のファイルを読んだ時 |

### 理由

**① `.claude/rules/` は現在まったく使われていないが、公式機能として最も確実な遅延ロード機構**

現状 `.claude/` にあるのは `settings.json`・`agents`・`commands`・`hooks`・`skills` のみ。しかし公式ドキュメントは `paths:` フロントマターについてこう明記している:

> "Path-scoped rules trigger when Claude reads files matching the pattern, not on every tool use."

`conventions.md` は現在 `AGENTS.md` からの1行でしか指されておらず、**AI が実際に読むかは「そう書いてあるから読む」という弱い保証**にとどまる（公式も CLAUDE.md は enforcement ではないと明記）。`.claude/rules/` に `paths: ["**/*.cs"]` で置けば、C# ファイルを読んだ時点で**機械的にロードされる**。

**② 「Controller を編集する時だけ Controller の規範を与える」は skill では実現できない**

skill は description マッチで「タスクの種類」から発火するため、「今どのファイルを触っているか」では発火しない。この要件を満たすのは `paths:` だけ。

**③ 実測でも、レイヤー単位のターゲティングは instructions/rules 層でやるのが唯一の実例**

24リポジトリ・SKILL.md 1,168件を実クローンして調査した結果:

- **skill が外部の `docs/architecture/*` を参照する実例はほぼゼロ**（`docs/` へのリンクは7件、うち architecture 言及は3件で全て「ADR を生成する側」）。理由は、ランタイムが skill ディレクトリ内しか配信しない（Microsoft Agent Framework は2階層まで）ことと、公式が nested reference の部分読み失敗を名指しで警告していること
- **「Controller単位・ViewModel単位の skill」は実例ゼロ**。`maui-skills` 41個に `maui-viewmodel` は無く、`dotnet/skills` の Blazor 9個も「オーサリング上の関心事」で分割。レイヤー単位の skill は**「作られて廃止された」1件のみ**（`application-layer-testing` → `outside-in-tdd` へ統合）
- **唯一レイヤー単位のターゲティングをしている実例（SebastienDegodez）は、skill ではなく instructions の `applyTo:` で実現**している

公式ガイダンスも *"Skills scoped too narrowly force multiple skills to load for a single task, risking overhead and conflicting instructions"* と否定的。

> 📌 この「触ったファイルで発火させる」設計は**独立に3回再発明されている**: Codified Context 論文の trigger table / `adrkit` の `affects` / `vercel/ai` の ADR skill の `Affected paths`。

### 実装時の論点

1. 形態を差し替える際、skill と rules の**両方**を出し入れする必要がある（現状の `setup.ps1 -Form` は docs のみ削除）
2. `references/` と `rules/` で同じ内容を二重に持たない切り分け — **references = 作業全体で参照するレイヤー間の関係 / rules = そのファイルを触る瞬間に効く書き方**
3. 参照切れの検出（skill → references のリンク切れ）。実測では `maui-skills` 39個中**24個**の `references/` が SKILL.md から一度も参照されていない配線漏れがあった

---

## 3. 📖 ADR の「読ませ方」— 決定の帰結を rules に書き下ろす

### 現状（template-spec）

ADR への参照は**すべて「書く側」**（`/adr`・`adr-guide`・`spec-close`・`/done` の有無チェック・`reviewer` の書き漏れ指摘）。**「ADR を読め」という指示は一つも無い。**

これ自体は問題ではない。調査の結果、**ADR を日常的に読ませる運用は業界的にも存在しない**ことが確認できた:

- 一次情報（Nygard・AWS・Google Cloud・Microsoft WAF・ThoughtWorks・Fowler）が想定する読み手は「オンボーディング時の一括読み」と「決定を覆す/レビューする瞬間の検索」のみ。**「日常的に参照し続ける文書」と書いている出典は一つも無い**
- **AGENTS.md 公式サイト・Claude Code 公式 memory ドキュメント・ThoughtWorks の harness engineering 記事は、いずれも ADR に一言も言及していない**
- ADR は不変のアーカイブ（AWS: *"When the team accepts an ADR, it becomes immutable."*）

### 指摘したいギャップ

**「ADR に書いた決定を、日々どう守らせるか」の経路が明示されていない。**

`AGENTS.md` は「決定 → `docs/adr/` に追記」と書くが、その決定の**帰結を運用ルールとして書き下ろす**ステップが無い。ADR は読まれないため、決定は記録された時点で運用から切り離される。

実際、参照実装として調べた `backstage/backstage` では、ADR に規約そのもの（`adr003-avoid-default-exports` 等）が入っているのに `STYLE.md` に転記されておらず、**AI のレビュー採点対象からも外れている**という状態が確認できた。

### 提案

**`/adr` コマンドに「日々守るべきルールが生じたなら `.claude/rules/` にも追記する」ステップを足す。**

```
決定が生じる
   ├─→ /adr で ADR に記録        … なぜ選んだか・何を捨てたか（履歴。読ませない）
   └─→ 日々守るルールが生じたなら rules に書き下ろす
         └─ rules 内に「why は ADR-NNNN」とリンクを張る
```

### 根拠

実務が「決定を日々守らせる」ために採っている手段は3つだけで、そのうち最も軽いのがこの形:

| # | 手段 | 実例 |
|---|---|---|
| **1** | **決定の帰結を rules に書き下ろし、ADR にはリンクだけ張る** | `mattpocock/skills`（217k stars）— *"Why a Claude plugin but not (yet) a Codex one lives in `.agents/adr/0002-...`"* |
| 2 | ADR 自体に `paths:` を持たせ、触った時だけ注入 | `adrkit` の `affects` + MCP `get_decision_context(files[])` |
| 3 | 決定論的ゲートで強制 | PreToolUse hook・CI のフィットネス関数 |

**②は結局 `rules` 機構の再実装になる**ため、①が最も筋が良い。

なお **MADR の `Confirmation` フィールド**は、決定の強制手段を「フィットネス関数（ArchUnit 等）かコードレビュー」と定めており、この提案と整合する。逆に **Nygard の `Consequences` に強制の意味論は無い**（*"the resulting context, after applying the decision"*）ため、「Consequences に規約へのポインタを置く」を原典に根拠付けることはできない。

> ⚠️ **注意**: 「ADR corpus と派生規約文書の両方を維持し、その同期プロセスを記述した事例研究」は**公開文献に存在しない**。つまりこの提案は先行事例の踏襲ではなく設計判断であり、同期の運用（ADR を supersede した時に rules をどう直すか）は自前で設計する必要がある。

---

## 4. 💡 参考: DrivenPlatform 側で採る、あえて異なる方針

**template-spec に変更を求めるものではない**が、判断材料として記録しておく。

### work/ の git 管理

| | template-spec | DrivenPlatform |
|---|---|---|
| 方針 | **gitignore**（`work/*` + `!work/README.md`） | **git 管理する** |
| 理由 | 「どうせクローズ時に削除する一時物を履歴に残さない」という一貫性 | 仕様レビュー・worktree・担当者交代・CI 検証を成立させる |

調査で判明した事実（出典は DrivenPlatform 側 `docs-maintenance/27_ドキュメント配置の調査.md`）:

- **主要 SDD ツールは spec/plan をコミットするのが多数派** — OpenSpec は *"You commit `openspec/` like any source."* と明記。spec-kit も利用者側では `specs/` をコミットする（同リポジトリ自身が gitignore しているのは *"meant for dogfooding"* と明記されており、利用者への推奨ではない）
- gitignore した場合の実害:
  - **仕様をレビューできない** — AI 生成コードは同じモデルが実装に合わせてテストも書くためテストが独立検証にならず、仕様を人間が見る価値が上がっている
  - **worktree・新規 clone に存在しない** — Claude Code 公式: *"A worktree is a fresh checkout, so untracked files ... are not present."*（`.worktreeinclude` で緩和可能だがチーム共有にはならない）
  - **担当者交代・別マシンで文脈が消える** — Claude Code の auto memory もマシンローカルで共有されない
  - **CI で spec を検証できない**

> 📌 どちらが正しいかは**運用規模による**。個人〜小規模・同一マシン中心なら gitignore で問題なく、チーム開発・仕様レビュー重視なら コミットが有利。
> template-spec の `docs/guides/workflow.md` は再開について「`work/` の SPEC/PLAN を見れば現在地を復元できる」と書いているが、これは**同一マシンでの新セッション**を前提としている。チーム運用を想定するなら再検討の余地がある。

---

## 5. 📎 補足: 調査で確認できた公式仕様（template-spec の設計にも関係しうる）

出典は Claude Code 公式ドキュメント（https://code.claude.com/docs/en/memory ・ /skills）。

| # | 事実 | template-spec への含意 |
|---|---|---|
| 1 | **`@path` インポートは遅延ロードではない** — *"imported files still load and enter the context window at launch"*。公式は *"Splitting into @path imports helps organization but doesn't reduce context"* とも明記 | `CLAUDE.md` → `@AGENTS.md` は**整理のため**であり、コンテキスト削減にはならない。`AGENTS.md` 自体を薄く保つ必要がある |
| 2 | **`.claude/rules/` の `paths:` フロントマターが本物の遅延ロード** — 該当パスのファイルを読んだ時だけロードされる | 形態別の原則（`docs/architecture/<form>.md`）を常時ロードさせず、`paths:` でスコープした rules に置く選択肢がある |
| 3 | **skill は補助ファイルを同梱できる** — `references/` 等に置き、必要時のみ読まれる（3段階の progressive disclosure）。*"SKILL.md は500行未満に"* | 形態固有の詳細を skill 側に持たせる設計が公式にサポートされている |
| 4 | **CLAUDE.md は200行未満が目標** — *"Files over 200 lines consume more context and may reduce adherence."* | — |
| 5 | **ブロックレベルの HTML コメントは注入前に除去される** | メンテナ向け注記をトークン消費ゼロで書ける（`<!-- sdd:... -->` マーカーは既にこの恩恵を受けている） |
