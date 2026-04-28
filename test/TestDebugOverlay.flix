// Tests for DebugOverlay — ナビゲーション関数とオーバーレイ収集のテスト

// ========================================================================
// テスト用ヘルパー
// ========================================================================

/// テスト用のシーンツリーを構築する
///
///   Root (Plain)
///     ├─ BG (Sprite)
///     ├─ Player (Character)
///     │    ├─ PlayerSprite (AnimatedSprite)
///     │    └─ Hitbox (Area)
///     │         └─ Shape (RectShape 48x48)
///     └─ Enemy (Area)
///          └─ EnemyShape (RectShape 64x32)
///
def mkDebugTestTree(): SceneTree.Node =
    let bg = Sprite2D.init({name = "BG", pos = Vec2D.zero(),
        size = {x = 784.0f32, y = 1000.0f32}, texture = "white"});
    let playerSprite = AnimatedSprite2D.init({
        name = "PlayerSprite", pos = Vec2D.zero(),
        size = {x = 64.0f32, y = 64.0f32},
        animations = Map#{
            "idle" => ({frames = "FroggerIdle" :: Nil}: SceneTree.AnimationEntry),
            "walk" => ({frames = "FroggerIdle" :: "FroggerLeap" :: Nil}: SceneTree.AnimationEntry)
        },
        initialAnimation = "idle"
    });
    let hitboxShape = RectShape2D.init({name = "Shape", size = {x = 48.0f32, y = 48.0f32}});
    let hitbox = Area2D.init({name = "Hitbox", pos = {x = 8.0f32, y = 8.0f32}, children = hitboxShape :: Nil});
    let player = CharacterBody2D.init({name = "Player", pos = {x = 384.0f32, y = 832.0f32},
        children = playerSprite :: hitbox :: Nil})
        |> CharacterBody2D.moveSpeed(500.0f32);
    let enemyShape = RectShape2D.init({name = "EnemyShape", size = {x = 64.0f32, y = 32.0f32}});
    let enemy = Area2D.init({name = "Enemy", pos = {x = 100.0f32, y = 500.0f32},
        children = enemyShape :: Nil})
        |> Area2D.velocity({x = 100.0f32, y = 0.0f32});
    SceneTree.node2D("Root", Vec2D.zero(), bg :: player :: enemy :: Nil)

// ========================================================================
// nodeAtPath — パスによるノード検索
// ========================================================================

@Test
def testNodeAtPathEmptyReturnsRoot(): Unit \ Assert =
    // 空パスはルート自身を返す
    let root = mkDebugTestTree();
    let result = DebugOverlay.nodeAtPath(Nil, root) |> Option.map(SceneTree.nodeName);
    Assert.assertEq(expected = Some("Root"), result)

@Test
def testNodeAtPathSingleIndex(): Unit \ Assert =
    // [0] = Root の最初の子 = "BG"
    let root = mkDebugTestTree();
    let result = DebugOverlay.nodeAtPath(0 :: Nil, root) |> Option.map(SceneTree.nodeName);
    Assert.assertEq(expected = Some("BG"), result)

@Test
def testNodeAtPathNestedIndex(): Unit \ Assert =
    // [1, 0] = Root > Player > PlayerSprite
    let root = mkDebugTestTree();
    let result = DebugOverlay.nodeAtPath(1 :: 0 :: Nil, root) |> Option.map(SceneTree.nodeName);
    Assert.assertEq(expected = Some("PlayerSprite"), result)

@Test
def testNodeAtPathDeep(): Unit \ Assert =
    // [1, 1, 0] = Root > Player > Hitbox > Shape
    let root = mkDebugTestTree();
    let result = DebugOverlay.nodeAtPath(1 :: 1 :: 0 :: Nil, root) |> Option.map(SceneTree.nodeName);
    Assert.assertEq(expected = Some("Shape"), result)

@Test
def testNodeAtPathInvalidIndex(): Unit \ Assert =
    // [99] = 存在しないインデックス → None
    let root = mkDebugTestTree();
    let result = DebugOverlay.nodeAtPath(99 :: Nil, root);
    Assert.assertEq(expected = (None: Option[SceneTree.Node]), result)

