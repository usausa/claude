---
name: impl
description: 承認済みプランに沿ってフェーズ実装する。csharp-layered-feature の手順・警告ゼロ・PLAN チェック更新。
---

> 引数: [対象フェーズ (省略時は次の未完フェーズ)]

承認済みの実装プランに沿って実装する。

1. 作業フォルダ(解決規則は `docs/work/README.md`)の PLAN と対象の SPEC(作業フォルダまたは `docs/spec/SPEC-*.md`)を読む
2. $ARGUMENTS のフェーズ(省略時は次の未完フェーズ)を実装する:
   - `csharp-layered-feature` の手順に沿う(レイヤ責務はアーキ規範 rule が対象ファイルで自動適用。上位は薄く、下位へ委譲)
   - ビルド警告ゼロを保つ。受け入れ条件はテスト名に込める
3. 完了した項目を PLAN の `- [x]` に更新する
4. フェーズ末に `/verify`(build + test 緑)で確認する
