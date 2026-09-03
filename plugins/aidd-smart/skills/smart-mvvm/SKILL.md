---
name: smart-mvvm
description: Smart スタックの MVVM 標準 (Smart.Mvvm・Smart.Navigation・Smart.Resolver・Modules 構成)
paths:
  - "src/**"
---

# MVVM (Smart スタック標準)

> `aidd-dotnet` の dotnet-mvvm を具体化し、基盤を断定する。詳細・コード例は references/ を必要時に読む。

- MVVM 基盤は **Smart.Mvvm**: アプリ共通基底 `AppViewModelBase : ExtendViewModelBase` + `[ObservableGeneratorOption(Reactive = true, ViewModel = true)]`、変更通知は `[ObservableProperty]` + partial プロパティ、コマンドは `MakeDelegateCommand` / `MakeAsyncCommand` (+ `BusyState` ガード)、購読は `Disposables`、通知は `IReactiveMessenger`。CommunityToolkit.Mvvm は導入しない。
- **画面遷移はプラットフォームを問わず Smart.Navigation**: 画面 ID は enum (`ViewId` / `DialogId`)、View に `[View(ViewId.X)]`、登録は `[ViewSource]` partial + `AutoRegister`、シェルは `NavigationContainer`、起動末尾に `ForwardAsync(初期画面)`、DEBUG 時のみ遷移トレース。ツール的な子ウィンドウ管理のみ `WindowManager`。
- DI は **Smart.Resolver**: `ConfigureContainer(new SmartServiceProviderFactory(), ConfigureContainer)`、冒頭で `UseAutoBinding/ArrayBinding/AssignableBinding`、ホスト構築後に `ResolveProvider.Default.Provider = host.Services`、XAML から `s:DataContextResolver.Type` で VM 解決 (code-behind は `InitializeComponent()` のみ)。
- **多数の画面を持つアプリは `Modules/<機能>` に View + ViewModel を機能単位で同居配置** (vertical slice)。`Modules/` 直下は横断部品 (ViewId・基底 VM) のみ。
- 起動ハブ: `ApplicationExtensions.cs` に `ConfigureLogging` / `ConfigureComponents` / `StartApplicationAsync` / `ExitApplicationAsync` を集約し App を薄く保つ。

## references (詳細)

smart-mvvm / smart-navigation / smart-resolver / modules-structure / client-startup-hub
