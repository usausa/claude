# 設定クラスの命名と2系統

| 項目 | 内容 |
|---|---|
| ID | config-1 |
| 分類 | config |
| 関連 | config-2(バインドの定型) / config-3(ネスト設定) / config-4(配置場所) / namespace-5(モデルのサフィックス規約) |

## 目的

設定クラスを **アプリ設定(`<セクション>Setting`)と再利用コンポーネント設定(`<Name>Options`)の2系統に分けて命名する**。

- クラス名を見ただけで「誰が所有し、どこに置かれ、どこまで持ち出せるか」が判る
- appsettings のセクション名とクラス名が1対1に対応し、設定の出所を辿れる

## 標準形

両系統に共通する規約:

- クラスは `sealed`
- プロパティは `{ get; set; } = default!`(+ 検証属性)または `required` で必須を表現する
- コレクションは `{ get; } = [];`(getter-only。バインダが要素を追加する)

### アプリ設定 — `<セクション>Setting`(単数形)

appsettings のセクション名 + `Setting`。アプリケーション(ホスト)が所有する。

```csharp
namespace Template.Host.Settings;

public sealed class AuthSetting
{
    [Required]
    [MinLength(32)]
    public string SecretKey { get; set; } = default!;

    [Required]
    public string Issuer { get; set; } = default!;

    [Range(1, 1440)]
    public int ExpireMinutes { get; set; }
}
```

```json
"Auth": {
  "SecretKey": "<dummy-secret-key-0123456789abcdef>",
  "Issuer": "TemplateHost",
  "ExpireMinutes": 60
}
```

`required` による必須表現(検証属性を使わない最小形):

```csharp
namespace Template.Host.Settings;

public sealed class ServerSetting
{
    public int Port { get; set; }

    public bool AllowAnonymous { get; set; }

    public required string PublicKey { get; set; }
}
```

### コンポーネント設定 — `<Name>Options`

再利用可能なコンポーネント(`I<Name>` + `<Name>` + `<Name>Options` + `<Name>Exception` の4点セット → namespace-3)に付属する設定。コンポーネントが所有する。

```csharp
namespace Template.Host.Infrastructure.Storage;

public sealed class FileStorageOptions
{
    [Required]
    public string Root { get; set; } = default!;
}
```

## 使い分け基準

| 観点 | `<セクション>Setting` | `<Name>Options` |
|---|---|---|
| 所有者 | アプリケーション(ホスト) | 再利用コンポーネント |
| 名前の由来 | appsettings のセクション名 | コンポーネント名 |
| 語形 | 単数形 `Setting` | `Options`(BCL / ASP.NET Core の慣行に一致) |
| 配置 | `Settings/`(config-4) | コンポーネントと同居(config-4) |
| 可搬性 | 移設しない(アプリ固有) | コンポーネントごと他プロジェクトへ持ち出せる |

迷ったときの判定: そのクラスは**コンポーネントを別プロジェクトに持ち出すとき一緒に動くか**。動くなら `Options`、アプリに残るなら `Setting`。

## アンチパターン

- **`Config` / `Configuration` 等の別サフィックス** — 2系統の判別ができなくなる。`Setting` / `Options` 以外を使わない
- **複数形 `Settings` のクラス名** — フォルダ名(`Settings/`)と衝突し、単数形の規約(namespace-5)にも反する
- **`sealed` の欠落・空文字既定での必須ごまかし** — `= string.Empty` は欠落を握りつぶす。必須は `= default!` + 検証属性、または `required` で表現し、欠落を起動時に検出する(config-2)
- **`IConfiguration` の直接参照** — 業務コードが `IConfiguration` を受けて `GetSection` するのは型と検証の放棄。必ず設定クラスにバインドして受ける(config-2)
