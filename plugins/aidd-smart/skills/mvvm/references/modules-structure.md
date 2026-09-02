# Modules 構成(vertical slice)

| 項目 | 内容 |
|---|---|
| ID | mvvm-5 |
| 分類 | mvvm |
| 関連 | mvvm-1(ViewModel 基底) / mvvm-2(ViewId / Smart.Navigation) / namespace-7(クライアント名前空間) / maui-5(Blazor Hybrid) |

## 目的

**多数の画面を用意しナビゲーションを行うアプリケーションでは、`Modules/<機能>` フォルダに機能単位で View と ViewModel を同居配置する(決定)**。

- 1画面の変更が1フォルダで完結する(vertical slice)。`Views/` と `ViewModels/` に分ける水平分割では、機能追加のたびに複数フォルダを行き来することになる
- フォルダ=名前空間により、機能のまとまりがそのまま名前空間に現れる
- クライアント一般のルールではなく、**MVVM(XAML 系クライアント)のルール**として定義する

## 標準形

### フォルダツリー

```
Template.App/
└─ Modules/
   ├─ ViewId.cs               # 画面 ID(mvvm-2)
   ├─ DialogId.cs             # ダイアログ ID(使用時)
   ├─ AppViewModelBase.cs     # ViewModel 基底(mvvm-1)
   ├─ Main/
   │  ├─ MenuView.xaml
   │  ├─ MenuView.xaml.cs
   │  ├─ MenuViewModel.cs
   │  ├─ SettingView.xaml
   │  ├─ SettingView.xaml.cs
   │  └─ SettingViewModel.cs
   └─ Order/
      ├─ OrderListView.xaml
      ├─ OrderListView.xaml.cs
      ├─ OrderListViewModel.cs
      ├─ OrderDetailView.xaml
      ├─ OrderDetailView.xaml.cs
      └─ OrderDetailViewModel.cs
```

- `Modules/` 直下には**機能横断の部品**(画面 ID・ViewModel 基底・遷移パラメータ定義等)のみを置く
- `Modules/<機能>/` には View(XAML + code-behind)と ViewModel の対を置く。ファイル名は `<画面名>View` / `<画面名>ViewModel` で対にする

### 命名と名前空間

| 対象 | 規約 | 例 |
|---|---|---|
| 機能フォルダ | 機能名(PascalCase) | `Main` / `Order` / `Device` |
| View | `<画面名>View` | `OrderListView` |
| ViewModel | `<画面名>ViewModel` | `OrderListViewModel` |
| 名前空間 | フォルダに一致 | `Template.App.Modules.Order` |

画面 ID(`ViewId`)は機能グループ毎にコメントで区切り、`<機能><画面>` の連結名とする(`OrderList` / `OrderDetail`)。

### 機能内の追加ファイル

機能に閉じた部品(その機能でしか使わないコンバータ・パラメータ record 等)は機能フォルダ内に置いてよい。複数機能で使う部品は `Modules/` 直下、または語彙に応じた名前空間(`Helpers` / `Messaging` 等 → namespace-7)へ昇格させる。

## 配置ルール

| 対象 | 場所 |
|---|---|
| View + ViewModel | `Modules/<機能>/` に同居 |
| `ViewId` / `DialogId`・ViewModel 基底 | `Modules/` 直下 |
| 画面以外のレイヤ(State / Services / Usecase 等) | `Modules/` に置かない。namespace-7 の語彙に従う |
| ダイアログ View | 機能に属するものは `Modules/<機能>/`、共通ダイアログは `Modules/Dialogs/` 等の横断フォルダ |

## バリエーションと使い分け

- **画面数が少ないツール系アプリ**: `Modules` を切らず `Views/` 平置き(View / ViewModel / ViewId を同一フォルダに配置)でよい。多画面+ナビゲーションを行う規模になったら `Modules/<機能>` へ移行する
- **Blazor Hybrid(maui-5)**: `Modules` は使わず `Views/` + razor コンポーネント構成とする
- **機能フォルダの粒度**: 画面 ID のグループ(メニュー階層)と一致させるのが基本。1フォルダが肥大化したらサブ機能に分割する

## アンチパターン

- **多画面アプリでの `Views/` + `ViewModels/` 水平分割** — View と ViewModel が離れ、機能の変更が常に2フォルダにまたがる。機能単位の同居に統一する
- **`Modules/` への非画面部品の混入** — サービスや状態を機能フォルダに置くと、レイヤ境界(namespace-7)が崩れる。画面(View + ViewModel)とその付属物に限定する
- **機能をまたぐ ViewModel の相互参照** — 機能間の連携は Navigator のパラメータ(mvvm-2)や `State` / `IReactiveMessenger`(mvvm-1)を介す
- **1フォルダ=1画面の過分割** — `Modules/OrderList/` / `Modules/OrderDetail/` のような画面単位の分割はフォルダ数が爆発する。分割単位は機能とする
