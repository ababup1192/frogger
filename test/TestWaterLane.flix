// Tests for WaterLane — lane construction, log placement, wrapping, water zone, platform detection

// ========================================================================
// Lane Config Tests
// ========================================================================

@Test
def testLogLaneConfigCount(): Unit \ Assert =
    // 丸太レーンは4つ（レーン4-5はPhase7亀用に予約）
    Assert.assertEq(expected = 4, List.length(WaterLane.laneConfigs()))

// ========================================================================
// Lane Y Position Tests
// ========================================================================

@Test
def testLogLaneY0(): Unit \ Assert =
    // 水域レーン0は y=64（水域の先頭）
    Assert.assertEq(expected = 64.0f32, WaterLane.laneY(0))

@Test
def testLogLaneY1(): Unit \ Assert =
    Assert.assertEq(expected = 128.0f32, WaterLane.laneY(1))

@Test
def testLogLaneY2(): Unit \ Assert =
    Assert.assertEq(expected = 192.0f32, WaterLane.laneY(2))

@Test
def testLogLaneY3(): Unit \ Assert =
    Assert.assertEq(expected = 256.0f32, WaterLane.laneY(3))

// ========================================================================
// Log Size Tests
// ========================================================================

@Test
def testLogWidth0Segments(): Unit \ Assert =
    // segments=0: Start(64) + End(64) = 128
    Assert.assertEq(expected = 128.0f32, WaterLane.logWidth(0))

@Test
def testLogWidth1Segment(): Unit \ Assert =
    // segments=1: Start(64) + Middle(64) + End(64) = 192
    Assert.assertEq(expected = 192.0f32, WaterLane.logWidth(1))

@Test
def testLogWidth2Segments(): Unit \ Assert =
    // segments=2: Start(64) + Middle(128) + End(64) = 256
    Assert.assertEq(expected = 256.0f32, WaterLane.logWidth(2))

// ========================================================================
// buildWaterLanes structure tests
// ========================================================================

@Test
def testWaterLanesContainerName(): Unit \ Assert =
    Assert.assertEq(expected = "WaterLanes",
        WaterLane.buildWaterLanes() |> SceneTree.nodeName)

@Test
def testWaterLaneCount(): Unit \ Assert =
    // コンテナ直下に4つのレーンノード
    Assert.assertEq(expected = 4,
        WaterLane.buildWaterLanes() |> SceneTree.nodeChildren |> List.length)

@Test
def testWaterLane0LogCount(): Unit \ Assert =
    // レーン0は3本の丸太
    match SceneTree.findNode("WaterLane0", WaterLane.buildWaterLanes()) {
        case Some(lane) => Assert.assertEq(expected = 3, List.length(SceneTree.nodeChildren(lane)))
        case None => bug!("WaterLane0 not found")
    }

@Test
def testWaterLane1LogCount(): Unit \ Assert =
    // レーン1は2本の丸太
    match SceneTree.findNode("WaterLane1", WaterLane.buildWaterLanes()) {
        case Some(lane) => Assert.assertEq(expected = 2, List.length(SceneTree.nodeChildren(lane)))
        case None => bug!("WaterLane1 not found")
    }

@Test
def testWaterLane2LogCount(): Unit \ Assert =
    // レーン2は4本の丸太
    match SceneTree.findNode("WaterLane2", WaterLane.buildWaterLanes()) {
        case Some(lane) => Assert.assertEq(expected = 4, List.length(SceneTree.nodeChildren(lane)))
        case None => bug!("WaterLane2 not found")
    }

@Test
def testWaterLane3LogCount(): Unit \ Assert =
    // レーン3は3本の丸太
    match SceneTree.findNode("WaterLane3", WaterLane.buildWaterLanes()) {
        case Some(lane) => Assert.assertEq(expected = 3, List.length(SceneTree.nodeChildren(lane)))
        case None => bug!("WaterLane3 not found")
    }

