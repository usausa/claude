```
/spec(仕様草案 → docs/spec に採番)→ 人がレビュー & 承認
  → /plan(チェックリスト。docs/work/ の一時物)→ /impl(フェーズ実装 + フェーズ末 /verify)
  → PostToolUse フックで dotnet format 検証(逆フィードバック)
  → /reference(Web=OpenAPI 再生成)→ 意図が変われば SPEC 更新 + 蒸留(spec-close)
  → /review + /review-cross(Codex)→ /done(DoDゲート)→ 人間が git commit
```
- 実装プラン(`docs/work/` の PLAN)は**一時物**(完了時に削除。git 管理のため履歴には残る。SPEC だけが恒久の意図として残る)。