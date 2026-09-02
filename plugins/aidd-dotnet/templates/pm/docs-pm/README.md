# PM (プロジェクト管理) — feature 単位

- [iteration-plan.md](iteration-plan.md) — feature をイテレーションにまとめた計画。
- [progress.md](progress.md) — feature ごとの進捗ボード。
- 更新は `/pm-plan` (計画) と `/pm-status` (進捗)。

## 📏 方針
- **1 feature ≒ 1 SPEC** (SPEC = 仕様文書を feature の単位として扱う)。イテレーション = feature のグルーピング (期間で区切ってよい)。
- **WBS / フェーズゲートは使わない**。1 feature = 1 まとまり (SPEC→実装→テスト→レビュー) で進める。
- 進捗は SPEC / ADR / 実装 / テスト の有無から集計する。
- **現状仕様や実装詳細は書かない** (コード / 生成物が正)。ここは「計画と、どこまで進んだか」だけ。
- ここでの "feature" は機能単位の意味 (厳密な FDD の Feature ではない)。
