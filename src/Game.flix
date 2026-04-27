// Game module — game-specific logic for Frogger

mod Game {
    pub type alias GameState = {
        scene    = SceneTree.Node,
        gameOver = Bool,
        prevKeys = Set[Engine.Key],
        lives    = Int32
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
        {name = "white", path = "textures/white_1x1.png", hasAlpha = true} ::
        {name = "FroggerIdle", path = "textures/FroggerIdle.png", hasAlpha = true} ::
        {name = "Car1", path = "textures/Car1.png", hasAlpha = true} ::
        {name = "Car2", path = "textures/Car2.png", hasAlpha = true} ::
        {name = "Car3", path = "textures/Car3.png", hasAlpha = true} ::
        {name = "Car4", path = "textures/Car4.png", hasAlpha = true} ::
        {name = "Car5", path = "textures/Car5.png", hasAlpha = true} ::
        {name = "FroggerDead", path = "textures/FroggerDead.png", hasAlpha = true} ::
        {name = "LogStart", path = "textures/LogStart.png", hasAlpha = true} ::
        {name = "LogMiddle", path = "textures/LogMiddle.png", hasAlpha = true} ::
        {name = "LogEnd", path = "textures/LogEnd.png", hasAlpha = true} ::
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
    // Input — Key Collection (effectful)
    // ========================================================================

    pub def collectPressedKeys(): Set[Engine.Key] \ Engine.Game =
        let keys = Engine.Key.W :: Engine.Key.A :: Engine.Key.S :: Engine.Key.D ::
                   Engine.Key.Up :: Engine.Key.Down :: Engine.Key.Left :: Engine.Key.Right :: Nil;
        List.foldLeft((acc, k) ->
            if (Engine.Game.isKeyPressed(k)) Set.insert(k, acc) else acc,
            Set.empty(), keys)

    // ========================================================================
    // Input — Pure Edge Detection
    // ========================================================================

    pub def justPressedKeys(curr: Set[Engine.Key], prev: Set[Engine.Key]): Set[Engine.Key] =
        Set.difference(curr, prev)

    // ========================================================================
    // Input — Direction from Just-Pressed Keys
    // ========================================================================

    pub def inputDirection(justPressed: Set[Engine.Key]): Option[SceneTree.Direction] =
        if (Set.memberOf(Engine.Key.W, justPressed) or Set.memberOf(Engine.Key.Up, justPressed))
            Some(SceneTree.Direction.Up)
        else if (Set.memberOf(Engine.Key.S, justPressed) or Set.memberOf(Engine.Key.Down, justPressed))
            Some(SceneTree.Direction.Down)
        else if (Set.memberOf(Engine.Key.A, justPressed) or Set.memberOf(Engine.Key.Left, justPressed))
            Some(SceneTree.Direction.Left)
        else if (Set.memberOf(Engine.Key.D, justPressed) or Set.memberOf(Engine.Key.Right, justPressed))
            Some(SceneTree.Direction.Right)
        else
            None

    // ========================================================================
    // Game Initialization
    // ========================================================================

    pub def initGame(): GameState =
        let scene = FroggerScene.buildInitialScene();
        {scene = scene, gameOver = false, prevKeys = Set.empty(), lives = 3}

    // ========================================================================
    // Game Loop
    // ========================================================================

    def processInput(state: GameState): GameState \ Engine.Game =
        let currKeys = collectPressedKeys();
        if (FroggerScene.isPlayerDead(state#scene))
            {prevKeys = currKeys | state}
        else {
            let justPressed = justPressedKeys(currKeys, state#prevKeys);
            {scene = match inputDirection(justPressed) {
                case Some(dir) => FroggerScene.applyInput(dir, state#scene)
                case None      => state#scene
            }, prevKeys = currKeys | state}
        }

    pub def updateGame(state: GameState): GameState \ Engine.Game =
        (if (not state#gameOver) processInput(state) else state) |>
            FroggerScene.stepFrame(Engine.Game.getDeltaTime())

    pub def startGame(): GameState \ Engine.Game =
        let state = initGame();
        runLoop(state)

    @Tailrec
    def runLoop(state: GameState): GameState \ Engine.Game =
        if (Engine.Game.shouldClose() or Engine.Game.isKeyPressed(Engine.Key.Escape)) state
        else {
            let newState = updateGame(state);
            Engine.Game.render(newState#scene);
            runLoop(newState)
        }

}
