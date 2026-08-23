# 引き継ぎ (2026-08-18): コンテキスト再構築 完了 → 実運用検証へ

> 環境をまたぐ引き継ぎ資料。**このファイルは git 管理されているため、clone / pull だけで新環境に届く**(旧方式の `template-drafts/HANDOVER.md` は役目を終えた。ドラフトのフォルダごと削除する)。
> 残作業が完了したらこのファイルは削除してよい(決定は decisions.md、経緯は restructure-context.md に残る)。

## 1. 現在地 (完了したこと)

**コンテキスト構造の「発火条件」ベース再構築と、template-drafts の取り込みがすべて完了**している。

- **rules**: アーキ規範は `.setup/rules/` カタログ (20 本) に置かれ、`setup.ps1 -Form <form> [-Include grpc,cli]` が共通 + 採用形態分を `.claude/rules/` へコピーする (`paths:` で対象ファイルを読むと自動適用)
- **skills**: 全て形態非依存のフロー (`work-init` / `work-close` / `rule-create` / `adr-guide` (+references に SAMPLE-01〜04) / `csharp-layered-feature` / `git-commit` / `sync-docs-from-code` / `spec-close` (full のみ))
- **作業フォルダ**: `docs/work/` (git 管理・完了時削除)。解決規則 = ブランチフォルダ優先・無ければ直下 (正は `docs/work/README.md`)
- **ADR**: 手動基本・`/adr` はドラフト支援。`tags` / `related` メタデータ + index は生成物。rules とは独立保管
- 設計と経緯 = [restructure-context.md](restructure-context.md) / 決定 = [decisions.md](decisions.md) / 未決 = [backlog.md](backlog.md)
- 回帰テスト (`pwsh .setup/maintenance/test-setup.ps1`) は ALL PASS の状態

## 2. 新環境での初回手順

1. `template-spec` を git pull (この資料と全成果物が届く)
2. AI に下記 4. の指示プロンプトを渡す
3. AI は下記 3-A の memory を再投入してから残作業プランを再開する

### 3-A. memory 再投入の内容 (パスは環境の配置に読み替え)

1. **プロジェクト認識 (type: project)**: `template-spec` = template-aidd 原本。保守の正は `.setup/maintenance/` (入口 MAINTENANCE.md)。現況 = コンテキスト再構築 + drafts 取り込み完了 (2026-08-18)・実運用検証段階 (残作業は `.setup/maintenance/handover-2026-08.md`)。git 操作はコマンド提示が既定、`work-close` / `git-commit` skill として依頼されたときは AI 実行可。
2. **関連資産の地図 (type: project)**: `template-architecture` (実プロジェクト群から逆蒸留した規約の正典・WIP・git) / `dotnet-performance` (高速化パターン集・git) / `dotnet-mcp-skills-カタログ.md` (MCP / skill 選定カタログ)。`template-drafts` は取り込み完了につき削除済み (残っていたら削除する)。絶対パスは repo に書かず memory で持つ。
3. **文体ルール (type: feedback)**: ASCII 記号は半角 (中黒「・」は全角)・`§` 禁止・冗長括弧禁止・否定の明示 (「X は使わない」) は書かず正の記述のみ・docs 系は括弧前に半角スペース (`.claude/` 配下は既存様式に合わせる)。

## 3. 残作業プラン

### A. 仕上げ (小・各環境)

1. **template-drafts フォルダの削除** — git 外の一時物。取り込み完了につき各環境のローカルコピーを削除する (この資料が代替)
2. **DrivenPlatform 側の申し送り元ファイル削除** — `GitHubTemplate/template-spec/template-spec申し送り.md` (受け渡し完了。写しは `.setup/maintenance/drivenplatform-handover.md`)

### B. 実運用検証 (新環境の本命タスク)

1. **rules の実発火確認** — テンプレから実プロジェクトを setup し、C# ファイル・Domain・tests 等を触ったときに該当 rule がロードされるか確認する (`/context` で確認。InstructionsLoaded フックでログも可)。特に paths が実フォルダ構成と合うか: `data.md` (`**/Services/**`) / `api.md` (`**/Endpoints/**`) / `domain.md` (`**/Domain/**`) / `http-client.md` (`**/*Client*.cs`)
2. **setup.ps1 の実行確認** — 各 `-Form` (+ `-Include grpc,cli`) の成果物を実際に使い、rules・skills・docs の過不足を見る
3. **docs/work フローの一巡** — `work-init` → `/spec` → `/plan` → `/impl` → `/review` → `/done` (`work-close`) を実案件で回し、解決規則・git 管理・AI 実行 (skill 依頼時) の使用感を確認する
4. **ロード量の体感確認** — 常時発火 (`**/*.cs`) 6 本 + 形態別。重いと感じたら rules の圧縮を検討 (計測値は restructure-context 10.)

### C. 継続項目 (backlog.md が正)

winui.md の執筆 / generator・aws-lambda (採用時に rule 化。骨子は backlog に退避済み) / PreToolUse フック (作業フォルダ誤書き込み拒否) / hooks の非 Windows 対応 / D7 (テスト命名 — template-architecture のテスト doc 執筆時に決着) / Aaronontheweb skill の追加蒸留 / CPM ほか

### D. template-architecture への逆輸入 (別リポジトリの作業)

arch は WIP の正典。drafts 突合せで判明した「arch 側の取りこぼし」を逆輸入する余地がある: http-client 全体 / ログレベル使い分け表 / IsEnabled + SkipEnabledCheck / DI の形態差 / domain の命名語彙。既知の別件 = spec の Analyzers.ruleset CA2007 全体 Hidden vs arch 決定 #11 の整合 (未決)。

## 4. 指示用プロンプト (新環境の初回セッションにコピペ)

```
template-aidd 原本 (template-spec) の保守を別環境から引き継ぎます。

前提: コンテキスト構造の再構築と template-drafts の取り込みは完了済み。経緯と現在地は
.setup/maintenance/handover-2026-08.md に集約されている。

最初にやること:
1. .setup/maintenance/MAINTENANCE.md と .setup/maintenance/handover-2026-08.md を全文読む。
2. handover の 3-A に従って memory を再投入する (パスはこの環境の配置で書く)。
3. handover の「3. 残作業プラン」の A (仕上げ) から順に着手する。B (実運用検証) は
   私が対象プロジェクトを指定してから進める。

役割分担: 方針の決定と commit は私 (人間)、改稿・検証・進捗更新はあなた (AI)。
毎バッチ「差分提示 → 私が承認 → commit」。git 操作はコマンド提示が既定だが、
work-close / git-commit skill として依頼したときは実行までしてよい。
テンプレを変更したら pwsh .setup/maintenance/test-setup.ps1 の ALL PASS が完了条件。
```
