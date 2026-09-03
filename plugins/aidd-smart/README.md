# aidd-smart - Smart アーキテクチャルール

Smart ライブラリを使用したアプリケーションテンプレートで使用する。
`dotnet-*` の中立規律を上書き具体化し、ライブラリを断定する(Smart.Mvvm / Smart.Navigation / Smart.Data.Accessor / Serilog / NSwag ほか)。

## 🚀 導入

```
/plugin install aidd-smart@aidd   # 依存で aidd-dotnet も入る
/aidd-smart:init                  # rules 19 本を .claude/rules/ へ展開 (managed。プラグイン更新後は再実行)
```

## 🧠 rules

| rule | 内容 |
|---|---|
| [smart-structure](.claude/rules/smart-structure.md) | プロジェクト構造(警告抑止三層・定型ファイル・メンバ順序) |
| [smart-solution](.claude/rules/smart-solution.md) | ソリューション分割 |
| [smart-namespace](.claude/rules/smart-namespace.md) | 名前空間辞書 |
| [smart-host](.claude/rules/smart-host.md) | DI 登録(登録順・切り出し・スコープ) |
| [smart-config](.claude/rules/smart-config.md) | 設定クラス |
| [smart-log](.claude/rules/smart-log.md) | ログ(LoggerMessage 定型・Serilog・調査用トグル) |
| [smart-data](.claude/rules/smart-data.md) | データアクセス(Smart.Data.Accessor・2-way SQL) |
| [smart-web](.claude/rules/smart-web.md) | Web API(Minimal API・契約・NSwag) |
| [smart-blazor](.claude/rules/smart-blazor.md) | Blazor(code-behind 分離・基底・検証) |
| [smart-mvvm](.claude/rules/smart-mvvm.md) | MVVM(Smart.Mvvm / Navigation / Resolver・Modules 構成) |
| [smart-wpf](.claude/rules/smart-wpf.md) | WPF(WindowManager 方式) |
| [smart-avalonia](.claude/rules/smart-avalonia.md) | Avalonia(組込み向け入力抽象化) |
| [smart-maui](.claude/rules/smart-maui.md) | MAUI(自前 Shell・Components 分割・Blazor Hybrid) |
| [smart-worker](.claude/rules/smart-worker.md) | バッチ・CLI(IAction + ActionWorker・System.CommandLine) |
| [smart-network](.claude/rules/smart-network.md) | TCP サーバ(Kestrel ConnectionHandler・アロケーションフリー) |
| [smart-test](.claude/rules/smart-test.md) | テスト(xunit.v3 + MTP・AAA・モック方針) |
| [smart-telemetry](.claude/rules/smart-telemetry.md) | テレメトリ・ヘルスチェック(ApplicationInstrument) |
| [smart-generator](.claude/rules/smart-generator.md) | ソースジェネレータ(IIncrementalGenerator・実ビルドテスト) |
| [smart-guideline](.claude/rules/smart-guideline.md) | 横断ガイドライン詳細(エラー処理・非同期・HTTP クライアント) |

## 🧰 その他

| 提供物 | 内容 |
|---|---|
| [init](skills/init/SKILL.md) | smart rules の展開 |
| references | rule と対になる同名の器 skill(skills/smart-*/references/)がコード例付き詳細 69 本を保持。rule 末尾から誘導され必要時に読まれる |