// ========================================================================
// globalPosAtPath — グローバル座標の計算
// ========================================================================

@Test
def testGlobalPosAtPathRoot(): Unit \ Assert =
    // ルートの位置は (0,0)
    let root = mkDebugTestTree();
    let result = DebugOverlay.globalPosAtPath(Nil, root);
    Assert.assertEq(expected = Some(Vec2D.zero()), result)

@Test
def testGlobalPosAtPathPlayer(): Unit \ Assert =
    // Player の位置 = Root(0,0) + Player(384,832) = (384,832)
    let root = mkDebugTestTree();
    let result = DebugOverlay.globalPosAtPath(1 :: Nil, root);
    Assert.assertEq(expected = Some({x = 384.0f32, y = 832.0f32}), result)

@Test
def testGlobalPosAtPathHitbox(): Unit \ Assert =
    // Hitbox の位置 = Root(0,0) + Player(384,832) + Hitbox(8,8) = (392,840)
    let root = mkDebugTestTree();
    let result = DebugOverlay.globalPosAtPath(1 :: 1 :: Nil, root);
    Assert.assertEq(expected = Some({x = 392.0f32, y = 840.0f32}), result)

// ========================================================================
// navigateRight — 兄弟ノード右移動
// ========================================================================

@Test
def testNavigateRightFromFirst(): Unit \ Assert =
    // [0] → [1]（BG → Player）
    let root = mkDebugTestTree();
    let result = DebugOverlay.navigateRight(0 :: Nil, root);
    Assert.assertEq(expected = 1 :: Nil, result)

@Test
def testNavigateRightWraps(): Unit \ Assert =
    // [2] → [0]（Enemy → BG、ラップ）
    let root = mkDebugTestTree();
    let result = DebugOverlay.navigateRight(2 :: Nil, root);
    Assert.assertEq(expected = 0 :: Nil, result)

@Test
def testNavigateRightAtRoot(): Unit \ Assert =
    // 空パス（ルート自身）→ 変化なし
    let root = mkDebugTestTree();
    let result = DebugOverlay.navigateRight(Nil, root);
    Assert.assertEq(expected = (Nil: List[Int32]), result)

@Test
def testNavigateRightNested(): Unit \ Assert =
    // [1, 0] → [1, 1]（PlayerSprite → Hitbox）
    let root = mkDebugTestTree();
    let result = DebugOverlay.navigateRight(1 :: 0 :: Nil, root);
    Assert.assertEq(expected = 1 :: 1 :: Nil, result)

// ========================================================================
// navigateLeft — 兄弟ノード左移動
// ========================================================================

@Test
def testNavigateLeftFromSecond(): Unit \ Assert =
    // [1] → [0]（Player → BG）
    let root = mkDebugTestTree();
    let result = DebugOverlay.navigateLeft(1 :: Nil, root);
    Assert.assertEq(expected = 0 :: Nil, result)

@Test
def testNavigateLeftWraps(): Unit \ Assert =
    // [0] → [2]（BG → Enemy、ラップ）
    let root = mkDebugTestTree();
    let result = DebugOverlay.navigateLeft(0 :: Nil, root);
    Assert.assertEq(expected = 2 :: Nil, result)

@Test
def testNavigateLeftAtRoot(): Unit \ Assert =
    // 空パス → 変化なし
    let root = mkDebugTestTree();
    let result = DebugOverlay.navigateLeft(Nil, root);
    Assert.assertEq(expected = (Nil: List[Int32]), result)

// ========================================================================
// navigateDown — 子ノードに入る
// ========================================================================

@Test
def testNavigateDownFromRoot(): Unit \ Assert =
    // [] → [0]（Root → 最初の子 BG）
    let root = mkDebugTestTree();
    let result = DebugOverlay.navigateDown(Nil, root);
    Assert.assertEq(expected = 0 :: Nil, result)

@Test
def testNavigateDownIntoPlayer(): Unit \ Assert =
    // [1] → [1, 0]（Player → PlayerSprite）
    let root = mkDebugTestTree();
    let result = DebugOverlay.navigateDown(1 :: Nil, root);
    Assert.assertEq(expected = 1 :: 0 :: Nil, result)

