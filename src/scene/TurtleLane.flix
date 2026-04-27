// TurtleLane — turtle lane logic for the water zone

mod TurtleLane {

    // ========================================================================
    // Lane Configuration
    // ========================================================================

    pub type alias TurtleLaneConfig = {
        laneIndex = Int32,
        speed = Float32,
        direction = Float32,
        turtleCount = Int32,
        sectionCount = Int32,
        spacing = Float32
    }

    pub def laneConfigs(): List[TurtleLaneConfig] =
        {laneIndex = 4, speed = 100.0f32, direction =  1.0f32, turtleCount = 3, sectionCount = 3, spacing = 250.0f32} ::
        {laneIndex = 5, speed = 130.0f32, direction = -1.0f32, turtleCount = 2, sectionCount = 4, spacing = 200.0f32} ::
        Nil

    // ========================================================================
    // Lane Y positions (water zone starts at 64, each lane is 64px tall)
    // ========================================================================

    pub def laneY(index: Int32): Float32 =
        WaterLane.laneY(index)

    // ========================================================================
    // Naming Helpers
    // ========================================================================

    pub def containerName(): String = "TurtleLanes"

    pub def laneName(index: Int32): String =
        "TurtleLane${index}"

    pub def sectionName(laneIdx: Int32, secIdx: Int32): String =
        "T${laneIdx}_${secIdx}"

    // ========================================================================
    // Section Size — computed from turtleCount
    // Each turtle sprite is 64×48, sections are turtleCount turtles wide
    // ========================================================================

    def turtleSpriteW(): Float32 = 64.0f32

    def turtleSpriteH(): Float32 = 48.0f32

    pub def sectionWidth(turtleCount: Int32): Float32 =
        Int32.toFloat32(turtleCount) * turtleSpriteW()

    pub def sectionSize(turtleCount: Int32): Vec2D.Vec2 =
        {x = sectionWidth(turtleCount), y = turtleSpriteH()}

    // ========================================================================
    // Wrap boundaries
    // ========================================================================

    def screenW(): Float32 = Int32.toFloat32(Game.screenWidth())

    pub def wrapMin(turtleCount: Int32): Float32 =
        -1.0f32 * sectionWidth(turtleCount) - 20.0f32

    pub def wrapMax(): Float32 = screenW() + 20.0f32

    pub def wrapX(x: Float32, direction: Float32, turtleCount: Int32): Float32 =
        if (direction < 0.0f32 and x < wrapMin(turtleCount))
            wrapMax()
        else if (direction > 0.0f32 and x > wrapMax())
            wrapMin(turtleCount)
        else
            x

    // ========================================================================
    // Initial X placement — distribute sections from the entry edge
    // ========================================================================

