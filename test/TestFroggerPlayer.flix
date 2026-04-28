// Tests for FroggerPlayer — sprite, movement, and input

// ========================================================================
// Scene Loading — scene.jsonの全パラメータが正しくNodeに変換されるか一括検証
// ========================================================================

@Test
def testBuildPlayerMatchesJson(): Unit \ {Assert, Fs.FileRead} =
    let player = FroggerPlayer.buildPlayer();
    let pos = SceneTree.nodePosition(player);
    let result = forM (
        cbd    <- SceneTree.characterBodyData(player);
        asd    <- SceneTree.findAnimatedSpriteData(SceneTree.childName(FroggerPlayer.Child.Sprite), player);
        hitbox <- SceneTree.findNode(SceneTree.childName(FroggerPlayer.Child.Hitbox), player);
        shape  <- SceneTree.findRectShape(SceneTree.nodeChildren(hitbox))
    ) yield {
        // Root: CharacterBody2D "Player" at startPos, moveSpeed=512
        Assert.assertEq(expected = "Player", SceneTree.nodeName(player));
        Assert.assertEq(expected = FroggerPlayer.startPos()#x, pos#x);
        Assert.assertEq(expected = FroggerPlayer.startPos()#y, pos#y);
        Assert.assertEq(expected = 512.0f32, cbd#moveSpeed);
        Assert.assertEq(expected = pos#x, cbd#targetPos#x);
        Assert.assertEq(expected = pos#y, cbd#targetPos#y);
        // Sprite: size=(64,64), initialAnimation="idle", fps=4
        Assert.assertEq(expected = 64.0f32, asd#size#x);
        Assert.assertEq(expected = 64.0f32, asd#size#y);
        Assert.assertEq(expected = "idle", asd#currentAnimation);
        Assert.assertEq(expected = 4.0f32, asd#fps);
        // Hitbox: pos=(16,20), Shape: size=(32,24)
        let hpos = SceneTree.nodePosition(hitbox);
        Assert.assertEq(expected = 16.0f32, hpos#x);
        Assert.assertEq(expected = 20.0f32, hpos#y);
        Assert.assertEq(expected = 32.0f32, shape#x);
        Assert.assertEq(expected = 24.0f32, shape#y)
    };
    match result {
        case Some(_) => ()
        case None    => bug!("Player node structure does not match expected JSON layout")
    }

// ========================================================================
// computeNewTarget Tests
// ========================================================================

@Test
def testComputeNewTargetMoveUp(): Unit \ {Assert, Fs.FileRead} =
    let config = FroggerPlayer.loadConfig(FroggerScene.buildInitialScene());
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Up, {x = 384.0f32, y = 832.0f32}, config);
    Assert.assertEq(expected = 384.0f32, result#x);
    Assert.assertEq(expected = 768.0f32, result#y)

@Test
def testComputeNewTargetMoveDown(): Unit \ {Assert, Fs.FileRead} =
    let config = FroggerPlayer.loadConfig(FroggerScene.buildInitialScene());
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Down, {x = 384.0f32, y = 768.0f32}, config);
    Assert.assertEq(expected = 384.0f32, result#x);
    Assert.assertEq(expected = 832.0f32, result#y)

@Test
def testComputeNewTargetMoveLeft(): Unit \ {Assert, Fs.FileRead} =
    let config = FroggerPlayer.loadConfig(FroggerScene.buildInitialScene());
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Left, {x = 384.0f32, y = 832.0f32}, config);
    Assert.assertEq(expected = 320.0f32, result#x);
    Assert.assertEq(expected = 832.0f32, result#y)

@Test
def testComputeNewTargetMoveRight(): Unit \ {Assert, Fs.FileRead} =
    let config = FroggerPlayer.loadConfig(FroggerScene.buildInitialScene());
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Right, {x = 384.0f32, y = 832.0f32}, config);
    Assert.assertEq(expected = 448.0f32, result#x);
    Assert.assertEq(expected = 832.0f32, result#y)

@Test
def testComputeNewTargetClampTop(): Unit \ {Assert, Fs.FileRead} =
    let config = FroggerPlayer.loadConfig(FroggerScene.buildInitialScene());
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Up, {x = 384.0f32, y = 0.0f32}, config);
    Assert.assertEq(expected = 0.0f32, result#y)

@Test
def testComputeNewTargetClampBottom(): Unit \ {Assert, Fs.FileRead} =
    let config = FroggerPlayer.loadConfig(FroggerScene.buildInitialScene());
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Down, {x = 384.0f32, y = 832.0f32}, config);
    Assert.assertEq(expected = 832.0f32, result#y)

@Test
def testComputeNewTargetClampLeft(): Unit \ {Assert, Fs.FileRead} =
    let config = FroggerPlayer.loadConfig(FroggerScene.buildInitialScene());
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Left, {x = 0.0f32, y = 384.0f32}, config);
    Assert.assertEq(expected = 0.0f32, result#x)

@Test
def testComputeNewTargetClampRight(): Unit \ {Assert, Fs.FileRead} =
    let config = FroggerPlayer.loadConfig(FroggerScene.buildInitialScene());
    let result = FroggerPlayer.computeNewTarget(SceneTree.Direction.Right, {x = 720.0f32, y = 384.0f32}, config);
    Assert.assertEq(expected = 720.0f32, result#x)

// ========================================================================
// stepFrame Tests
// ========================================================================

@Test
def testStepFrameLerpIntermediate(): Unit \ {Assert, Fs.FileRead} =
    let player = FroggerPlayer.buildPlayer();
    let scene = SceneTree.node2D("Root", Vec2D.zero(), player :: Nil);
    // Move target up by one cell (64px) via applyInput
    let sceneWithTarget = FroggerPlayer.applyInput(SceneTree.Direction.Up, scene);
    // delta = 512 * 0.0625 = 32, distance = 64, so moves halfway
    let dt = 0.0625f32;
    let newScene = FroggerPlayer.stepFrame(dt, sceneWithTarget);
    match SceneTree.globalPosition("Player", newScene) {
        case Some(pos) =>
            Assert.assertEq(expected = 384.0f32, pos#x);
            Assert.assertEq(expected = 800.0f32, pos#y)
        case None => Assert.assertTrue(false)
    }

@Test
def testStepFrameArrival(): Unit \ {Assert, Fs.FileRead} =
    let player = FroggerPlayer.buildPlayer();
    let scene = SceneTree.node2D("Root", Vec2D.zero(), player :: Nil);
    // Move target up by one cell (64px) via applyInput
    let sceneWithTarget = FroggerPlayer.applyInput(SceneTree.Direction.Up, scene);
    // delta = 512 * 1.0 = 512, distance = 64, player reaches target
    let dt = 1.0f32;
    let newScene = FroggerPlayer.stepFrame(dt, sceneWithTarget);
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
def testInitialSceneContainsPlayer(): Unit \ {Assert, Fs.FileRead} =
    let scene = FroggerScene.buildInitialScene();
    match SceneTree.findNode("Player", scene) {
        case Some(player) => Assert.assertEq(expected = "Player", SceneTree.nodeName(player))
        case None         => Assert.assertTrue(false)
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
