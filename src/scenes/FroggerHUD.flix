// FroggerHUD — HUD overlay (lives, timer, messages)

mod FroggerHUD {

    // ========================================================================
    // Child enum
    // ========================================================================

    pub enum Child with Eq, ToString {
        case LivesLabel
        case TimerLabel
        case MessageLabel
        case RestartLabel
    }

    instance SceneTree.SceneChild[Child] {
        pub def sceneName(_c: Child): String = FroggerHUD.containerName()
        pub def childName(c: Child): String = match c {
            case Child.LivesLabel   => "LivesLabel"
            case Child.TimerLabel   => "TimerLabel"
            case Child.MessageLabel => "MessageLabel"
            case Child.RestartLabel => "RestartLabel"
        }
    }

    // ========================================================================
    // Constants
    // ========================================================================

    pub def containerName(): String = "HUD"

    // ========================================================================
    // Build HUD — SceneLoader に委譲
    // ========================================================================

    pub def buildHUD(): SceneTree.Node \ Fs.FileRead =
        SceneLoader.loadScene("src/scenes/FroggerHUD.scene.json")

    // ========================================================================
    // Update Functions
    // ========================================================================

    pub def update(state: {lives = Int32, timeRemaining = Float32, scene = SceneTree.Node | _r}): SceneTree.Node =
        let seconds = Float32.max(0.0f32, state#timeRemaining) |> Vec2D.floatToInt32;
        state#scene
            |> SceneTree.updateLabelIn(containerName(), SceneTree.childName(Child.LivesLabel),
                ld -> {text = "LIVES: ${state#lives}" | ld})
            |> SceneTree.updateLabelIn(containerName(), SceneTree.childName(Child.TimerLabel),
                ld -> {text = "TIME: ${seconds}" | ld})

    pub def showMessage(text: String, scene: SceneTree.Node): SceneTree.Node =
        SceneTree.updateLabelIn(containerName(), SceneTree.childName(Child.MessageLabel),
            ld -> {text = text, visible = true | ld}, scene)

    pub def showRestart(scene: SceneTree.Node): SceneTree.Node =
        SceneTree.updateLabelIn(containerName(), SceneTree.childName(Child.RestartLabel),
            ld -> {text = "Press ENTER to restart", visible = true | ld}, scene)

    pub def hideOverlays(scene: SceneTree.Node): SceneTree.Node =
        scene
            |> SceneTree.updateLabelIn(containerName(), SceneTree.childName(Child.MessageLabel),
                ld -> {visible = false | ld})
            |> SceneTree.updateLabelIn(containerName(), SceneTree.childName(Child.RestartLabel),
                ld -> {visible = false | ld})
}
