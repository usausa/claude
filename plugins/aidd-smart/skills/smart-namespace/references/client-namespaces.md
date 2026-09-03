# クライアント側の標準名前空間

| 項目 | 内容 |
|---|---|
| ID | namespace-7 |
| 分類 | namespace |
| 関連 | namespace-1(サーバ側) / namespace-3(Components の使い分け) / namespace-6(Usecase) / mvvm-2(Smart.Navigation) / mvvm-5(Modules 規則) / maui-3(自前 Shell) / maui-4(プラットフォーム機能ラッパ) / maui-5(Blazor Hybrid) / avalonia-2(入力デバイス抽象) |

## 目的

クライアント(MAUI / WPF / Avalonia)プロジェクトの名前空間語彙を定義する。

- クライアントは1ソリューション=1プロジェクトが基本(solution-1)。フォルダ=名前空間でレイヤを分割する
- サーバ側と共通の語彙(`Services` / `Usecase` / `State` / `Helpers` / `Models` / `Domain`)は同じ意味で使い(namespace-1)、クライアント固有の語彙を追加する

## 標準形

### フォルダツリー

```
Template.MobileApp/
├─ Behaviors/          # attached behavior(.android.cs / .ios.cs 分割)
├─ Components/         # プラットフォーム機能ラッパ
├─ Controls/           # カスタムコントロール
├─ Converters/         # 値コンバータ
├─ Devices/
│  └─ Input/           # 入力デバイス抽象
├─ Domain/             # namespace-4 と同じ
├─ Helpers/            # 純粋関数
├─ Messaging/          # View↔VM 命令用コントローラ
├─ Models/             # namespace-5 と同じ
├─ Modules/            # 機能単位の View + ViewModel(mvvm-5)
│  ├─ Main/
│  └─ Order/
├─ Services/           # I/O 境界
├─ Shell/              # 自前シェル(maui-3)
├─ State/              # 可変シングルトン状態
└─ Usecase/            # namespace-6
```

### 語彙表

| 名前空間 | 置くもの | 代表クラス |
|---|---|---|
| `Modules/<機能>` | 機能単位で View と ViewModel を同居配置(多画面+ナビゲーションを行うアプリ。規則の定義は mvvm-5)。`Modules` 直下に画面 ID(`ViewId` / `DialogId`)と ViewModel 基底を置く | `MenuView` / `MenuViewModel` / `ViewId` |
| `State` | プロセス内で共有する可変シングルトン状態 | `Session` / `DeviceState` / `Settings` |
| `Services` | I/O 境界(API 呼び出し・ローカル DB・HTTP) | `HttpService` / `DataService` |
| `Usecase` | 業務フローの組み立て(namespace-6) | `OrderUsecase` |
| `Components` | **プラットフォーム機能ラッパ(維持決定)**。NFC・OCR・Bluetooth 等 | `Nfc` / `OcrReader` |
| `Behaviors` | View に付与する attached behavior。プラットフォーム差分は `.android.cs` / `.ios.cs` | `EntryBind` / `Focus` |
| `Messaging` | View↔VM の命令用コントローラ | `EntryController` / `CameraController` |
| `Helpers` | 状態を持たない純粋関数 | `ImageHelper` |
| `Shell` | 自前シェル。共通ヘッダ・物理キーを VM から宣言的に制御(maui-3) | `IShellControl` / `ShellProperty` |
| `Devices.Input` | 入力デバイス抽象。実機とデバッグ実装を差し替える(avalonia-2) | `IInputDevice` / `DebugInputDevice` |

### Components(プラットフォーム機能ラッパ)

サーバ側の決定(`Components` = Blazor の UI → namespace-3)とは別に、**クライアント側の `Components` はプラットフォーム機能ラッパとしてそのまま維持する(決定)**。プラットフォーム差分は `#if` ではなく partial クラス + プラットフォーム別ファイルで分割する(maui-4)。

```
Components/
├─ Nfc.cs              # 共通 API(インターフェースと共通部)
├─ Nfc.android.cs      # partial によるプラットフォーム実装
├─ OcrReader.cs
├─ OcrReader.android.cs
└─ StorageManager.cs
```

### Messaging(View↔VM 命令)

ViewModel から View への命令(フォーカス移動・カメラ操作等)は、バインド可能なコントローラとして表現する。View 側は `Behaviors` のバインド部品がコントローラを購読して実操作を行う。

```csharp
// ViewModel 側: コントローラをプロパティとして公開し、命令はメソッド呼び出しで表現する
public EntryController NameEntry { get; } = new();

public void ClearInput()
{
    NameEntry.Text = string.Empty;
    NameEntry.Focus();
}
```

### State

変更通知(`ObservableObject` 等)を持つ可変状態を Singleton で DI 登録する。`Session`(業務セッション)、`DeviceState`(バッテリー・ネットワーク等をイベント購読で反映)、`Settings`(永続化されるアプリ設定値)が代表形。

## 配置ルール

| 対象 | 場所 |
|---|---|
| View + ViewModel | `Modules/<機能>/`(mvvm-5)。Blazor Hybrid では `Views/`(maui-5) |
| 画面 ID(`ViewId` / `DialogId`)・ViewModel 基底 | `Modules/` 直下 |
| プラットフォーム機能ラッパ | `Components/`(partial 分割) |
| プラットフォーム固有の入口・リソース | `Platforms/<OS>/`(MAUI 標準構成)。ロジックは `Components` の partial 側に寄せる |

## バリエーションと使い分け

- **Blazor Hybrid**: Smart.Navigation を使わず `Views/` + メッセージ駆動遷移とする(maui-5)。`Modules` は使わない
- 画面数が少ないツール系アプリでは `Modules` を切らず `Views/` + `ViewModels/` の平置きでよい。多画面+ナビゲーションを行う規模になったら `Modules` へ移行する(mvvm-5)
- `Devices.Input` はキーパッド・ハンディスキャナ等の入力デバイスを持つ組込み系で使う(avalonia-2)。タッチ操作のみのアプリでは不要
- `Services` と `Components` の境界: 外部との I/O(HTTP・DB)= `Services`、デバイス機能(NFC・カメラ・センサー)= `Components`

## アンチパターン

- 多画面アプリで View と ViewModel を `Views/` と `ViewModels/` に分離配置する — 機能単位の同居(mvvm-5)に反する
- クライアントの `Components` に UI コントロールを置く — カスタムコントロールは `Controls/`
- 画面間の共有状態を ViewModel に持たせて受け渡す — 共有状態は `State` に集約する
- ViewModel が View を直接参照して操作する — 命令は `Messaging` のコントローラを介す
- プラットフォーム差分を `#if ANDROID` で本体コードに散らす — partial の `.android.cs` / `.ios.cs` 分割に統一する(maui-4)
