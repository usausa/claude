# 設定クラスの配置場所

| 項目 | 内容 |
|---|---|
| ID | config-4 |
| 分類 | config |
| 関連 | config-1(命名と2系統) / config-3(ネスト設定) / namespace-1(サーバ側の標準語彙) / namespace-3(Components / Infrastructure) |

## 目的

設定クラスの置き場を固定し、**「設定を知りたければ `Settings/` を見る」を全プロジェクトで成立させる**。

- appsettings のセクション一覧と `Settings/` のファイル一覧が対応し、設定の全体像を1フォルダで把握できる
- 再利用コンポーネントの設定は本体と離れないため、コンポーネント単位の移設が壊れない

## 標準形(決定事項)

**アプリケーションの設定クラスは `Settings/` 配下に配置する。コンポーネント固有の設定(`<Name>Options`)はコンポーネントと同じ場所に配置する。**

```
Template.Host/
├─ Settings/                       … アプリ設定(<セクション>Setting)
│  ├─ AuthSetting.cs
│  ├─ LimitSetting.cs
│  └─ LogSetting.cs
├─ Infrastructure/
│  └─ Storage/                     … コンポーネントの4点セット(namespace-3)
│     ├─ IStorage.cs
│     ├─ FileStorage.cs
│     ├─ FileStorageOptions.cs     … Options はコンポーネントと同居
│     └─ StorageException.cs
└─ appsettings.json
```

- `Settings/` の名前空間は `<Root>.Settings`(namespace-1 の標準語彙)
- `<Name>Options` は `I<Name>` / `<Name>` / `<Name>Exception` と同じフォルダ・同じ名前空間に置く

## 配置ルール

| 種類 | 場所 | 名前空間 |
|---|---|---|
| アプリ設定 `<セクション>Setting` | `Settings/` | `<Root>.Settings` |
| ネスト設定 `~Entry` | 親 Setting にネスト定義(config-3) | 親と同じ |
| コンポーネント設定 `<Name>Options` | コンポーネントと同じフォルダ | コンポーネントと同じ |

1クラス = 1ファイルとする(`~Entry` は親のファイル内にネスト定義)。

## バリエーションと使い分け

- **クライアント(単一プロジェクト構成)**: サーバ系と同じく `Settings/` フォルダを置く(フォルダ = 名前空間のレイヤ分割の一部)
- **基盤層プロジェクト分離時(solution-3)**: コンポーネントを基盤プロジェクトへ移す場合、`<Name>Options` はコンポーネントと一緒に移動する。`<セクション>Setting` はホスト側の `Settings/` に残る
- **設定クラスを持たない値**: テレメトリ関連は環境変数から取得し(telemetry-1)、Setting クラスを作らない

## アンチパターン

- **ルート直下・`Models/` への散在** — 設定クラスがモデルや業務クラスに紛れ、appsettings との対応が追えなくなる
- **`<Name>Options` の `Settings/` への吸い上げ** — コンポーネントを移設するときに設定だけ取り残され、可搬性が壊れる。Options は本体と同居させる
- **アプリ設定のコンポーネント側配置** — 逆方向の混在も不可。アプリ(ホスト)所有の設定は `Settings/` に集約する(所有者の判定は config-1 の使い分け基準)
- **1ファイル複数クラス** — `Settings/` 内で複数の Setting を1ファイルにまとめない。セクションとファイルの1対1対応を保つ
