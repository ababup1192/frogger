// FroggerPlayer — player node and movement logic

mod FroggerPlayer {

    pub enum Child with Eq, ToString {
        case Sprite
    }

    instance SceneTree.SceneChild[Child] {
        pub def sceneName(_c: Child): String = FroggerPlayer.playerName()
        pub def childName(c: Child): String = match c {
            case Child.Sprite => "Sprite"
        }
    }

    // ========================================================================
    // Constants
    // ========================================================================

    pub def cellSize(): Float32 = 64.0f32

    pub def startPos(): Vec2D.Vec2 = {x = 384.0f32, y = 832.0f32}

    pub def moveSpeed(): Float32 = 512.0f32

    def minBound(): Vec2D.Vec2 = {x = 0.0f32, y = 0.0f32}

    def maxBound(): Vec2D.Vec2 = {x = 720.0f32, y = 832.0f32}

    pub def playerName(): String = "Player"

    // ========================================================================
    // Node Builder
    // ========================================================================

    pub def buildPlayer(): SceneTree.Node =
        let sprite = Sprite2D.init({name = SceneTree.childName(Child.Sprite), pos = Vec2D.zero(),
                                    size = {x = cellSize(), y = cellSize()},
                                    texture = "FroggerIdle"});
        SceneTree.node2D(playerName(), startPos(), sprite :: Nil)

    // ========================================================================
    // Movement — Compute New Target (pure)
    // ========================================================================

    pub def computeNewTarget(dir: SceneTree.Direction, currentTarget: Vec2D.Vec2): Vec2D.Vec2 =
        let delta = Vec2D.mul(SceneTree.directionToVec(dir), cellSize());
        let raw = Vec2D.add(currentTarget, delta);
        Vec2D.clamp(raw, minBound(), maxBound())

    // ========================================================================
    // Movement — Step Player (lerp toward target, pure)
    // ========================================================================

    pub def stepPlayer(dt: Float32, targetPos: Vec2D.Vec2, scene: SceneTree.Node): SceneTree.Node =
        let currentPos = SceneTree.globalPosition(playerName(), scene)
            |> Option.getWithDefault(startPos());
        let leapedPos = Vec2D.moveToward(currentPos, targetPos, moveSpeed() * dt);
        SceneTree.setNodePosition(playerName(), leapedPos, scene)
}
