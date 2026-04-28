// Tests for VehicleLane — lane construction, vehicle placement, wrapping, and movement

// ========================================================================
// Lane Config Tests — laneConfigs() は純粋関数
// ========================================================================

@Test
def testLaneConfigCount(): Unit \ Assert =
    // 5レーン分の設定が定義されている
    Assert.assertEq(expected = 5, List.length(VehicleLane.laneConfigs()))

// ========================================================================
// laneY Tests — road zone starts at 512, each lane is 64px tall
// ========================================================================

@Test
def testLaneY0(): Unit \ Assert =
    // レーン0は y=512
    Assert.assertEq(expected = 512.0f32, VehicleLane.laneY(0))

@Test
def testLaneY4(): Unit \ Assert =
    // レーン4は y=768（512 + 4*64）
    Assert.assertEq(expected = 768.0f32, VehicleLane.laneY(4))

// ========================================================================
// initialX Tests — direction に応じた初期配置
// ========================================================================

@Test
def testInitialXLeftMoving(): Unit \ Assert =
    // 左方向レーン: screenW(784) から spacing 分ずつ左へ
    let cfg = List.head(VehicleLane.laneConfigs());
    match cfg {
        case Some(c) =>
            Assert.assertEq(expected = (784.0f32, 684.0f32),
                (VehicleLane.initialX(c, 0), VehicleLane.initialX(c, 1)))
        case None => bug!("laneConfigs is empty")
    }

@Test
def testInitialXRightMoving(): Unit \ Assert =
    // 右方向レーン: 0 から spacing 分ずつ右へ
    let cfg = List.head(List.drop(1, VehicleLane.laneConfigs()));
    match cfg {
        case Some(c) =>
            Assert.assertEq(expected = (0.0f32, 150.0f32),
                (VehicleLane.initialX(c, 0), VehicleLane.initialX(c, 1)))
        case None => bug!("laneConfigs has fewer than 2 entries")
    }

// ========================================================================
// buildVehicleLanes structure tests — Vehicle テンプレート読込あり
// ========================================================================

@Test
def testContainerName(): Unit \ {Assert, Fs.FileRead} =
    // コンテナノード名は "VehicleLanes"
    Assert.assertEq(expected = "VehicleLanes",
        VehicleLane.buildVehicleLanes() |> SceneTree.nodeName)

@Test
def testLaneCount(): Unit \ {Assert, Fs.FileRead} =
    // 5レーン分の子ノードが構築される
    Assert.assertEq(expected = 5,
        VehicleLane.buildVehicleLanes() |> SceneTree.nodeChildren |> List.length)

@Test
def testLane0VehicleCount(): Unit \ {Assert, Fs.FileRead} =
    // レーン0は車両3台
    match SceneTree.findNode("VehicleLane0", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 3, List.length(SceneTree.nodeChildren(lane)))
        case None       => bug!("VehicleLane0 not found")
    }

@Test
def testLane1VehicleCount(): Unit \ {Assert, Fs.FileRead} =
    // レーン1は車両4台
    match SceneTree.findNode("VehicleLane1", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 4, List.length(SceneTree.nodeChildren(lane)))
        case None       => bug!("VehicleLane1 not found")
    }

@Test
def testLane2VehicleCount(): Unit \ {Assert, Fs.FileRead} =
    // レーン2は車両2台
    match SceneTree.findNode("VehicleLane2", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 2, List.length(SceneTree.nodeChildren(lane)))
        case None       => bug!("VehicleLane2 not found")
    }

@Test
def testLane3VehicleCount(): Unit \ {Assert, Fs.FileRead} =
    // レーン3は車両4台
    match SceneTree.findNode("VehicleLane3", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 4, List.length(SceneTree.nodeChildren(lane)))
        case None       => bug!("VehicleLane3 not found")
    }

@Test
def testLane4VehicleCount(): Unit \ {Assert, Fs.FileRead} =
    // レーン4は車両2台
    match SceneTree.findNode("VehicleLane4", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 2, List.length(SceneTree.nodeChildren(lane)))
        case None       => bug!("VehicleLane4 not found")
    }

// ========================================================================
// Lane Y position in scene tree
// ========================================================================

@Test
def testLane0YPosition(): Unit \ {Assert, Fs.FileRead} =
    // レーン0の Y 座標は 512
    match SceneTree.findNode("VehicleLane0", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 512.0f32, SceneTree.nodePosition(lane)#y)
        case None       => bug!("VehicleLane0 not found")
    }

@Test
def testLane4YPosition(): Unit \ {Assert, Fs.FileRead} =
    // レーン4の Y 座標は 768
    match SceneTree.findNode("VehicleLane4", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 768.0f32, SceneTree.nodePosition(lane)#y)
        case None       => bug!("VehicleLane4 not found")
    }

// ========================================================================
// wrapX tests — direction-aware wrapping
// ========================================================================

@Test
def testWrapXLeftMovingPastLeft(): Unit \ Assert =
    // Left-moving car goes past wrapMin(-100) → wraps to wrapMax(884)
    Assert.assertEq(expected = 884.0f32, VehicleLane.wrapX(-110.0f32, -1.0f32))

