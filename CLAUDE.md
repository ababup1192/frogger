## 言語

開発者とのやり取りは、日本語を使うこと

## 環境

- devbox shell で開発環境に入る（JDK 21 必須）
- bin/flix.jar は Flix 0.71.0（devbox には最新がないため手動ダウンロード）
- コマンド実行は `devbox run -- java -jar bin/flix.jar <command>` の形式で行う

```bash
devbox run -- java -jar bin/flix.jar test
devbox run -- java -jar bin/flix.jar run
devbox run -- java -jar bin/flix.jar build
```

**注意**: `devbox run flix test` は対話REPLに入ってしまうので使わないこと

## Flix バージョン更新

```bash
curl -L -o bin/flix.jar https://github.com/flix/flix/releases/download/vX.XX.X/flix.jar
```

## 変更後の確認

コード変更後は `/verify` スキルを実行すること。

## Flix コーディングルール

**重要**: Flix コードを書く前に `/flix-docs` スキルを実行し、公式ドキュメントとプロジェクト固有のルールを確認すること。

## 外部 JAR の利用

外部 JAR を追加する場合は `/add-jar` スキルを参照すること。

## ゲームエンジン開発のお作法

ゲームエンジン関連のコード（Scene, Game, Node）を触る場合は `/engine-guide` スキルを参照すること。
