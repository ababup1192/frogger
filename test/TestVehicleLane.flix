// Tests for VehicleLane — lane construction, vehicle placement, wrapping, and movement

// ========================================================================
// Lane Config Tests
// ========================================================================

@Test
def testLaneConfigCount(): Unit \ Assert =
    Assert.assertEq(expected = 5, List.length(VehicleLane.laneConfigs()))

// ========================================================================
// Lane Y Position Tests
// ========================================================================

@Test
def testLaneY0(): Unit \ Assert =
    Assert.assertEq(expected = 512.0f32, VehicleLane.laneY(0))

@Test
def testLaneY1(): Unit \ Assert =
    Assert.assertEq(expected = 576.0f32, VehicleLane.laneY(1))

@Test
def testLaneY2(): Unit \ Assert =
    Assert.assertEq(expected = 640.0f32, VehicleLane.laneY(2))

@Test
def testLaneY3(): Unit \ Assert =
    Assert.assertEq(expected = 704.0f32, VehicleLane.laneY(3))

@Test
def testLaneY4(): Unit \ Assert =
    Assert.assertEq(expected = 768.0f32, VehicleLane.laneY(4))

// ========================================================================
// buildVehicleLanes structure tests
// ========================================================================

@Test
def testContainerName(): Unit \ Assert =
    Assert.assertEq(expected = "VehicleLanes",
        VehicleLane.buildVehicleLanes() |> SceneTree.nodeName)

@Test
def testLaneCount(): Unit \ Assert =
    Assert.assertEq(expected = 5,
        VehicleLane.buildVehicleLanes() |> SceneTree.nodeChildren |> List.length)

@Test
def testLane0VehicleCount(): Unit \ Assert =
    match SceneTree.findNode("VehicleLane0", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 3, List.length(SceneTree.nodeChildren(lane)))
        case None       => Assert.assertTrue(false)
    }

@Test
def testLane1VehicleCount(): Unit \ Assert =
    match SceneTree.findNode("VehicleLane1", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 4, List.length(SceneTree.nodeChildren(lane)))
        case None       => Assert.assertTrue(false)
    }

@Test
def testLane2VehicleCount(): Unit \ Assert =
    match SceneTree.findNode("VehicleLane2", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 2, List.length(SceneTree.nodeChildren(lane)))
        case None       => Assert.assertTrue(false)
    }

@Test
def testLane3VehicleCount(): Unit \ Assert =
    match SceneTree.findNode("VehicleLane3", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 4, List.length(SceneTree.nodeChildren(lane)))
        case None       => Assert.assertTrue(false)
    }

@Test
def testLane4VehicleCount(): Unit \ Assert =
    match SceneTree.findNode("VehicleLane4", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 2, List.length(SceneTree.nodeChildren(lane)))
        case None       => Assert.assertTrue(false)
    }

// ========================================================================
// Lane Y position in scene tree
// ========================================================================

@Test
def testLane0YPosition(): Unit \ Assert =
    match SceneTree.findNode("VehicleLane0", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 512.0f32, SceneTree.nodePosition(lane)#y)
        case None       => Assert.assertTrue(false)
    }

