# コンテキスト構造の再設計 (発火条件ベース)

> テンプレ保守の方針書。**承認済み (2026-08-17)・実施中**。完了後は経緯記録として残す。
> 入力: [drivenplatform-handover.md](drivenplatform-handover.md) (DrivenPlatform 検討からの申し送り) + 2026-08-16 の方針指示
> 作成: 2026-08-16

## 1. 目的

ドキュメントを「何の知識か」でなく「**いつ適用されるか (発火条件)**」で配置し、AI が読む保証を機械化する。

## 2. 確定方針 (人の指示済み)

| # | 方針 |
|---|---|
| 1 | **skills はプラットフォーム (アプリ形態) 非依存**とし、主にフロー (工程) に関するものを用意する。ツール依存は .NET まで許容 |
| 2 | **アーキテクチャ規範は Path-Scoped Rules** (`.claude/rules/*.md` + `paths:`) で適用する |
| 3 | **初期化で、どの rules をコピーするかを決定**する (採用形態による選定) |
| 4 | **Claude 専用に割り切る** (Codex 互換は考慮しない)。`AGENTS.md` は参照のみを残して薄くする |
| 5 | **`/adr` は rules を作成するステップを持つ** (決定の帰結を日々のルールとして書き下ろす) |
| 6 | **work/ は git 管理へ変更**。初期化 skill がブランチと同期し、完了 skill が片付けを行う。初期化・完了以外の skill はブランチ・ディレクトリ構造に非依存とし、どちらの方式でも使える。フロー: (初期化) - スペック - プラン - 実装 - レビュー - (完了)。初期化と完了は必須にしない |
| 7 | **rules は ADR の代替にしない**。rules は決定の「機械制約」としての面を仕組み化するもの (ADR 的な意味を含んでよい)。`docs/adr` は本来の ADR として残す。**両者は独立して保管し、相互リンクは持たない** (rule → ADR は無し。ADR → rule も必然ではない) |
| 8 | **ADR の編集は手動が基本・作製タイミングは任意**。skill の支援は枠の用意・コンテキストからのドラフト作製まで。一般 rules は初期化時にコピーし、**ルール作製スキル**がプロジェクト固有の rules を追加していく |
| 9 | ADR を機械的に参照する経路として、**/spec /plan /review に「docs/adr を参照し準拠を確認する」記述を追加**する |
| 10 | **完了 skill のメイン = 最終プッシュ・ブランチ削除・work 配下のブランチフォルダ削除**。蒸留すべき内容があれば削除前に確認を出し ADR の枠を用意する (通常はあまりないケースの想定) |
| 11 | **/review が見るのは ADR** (+ 既存 checklist)。**rules はレビューで見ない** — rules は実装時に `paths:` で機械的に効いており、レビューでの再確認は重複になるため |
| 12 | 作業フォルダは **`docs/work/`** に置く (リポジトリ直下 `work/` から移動) |

## 3. 新しい三層構造

| 層 | 発火条件 | 置き場 | 内容 |
|---|---|---|---|
| **フロー skill** | タスクの種類 (description マッチ / 明示呼び出し) | `.claude/skills/` `.claude/commands/` | 工程の進め方。形態非依存 (.NET ツール依存は可) |
| **アーキ規範 rules** | 対象ファイルを読んだ時 (`paths:` グロブ) | `.claude/rules/` | 現 docs/architecture の全内容 (形態別 + common + conventions) |
| **入口** | 常時ロード | `AGENTS.md` (CLAUDE.md が import) | 地図と参照のみ。200 行未満を維持 |

## 4. rules の設計

### 4.1 配布モデル (コピー方式)

- 原本はカタログ **`.setup/rules/`** に全形態分を持つ。
- `setup.ps1 -Form <form>` が採用形態に応じて **`.claude/rules/` へコピー**する (現行の「非採用を削除」から転換)。
- 利点: 原本リポジトリ自体の保守作業中に、アプリ向け rules が誤発火しない。「どれをコピーするか」の決定表が setup.ps1 に一元化される。
- オプション要素 (grpc / cli) は setup.ps1 の引数 (例: `-Include grpc,cli`) で**指定された時だけコピー**する。既定は含めない (非採用形態を削除する現行の流儀と同じ)。コピーされた後も paths が狭いため、該当ファイルを触るまでは発火しない (二重の安全)。

### 4.2 現 docs/architecture → rules マッピング案

paths は初期案。移行時に実コードのフォルダ規約 (csharp-layered-feature 参照) と突き合わせて精査する。

