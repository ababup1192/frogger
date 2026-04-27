// HUDScene — Score display, message, and start button

mod HUDScene {
    use SceneTree.childName

    // Node names
    pub def hudName(): String = "HUD"

    // ========================================================================
    // Child enum + SceneChild instance
    // ========================================================================

    pub enum Child with Eq, ToString {
        case ScoreLabel
        case Message
        case TitleLine2
        case StartButton
        case MessageTimer
    }

    instance SceneTree.SceneChild[Child] {
        pub def sceneName(_c: Child): String = hudName()
        pub def childName(c: Child): String = match c {
            case Child.ScoreLabel   => "ScoreLabel"
            case Child.Message      => "Message"
            case Child.TitleLine2   => "TitleLine2"
            case Child.StartButton  => "StartButton"
            case Child.MessageTimer => "MessageTimer"
        }
    }

    // ========================================================================
    // Build HUD
    // ========================================================================

    pub def buildHUD(): SceneTree.Node =
        let font = Game.defaultFont();
        let scoreLabel = Label2D.init({
                name = childName(Child.ScoreLabel), pos = {x = 240.0f32, y = 44.0f32},
                text = "0", fontSize = 48.0f32, font = font
            })
            |> Label2D.centered(true);
        let message = Label2D.init({
                name = childName(Child.Message), pos = {x = 240.0f32, y = 340.0f32},
                text = "", fontSize = 64.0f32, font = font
            })
            |> Label2D.centered(true)
            |> Label2D.visible(false);
        let titleLine2 = Label2D.init({
                name = childName(Child.TitleLine2), pos = {x = 240.0f32, y = 378.0f32},
                text = "", fontSize = 64.0f32, font = font
            })
            |> Label2D.centered(true)
            |> Label2D.visible(false);
        let startButton = Button2D.init({
                name = childName(Child.StartButton), pos = {x = 240.0f32, y = 540.0f32},
                text = "Start", fontSize = 48.0f32, font = font
            });
        let messageTimer = Timer2D.init({
            name = childName(Child.MessageTimer), waitTime = 2.0f32, oneShot = true
        });
        CanvasLayer2D.init({
            name = hudName(),
            children = scoreLabel :: message :: titleLine2 :: startButton :: messageTimer :: Nil
        })

    // ========================================================================
    // Score
    // ========================================================================

    pub def updateScore(score: Int32, scene: SceneTree.Node): SceneTree.Node =
        SceneTree.updateLabelIn(hudName(), childName(Child.ScoreLabel), ld -> {text = "${score}" | ld}, scene)

    // ========================================================================
    // Message
    // ========================================================================

    pub def showMessage(text: String, scene: SceneTree.Node): SceneTree.Node =
        scene
            |> SceneTree.updateLabelIn(hudName(), childName(Child.Message), ld -> {text = text, visible = true | ld})
            |> SceneTree.startTimerIn(hudName(), childName(Child.MessageTimer))

    pub def hideMessage(scene: SceneTree.Node): SceneTree.Node =
        SceneTree.updateLabelIn(hudName(), childName(Child.Message), ld -> {visible = false | ld}, scene)

    // ========================================================================
    // Game Over flow
    // ========================================================================

    pub def showGameOver(scene: SceneTree.Node): SceneTree.Node =
        showMessage("Game Over", scene)

    def setNodePos(name: String, pos: Vec2D.Vec2, root: SceneTree.Node): SceneTree.Node =
        SceneTree.mapNodeIn(hudName(), name, node -> {
            let SceneTree.Node.MkNode(n, _, kind, ch) = node;
            SceneTree.Node.MkNode(n, pos, kind, ch)
        }, root)

    pub def showStartButton(scene: SceneTree.Node): SceneTree.Node =
        scene
            |> setNodePos(childName(Child.Message), {x = 240.0f32, y = 302.0f32})
            |> SceneTree.updateLabelIn(hudName(), childName(Child.Message), ld -> {text = "Dodge the", visible = true | ld})
            |> SceneTree.updateLabelIn(hudName(), childName(Child.TitleLine2), ld -> {text = "Creeps!", visible = true | ld})
            |> SceneTree.updateButtonIn(hudName(), childName(Child.StartButton), bd -> {visible = true | bd})

    pub def hideStartButton(scene: SceneTree.Node): SceneTree.Node =
        scene
            |> setNodePos(childName(Child.Message), {x = 240.0f32, y = 340.0f32})
            |> SceneTree.updateButtonIn(hudName(), childName(Child.StartButton), bd -> {visible = false | bd})
            |> SceneTree.updateLabelIn(hudName(), childName(Child.TitleLine2), ld -> {visible = false | ld})
            |> hideMessage

    // ========================================================================
    // Event Handlers (delegated from MainScene)
    // ========================================================================

    pub def handleTimeout(timerName: String, gameOver: Bool, scene: SceneTree.Node): SceneTree.Node =
        if (timerName == childName(Child.MessageTimer))
            if (gameOver) showStartButton(scene) else scene
        else
            scene

    pub def isStartButton(buttonName: String): Bool =
        buttonName == childName(Child.StartButton)

    pub def isStartButtonVisible(scene: SceneTree.Node): Bool =
        SceneTree.isButtonVisible(childName(Child.StartButton), scene)

    /// Consolidates HUD state changes for new game start
    pub def onNewGame(scene: SceneTree.Node): SceneTree.Node =
        scene
            |> hideStartButton
            |> showMessage("Get Ready!")
            |> updateScore(0)

}