@Test
def testLane4YPosition(): Unit \ Assert =
    match SceneTree.findNode("VehicleLane4", VehicleLane.buildVehicleLanes()) {
        case Some(lane) => Assert.assertEq(expected = 768.0f32, SceneTree.nodePosition(lane)#y)
        case None       => Assert.assertTrue(false)
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
// initialX tests — cars distributed from the entry edge
// ========================================================================

@Test
def testInitialXLeftMovingVehicle0(): Unit \ Assert =
    // Left-moving: screenW(784) - spacing(100) * 0 = 784
    let cfg: VehicleLane.LaneConfig = {laneIndex = 0, speed = 200.0f32, direction = -1.0f32, texture = "Car1", vehicleCount = 3, spacing = 100.0f32};
    Assert.assertEq(expected = 784.0f32, VehicleLane.initialX(cfg, 0))

@Test
def testInitialXLeftMovingVehicle1(): Unit \ Assert =
    // Left-moving: 784 - 100 * 1 = 684
    let cfg: VehicleLane.LaneConfig = {laneIndex = 0, speed = 200.0f32, direction = -1.0f32, texture = "Car1", vehicleCount = 3, spacing = 100.0f32};
    Assert.assertEq(expected = 684.0f32, VehicleLane.initialX(cfg, 1))

@Test
def testInitialXRightMovingVehicle0(): Unit \ Assert =
    // Right-moving: spacing(150) * 0 = 0
    let cfg: VehicleLane.LaneConfig = {laneIndex = 1, speed = 250.0f32, direction = 1.0f32, texture = "Car2", vehicleCount = 4, spacing = 150.0f32};
    Assert.assertEq(expected = 0.0f32, VehicleLane.initialX(cfg, 0))

@Test
def testInitialXRightMovingVehicle1(): Unit \ Assert =
    // Right-moving: 150 * 1 = 150
    let cfg: VehicleLane.LaneConfig = {laneIndex = 1, speed = 250.0f32, direction = 1.0f32, texture = "Car2", vehicleCount = 4, spacing = 150.0f32};
    Assert.assertEq(expected = 150.0f32, VehicleLane.initialX(cfg, 1))

// ========================================================================
// stepAndCollide movement tests — engine physics moves Area2D by velocity
// ========================================================================

@Test
def testPhysicsMovesLeftward(): Unit \ Assert =
    // V0_0 はレーン0で左方向 (speed=200, direction=-1) なので、dt後に左に移動する
    let scene = SceneTree.node2D("Root", Vec2D.zero(), VehicleLane.buildVehicleLanes() :: Nil);
    match SceneTree.findNode("V0_0", scene) {
        case Some(v) =>
            let initX = SceneTree.nodePosition(v)#x;
            let moved = run {
                SceneTree.stepAndCollide(scene, 0.1f32, FroggerScene.physicsConfig())
            } with handler SceneTree.OnCollision {
                def bodyEntered(_name, _pos, _body, k) = k(())
                def areaEntered(_name, _pos, _body, k) = k(())
            };
            match SceneTree.findNode("V0_0", moved) {
                case Some(v2) => Assert.assertTrue(SceneTree.nodePosition(v2)#x < initX)
                case None     => Assert.assertTrue(false)
            }
        case None => Assert.assertTrue(false)
    }

@Test
def testPhysicsMovesRightward(): Unit \ Assert =
    // V1_0 はレーン1で右方向 (speed=250, direction=1) なので、dt後に右に移動する
    let scene = SceneTree.node2D("Root", Vec2D.zero(), VehicleLane.buildVehicleLanes() :: Nil);
    match SceneTree.findNode("V1_0", scene) {
        case Some(v) =>
            let initX = SceneTree.nodePosition(v)#x;
            let moved = run {
                SceneTree.stepAndCollide(scene, 0.1f32, FroggerScene.physicsConfig())
            } with handler SceneTree.OnCollision {
                def bodyEntered(_name, _pos, _body, k) = k(())
                def areaEntered(_name, _pos, _body, k) = k(())
            };
            match SceneTree.findNode("V1_0", moved) {
                case Some(v2) => Assert.assertTrue(SceneTree.nodePosition(v2)#x > initX)
                case None     => Assert.assertTrue(false)
            }
        case None => Assert.assertTrue(false)
    }

// ========================================================================
// Vehicle texture tests — Sprite is now a child of the Area2D vehicle node
// ========================================================================

@Test
def testLane0VehicleTexture(): Unit \ Assert =
    // V0_0 は Area2D で、子ノード "Sprite" にテクスチャがある
    match SceneTree.findNode("V0_0", VehicleLane.buildVehicleLanes()) {
        case Some(v) =>
            match SceneTree.findNode(VehicleLane.vehicleSpriteName(), v) {
                case Some(sprite) => match SceneTree.nodeKind(sprite) {
                    case SceneTree.NodeKind.Sprite(sd) => Assert.assertEq(expected = "Car1", sd#texture)
                    case _ => Assert.assertTrue(false)
                }
                case None => Assert.assertTrue(false)
            }
        case None => Assert.assertTrue(false)
    }

@Test
def testLane2VehicleTexture(): Unit \ Assert =
    match SceneTree.findNode("V2_0", VehicleLane.buildVehicleLanes()) {
        case Some(v) =>
            match SceneTree.findNode(VehicleLane.vehicleSpriteName(), v) {
                case Some(sprite) => match SceneTree.nodeKind(sprite) {
                    case SceneTree.NodeKind.Sprite(sd) => Assert.assertEq(expected = "Car3", sd#texture)
                    case _ => Assert.assertTrue(false)
                }
                case None => Assert.assertTrue(false)
            }
        case None => Assert.assertTrue(false)
    }

// ========================================================================
// Vehicle node kind test — vehicles are now Area2D
// ========================================================================

@Test
def testVehicleIsArea2D(): Unit \ Assert =
    match SceneTree.findNode("V0_0", VehicleLane.buildVehicleLanes()) {
        case Some(v) => match SceneTree.nodeKind(v) {
            case SceneTree.NodeKind.Area(_) => Assert.assertTrue(true)
            case _ => Assert.assertTrue(false)
        }
        case None => Assert.assertTrue(false)
    }

// ========================================================================
// Scene integration test
// ========================================================================

@Test
def testInitialSceneContainsVehicleLanes(): Unit \ Assert =
    match SceneTree.findNode("VehicleLanes", FroggerScene.buildInitialScene()) {
        case Some(container) => Assert.assertEq(expected = "VehicleLanes", SceneTree.nodeName(container))
        case None            => Assert.assertTrue(false)
    }
