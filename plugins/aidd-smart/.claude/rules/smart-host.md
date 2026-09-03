---
paths:
  - "**/Program.cs"
  - "**/ApplicationExtensions*.cs"
  - "**/Application/**"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。dotnet-* と重なる規範は smart-* が優先。プロジェクト固有の上書きは conventions.md へ -->

# 起動処理 (Smart スタック標準)

> サーバ系の DI 登録。起動の定型 (Program の宣言列挙・起動ログの儀式) はテンプレート済みのため、ここではサービス追加時に増える登録だけを規範化する。詳細・コード例は `smart-host` skill の references を必要時に読む。

- **登録順 = レイヤ順** (Setting → Provider → Component → Service → Usecase → Worker) を区切りコメントで見せる。機能単位は `ServiceCollectionExtensions.AddXxx()` へ切り出し。複数実装は `AddSingleton<I,T>` 並記 → `IEnumerable<T>` 受け。**基本 Singleton** (Worker から Scoped 依存を使うときは実行毎に `IServiceScopeFactory` でスコープ)。