@Test
def testNavigateDownLeafNode(): Unit \ Assert =
    // [0]（BG = Sprite、子なし）→ 変化なし
    let root = mkDebugTestTree();
    let result = DebugOverlay.navigateDown(0 :: Nil, root);
    Assert.assertEq(expected = 0 :: Nil, result)

// ========================================================================
// navigateUp — 親ノードに戻る
// ========================================================================

@Test
def testNavigateUpFromChild(): Unit \ Assert =
    // [1, 0] → [1]
    let result = DebugOverlay.navigateUp(1 :: 0 :: Nil);
    Assert.assertEq(expected = 1 :: Nil, result)

@Test
def testNavigateUpFromTopLevel(): Unit \ Assert =
    // [1] → []
    let result = DebugOverlay.navigateUp(1 :: Nil);
    Assert.assertEq(expected = (Nil: List[Int32]), result)

@Test
def testNavigateUpFromRoot(): Unit \ Assert =
    // [] → []
    let result = DebugOverlay.navigateUp(Nil);
    Assert.assertEq(expected = (Nil: List[Int32]), result)

// ========================================================================
// pathString — パスの文字列表現
// ========================================================================

@Test
def testPathStringRoot(): Unit \ Assert =
    let root = mkDebugTestTree();
    let result = DebugOverlay.pathString(Nil, root);
    Assert.assertEq(expected = "Root", result)

@Test
def testPathStringPlayer(): Unit \ Assert =
    let root = mkDebugTestTree();
    let result = DebugOverlay.pathString(1 :: Nil, root);
    Assert.assertEq(expected = "Root > Player", result)

@Test
def testPathStringDeep(): Unit \ Assert =
    let root = mkDebugTestTree();
    let result = DebugOverlay.pathString(1 :: 1 :: 0 :: Nil, root);
    Assert.assertEq(expected = "Root > Player > Hitbox > Shape", result)

// ========================================================================
// collectOverlay — ヒットボックス・スプライト境界の収集
// ========================================================================