| 現 doc | rule | paths 案 | コピー条件 |
|---|---|---|---|
| conventions.md | conventions.md | `**/*.cs` | 常時 |
| common/coding-principles.md | coding-principles.md | `**/*.cs` | 常時 |
| common/async.md | async.md | `**/*.cs` | 常時 |
| common/errors.md | errors.md | `**/*.cs` | 常時 |
| common/logging.md | logging.md | `**/*.cs` | 常時 |
| common/security.md | security.md | `**/*.cs` (要精査) | 常時 |
| common/data.md | data.md | `**/Data/**` `**/*Accessor*.cs` `**/*Repository*.cs` | 常時 |
| common/http-client.md | http-client.md | `**/*Client*.cs` `**/Clients/**` | 常時 |
| web.md | web.md | `src/**` | web |
| api.md | api.md | `**/Controllers/**` `**/Endpoints/**` | web |
| blazor.md | blazor.md | `**/*.razor` `**/*.razor.cs` `**/Components/**` `**/Pages/**` | web (Blazor 採用時) |
| mvvm.md | mvvm.md | `**/ViewModels/**` `**/*ViewModel*.cs` | maui / desktop |
| maui.md | maui.md | `**/*.xaml` `**/Platforms/**` | maui |
| wpf.md | wpf.md | `**/*.xaml` `**/*.xaml.cs` | desktop |
| desktop.md | desktop.md | `src/**` | desktop |
| worker.md | worker.md | `**/*Worker*.cs` `**/*Job*.cs` `**/Workers/**` | worker |
| (skill: blazor-playwright) | blazor-e2e.md | `tests/**/*E2ETests*/**` `**/playwright.config.*` | web (Blazor 採用時) |
| (drafts: grpc.md) | grpc.md | `**/*.proto` `**/Grpc/**` | オプション (`-Include grpc`) |
| (drafts: cli.md) | cli.md | `**/Commands/**` (Commands フォルダ前提) | オプション (`-Include cli`) |

### 4.3 rules の記述規律

- rules は「そのファイルを触る瞬間に効く**書き方の規範**」に絞る。1 本を簡潔に保つ (目安 50 行)。
- 背景・選定理由は ADR へ (rules からは `why: ADR-NNNN` でリンク)。
- 常時発火 (`**/*.cs`) の rules は合算ロード量に上限意識を持つ (合計の目安を移行時に計測して決める)。
- 人間の読み物としても rules を正とする (docs/architecture は残さない。地図は `AGENTS.md` と `docs/README.md` に置く)。

### 4.4 参照保証の機械化 (腐敗・未参照の防止)

- **paths を決められない規範は rule にしない** — 発火しない rule = 参照されないドキュメント。近縁の rule に節として吸収する。
- **新設場面の発火ギャップを埋める**: rules は「ファイルを読んだ時」に効くため、対象がまだ存在しない新設場面 (プロジェクト・フォルダの新規作成) では発火しない。新設の入口 (命名規約と最初の一歩) は上位の広い rule に 1 行のポインタで持たせる。例: E2E プロジェクトの新設 → rules/testing.md (`paths: tests/**`) に「E2E は `tests/<App>.E2ETests`、手順と注意は blazor-e2e」の 1 行。命名規約に従って最初のファイルを作った時点から blazor-e2e が自動発火する。
- **test-setup.ps1 に検証を追加**: rules フロントマター (`paths:`) の構文 / rules・skills 内のリンク切れ / カタログの全 rule がいずれかの Form またはオプションのコピー表に載っていること (コピーされないカタログ項目を作らない)。
- **PreToolUse フック (採否 → 10.)**: 現ブランチ以外の `docs/work/<slug>/` への書き込みを拒否する (申し送り理由 2 の機械強制。`docs/work/` 直下は許容し 6.3 の両方式と両立)。

## 5. skills / commands の仕分け

