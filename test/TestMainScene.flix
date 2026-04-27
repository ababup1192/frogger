// Tests for MainScene — game flow

// ========================================================================
// buildInitialScene
// ========================================================================

@Test
def testMainSceneHasTimers(): Unit \ Assert =
    let scene = MainScene.buildInitialScene();
    Assert.assertTrue(not Option.isEmpty(SceneTree.findNode(SceneTree.childName(MainScene.Child.MobTimer), scene)));
    Assert.assertTrue(not Option.isEmpty(SceneTree.findNode(SceneTree.childName(MainScene.Child.ScoreTimer), scene)));
    Assert.assertTrue(not Option.isEmpty(SceneTree.findNode(SceneTree.childName(MainScene.Child.StartTimer), scene)))

@Test
def testMainSceneHasStartPosition(): Unit \ Assert =
    let scene = MainScene.buildInitialScene();
    Assert.assertTrue(not Option.isEmpty(SceneTree.findNode(SceneTree.childName(MainScene.Child.StartPosition), scene)))

@Test
def testMainSceneHasMobs(): Unit \ Assert =
    let scene = MainScene.buildInitialScene();
    Assert.assertTrue(not Option.isEmpty(SceneTree.findNode(SceneTree.childName(MainScene.Child.Mobs), scene)))

// ========================================================================
// isReadyToStart
// ========================================================================

@Test
def testIsReadyToStartInitial(): Unit \ Assert =
    let scene = MainScene.buildInitialScene();
    Assert.assertTrue(MainScene.isReadyToStart(scene))

@Test
def testIsReadyToStartAfterNewGame(): Unit \ Assert =
    let state = Game.initGame(0, 0);
    let active = silentAudio(() -> MainScene.newGame(state));
    Assert.assertFalse(MainScene.isReadyToStart(active#scene))

// ========================================================================
// buildInitialScene — player hidden
// ========================================================================

@Test
def testBuildInitialScenePlayerHidden(): Unit \ Assert =
    let scene = MainScene.buildInitialScene();
    match SceneTree.findNode(PlayerScene.playerName(), scene) {
        case Some(node) =>
            let children = SceneTree.nodeChildren(node);
            let spriteVisible = List.findMap(child -> match SceneTree.nodeKind(child) {
                case SceneTree.NodeKind.AnimatedSprite(asd) => Some(asd#visible)
                case _ => None
            }, children);
            match spriteVisible {
                case Some(v) => Assert.assertFalse(v)
                case None => Assert.assertTrue(false)
            }
        case None => Assert.assertTrue(false)
    }

// ========================================================================
// newGame
// ========================================================================

def silentAudio(f: Unit -> a \ Engine.Audio): a =
    run { f() }
    with handler Engine.Audio {
        def playAudio(_name, k) = k(())
        def stopAudio(_name, k) = k(())
    }

@Test
def testNewGameScoreZero(): Unit \ Assert =
    let state = Game.initGame(0, 0);
    let active = silentAudio(() -> MainScene.newGame(state));
    Assert.assertEq(expected = 0, active#score)

@Test
def testNewGamePlayerPosition(): Unit \ Assert =
    let state = Game.initGame(0, 0);
    let active = silentAudio(() -> MainScene.newGame(state));
    let pos = SceneTree.globalPosition(PlayerScene.playerName(), active#scene) |> Option.getWithDefault(Vec2D.zero());
    Assert.assertEq(expected = 240.0f32, pos#x);
    Assert.assertEq(expected = 450.0f32, pos#y)

@Test
def testNewGameStartTimerRunning(): Unit \ Assert =
    let state = Game.initGame(0, 0);
    let active = silentAudio(() -> MainScene.newGame(state));
    Assert.assertTrue(SceneTree.isTimerRunning(SceneTree.childName(MainScene.Child.StartTimer), active#scene))

// ========================================================================
// gameOverState
// ========================================================================

@Test
def testGameOverStopsTimers(): Unit \ Assert =
    let state = Game.initGame(0, 0);
    let active = silentAudio(() -> MainScene.newGame(state));
    // Simulate: start mob and score timers, then trigger game over
    let running = {scene = active#scene
        |> SceneTree.startTimer(SceneTree.childName(MainScene.Child.MobTimer))
        |> SceneTree.startTimer(SceneTree.childName(MainScene.Child.ScoreTimer))
    | active};
    let over = silentAudio(() -> MainScene.gameOverState(running));
    Assert.assertTrue(over#gameOver);
    Assert.assertFalse(SceneTree.isTimerRunning(SceneTree.childName(MainScene.Child.MobTimer), over#scene));
    Assert.assertFalse(SceneTree.isTimerRunning(SceneTree.childName(MainScene.Child.ScoreTimer), over#scene))

// ========================================================================
// Rigid-Area overlap detection
// ========================================================================

@Test
def testRigidAreaOverlapDetected(): Unit \ Assert =
    // Mob (RigidBody) at same position as Player (Area2D) → overlap detected
    let player = PlayerScene.buildPlayer({x = 100.0f32, y = 100.0f32});
    let mob = SceneTree.rigidBody2D("Mob_0", {x = 100.0f32, y = 100.0f32},
        {velocity = Vec2D.zero(), gravityScale = 0.0f32, rotation = 0.0f32},
        SceneTree.collisionShape2D("Shape", SceneTree.CollisionShapeData.CapsuleShape(27.0f32, 67.5f32)) :: Nil);
    let root = SceneTree.node2D(MainScene.rootName(), Vec2D.zero(), player :: mob :: Nil);
    let overlaps = SceneTree.detectRigidAreaOverlaps(root);
    Assert.assertTrue(List.length(overlaps) > 0)

@Test
def testRigidAreaOverlapNotDetectedWhenFar(): Unit \ Assert =
    let player = PlayerScene.buildPlayer({x = 0.0f32, y = 0.0f32});
    let mob = SceneTree.rigidBody2D("Mob_0", {x = 400.0f32, y = 400.0f32},
        {velocity = Vec2D.zero(), gravityScale = 0.0f32, rotation = 0.0f32},
        SceneTree.collisionShape2D("Shape", SceneTree.CollisionShapeData.CapsuleShape(27.0f32, 67.5f32)) :: Nil);
    let root = SceneTree.node2D(MainScene.rootName(), Vec2D.zero(), player :: mob :: Nil);
    let overlaps = SceneTree.detectRigidAreaOverlaps(root);
    Assert.assertEq(expected = 0, List.length(overlaps))

// ========================================================================
// applyInput
// ========================================================================

@Test
def testApplyInputZero(): Unit \ Assert =
    let state = Game.initGame(0, 0);
    let active = silentAudio(() -> MainScene.newGame(state));
    let before = SceneTree.globalPosition(PlayerScene.playerName(), active#scene) |> Option.getWithDefault(Vec2D.zero());
    let after = MainScene.applyInput(Vec2D.zero(), active#scene);
    let afterPos = SceneTree.globalPosition(PlayerScene.playerName(), after) |> Option.getWithDefault(Vec2D.zero());
    Assert.assertEq(expected = before#x, afterPos#x);
    Assert.assertEq(expected = before#y, afterPos#y)
