// WaterLane — log lane logic for the water zone

mod WaterLane {

    // ========================================================================
    // Lane Configuration
    // ========================================================================

    pub type alias LogLaneConfig = {
        laneIndex = Int32,
        speed = Float32,
        direction = Float32,
        segments = Int32,
        logCount = Int32,
        spacing = Float32
    }

    pub def laneConfigs(): List[LogLaneConfig] =
        {laneIndex = 0, speed = 120.0f32, direction =  1.0f32, segments = 1, logCount = 3, spacing = 250.0f32} ::
        {laneIndex = 1, speed =  80.0f32, direction = -1.0f32, segments = 2, logCount = 2, spacing = 350.0f32} ::
        {laneIndex = 2, speed = 150.0f32, direction =  1.0f32, segments = 0, logCount = 4, spacing = 200.0f32} ::
        {laneIndex = 3, speed = 100.0f32, direction = -1.0f32, segments = 1, logCount = 3, spacing = 280.0f32} ::
        Nil

    // ========================================================================
    // Lane Y positions (water zone starts at 64, each lane is 64px tall)
    // ========================================================================

    pub def laneY(index: Int32): Float32 =
        64.0f32 + Int32.toFloat32(index) * 64.0f32

    // ========================================================================
    // Naming Helpers
    // ========================================================================

    pub def containerName(): String = "WaterLanes"

    pub def laneName(index: Int32): String =
        "WaterLane${index}"

    pub def logName(laneIdx: Int32, logIdx: Int32): String =
        "L${laneIdx}_${logIdx}"

    // ========================================================================
    // Wrap boundaries
    // ========================================================================

    def screenW(): Float32 = Int32.toFloat32(Game.screenWidth())

    pub def wrapMin(segments: Int32): Float32 =
        -1.0f32 * Log.width(segments) - 20.0f32

    pub def wrapMax(): Float32 = screenW() + 20.0f32

    pub def wrapX(x: Float32, direction: Float32, segments: Int32): Float32 =
        if (direction < 0.0f32 and x < wrapMin(segments))
            wrapMax()
        else if (direction > 0.0f32 and x > wrapMax())
            wrapMin(segments)
        else
            x

    // ========================================================================
    // Initial X placement — distribute logs from the entry edge
    // ========================================================================

