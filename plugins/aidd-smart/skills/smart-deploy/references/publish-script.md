# 発行スクリプト

| 項目 | 内容 |
|---|---|
| ID | deploy-3 |
| 分類 | deploy |
| 関連 | deploy-1(Windows / systemd 両対応) / deploy-2(systemd unit の定石) / structure-2(Directory.Build.props 標準: Version の一括管理) / host-2(起動の定型行) |

## 目的

発行形態を**単一ファイル + self-contained に統一し、発行コマンドをスクリプトに固定する**。

- 配置先にランタイムを要求せず、実行ファイル1つ(+ appsettings)のコピーで配置が完結する
- 発行オプションを人の記憶ではなくスクリプトと csproj に置き、誰が発行しても同じ成果物になる
- 開発時のビルドには影響を与えず、発行時のみ単一ファイル化を有効にする

## 標準形

### csproj 側 — `DeploySingleFile` プロパティによる条件化

単一ファイル発行の設定は `DeploySingleFile` プロパティの**有無で条件化**する。プロパティを渡さない通常ビルド(開発・テスト)は従来どおりのまま、発行時のみ有効になる。

```xml
<PropertyGroup Condition="'$(DeploySingleFile)'!=''">
  <PublishSingleFile>true</PublishSingleFile>
  <SelfContained>true</SelfContained>
</PropertyGroup>

<ItemGroup>
  <Content Update="appsettings.*.json" CopyToPublishDirectory="Never" />
</ItemGroup>
```

| 設定 | 内容 |
|---|---|
| `PublishSingleFile` + `SelfContained` | 単一ファイル + ランタイム同梱。配置先に .NET のインストールを要求しない |
| `appsettings.*.json` を `CopyToPublishDirectory="Never"` | 環境別設定は発行物に含めない。環境の切り替えは環境変数(deploy-2)と配置先での管理に寄せる |

条件ブロックはこの2行を基本とする。ネイティブライブラリの同梱(`IncludeNativeLibrariesForSelfExtract`)やカルチャ非依存化(`InvariantGlobalization`)は必要なアプリでのみ追加する(→ バリエーション)。

### 発行スクリプト

リポジトリ直下に配置し、出力先を削除してから発行する(`dotnet publish -o` は出力先をクリーンしないため、古い成果物の混入を防ぐ)。

Windows 向け(`publish.ps1`)— **ReadyToRun は win のみ有効化**する。

```powershell
$output = './publish/win-x64'
if (Test-Path $output) { Remove-Item -Recurse -Force $output }

dotnet publish ./App.Host/App.Host.csproj -c Release -r win-x64 -o $output `
    -p:DeploySingleFile=true `
    -p:PublishReadyToRun=true
```

Linux 向け(`publish.sh`)。

```bash
#!/bin/sh
output=./publish/linux-x64
rm -rf "${output}"

dotnet publish ./App.Host/App.Host.csproj -c Release -r linux-x64 -o "${output}" \
    -p:DeploySingleFile=true
```

- 発行形態の判断(単一ファイル化・R2R)はスクリプトが `-p:` で渡し、csproj は条件付き定義で受ける、という役割分担にする
- `Version` は Directory.Build.props で一括管理しているため(structure-2)、発行スクリプトでバージョンを上書きしない

### appsettings の扱い

`appsettings.json` は実行ファイルの隣に**単一ファイルの外側**として置く(発行後も編集可能に保つ)。

```xml
<ItemGroup>
  <Content Include="appsettings.json">
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    <ExcludeFromSingleFile>True</ExcludeFromSingleFile>
  </Content>
  <Content Include="appsettings.*.json">
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    <CopyToPublishDirectory>Never</CopyToPublishDirectory>
    <DependentUpon>appsettings.json</DependentUpon>
    <ExcludeFromSingleFile>True</ExcludeFromSingleFile>
  </Content>
</ItemGroup>
```

単一ファイル実行時の設定・パス解決が成立するのは、host-2 の定型行(`SetCurrentDirectory(AppContext.BaseDirectory)` / `SetBasePath`)とセットになっているためである。

## 配置ルール

| 対象 | 場所 |
|---|---|
| 発行スクリプト | リポジトリのルート直下(`publish.ps1` / `publish.sh`) |
| 単一ファイル発行の条件付き設定 | ホストプロジェクトの csproj |
| 発行物 | Windows: サービス登録先のフォルダ / Linux: `/opt/<app>/`(deploy-2) |

## バリエーションと使い分け

- **ReadyToRun**: Windows 向けの発行でのみ `-p:PublishReadyToRun=true` を付け、起動時間を短縮する。サイズ増と天秤にかけ、Linux 常駐サービスでは付けない
- **ネイティブライブラリの同梱**: SQLite 等のネイティブ依存を持つアプリでは `IncludeNativeLibrariesForSelfExtract` を追加し、ネイティブライブラリも単一ファイルに含める(起動時に一時ディレクトリへ自己解凍)。付けない場合、ネイティブライブラリは実行ファイルの隣に出力される
- **InvariantGlobalization**: カルチャ依存の書式化・照合を使わないと言い切れる場合のみ `InvariantGlobalization` を追加し、ICU 非依存でサイズと起動を軽くする。適用実績は Blazor WASM クライアントのペイロード削減が主で、サーバ発行の既定には含めない
- **framework-dependent 発行**: ランタイムを統制済みの社内サーバ群に多数のアプリを同居させる場合のみ選択肢になる。既定は self-contained。Windows クライアント(WPF 等)では `--no-self-contained` + ReadyToRun + `IncludeNativeLibrariesForSelfExtract` を組み合わせた単一ファイル配布の実績がある(.NET 導入済み端末向け)
- **コンテナ配布**: コンテナイメージで配布する場合は単一ファイル化は不要で、本トピックの対象外

## アンチパターン

- **csproj への発行設定の直書き(無条件)** — `SelfContained` は通常のビルドにも効くため、開発時のビルド・テストまでランタイム同梱になり遅くなる。`DeploySingleFile` の有無で条件化する
- **発行コマンドの口伝** — オプションを README や記憶に置くと成果物が人によってブレる。スクリプトに固定する
- **出力先を消さずに発行** — `dotnet publish -o` は出力先をクリーンしないため、リネーム・削除済みの古いファイルが成果物に残留する
- **環境別 appsettings の同梱** — `appsettings.Production.json` 等を発行物に含めると、環境の切り替えが成果物の差し替えになる。`CopyToPublishDirectory="Never"` を徹底する
- **接続文字列・鍵の焼き込み** — 秘匿値を発行物に含めない。環境変数(deploy-2)または配置先の設定で与える
