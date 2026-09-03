---
paths:
  - "**/Commands/**"
---

<!-- managed by aidd-dotnet plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# CLI ツール

> コンソール CLI をオプションで採用する場合の規範 (`setup.ps1 -Include cli` で採用)。コマンド定義フレームワークはプロジェクトで選定し `/adr` に残す。

## 構成

- Generic Host 風の組み立てに統一する: builder 生成 → DI 登録 → コマンド登録 → `return await host.RunAsync()`。
- レイヤは Worker と同じ発想: Command (薄い) → Usecase → Service。コマンド本体にロジックを書かない。

## コマンド定義 (宣言的バインド)

- コマンドは `Commands/` 配下にクラス + 属性で宣言し、パーサ操作をコードに書かない。命名は `動詞対象Command` (例: `DataGetCommand`)。オプションは属性付きプロパティで受ける。
- 親コマンド (ハンドラなし) + サブコマンド登録で階層化し、共通オプションは抽象基底クラスに集約する。

## フィルタ (横断関心)

- ログ (開始 / 終了 + elapsed) と例外の全捕捉 (最外周でエラーログ + ExitCode 設定) はフィルタ / ミドルウェア型で差し、コマンド本体に try/catch・計測コードを書かない (Web のフィルタ・Worker の最外周 catch と同型)。

## 出力と ExitCode

- **ユーザー向け出力 (コンソールの OK / NG) とログ (ファイル) を分離**する。ログはファイルシンクのみ (コンソールを汚さない)。
- ExitCode 規約: 成功 `0` / 失敗 `-1` (スクリプト・スケジューラからの成否判定用。POSIX 系では `-1` が `255` に丸まるため、シェルからは非 0 で判定する)。

## 配布

- **フレームワーク依存 + `PublishSingleFile`** を既定にする (AOT / self-contained は要件が出てから)。
- `appsettings.json` は `ExcludeFromSingleFile=True` で exe の横に外出しする (現地で編集可能に)。`appsettings.*.json` は publish から除外する。
