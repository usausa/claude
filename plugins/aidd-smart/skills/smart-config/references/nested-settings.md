# ネスト設定

| 項目 | 内容 |
|---|---|
| ID | config-3 |
| 分類 | config |
| 関連 | config-1(命名と2系統) / config-2(バインドの定型) / namespace-5(モデルのサフィックス規約) / log-5(ログ4系統の個別トグル) |

## 目的

関連する設定群を親セクション配下にまとめつつ、**利用側には必要な子設定だけを渡す**。

- appsettings の階層とクラス構造が1対1に対応し、設定の全体像がクラス定義から読める
- 利用側の依存が「親設定の全部」ではなく「自分が使う子」に絞られ、テスト時の組み立ても小さくなる

## 標準形

入れ子の `sealed class` に **`~Entry` サフィックス**を付け、親クラスの中にネスト定義する(namespace-5)。

```csharp
namespace Template.Worker.Settings;

public sealed class WorkerSetting
{
    [Required]
    public ScheduleEntry Schedule { get; set; } = default!;

    [Required]
    public CleanupEntry Cleanup { get; set; } = default!;

    public sealed class ScheduleEntry
    {
        [Required]
        public string Cron { get; set; } = default!;

        [Required]
        public string Action { get; set; } = default!;

        public List<string> Arguments { get; } = [];
    }

    public sealed class CleanupEntry
    {
        [Required]
        public string Directory { get; set; } = default!;

        [Range(0, 3650)]
        public int RetainDays { get; set; }
    }
}
```

```json
"Worker": {
  "Schedule": {
    "Cron": "*/5 * * * *",
    "Action": "hello",
    "Arguments": [ "schedule" ]
  },
  "Cleanup": {
    "Directory": "Work",
    "RetainDays": 7
  }
}
```

### 分解 DI 登録

親を config-2 パターン①でバインドしたうえで、**ネスト子を分解して個別に DI 登録**する。利用側は子 Entry を直接受ける。

```csharp
// Setting
builder.Services.AddOptions<WorkerSetting>().BindConfiguration("Worker").ValidateDataAnnotations().ValidateOnStart();
builder.Services.AddSingleton(static p => p.GetRequiredService<IOptions<WorkerSetting>>().Value);
builder.Services.AddSingleton(static p => p.GetRequiredService<WorkerSetting>().Schedule);
builder.Services.AddSingleton(static p => p.GetRequiredService<WorkerSetting>().Cleanup);
```

```csharp
public sealed class CleanupAction : IAction
{
    private readonly WorkerSetting.CleanupEntry setting;

    public CleanupAction(WorkerSetting.CleanupEntry setting)
    {
        this.setting = setting;
    }
}
```

- 検証は親の `ValidateOnStart` が入れ子ごと面倒を見る(子の個別検証は不要)
- 親設定そのものを使う利用者がいなければ、親の登録行は省略してよい(その場合も `AddOptions` の検証登録は残す)

### 同型の繰り返し

同じ形の設定が複数ある場合も、共通の Entry 1 つをネスト定義して使い回す。

```csharp
public sealed class LimitSetting
{
    [Required]
    public LimitEntry Global { get; set; } = default!;

    [Required]
    public LimitEntry Auth { get; set; } = default!;

    public sealed class LimitEntry
    {
        [Range(1, 3600)]
        public int Window { get; set; }

        [Range(1, Int32.MaxValue)]
        public int PermitLimit { get; set; }

        [Range(0, Int32.MaxValue)]
        public int QueueLimit { get; set; }
    }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| 親 Setting | `Settings/<セクション>Setting.cs`(config-4) |
| `~Entry` | 親クラスにネスト定義(独立ファイルにしない) |
| 分解登録 | 起動処理の `// Setting` セクション(config-2 / host-4) |

## バリエーションと使い分け

- **ネストする基準**: 同一機能のパラメータが2個以上あればグルーピングする(bool 1個なら親に直置きでよい → log-5)
- **セクション分割への切り替え**: Entry が他セクションからも使われる、または階層が3段以上になる場合は、独立した `<セクション>Setting` への分割を検討する

## アンチパターン

- **接頭辞によるフラット化** — `ScheduleCron` / `ScheduleAction` のような接頭辞プロパティの羅列は、グループ境界が名前の中に埋もれる。入れ子にする
- **Entry のトップレベル定義** — 親から切り離して独立クラスにすると、所有関係と使用範囲が不明になる。親にネストして従属を型で表す
- **利用側への親 Setting 渡し** — 子1つで足りる利用者に親全体を渡すと、依存範囲が実際より広く見え、テストで無関係な子まで組み立てるはめになる。分解登録で子を渡す
- **`Entry` 以外のサフィックス** — `Item` / `Config` 等が混ざると入れ子であることが名前から判別できない。`~Entry` に統一する(namespace-5)
