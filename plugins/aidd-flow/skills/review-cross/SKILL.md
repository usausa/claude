---
name: review-cross
description: 別ベンダー (Codex) でクロスレビューするための手順とコマンドを用意する。バイアス排除の第二の目。
---

同一ベンダーのバイアスを避けるため、Claude の `/review` とは別に **Codex でもレビュー**する (Codex 利用可の環境が前提)。

1. レビュー対象の変更を確認する (`git diff` 等)。
2. 次の内容で codex を起動するよう、**人にコマンドを提示**する:
   - 参照させるもの: プロジェクトの規約 (AGENTS.md 等があれば)、レビュー観点 (`review` skill の references/review-checklist.md の内容を**プロンプトに展開**して渡す — Codex はプラグイン内ファイルを知らないため)、対象の SPEC、変更差分。
   - 例:
     ```
     codex "以下のレビュー観点で直近の変更をレビューして。<references/review-checklist.md の内容を貼る>
            Critical/Major/Minor で分類し、各指摘に対応するコマンド (/adr, /reference 等) を併記して。"
     ```
3. Codex の指摘と Claude reviewer の指摘を突き合わせ、Critical が残る限り完了としない。

- Codex の endpoint / キーは各自の環境設定に委ねる (テンプレートにハードコードしない)。