    pub def initialX(cfg: LogLaneConfig, i: Int32): Float32 =
        let fi = Int32.toFloat32(i);
        if (cfg#direction < 0.0f32)
            screenW() - cfg#spacing * fi
        else
            cfg#spacing * fi

    // ========================================================================
    // Build a single log — delegate to Log.build
    // ========================================================================

    def buildLog(cfg: LogLaneConfig, i: Int32): SceneTree.Node =
        Log.build(logName(cfg#laneIndex, i),
                  {x = initialX(cfg, i), y = 0.0f32},
                  cfg#segments)
            |> Area2D.velocity({x = cfg#speed * cfg#direction, y = 0.0f32})

    // ========================================================================
    // Build a single lane with its logs
    // ========================================================================

    def buildLane(cfg: LogLaneConfig): SceneTree.Node =
        List.range(0, cfg#logCount)
            |> List.map(i -> buildLog(cfg, i))
            |> SceneTree.node2D(laneName(cfg#laneIndex),
                                {x = 0.0f32, y = laneY(cfg#laneIndex)})

    // ========================================================================
    // Build all water lanes as a container Node2D
    // ========================================================================

    pub def buildWaterLanes(): SceneTree.Node =
        laneConfigs()
            |> List.map(buildLane)
            |> SceneTree.node2D(containerName(), Vec2D.zero())

    // ========================================================================
    // Wrap logs — same pattern as VehicleLane.wrapVehicles
    // ========================================================================

    def wrapLog(cfg: LogLaneConfig, logIdx: Int32, scene: SceneTree.Node): SceneTree.Node =
        scene |> SceneTree.updateNodePosition(logName(cfg#laneIndex, logIdx), pos ->
            {x = wrapX(pos#x, cfg#direction, cfg#segments), y = pos#y})

    def wrapLane(cfg: LogLaneConfig, scene: SceneTree.Node): SceneTree.Node =
        List.range(0, cfg#logCount)
            |> List.foldLeft((sc, i) -> wrapLog(cfg, i, sc), scene)

    pub def wrapLogs(scene: SceneTree.Node): SceneTree.Node =
        List.foldLeft((sc, cfg) -> wrapLane(cfg, sc), scene, laneConfigs())

    // ========================================================================
    // Water Zone Detection
    // ========================================================================

    pub def waterZoneMinY(): Float32 = 64.0f32

    pub def waterZoneMaxY(): Float32 = 448.0f32

    pub def isInWaterZone(playerY: Float32): Bool =
        playerY >= waterZoneMinY() and playerY < waterZoneMaxY()

    // ========================================================================
    // Platform Overlap Check — manual AABB between player hitbox and all logs
    // Returns: Option of log velocity if player is on a log
    // ========================================================================

    pub def findOverlappingLogVelocity(scene: SceneTree.Node): Option[Vec2D.Vec2] =
        SceneTree.globalPosition(FroggerPlayer.playerName(), scene)
            |> Option.flatMap(playerPos ->
                let config = FroggerPlayer.loadConfig(scene);
                findFirstOverlapping(FroggerPlayer.playerCenter(playerPos, config), laneConfigs(), scene))

    def findFirstOverlapping(center: Vec2D.Vec2,
                             configs: List[LogLaneConfig], scene: SceneTree.Node): Option[Vec2D.Vec2] =
        match configs {
            case Nil => None
            case cfg :: rest =>
                match findOverlapInLane(center, cfg, scene) {
                    case Some(vel) => Some(vel)
                    case None => findFirstOverlapping(center, rest, scene)
                }
        }

    def findOverlapInLane(center: Vec2D.Vec2,
                          cfg: LogLaneConfig, scene: SceneTree.Node): Option[Vec2D.Vec2] =
        let logSz = Log.size(cfg#segments);
        let vel = {x = cfg#speed * cfg#direction, y = 0.0f32};
        List.range(0, cfg#logCount)
            |> List.findMap(i ->
                SceneTree.globalPosition(logName(cfg#laneIndex, i), scene)
                    |> Option.flatMap(logPos ->
                        if (SceneTree.checkPointInRect(center, logPos, logSz))
                            Some(vel)
                        else None))

    // ========================================================================
    // Apply platform riding — shift player pos + targetPos by log velocity * dt
    // ========================================================================

    pub def applyPlatformRiding(dt: Float32, scene: SceneTree.Node): SceneTree.Node =
        match findOverlappingLogVelocity(scene) {
            case None => scene
            case Some(vel) =>
                let dx = vel#x * dt;
                match SceneTree.globalPosition(FroggerPlayer.playerName(), scene) {
                    case None => scene
                    case Some(playerPos) =>
                        let newPos = {x = playerPos#x + dx, y = playerPos#y};
                        scene
                            |> SceneTree.setNodePosition(FroggerPlayer.playerName(), newPos)
                            |> SceneTree.updateCharacterBody(FroggerPlayer.playerName(),
                                cbd -> {targetPos = {x = cbd#targetPos#x + dx, y = cbd#targetPos#y} | cbd})
                }
        }

    // ========================================================================
    // Screen-edge death check — log carried player off screen
    // ========================================================================

    pub def isPlayerOffScreen(scene: SceneTree.Node): Bool =
        match SceneTree.globalPosition(FroggerPlayer.playerName(), scene) {
            case None => false
            case Some(pos) => pos#x < -32.0f32 or pos#x > screenW() + 32.0f32
        }

    // ========================================================================
    // Drown Check — player is in water without a log, or carried off screen
    // ========================================================================

    pub def shouldDrown(atTarget: Bool, onPlatform: Bool, scene: SceneTree.Node): Bool =
        let inWater = SceneTree.globalPosition(FroggerPlayer.playerName(), scene)
            |> Option.map(pos -> isInWaterZone(pos#y))
            |> Option.getWithDefault(false);
        (atTarget and inWater and not onPlatform) or isPlayerOffScreen(scene)
}