// ========================================================================
// Lane Y position in scene tree
// ========================================================================

@Test
def testWaterLane0YPosition(): Unit \ Assert =
    match SceneTree.findNode("WaterLane0", WaterLane.buildWaterLanes()) {
        case Some(lane) => Assert.assertEq(expected = 64.0f32, SceneTree.nodePosition(lane)#y)
        case None => bug!("WaterLane0 not found")
    }

@Test
def testWaterLane3YPosition(): Unit \ Assert =
    match SceneTree.findNode("WaterLane3", WaterLane.buildWaterLanes()) {
        case Some(lane) => Assert.assertEq(expected = 256.0f32, SceneTree.nodePosition(lane)#y)
        case None => bug!("WaterLane3 not found")
    }

// ========================================================================
// Log node kind — logs are Area2D
// ========================================================================

@Test
def testLogIsArea2D(): Unit \ Assert =
    match SceneTree.findNode("L0_0", WaterLane.buildWaterLanes()) {
        case Some(logNode) => match SceneTree.nodeKind(logNode) {
            case SceneTree.NodeKind.Area(_) => Assert.assertTrue(true)
            case _ => bug!("L0_0 should be Area2D")
        }
        case None => bug!("L0_0 not found")
    }

// ========================================================================
// Log has collision shape
// ========================================================================

@Test
def testLogHasCollisionShape(): Unit \ Assert =
    match SceneTree.findNode("L0_0", WaterLane.buildWaterLanes()) {
        case Some(logNode) =>
            match SceneTree.findNode("Shape", logNode) {
                case Some(shape) => match SceneTree.nodeKind(shape) {
                    case SceneTree.NodeKind.Shape(_) => Assert.assertTrue(true)
                    case _ => bug!("Shape should be CollisionShape")
                }
                case None => bug!("Shape not found in log")
            }
        case None => bug!("L0_0 not found")
    }

// ========================================================================
// Log has start and end sprites
// ========================================================================

@Test
def testLogHasStartSprite(): Unit \ Assert =
    match SceneTree.findNode("L0_0", WaterLane.buildWaterLanes()) {
        case Some(logNode) =>
            match SceneTree.findNode("SpriteStart", logNode) {
                case Some(sprite) => match SceneTree.nodeKind(sprite) {
                    case SceneTree.NodeKind.Sprite(sd) => Assert.assertEq(expected = "LogStart", sd#texture)
                    case _ => bug!("SpriteStart should be Sprite")
                }
                case None => bug!("SpriteStart not found")
            }
        case None => bug!("L0_0 not found")
    }

@Test
def testLogHasEndSprite(): Unit \ Assert =
    match SceneTree.findNode("L0_0", WaterLane.buildWaterLanes()) {
        case Some(logNode) =>
            match SceneTree.findNode("SpriteEnd", logNode) {
                case Some(sprite) => match SceneTree.nodeKind(sprite) {
                    case SceneTree.NodeKind.Sprite(sd) => Assert.assertEq(expected = "LogEnd", sd#texture)
                    case _ => bug!("SpriteEnd should be Sprite")
                }
                case None => bug!("SpriteEnd not found")
            }
        case None => bug!("L0_0 not found")
    }

// ========================================================================
// Log naming tests
// ========================================================================

@Test
def testLogNaming(): Unit \ Assert =
    Assert.assertEq(expected = "L2_1", WaterLane.logName(2, 1))

@Test
def testLogNaming00(): Unit \ Assert =
    Assert.assertEq(expected = "L0_0", WaterLane.logName(0, 0))

// ========================================================================
// wrapX tests — direction-aware wrapping
// ========================================================================

@Test
def testLogWrapXLeftMovingPastLeft(): Unit \ Assert =
    //   ┌────────────────────┐
    //   │      screen        │ →ワープ先(右端)
    //   └────────────────────┘
    // ←丸太(消える)
    let segments = 1;
    let x = WaterLane.wrapMin(segments) - 1.0f32;
    Assert.assertEq(expected = WaterLane.wrapMax(), WaterLane.wrapX(x, -1.0f32, segments))

@Test
def testLogWrapXRightMovingPastRight(): Unit \ Assert =
    // ワープ先(左端)←
    //   ┌────────────────────┐
    //   │      screen        │
    //   └────────────────────┘  丸太→(消える)
    let segments = 1;
    let x = WaterLane.wrapMax() + 1.0f32;
    Assert.assertEq(expected = WaterLane.wrapMin(segments), WaterLane.wrapX(x, 1.0f32, segments))

@Test
def testLogWrapXInBounds(): Unit \ Assert =
    // 画面内 → ワープなし
    Assert.assertEq(expected = 300.0f32, WaterLane.wrapX(300.0f32, 1.0f32, 1))

@Test
def testLogWrapXLeftMovingInBounds(): Unit \ Assert =
    // 左方向でも画面内ならワープなし
    Assert.assertEq(expected = 400.0f32, WaterLane.wrapX(400.0f32, -1.0f32, 1))

// ========================================================================
// Water Zone Detection Tests
// ========================================================================

@Test
def testIsInWaterZoneAtTop(): Unit \ Assert =
    // y=64 は水域の先頭（水域内）
    Assert.assertTrue(WaterLane.isInWaterZone(64.0f32))

@Test
def testIsInWaterZoneInMiddle(): Unit \ Assert =
    // y=200 は水域の中間
    Assert.assertTrue(WaterLane.isInWaterZone(200.0f32))

@Test
def testNotInWaterZoneAtMedian(): Unit \ Assert =
    // y=448 は中間歩道（水域外）
    Assert.assertFalse(WaterLane.isInWaterZone(448.0f32))

@Test
def testNotInWaterZoneAtStart(): Unit \ Assert =
    // y=832 はスタート地点（水域外）
    Assert.assertFalse(WaterLane.isInWaterZone(832.0f32))

@Test
def testNotInWaterZoneAtHome(): Unit \ Assert =
    // y=0 はホームゾーン（水域外）
    Assert.assertFalse(WaterLane.isInWaterZone(0.0f32))

// ========================================================================
// Platform Overlap Detection Tests
// ========================================================================

@Test
def testNoOverlapAtStartPos(): Unit \ Assert =
    // スタート地点(y=832)ではどの丸太とも重ならない
    let scene = FroggerScene.buildInitialScene();
    Assert.assertTrue(Option.isEmpty(WaterLane.findOverlappingLogVelocity(scene)))

@Test
def testPlayerNotOffScreenAtStart(): Unit \ Assert =
    // スタート地点では画面外ではない
    Assert.assertFalse(WaterLane.isPlayerOffScreen(FroggerScene.buildInitialScene()))

// ========================================================================
// Physics movement tests — logs move via Area2D velocity
// ========================================================================

@Test
def testLogMovesRightward(): Unit \ Assert =
    // L0_0 はレーン0で右方向 (speed=120, direction=1) なので右に移動する
    let scene = SceneTree.node2D("Root", Vec2D.zero(), WaterLane.buildWaterLanes() :: Nil);
    match SceneTree.findNode("L0_0", scene) {
        case Some(logNode) =>
            let initX = SceneTree.nodePosition(logNode)#x;
            let moved = run {
                SceneTree.stepAndCollide(scene, 0.1f32, FroggerScene.physicsConfig())
            } with handler SceneTree.OnCollision {
                def bodyEntered(_name, _pos, _body, k) = k(())
                def areaEntered(_name, _pos, _body, k) = k(())
            };
            match SceneTree.findNode("L0_0", moved) {
                case Some(movedLog) => Assert.assertTrue(SceneTree.nodePosition(movedLog)#x > initX)
                case None => bug!("L0_0 not found after move")
            }
        case None => bug!("L0_0 not found")
    }

@Test
def testLogMovesLeftward(): Unit \ Assert =
    // L1_0 はレーン1で左方向 (speed=80, direction=-1) なので左に移動する
    let scene = SceneTree.node2D("Root", Vec2D.zero(), WaterLane.buildWaterLanes() :: Nil);
    match SceneTree.findNode("L1_0", scene) {
        case Some(logNode) =>
            let initX = SceneTree.nodePosition(logNode)#x;
            let moved = run {
                SceneTree.stepAndCollide(scene, 0.1f32, FroggerScene.physicsConfig())
            } with handler SceneTree.OnCollision {
                def bodyEntered(_name, _pos, _body, k) = k(())
                def areaEntered(_name, _pos, _body, k) = k(())
            };
            match SceneTree.findNode("L1_0", moved) {
                case Some(movedLog) => Assert.assertTrue(SceneTree.nodePosition(movedLog)#x < initX)
                case None => bug!("L1_0 not found after move")
            }
        case None => bug!("L1_0 not found")
    }

// ========================================================================
// shouldDrown tests
// ========================================================================

@Test
def testShouldNotDrownAtStart(): Unit \ Assert =
    // スタート地点(y=832)は水域外なので溺死しない
    Assert.assertFalse(WaterLane.shouldDrown(FroggerScene.buildInitialScene()))

@Test
def testShouldDrownInWaterWithoutLog(): Unit \ Assert =
    // 水域内(y=100)かつ丸太に乗っていない → 溺死する
    //   ┌────────────────────┐
    //   │  water zone        │  ←プレイヤーがここに浮いている（丸太なし）
    //   └────────────────────┘
    let scene = FroggerScene.buildInitialScene()
        |> SceneTree.setNodePosition(FroggerPlayer.playerName(), {x = 50.0f32, y = 100.0f32});
    Assert.assertTrue(WaterLane.shouldDrown(scene))

@Test
def testShouldNotDrownOnMedian(): Unit \ Assert =
    // 中間歩道(y=448)は水域外なので溺死しない
    let scene = FroggerScene.buildInitialScene()
        |> SceneTree.setNodePosition(FroggerPlayer.playerName(), {x = 384.0f32, y = 448.0f32});
    Assert.assertFalse(WaterLane.shouldDrown(scene))

@Test
def testShouldDrownOffScreenLeft(): Unit \ Assert =
    // 画面外（左端を超過）→ 溺死する
    let scene = FroggerScene.buildInitialScene()
        |> SceneTree.setNodePosition(FroggerPlayer.playerName(), {x = -50.0f32, y = 100.0f32});
    Assert.assertTrue(WaterLane.shouldDrown(scene))

@Test
def testShouldDrownOffScreenRight(): Unit \ Assert =
    // 画面外（右端を超過）→ 溺死する
    let scene = FroggerScene.buildInitialScene()
        |> SceneTree.setNodePosition(FroggerPlayer.playerName(), {x = 850.0f32, y = 100.0f32});
    Assert.assertTrue(WaterLane.shouldDrown(scene))

// ========================================================================
// Scene integration tests
// ========================================================================

@Test
def testInitialSceneContainsWaterLanes(): Unit \ Assert =
    match SceneTree.findNode("WaterLanes", FroggerScene.buildInitialScene()) {
        case Some(container) => Assert.assertEq(expected = "WaterLanes", SceneTree.nodeName(container))
        case None => bug!("WaterLanes not found in initial scene")
    }

@Test
def testInitialSceneWaterLaneHas4Lanes(): Unit \ Assert =
    match SceneTree.findNode("WaterLanes", FroggerScene.buildInitialScene()) {
        case Some(container) => Assert.assertEq(expected = 4,
            SceneTree.nodeChildren(container) |> List.length)
        case None => bug!("WaterLanes not found in initial scene")
    }
