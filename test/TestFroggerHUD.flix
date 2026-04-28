// Tests for FroggerHUD — HUD structure, label updates, and message overlays

// ========================================================================
// HUD Structure Tests
// ========================================================================

// HUD コンテナ名が "HUD" であること
@Test
def testHUDContainerName(): Unit \ Assert =
    Assert.assertEq(expected = "HUD", FroggerHUD.containerName())

// HUD ノードは CanvasLayer であること
@Test
def testHUDIsCanvasLayer(): Unit \ Assert =
    let hud = FroggerHUD.buildHUD();
    match SceneTree.nodeKind(hud) {
        case SceneTree.NodeKind.CanvasLayer => Assert.assertTrue(true)
        case _ => bug!("HUD should be CanvasLayer")
    }

// HUD に 4つの子ノード（LivesLabel, TimerLabel, MessageLabel, RestartLabel）があること
@Test
def testHUDHasFourChildren(): Unit \ Assert =
    let hud = FroggerHUD.buildHUD();
    Assert.assertEq(expected = 4, List.length(SceneTree.nodeChildren(hud)))

// HUD の子ノード名が正しい順序であること
@Test
def testHUDChildNames(): Unit \ Assert =
    let names = FroggerHUD.buildHUD()
        |> SceneTree.nodeChildren
        |> List.map(SceneTree.nodeName);
    Assert.assertEq(expected = "LivesLabel" :: "TimerLabel" :: "MessageLabel" :: "RestartLabel" :: Nil, names)

// ========================================================================
// 初期状態テスト
// ========================================================================

// LivesLabel の初期テキストが "LIVES: 3" であること
@Test
def testInitialLivesLabel(): Unit \ Assert =
    let hud = FroggerHUD.buildHUD();
    match SceneTree.findNode("LivesLabel", hud) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) =>
                Assert.assertEq(expected = "LIVES: 3", ld#text)
            case _ => bug!("LivesLabel should be Label")
        }
        case None => bug!("LivesLabel not found")
    }

// TimerLabel の初期テキストが "TIME: 30" であること
@Test
def testInitialTimerLabel(): Unit \ Assert =
    let hud = FroggerHUD.buildHUD();
    match SceneTree.findNode("TimerLabel", hud) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) =>
                Assert.assertEq(expected = "TIME: 30", ld#text)
            case _ => bug!("TimerLabel should be Label")
        }
        case None => bug!("TimerLabel not found")
    }

// MessageLabel が初期状態では非表示であること
@Test
def testMessageLabelInitiallyHidden(): Unit \ Assert =
    let hud = FroggerHUD.buildHUD();
    match SceneTree.findNode("MessageLabel", hud) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) =>
                Assert.assertEq(expected = false, ld#visible)
            case _ => bug!("MessageLabel should be Label")
        }
        case None => bug!("MessageLabel not found")
    }

// RestartLabel が初期状態では非表示であること
@Test
def testRestartLabelInitiallyHidden(): Unit \ Assert =
    let hud = FroggerHUD.buildHUD();
    match SceneTree.findNode("RestartLabel", hud) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) =>
                Assert.assertEq(expected = false, ld#visible)
            case _ => bug!("RestartLabel should be Label")
        }
        case None => bug!("RestartLabel not found")
    }

// ========================================================================
// Update Tests
// ========================================================================

// update でライフ数のテキストが更新されること
@Test
def testUpdateLivesChangesText(): Unit \ Assert =
    let scene = SceneTree.node2D("Root", Vec2D.zero(), FroggerHUD.buildHUD() :: Nil);
    let updated = FroggerHUD.update({lives = 2, timeRemaining = 30.0f32, scene = scene});
    match SceneTree.findNode("LivesLabel", updated) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) =>
                Assert.assertEq(expected = "LIVES: 2", ld#text)
            case _ => bug!("LivesLabel should be Label")
        }
        case None => bug!("LivesLabel not found")
    }

// update でタイマーテキストが更新されること（小数点以下は切り捨て）
@Test
def testUpdateTimerChangesText(): Unit \ Assert =
    let scene = SceneTree.node2D("Root", Vec2D.zero(), FroggerHUD.buildHUD() :: Nil);
    let updated = FroggerHUD.update({lives = 3, timeRemaining = 15.7f32, scene = scene});
    match SceneTree.findNode("TimerLabel", updated) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) =>
                Assert.assertEq(expected = "TIME: 16", ld#text)
            case _ => bug!("TimerLabel should be Label")
        }
        case None => bug!("TimerLabel not found")
    }

// ========================================================================
// Message & Restart Overlay Tests
// ========================================================================

// showMessage でメッセージテキストが設定され表示されること
@Test
def testShowMessageSetsTextAndVisible(): Unit \ Assert =
    let scene = SceneTree.node2D("Root", Vec2D.zero(), FroggerHUD.buildHUD() :: Nil);
    let updated = FroggerHUD.showMessage("You Won!", scene);
    match SceneTree.findNode("MessageLabel", updated) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) =>
                Assert.assertEq(expected = ("You Won!", true), (ld#text, ld#visible))
            case _ => bug!("MessageLabel should be Label")
        }
        case None => bug!("MessageLabel not found")
    }

// showRestart でリスタートラベルが表示されること
@Test
def testShowRestartMakesVisible(): Unit \ Assert =
    let scene = SceneTree.node2D("Root", Vec2D.zero(), FroggerHUD.buildHUD() :: Nil);
    let updated = FroggerHUD.showRestart(scene);
    match SceneTree.findNode("RestartLabel", updated) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) =>
                Assert.assertEq(expected = true, ld#visible)
            case _ => bug!("RestartLabel should be Label")
        }
        case None => bug!("RestartLabel not found")
    }

// hideOverlays でメッセージとリスタートの両方が非表示になること
@Test
def testHideOverlaysMakesBothHidden(): Unit \ Assert =
    let scene = SceneTree.node2D("Root", Vec2D.zero(), FroggerHUD.buildHUD() :: Nil)
        |> FroggerHUD.showMessage("Test")
        |> FroggerHUD.showRestart;
    let hidden = FroggerHUD.hideOverlays(scene);
    let msgVis = match SceneTree.findNode("MessageLabel", hidden) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) => ld#visible
            case _ => bug!("MessageLabel should be Label")
        }
        case None => bug!("MessageLabel not found")
    };
    let rstVis = match SceneTree.findNode("RestartLabel", hidden) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) => ld#visible
            case _ => bug!("RestartLabel should be Label")
        }
        case None => bug!("RestartLabel not found")
    };
    Assert.assertEq(expected = (false, false), (msgVis, rstVis))
