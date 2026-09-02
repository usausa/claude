# 定型ファイル(GlobalUsing / Assembly / GlobalSuppressions)

| 項目 | 内容 |
|---|---|
| ID | structure-5 |
| 分類 | structure |
| 関連 | structure-2(ImplicitUsings) / structure-4(警告抑止の三層) / structure-6(using 配置) / log-1(Log.cs) / solution-4(基盤ライブラリ) |

## 目的

全プロジェクトの直下に**同じ3つの定型ファイルを置き、using 集約・アセンブリ属性・抑止宣言の置き場を固定する**。

- `GlobalUsing.cs` — プロジェクト全体で使う global using の集約
- `Assembly.cs` — アセンブリレベル属性の集約
- `GlobalSuppressions.cs` — アセンブリ単位の警告抑止(structure-4)

新規プロジェクトはこの3ファイルの配置から始まり、どのプロジェクトを開いても同じ場所に同じ役割のファイルがある状態を保つ(ログ定義の `Log.cs` は log-1)。

## 標準形

### GlobalUsing.cs

```csharp
// ReSharper disable RedundantUsingDirective.Global
#pragma warning disable
global using System;
global using System.Buffers;
global using System.Collections.Generic;
global using System.ComponentModel.DataAnnotations;
global using System.Diagnostics.CodeAnalysis;
global using System.Globalization;
global using System.IO;
global using System.Linq;
global using System.Runtime.CompilerServices;
global using System.Text;
global using System.Threading;
global using System.Threading.Tasks;

global using Microsoft.Extensions.DependencyInjection;
global using Microsoft.Extensions.Logging;
global using Microsoft.Extensions.Options;

global using Smart;
global using Smart.Collections.Generic;
global using Smart.Linq;

// ReSharper disable MissingBlankLines
global using Template.ApiServer;
//global using Template.ApiServer.Models;
//global using Template.ApiServer.Services;
```

- 先頭の2行は固定とする。**未使用 using を許容する宣言専用ファイル**のため、ReSharper の冗長 using 検査と全アナライザ警告(using の順序・空行検査等)をファイル単位で無効化する
- **System → サードパーティ → 自プロジェクトの順に、空行区切りのブロック**で並べる。各ブロック内はアルファベット順
- 自プロジェクトのブロックには、**将来使う名前空間をコメントアウトで予約**しておく。プロジェクトが成長したときの追加位置が決まっており、プロジェクト間で並びが揃う(予約のコメント行が空行検査に触れるため、ブロック前で `MissingBlankLines` を disable する)

### Assembly.cs

```csharp
[assembly: CLSCompliant(false)]
```

- `CLSCompliant(false)` を既定とする(アプリケーションのアセンブリに CLS 準拠は要求しない)
- 対象プラットフォームが固定のプロジェクトでは、プラットフォーム属性をここへ追加する(`SupportedOSPlatform` 使用時は `System.Runtime.Versioning` を GlobalUsing.cs に追加する)

```csharp
[assembly: CLSCompliant(false)]
[assembly: SupportedOSPlatform("windows")]
```

### GlobalSuppressions.cs

アセンブリ単位の警告抑止。ホストプロジェクトの標準ペアは CA1515 + CA2007(内容と判断基準は structure-4)。

```csharp
[assembly: SuppressMessage("Maintainability", "CA1515:Consider making public types internal", Justification = "Ignore")]
[assembly: SuppressMessage("Reliability", "CA2007:Do not directly await a Task", Justification = "Ignore")]
```

- Assembly.cs / GlobalSuppressions.cs に using 宣言が不要なのは、`System` と `System.Diagnostics.CodeAnalysis` を GlobalUsing.cs で全体適用しているためである

## 配置ルール

| ファイル | 場所 |
|---|---|
| GlobalUsing.cs / Assembly.cs / GlobalSuppressions.cs | 各プロジェクトの直下(ルート) |
| ファイル固有の using | 各 .cs の namespace 内(structure-6)。プロジェクト全体で使うものだけを GlobalUsing.cs へ |
| Log.cs | 名前空間(フォルダ)毎に分割配置(log-1) |

## バリエーションと使い分け

- **Web ホスト**: サードパーティブロックの前に `Microsoft.AspNetCore.*` / `Microsoft.Extensions.*` のフレームワークブロックを置く
- **データアクセス層**: `Smart.Data.*`(data-1)等、その層で常用する名前空間を追加する
- **テストプロジェクト**: xunit と `Mocks` 名前空間(test-4)を追加する
- **汎用の基盤ライブラリ(solution-4)**: アプリ非依存のライブラリでは `CLSCompliant(true)` とする場合がある
- **ImplicitUsings との関係**: SDK の暗黙 using(structure-2)と重複しても構わない。GlobalUsing.cs 側を網羅的に保つことで、SDK 種別(Web / Worker)による暗黙セットの差を吸収する

## アンチパターン

- **共通 using の各ファイル記述** — プロジェクト全体で使う名前空間が各ファイルに散らばる。GlobalUsing.cs に集約し、ファイル側はファイル固有分のみにする
- **先頭2行の省略** — using の順序・空行系の検査がこのファイルに適用され、宣言の整理に無意味な対応を強いられる
- **アセンブリ属性の csproj・任意ファイルへの分散** — 属性の置き場が予測できなくなる。Assembly.cs / GlobalSuppressions.cs の役割分担を守る
- **定型ファイルの省略** — 「このプロジェクトだけ無い」状態を作らない。内容が1行でも3ファイルを置き、骨格を揃える
