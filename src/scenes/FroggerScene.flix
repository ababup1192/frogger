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

    pub def triggerDeath(state: Game.GameState): Game.GameState =
        {scene = state#scene
            |> FroggerPlayer.showDeathSprite
            |> SceneTree.startTimer(SceneTree.childName(Child.DeathTimer)),
         lives = state#lives - 1 | state}

    // ========================================================================
    // Home Slot Check — player reached home zone
    // ========================================================================

    def checkHomeSlot(atTarget: Bool, playerPos: Option[Vec2D.Vec2],
                      state: Game.GameState): Game.GameState =
        match playerPos {
            case None => state
            case Some(pos) =>
                if (not atTarget or not HomeSlot.isInHomeZone(pos#y)) state
                else match HomeSlot.findSlotAtPosition(state#scene, pos#x, state#homeSlotsFilled) {
                    case Some(slotIdx) =>
                        let newFilled = Set.insert(slotIdx, state#homeSlotsFilled);
                        let filledScene = state#scene |> HomeSlot.fillSlot(slotIdx);
                        let respawnedScene = FroggerPlayer.respawn(filledScene);
                        if (HomeSlot.allFilled(newFilled))
                            {scene = respawnedScene, homeSlotsFilled = newFilled, won = true,
                             timeRemaining = Game.initialTimeRemaining() | state}
                        else
                            {scene = respawnedScene, homeSlotsFilled = newFilled,
                             timeRemaining = Game.initialTimeRemaining() | state}
                    case None =>
                        // Home zone but no valid slot — death (hit wall between slots)
                        triggerDeath(state)
                }
        }

    // ========================================================================
    // Frame Step — physics (stepAndCollide) + OnCollision + OnTimeout
    // ========================================================================

    pub def stepFrame(dt: Float32, state: Game.GameState): Game.GameState =
        let hitboxName = SceneTree.childName(FroggerPlayer.Child.Hitbox);
        if (isPlayerDead(state#scene)) {
            // Death active: move vehicles/logs via physics, step timer, handle timeout
            let movedScene = run {
                SceneTree.stepAndCollide(state#scene, dt, physicsConfig())
            } with handler SceneTree.OnCollision {
                def bodyEntered(_name, _pos, _body, k) = k(())
                def areaEntered(_name, _pos, _body, k) = k(())
            };
            let wrappedScene = movedScene
                |> VehicleLane.wrapVehicles
                |> WaterLane.wrapLogs
                |> TurtleLane.wrapTurtles
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
                            {gameOver = true | st}
                    else st
            }
        } else {
            // Normal: move player, then physics step with collision detection
            let playerScene = FroggerPlayer.stepFrame(dt, state#scene);
            let collisionState = run {
                let s = SceneTree.stepAndCollide(playerScene, dt, physicsConfig());
                {scene = s |> VehicleLane.wrapVehicles |> WaterLane.wrapLogs |> TurtleLane.wrapTurtles |> SceneTree.stepAnimations(dt) | state}
            } with handler SceneTree.OnCollision {
                def bodyEntered(_name, _pos, _body, k) = k(())
                def areaEntered(name, _pos, body, k) =
                    let st = k(());
                    if (name == hitboxName and not isPlayerDead(st#scene) and
                        String.startsWith({prefix = "V"}, body#name))
                        triggerDeath(st)
                    else st
            };
            // Platform riding (log or turtle) + water zone death check
            let ridingScene = collisionState#scene
                |> WaterLane.applyPlatformRiding(dt)
                |> TurtleLane.applyPlatformRiding(dt);
            let onLog = not Option.isEmpty(WaterLane.findOverlappingLogVelocity(ridingScene));
            let onTurtle = not Option.isEmpty(TurtleLane.findOverlappingTurtleVelocity(ridingScene));
            let playerPos = SceneTree.globalPosition(FroggerPlayer.playerName(), ridingScene);
            let inWater = playerPos
                |> Option.map(pos -> WaterLane.isInWaterZone(pos#y))
                |> Option.getWithDefault(false);
            let atTarget = FroggerPlayer.isAtTarget(ridingScene);
            let drown = (atTarget and inWater and not onLog and not onTurtle) or WaterLane.isPlayerOffScreen(ridingScene);
            if (drown and not isPlayerDead(ridingScene))
                triggerDeath({scene = ridingScene | collisionState})
            else
                // Home slot check — player reached home zone
                checkHomeSlot(atTarget, playerPos, {scene = ridingScene | collisionState})
        }
}
