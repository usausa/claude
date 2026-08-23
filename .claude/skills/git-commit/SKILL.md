---
name: git-commit
description: Git のコミットメッセージ / ブランチ命名 / ステージング単位の規約(Conventional Commits)。commit・push・ブランチ作成のコマンドを人に提示する時に使う。
---

# Git 提示の規約

> このプロジェクトは **AI が git コマンドを提示し、人が実行**する(`AGENTS.md`)。提示する文面・ブランチ名・コミット単位をここで規約化する。
> **例外**: このスキル(または `work-close`)の手順として人からコミット / プッシュを明示的に依頼されたときは、AI が実行してよい(`git push` 等は permission の確認が入る)。

## コミットメッセージ(Conventional Commits)
- 形式: `type(scope): 要約`。要約は簡潔・命令形寄り(日本語可)。**何を**は diff で分かるので、本文には**なぜ**を書く。
- type: `feat` / `fix` / `docs` / `refactor` / `test` / `perf` / `build` / `ci` / `chore` / `style`。破壊的変更は `feat!:` または本文に `BREAKING CHANGE:`。
- フッタで関連 ID を紐づける: `Refs: SPEC-0002, ADR-0003`(`/trace` の対応づけと揃える)。

## ブランチ名
- `type/短い説明`(kebab-case)。例 `feat/inventory-adjust`、`fix/login-lock`。issue があれば `feat/123-inventory-adjust`。

## 途中プッシュ(他者レビュー用)と最終プッシュ
- ブランチ作業の途中で他者のレビューを受けるときは、その時点までを意図単位でコミットし、`git push -u origin <branch>` を提示する(PR はドラフトでよい)。
- 機能完了時の最終コミット・プッシュ・ブランチ削除は `work-close` skill がこの規約を使って提示する(git 操作の型はこのファイルに一元化)。

## ステージング単位
- **1 コミット = 1 つの意図**。意図が変わったら **コード + SPEC を同じコミット**に含める(SDD 原則。意図と実装をズラさない)。
- `docs/reference/**` は生成物(OpenAPI 等)。再生成の結果は別コミットに分けると差分が読みやすい。
- **秘匿情報(接続文字列・キー・user-secrets / SecureStorage 対象・`appsettings.*.json` の機密)はコミットしない**。`.gitignore` 済みを確認。

## 提示の型
```bash
git checkout -b feat/inventory-adjust
git add src/ docs/spec/SPEC-0002.md
git commit -m "feat(inventory): 在庫調整 API を追加"
git push -u origin feat/inventory-adjust
```

## 機械強制したい場合(任意)
- .NET の定番は **Husky.Net**: `commit-msg` フックで Conventional Commits を正規表現検証、`pre-commit` で `${staged}` に `dotnet format`。`dotnet tool` + `task-runner.json` で設定する。
- 本テンプレは既に PostToolUse フックで `dotnet format` を検証するため、git 側の強制は任意。
