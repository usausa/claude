---
id: SAMPLE-03
title: サービスは全 Singleton とし、リクエスト文脈は AsyncLocal で扱う
status: accepted
date: 20XX-XX-XX
tags: [coding-principles]
related: [SAMPLE-02]
superseded-by:
---

> **サンプル ADR**(DI ライフタイムというプロジェクト方針の記録例)。テンプレはライフタイムの既定を定めないため、決める場合はこの形で残す。

## 背景 / 課題

DI ライフタイムの既定方針を決める必要がある。ASP.NET Core の慣例では Scoped(リクエスト単位)を多用するが、Scoped は captive dependency(Singleton が Scoped を掴む)事故の温床になる。さらに Blazor Server 同居構成では Scoped の意味が「回路 = 接続」単位に変わり、Web API の「リクエスト」単位と一致しない。サービス層は原則ステートレスで、リクエスト固有の状態はごく少数(認証情報・ログ文脈・リクエスト内メモ化)しかない。

## 決定

- サービス(Service / Usecase / Accessor / 横断部品)は**全て Singleton** で登録する
- リクエストを跨いではならない文脈は **`AsyncLocal` ベースのコンテキスト**に置き、ライフサイクルインターフェースとして登録 → グローバルフィルタがリクエスト開始時と終了時(finally)に一括 `Clear()` する
- 設定は `Configure<T>` + `IOptions<T>.Value` の Singleton 直登録で、利用側は素の `T` を注入する

## 検討した代替案

- **案A: Scoped を基本にする(慣例)** / 却下理由: ライフタイム混在による captive dependency の危険、Blazor Server とのスコープ意味論の不一致、リクエスト毎のグラフ構築コスト。実際に Scoped が必要な状態がほぼ無い
- **案B: HttpContext.Items で文脈受け渡し** / 却下理由: HttpContext への依存が Service 層へ漏れる。Blazor / Worker で同じコードが使えない

## 結果(トレードオフ・影響)

- **得たもの**: ライフタイム事故の構造的排除、登録の単純化(生成やヘルパーで機械化しやすい)、ホスティング形態(Web / Blazor / Worker)をまたぐ同一コード
- **捨てたもの**: 「フィールドに置けば済む」手軽さ — サービスに可変状態を持つことは禁止になり、状態は明示的な管理(AsyncLocal / State クラス / キャッシュ部品)に限定される
- **将来への注意**: Clear 漏れは状態リークになる。ライフサイクルの一括 Clear をフィルタ 1 箇所に集約して機械化する