| 現在 | 新 | 扱い |
|---|---|---|
| /spec, /plan, /impl, /review, /verify, /done, /reference | 中間フロー | 維持。**作業フォルダ解決規則** (6.3) を組み込み、置き場非依存に改修。**/spec /plan /review には docs/adr の参照・準拠確認ステップを追加** (7.) |
| spec-close skill (lite) | **work-close skill (完了)** | 置換。最終プッシュ・ブランチ削除・作業フォルダ削除がメイン。蒸留は例外時のみ (6.4)。full の spec-close (SPEC 蒸留) は存続し work-close から参照 |
| (新規) | **work-init skill (初期化)** | ブランチ確認・作成 + `docs/work/<branch-slug>/` 作成 |
| (新規) | **ルール作製スキル** | プロジェクト固有 rule の追加・既存 rule への追記 (7.) |
| /adr + adr-guide skill | /adr (ドラフト支援) | 改修。ADR は手動編集が基本・タイミング任意という位置づけに変更。採番・index 追記・枠 / ドラフトの用意は支援として維持 |
| git-commit skill | **コミット・プッシュ skill** | 改組・拡張。規約 (Conventional Commits・ブランチ名・ステージング単位) を核に、**途中プッシュ (他者レビュー用) のフロー**を追加。完了 skill の最終プッシュもこれに委譲し、git 操作の型を一元化する |
| csharp-layered-feature, sync-docs-from-code | 維持 | 形態非依存・.NET 依存の範囲内。参照先を rules に張り替え |
| blazor-playwright | **rules 化 (確定)** | `blazor-e2e.md` として rules カタログへ (4.2)。skill は廃止。これで .claude/skills は全て形態非依存になり、setup の出し入れ対象が rules だけに単純化される。新設時の発火ギャップは testing rule のポインタで埋める (4.4) |
| /review-cross (Codex 用) | **要決定** | Claude 専用化に伴い削除候補 |
| /pm-plan, /pm-status | 維持 | 影響なし |

## 6. 作業フォルダ (docs/work/) の運用変更

### 6.0 置き場の移動

- リポジトリ直下の `work/` を **`docs/work/`** へ移動する。docs/README.md の寿命クラス表には work/ (一時物クラス) が既に 1 行として載っており、移動により「文書はすべて docs/ 配下・寿命はクラス表が契約」に一元化される (表の場所列と ID 体系の記述を更新)。

### 6.1 git 管理化

- `.gitignore` の `work/*` 除外を撤廃し、docs/work/ をコミット対象にする。
- 理由 (申し送り 4. の調査結果): 仕様の人間レビュー・worktree / 新規 clone での再現・担当者交代・CI 検証が成立する。SDD ツールの多数派 (OpenSpec 等) と一致。
- 「一時物」の性格は維持する: 完了時にクローズ蒸留して**削除**する運用は変わらない (git 履歴には残る = レビュー可能性の獲得)。

### 6.2 初期化 skill (任意)

1. 現在のブランチを確認。main 直下なら作業ブランチの作成を促す (git-commit skill の命名規約)。
2. ブランチ名から作業フォルダを導出: `docs/work/<branch-slug>/` (スラッシュは `-` に置換。例 `feature/foo-bar` → `docs/work/feature-foo-bar/`)。
3. SPEC.md / PLAN.md の置き場をこのフォルダに確定する。

### 6.3 作業フォルダ解決規則 (中間フローが共有)

```
1. docs/work/<current-branch-slug>/ が存在する → それを使う
2. 存在しない → docs/work/ 直下 (従来の SPEC-<topic>.md 形式) を使う
```

- 中間フロー (/spec /plan /impl /review) はこの規則だけに依存し、ブランチ運用・git 管理の有無を知らない。
- これにより初期化・完了は必須でない: main 直下の小変更は従来どおり docs/work/ 直下フラットで回せる。

### 6.4 完了 skill (任意。従来の spec-close を置き換え)

メインは片付け: **最終プッシュ・ブランチ削除・docs/work 配下のブランチフォルダ削除**。

1. 蒸留チェック (例外処理): SPEC / PLAN に恒久化すべき内容 (決定・用語) が残っていないか確認。あれば**削除前に人へ確認を出し、ADR の枠を用意**する。通常は実装中に ADR / rules へ落ちている想定で、空振りが正常。
2. 作業フォルダ (6.3 で解決した場所) を削除。
3. 最終コミット・push は**コミット・プッシュ skill に委譲**し、(マージ後の) ブランチ削除まで導く (Git 操作は人間実行の現規約を維持し、コマンド列を提示。実行まで任せるかは 10.)。
4. 孤児検出: マージ済みブランチに対応する `docs/work/*/` の残存を警告 (git 管理化により機械検出が可能になる)。初期化 skill 実行時にも同じ検査を行う。

### 6.5 付随修正

- `AGENTS.md` の DoD「`work/` が空」→「自分の作業フォルダがクローズ蒸留済み (削除済み)」。`work/` への言及はすべて `docs/work/` へ張り替え。
- `work/README.md` は `docs/work/README.md` へ移動し新運用に改稿。`docs/guides/workflow.md` も改稿 (別マシン再開の記述は「git 管理のため clone で再現される」に更新)。
- `setup.ps1 -Sdd full` (docs/spec 恒久保存) との整合は別途確認 (今回は lite 基準の変更)。

