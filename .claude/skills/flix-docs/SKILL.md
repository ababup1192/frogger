---
name: flix-docs
description: "Flixの公式ドキュメントとプロジェクト固有のコーディングスタイルを確認する。パイプスタイル、エフェクト構文、テストの書き方、0.71.0固有の注意点を含む"
when_to_use: "Flixコードを新規作成・修正するとき、テストを書くとき、Flix構文を確認したいとき"
allowed-tools: WebFetch
---

# Flix ドキュメント参照

Flixコードを書く・修正する前に、公式LLM向けドキュメントと本プロジェクトのルールを確認してください。

## 手順

1. **WebFetch** で `https://doc.flix.dev/for-llms.html` を取得する
2. 以下の項目を特に確認する：
   - 型システムとエフェクト構文
   - モジュール規約
   - パターンマッチの書き方
   - パイプ演算子 `|>` の使い方

3. 取得したドキュメントの要点を簡潔に提示し、これからの作業に関連する部分をハイライトすること

4. 以下のプロジェクト固有ルールを必ずリマインドすること

---

## Flix コーディングスタイル

### 全般

- 関数には必ずドキュメントコメントを書くこと。何の処理をしているか、意図が読み手に明確に伝わること
- ドキュメントコメントは、汎用的なものを除いて、専門用語を避けて、平易な言葉で説明すること
- type alias でレコード定義、enum、struct は、全体のコメントと各フィールドの役割のコメントを書くこと
- 関数の引数にプリミティブな引数が並ぶ場合は、named-parameters と syntax sugar を採用すること
  - https://doc.flix.dev/records.html?highlight=name#named-parameters

### パイプスタイル

- なるべくパイプスタイルを使い `|>` で一時変数を作らないこと
- インラインで書ける場合は、インラインで書いて、一時変数を作らないこと
- `|>` で書きやすいように、レシーバとなる変数を最後の引数として関数を作ること

### 高階関数

- パターンマッチがネストしないように、高階関数をなるべく利用すること
- `map`, `flatMap` などが続いたら、`forM` が使えないか検討すること
- `map`, `filter` などが続いたら、`filterMap` 等の関数が使えないか検討すること

### ライブラリ選択

- Random は、Java の API を使わず `Math.Random`, `Math.Shuffle` を使う。うまくいかない場合は、RandomUtil を拡張
- ファイル操作は、[Fs](https://api.flix.dev/Fs.html), [BufReader](https://api.flix.dev/BufReader.html) を検討

---

## テストコードスタイル

- テストケースは、意図がわかるように必ずコメントを丁寧に書くこと
- 複雑なテストの場合のコメントは、アスキーアートを書くこと
- テストは、なるべく 1 assert で書くこと。複数の値は、List やタプルで比較すること
- テストで、パターンマッチなどの分岐は書かないこと。分岐がそもそも生じないような書き方を検討すること
  - もし分岐がどうしても生じる場合は、来てはいけない分岐で `bug!` を使用すること
- 責務を意識して、テストを書くこと。なるべく、対象となるモジュールのデータやイニシャライズ関数を使うこと
- テストはグルーピングと順序に気をつけること。describe は Flix にはないため、グルーピングできるものは大きめのコメントで区切ること

### @Test 関数の戻り値

- `@Test` 関数は必ず `Unit` を返す必要がある
- Assert モジュールを使って assertion をする

```flix
@Test
def testFoo(): Unit \ Assert =
    Assert.assertTrue(someCondition)
```

---

## Flix 0.71.0 固有の注意点（公式ドキュメントに載っていない）

### 予約語に注意

- `handler` は予約語（エフェクトハンドラで使用）
- import 文、変数名として使うとパースエラーになる
- 代わりの英単語を使うか、2単語以上で命名する

```flix
// NG: handler は予約語
case Some((handler, params)) => ...

// OK: 別の単語を使う
case Some((action, params)) => ...
```

### Channel API

- Java の atomic 変数を使いたくなったら見ること
- `Channel.buffered(size)` — Region を受け取らない、サイズのみ
- 戻り値は `(Sender[t], Receiver[t])` のタプル
- エフェクトは `Chan` と `NonDet`
- 参考: https://doc.flix.dev/concurrency.html?highlight=Channel#communicating-with-channels

### try-catch での Java 例外

- import してから使う（`##java.io.IOException` ではなく `IOException`）

### Java interop

- Java の import をするときは、モジュールのトップレベルに書く必要がある
- import を書かずに `java.Math.abs()` のようには呼び出せない
