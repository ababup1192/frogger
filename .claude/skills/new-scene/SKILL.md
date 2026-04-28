---
name: new-scene
description: "新しいSceneファイルを既存パターンに沿ってスキャフォールドする"
allowed-tools: Read, Edit, Write, Glob, Grep
---

# 新規 Scene スキャフォールド

新しい Scene を追加するとき、既存のパターンに沿ったボイラープレートを生成する。

## 手順

1. ユーザーにシーンの情報を確認する:
   - シーン名（モジュール名）
   - 子ノードの一覧（Child enum に入れるもの）
   - 親シーンはどこか（FroggerScene の子として追加するか、独立か）

2. 以下のテンプレートに従って `src/scene/{SceneName}.flix` を生成する

3. 親シーンへの登録が必要なら、親の `Child` enum と `SceneChild` instance に追加する

4. テストファイル `test/Test{SceneName}.flix` の雛形も生成する

## テンプレート

```flix
// {SceneName} — {一行説明}

mod {SceneName} {

    // ========================================================================
    // 子ノード定義
    // ========================================================================

    /// このシーンが管理する子ノードの一覧
    pub enum Child with Eq, ToString {
        case {Child1}
        case {Child2}
        // ...
    }

    instance SceneTree.SceneChild[Child] {
        pub def sceneName(_c: Child): String = {SceneName}.containerName()
        pub def childName(c: Child): String = match c {
            case Child.{Child1} => "{child1Name}"
            case Child.{Child2} => "{child2Name}"
            // ...
        }
    }

    // ========================================================================
    // 定数
    // ========================================================================

    /// コンテナノードの名前
    pub def containerName(): String = "{SceneName}"

    // ========================================================================
    // シーン構築
    // ========================================================================

    /// 初期シーンを構築する
    pub def buildScene(): SceneTree.Node =
        SceneTree.Node.MkNode(
            containerName(),
            {x = 0.0f32, y = 0.0f32},
            SceneTree.NodeKind.Plain,
            {Child1} :: {Child2} :: Nil
        )

    // ========================================================================
    // 更新
    // ========================================================================

    /// フレーム更新処理
    pub def update(dt: Float32, scene: SceneTree.Node): SceneTree.Node =
        // TODO: 実装
        scene
}
```

## テストテンプレート

```flix
// Test{SceneName} — {SceneName} のユニットテスト

// ========================================================================
// 初期構築テスト
// ========================================================================

@Test
def test{SceneName}Build(): Unit \ Assert =
    // 初期構築が成功し、コンテナノードが正しい名前を持つことを確認
    let scene = {SceneName}.buildScene()
    Assert.assertEqual("{SceneName}", SceneTree.nodeName(scene))
```

## 注意事項

- `containerName()` は親シーンの `SceneChild` instance から参照される
- 既存の Scene（`VehicleLane.flix`, `WaterLane.flix`, `HomeSlot.flix`）を参考にすること
- ノードの種類は `NodeBuilders.flix` のビルダーを活用する（MkNode は最終手段）
- 座標やサイズの定数は名前付き関数として定義し、マジックナンバーを避ける
