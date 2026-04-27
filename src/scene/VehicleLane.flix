// VehicleLane — vehicle lane logic for the road zone

mod VehicleLane {

    // ========================================================================
    // Lane Configuration
    // ========================================================================

    pub type alias LaneConfig = {
        laneIndex = Int32,
        speed = Float32,
        direction = Float32,
        texture = String,
        vehicleCount = Int32,
        spacing = Float32
    }

    pub def laneConfigs(): List[LaneConfig] =
        {laneIndex = 0, speed = 200.0f32, direction = -1.0f32, texture = "Car1", vehicleCount = 3, spacing = 100.0f32} ::
        {laneIndex = 1, speed = 250.0f32, direction =  1.0f32, texture = "Car2", vehicleCount = 4, spacing = 150.0f32} ::
        {laneIndex = 2, speed = 200.0f32, direction = -1.0f32, texture = "Car3", vehicleCount = 2, spacing = 300.0f32} ::
        {laneIndex = 3, speed = 200.0f32, direction =  1.0f32, texture = "Car4", vehicleCount = 4, spacing = 300.0f32} ::
        {laneIndex = 4, speed = 160.0f32, direction = -1.0f32, texture = "Car5", vehicleCount = 2, spacing = 230.0f32} ::
        Nil

    // ========================================================================
    // Lane Y positions (road zone starts at 512, each lane is 64px tall)
    // ========================================================================

    pub def laneY(index: Int32): Float32 =
        512.0f32 + Int32.toFloat32(index) * 64.0f32

    // ========================================================================
    // Naming Helpers
    // ========================================================================

    pub def containerName(): String = "VehicleLanes"

    pub def laneName(index: Int32): String =
        "VehicleLane${index}"

    pub def vehicleName(laneIdx: Int32, vehicleIdx: Int32): String =
        "V${laneIdx}_${vehicleIdx}"

    // ========================================================================
    // Vehicle size (matching Godot: 16x12 * 4 = 64x48)
    // ========================================================================

    def vehicleSize(): Vec2D.Vec2 = {x = 64.0f32, y = 48.0f32}

    // ========================================================================
    // Wrap boundaries — one car width buffer beyond each screen edge
    // ========================================================================

    def screenW(): Float32 = Int32.toFloat32(Game.screenWidth())

    pub def wrapMin(): Float32 = -100.0f32

    pub def wrapMax(): Float32 = screenW() + 100.0f32

    // ========================================================================
    // Initial X placement — distribute cars from the entry edge
    // ========================================================================

    pub def initialX(cfg: LaneConfig, i: Int32): Float32 =
        let fi = Int32.toFloat32(i);
        if (cfg#direction < 0.0f32)
            // Left-moving: start from right side of screen
            screenW() - cfg#spacing * fi
        else
            // Right-moving: start from left side of screen
            cfg#spacing * fi

    // ========================================================================
    // Wrap logic — direction-aware, asymmetric for 0..784 screen
    // ========================================================================

    pub def wrapX(x: Float32, direction: Float32): Float32 =
        if (direction < 0.0f32 and x < wrapMin())
            wrapMax()
        else if (direction > 0.0f32 and x > wrapMax())
            wrapMin()
        else
            x

    // ========================================================================
    // Build a single lane with its vehicles
    // ========================================================================

    def buildLane(cfg: LaneConfig): SceneTree.Node =
        List.range(0, cfg#vehicleCount)
            |> List.map(i ->
                Sprite2D.init({name = vehicleName(cfg#laneIndex, i),
                               pos = {x = initialX(cfg, i), y = 0.0f32},
                               size = vehicleSize(),
                               texture = cfg#texture}))
            |> SceneTree.node2D(laneName(cfg#laneIndex),
                                {x = 0.0f32, y = laneY(cfg#laneIndex)})

    // ========================================================================
    // Build all vehicle lanes as a container Node2D
    // ========================================================================

    pub def buildVehicleLanes(): SceneTree.Node =
        laneConfigs()
            |> List.map(buildLane)
            |> SceneTree.node2D(containerName(), Vec2D.zero())

    // ========================================================================
    // Step frame — move each vehicle and wrap at screen edges
    // ========================================================================

    def stepVehicle(dt: Float32, cfg: LaneConfig, vIdx: Int32, scene: SceneTree.Node): SceneTree.Node =
        let vName = vehicleName(cfg#laneIndex, vIdx);
        match SceneTree.findNode(vName, scene) {
            case Some(vehicle) =>
                let pos = SceneTree.nodePosition(vehicle);
                let newX = wrapX(pos#x + cfg#speed * cfg#direction * dt, cfg#direction);
                SceneTree.setNodePosition(vName, {x = newX, y = pos#y}, scene)
            case None => scene
        }

    def stepLane(dt: Float32, cfg: LaneConfig, scene: SceneTree.Node): SceneTree.Node =
        List.range(0, cfg#vehicleCount)
            |> List.foldLeft((sc, i) -> stepVehicle(dt, cfg, i, sc), scene)

    pub def stepFrame(dt: Float32, scene: SceneTree.Node): SceneTree.Node =
        List.foldLeft((sc, cfg) -> stepLane(dt, cfg, sc), scene, laneConfigs())
}
