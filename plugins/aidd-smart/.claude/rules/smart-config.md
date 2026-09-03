---
paths:
  - "**/Settings/**"
  - "**/*Setting.cs"
  - "**/*Options.cs"
  - "**/appsettings*.json"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。dotnet-* と重なる規範は smart-* が優先。プロジェクト固有の上書きは conventions.md へ -->

# 設定クラス (Smart スタック標準)

> 詳細・コード例は `smart-config` skill の references を必要時に読む。

- 2 系統の命名: アプリ設定 = `<セクション>Setting` (単数形・`Settings/` 配下) / 再利用コンポーネント付属 = `<Name>Options` (コンポーネントと同居)。全て `sealed`。
- バインド定型 2 パターン: ① 実行時に使う値 = `AddOptions<T>().BindConfiguration(...).ValidateDataAnnotations().ValidateOnStart()` + **`IOptions<T>.Value` を剥がして `T` を Singleton 登録** (IOptions を業務コードへ漏らさない) / ② 起動の組み立てで使う値 = `GetSection().Get<T>()!` で即時取得しローカル変数に留める。
- ネスト設定は親にネスト定義した `*Entry` とし、利用側には**必要な子だけを分解登録**して渡す。
- テレメトリ関連の設定は環境変数から取得する (設定クラスを作らない。判定は `IConfiguration` 拡張へ隠蔽)。