    pub def initialX(cfg: TurtleLaneConfig, i: Int32): Float32 =
        let fi = Int32.toFloat32(i);
        if (cfg#direction < 0.0f32)
            screenW() - cfg#spacing * fi
        else
            cfg#spacing * fi

    // ========================================================================
    // Build turtle sprites for a section (turtleCount sprites side by side)
    // ========================================================================

    def buildTurtleSprites(turtleCount: Int32): List[SceneTree.Node] =
        let spriteY = 8.0f32;
        List.range(0, turtleCount)
            |> List.map(i ->
                Sprite2D.init({name = "Sprite${i}",
                               pos = {x = Int32.toFloat32(i) * turtleSpriteW(), y = spriteY},
                               size = {x = turtleSpriteW(), y = turtleSpriteH()},
                               texture = "Turtle"}))

    // ========================================================================
    // Build a single section (Area2D + Turtle Sprites + CollisionShape)
    // ========================================================================

    def buildSection(cfg: TurtleLaneConfig, i: Int32): SceneTree.Node =
        let sprites = buildTurtleSprites(cfg#turtleCount);
        let shape = SceneTree.collisionShape2D("Shape",
                        SceneTree.CollisionShapeData.RectShape(sectionSize(cfg#turtleCount)));
        Area2D.init({name = sectionName(cfg#laneIndex, i),
                     pos = {x = initialX(cfg, i), y = 0.0f32},
                     children = List.append(sprites, shape :: Nil)})
            |> Area2D.velocity({x = cfg#speed * cfg#direction, y = 0.0f32})

    // ========================================================================
    // Build a single lane with its sections
    // ========================================================================

    def buildLane(cfg: TurtleLaneConfig): SceneTree.Node =
        List.range(0, cfg#sectionCount)
            |> List.map(i -> buildSection(cfg, i))
            |> SceneTree.node2D(laneName(cfg#laneIndex),
                                {x = 0.0f32, y = laneY(cfg#laneIndex)})

    // ========================================================================
    // Build all turtle lanes as a container Node2D
    // ========================================================================

    pub def buildTurtleLanes(): SceneTree.Node =
        laneConfigs()
            |> List.map(buildLane)
            |> SceneTree.node2D(containerName(), Vec2D.zero())

    // ========================================================================
    // Wrap sections — same pattern as WaterLane.wrapLogs
    // ========================================================================

    def wrapSection(cfg: TurtleLaneConfig, secIdx: Int32, scene: SceneTree.Node): SceneTree.Node =
        let sName = sectionName(cfg#laneIndex, secIdx);
        match SceneTree.findNode(sName, scene) {
            case Some(secNode) =>
                let pos = SceneTree.nodePosition(secNode);
                let newX = wrapX(pos#x, cfg#direction, cfg#turtleCount);
                if (newX == pos#x) scene
                else SceneTree.setNodePosition(sName, {x = newX, y = pos#y}, scene)
            case None => scene
        }

    def wrapLane(cfg: TurtleLaneConfig, scene: SceneTree.Node): SceneTree.Node =
        List.range(0, cfg#sectionCount)
            |> List.foldLeft((sc, i) -> wrapSection(cfg, i, sc), scene)

    pub def wrapTurtles(scene: SceneTree.Node): SceneTree.Node =
        List.foldLeft((sc, cfg) -> wrapLane(cfg, sc), scene, laneConfigs())

    // ========================================================================
    // Platform Overlap Check — manual AABB between player hitbox and all sections
    // Returns: Option of section velocity if player is on a turtle
    // ========================================================================

    pub def findOverlappingTurtleVelocity(scene: SceneTree.Node): Option[Vec2D.Vec2] =
        match SceneTree.globalPosition(FroggerPlayer.playerName(), scene) {
            case None => None
            case Some(playerPos) =>
                let hitboxPos = Vec2D.add(playerPos, FroggerPlayer.playerHitboxOffset());
                let hitboxSize = FroggerPlayer.playerHitboxSize();
                findFirstOverlapping(hitboxPos, hitboxSize, laneConfigs(), scene)
        }

    def findFirstOverlapping(hitboxPos: Vec2D.Vec2, hitboxSize: Vec2D.Vec2,
                             configs: List[TurtleLaneConfig], scene: SceneTree.Node): Option[Vec2D.Vec2] =
        match configs {
            case Nil => None
            case cfg :: rest =>
                match findOverlapInLane(hitboxPos, hitboxSize, cfg, scene) {
                    case Some(vel) => Some(vel)
                    case None => findFirstOverlapping(hitboxPos, hitboxSize, rest, scene)
                }
        }

    def findOverlapInLane(hitboxPos: Vec2D.Vec2, hitboxSize: Vec2D.Vec2,
                          cfg: TurtleLaneConfig, scene: SceneTree.Node): Option[Vec2D.Vec2] =
        let secSz = sectionSize(cfg#turtleCount);
        let vel = {x = cfg#speed * cfg#direction, y = 0.0f32};
        List.range(0, cfg#sectionCount)
            |> List.findMap(i ->
                match SceneTree.globalPosition(sectionName(cfg#laneIndex, i), scene) {
                    case None => None
                    case Some(secPos) =>
                        if (SceneTree.checkRectRect(hitboxPos, hitboxSize, secPos, secSz))
                            Some(vel)
                        else None
                })

    // ========================================================================
    // Apply platform riding — shift player pos + targetPos by turtle velocity * dt
    // ========================================================================

    pub def applyPlatformRiding(dt: Float32, scene: SceneTree.Node): SceneTree.Node =
        match findOverlappingTurtleVelocity(scene) {
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
}
