// FroggerScene — root scene for Frogger

mod FroggerScene {
    pub def rootName(): String = "Root"

    pub enum Child with Eq, ToString {
        case Player
        case PlayerTarget
    }

    instance SceneTree.SceneChild[Child] {
        pub def sceneName(_c: Child): String = FroggerScene.rootName()
        pub def childName(c: Child): String = match c {
            case Child.Player       => FroggerPlayer.playerName()
            case Child.PlayerTarget => "PlayerTarget"
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
        let board = buildBoard();
        let player = FroggerPlayer.buildPlayer();
        let target = Marker2D.init({name = SceneTree.childName(Child.PlayerTarget), pos = FroggerPlayer.startPos()});
        SceneTree.node2D(rootName(), Vec2D.zero(),
            List.append(board, player :: target :: Nil))

    // ========================================================================
    // Input Application
    // ========================================================================

    pub def applyInput(dir: Option[SceneTree.Direction], scene: SceneTree.Node): SceneTree.Node =
        let name = SceneTree.childName(Child.PlayerTarget);
        match dir {
            case Some(d) =>
                let targetPos = SceneTree.globalPosition(name, scene)
                    |> Option.getWithDefault(FroggerPlayer.startPos());
                let newTarget = FroggerPlayer.computeNewTarget(d, targetPos);
                SceneTree.setNodePosition(name, newTarget, scene)
            case None => scene
        }

    // ========================================================================
    // Frame Step
    // ========================================================================

    pub def stepFrame(dt: Float32, state: Game.GameState): Game.GameState =
        let targetPos = SceneTree.globalPosition(SceneTree.childName(Child.PlayerTarget), state#scene)
            |> Option.getWithDefault(FroggerPlayer.startPos());
        let newScene = FroggerPlayer.stepPlayer(dt, targetPos, state#scene);
        {scene = newScene | state}
}
