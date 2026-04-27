// Game module — game-specific logic for Frogger

mod Game {
    pub type alias GameState = {
        scene    = SceneTree.Node,
        gameOver = Bool
    }

    // ========================================================================
    // Constants
    // ========================================================================

    pub def screenWidth(): Int32 = 784
    pub def screenHeight(): Int32 = 1000

    // ========================================================================
    // Font
    // ========================================================================

    pub def defaultFont(): String = "textures/UDEVGothic-Regular.ttf"

    pub def fontManifest(): List[String] =
        defaultFont() :: Nil

    // ========================================================================
    // Texture Manifest
    // ========================================================================

    pub def textureManifest(): List[Engine.TextureEntry] =
        {name = "FroggerIdle", path = "textures/FroggerIdle.png", hasAlpha = true} ::
        Nil

    // ========================================================================
    // Audio Manifest
    // ========================================================================

    pub def audioManifest(): List[Engine.AudioEntry] =
        Nil

    // ========================================================================
    // Engine Config
    // ========================================================================

    pub def engineConfig(): Engine.EngineConfig = {
        screenWidth = screenWidth(),
        screenHeight = screenHeight(),
        title = "Frogger",
        textureManifest = textureManifest(),
        audioManifest = audioManifest(),
        fontPath = defaultFont(),
        clearColor = {r = 0.2f32, g = 0.5f32, b = 0.2f32}
    }

    // ========================================================================
    // Game Initialization
    // ========================================================================

    pub def initGame(): GameState =
        let scene = FroggerScene.buildInitialScene();
        {scene = scene, gameOver = false}

    // ========================================================================
    // Game Loop
    // ========================================================================

    pub def startGame(): GameState \ Engine.Game =
        let state = initGame();
        runLoop(state)

    @Tailrec
    def runLoop(state: GameState): GameState \ Engine.Game =
        if (Engine.Game.shouldClose() or Engine.Game.isKeyPressed(Engine.Key.Escape)) state
        else {
            Engine.Game.render(state#scene);
            let _dt = Engine.Game.getDeltaTime();
            runLoop(state)
        }

}
