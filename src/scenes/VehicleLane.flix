// VehicleLane — vehicle lane logic for the road zone

mod VehicleLane {

    // ========================================================================
    // Lane Configuration
    // ========================================================================

    /// ラップ処理に必要なレーン情報
    pub type alias LaneConfig = {
        laneIndex = Int32,
        speed = Float32,
        direction = Float32,
        texture = String,
        vehicleCount = Int32,
        spacing = Float32
    }

    /// シーンツリーから各レーンの設定を抽出する（ラップ処理用）
    pub def loadLaneConfigs(scene: SceneTree.Node): List[LaneConfig] =
        match SceneTree.findNode(containerName(), scene) {
            case None => Nil
            case Some(container) =>
                extractLaneConfigs(SceneTree.nodeChildren(container), 0)
        }

    /// レーンノードのリストから LaneConfig を再帰的に構築する
    def extractLaneConfigs(lanes: List[SceneTree.Node], idx: Int32): List[LaneConfig] =
        match lanes {
            case Nil => Nil
            case lane :: rest =>
                let children = SceneTree.nodeChildren(lane);
                let vehicleCount = List.length(children);
                let (speed, direction) = match List.head(children) {
                    case Some(vehicle) => match SceneTree.nodeKind(vehicle) {
                        case SceneTree.NodeKind.Area(ad) =>
                            (Float32.abs(ad#velocity#x),
                             if (ad#velocity#x < 0.0f32) -1.0f32 else 1.0f32)
                        case _ => (0.0f32, 1.0f32)
                    }
                    case None => (0.0f32, 1.0f32)
                };
                let texture = match List.head(children) {
                    case Some(vehicle) =>
                        match SceneTree.findSpriteData("Sprite", vehicle) {
                            case Some(sd) => sd#texture
                            case None     => ""
                        }
                    case None => ""
                };
                let cfg: LaneConfig = {
                    laneIndex = idx, speed = speed, direction = direction,
                    texture = texture, vehicleCount = vehicleCount, spacing = 0.0f32
                };
                cfg :: extractLaneConfigs(rest, idx + 1)
        }

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

    pub def isVehicle(name: String): Bool =
        String.startsWith({prefix = "V"}, name)

    /// プレイヤーの Hitbox と車両の衝突かどうかを判定する
    pub def isVehicleCollision(hitboxName: String, areaName: String, bodyName: String): Bool =
        areaName == hitboxName and isVehicle(bodyName)

    // ========================================================================
    // Wrap boundaries — one car width buffer beyond each screen edge
    // ========================================================================

    def screenW(): Float32 = Int32.toFloat32(Game.screenWidth())

    pub def wrapMin(): Float32 = -100.0f32

    pub def wrapMax(): Float32 = screenW() + 100.0f32

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
    // Build all vehicle lanes from JSON scene file
    // ========================================================================

    /// 全車両レーンを JSON シーンファイルから構築する
    pub def buildVehicleLanes(): SceneTree.Node \ Fs.FileRead =
        SceneLoader.loadScene("src/scenes/VehicleLane.scene.json")

    // ========================================================================
    // Wrap vehicles — apply screen-edge wrapping (movement handled by engine)
    // ========================================================================

    def wrapVehicle(cfg: LaneConfig, vehicleIdx: Int32, scene: SceneTree.Node): SceneTree.Node =
        scene |> SceneTree.updateNodePosition(vehicleName(cfg#laneIndex, vehicleIdx), pos ->
            {x = wrapX(pos#x, cfg#direction), y = pos#y})

    def wrapLane(cfg: LaneConfig, scene: SceneTree.Node): SceneTree.Node =
        List.range(0, cfg#vehicleCount)
            |> List.foldLeft((sc, i) -> wrapVehicle(cfg, i, sc), scene)

    /// 設定リストに基づいて全レーンの車両をラップする
    pub def wrapVehicles(configs: List[LaneConfig], scene: SceneTree.Node): SceneTree.Node =
        List.foldLeft((sc, cfg) -> wrapLane(cfg, sc), scene, configs)
}
