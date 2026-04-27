// FroggerScene — root scene for Frogger

mod FroggerScene {
    pub def rootName(): String = "Root"

    pub enum Child with Eq, ToString {
        case Player
        case VehicleLanes
        case WaterLanes
        case TurtleLanes
        case DeathTimer
    }

    instance SceneTree.SceneChild[Child] {
        pub def sceneName(_c: Child): String = FroggerScene.rootName()
        pub def childName(c: Child): String = match c {
            case Child.Player => FroggerPlayer.playerName()
            case Child.VehicleLanes => VehicleLane.containerName()
            case Child.WaterLanes => WaterLane.containerName()
            case Child.TurtleLanes => TurtleLane.containerName()
            case Child.DeathTimer => FroggerScene.deathTimerName()
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
    // Zone Colors
    // ========================================================================

    def greenColor(): Engine.Color  = {r = 0.2f32, g = 0.5f32, b = 0.2f32}
    def blueColor(): Engine.Color   = {r = 0.0f32, g = 0.2f32, b = 0.6f32}
    def darkGrayColor(): Engine.Color = {r = 0.15f32, g = 0.15f32, b = 0.15f32}

    // ========================================================================
    // Helpers
    // ========================================================================

    def coloredRect(name: String, y: Float32, h: Float32, col: Engine.Color): SceneTree.Node =
        Sprite2D.init({name = name, pos = {x = 0.0f32, y = y}, size = {x = screenW(), y = h}, texture = "white"})
            |> Sprite2D.color(col)

    // ========================================================================
    // Board Builder
    // ========================================================================

    pub def buildBoard(): List[SceneTree.Node] =
        coloredRect("HomeZone",   homeZoneY(),   homeZoneH(),   greenColor()) ::
        coloredRect("WaterZone",  waterZoneY(),  waterZoneH(),  blueColor()) ::
        coloredRect("MedianZone", medianZoneY(), medianZoneH(), greenColor()) ::
        coloredRect("RoadZone",   roadZoneY(),   roadZoneH(),   darkGrayColor()) ::
        coloredRect("StartZone",  startZoneY(),  startZoneH(),  greenColor()) ::
        Nil

    // ========================================================================
    // Scene Construction
    // ========================================================================

    pub def buildInitialScene(): SceneTree.Node =
        let deathTimer = Timer2D.init({name = deathTimerName(), waitTime = deathTimerWait(), oneShot = true});
        (buildBoard() ::: WaterLane.buildWaterLanes() :: TurtleLane.buildTurtleLanes() :: VehicleLane.buildVehicleLanes() :: FroggerPlayer.buildPlayer() :: deathTimer :: Nil)
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

    def triggerDeath(state: Game.GameState): Game.GameState =
        {scene = state#scene
            |> FroggerPlayer.showDeathSprite
            |> SceneTree.startTimer(SceneTree.childName(Child.DeathTimer)),
         lives = state#lives - 1 | state}

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
                |> TurtleLane.wrapTurtles;
            run {
                let s = SceneTree.stepTimers(dt, wrappedScene);
                {scene = s | state}
            } with handler SceneTree.OnTimeout {
                def timeout(name, k) =
                    let st = k(());
                    if (name == SceneTree.childName(Child.DeathTimer))
                        if (st#lives > 0)
                            {scene = FroggerPlayer.respawn(st#scene) | st}
                        else
                            {gameOver = true | st}
                    else st
            }
        } else {
            // Normal: move player, then physics step with collision detection
            let playerScene = FroggerPlayer.stepFrame(dt, state#scene);
            let collisionState = run {
                let s = SceneTree.stepAndCollide(playerScene, dt, physicsConfig());
                {scene = s |> VehicleLane.wrapVehicles |> WaterLane.wrapLogs |> TurtleLane.wrapTurtles | state}
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
            let inWater = SceneTree.globalPosition(FroggerPlayer.playerName(), ridingScene)
                |> Option.map(pos -> WaterLane.isInWaterZone(pos#y))
                |> Option.getWithDefault(false);
            let atTarget = FroggerPlayer.isAtTarget(ridingScene);
            let drown = (atTarget and inWater and not onLog and not onTurtle) or WaterLane.isPlayerOffScreen(ridingScene);
            if (drown and not isPlayerDead(ridingScene))
                triggerDeath({scene = ridingScene | collisionState})
            else {scene = ridingScene | collisionState}
        }
}
