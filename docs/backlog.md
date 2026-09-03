# 検討事項(未決 TODO)

> 設計上まだ確定していない・今後見直す論点。**確定したら本体へ反映して [decisions.md](decisions.md) に記録を移し、ここから消す**。
> 2026-09-03 に整理: プラグイン化で失効・完了した項は削除した(経緯は git 履歴)。

## 実運用で確定する(ドッグフーディング・実プロジェクト一巡と併走)

- **SPEC(機能単位)に何を残すか** — 「非復元の意図だけ残す」基準は確定済み。恒久的に持たせる中身の線引きは実運用で観察して確定(full の蒸留対象)
- **SDD lite の検証** — クローズ蒸留で意図が十分残るか / テスト名 = 受け入れ条件の規律が維持できるか / 既定(full)の妥当性
- **lite の ceremony の厚み** — Spec Kit の `/clarify` / `/analyze` 相当を「未決事項 + 人レビュー」に畳んでいる。複雑機能で前捌きが薄くないか
- **`/done` クローズ蒸留の安全網** — 「テスト / ADR / glossary のどれにも載らず消える意図はないか」の明示チェックを足すか(lite の情報損失リスク対策)

## 機構・拡張

- **aidd.md の撤廃検討** — 常時適用 rule は最小限に保つ方針のため、SDD レベルの持ち方(フロー skill が都度読む設定ファイル化等)を再確認して撤廃できるか判断(2026-09 の仮置き)
- **担保のハード強制** — `/done` ゲートを Husky.Net pre-commit / CI へ移設するか(バイパス不能化。slopwatch も部品候補)。現実解の候補: pre-commit は軽く + CI で二段
- **非 Windows 対応** — hooks(source-normalize / dotnet-verify / done-check)と init は PowerShell 前提。macOS / Linux で使うなら代替が要る
- **PreToolUse フック(作業フォルダの誤書き込み拒否)** — 現ブランチ以外の `docs/work/<slug>/` への書き込み拒否。非 Windows 対応と合わせて検討
- **doc-sync agent の役割整理** — reference skill が手順を直接持ち、doc-sync agent はどこからも呼ばれていない。委譲に一本化するか廃止するか

## 規範の追加候補

- **winui 規範** — `dotnet-winui` rule の追加のみで対応可(desktop 系の枠は設計済み)
- **aws-lambda 規範** — 未執筆(規範のない枠は置かない)。ハンドラ属性 + Source Generator 宣言 / プラットフォームロガー + LoggerMessage / コールドスタート対策(R2R + arm64)/ SAM デプロイ。書けた時に rule 新設
- **UI テストの対称展開** — MAUI(`maui-appium` 等)/ Desktop(FlaUI 等)の E2E 規範を blazor-e2e と同じイディオムで用意するか。`/verify` での E2E 実行方針(実行時間が問題化したら `[Trait("Category", "E2E")]` で分離)
- **Aaronontheweb/dotnet-skills の蒸留候補** — slopwatch(ハード強制と連動)/ Aspire 系(実装開始時)/ EF Core 系(採用時)。一括導入せず cherry-pick + 日本語蒸留の方針は確定済み

## その他の保留

- CPM(`Directory.Packages.props`)/ `global.json` の採用可否
- 汎用プロンプト集(bug-fix / test-gen 等)の扱い
- ドキュメントの分離(人専用文書・重いアセットが増えた場合の `docs/assets/` 等)
- nested `AGENTS.md` / org での AGENTS.md 必須化(組織側の論点)
- 検討事項の運用の Issues 化(複数人・複数 AI 体制になったら)
- リポジトリ改名の要否(usausa/template-spec のまま使うか)— 人の判断
