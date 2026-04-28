// FroggerScene — root scene for Frogger

mod FroggerScene {
    pub def rootName(): String = "Root"

    pub enum Child with Eq, ToString {
        case Player
        case VehicleLanes
        case WaterLanes
        case TurtleLanes
        case HomeSlots
        case DeathTimer
        case HUD
    }

    instance SceneTree.SceneChild[Child] {
        pub def sceneName(_c: Child): String = FroggerScene.rootName()
        pub def childName(c: Child): String = match c {
            case Child.Player => FroggerPlayer.playerName()
            case Child.VehicleLanes => VehicleLane.containerName()
            case Child.WaterLanes => WaterLane.containerName()
            case Child.TurtleLanes => TurtleLane.containerName()
            case Child.HomeSlots => HomeSlot.containerName()
            case Child.DeathTimer => FroggerScene.deathTimerName()
            case Child.HUD => FroggerHUD.containerName()
        }
    }

    pub def deathTimerName(): String = "DeathTimer"

    def deathTimerWait(): Float32 = 2.0f32

    // ========================================================================
    // SceneState — FroggerScene が管理するシーン状態
    // ========================================================================

    pub type alias SceneState = {
        scene         = SceneTree.Node,
        lives         = Int32,
        timeRemaining = Float32
    }

    pub def initSceneState(): SceneState \ Fs.FileRead = {
        scene = buildInitialScene(),
        lives = 3,
        timeRemaining = Game.initialTimeRemaining()
    }

    // ========================================================================
    // Game End Conditions
    // ========================================================================