## 7. ADR と rules の分担

|  | docs/adr | .claude/rules |
|---|---|---|
| 性格 | 本来の ADR: なぜ選んだか・何を捨てたかの**履歴** (不変・追記のみ) | 決定の**機械制約**としての面: ファイルを触る瞬間に効く書き方の規範 |
| 作られ方 | **手動が基本**・タイミング任意。skill は枠の用意・会話からのドラフト作製の支援まで (/adr を改修) | 一般 rules = 初期化時にカタログからコピー。プロジェクト固有 rules = **ルール作製スキル**で追加 |
| 読まれ方 | /spec /plan /review が `docs/adr/index.md` を確認し、関連する決定への準拠を確認する | `paths:` により機械ロード |
| 相互リンク | **持たない** — 独立して保管する存在 | 同左 (rule → ADR のリンクは書かない) |

- **ルール作製スキルの責務**: 出力先の判断 (既存 rule への追記 / 新設)・`paths:` の設計と検証 (発火しない rule を作らない)・既存 rules との重複・矛盾チェック・簡潔性 (4.3) の維持。
- **中間フローへの追記**: /spec =「index.md を確認し、関連決定と矛盾する場合は SPEC に明記して人に確認」/ /plan =「PLAN が既存決定と矛盾しないか確認」/ /review = review-checklist.md に「既存 ADR への準拠」観点を追加。**レビューは rules を見ない** (rules は実装時に効いている。再確認は重複)。
- **supersede 時**: 相互リンクを持たないため機械同期は行わない。adr-guide に「決定を覆した時は関連する rules の見直しも検討する」の注意を 1 行置く (発見は 7.1 のタグ・語彙の一致で足りる)。
- `_template.md` の「結果」節は 3 点セット構造 (得たもの / 捨てたもの / 将来への注意) に更新 (HANDOVER 4.3 の逆輸入)。

### 7.1 docs/adr の管理体系

**フラット連番を維持し、関連はメタデータと生成 index で見せる。**

| 項目 | 設計 |
|---|---|
| ファイル | `NNNN-<kebab-title>.md` のフラット連番を維持 (時系列 = 履歴の本質。max+1 採番の機械化が単純なまま) |
| 関連の表現 | frontmatter に `tags:` (1〜3 個) と `related:` (ADR 間の相互参照)。既存の `status:` / `superseded-by:` と合わせてメタデータに寄せる |
| タグの語彙 | 事前の固定リストは用意しない。**第一候補 = rules のファイル名語彙** (data / api / logging / testing / domain 等)、足りなければ glossary のドメイン語。「共通」のような何でも入るタグは用意しない (分類として機能しない) |
| index.md | **frontmatter からの生成物にする** (手編集しない — docs/reference と同じ規律で腐敗を防ぐ)。タグ別セクション + 時系列全列挙の 2 部構成。/adr (ドラフト支援) が再生成する |
| 準拠確認との接続 | /spec /plan /review は「変更に関連するタグの ADR に絞って読む」— 全読みを避け、件数が増えても参照コストを一定に保つ |
| 後からの再分類 | メタデータ行の追加・修正は許容 (本文は不変。「status 行の更新のみ許容」という既存規約の自然な拡張) |

サブディレクトリ案・先頭数字グループ案を採らない理由:

1. 分類の**事前確定**が必要になり、置き場を推測する余地 (申し送りが排除したもの) が ADR 側で復活する
2. 複数領域にまたがる決定 (例:「API のエラー応答形式」= api + errors) を 1 箇所に置けない。タグなら複数付与できる
3. カテゴリの改廃がファイル移動を生み、「過去 ADR は編集しない」と衝突する。メタデータ方式なら本文不変のまま再分類できる
4. 想定規模 (プロジェクトあたり数十件) ではフラット + 生成 index で十分見通せる

## 8. drafts 取り込み先の再マッピング

突合せ結果 (HANDOVER 4.)・決定待ち (D6 / D7 / D8)・バッチ順は**全て有効のまま**。取り込み先のみ読み替える:

