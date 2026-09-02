---
description: SPEC→ADR→test→code の ID 整合を検査し、孤児・リンク切れ・未記録の決定を報告する。
allowed-tools: Read, Grep, Glob
---

`docs/` 配下の frontmatter(`id` / `related` / `supersedes` / `status`)を走査してトレーサビリティを検査する。

1. `docs/spec/`・`docs/adr/` の `id` と参照関係を収集
2. 次を検出して表で報告:
   - `related` に書かれた ID が実在しない(**リンク切れ**)
   - どこからも参照されない**孤児** `SPEC-`
   - **退役候補**: SPEC が参照していた code / test が消えている (= 機能が削除された) → `status: retired` へ (または SPEC 削除)。ADR は不変なので `status: superseded/retired` にし理由を残す
   - `status: superseded` なのに後継 ADR が無い / 後継が実在しない
   - 公開 API・型を変えた形跡があるのに対応する ADR が無い(→ `/adr` を促す)
   - リンク切れ(相対リンク・画像)
3. `docs/traceability/index.md` を最新の対応表(SPEC↔ADR↔test↔code)に更新する
