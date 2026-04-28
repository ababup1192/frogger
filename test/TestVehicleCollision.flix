// Tests for vehicle collision (OnCollision), death sprite, respawn, and death timer

// ========================================================================
// OnCollision (Area2D overlap) Tests
// ========================================================================

@Test
def testCollisionDetectedWhenHitboxOverlapsVehicle(): Unit \ {Assert, Fs.FileRead} =
    // プレイヤーを V0_0 (初期位置 x=784, レーンY=512) 付近に移動して
    // stepAndCollide で areaEntered が発火することを確認
    let scene = FroggerScene.buildInitialScene()
        |> SceneTree.setNodePosition(FroggerPlayer.playerName(), {x = 760.0f32, y = 512.0f32})
        |> SceneTree.updateCharacterBody(FroggerPlayer.playerName(),
            cbd -> {targetPos = {x = 760.0f32, y = 512.0f32} | cbd});
    let hitboxName = SceneTree.childName(FroggerPlayer.Child.Hitbox);
    let (_, hit) = run {
        let s = SceneTree.stepAndCollide(scene, 0.0f32, FroggerScene.physicsConfig());
        (s, false)
    } with handler SceneTree.OnCollision {
        def bodyEntered(_name, _pos, _body, k) = k(())
        def areaEntered(name, _pos, _body, k) =
            let (s, h) = k(());
            (s, h or name == hitboxName)
    };
    Assert.assertTrue(hit)

@Test
def testNoCollisionAtStartPos(): Unit \ {Assert, Fs.FileRead} =
    // スタート地点ではどの車両とも重ならない
    let scene = FroggerScene.buildInitialScene();
    let hitboxName = SceneTree.childName(FroggerPlayer.Child.Hitbox);
    let (_, hit) = run {
        let s = SceneTree.stepAndCollide(scene, 0.0f32, FroggerScene.physicsConfig());
        (s, false)
    } with handler SceneTree.OnCollision {
        def bodyEntered(_name, _pos, _body, k) = k(())
        def areaEntered(name, _pos, _body, k) =
            let (s, h) = k(());
            (s, h or name == hitboxName)
    };
    Assert.assertFalse(hit)

// ========================================================================
// isPlayerDead Tests
// ========================================================================

@Test
def testNotDeadInitially(): Unit \ {Assert, Fs.FileRead} =
    Assert.assertFalse(FroggerScene.isPlayerDead(FroggerScene.buildInitialScene()))

@Test
def testDeadAfterTimerStart(): Unit \ {Assert, Fs.FileRead} =
    let scene = FroggerScene.buildInitialScene()
        |> SceneTree.startTimer(FroggerScene.deathTimerName());
    Assert.assertTrue(FroggerScene.isPlayerDead(scene))

// ========================================================================
// showDeathSprite Tests
// ========================================================================

@Test
def testShowDeathSpriteChangesAnimation(): Unit \ {Assert, Fs.FileRead} =
    // 死亡時は AnimatedSprite の currentAnimation が "dead" に変わる
    let deathScene = FroggerScene.buildInitialScene() |> FroggerPlayer.showDeathSprite;
    match SceneTree.findNodeIn(FroggerPlayer.playerName(), SceneTree.childName(FroggerPlayer.Child.Sprite), deathScene) {
        case Some(sprite) => match SceneTree.nodeKind(sprite) {
            case SceneTree.NodeKind.AnimatedSprite(asd) =>
                Assert.assertEq(expected = "dead", asd#currentAnimation)
            case _ => bug!("Player/Sprite is not an AnimatedSprite node")
        }
        case None => bug!("Player/Sprite not found")
    }

// ========================================================================
// respawn Tests
// ========================================================================

@Test
def testRespawnResetsPosition(): Unit \ {Assert, Fs.FileRead} =
    let scene = FroggerScene.buildInitialScene();
    let sp = FroggerPlayer.startPos();
    let moved = scene
        |> SceneTree.setNodePosition(FroggerPlayer.playerName(), {x = 200.0f32, y = 500.0f32})
        |> SceneTree.updateCharacterBody(FroggerPlayer.playerName(),
            cbd -> {targetPos = {x = 200.0f32, y = 500.0f32} | cbd});
    match SceneTree.globalPosition(FroggerPlayer.playerName(), FroggerPlayer.respawn(moved)) {
        case Some(pos) =>
            Assert.assertEq(expected = sp#x, pos#x);
            Assert.assertEq(expected = sp#y, pos#y)
        case None => Assert.assertTrue(false)
    }

@Test
def testRespawnRestoresIdleAnimation(): Unit \ {Assert, Fs.FileRead} =
    // リスポーン後は AnimatedSprite の currentAnimation が "idle" に戻る
    let respawned = FroggerScene.buildInitialScene()
        |> FroggerPlayer.showDeathSprite
        |> FroggerPlayer.respawn;
    match SceneTree.findNodeIn(FroggerPlayer.playerName(), SceneTree.childName(FroggerPlayer.Child.Sprite), respawned) {
        case Some(sprite) => match SceneTree.nodeKind(sprite) {
            case SceneTree.NodeKind.AnimatedSprite(asd) =>
                Assert.assertEq(expected = "idle", asd#currentAnimation)
            case _ => bug!("Player/Sprite is not an AnimatedSprite node")
        }
        case None => bug!("Player/Sprite not found")
    }

// ========================================================================
// Death Timer (OnTimeout) Tests
// ========================================================================

@Test
def testDeathTimerFiresAfterWait(): Unit \ {Assert, Fs.FileRead} =
    let scene = FroggerScene.buildInitialScene()
        |> SceneTree.startTimer(FroggerScene.deathTimerName());
    let fired = run {
        discard SceneTree.stepTimers(2.0f32, scene);
        false
    } with handler SceneTree.OnTimeout {
        def timeout(name, _k) = name == FroggerScene.deathTimerName()
    };
    Assert.assertTrue(fired)

@Test
def testDeathTimerNotFiredEarly(): Unit \ {Assert, Fs.FileRead} =
    let scene = FroggerScene.buildInitialScene()
        |> SceneTree.startTimer(FroggerScene.deathTimerName());
    let fired = run {
        discard SceneTree.stepTimers(1.0f32, scene);
        false
    } with handler SceneTree.OnTimeout {
        def timeout(name, _k) = name == FroggerScene.deathTimerName()
    };
    Assert.assertFalse(fired)

@Test
def testDeathTimerStopsAfterFiring(): Unit \ {Assert, Fs.FileRead} =
    let scene = FroggerScene.buildInitialScene()
        |> SceneTree.startTimer(FroggerScene.deathTimerName());
    let result = SceneTree.runWithNoopTimeout(() ->
        SceneTree.stepTimers(2.5f32, scene));
    Assert.assertFalse(FroggerScene.isPlayerDead(result))
