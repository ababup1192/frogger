// Game module — game-specific logic for Frogger

mod Game {
    pub type alias GameState = {
        scene           = SceneTree.Node,
        gameOver        = Bool,
        prevKeys        = Set[Engine.Key],
        lives           = Int32,
        homeSlotsFilled = Set[Int32],
        won             = Bool,
        timeRemaining   = Float32,
        debugMode       = Bool,
        debugCursor     = List[Int32]
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
        {name = "FroggerLeap", path = "textures/FroggerLeap.png", hasAlpha = true} ::
        {name = "Car1", path = "textures/Car1.png", hasAlpha = true} ::
        {name = "Car2", path = "textures/Car2.png", hasAlpha = true} ::
        {name = "Car3", path = "textures/Car3.png", hasAlpha = true} ::
        {name = "Car4", path = "textures/Car4.png", hasAlpha = true} ::
        {name = "Car5", path = "textures/Car5.png", hasAlpha = true} ::
        {name = "FroggerDead", path = "textures/FroggerDead.png", hasAlpha = true} ::
        {name = "LogStart", path = "textures/LogStart.png", hasAlpha = true} ::
        {name = "LogMiddle", path = "textures/LogMiddle.png", hasAlpha = true} ::
        {name = "LogEnd", path = "textures/LogEnd.png", hasAlpha = true} ::
        {name = "Turtle_01", path = "textures/Turtle_01.png", hasAlpha = true} ::
        {name = "Turtle_02", path = "textures/Turtle_02.png", hasAlpha = true} ::
        {name = "Turtle_03", path = "textures/Turtle_03.png", hasAlpha = true} ::
        {name = "Home", path = "textures/Home.png", hasAlpha = true} ::
        {name = "HomeFrog", path = "textures/HomeFrog.png", hasAlpha = true} ::
        {name = "Road", path = "textures/Road.png", hasAlpha = true} ::
        {name = "Water", path = "textures/Water.png", hasAlpha = true} ::
        {name = "Median", path = "textures/Median.png", hasAlpha = true} ::
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
                   Engine.Key.Up :: Engine.Key.Down :: Engine.Key.Left :: Engine.Key.Right ::
                   Engine.Key.Enter :: Engine.Key.F1 :: Nil;
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

    pub def initialTimeRemaining(): Float32 = 30.0f32

    pub def initGame(): GameState =
        let scene = FroggerScene.buildInitialScene();
        {scene = scene, gameOver = false, prevKeys = Set.empty(), lives = 3,
         homeSlotsFilled = Set.empty(), won = false, timeRemaining = initialTimeRemaining(),
         debugMode = false, debugCursor = Nil}

    // ========================================================================
    // Game Loop
    // ========================================================================

    /// デバッグモード中の入力処理（矢印キーでツリーナビゲーション、F1で終了）
    def updateDebugMode(state: GameState): GameState \ Engine.Game =
        let _ = Engine.Game.getDeltaTime();
        let currKeys = collectPressedKeys();
        let justPressed = justPressedKeys(currKeys, state#prevKeys);
        let root = state#scene;
        // F1 でデバッグモード OFF
        if (Set.memberOf(Engine.Key.F1, justPressed))
            {debugMode = false, prevKeys = currKeys | state}
        // 右キー: 兄弟ノード次へ
        else if (Set.memberOf(Engine.Key.Right, justPressed) or Set.memberOf(Engine.Key.D, justPressed))
            {debugCursor = DebugOverlay.navigateRight(state#debugCursor, root), prevKeys = currKeys | state}
        // 左キー: 兄弟ノード前へ
        else if (Set.memberOf(Engine.Key.Left, justPressed) or Set.memberOf(Engine.Key.A, justPressed))
            {debugCursor = DebugOverlay.navigateLeft(state#debugCursor, root), prevKeys = currKeys | state}
        // 下キー: 子ノードに入る
        else if (Set.memberOf(Engine.Key.Down, justPressed) or Set.memberOf(Engine.Key.S, justPressed))
            {debugCursor = DebugOverlay.navigateDown(state#debugCursor, root), prevKeys = currKeys | state}
        // 上キー: 親ノードに戻る
        else if (Set.memberOf(Engine.Key.Up, justPressed) or Set.memberOf(Engine.Key.W, justPressed))
            {debugCursor = DebugOverlay.navigateUp(state#debugCursor), prevKeys = currKeys | state}
        else
            {prevKeys = currKeys | state}

    pub def updateGame(state: GameState): GameState \ Engine.Game =
        if (state#debugMode)
            updateDebugMode(state)
        else {
            let dt = Engine.Game.getDeltaTime();
            let currKeys = collectPressedKeys();
            let justPressed = justPressedKeys(currKeys, state#prevKeys);
            // F1 でデバッグモード ON
            if (Set.memberOf(Engine.Key.F1, justPressed))
                {debugMode = true, debugCursor = Nil, prevKeys = currKeys | state}
            else if (state#gameOver or state#won) {
                // Game ended — Enter to restart, otherwise just update prevKeys
                if (Set.memberOf(Engine.Key.Enter, justPressed))
                    initGame()
                else
                    {prevKeys = currKeys | state}
            } else {
                // Normal play
                let inputState = if (FroggerScene.isPlayerDead(state#scene))
                    {prevKeys = currKeys | state}
                else {
                    {scene = match inputDirection(justPressed) {
                        case Some(dir) => FroggerScene.applyInput(dir, state#scene)
                        case None      => state#scene
                    }, prevKeys = currKeys | state}
                };
                // Physics & collision
                let physicsState = FroggerScene.stepFrame(dt, inputState);
                // Timer countdown (skip while dead)
                let timerState = if (FroggerScene.isPlayerDead(physicsState#scene))
                    physicsState
                else {
                    let newTime = physicsState#timeRemaining - dt;
                    if (newTime <= 0.0f32)
                        FroggerScene.triggerDeath({timeRemaining = 0.0f32 | physicsState})
                    else
                        {timeRemaining = newTime | physicsState}
                };
                // HUD update
                let hudScene = timerState#scene
                    |> FroggerHUD.updateLives(timerState#lives)
                    |> FroggerHUD.updateTimer(timerState#timeRemaining);
                // End-game messages
                let finalScene = if (timerState#gameOver)
                    hudScene |> FroggerHUD.showMessage("You Lost!") |> FroggerHUD.showRestart
                else if (timerState#won)
                    hudScene |> FroggerHUD.showMessage("You Won!") |> FroggerHUD.showRestart
                else hudScene;
                {scene = finalScene | timerState}
            }
        }

    pub def startGame(): GameState \ Engine.Game =
        let state = initGame();
        runLoop(state)

    /// デバッグモード時のオーバーレイを計算する
    def computeDebugOverlay(state: GameState): Option[Engine.DebugOverlay] =
        if (state#debugMode) {
            let selectedNode = DebugOverlay.nodeAtPath(state#debugCursor, state#scene);
            let gpos = DebugOverlay.globalPosAtPath(state#debugCursor, state#scene);
            match (selectedNode, gpos) {
                case (Some(node), Some(pos)) =>
                    let overlay = DebugOverlay.collectOverlay(node, pos, defaultFont());
                    let inspector = DebugOverlay.inspectorText(node, state#debugCursor, state#scene, defaultFont());
                    Some({rects = overlay#rects, labels = List.append(overlay#labels, inspector)})
                case _ => Some(DebugOverlay.empty())
            }
        } else None

    @Tailrec
    def runLoop(state: GameState): GameState \ Engine.Game =
        if (Engine.Game.shouldClose() or Engine.Game.isKeyPressed(Engine.Key.Escape)) state
        else {
            let newState = updateGame(state);
            let overlay = computeDebugOverlay(newState);
            Engine.Game.render(newState#scene, overlay);
            runLoop(newState)
        }

}
