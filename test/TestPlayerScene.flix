// Tests for PlayerScene — player scene encapsulation

// ========================================================================
// clampToScreen
// ========================================================================

@Test
def testClampToScreen(): Unit \ Assert =
    let player = PlayerScene.buildPlayer({x = 600.0f32, y = 800.0f32});
    let root = SceneTree.node2D(MainScene.rootName(), Vec2D.zero(), player :: Nil);
    let screenSize = {x = 480.0f32, y = 720.0f32};
    let clamped = PlayerScene.clampToScreen(screenSize, root);
    let pos = SceneTree.globalPosition(PlayerScene.playerName(), clamped) |> Option.getWithDefault(Vec2D.zero());
    let size = PlayerScene.playerSize();
    Assert.assertEq(expected = 480.0f32 - size#x, pos#x);
    Assert.assertEq(expected = 720.0f32 - size#y, pos#y)

@Test
def testClampToScreenInside(): Unit \ Assert =
    let player = PlayerScene.buildPlayer({x = 100.0f32, y = 200.0f32});
    let root = SceneTree.node2D(MainScene.rootName(), Vec2D.zero(), player :: Nil);
    let screenSize = {x = 480.0f32, y = 720.0f32};
    let clamped = PlayerScene.clampToScreen(screenSize, root);
    let pos = SceneTree.globalPosition(PlayerScene.playerName(), clamped) |> Option.getWithDefault(Vec2D.zero());
    Assert.assertEq(expected = 100.0f32, pos#x);
    Assert.assertEq(expected = 200.0f32, pos#y)
