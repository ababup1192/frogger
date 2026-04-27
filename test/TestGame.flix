// Tests for Dodge the Creeps — Game module

// ========================================================================
// Helper: Game effect handler for tests
// ========================================================================

def runOneFrame(state: Game.GameState, dt: Float32): Game.GameState =
    runOneFrameWithKeys(state, dt, Set.empty())

def runOneFrameWithKeys(state: Game.GameState, dt: Float32, keys: Set[Engine.Key]): Game.GameState =
    run {
        Game.updateGame(state)
    } with handler Math.Random {
        def randomFloat64(k) = k(0.5)
        def randomInt64(k) = k(0i64)
    }
    with handler Engine.Audio {
        def playAudio(_name, k) = k(())
        def stopAudio(_name, k) = k(())
    }
    with handler Engine.Game {
        def render(_scene, k)        = k(())
        def shouldClose(k)           = k(true)
        def getDeltaTime(k)          = k(dt)
        def isKeyPressed(key, k) = k(Set.memberOf(key, keys))
    }
    with handler Engine.Mouse {
        def isMousePressed(k) = k(false)
        def getMouseX(k)      = k(0.0f32)
        def getMouseY(k)      = k(0.0f32)
    }

// Helper: create an active (not gameOver) state for testing movement
def activeGameState(): Game.GameState =
    let state = Game.initGame(0, 0);
    run { MainScene.newGame(state) }
    with handler Engine.Audio {
        def playAudio(_name, k) = k(())
        def stopAudio(_name, k) = k(())
    }

// ========================================================================
// Tests
// ========================================================================

@Test
def testInitGameCreatesScene(): Unit \ Assert =
    let state = Game.initGame(0, 0);
    let rootName = SceneTree.nodeName(state#scene);
    Assert.assertEq(expected = MainScene.rootName(), rootName)

@Test
def testInitGameScore(): Unit \ Assert =
    let state = Game.initGame(0, 0);
    Assert.assertEq(expected = 0, state#score)

@Test
def testInitGameIsGameOver(): Unit \ Assert =
    let state = Game.initGame(0, 0);
    Assert.assertTrue(state#gameOver)

@Test
def testUpdateGameNoInputPreservesScene(): Unit \ Assert =
    let state = activeGameState();
    let result = runOneFrame(state, 0.0f32);
    let playerPos = SceneTree.globalPosition(PlayerScene.playerName(), result#scene) |> Option.getWithDefault(Vec2D.zero());
    Assert.assertEq(expected = 240.0f32, playerPos#x);
    Assert.assertEq(expected = 450.0f32, playerPos#y)

@Test
def testMoveRight(): Unit \ Assert =
    let state = activeGameState();
    let result = runOneFrameWithKeys(state, 1.0f32, Set#{Game.keyD()});
    let pos = SceneTree.globalPosition(PlayerScene.playerName(), result#scene) |> Option.getWithDefault(Vec2D.zero());
    Assert.assertTrue(pos#x > 240.0f32)

@Test
def testMoveLeft(): Unit \ Assert =
    let state = activeGameState();
    let result = runOneFrameWithKeys(state, 1.0f32, Set#{Game.keyA()});
    let pos = SceneTree.globalPosition(PlayerScene.playerName(), result#scene) |> Option.getWithDefault(Vec2D.zero());
    Assert.assertTrue(pos#x < 240.0f32)

@Test
def testMoveDown(): Unit \ Assert =
    let state = activeGameState();
    let result = runOneFrameWithKeys(state, 1.0f32, Set#{Game.keyS()});
    let pos = SceneTree.globalPosition(PlayerScene.playerName(), result#scene) |> Option.getWithDefault(Vec2D.zero());
    Assert.assertTrue(pos#y > 450.0f32)

@Test
def testMoveUp(): Unit \ Assert =
    let state = activeGameState();
    let result = runOneFrameWithKeys(state, 1.0f32, Set#{Game.keyW()});
    let pos = SceneTree.globalPosition(PlayerScene.playerName(), result#scene) |> Option.getWithDefault(Vec2D.zero());
    Assert.assertTrue(pos#y < 450.0f32)

@Test
def testNoInputStopsAnimation(): Unit \ Assert =
    let state = activeGameState();
    let result = runOneFrame(state, 0.016f32);
    let spriteNode = SceneTree.findChild(PlayerScene.Child.Sprite, result#scene);
    let playing = match spriteNode {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.AnimatedSprite(asd) => asd#playing
            case _ => true
        }
        case None => true
    };
    Assert.assertFalse(playing)