@Test
def testWrapXLeftMovingInBounds(): Unit \ Assert =
    // Left-moving car still on screen → no wrap
    Assert.assertEq(expected = 300.0f32, VehicleLane.wrapX(300.0f32, -1.0f32))

@Test
def testWrapXRightMovingPastRight(): Unit \ Assert =
    // Right-moving car goes past wrapMax(884) → wraps to wrapMin(-100)
    Assert.assertEq(expected = -100.0f32, VehicleLane.wrapX(890.0f32, 1.0f32))

@Test
def testWrapXRightMovingInBounds(): Unit \ Assert =
    // Right-moving car still on screen → no wrap
    Assert.assertEq(expected = 400.0f32, VehicleLane.wrapX(400.0f32, 1.0f32))

// ========================================================================
// stepAndCollide movement tests — engine physics moves Area2D by velocity
// ========================================================================

@Test
def testPhysicsMovesLeftward(): Unit \ {Assert, Fs.FileRead} =
    // V0_0 はレーン0で左方向 (speed=200, direction=-1) なので、dt後に左に移動する
    let scene = SceneTree.node2D("Root", Vec2D.zero(), VehicleLane.buildVehicleLanes() :: Nil);
    match SceneTree.findNode("V0_0", scene) {
        case Some(v) =>
            let initX = SceneTree.nodePosition(v)#x;
            let moved = SceneTree.runWithNoopCollision(() ->
                SceneTree.stepAndCollide(scene, 0.1f32, FroggerScene.physicsConfig()));
            match SceneTree.findNode("V0_0", moved) {
                case Some(v2) => Assert.assertTrue(SceneTree.nodePosition(v2)#x < initX)
                case None     => bug!("V0_0 not found after step")
            }
        case None => bug!("V0_0 not found")
    }

@Test
def testPhysicsMovesRightward(): Unit \ {Assert, Fs.FileRead} =
    // V1_0 はレーン1で右方向 (speed=250, direction=1) なので、dt後に右に移動する
    let scene = SceneTree.node2D("Root", Vec2D.zero(), VehicleLane.buildVehicleLanes() :: Nil);
    match SceneTree.findNode("V1_0", scene) {
        case Some(v) =>
            let initX = SceneTree.nodePosition(v)#x;
            let moved = SceneTree.runWithNoopCollision(() ->
                SceneTree.stepAndCollide(scene, 0.1f32, FroggerScene.physicsConfig()));
            match SceneTree.findNode("V1_0", moved) {
                case Some(v2) => Assert.assertTrue(SceneTree.nodePosition(v2)#x > initX)
                case None     => bug!("V1_0 not found after step")
            }
        case None => bug!("V1_0 not found")
    }

// ========================================================================
// Vehicle texture tests — Sprite is a child of the Area2D vehicle node
// ========================================================================

@Test
def testLane0VehicleTexture(): Unit \ {Assert, Fs.FileRead} =
    // V0_0 の子 Sprite に Car1 テクスチャが設定されている
    match SceneTree.findNode("V0_0", VehicleLane.buildVehicleLanes()) {
        case Some(v) =>
            match SceneTree.findNode("Sprite", v) {
                case Some(sprite) => match SceneTree.nodeKind(sprite) {
                    case SceneTree.NodeKind.Sprite(sd) => Assert.assertEq(expected = "Car1", sd#texture)
                    case _ => bug!("Sprite node is not Sprite2D")
                }
                case None => bug!("Sprite not found in V0_0")
            }
        case None => bug!("V0_0 not found")
    }

@Test
def testLane2VehicleTexture(): Unit \ {Assert, Fs.FileRead} =
    // V2_0 の子 Sprite に Car3 テクスチャが設定されている
    match SceneTree.findNode("V2_0", VehicleLane.buildVehicleLanes()) {
        case Some(v) =>
            match SceneTree.findNode("Sprite", v) {
                case Some(sprite) => match SceneTree.nodeKind(sprite) {
                    case SceneTree.NodeKind.Sprite(sd) => Assert.assertEq(expected = "Car3", sd#texture)
                    case _ => bug!("Sprite node is not Sprite2D")
                }
                case None => bug!("Sprite not found in V2_0")
            }
        case None => bug!("V2_0 not found")
    }

// ========================================================================
// Vehicle node kind test — vehicles are Area2D
// ========================================================================

@Test
def testVehicleIsArea2D(): Unit \ {Assert, Fs.FileRead} =
    // V0_0 は Area2D ノードとして構築される
    match SceneTree.findNode("V0_0", VehicleLane.buildVehicleLanes()) {
        case Some(v) => match SceneTree.nodeKind(v) {
            case SceneTree.NodeKind.Area(_) => Assert.assertTrue(true)
            case _ => bug!("V0_0 is not Area2D")
        }
        case None => bug!("V0_0 not found")
    }

// ========================================================================
// Scene integration test
// ========================================================================

@Test
def testInitialSceneContainsVehicleLanes(): Unit \ {Assert, Fs.FileRead} =
    // FroggerScene にも VehicleLanes コンテナが含まれる
    match SceneTree.findNode("VehicleLanes", FroggerScene.buildInitialScene()) {
        case Some(container) => Assert.assertEq(expected = "VehicleLanes", SceneTree.nodeName(container))
        case None            => bug!("VehicleLanes not found in initial scene")
    }
