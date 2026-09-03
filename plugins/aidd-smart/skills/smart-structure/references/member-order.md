# メンバ記述順序ガイドライン

| 項目 | 内容 |
|---|---|
| ID | structure-7 |
| 分類 | structure |
| 関連 | structure-3(SA1201 系無効) / structure-6(区切りコメント) / blazor-4(code-behind) / mvvm-1(ObservableProperty) / worker-1(BackgroundService) / test-5(Helper セクション) |

## 目的

クラス内のメンバ記述順序を統一し、**どのクラスを開いても「何がどこにあるか」を予測可能にする**。

- 順序はガイドラインとして運用し、**機械強制しない**。メンバ順序系ルール(SA1201 / SA1202 / SA1203 / SA1204 / SA1214)は無効のままとする(structure-3)
- 機械強制を避けるのは、**関連メンバの近接配置**(フィールドとプロパティの対、小さなヘルパーを利用箇所の近くに置く等)を順序より優先できる余地を残すためである

## 標準形

記述順序は次のとおり。

| # | メンバ | 補足 |
|---|---|---|
| ① | 定数 | `const` / `static readonly` |
| ② | フィールド | static → インスタンスの順。readonly を先に |
| ③ | イベント | |
| ④ | プロパティ | ViewModel の ObservableProperty・コマンド(mvvm-1)、Blazor の `[Inject]` / `[Parameter]`(blazor-4)を含む |
| ⑤ | コンストラクタ | Dispose を直後に置く |
| ⑥ | ライフサイクルメソッド | OnInitialized / ExecuteAsync / StartAsync 等 |
| ⑦ | メソッド群 | **public/private の順序より処理の種類単位のグルーピングを優先**し、`//----` 帯(structure-6)でセクション化 |
| ⑧ | ネスト型 | |

サンプル骨格:

```csharp
public sealed class DataSynchronizer : IDisposable
{
    // ① 定数
    private const int RetryLimit = 3;

    private static readonly TimeSpan RetryInterval = TimeSpan.FromSeconds(10);

    // ② フィールド(static → インスタンス、readonly 優先)
    private readonly ILogger<DataSynchronizer> log;
    private readonly IDataService dataService;
    private Timer? timer;

    // ③ イベント
    public event EventHandler? Completed;

    // ④ プロパティ
    public bool IsRunning { get; private set; }

    // ⑤ コンストラクタ + Dispose
    public DataSynchronizer(ILogger<DataSynchronizer> log, IDataService dataService)
    {
        this.log = log;
        this.dataService = dataService;
    }

    public void Dispose()
    {
        timer?.Dispose();
    }

    //--------------------------------------------------------------------------------
    // ⑥ ライフサイクル
    //--------------------------------------------------------------------------------

    public ValueTask StartAsync(CancellationToken cancellationToken)
    {
        // 起動処理
        return ValueTask.CompletedTask;
    }

    //--------------------------------------------------------------------------------
    // ⑦ メソッド群: Synchronize(処理の種類単位)
    //--------------------------------------------------------------------------------

    public async ValueTask SynchronizeAsync(CancellationToken cancellationToken)
    {
        await SynchronizeCoreAsync(cancellationToken);
    }

    // public エントリと、それだけが呼ぶ private 実装は同じセクションに近接配置する
    private async ValueTask SynchronizeCoreAsync(CancellationToken cancellationToken)
    {
        await dataService.UpdateAsync(cancellationToken);
    }

    //--------------------------------------------------------------------------------
    // ⑦ メソッド群: Helper
    //--------------------------------------------------------------------------------

    private static string MakeKey(string name) => $"sync-{name}";

    // ⑧ ネスト型
    private sealed record SyncContext(string Key, DateTime Timestamp);
}
```

メソッド群の要点:

- 「公開メソッドを先に、非公開を後に」という並びは**固定しない**。処理の種類(機能)でまとめ、そのまとまりを `//----` セクションにする
- public エントリポイントと、それだけが呼ぶ private 実装・ヘルパーは同一セクションに近接配置する

## 配置ルール

| 対象 | 扱い |
|---|---|
| 順序の適用単位 | class / struct / record 共通 |
| セクション区切り | `//----` 帯形式(structure-6)。小さいクラスでは省略してよい |
| 機械強制 | しない。SA1201 系は無効のまま(structure-3)、レビューもガイドライン参照に留める |

## バリエーションと使い分け

- **ViewModel(mvvm-1)**: `[ObservableProperty]` とコマンド定義は④に置き、コマンドの実装メソッドは⑦の該当機能セクションに置く
- **Blazor code-behind(blazor-4)**: `[Inject]` → `[Parameter]` の順で④、`OnInitializedAsync` 等は⑥。ビハインド内の節コメント固定順(State → Data → …)は規約ではなく参考パターンとする
- **BackgroundService(worker-1)**: `ExecuteAsync` は⑥のライフサイクルとして前方に置く
- **テストクラス(test-5)**: 例外として `// ---- Helper ----` セクションをクラス冒頭に置く方式を用いる

## アンチパターン

- **SA1201 系の有効化による機械強制** — 近接配置の判断余地が失われ、機能のまとまりが可視性順で分断される
- **可視性順のメソッド並べ替え** — public 一覧 → private 一覧の並びは、処理を追うときにファイル内ジャンプを強いる
- **関連メンバの散在** — フィールドと対になるプロパティ、単一箇所からしか呼ばれないヘルパーが離れて置かれる状態を作らない
- **セクションなしの長大クラス** — メソッドが増えたら `//----` セクションを切る。切れないほど雑多ならクラス分割を検討する
