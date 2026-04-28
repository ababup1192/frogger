// Tests for TurtleLane — lane construction, section placement, wrapping, platform detection

// ========================================================================
// Lane Config Tests
// ========================================================================

@Test
def testTurtleLaneConfigCount(): Unit \ Assert =
    // 亀レーンは2つ（レーン4とレーン5）
    Assert.assertEq(expected = 2, List.length(TurtleLane.laneConfigs()))

@Test
def testTurtleLane4Config(): Unit \ Assert =
    // レーン4: 右方向, 亀3匹/セクション, 3セクション
    match List.head(TurtleLane.laneConfigs()) {
        case Some(cfg) =>
            Assert.assertEq(
                expected = (4, 1.0f32, 3, 3),
                (cfg#laneIndex, cfg#direction, cfg#turtleCount, cfg#sectionCount))
        case None => bug!("laneConfigs is empty")
    }

@Test
def testTurtleLane5Config(): Unit \ Assert =
    // レーン5: 左方向, 亀2匹/セクション, 4セクション
    match List.nth(1, TurtleLane.laneConfigs()) {
        case Some(cfg) =>
            Assert.assertEq(
                expected = (5, -1.0f32, 2, 4),
                (cfg#laneIndex, cfg#direction, cfg#turtleCount, cfg#sectionCount))
        case None => bug!("laneConfigs has no second element")
    }

// ========================================================================
// Lane Y Position Tests
// ========================================================================

@Test
def testTurtleLaneY4(): Unit \ Assert =
    // レーン4は y=320（64 + 4×64）
    Assert.assertEq(expected = 320.0f32, TurtleLane.laneY(4))

@Test
def testTurtleLaneY5(): Unit \ Assert =
    // レーン5は y=384（64 + 5×64）
    Assert.assertEq(expected = 384.0f32, TurtleLane.laneY(5))

// ========================================================================
// Section Size Tests
// ========================================================================

@Test
def testSectionWidth2Turtles(): Unit \ Assert =
    // 亀2匹: 2×64 = 128
    Assert.assertEq(expected = 128.0f32, TurtleGroup.width(2))

@Test
def testSectionWidth3Turtles(): Unit \ Assert =
    // 亀3匹: 3×64 = 192
    Assert.assertEq(expected = 192.0f32, TurtleGroup.width(3))

@Test
def testSectionSize2Turtles(): Unit \ Assert =
    // 亀2匹セクション: 幅128, 高さ48
    let sz = TurtleGroup.size(2);
    Assert.assertEq(expected = (128.0f32, 48.0f32), (sz#x, sz#y))

@Test
def testSectionSize3Turtles(): Unit \ Assert =
    // 亀3匹セクション: 幅192, 高さ48
    let sz = TurtleGroup.size(3);
    Assert.assertEq(expected = (192.0f32, 48.0f32), (sz#x, sz#y))

// ========================================================================
// buildTurtleLanes structure tests
// ========================================================================

@Test
def testTurtleLanesContainerName(): Unit \ Assert =
    Assert.assertEq(expected = "TurtleLanes",
        TurtleLane.buildTurtleLanes() |> SceneTree.nodeName)

@Test
def testTurtleLaneCount(): Unit \ Assert =
    // コンテナ直下に2つのレーンノード
    Assert.assertEq(expected = 2,
        TurtleLane.buildTurtleLanes() |> SceneTree.nodeChildren |> List.length)

@Test
def testTurtleLane4SectionCount(): Unit \ Assert =
    // レーン4は3セクション
    match SceneTree.findNode("TurtleLane4", TurtleLane.buildTurtleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 3, List.length(SceneTree.nodeChildren(lane)))
        case None => bug!("TurtleLane4 not found")
    }

@Test
def testTurtleLane5SectionCount(): Unit \ Assert =
    // レーン5は4セクション
    match SceneTree.findNode("TurtleLane5", TurtleLane.buildTurtleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 4, List.length(SceneTree.nodeChildren(lane)))
        case None => bug!("TurtleLane5 not found")
    }

// ========================================================================
// Lane Y position in scene tree
// ========================================================================

@Test
def testTurtleLane4YPosition(): Unit \ Assert =
    match SceneTree.findNode("TurtleLane4", TurtleLane.buildTurtleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 320.0f32, SceneTree.nodePosition(lane)#y)
        case None => bug!("TurtleLane4 not found")
    }

@Test
def testTurtleLane5YPosition(): Unit \ Assert =
    match SceneTree.findNode("TurtleLane5", TurtleLane.buildTurtleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 384.0f32, SceneTree.nodePosition(lane)#y)
        case None => bug!("TurtleLane5 not found")
    }

// ========================================================================
// Section node kind — sections are Area2D
// ========================================================================

@Test
def testSectionIsArea2D(): Unit \ Assert =
    match SceneTree.findNode("T4_0", TurtleLane.buildTurtleLanes()) {
        case Some(secNode) => match SceneTree.nodeKind(secNode) {
            case SceneTree.NodeKind.Area(_) => Assert.assertTrue(true)
            case _ => bug!("T4_0 should be Area2D")
        }
        case None => bug!("T4_0 not found")
    }

// ========================================================================
// Section has collision shape
// ========================================================================

@Test
def testSectionHasCollisionShape(): Unit \ Assert =
    match SceneTree.findNode("T4_0", TurtleLane.buildTurtleLanes()) {
        case Some(secNode) =>
            match SceneTree.findNode("Shape", secNode) {
                case Some(shape) => match SceneTree.nodeKind(shape) {
                    case SceneTree.NodeKind.Shape(_) => Assert.assertTrue(true)
                    case _ => bug!("Shape should be CollisionShape")
                }
                case None => bug!("Shape not found in section")
            }
        case None => bug!("T4_0 not found")
    }

// ========================================================================
// Section has turtle sprites
// ========================================================================

@Test
def testLane4SectionHas3Sprites(): Unit \ Assert =
    // レーン4のセクションは亀3匹 → Sprite0, Sprite1, Sprite2 + Shape = 4子ノード
    match SceneTree.findNode("T4_0", TurtleLane.buildTurtleLanes()) {
        case Some(secNode) =>
            // 3スプライト + 1Shape = 4
            Assert.assertEq(expected = 4, List.length(SceneTree.nodeChildren(secNode)))
        case None => bug!("T4_0 not found")
    }

@Test
def testLane5SectionHas2Sprites(): Unit \ Assert =
    // レーン5のセクションは亀2匹 → Sprite0, Sprite1 + Shape = 3子ノード
    match SceneTree.findNode("T5_0", TurtleLane.buildTurtleLanes()) {
        case Some(secNode) =>
            // 2スプライト + 1Shape = 3
            Assert.assertEq(expected = 3, List.length(SceneTree.nodeChildren(secNode)))
        case None => bug!("T5_0 not found")
    }

@Test
def testSpriteAnimation(): Unit \ Assert =
    // 亀スプライトは AnimatedSprite で、初期アニメーションが "swim"
    match SceneTree.findNode("T4_0", TurtleLane.buildTurtleLanes()) {
        case Some(secNode) =>
            match SceneTree.findNode("Sprite0", secNode) {
                case Some(sprite) => match SceneTree.nodeKind(sprite) {
                    case SceneTree.NodeKind.AnimatedSprite(asd) =>
                        Assert.assertEq(expected = "swim", asd#currentAnimation)
                    case _ => bug!("Sprite0 should be AnimatedSprite")
                }
                case None => bug!("Sprite0 not found")
            }
        case None => bug!("T4_0 not found")
    }

// ========================================================================
// Section naming tests
// ========================================================================

@Test
def testSectionNaming(): Unit \ Assert =
    Assert.assertEq(expected = "T4_2", TurtleLane.sectionName(4, 2))

@Test
def testSectionNaming50(): Unit \ Assert =
    Assert.assertEq(expected = "T5_0", TurtleLane.sectionName(5, 0))

// ========================================================================
// wrapX tests — direction-aware wrapping
// ========================================================================

@Test
def testTurtleWrapXLeftMovingPastLeft(): Unit \ Assert =
    //   ┌────────────────────┐
    //   │      screen        │ →ワープ先(右端)
    //   └────────────────────┘
    // ←亀セクション(消える)
    let turtleCount = 2;
    let x = TurtleLane.wrapMin(turtleCount) - 1.0f32;
    Assert.assertEq(expected = TurtleLane.wrapMax(), TurtleLane.wrapX(x, -1.0f32, turtleCount))

@Test
def testTurtleWrapXRightMovingPastRight(): Unit \ Assert =
    // ワープ先(左端)←
    //   ┌────────────────────┐
    //   │      screen        │
    //   └────────────────────┘  亀→(消える)
    let turtleCount = 3;
    let x = TurtleLane.wrapMax() + 1.0f32;
    Assert.assertEq(expected = TurtleLane.wrapMin(turtleCount), TurtleLane.wrapX(x, 1.0f32, turtleCount))

@Test
def testTurtleWrapXInBounds(): Unit \ Assert =
    // 画面内 → ワープなし
    Assert.assertEq(expected = 300.0f32, TurtleLane.wrapX(300.0f32, 1.0f32, 2))

@Test
def testTurtleWrapXLeftMovingInBounds(): Unit \ Assert =
    // 左方向でも画面内ならワープなし
    Assert.assertEq(expected = 400.0f32, TurtleLane.wrapX(400.0f32, -1.0f32, 3))

// ========================================================================
// Platform Overlap Detection Tests
// ========================================================================

@Test
def testNoTurtleOverlapAtStartPos(): Unit \ {Assert, Fs.FileRead} =
    // スタート地点(y=832)ではどの亀とも重ならない
    let scene = FroggerScene.buildInitialScene();
    Assert.assertTrue(Option.isEmpty(TurtleLane.findOverlappingTurtleVelocity(scene)))

// ========================================================================
// Physics movement tests — turtles move via Area2D velocity
// ========================================================================

@Test
def testTurtleMovesRightward(): Unit \ Assert =
    // T4_0 はレーン4で右方向 (speed=100, direction=1) なので右に移動する
    let scene = SceneTree.node2D("Root", Vec2D.zero(), TurtleLane.buildTurtleLanes() :: Nil);
    match SceneTree.findNode("T4_0", scene) {
        case Some(secNode) =>
            let initX = SceneTree.nodePosition(secNode)#x;
            let moved = SceneTree.runWithNoopCollision(() ->
                SceneTree.stepAndCollide(scene, 0.1f32, FroggerScene.physicsConfig()));
            match SceneTree.findNode("T4_0", moved) {
                case Some(movedSec) => Assert.assertTrue(SceneTree.nodePosition(movedSec)#x > initX)
                case None => bug!("T4_0 not found after move")
            }
        case None => bug!("T4_0 not found")
    }

@Test
def testTurtleMovesLeftward(): Unit \ Assert =
    // T5_0 はレーン5で左方向 (speed=130, direction=-1) なので左に移動する
    let scene = SceneTree.node2D("Root", Vec2D.zero(), TurtleLane.buildTurtleLanes() :: Nil);
    match SceneTree.findNode("T5_0", scene) {
        case Some(secNode) =>
            let initX = SceneTree.nodePosition(secNode)#x;
            let moved = SceneTree.runWithNoopCollision(() ->
                SceneTree.stepAndCollide(scene, 0.1f32, FroggerScene.physicsConfig()));
            match SceneTree.findNode("T5_0", moved) {
                case Some(movedSec) => Assert.assertTrue(SceneTree.nodePosition(movedSec)#x < initX)
                case None => bug!("T5_0 not found after move")
            }
        case None => bug!("T5_0 not found")
    }

// ========================================================================
// Drowning tests — 亀に乗っている場合は溺死しない
// ========================================================================

@Test
def testShouldNotDrownOnTurtle(): Unit \ {Assert, Fs.FileRead} =
    // 水域内(y=320)かつ亀セクション(T4_0)の上 → 溺死しない
    //   ┌────────────────────────┐
    //   │  T4_0 [亀][亀][亀]     │  ←プレイヤーが亀の上
    //   └────────────────────────┘
    let scene = FroggerScene.buildInitialScene();
    // T4_0のグローバル位置を取得してプレイヤーをその上に配置
    match SceneTree.globalPosition("T4_0", scene) {
        case Some(turtlePos) =>
            let playerPos = {x = turtlePos#x + 10.0f32, y = turtlePos#y - 14.0f32};
            let movedScene = scene
                |> SceneTree.setNodePosition(FroggerPlayer.playerName(), playerPos);
            // 亀に乗っているので溺死しない
            let onTurtle = not Option.isEmpty(TurtleLane.findOverlappingTurtleVelocity(movedScene));
            Assert.assertTrue(onTurtle)
        case None => bug!("T4_0 not found in scene")
    }

// ========================================================================
// isAtTarget tests — 移動中は溺死判定をスキップする
// ========================================================================

@Test
def testIsAtTargetWhenAtTarget(): Unit \ {Assert, Fs.FileRead} =
    // プレイヤーがスタート地点にいる（pos == targetPos） → isAtTarget = true
    let scene = FroggerScene.buildInitialScene();
    Assert.assertTrue(FroggerPlayer.isAtTarget(scene))

@Test
def testIsAtTargetWhenMoving(): Unit \ {Assert, Fs.FileRead} =
    // プレイヤーが移動中（pos != targetPos） → isAtTarget = false
    //   中央分離帯(y=448)から上ボタンを押した直後:
    //     pos = y=440 (まだ中間位置)
    //     targetPos = y=384 (亀レーン5)
    let scene = FroggerScene.buildInitialScene()
        |> SceneTree.setNodePosition(FroggerPlayer.playerName(), {x = 384.0f32, y = 440.0f32})
        |> SceneTree.updateCharacterBody(FroggerPlayer.playerName(), cbd ->
            {targetPos = {x = 384.0f32, y = 384.0f32} | cbd});
    Assert.assertFalse(FroggerPlayer.isAtTarget(scene))

@Test
def testNoDrownWhileMovingIntoWaterZone(): Unit \ {Assert, Fs.FileRead} =
    // 移動中(pos≠targetPos)に水域内にいても溺死しない
    //   pos = y=440 (水域内, 64 ≤ y < 448)
    //   targetPos = y=384 (まだ到達していない)
    //   丸太にも亀にも乗っていない
    //   → atTarget=false なので drown=false
    let scene = FroggerScene.buildInitialScene()
        |> SceneTree.setNodePosition(FroggerPlayer.playerName(), {x = 384.0f32, y = 440.0f32})
        |> SceneTree.updateCharacterBody(FroggerPlayer.playerName(), cbd ->
            {targetPos = {x = 384.0f32, y = 384.0f32} | cbd});
    let atTarget = FroggerPlayer.isAtTarget(scene);
    let inWater = SceneTree.globalPosition(FroggerPlayer.playerName(), scene)
        |> Option.map(pos -> WaterLane.isInWaterZone(pos#y))
        |> Option.getWithDefault(false);
    let onLog = not Option.isEmpty(WaterLane.findOverlappingLogVelocity(scene));
    let onTurtle = not Option.isEmpty(TurtleLane.findOverlappingTurtleVelocity(scene));
    // 水域内だが移動中 → 溺死しない
    let drown = (atTarget and inWater and not onLog and not onTurtle);
    Assert.assertEq(expected = (true, false, false, false, false), (inWater, atTarget, onLog, onTurtle, drown))

// ========================================================================
// Scene integration tests
// ========================================================================

@Test
def testInitialSceneContainsTurtleLanes(): Unit \ {Assert, Fs.FileRead} =
    match SceneTree.findNode("TurtleLanes", FroggerScene.buildInitialScene()) {
        case Some(container) => Assert.assertEq(expected = "TurtleLanes", SceneTree.nodeName(container))
        case None => bug!("TurtleLanes not found in initial scene")
    }

@Test
def testInitialSceneTurtleLaneHas2Lanes(): Unit \ {Assert, Fs.FileRead} =
    match SceneTree.findNode("TurtleLanes", FroggerScene.buildInitialScene()) {
        case Some(container) => Assert.assertEq(expected = 2,
            SceneTree.nodeChildren(container) |> List.length)
        case None => bug!("TurtleLanes not found in initial scene")
    }
