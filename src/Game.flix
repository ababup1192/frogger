// Game module — game-specific logic for Dodge the Creeps

mod Game {
    pub type alias GameState = {
        scene      = SceneTree.Node,
        score      = Int32,
        mobCounter = Int32,
        gameOver   = Bool
    }

    // ========================================================================
    // Constants
    // ========================================================================

    pub def screenWidth(): Int32 = 480
    pub def screenHeight(): Int32 = 720

    pub def keyW(): Engine.Key = Engine.Key.W
    pub def keyA(): Engine.Key = Engine.Key.A
    pub def keyS(): Engine.Key = Engine.Key.S
    pub def keyD(): Engine.Key = Engine.Key.D
    pub def keyUp(): Engine.Key = Engine.Key.Up
    pub def keyDown(): Engine.Key = Engine.Key.Down
    pub def keyLeft(): Engine.Key = Engine.Key.Left
    pub def keyRight(): Engine.Key = Engine.Key.Right
    pub def keyEnter(): Engine.Key = Engine.Key.Enter

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
        {name = "playerGrey_walk1", path = "textures/playerGrey_walk1.png", hasAlpha = true} ::
        {name = "playerGrey_walk2", path = "textures/playerGrey_walk2.png", hasAlpha = true} ::
        {name = "playerGrey_up1", path = "textures/playerGrey_up1.png", hasAlpha = true} ::
        {name = "playerGrey_up2", path = "textures/playerGrey_up2.png", hasAlpha = true} ::
        {name = "enemyFlyingAlt_1", path = "textures/enemyFlyingAlt_1.png", hasAlpha = true} ::
        {name = "enemyFlyingAlt_2", path = "textures/enemyFlyingAlt_2.png", hasAlpha = true} ::
        {name = "enemySwimming_1", path = "textures/enemySwimming_1.png", hasAlpha = true} ::
        {name = "enemySwimming_2", path = "textures/enemySwimming_2.png", hasAlpha = true} ::
        {name = "enemyWalking_1", path = "textures/enemyWalking_1.png", hasAlpha = true} ::
        {name = "enemyWalking_2", path = "textures/enemyWalking_2.png", hasAlpha = true} ::
        Nil

    // ========================================================================
    // Audio Manifest
    // ========================================================================

    pub def audioManifest(): List[Engine.AudioEntry] =
        {name = "music", path = "sounds/House In a Forest Loop.ogg", looping = true} ::
        {name = "death", path = "sounds/gameover.wav", looping = false} ::
        Nil

    // ========================================================================
    // Engine Config
    // ========================================================================

    pub def engineConfig(): Engine.EngineConfig = {
        screenWidth = screenWidth(),
        screenHeight = screenHeight(),
        title = "Dodge the Creeps!",
        textureManifest = textureManifest(),
        audioManifest = audioManifest(),
        fontPath = defaultFont(),
        clearColor = {r = 0.2196f32, g = 0.3725f32, b = 0.3804f32}
    }

    // ========================================================================
    // Game Initialization
    // ========================================================================

    pub def initGame(_playerRow: Int32, _playerCol: Int32): GameState =
        let scene = MainScene.buildInitialScene();
        {scene = scene, score = 0, mobCounter = 0, gameOver = true}

    // ========================================================================
    // Game Loop
    // ========================================================================

    pub def startGame(): GameState \ {Engine.Game, Engine.Mouse, Engine.Audio, Math.Random} =
        let state = initGame(0, 0);
        runLoop(state)

    @Tailrec
    def runLoop(state: GameState): GameState \ {Engine.Game, Engine.Mouse, Engine.Audio, Math.Random} =
        if (Engine.Game.shouldClose() or Engine.Game.isKeyPressed(Engine.Key.Escape)) state
        else {
            let newState = updateGame(state);
            Engine.Game.render(newState#scene);
            runLoop(newState)
        }

    // ========================================================================
    // Game Logic — per-frame update
    // ========================================================================

    pub def updateGame(state: GameState): GameState \ {Engine.Game, Engine.Mouse, Engine.Audio, Math.Random} =
        (if (not state#gameOver) {scene = processInput(state#scene) | state} else state)
            |> MainScene.stepFrame(Engine.Game.getDeltaTime())
            |> (st -> if (st#gameOver and Engine.Game.isKeyPressed(keyEnter()) and MainScene.isReadyToStart(st#scene))
                          MainScene.newGame(st)
                      else st)

    // ========================================================================
    // Input Processing
    // ========================================================================

    def readInputDirection(): Vec2D.Vec2 \ Engine.Game =
        let x = (if (Engine.Game.isKeyPressed(keyD()) or Engine.Game.isKeyPressed(keyRight())) 1.0f32 else 0.0f32)
               - (if (Engine.Game.isKeyPressed(keyA()) or Engine.Game.isKeyPressed(keyLeft()))  1.0f32 else 0.0f32);
        let y = (if (Engine.Game.isKeyPressed(keyS()) or Engine.Game.isKeyPressed(keyDown()))  1.0f32 else 0.0f32)
               - (if (Engine.Game.isKeyPressed(keyW()) or Engine.Game.isKeyPressed(keyUp()))   1.0f32 else 0.0f32);
        {x = x, y = y}

    def processInput(scene: SceneTree.Node): SceneTree.Node \ Engine.Game =
        MainScene.applyInput(readInputDirection(), scene)

}
