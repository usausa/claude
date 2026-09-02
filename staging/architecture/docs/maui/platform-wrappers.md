# プラットフォーム機能ラッパ(Components / Behaviors / Messaging)

| 項目 | 内容 |
|---|---|
| ID | maui-4 |
| 分類 | maui |
| 関連 | namespace-3(Components / Infrastructure の決定) / namespace-7(クライアント側の標準語彙) / maui-1(DI 登録) / mvvm-1(Smart.Mvvm 基盤) |

## 目的

デバイス機能・プラットフォーム差分・View 操作を、それぞれ専用の名前空間に分離する。

- `Components/` = デバイス機能ラッパ(NFC・OCR・Bluetooth 等)。**プラットフォーム差分は `#if` ではなく partial クラス + プラットフォーム別ファイル**(`.android.cs` / `.ios.cs`)で分割する
- `Behaviors/` = View に付与する attached behavior / attached property。ネイティブハンドラ操作を伴うものは同じく partial 分割
- `Messaging/` = ViewModel から View への命令(フォーカス・カメラ操作等)を表すバインド可能なコントローラ

名称について: サーバ側では `Components` は Blazor の UI コンポーネント置き場と決定されたが(namespace-3)、**クライアント側の `Components` はプラットフォーム機能ラッパとしてそのまま維持する(決定 18、namespace-7)**。

## 標準形

### Components — インターフェース + partial 実装

共通ファイルに公開契約(インターフェース)と共通ロジックを置き、プラットフォーム固有部は `private partial` メソッドとして `.android.cs` 側で実装する。

```csharp
// Components/Nfc.cs(共通: 契約と状態管理)
public interface INfcReader
{
    event EventHandler<NfcEventArgs>? Detected;

    bool Enabled { get; set; }
}

public sealed partial class NfcReader : INfcReader
{
    public event EventHandler<NfcEventArgs>? Detected;

    public bool Enabled
    {
        get;
        set
        {
            if (value)
            {
                if (!field)
                {
                    Start();
                    field = true;
                }
            }
            else
            {
                if (field)
                {
                    Stop();
                    field = false;
                }
            }
        }
    }

    private partial void Start();

    private partial void Stop();
}
```

```csharp
// Components/Nfc.android.cs(Android 実装)
public sealed partial class NfcReader : Java.Lang.Object, NfcAdapter.IReaderCallback
{
    private NfcAdapter? nfcAdapter;

    private partial void Start()
    {
        if (nfcAdapter is null)
        {
            var nfcManager = (NfcManager)Application.Context.GetSystemService(Context.NfcService)!;
            nfcAdapter = nfcManager.DefaultAdapter!;
        }

        nfcAdapter.EnableReaderMode(ActivityResolver.CurrentActivity, this, NfcReaderFlags.NfcF, null);
    }

    private partial void Stop()
    {
        nfcAdapter?.DisableReaderMode(currentActivity);
    }
}
```

DI にはインターフェースで登録する(maui-1 の Components 区画)。

```csharp
config.BindSingleton<IStorageManager, StorageManager>();
config.BindSingleton<INfcReader, NfcReader>();
config.BindSingleton<IOcrReader, OcrReader>();
```

### Behaviors — attached property + ハンドラマッピングの partial 分割

共通ファイルに attached property の宣言を置き、ネイティブハンドラへの反映(`Mapper.AppendToMapping`)をプラットフォーム別ファイルの partial で実装する。

```csharp
// Behaviors/EntryOption.cs(共通: プロパティ宣言)
public static partial class EntryOption
{
    public static partial void UseCustomMapper(BehaviorOptions options);

    public static readonly BindableProperty SelectAllOnFocusProperty = BindableProperty.CreateAttached(
        "SelectAllOnFocus",
        typeof(bool),
        typeof(EntryOption),
        false);

    public static bool GetSelectAllOnFocus(BindableObject bindable) => (bool)bindable.GetValue(SelectAllOnFocusProperty);

    public static void SetSelectAllOnFocus(BindableObject bindable, bool value) => bindable.SetValue(SelectAllOnFocusProperty, value);
}
```

```csharp
// Behaviors/EntryOption.android.cs(Android: ハンドラ反映)
public static partial class EntryOption
{
    public static partial void UseCustomMapper(BehaviorOptions options)
    {
        if (options.SelectAllOnFocus)
        {
            EntryHandler.Mapper.AppendToMapping(SelectAllOnFocusProperty.PropertyName,
                static (handler, _) => UpdateSelectAllOnFocus(handler.PlatformView, (Entry)handler.VirtualView));
        }
    }
}
```

### Messaging — View↔VM 命令用コントローラ

ViewModel から View への命令(フォーカス移動・カメラ撮影等)は、バインド可能なコントローラで表現する。View 側は `Behaviors` のバインド部品(`EntryBind` / `CameraBind` 等)がコントローラを購読して実操作を行う。

```csharp
// Messaging/EntryController.cs
public sealed class EntryController : NotificationObject
{
    [EditorBrowsable(EditorBrowsableState.Never)]
    public event EventHandler<EventArgs>? FocusRequest;

    public string? Text
    {
        get;
        set => SetProperty(ref field, value);
    }

    public bool Enable
    {
        get;
        set => SetProperty(ref field, value);
    }

    // Request(ViewModel から呼ぶ)
    public void Focus()
    {
        FocusRequest?.Invoke(this, EventArgs.Empty);
    }
}
```

```csharp
// ViewModel 側: コントローラをプロパティとして公開する
public EntryController CodeEntry { get; } = new();

public void ClearInput()
{
    CodeEntry.Text = string.Empty;
    CodeEntry.Focus();
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| デバイス機能ラッパ(NFC・OCR・Bluetooth・Storage 等) | `Components/<Name>.cs` + `<Name>.android.cs` / `<Name>.ios.cs` |
| attached behavior / attached property | `Behaviors/`(差分があれば同じく partial 分割) |
| View↔VM 命令コントローラ | `Messaging/<Name>Controller.cs` |
| プラットフォームの入口(MainActivity 等)・マニフェスト | `Platforms/<OS>/`(MAUI 標準)。ロジックは置かず `Components` の partial 側に寄せる |
| DI 登録 | `MauiProgram.ConfigureContainer` の Components 区画(maui-1) |

## バリエーションと使い分け

- **`Services` との境界**(namespace-7): 外部との I/O(HTTP・ローカル DB)= `Services`、デバイス機能 = `Components`
- **`Helpers` との境界**: 状態を持たない純関数は `Helpers`。プラットフォーム差分のある static ヘルパ(`CrashReport` 等)は `Helpers` でも partial 分割方式を使ってよい
- 単一プラットフォームのみ対応するアプリでも partial 分割は維持する(対応 OS 追加時にファイル追加だけで済む)
- 汎用ライブラリ化できる水準のものはアプリの `Components` から基盤パッケージへ昇格させる

## アンチパターン

- **`#if ANDROID` を本体コードに散らす** — 差分は partial のプラットフォーム別ファイルに分割し、共通ファイルには契約と共通ロジックのみ置く
- **`Platforms/<OS>/` へのロジック実装** — `Platforms` は入口とマニフェストのみ。機能実装は `Components` の partial 側に寄せる
- **ViewModel が View を直接参照して操作する** — 命令は `Messaging` のコントローラを介す。ViewModel は View の型を知らない
- **クライアントの `Components` に UI コントロールを置く** — カスタムコントロールは `Controls/`(namespace-7)。`Components` はデバイス機能専用
- **具象型での DI 参照** — 利用側は `INfcReader` 等のインターフェースを受ける。テスト時のモック差し替えを可能に保つ