    pub def isWon(state: SceneState): Bool =
        HomeSlot.isAllFilled(state#scene)

    pub def isGameOver(state: SceneState): Bool =
        state#lives <= 0 and not isPlayerDead(state#scene)

    // ========================================================================
    // Physics Config
    // ========================================================================

    pub def physicsConfig(): SceneTree.PhysicsConfig =
        {screenSize = {x = Int32.toFloat32(Game.screenWidth()),
                       y = Int32.toFloat32(Game.screenHeight())}}

    // ========================================================================
    // Board Layout Constants
    // ========================================================================

    def screenW(): Float32 = Int32.toFloat32(Game.screenWidth())

    def homeZoneY(): Float32      = 0.0f32
    def homeZoneH(): Float32      = 64.0f32

    def waterZoneY(): Float32     = 64.0f32
    def waterZoneH(): Float32     = 384.0f32

    def medianZoneY(): Float32    = 448.0f32
    def medianZoneH(): Float32    = 64.0f32

    def roadZoneY(): Float32      = 512.0f32
    def roadZoneH(): Float32      = 320.0f32

    def startZoneY(): Float32     = 832.0f32
    def startZoneH(): Float32     = 64.0f32

    // ========================================================================
    // Player Movement Bounds
    // ========================================================================

    /// プレイヤーが移動できるグリッド座標の範囲（min, max）
    pub def playerBounds(): (Vec2D.Vec2, Vec2D.Vec2) =
        ({x = 0.0f32, y = homeZoneY()},
         {x = screenW() - tileSize(), y = startZoneY()})

    // ========================================================================
    // Zone Colors
    // ========================================================================

    def greenColor(): Engine.Color  = {r = 0.2f32, g = 0.5f32, b = 0.2f32}

    // ========================================================================
    // Helpers
    // ========================================================================

    def coloredRect(name: String, y: Float32, h: Float32, col: Engine.Color): SceneTree.Node =
        Sprite2D.init({name = name, pos = {x = 0.0f32, y = y}, size = {x = screenW(), y = h}, texture = "white"})
            |> Sprite2D.color(col)

    // 16x16 texture at 4x scale = 64px tile
    def tileSize(): Float32 = 64.0f32

    def tiledRect(name: String, y: Float32, h: Float32, texture: String): SceneTree.Node =
        Sprite2D.init({name = name, pos = {x = 0.0f32, y = y}, size = {x = screenW(), y = h}, texture = texture})
            |> Sprite2D.uv(Vec2D.zero(), {x = screenW() / tileSize(), y = h / tileSize()})

    // ========================================================================
    // Board Builder
    // ========================================================================

    pub def buildBoard(): List[SceneTree.Node] =
        coloredRect("HomeZone",   homeZoneY(),   homeZoneH(),   greenColor()) ::
        tiledRect("WaterZone",    waterZoneY(),  waterZoneH(),  "Water") ::
        tiledRect("MedianZone",   medianZoneY(), medianZoneH(), "Median") ::
        tiledRect("RoadZone",     roadZoneY(),   roadZoneH(),   "Road") ::
        coloredRect("StartZone",  startZoneY(),  startZoneH(),  greenColor()) ::
        Nil

    // ========================================================================
    // Scene Construction
    // ========================================================================

    pub def buildInitialScene(): SceneTree.Node \ Fs.FileRead =
        let deathTimer = Timer2D.init({name = deathTimerName(), waitTime = deathTimerWait(), oneShot = true});
        (buildBoard() ::: HomeSlot.buildHomeSlots() :: WaterLane.buildWaterLanes() :: TurtleLane.buildTurtleLanes() :: VehicleLane.buildVehicleLanes() :: FroggerPlayer.buildPlayer() :: deathTimer :: FroggerHUD.buildHUD() :: Nil)
            |> SceneTree.node2D(rootName(), Vec2D.zero())

    // ========================================================================
    // Input Application — delegate to FroggerPlayer
    // ========================================================================

    pub def applyInput(dir: SceneTree.Direction, scene: SceneTree.Node): SceneTree.Node =
        FroggerPlayer.applyInput(dir, scene)

    // ========================================================================
    // Death State — derived from DeathTimer running state
    // ========================================================================

    pub def isPlayerDead(scene: SceneTree.Node): Bool =
        SceneTree.isTimerRunning(SceneTree.childName(Child.DeathTimer), scene)

    // ========================================================================
    // Death Trigger — shared helper for vehicle collision and drowning
    // ========================================================================

    pub def triggerDeath(state: SceneState): SceneState =
        {scene = state#scene
            |> FroggerPlayer.showDeathSprite
            |> SceneTree.startTimer(SceneTree.childName(Child.DeathTimer)),
         lives = state#lives - 1 | state}

    // ========================================================================
    // Wrap All Lanes — vehicle, log, turtle wrapping in one pass
    // ========================================================================

    def wrapAllLanes(scene: SceneTree.Node): SceneTree.Node =
        scene
            |> VehicleLane.wrapVehicles
            |> WaterLane.wrapLogs
            |> TurtleLane.wrapTurtles

    // ========================================================================
    // Water Zone Step — platform riding (log + turtle) + drown check
    // ========================================================================

    def stepWaterZone(dt: Float32, scene: SceneTree.Node):
            {scene = SceneTree.Node, atTarget = Bool, shouldDrown = Bool} =
        let ridingScene = scene
            |> WaterLane.applyPlatformRiding(dt)
            |> TurtleLane.applyPlatformRiding(dt);
        let atTarget = FroggerPlayer.isAtTarget(ridingScene);
        let onPlatform = not Option.isEmpty(WaterLane.findOverlappingLogVelocity(ridingScene))
            or not Option.isEmpty(TurtleLane.findOverlappingTurtleVelocity(ridingScene));
        {scene = ridingScene, atTarget = atTarget,
         shouldDrown = WaterLane.shouldDrown(atTarget, onPlatform, ridingScene)}

    // ========================================================================
    // Home Slot Check — player reached home zone
    // ========================================================================

    def checkHomeSlot(atTarget: Bool, playerPos: Option[Vec2D.Vec2],
                      state: SceneState): SceneState =
        match playerPos {
            case None => state
            case Some(pos) =>
                if (not atTarget or not HomeSlot.isInHomeZone(pos#y)) state
                else match HomeSlot.tryFillSlot(pos, state#scene) {
                    case Some(filledScene) =>
                        {scene = FroggerPlayer.respawn(filledScene),
                         timeRemaining = Game.initialTimeRemaining() | state}
                    case None =>
                        triggerDeath(state)
                }
        }

    // ========================================================================
    // Frame Step (Dead) — physics + wrap + death timer timeout
    // ========================================================================

    def stepFrameDead(dt: Float32, state: SceneState): SceneState =
        let movedScene = run {
            SceneTree.stepAndCollide(state#scene, dt, physicsConfig())
        } with handler SceneTree.OnCollision {
            def bodyEntered(_name, _pos, _body, k) = k(())
            def areaEntered(_name, _pos, _body, k) = k(())
        };
        let wrappedScene = movedScene
            |> wrapAllLanes
            |> SceneTree.stepAnimations(dt);
        run {
            let s = SceneTree.stepTimers(dt, wrappedScene);
            {scene = s | state}
        } with handler SceneTree.OnTimeout {
            def timeout(name, k) =
                let st = k(());
                if (name == SceneTree.childName(Child.DeathTimer))
                    if (st#lives > 0)
                        {scene = FroggerPlayer.respawn(st#scene),
                         timeRemaining = Game.initialTimeRemaining() | st}
                    else
                        st
                else st
        }

    // ========================================================================
    // Frame Step (Alive) — player move + physics + collision + water zone
    // ========================================================================

    def stepFrameAlive(dt: Float32, state: SceneState): SceneState =
        let hitboxName = SceneTree.childName(FroggerPlayer.Child.Hitbox);
        let playerScene = FroggerPlayer.stepFrame(dt, state#scene);
        let collisionState = run {
            let s = SceneTree.stepAndCollide(playerScene, dt, physicsConfig());
            {scene = s |> wrapAllLanes |> SceneTree.stepAnimations(dt) | state}
        } with handler SceneTree.OnCollision {
            def bodyEntered(_name, _pos, _body, k) = k(())
            def areaEntered(name, _pos, body, k) =
                let st = k(());
                if (VehicleLane.isVehicleCollision(hitboxName, name, body#name)
                    and not isPlayerDead(st#scene))
                    triggerDeath(st)
                else st
        };
        // Water zone: platform riding (log + turtle) + drown check
        let water = stepWaterZone(dt, collisionState#scene);
        let playerPos = SceneTree.globalPosition(FroggerPlayer.playerName(), water#scene);
        if (water#shouldDrown and not isPlayerDead(water#scene))
            triggerDeath({scene = water#scene | collisionState})
        else
            checkHomeSlot(water#atTarget, playerPos, {scene = water#scene | collisionState})

    // ========================================================================
    // Frame Step — dispatch to dead / alive path
    // ========================================================================

    pub def stepFrame(dt: Float32, state: SceneState): SceneState =
        if (isPlayerDead(state#scene))
            stepFrameDead(dt, state)
        else
            stepFrameAlive(dt, state)

    // ========================================================================
    // stepScene — 1フレームのシーン更新を統合
    // ========================================================================

    pub def stepScene(dt: Float32, dir: Option[SceneTree.Direction],
                      state: SceneState): SceneState =
        // 1. Input application
        let inputScene = match dir {
            case Some(d) => applyInput(d, state#scene)
            case None    => state#scene
        };
        // 2. Physics & collision
        let physicsState = stepFrame(dt, {scene = inputScene | state});
        // 3. Timer countdown (skip while dead)
        let timerState = if (isPlayerDead(physicsState#scene))
            physicsState
        else {
            let newTime = physicsState#timeRemaining - dt;
            if (newTime <= 0.0f32)
                triggerDeath({timeRemaining = 0.0f32 | physicsState})
            else
                {timeRemaining = newTime | physicsState}
        };
        // 4. HUD update
        let hudScene = timerState#scene
            |> FroggerHUD.updateLives(timerState#lives)
            |> FroggerHUD.updateTimer(timerState#timeRemaining);
        // 5. End-game messages
        let finalScene = if (isGameOver(timerState))
            hudScene |> FroggerHUD.showMessage("You Lost!") |> FroggerHUD.showRestart
        else if (isWon(timerState))
            hudScene |> FroggerHUD.showMessage("You Won!") |> FroggerHUD.showRestart
        else hudScene;
        {scene = finalScene | timerState}
}
