---
name: desktop
description: デスクトップ (WPF / WinUI) の Windows 環境固有規約
paths:
  - "src/**"
---

# デスクトップ (Windows 環境固有: WPF / WinUI 共通)

> Windows デスクトップ環境の**共通固有事項** (WPF / WinUI で共有)。MVVM レイヤ・UI 原則は `mvvm` skill、UI 技術固有は `wpf` skill (将来 `winui`)、プロジェクト方針は プロジェクトの `.claude/rules/conventions.md` を参照。

## ログの具体 (`logging` skill の実装)
- `ILogger` + ファイル出力 (`%LOCALAPPDATA%\<App>\logs` 等)。イベントログは運用要件があるときのみ。

## データの具体 (`data` skill の実装)
- ローカル DB は SQLite 等。書き込み先は `%LOCALAPPDATA%\<App>` (Program Files 配下に書き込まない)。
- ユーザー設定は AppData 配下。ローミングの要否で Local / Roaming を選ぶ。

## セキュリティの具体 (`security` skill の実装)
- 秘匿値は **DPAPI (`ProtectedData`, CurrentUser スコープ) / Windows 資格情報マネージャー**に保存 (平文ファイル・レジストリに置かない)。
- 端末・アカウント共有を想定し、ユーザースコープで保護する。
- 通信は TLS・証明書検証を有効に。社内プロキシ環境は早期に検証する。

## 配置 / 更新
- 配布方式 (MSIX / インストーラ / xcopy) と自動更新の有無は要件で早期に決め、`/adr` に残す。
- 多重起動の制御 (Mutex) は要件に応じて。

## Windows 統合
- 高 DPI (PerMonitorV2) を前提にレイアウトする。
- 通知・タスクトレイ・スタートアップ登録は要件があるときのみ (常駐化の設計は `/adr`)。
