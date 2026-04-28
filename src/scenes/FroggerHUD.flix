// FroggerHUD — HUD overlay (lives, timer, messages)

mod FroggerHUD {

    // ========================================================================
    // Constants
    // ========================================================================

    pub def containerName(): String = "HUD"

    def livesLabelName(): String = "LivesLabel"

    def timerLabelName(): String = "TimerLabel"

    def messageLabelName(): String = "MessageLabel"

    def restartLabelName(): String = "RestartLabel"

    def hudFontSize(): Float32 = 28.0f32

    def messageFontSize(): Float32 = 48.0f32

    def restartFontSize(): Float32 = 24.0f32

    // ========================================================================
    // Build HUD — CanvasLayer with four Label2D children
    //
    // CanvasLayer "HUD"
    // +-- Label2D "LivesLabel"     pos=(20, 920)     "LIVES: 3"
    // +-- Label2D "TimerLabel"     pos=(650, 920)    "TIME: 30"
    // +-- Label2D "MessageLabel"   pos=(392, 450)    "" (hidden, centered)
    // +-- Label2D "RestartLabel"   pos=(392, 520)    "" (hidden, centered)
    // ========================================================================

    pub def buildHUD(): SceneTree.Node =
        let font = Game.defaultFont();
        let livesLabel = Label2D.init({name = livesLabelName(), pos = {x = 20.0f32, y = 920.0f32},
                                       text = "LIVES: 3", fontSize = hudFontSize(), font = font});
        let timerLabel = Label2D.init({name = timerLabelName(), pos = {x = 650.0f32, y = 920.0f32},
                                       text = "TIME: 30", fontSize = hudFontSize(), font = font});
        let messageLabel = Label2D.init({name = messageLabelName(), pos = {x = 392.0f32, y = 450.0f32},
                                          text = "", fontSize = messageFontSize(), font = font})
            |> Label2D.visible(false)
            |> Label2D.centered(true)
            |> Label2D.color({r = 1.0f32, g = 1.0f32, b = 0.0f32});
        let restartLabel = Label2D.init({name = restartLabelName(), pos = {x = 392.0f32, y = 520.0f32},
                                          text = "", fontSize = restartFontSize(), font = font})
            |> Label2D.visible(false)
            |> Label2D.centered(true);
        CanvasLayer2D.init({name = containerName(),
                            children = livesLabel :: timerLabel :: messageLabel :: restartLabel :: Nil})

    // ========================================================================
    // Update Functions
    // ========================================================================

    pub def update(state: {lives = Int32, timeRemaining = Float32, scene = SceneTree.Node | _r}): SceneTree.Node =
        let seconds = Float32.max(0.0f32, state#timeRemaining) |> Vec2D.floatToInt32;
        state#scene
            |> SceneTree.updateLabelIn(containerName(), livesLabelName(),
                ld -> {text = "LIVES: ${state#lives}" | ld})
            |> SceneTree.updateLabelIn(containerName(), timerLabelName(),
                ld -> {text = "TIME: ${seconds}" | ld})

    pub def showMessage(text: String, scene: SceneTree.Node): SceneTree.Node =
        SceneTree.updateLabelIn(containerName(), messageLabelName(),
            ld -> {text = text, visible = true | ld}, scene)

    pub def showRestart(scene: SceneTree.Node): SceneTree.Node =
        SceneTree.updateLabelIn(containerName(), restartLabelName(),
            ld -> {text = "Press ENTER to restart", visible = true | ld}, scene)

    pub def hideOverlays(scene: SceneTree.Node): SceneTree.Node =
        scene
            |> SceneTree.updateLabelIn(containerName(), messageLabelName(),
                ld -> {visible = false | ld})
            |> SceneTree.updateLabelIn(containerName(), restartLabelName(),
                ld -> {visible = false | ld})
}
