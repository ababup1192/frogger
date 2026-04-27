// Tests for FroggerPlayer — sprite, movement, and input

// ========================================================================
// Sprite Tests
// ========================================================================

@Test
def testPlayerIsNode2D(): Unit \ Assert =
    let player = FroggerPlayer.buildPlayer();
    match SceneTree.nodeKind(player) {
        case SceneTree.NodeKind.Plain => Assert.assertTrue(true)
        case _ => Assert.assertTrue(false)
    }

@Test
def testPlayerName(): Unit \ Assert =
    let player = FroggerPlayer.buildPlayer();
    Assert.assertEq(expected = "Player", SceneTree.nodeName(player))

@Test
def testPlayerPosition(): Unit \ Assert =
    let player = FroggerPlayer.buildPlayer();
    let pos = SceneTree.nodePosition(player);
    Assert.assertEq(expected = 384.0f32, pos#x);
    Assert.assertEq(expected = 832.0f32, pos#y)

@Test
def testPlayerSpriteChildName(): Unit \ Assert =
    let player = FroggerPlayer.buildPlayer();
    match SceneTree.findNode("Sprite", player) {
        case Some(sprite) => Assert.assertEq(expected = "Sprite", SceneTree.nodeName(sprite))
        case None         => Assert.assertTrue(false)
    }

@Test
def testPlayerSpriteTexture(): Unit \ Assert =
    let player = FroggerPlayer.buildPlayer();
    match SceneTree.findNode("Sprite", player) {
        case Some(sprite) => match SceneTree.nodeKind(sprite) {
            case SceneTree.NodeKind.Sprite(sd) =>
                Assert.assertEq(expected = "FroggerIdle", sd#texture)
            case _ => Assert.assertTrue(false)
        }
        case None => Assert.assertTrue(false)
    }

@Test
def testPlayerSpriteSize(): Unit \ Assert =
    let player = FroggerPlayer.buildPlayer();
    match SceneTree.findNode("Sprite", player) {
        case Some(sprite) => match SceneTree.nodeKind(sprite) {
            case SceneTree.NodeKind.Sprite(sd) =>
                Assert.assertEq(expected = 64.0f32, sd#size#x);
                Assert.assertEq(expected = 64.0f32, sd#size#y)
            case _ => Assert.assertTrue(false)
        }
        case None => Assert.assertTrue(false)
    }

// ========================================================================
// computeNewTarget Tests
// ========================================================================

@Test
def testComputeNewTargetMoveUp(): Unit \ Assert =
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Up, {x = 384.0f32, y = 832.0f32});
    Assert.assertEq(expected = 384.0f32, result#x);
    Assert.assertEq(expected = 768.0f32, result#y)

@Test
def testComputeNewTargetMoveDown(): Unit \ Assert =
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Down, {x = 384.0f32, y = 768.0f32});
    Assert.assertEq(expected = 384.0f32, result#x);
    Assert.assertEq(expected = 832.0f32, result#y)

@Test
def testComputeNewTargetMoveLeft(): Unit \ Assert =
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Left, {x = 384.0f32, y = 832.0f32});
    Assert.assertEq(expected = 320.0f32, result#x);
    Assert.assertEq(expected = 832.0f32, result#y)

@Test
def testComputeNewTargetMoveRight(): Unit \ Assert =
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Right, {x = 384.0f32, y = 832.0f32});
    Assert.assertEq(expected = 448.0f32, result#x);
    Assert.assertEq(expected = 832.0f32, result#y)

@Test
def testComputeNewTargetClampTop(): Unit \ Assert =
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Up, {x = 384.0f32, y = 0.0f32});
    Assert.assertEq(expected = 0.0f32, result#y)

@Test
def testComputeNewTargetClampBottom(): Unit \ Assert =
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Down, {x = 384.0f32, y = 832.0f32});
    Assert.assertEq(expected = 832.0f32, result#y)

@Test
def testComputeNewTargetClampLeft(): Unit \ Assert =
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Left, {x = 0.0f32, y = 384.0f32});
    Assert.assertEq(expected = 0.0f32, result#x)

@Test
def testComputeNewTargetClampRight(): Unit \ Assert =
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Right, {x = 720.0f32, y = 384.0f32});
    Assert.assertEq(expected = 720.0f32, result#x)

// ========================================================================
// stepPlayer Tests
// ========================================================================

@Test
def testStepPlayerLerpIntermediate(): Unit \ Assert =
    let player = FroggerPlayer.buildPlayer();
    let scene = SceneTree.node2D("Root", Vec2D.zero(), player :: Nil);
    let target = {x = 384.0f32, y = 768.0f32};
    // delta = 512 * 0.0625 = 32, distance = 64, so moves halfway
    let dt = 0.0625f32;
    let newScene = FroggerPlayer.stepPlayer(dt, target, scene);
    match SceneTree.globalPosition("Player", newScene) {
        case Some(pos) =>
            Assert.assertEq(expected = 384.0f32, pos#x);
            Assert.assertEq(expected = 800.0f32, pos#y)
        case None => Assert.assertTrue(false)
    }

@Test
def testStepPlayerArrival(): Unit \ Assert =
    let player = FroggerPlayer.buildPlayer();
    let scene = SceneTree.node2D("Root", Vec2D.zero(), player :: Nil);
    let target = {x = 384.0f32, y = 768.0f32};
    // delta = 512 * 1.0 = 512, distance = 64, player reaches target
    let dt = 1.0f32;
    let newScene = FroggerPlayer.stepPlayer(dt, target, scene);
    match SceneTree.globalPosition("Player", newScene) {
        case Some(pos) =>
            Assert.assertEq(expected = 384.0f32, pos#x);
            Assert.assertEq(expected = 768.0f32, pos#y)
        case None => Assert.assertTrue(false)
    }

// ========================================================================
// Scene Integration Tests
// ========================================================================

@Test
def testInitialSceneContainsPlayer(): Unit \ Assert =
    let scene = FroggerScene.buildInitialScene();
    match SceneTree.findNode("Player", scene) {
        case Some(player) => Assert.assertEq(expected = "Player", SceneTree.nodeName(player))
        case None         => Assert.assertTrue(false)
    }

@Test
def testInitialSceneContainsPlayerTarget(): Unit \ Assert =
    let scene = FroggerScene.buildInitialScene();
    match SceneTree.findNode("PlayerTarget", scene) {
        case Some(node) => Assert.assertEq(expected = "PlayerTarget", SceneTree.nodeName(node))
        case None       => Assert.assertTrue(false)
    }

// ========================================================================
// justPressedKeys Tests (Game module)
// ========================================================================

@Test
def testJustPressedDetectsNewKey(): Unit \ Assert =
    let curr = Set.insert(Engine.Key.W, Set.empty());
    let prev = Set.empty();
    let result = Game.justPressedKeys(curr, prev);
    Assert.assertTrue(Set.memberOf(Engine.Key.W, result))

@Test
def testJustPressedIgnoresHeldKey(): Unit \ Assert =
    let curr = Set.insert(Engine.Key.W, Set.empty());
    let prev = Set.insert(Engine.Key.W, Set.empty());
    let result = Game.justPressedKeys(curr, prev);
    Assert.assertTrue(Set.isEmpty(result))

@Test
def testJustPressedIgnoresReleasedKey(): Unit \ Assert =
    let curr = Set.empty();
    let prev = Set.insert(Engine.Key.W, Set.empty());
    let result = Game.justPressedKeys(curr, prev);
    Assert.assertTrue(Set.isEmpty(result))

// ========================================================================
// inputDirection Tests (Game module)
// ========================================================================

@Test
def testInputDirectionW(): Unit \ Assert =
    let pressed = Set.insert(Engine.Key.W, Set.empty());
    Assert.assertEq(expected = Some(SceneTree.Direction.Up), Game.inputDirection(pressed))

@Test
def testInputDirectionUp(): Unit \ Assert =
    let pressed = Set.insert(Engine.Key.Up, Set.empty());
    Assert.assertEq(expected = Some(SceneTree.Direction.Up), Game.inputDirection(pressed))

@Test
def testInputDirectionS(): Unit \ Assert =
    let pressed = Set.insert(Engine.Key.S, Set.empty());
    Assert.assertEq(expected = Some(SceneTree.Direction.Down), Game.inputDirection(pressed))

@Test
def testInputDirectionDown(): Unit \ Assert =
    let pressed = Set.insert(Engine.Key.Down, Set.empty());
    Assert.assertEq(expected = Some(SceneTree.Direction.Down), Game.inputDirection(pressed))

@Test
def testInputDirectionA(): Unit \ Assert =
    let pressed = Set.insert(Engine.Key.A, Set.empty());
    Assert.assertEq(expected = Some(SceneTree.Direction.Left), Game.inputDirection(pressed))

@Test
def testInputDirectionLeft(): Unit \ Assert =
    let pressed = Set.insert(Engine.Key.Left, Set.empty());
    Assert.assertEq(expected = Some(SceneTree.Direction.Left), Game.inputDirection(pressed))

@Test
def testInputDirectionD(): Unit \ Assert =
    let pressed = Set.insert(Engine.Key.D, Set.empty());
    Assert.assertEq(expected = Some(SceneTree.Direction.Right), Game.inputDirection(pressed))

@Test
def testInputDirectionRight(): Unit \ Assert =
    let pressed = Set.insert(Engine.Key.Right, Set.empty());
    Assert.assertEq(expected = Some(SceneTree.Direction.Right), Game.inputDirection(pressed))

@Test
def testInputDirectionEmpty(): Unit \ Assert =
    let dir: Option[SceneTree.Direction] = Game.inputDirection(Set.empty());
    Assert.assertEq(expected = (None: Option[SceneTree.Direction]), dir)

@Test
def testInputDirectionPriorityUpOverDown(): Unit \ Assert =
    let pressed = Set.insert(Engine.Key.W, Set.insert(Engine.Key.S, Set.empty()));
    Assert.assertEq(expected = Some(SceneTree.Direction.Up), Game.inputDirection(pressed))

@Test
def testInputDirectionPriorityUpOverRight(): Unit \ Assert =
    let pressed = Set.insert(Engine.Key.W, Set.insert(Engine.Key.D, Set.empty()));
    Assert.assertEq(expected = Some(SceneTree.Direction.Up), Game.inputDirection(pressed))
