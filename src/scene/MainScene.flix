// MainScene — top-level scene for Dodge the Creeps

mod MainScene {
    use SceneTree.childName

    def screenW(): Float32 = Int32.toFloat32(Game.screenWidth())
    def screenH(): Float32 = Int32.toFloat32(Game.screenHeight())

    def startPos(): Vec2D.Vec2 = {x = 240.0f32, y = 450.0f32}

    // Root node name
    pub def rootName(): String = "Root"

    // ========================================================================
    // Child enum + SceneChild instance
    // ========================================================================

    pub enum Child with Eq, ToString {
        case Mobs
        case MobTimer
        case ScoreTimer
        case StartTimer
        case StartPosition
    }

    instance SceneTree.SceneChild[Child] {
        pub def sceneName(_c: Child): String = rootName()
        pub def childName(c: Child): String = match c {
            case Child.Mobs          => "Mobs"
            case Child.MobTimer      => "MobTimer"
            case Child.ScoreTimer    => "ScoreTimer"
            case Child.StartTimer    => "StartTimer"
            case Child.StartPosition => "StartPosition"
        }
    }

    def mobPathData(): SceneTree.PathData = {
        points =
            {x = 0.0f32, y = 0.0f32} ::
            {x = screenW(), y = 0.0f32} ::
            {x = screenW(), y = screenH()} ::
            {x = 0.0f32, y = screenH()} ::
            Nil
    }

    // ========================================================================
    // Build Initial Scene
    // ========================================================================

    pub def buildInitialScene(): SceneTree.Node =
        let player = PlayerScene.buildPlayer(startPos());
        let mobTimer = Timer2D.init({name = childName(Child.MobTimer), waitTime = 0.5f32, oneShot = false});
        let scoreTimer = Timer2D.init({name = childName(Child.ScoreTimer), waitTime = 1.0f32, oneShot = false});
        let startTimer = Timer2D.init({name = childName(Child.StartTimer), waitTime = 2.0f32, oneShot = true});
        let startPosition = Marker2D.init({name = childName(Child.StartPosition), pos = startPos()});
        let mobs = SceneTree.node2D(childName(Child.Mobs), Vec2D.zero(), Nil);
        let hud = HUDScene.buildHUD();
        SceneTree.node2D(rootName(), Vec2D.zero(),
            player :: mobs :: mobTimer :: scoreTimer :: startTimer :: startPosition :: hud :: Nil)
            |> PlayerScene.hidePlayer
            |> HUDScene.showStartButton

    // ========================================================================
    // Input
    // ========================================================================

    pub def applyInput(direction: Vec2D.Vec2, scene: SceneTree.Node): SceneTree.Node =
        PlayerScene.movePlayer(direction, scene)

    // ========================================================================
    // New Game
    // ========================================================================

    pub def isReadyToStart(scene: SceneTree.Node): Bool =
        HUDScene.isStartButtonVisible(scene)

    pub def newGame(state: Game.GameState): Game.GameState \ Engine.Audio =
        Engine.Audio.playAudio("music");
        {scene = state#scene
            |> removeAllMobs
            |> PlayerScene.startPlayer(startPos())
            |> SceneTree.startTimer(childName(Child.StartTimer))
            |> HUDScene.onNewGame,
         score = 0, mobCounter = 0, gameOver = false}

    // ========================================================================
    // Game Over
    // ========================================================================

    pub def gameOverState(state: Game.GameState): Game.GameState \ Engine.Audio =
        Engine.Audio.stopAudio("music");
        Engine.Audio.playAudio("death");
        {scene = state#scene
            |> SceneTree.stopTimer(childName(Child.ScoreTimer))
            |> SceneTree.stopTimer(childName(Child.MobTimer))
            |> PlayerScene.hidePlayer
            |> HUDScene.showGameOver,
         gameOver = true | state}

    // ========================================================================
    // Per-frame Step
    // ========================================================================

    pub def stepFrame(dt: Float32, state: Game.GameState): Game.GameState \ {Math.Random, Engine.Audio, Engine.Mouse} =
        let screenSize = {x = screenW(), y = screenH()};
        let config: SceneTree.PhysicsConfig = {
            screenSize = screenSize
        };
        let go = state#gameOver;
        run {
            {scene = SceneTree.stepAndCollide(state#scene, dt, config)
                |> SceneTree.stepTimers(dt)
                |> SceneTree.processScreenNotifiers(screenSize)
                |> SceneTree.stepAnimations(dt)
                |> (s -> if (go) SceneTree.processButtonClicks(s)
                         else PlayerScene.clampToScreen(screenSize, s))
             | state}
        }
        with handler SceneTree.OnCollision {
            def bodyEntered(_nodeName, _selfPos, _body, k) = k(())
            def areaEntered(nodeName, _selfPos, _body, k) =
                if (not go and nodeName == PlayerScene.playerName())
                    gameOverState(k(()))
                else
                    k(())
        }
        with handler SceneTree.OnTimeout {
            def timeout(timerName, k) =
                let st = k(());
                // MainScene's own timers
                if (timerName == childName(Child.StartTimer))
                    {scene = st#scene
                        |> SceneTree.startTimer(childName(Child.MobTimer))
                        |> SceneTree.startTimer(childName(Child.ScoreTimer))
                        |> HUDScene.hideMessage
                     | st}
                else if (timerName == childName(Child.ScoreTimer)) {
                    let newScore = st#score + 1;
                    {scene = HUDScene.updateScore(newScore, st#scene), score = newScore | st}
                }
                else if (timerName == childName(Child.MobTimer))
                    spawnMob(st)
                // HUD timers delegated to HUD
                else
                    {scene = HUDScene.handleTimeout(timerName, st#gameOver, st#scene) | st}
        }
        with handler SceneTree.OnScreenExited {
            def screenExited(bodyName, k) =
                let st = k(());
                {scene = SceneTree.filterChildren(childName(Child.Mobs),
                    child -> not (SceneTree.nodeName(child) == bodyName), st#scene) | st}
        }
        with handler SceneTree.OnButtonPressed {
            def buttonPressed(buttonName, k) =
                let st = k(());
                if (HUDScene.isStartButton(buttonName))
                    newGame(st)
                else st
        }

    // ========================================================================
    // Spawn Mob
    // ========================================================================

    def randomFloat32(): Float32 \ Math.Random =
        Float64.truncateToFloat32(Math.Random.randomFloat64())

    def spawnMob(state: Game.GameState): Game.GameState \ Math.Random =
        let mobId = state#mobCounter;
        let mobName = "Mob_${mobId}";

        // Random position on the path (0.0 to 1.0)
        let t = randomFloat32();

        // Get path data
        let (spawnPos, normal) = SceneTree.pathSample(t, mobPathData());

        // Direction: inward normal + random jitter ±45°
        let jitterRad = (randomFloat32() - 0.5f32) * (3.14159265f32 / 2.0f32);
        let direction = Vec2D.rotated(normal, jitterRad);

        let velocity = Vec2D.mul(direction, 150.0f32 + randomFloat32() * 100.0f32);
        let directionAngle = Vec2D.angle(direction);

        {scene = SceneTree.addChild(childName(Child.Mobs),
            MobScene.buildMob(mobName, spawnPos, velocity, directionAngle), state#scene),
         mobCounter = mobId + 1 | state}

    // ========================================================================
    // Remove all mobs
    // ========================================================================

    def removeAllMobs(scene: SceneTree.Node): SceneTree.Node =
        SceneTree.filterChildren(childName(Child.Mobs), _ -> false, scene)

}
