## 言語
開発者とのやり取りは、日本語を使うこと

## 環境

- devbox shell で開発環境に入る（JDK 21 必須）
- `flix run` / `flix test` / `flix build` で実行
- bin/flix.jar は Flix 0.71.0（devbox には最新がないため手動ダウンロード）

## Flix バージョン更新

```bash
curl -L -o bin/flix.jar https://github.com/flix/flix/releases/download/vX.XX.X/flix.jar
```

## 変更後の確認

コード変更後は必ず以下を両方実行すること：
1. `flix test` - テストが通ることを確認
2. `flix run`  - 実際に動作することを確認

## Flix コーディングルール

**重要**: Flix コードを書く前に必ず以下を参照すること（WebFetch で取得）
https://doc.flix.dev/for-llms.html

ここに書いてあるルールは決して破らないこと。

## Flix コーディングスタイル
- なるべく パイプスタイルを使い |> で 一時変数を作らないこと
- インラインで書ける場合は、インラインで書いて、一時変数を作らないこと
- |>で書きやすいように、レシーバとなる変数を最後の引数として、関数を作ること
- パターンマッチがネストしないように、高階関数をなるべく利用すること
- map, flatMap などが続いたら、forMが使えないか検討すること
- map, filter などが続いたら、filterMap等の関数が変えないか検討すること
- Randomは、JavaのAPIを使わず Math.Random, Math.Shuffleを使う。うまくいかない場合は、RandomUtilを拡張
- ファイル操作は、[Fs](https://api.flix.dev/Fs.html), [BufReader](https://api.flix.dev/BufReader.html) を検討

### テストコードスタイル
- テストコードは、意図がわかるようにコメントを丁寧に書くこと
- 複雑なテストは、アスキーアートを書くこと
- 専門用語が難しい場合は、平易な言葉を検討すること
- テストは、なるべく1assertで書くこと。複数の値は、Listやタプルで比較すること
- テストで、パターンマッチなどの分岐は書かないでください。来てはいけない分岐では、bug!を使用すること
- 責務を意識して、テストを書くこと。なるべく、対象となるモジュールのデータやイニシャライズ関数を使うこと
- テストはグルーピングと順序に気をつけてください。describeはflixにはないため、グルーピングできるものは、大きめのコメントで区切ってください。

## Flix 0.71.0 固有の注意点（公式ドキュメントに載っていない）

### Channel API
- Javaのatomic変数を使いたくなったら見ること
- `Channel.buffered(size)` - Region を受け取らない、サイズのみ
- 戻り値は `(Sender[t], Receiver[t])` のタプル
- エフェクトは `Chan` と `NonDet`
- ここを見てからコードを書くこと https://doc.flix.dev/concurrency.html?highlight=Channel#communicating-with-channels

### try-catch での Java 例外
- import してから使う（`##java.io.IOException` ではなく `IOException`）

### 予約語に注意
- `handler` は予約語（エフェクトハンドラで使用）
- import文, 変数名として使うとパースエラーになる
- 代わりの英単語を使うか、~~Handlerのように2単語以上で命名する

```flix
// NG: handler は予約語
case Some((handler, params)) => ...

// OK: 別の単語 を使う
case Some((action, params)) => ...
```

## テストの書き方

### @Test 関数の戻り値
- `@Test` 関数は必ず `Unit` を返す必要がある
- Assertモジュールを使って、assertionをする

```flix
// OK: Assert.assertTrue でラップ
@Test
def testFoo(): Unit \ Assert =
    Assert.assertTrue(someCondition)
```

### interlop Java
- Javaのimportをするときは、モジュールのトップレベルに書く必要がある
- importを書かずに java.Math.abs() のようには呼び出せない

## 外部 JAR の利用

予約語（`handler` 等）を含むパッケージは Java ラッパー経由で使う。

1. `flix.toml` に Maven 依存追加 → `flix build` で `lib/cache/` にダウンロード
2. Java ラッパーをコンパイルして `lib/external/xxx.jar` に配置
3. `flix.toml` の `[jar-dependencies]` に `"xxx.jar" = "url:file://local"` を追加
4. Flix から `import mypkg.MyClass` で利用

## ゲームエンジン開発のお作法

### コーディングスタイル
- 無駄な実装(特に座標系)をしてしまわないように、状況に適したNodeの種類を選び、使ってください。
- SceneTree.Node.MkNode は、手動でNodeを作るので、最終手段です。既存のNodeをなるべく使ってください。
- 実装が複雑になっている場合は、ゲームエンジンが拡張できないか考え、提案してください。
- イベントの検知を有効活用してください、OnCollision, OnTimeoutなど、便利なAlgebraic Effectが用意されています
- イベントのノードは、nameをSceneTree.childNameなどで必ずフィルタすること

### Game ファイルの責務
- ゲーム全体の状態定義（`GameState` 等）とメインループを持つ
- 入力のポーリング・エッジ検出を行い、Scene に渡す
- Scene の構築・入力適用・フレーム更新を呼び出す **オーケストレーター**
- ゲーム固有のロジック（移動計算等）はSceneに委譲する

### Scene ファイルの責務
- シーンが管理する子ノードを`SceneTree.SceneChild`で定義する
- シーンの初期構築（`buildInitialScene` 相当）を提供する
- 親子関係があるSceneでは、責務を決め、親は子の呼び出し委譲をするオーケストレーターに徹する