@Test
def testCollectOverlayRootRectsCount(): Unit \ Assert =
    // Root 配下すべてのShape + Sprite/AnimatedSprite を収集する
    //  - BG (Sprite: 1 rect)
    //  - PlayerSprite (AnimatedSprite: 1 rect)
    //  - Shape in Hitbox (Shape: 1 rect)
    //  - EnemyShape (Shape: 1 rect)
    //  計4つの矩形
    let root = mkDebugTestTree();
    let overlay = DebugOverlay.collectOverlay(root, Vec2D.zero(), "font.ttf");
    Assert.assertEq(expected = 4, List.length(overlay#rects))

@Test
def testCollectOverlayPlayerRectsCount(): Unit \ Assert =
    // Player 配下:
    //  - PlayerSprite (AnimatedSprite: 1 rect)
    //  - Shape in Hitbox (Shape: 1 rect)
    //  計2つの矩形
    let root = mkDebugTestTree();
    let playerNode = DebugOverlay.nodeAtPath(1 :: Nil, root) |> Option.getWithDefault(root);
    let overlay = DebugOverlay.collectOverlay(playerNode, {x = 384.0f32, y = 832.0f32}, "font.ttf");
    Assert.assertEq(expected = 2, List.length(overlay#rects))

@Test
def testCollectOverlayAnimatedSpriteHasLabel(): Unit \ Assert =
    // Player 配下に AnimatedSprite があるので、アニメ情報のラベルが1つ生成される
    let root = mkDebugTestTree();
    let playerNode = DebugOverlay.nodeAtPath(1 :: Nil, root) |> Option.getWithDefault(root);
    let overlay = DebugOverlay.collectOverlay(playerNode, {x = 384.0f32, y = 832.0f32}, "font.ttf");
    Assert.assertEq(expected = 1, List.length(overlay#labels))

@Test
def testCollectOverlayShapeColor(): Unit \ Assert =
    // Enemy > EnemyShape のShape色は Area の緑 (0, 1, 0)
    let root = mkDebugTestTree();
    let enemyNode = DebugOverlay.nodeAtPath(2 :: Nil, root) |> Option.getWithDefault(root);
    let overlay = DebugOverlay.collectOverlay(enemyNode, {x = 100.0f32, y = 500.0f32}, "font.ttf");
    let rectColors = List.map(r -> r#color, overlay#rects);
    // Area2D の子 Shape は緑色
    Assert.assertEq(expected = ({r = 0.0f32, g = 1.0f32, b = 0.0f32}: Engine.Color) :: Nil, rectColors)

@Test
def testCollectOverlayLeafEmpty(): Unit \ Assert =
    // BG (Sprite、子なし) → 自身の境界のみ、labels なし
    let root = mkDebugTestTree();
    let bgNode = DebugOverlay.nodeAtPath(0 :: Nil, root) |> Option.getWithDefault(root);
    let overlay = DebugOverlay.collectOverlay(bgNode, Vec2D.zero(), "font.ttf");
    Assert.assertEq(expected = (1, 0), (List.length(overlay#rects), List.length(overlay#labels)))

// ========================================================================
// inspectorText — インスペクタ行の生成
// ========================================================================

@Test
def testInspectorTextRootContainsHeader(): Unit \ Assert =
    // Root ノードのインスペクタに "[Debug] Root" が含まれる
    let root = mkDebugTestTree();
    let lines = DebugOverlay.inspectorText(root, Nil, root, "font.ttf");
    let firstText = List.head(lines) |> Option.map(td -> td#text) |> Option.getWithDefault("");
    Assert.assertTrue(String.contains({substr = "[Debug] Root"}, firstText))

@Test
def testInspectorTextCharacterBody(): Unit \ Assert =
    // Player (Character2D) のインスペクタに "Type: Character2D" が含まれる
    let root = mkDebugTestTree();
    let playerNode = DebugOverlay.nodeAtPath(1 :: Nil, root) |> Option.getWithDefault(root);
    let lines = DebugOverlay.inspectorText(playerNode, 1 :: Nil, root, "font.ttf");
    let texts = List.map(td -> td#text, lines);
    let hasType = List.exists(t -> String.contains({substr = "Character2D"}, t), texts);
    Assert.assertTrue(hasType)

@Test
def testInspectorTextAnimatedSprite(): Unit \ Assert =
    // PlayerSprite (AnimatedSprite2D) のインスペクタに "Animation: idle" が含まれる
    let root = mkDebugTestTree();
    let spriteNode = DebugOverlay.nodeAtPath(1 :: 0 :: Nil, root) |> Option.getWithDefault(root);
    let lines = DebugOverlay.inspectorText(spriteNode, 1 :: 0 :: Nil, root, "font.ttf");
    let texts = List.map(td -> td#text, lines);
    let hasAnim = List.exists(t -> String.contains({substr = "Animation: idle"}, t), texts);
    Assert.assertTrue(hasAnim)

// ========================================================================
// ナビゲーション統合テスト
// ========================================================================

@Test
def testNavigateFullTraversal(): Unit \ Assert =
    // Root → [0] (Down) → [1] (Right) → [1,0] (Down) → [1] (Up) → [] (Up)
    //
    //   Root
    //     ├─ BG        [0]
    //     ├─ Player    [1]
    //     │    ├─ PlayerSprite  [1,0]
    //     │    └─ Hitbox        [1,1]
    //     └─ Enemy     [2]
    //
    let root = mkDebugTestTree();
    let p0 = (Nil: List[Int32]);
    let p1 = DebugOverlay.navigateDown(p0, root);      // [0]
    let p2 = DebugOverlay.navigateRight(p1, root);      // [1]
    let p3 = DebugOverlay.navigateDown(p2, root);        // [1, 0]
    let p4 = DebugOverlay.navigateUp(p3);                // [1]
    let p5 = DebugOverlay.navigateUp(p4);                // []
    let names = List.map(p -> DebugOverlay.nodeAtPath(p, root) |> Option.map(SceneTree.nodeName) |> Option.getWithDefault("?"),
        p0 :: p1 :: p2 :: p3 :: p4 :: p5 :: Nil);
    Assert.assertEq(expected = "Root" :: "BG" :: "Player" :: "PlayerSprite" :: "Player" :: "Root" :: Nil, names)