| ドラフト | 旧取り込み先 | 新取り込み先 |
|---|---|---|
| logging | common/logging.md | rules/logging.md (要 D6) |
| telemetry | 新規 common/telemetry.md | 単独 rule にしない (4.4 の原則)。計装の一般原則は rules/logging.md、観測性の具体は rules/web.md / rules/worker.md の節へ吸収 |
| async | common/async.md | rules/async.md |
| error-handling | errors + api + conventions に 3 分割 | rules/errors.md + rules/api.md + rules/conventions.md (分割方針は同じ) |
| mvvm / blazor | mvvm.md / blazor.md | rules/mvvm.md / rules/blazor.md |
| domain | 新規 common/domain.md | rules/domain.md (新規。paths: `**/Domain/**` 等) |
| data-access | common/data.md | rules/data.md |
| testing | tests/README 追記 | **rules/testing.md (新規。paths: `tests/**`)** — 新構造で発火条件が明確になり従来案より改善 |
| di-configuration | coding-principles か各形態 doc | rules/coding-principles.md か各形態 rule (分解方針は同じ) |
| worker-patterns | worker.md | rules/worker.md (要 D8) |
| grpc / cli (枠 doc) | 新規 doc + optional/ 案 | **確定**: setup オプション (`-Include grpc,cli`) 指定時のみコピーするオプション rules (4.1)。paths は grpc = `**/*.proto` `**/Grpc/**`、cli = `**/Commands/**` (Commands フォルダ前提)。cli の `Components` 改名・ExitCode 255 注記は取り込み時に実施 |
| generator | 新規 generator.md (枠のまま) | **確定: 標準で用意するファイルからは外す** (いったん見送り)。骨子は backlog へ退避し、必要になったプロジェクトでルール作製スキルにより起こす |
| aws-lambda | 取り込まない | 変更なし (TODO は backlog へ) |
| ADR サンプル 4 本 | 見本として残す | **解決**: ADR / rules 分離により置き場が確定 — 手動 ADR の見本として **adr-guide skill の references/ に厳選して置く** (docs/adr の index を汚さず、skill から確実に参照される)。4 本全部は移植せず見本価値の高いものを選ぶ。形式修正 (id 重複・related 空・status 矛盾) は移植時に実施 |

## 9. 移行手順 (コミット分割)

| # | 作業 | コミット |
|---|---|---|
| 0 | Batch 1 (http-client) コミット | 済 (2b1f60d) |
| 1 | 本方針書の承認 | 済 (2026-08-17) |
| 2 | rules 化: `.setup/rules/` カタログ新設・現 docs/architecture 全 17 本を移設改稿・AGENTS.md 参照張り替え | `refactor(context)` **済** (#3 と統合) |
| 3 | setup.ps1 / test-setup.ps1 改修 (コピー方式) + 回帰 ALL PASS | **済** (#2 に統合。各コミットで ALL PASS を保つため) |
| 4 | 作業フォルダ運用変更: `docs/work/` への移動・.gitignore・寿命クラス表更新・work-init / work-close skill・git-commit skill 拡張 (途中プッシュ)・中間コマンド改修・workflow.md | `feat(sdd)` |
| 5 | ADR / rules 分担: rule-create skill 新設・/adr ドラフト支援化 (tags / related・index 生成)・/spec /plan /review への ADR 参照追記・review-checklist に ADR 準拠観点・_template.md | `feat(adr)` **済** |
| 6 | drafts 取り込み再開 (logging から。新マッピング) | バッチ毎 |

## 10. 未決事項 (承認時に確認)

解決済み: /adr の位置づけ (→ 7.) / ADR サンプルの置き場 3 択 (→ 8. adr-guide references 案) / telemetry の paths (→ 4.4 の吸収原則) / blazor-playwright の扱い (→ 5. rules 化で確定) / 枠 doc の配布方式 (→ 4.1・8. grpc / cli は setup オプション指定時のみコピー、cli は Commands フォルダ前提、generator は標準から外し backlog へ)。

1. **/review-cross の削除可否** (Claude 専用化に伴う)
2. **常時発火 rules の合算ロード量** — 計測済み (2026-08-17): 常時 (`**/*.cs`) 6 本 = 108 行 / 7.0 KB、形態別 `src/**` 追加分 = worker 44 行〜web 92 行。公式の CLAUDE.md 目安 (200 行) の半分程度で、かつ対象ファイルを読む時だけのロード。**問題なしと判断** (異議があれば削減する)
3. **バッチ順への telemetry の挿入位置** (logging 直後を提案)
4. **PreToolUse フックの採否** (現ブランチ以外の `docs/work/<slug>/` への書き込み拒否。4.4)
5. **コミット・プッシュ / 完了 skill の git 操作の実行主体** — 提示のみ (現規約維持) か、skill 内で実行まで任せるか
