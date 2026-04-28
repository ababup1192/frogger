// Tests for FroggerHUD — HUD structure, label updates, and message overlays

// ========================================================================
// JSON 一括検証テスト
// ========================================================================

// buildHUD() が scene.json と一致する構造を返すこと
@Test
def testBuildHUDMatchesJson(): Unit \ {Assert, Fs.FileRead} =
    let hud = FroggerHUD.buildHUD();
    let children = SceneTree.nodeChildren(hud);
    def getLabelData(name: String): Option[{node = SceneTree.Node, ld = SceneTree.LabelData}] =
        forM (
            node <- SceneTree.findNode(name, hud)
        ) yield match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) => {node = node, ld = ld}
            case _ => bug!("${name} should be Label")
        };
    let result = forM (
        lives   <- getLabelData(SceneTree.childName(FroggerHUD.Child.LivesLabel));
        timer   <- getLabelData(SceneTree.childName(FroggerHUD.Child.TimerLabel));
        message <- getLabelData(SceneTree.childName(FroggerHUD.Child.MessageLabel));
        restart <- getLabelData(SceneTree.childName(FroggerHUD.Child.RestartLabel))
    ) yield {
        // Root: CanvasLayer "HUD" with 4 children
        Assert.assertEq(expected = "HUD", SceneTree.nodeName(hud));
        Assert.assertEq(expected = 4, List.length(children));
        // LivesLabel: pos=(20,920), text="LIVES: 3", fontSize=28
        Assert.assertEq(expected = 20.0f32, SceneTree.nodePosition(lives#node)#x);
        Assert.assertEq(expected = 920.0f32, SceneTree.nodePosition(lives#node)#y);
        Assert.assertEq(expected = "LIVES: 3", lives#ld#text);
        Assert.assertEq(expected = 28.0f32, lives#ld#fontSize);
        // TimerLabel: pos=(650,920), text="TIME: 30", fontSize=28
        Assert.assertEq(expected = 650.0f32, SceneTree.nodePosition(timer#node)#x);
        Assert.assertEq(expected = 920.0f32, SceneTree.nodePosition(timer#node)#y);
        Assert.assertEq(expected = "TIME: 30", timer#ld#text);
        Assert.assertEq(expected = 28.0f32, timer#ld#fontSize);
        // MessageLabel: pos=(392,450), text="", fontSize=48, hidden, centered, yellow
        Assert.assertEq(expected = 392.0f32, SceneTree.nodePosition(message#node)#x);
        Assert.assertEq(expected = 450.0f32, SceneTree.nodePosition(message#node)#y);
        Assert.assertEq(expected = "", message#ld#text);
        Assert.assertEq(expected = 48.0f32, message#ld#fontSize);
        Assert.assertEq(expected = false, message#ld#visible);
        Assert.assertEq(expected = true, message#ld#centered);
        Assert.assertEq(expected = 1.0f32, message#ld#color#r);
        Assert.assertEq(expected = 1.0f32, message#ld#color#g);
        Assert.assertEq(expected = 0.0f32, message#ld#color#b);
        // RestartLabel: pos=(392,520), text="", fontSize=24, hidden, centered
        Assert.assertEq(expected = 392.0f32, SceneTree.nodePosition(restart#node)#x);
        Assert.assertEq(expected = 520.0f32, SceneTree.nodePosition(restart#node)#y);
        Assert.assertEq(expected = "", restart#ld#text);
        Assert.assertEq(expected = 24.0f32, restart#ld#fontSize);
        Assert.assertEq(expected = false, restart#ld#visible);
        Assert.assertEq(expected = true, restart#ld#centered)
    };
    match result {
        case Some(_) => ()
        case None    => bug!("HUD node structure does not match expected JSON layout")
    }

// ========================================================================
// HUD Structure Tests
// ========================================================================

// HUD コンテナ名が "HUD" であること
@Test
def testHUDContainerName(): Unit \ Assert =
    Assert.assertEq(expected = "HUD", FroggerHUD.containerName())

// HUD ノードは CanvasLayer であること
@Test
def testHUDIsCanvasLayer(): Unit \ {Assert, Fs.FileRead} =
    let hud = FroggerHUD.buildHUD();
    match SceneTree.nodeKind(hud) {
        case SceneTree.NodeKind.CanvasLayer => Assert.assertTrue(true)
        case _ => bug!("HUD should be CanvasLayer")
    }

// HUD に 4つの子ノード（LivesLabel, TimerLabel, MessageLabel, RestartLabel）があること
@Test
def testHUDHasFourChildren(): Unit \ {Assert, Fs.FileRead} =
    let hud = FroggerHUD.buildHUD();
    Assert.assertEq(expected = 4, List.length(SceneTree.nodeChildren(hud)))

// HUD の子ノード名が正しい順序であること
@Test
def testHUDChildNames(): Unit \ {Assert, Fs.FileRead} =
    let names = FroggerHUD.buildHUD()
        |> SceneTree.nodeChildren
        |> List.map(SceneTree.nodeName);
    Assert.assertEq(expected = "LivesLabel" :: "TimerLabel" :: "MessageLabel" :: "RestartLabel" :: Nil, names)

// ========================================================================
// 初期状態テスト
// ========================================================================

// LivesLabel の初期テキストが "LIVES: 3" であること
@Test
def testInitialLivesLabel(): Unit \ {Assert, Fs.FileRead} =
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
def testInitialTimerLabel(): Unit \ {Assert, Fs.FileRead} =
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
def testMessageLabelInitiallyHidden(): Unit \ {Assert, Fs.FileRead} =
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
def testRestartLabelInitiallyHidden(): Unit \ {Assert, Fs.FileRead} =
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
def testUpdateLivesChangesText(): Unit \ {Assert, Fs.FileRead} =
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
def testUpdateTimerChangesText(): Unit \ {Assert, Fs.FileRead} =
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
def testShowMessageSetsTextAndVisible(): Unit \ {Assert, Fs.FileRead} =
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
def testShowRestartMakesVisible(): Unit \ {Assert, Fs.FileRead} =
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
def testHideOverlaysMakesBothHidden(): Unit \ {Assert, Fs.FileRead} =
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
