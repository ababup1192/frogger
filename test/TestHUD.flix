// Tests for HUD — score display, message, start button

use SceneTree.childName

// ========================================================================
// HUD Structure
// ========================================================================

@Test
def testHUDBuildStructure(): Unit \ Assert =
    let hud = HUDScene.buildHUD();
    Assert.assertTrue(not Option.isEmpty(SceneTree.findNode(childName(HUDScene.Child.ScoreLabel), hud)));
    Assert.assertTrue(not Option.isEmpty(SceneTree.findNode(childName(HUDScene.Child.Message), hud)));
    Assert.assertTrue(not Option.isEmpty(SceneTree.findNode(childName(HUDScene.Child.StartButton), hud)));
    Assert.assertTrue(not Option.isEmpty(SceneTree.findNode(childName(HUDScene.Child.MessageTimer), hud)))

// ========================================================================
// Score
// ========================================================================

@Test
def testUpdateScore(): Unit \ Assert =
    let hud = HUDScene.buildHUD();
    let root = SceneTree.node2D("Root", Vec2D.zero(), hud :: Nil);
    let updated = HUDScene.updateScore(42, root);
    match SceneTree.findChild(HUDScene.Child.ScoreLabel, updated) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) => Assert.assertEq(expected = "42", ld#text)
            case _ => Assert.assertTrue(false)
        }
        case None => Assert.assertTrue(false)
    }

// ========================================================================
// Message
// ========================================================================

@Test
def testShowMessage(): Unit \ Assert =
    let hud = HUDScene.buildHUD();
    let root = SceneTree.node2D("Root", Vec2D.zero(), hud :: Nil);
    let updated = HUDScene.showMessage("Hello", root);
    match SceneTree.findChild(HUDScene.Child.Message, updated) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) =>
                Assert.assertTrue(ld#visible);
                Assert.assertEq(expected = "Hello", ld#text)
            case _ => Assert.assertTrue(false)
        }
        case None => Assert.assertTrue(false)
    }

@Test
def testHideMessage(): Unit \ Assert =
    let hud = HUDScene.buildHUD();
    let root = SceneTree.node2D("Root", Vec2D.zero(), hud :: Nil);
    let shown = HUDScene.showMessage("Hello", root);
    let hidden = HUDScene.hideMessage(shown);
    match SceneTree.findChild(HUDScene.Child.Message, hidden) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) => Assert.assertFalse(ld#visible)
            case _ => Assert.assertTrue(false)
        }
        case None => Assert.assertTrue(false)
    }

// ========================================================================
// Start Button
// ========================================================================

@Test
def testShowStartButton(): Unit \ Assert =
    let hud = HUDScene.buildHUD();
    let root = SceneTree.node2D("Root", Vec2D.zero(), hud :: Nil);
    let updated = HUDScene.showStartButton(root);
    match SceneTree.findChild(HUDScene.Child.StartButton, updated) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Button(bd) => Assert.assertTrue(bd#visible)
            case _ => Assert.assertTrue(false)
        }
        case None => Assert.assertTrue(false)
    }

@Test
def testHideStartButton(): Unit \ Assert =
    let hud = HUDScene.buildHUD();
    let root = SceneTree.node2D("Root", Vec2D.zero(), hud :: Nil);
    let shown = HUDScene.showStartButton(root);
    let hidden = HUDScene.hideStartButton(shown);
    match SceneTree.findChild(HUDScene.Child.StartButton, hidden) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Button(bd) => Assert.assertFalse(bd#visible)
            case _ => Assert.assertTrue(false)
        }
        case None => Assert.assertTrue(false)
    }

// ========================================================================
// onNewGame
// ========================================================================

@Test
def testOnNewGame(): Unit \ Assert =
    let hud = HUDScene.buildHUD();
    let root = SceneTree.node2D("Root", Vec2D.zero(), hud :: Nil);
    let shown = HUDScene.showStartButton(root);
    let updated = HUDScene.onNewGame(shown);
    // StartButton should be hidden
    match SceneTree.findChild(HUDScene.Child.StartButton, updated) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Button(bd) => Assert.assertFalse(bd#visible)
            case _ => Assert.assertTrue(false)
        }
        case None => Assert.assertTrue(false)
    };
    // Message should be "Get Ready!" and visible
    match SceneTree.findChild(HUDScene.Child.Message, updated) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) =>
                Assert.assertTrue(ld#visible);
                Assert.assertEq(expected = "Get Ready!", ld#text)
            case _ => Assert.assertTrue(false)
        }
        case None => Assert.assertTrue(false)
    };
    // Score should be "0"
    match SceneTree.findChild(HUDScene.Child.ScoreLabel, updated) {
        case Some(node) => match SceneTree.nodeKind(node) {
            case SceneTree.NodeKind.Label(ld) => Assert.assertEq(expected = "0", ld#text)
            case _ => Assert.assertTrue(false)
        }
        case None => Assert.assertTrue(false)
    }

// ========================================================================
// MainScene includes HUD
// ========================================================================

@Test
def testMainSceneHasHUD(): Unit \ Assert =
    let scene = MainScene.buildInitialScene();
    Assert.assertTrue(not Option.isEmpty(SceneTree.findNode(HUDScene.hudName(), scene)))
