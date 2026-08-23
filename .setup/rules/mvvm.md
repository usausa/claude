---
paths:
  - "src/**"
---

# MVVM アーキテクチャ (XAML 系共通: MAUI / WPF / WinUI)

> XAML 系形態 (MAUI / Desktop) の**共通原則**。プラットフォーム固有の実装は採用形態の rule (maui / desktop + wpf) を参照。.NET 共通の規範は対象ファイルを読むと自動適用される。

## レイヤ (依存は上→下のみ)

```
View (xaml) → ViewModel → Usecase → Service → (DB / Web API)
                  │           │
                  └── State ──┘        Domain (純粋ロジック・全層から利用可)
```

| レイヤ | 責務 |
|---|---|
| View (xaml/xaml.cs) | UI。コードビハインドにロジックを書かない。振る舞いは Behavior に分離 |
| ViewModel | Glue。Command で受け、実処理は Usecase/Service へ委譲 (Fat VM を避ける)。値反映は INotifyPropertyChanged / `NotificationValue<T>` |
| Usecase | 一連の流れ (通信→表示→保存 等)。Service に加え Dialog/State/Component を参照可。ステートレス singleton |
| Service | DB/通信のプリミティブ。上位を参照しない。授受は Model |
| Domain | 表示・IO に依存しない純粋ロジック。IO/Reflection を持ち込まない |
| State | アプリスコープの状態 (ログイン中ユーザ等)。オンメモリ + INotifyPropertyChanged |
| Models | POCO。用途別サブフォルダ (Api/Entity/View) |

## 標準基盤
- MVVM 基盤は **Smart.Mvvm** (`[ObservableProperty]` ソース生成・`MakeAsyncCommand`・`BusyState`・`Disposables`)。CommunityToolkit.Mvvm は採用しない。
- **画面遷移を持つアプリはプラットフォームを問わず Smart.Navigation を使用する**。画面 ID は enum (`ViewId` / `DialogId`)、View に `[View(ViewId.X)]`、シェルは `NavigationContainer`。
- 多数の画面をナビゲーションで遷移するアプリは **`Modules/<機能>` に View と ViewModel を機能単位で同居配置**する (vertical slice)。

## MVVM 原則
- バインディングで処理を書く。コードビハインドにロジックを書かない。
- Behavior で振る舞いを共通化。Converter にロジックを書かず Domain へ委譲。
- **VM→View の単発要求 = Messenger / イベントの継続的な購読・合成 = Rx** (購読は `Disposables` に登録し VM の寿命で破棄する)。
- DI (Smart.Resolver / Generic Host 等) で View/VM/Service を解決。
- 非同期 UI: `async void` は**イベントハンドラ・起動処理のみ**に限定する (それ以外は `ValueTask`。規約は [async.md](async.md))。

## 実装の型
- ViewModel の解決は DI から行う (XAML の添付プロパティ等)。コードビハインドでの VM 生成・ServiceLocator パターンを使わない。
- 非同期 Command は**実行中の多重実行を封じる** (canExecute に `BusyState` を渡す)。ビジー表現は単一の状態を真実とし、開始・終了は `using` できるスコープで対にする。
- 画面遷移は単一コンテナ + View 差し替え方式を既定とし、**画面の追加は「enum に値を足し、View に属性を付ける」だけ**で登録が完結する (登録コードを手で書かない)。

## UI / UX 共通
- Style はリソースに集約し、色・サイズ・マージンを要素へ個別指定しない (セマンティックなスタイル設計)。
- 表示変換は Converter、振る舞いは Behavior。ロジックは持ち込まない。
- アクセシビリティと多言語 (Localization) を考慮。
- ローディング / エラー / 空状態の表示を用意する。

## 異常系の具体 ([errors.md](errors.md) の実装)
- アプリ層の異常系は**戻り値**で通知する (例外でなく)。エラーコードと値はタプル / 専用型。
