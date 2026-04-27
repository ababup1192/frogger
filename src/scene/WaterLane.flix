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
    // Log Size — computed from segments count
    // total width = 64 (Start) + segments * 64 (Middle) + 64 (End)
    // ========================================================================

    def segmentSize(): Float32 = 64.0f32

    pub def logWidth(segments: Int32): Float32 =
        (Int32.toFloat32(segments) + 2.0f32) * segmentSize()

    pub def logSize(segments: Int32): Vec2D.Vec2 =
        {x = logWidth(segments), y = 48.0f32}

    // ========================================================================
    // Wrap boundaries
    // ========================================================================

    def screenW(): Float32 = Int32.toFloat32(Game.screenWidth())

    pub def wrapMin(segments: Int32): Float32 =
        -1.0f32 * logWidth(segments) - 20.0f32

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
    // Build log sprites (LogStart + LogMiddle*n + LogEnd)
    // ========================================================================

    def buildLogSprites(segments: Int32): List[SceneTree.Node] =
        let spriteH = 48.0f32;
        let spriteY = 8.0f32;
        let startSprite = Sprite2D.init({name = "SpriteStart",
                                         pos = {x = 0.0f32, y = spriteY},
                                         size = {x = segmentSize(), y = spriteH},
                                         texture = "LogStart"});
        let midSprites = List.range(0, segments)
            |> List.map(i ->
                Sprite2D.init({name = "SpriteMid${i}",
                               pos = {x = segmentSize() + Int32.toFloat32(i) * segmentSize(), y = spriteY},
                               size = {x = segmentSize(), y = spriteH},
                               texture = "LogMiddle"}));
        let endSprite = Sprite2D.init({name = "SpriteEnd",
                                       pos = {x = segmentSize() + Int32.toFloat32(segments) * segmentSize(), y = spriteY},
                                       size = {x = segmentSize(), y = spriteH},
                                       texture = "LogEnd"});
        startSprite :: List.append(midSprites, endSprite :: Nil)

    // ========================================================================
    // Build a single log (Area2D + Sprites + CollisionShape)
    // ========================================================================

    def buildLog(cfg: LogLaneConfig, i: Int32): SceneTree.Node =
        let sprites = buildLogSprites(cfg#segments);
        let shape = SceneTree.collisionShape2D("Shape",
                        SceneTree.CollisionShapeData.RectShape(logSize(cfg#segments)));
        Area2D.init({name = logName(cfg#laneIndex, i),
                     pos = {x = initialX(cfg, i), y = 0.0f32},
                     children = List.append(sprites, shape :: Nil)})
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
        let lName = logName(cfg#laneIndex, logIdx);
        match SceneTree.findNode(lName, scene) {
            case Some(logNode) =>
                let pos = SceneTree.nodePosition(logNode);
                let newX = wrapX(pos#x, cfg#direction, cfg#segments);
                if (newX == pos#x) scene
                else SceneTree.setNodePosition(lName, {x = newX, y = pos#y}, scene)
            case None => scene
        }

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
        match SceneTree.globalPosition(FroggerPlayer.playerName(), scene) {
            case None => None
            case Some(playerPos) =>
                let hitboxPos = Vec2D.add(playerPos, FroggerPlayer.playerHitboxOffset());
                let hitboxSize = FroggerPlayer.playerHitboxSize();
                findFirstOverlapping(hitboxPos, hitboxSize, laneConfigs(), scene)
        }

    def findFirstOverlapping(hitboxPos: Vec2D.Vec2, hitboxSize: Vec2D.Vec2,
                             configs: List[LogLaneConfig], scene: SceneTree.Node): Option[Vec2D.Vec2] =
        match configs {
            case Nil => None
            case cfg :: rest =>
                match findOverlapInLane(hitboxPos, hitboxSize, cfg, scene) {
                    case Some(vel) => Some(vel)
                    case None => findFirstOverlapping(hitboxPos, hitboxSize, rest, scene)
                }
        }

    def findOverlapInLane(hitboxPos: Vec2D.Vec2, hitboxSize: Vec2D.Vec2,
                          cfg: LogLaneConfig, scene: SceneTree.Node): Option[Vec2D.Vec2] =
        let logSz = logSize(cfg#segments);
        let vel = {x = cfg#speed * cfg#direction, y = 0.0f32};
        List.range(0, cfg#logCount)
            |> List.findMap(i ->
                match SceneTree.globalPosition(logName(cfg#laneIndex, i), scene) {
                    case None => None
                    case Some(logPos) =>
                        if (SceneTree.checkRectRect(hitboxPos, hitboxSize, logPos, logSz))
                            Some(vel)
                        else None
                })

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

    pub def shouldDrown(scene: SceneTree.Node): Bool =
        let inWater = SceneTree.globalPosition(FroggerPlayer.playerName(), scene)
            |> Option.map(pos -> isInWaterZone(pos#y))
            |> Option.getWithDefault(false);
        (inWater and Option.isEmpty(findOverlappingLogVelocity(scene))) or isPlayerOffScreen(scene)
}
