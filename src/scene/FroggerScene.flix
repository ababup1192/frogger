// FroggerScene — root scene for Frogger

mod FroggerScene {
    pub def rootName(): String = "Root"

    pub enum Child with Eq, ToString {
        case Player
        case VehicleLanes
    }

    instance SceneTree.SceneChild[Child] {
        pub def sceneName(_c: Child): String = FroggerScene.rootName()
        pub def childName(c: Child): String = match c {
            case Child.Player => FroggerPlayer.playerName()
            case Child.VehicleLanes => VehicleLane.containerName()
        }
    }


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
        (buildBoard() ::: VehicleLane.buildVehicleLanes() :: FroggerPlayer.buildPlayer() :: Nil)
            |> SceneTree.node2D(rootName(), Vec2D.zero())

    // ========================================================================
    // Input Application — delegate to FroggerPlayer
    // ========================================================================

    pub def applyInput(dir: SceneTree.Direction, scene: SceneTree.Node): SceneTree.Node =
        FroggerPlayer.applyInput(dir, scene)

    // ========================================================================
    // Frame Step — delegate to FroggerPlayer
    // ========================================================================

    pub def stepFrame(dt: Float32, state: Game.GameState): Game.GameState =
        {scene = state#scene
            |> VehicleLane.stepFrame(dt)
            |> FroggerPlayer.stepFrame(dt)
        | state}
}
