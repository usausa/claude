# コマンドディスパッチ

| 項目 | 内容 |
|---|---|
| ID | worker-2 |
| 分類 | worker |
| 関連 | worker-1(Batch の共通骨格) / worker-3(CLI ツール) / host-4(DI 登録スタイル) / network-1(TCP サーバ基盤) |

## 目的

「名前(コマンド)から処理を選んで実行する」ディスパッチを、**DI の複数登録 + 線形探索**の1パターンに固定する。

- 処理の追加は「実装クラスを書いて `AddSingleton<I, T>` を1行足す」だけで完結する
- ディスパッチテーブル(switch / Dictionary / ステートマシン)を別途維持しない。登録一覧がそのまま処理の一覧になる
- コマンド数は高々数十であり、線形探索で性能上十分。仕組みの単純さを優先する

## 標準形

### 複数登録 → IEnumerable&lt;T&gt; 受け

同一インターフェースの実装を `AddSingleton<I, T>` で並記する(host-4)。

```csharp
// Action
builder.Services.AddSingleton<IAction, HelloAction>();
builder.Services.AddSingleton<IAction, CleanupAction>();
builder.Services.AddSingleton<IAction, ExportAction>();
```

利用側は `IEnumerable<T>` で全実装を受ける。登録した順に列挙される。

```csharp
public ActionWorker(IEnumerable<IAction> actions)
{
    this.actions = actions;
}
```

### 線形ディスパッチ

`Name` と入力の突合による線形探索で解決する。見つからない場合は「不明なコマンド」としてログ + エラー終了にする(worker-1)。

```csharp
var action = actions.FirstOrDefault(x => String.Equals(x.Name, arguments.Name, StringComparison.OrdinalIgnoreCase));
if (action is null)
{
    log.WarnActionUnknown(arguments.Name);
    Environment.ExitCode = -1;
    return;
}

await action.ExecuteAsync(arguments.GetParameters(), stoppingToken);
```

ホットパスで繰り返し解決する場合は、コンストラクタで配列化して `Array.Find` を使う。

```csharp
public sealed class CommandDispatcher
{
    private readonly ICommand[] commands;

    public CommandDispatcher(IEnumerable<ICommand> commands)
    {
        this.commands = commands.ToArray();
    }

    public ICommand? Resolve(string name) => Array.Find(commands, x => x.Match(name));
}
```

### Match メソッドによる判定の委譲

突合条件が単純な文字列一致でない場合(バイト列比較・別名・前方一致等)は、判定自体をコマンド側の `Match` に委譲する。ディスパッチャは条件の中身を知らない。

```csharp
public interface ICommand
{
    string Name { get; }

    bool Match(ReadOnlySequence<byte> command);

    ValueTask<bool> ExecuteAsync(CommandContext context, ReadOnlySequence<byte> options, IBufferWriter<byte> writer);
}
```

```csharp
public sealed class GetCommand : ICommand
{
    public string Name => "get";

    public bool Match(ReadOnlySequence<byte> command) => command.SequentialEqual("get"u8);

    // ...
}
```

TCP サーバ(network-1)の受信ループでは、受信フレームを分割した先頭部で `Match` を回す同じ形になる。

```csharp
foreach (var command in commands)
{
    if (command.Match(first))
    {
        var result = await command.ExecuteAsync(context, buffer, writer);
        // ...
    }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| コマンドインターフェース + 実装群 | 機能フォルダ(`Actions/`、`Handlers/Commands/` 等)に同居 |
| 登録 | 機能フォルダの `ServiceCollectionExtensions.AddXxx()`、少数ならホストの `// Action` セクションに並記(host-4) |
| ディスパッチ処理 | 実行エンジン側(`ActionWorker` / `CommandHandler`)に1箇所 |

## バリエーションと使い分け

- **Batch(worker-1)**: `Name` の文字列比較(`OrdinalIgnoreCase`)。起動毎に1回しか解決しないため `FirstOrDefault` で足りる
- **TCP コマンドサーバ(network-1)**: `Match(ReadOnlySequence<byte>)` に判定を委譲し、UTF-8 リテラル(`"get"u8`)とのアロケーションフリー比較にする
- **CLI ツール(worker-3)**: サブコマンド階層・オプション解析が必要な場合は自作ディスパッチではなく System.CommandLine のルーティングに乗せる

## アンチパターン

- **switch / Dictionary によるディスパッチテーブルの二重管理** — 実装クラスの追加とテーブルの更新が分離し、登録漏れの温床になる。DI 登録一覧を唯一のテーブルとする
- **ステートマシン化** — コマンド選択に状態遷移を持ち込まない。1入力=1コマンドの線形突合に保つ(接続状態の管理が必要でも、それは `Context` 側の責務とする)
- **早すぎる最適化** — 数十件の線形探索を Dictionary や FrozenDictionary に置き換える必要はない。プロファイルで問題になってから検討する
- **ディスパッチャが判定条件を知る** — `if (name == "get" || name == "fetch")` のような条件をエンジン側に書かない。`Match` としてコマンド側に置く
