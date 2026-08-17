---
paths:
  - "src/**"
---

# MAUI (プラットフォーム固有)

> **MAUI 固有**。MVVM レイヤ・UI 原則は [`mvvm.md`](mvvm.md)、プロジェクト方針は [`conventions.md`](conventions.md) を参照。

## UI / UX
- Style は `App.xaml` (`Resources/Styles`) に定義する (mvvm.md のスタイル原則の実装)。
- サイズは dpi を考慮した推奨値 (3, 6, 9, 12, 18, 24, 36, 48, 72 等) で統一。
- アクセシビリティは `SemanticProperties` を付与する。

## ログの具体 ([logging.md](logging.md) の実装)
- `ILogger` 経由。プロバイダは Logcat 出力 / ファイル出力 (MauiComponents 提供)。

## データの具体 ([data.md](data.md) の実装)
- 端末内 DB は SQLite (`Microsoft.Data.Sqlite`) + Micro-ORM。.NET 型 ⇔ SQLite 型は型ハンドラで変換 (Guid→TEXT, DateTime→INTEGER 等)。

## セキュリティの具体 ([security.md](security.md) の実装)
- 秘匿値は `SecureStorage` / プラットフォームのキーストアに保存 (平文ファイルに置かない)。
- 権限 (カメラ・位置等) は `Permissions` で必要時に要求し、最小化する。
- 通信は証明書検証を有効に (必要に応じて証明書ピンニング)。
- 端末紛失を想定し、機微データをローカルに残しすぎない。
