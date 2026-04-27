---
name: flix-docs
description: "Flixコードを書く・修正する前にLLM向けドキュメントを取得して参照する"
allowed-tools: WebFetch
---

# Flix ドキュメント参照

Flixコードを書く・修正する前に、公式LLM向けドキュメントを参照してください。

## 手順

1. **WebFetch** で `https://doc.flix.dev/for-llms.html` を取得する
2. 以下の項目を特に確認する：
   - 型システムとエフェクト構文
   - モジュール規約
   - パターンマッチの書き方
   - パイプ演算子 `|>` の使い方

3. CLAUDE.md 固有の注意点を必ずリマインドする：

### Flix 0.71.0 固有の注意点
- **`handler` は予約語** — 変数名やimport文で使うとパースエラーになる。代替の単語を使うこと
- **Channel API** — `Channel.buffered(size)` は Region を受け取らない。戻り値は `(Sender[t], Receiver[t])` のタプル。エフェクトは `Chan` と `NonDet`
- **`@Test` 関数** — 必ず `Unit` を返す。`Assert.assertTrue` / `Assert.assertEq` を使う

### コーディングスタイル
- パイプスタイル `|>` を使い、一時変数を作らない
- レシーバとなる変数を最後の引数にする
- パターンマッチのネストを避け、高階関数を活用
- `map`, `flatMap` が続いたら `forM` を検討
- `map`, `filter` が続いたら `filterMap` を検討
- Random は `Math.Random`, `Math.Shuffle` を使う（JavaのAPIは使わない）

## 出力

取得したドキュメントの要点を簡潔に提示し、これからの作業に関連する部分をハイライトすること。
