# Infrastructure の二段構え

| 項目 | 内容 |
|---|---|
| ID | solution-4 |
| 分類 | solution |
| 関連 | solution-1(プロジェクト分割の基本形) / solution-3(基盤層プロジェクト) / namespace-2(Application 名前空間) / namespace-3(Infrastructure 名前空間) / structure-5(定型ファイル) |

## 目的

業務非依存のインフラ部品を**「アプリ非依存」と「アプリ固有」の二段**に分け、置き場・名前空間・品質水準を変える。

- ① **アプリ非依存の基盤**: どのアプリ(製品)でもそのまま使える汎用部品。独立プロジェクトにし、BCL ミラーの名前空間と `CLSCompliant(true)` で汎用ライブラリの水準に上げる
- ② **アプリ固有だが業務非依存**: このアプリの都合(設定・規約)を含む部品。ホストプロジェクト内の `Infrastructure/` 名前空間に置く(namespace-3)
- 判定基準を「他のアプリでも使えるか」の一点に固定し、`X.Infrastructure.*` のような何でも入る中間層を作らない

## 標準形

### 二段の比較

| | ① アプリ非依存の基盤 | ② アプリ固有・業務非依存 |
|---|---|---|
| 置き場 | 独立プロジェクト | ホスト内 `Infrastructure/` 名前空間(namespace-3) |
| 名前空間 | BCL ミラー(`X.IO` / `X.Net` / `X.Threading` / `X.Text` 等) | `<App>.Infrastructure.*` |
| CLSCompliant | `true` | `false`(アプリ既定、structure-5) |
| 依存してよいもの | BCL(+汎用ライブラリ) | アプリの Settings / Log 等 |
| 共有範囲 | 製品をまたぐ | アプリ内 |

### ①: 独立プロジェクトと BCL ミラー名前空間

名前空間は `X.Infrastructure.*` とせず、**拡張・補完する BCL の名前空間をミラーする**。利用側からは標準ライブラリの延長として見え、部品の探し場所が BCL の知識だけで決まる。

```
Template/                  … 基盤ライブラリ(アプリ非依存)
├─ Assembly.cs             … [assembly: CLSCompliant(true)]
├─ IO/                     … namespace Template.IO(System.IO の補完)
├─ Net/                    … namespace Template.Net
├─ Text/                   … namespace Template.Text
└─ Threading/              … namespace Template.Threading
```

```csharp
using System;

[assembly: CLSCompliant(true)]
```

- `CLSCompliant(true)` により公開 API の型・命名への制約が厳しくなり、汎用ライブラリとしての品質水準が上がる。アプリ側の既定は `false`(structure-5)であり、この層だけ引き上げる
- BCL に対応が無い分野は、汎用の語彙で命名する(アプリ名・業務語彙を含めない)

### ②: ホスト内の Infrastructure 名前空間

アプリ固有だが業務非依存の部品(Storage / Security 等の `I<Name>` + `<Name>` + `<Name>Options` + `<Name>Exception` の4点セット)は、ホスト内の `Infrastructure/` に置く。詳細は namespace-3。

### 判定基準: 他のアプリでも使えるか

次のすべてを満たすなら①、ひとつでも欠けるなら②に置く。

- アプリの `Settings` / `Log` / `Domain` への参照が無い
- アプリの規約(命名・定数・設定キー)を知らない
- 部品の説明にアプリ名・業務語彙が不要(汎用の語彙で言い切れる)

迷ったら②に置く。②から①への昇格は後からできるが、①に混入したアプリ依存を剥がすのは難しい。

### solution-3(基盤層)との関係

| 層 | 共有範囲 | 性質 |
|---|---|---|
| ② `Infrastructure/` 名前空間 | 単一ホスト内 | アプリ固有・業務非依存 |
| 基盤層プロジェクト(solution-3) | 同一アプリの複数ホスト間 | アプリ固有・業務非依存 |
| ① 独立プロジェクト | 製品をまたぐ | アプリ非依存 |

昇格の階段は「② → 基盤層 → ①」。②が複数ホストで必要になれば基盤層(solution-3)へ、アプリ色が完全に抜ければ①へ引き上げる。

## 配置ルール

| 対象 | 場所 |
|---|---|
| アプリ非依存の汎用部品 | 独立プロジェクト。BCL ミラー名前空間 + `CLSCompliant(true)` |
| アプリ固有・業務非依存の部品 | ホスト内 `Infrastructure/`(namespace-3) |
| 複数ホストで共有するアプリ固有部品 | 基盤層プロジェクト(solution-3) |
| アプリ固有の共通部品(アプリ規約寄り) | `Application/`(namespace-2) |

## バリエーションと使い分け

- **パッケージ化**: ①が複数リポジトリから使われる段階で NuGet パッケージ化し、リポジトリを分離する
- **①のテスト**: 独立した Tests プロジェクトを持つ(配置・命名は test-3)
- **性能部品**: プール・バッファ等のアロケーション制御部品(network-3)は典型的な①候補

## アンチパターン

- **`X.Infrastructure` / `X.Common` / `X.Utils` という命名** — プロジェクト名でも名前空間でも作らない。判定基準を名前が壊し、雑多な置き場になる
- **①へのアプリ依存の混入** — アプリの Settings や設定キーに触れた時点で①ではない。②か基盤層(solution-3)へ戻す
- **早すぎる昇格** — 利用者が1アプリしか無い部品を独立プロジェクト化しない。②で十分
- **②に BCL ミラー名前空間を使う** — ホスト内の部品が `<App>.IO` 等を名乗ると①と区別できない。②は `<App>.Infrastructure.*` に置く
- **①と②の同居 DLL** — 1つのプロジェクトにアプリ依存と非依存を混在させる。CLSCompliant と依存規則がどちらつかずになる
