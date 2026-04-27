// FroggerPlayer — player node and movement logic

mod FroggerPlayer {

    pub enum Child with Eq, ToString {
        case Sprite
        case Hitbox
    }

    instance SceneTree.SceneChild[Child] {
        pub def sceneName(_c: Child): String = FroggerPlayer.playerName()
        pub def childName(c: Child): String = match c {
            case Child.Sprite => "Sprite"
            case Child.Hitbox => "Hitbox"
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

    pub def playerHitboxSize(): Vec2D.Vec2 = {x = 32.0f32, y = 24.0f32}

    pub def playerHitboxOffset(): Vec2D.Vec2 = {x = 16.0f32, y = 20.0f32}

    /// プレイヤーのスプライト中心座標を返す（プラットフォーム乗り判定用）
    pub def playerCenter(pos: Vec2D.Vec2): Vec2D.Vec2 =
        {x = pos#x + cellSize() / 2.0f32, y = pos#y + cellSize() / 2.0f32}

    // ========================================================================
    // Node Builder
    // ========================================================================

    def playerAnimations(): Map[String, SceneTree.AnimationEntry] =
        Map.empty()
            |> Map.insert("idle", {frames = "FroggerIdle" :: "FroggerLeap" :: Nil})
            |> Map.insert("dead", {frames = "FroggerDead" :: Nil})

    pub def buildPlayer(): SceneTree.Node =
        let sprite = AnimatedSprite2D.init({name = SceneTree.childName(Child.Sprite), pos = Vec2D.zero(),
                                            size = {x = cellSize(), y = cellSize()},
                                            animations = playerAnimations(),
                                            initialAnimation = "idle"})
            |> AnimatedSprite2D.fps(4.0f32);
        let hitboxShape = RectShape2D.init({name = "Shape", size = playerHitboxSize()});
        let hitbox = Area2D.init({name = SceneTree.childName(Child.Hitbox),
                                  pos = playerHitboxOffset(),
                                  children = hitboxShape :: Nil});
        CharacterBody2D.init({name = playerName(), pos = startPos(),
                              children = sprite :: hitbox :: Nil})
            |> CharacterBody2D.moveSpeed(moveSpeed())

    // ========================================================================
    // Movement — Compute New Target (pure)
    // ========================================================================

    pub def computeNewTarget(dir: SceneTree.Direction, currentTarget: Vec2D.Vec2): Vec2D.Vec2 =
        let delta = Vec2D.mul(SceneTree.directionToVec(dir), cellSize());
        let raw = Vec2D.add(currentTarget, delta);
        Vec2D.clamp(raw, minBound(), maxBound())

    // ========================================================================
    // Input Application — update targetPos on CharacterBody + rotate sprite
    // ========================================================================

    pub def applyInput(dir: SceneTree.Direction, scene: SceneTree.Node): SceneTree.Node =
        scene
            |> SceneTree.updateCharacterBody(playerName(), cbd ->
                {targetPos = computeNewTarget(dir, cbd#targetPos) | cbd})
            |> SceneTree.updateChildAnimatedSprite(playerName(), asd ->
                {rotation = SceneTree.directionToRotation(dir) | asd})

    // ========================================================================
    // Death & Respawn
    // ========================================================================

    pub def showDeathSprite(scene: SceneTree.Node): SceneTree.Node =
        SceneTree.updateChildAnimatedSprite(playerName(),
            AnimatedSprite2D.switchAnimation("dead", false), scene)

    pub def respawn(scene: SceneTree.Node): SceneTree.Node =
        scene
            |> SceneTree.setNodePosition(playerName(), startPos())
            |> SceneTree.updateCharacterBody(playerName(), cbd -> {targetPos = startPos() | cbd})
            |> SceneTree.updateChildAnimatedSprite(playerName(),
                AnimatedSprite2D.switchAnimation("idle", true))

    // ========================================================================
    // Movement State Query
    // ========================================================================

    pub def isAtTarget(scene: SceneTree.Node): Bool =
        match SceneTree.findNode(playerName(), scene) {
            case Some(node) =>
                match SceneTree.characterBodyData(node) {
                    case Some(cbd) => Vec2D.isZeroApprox(Vec2D.sub(cbd#targetPos, SceneTree.nodePosition(node)))
                    case None => true
                }
            case None => true
        }

    // ========================================================================
    // Frame Step — engine handles moveToward automatically
    // ========================================================================

    pub def stepFrame(dt: Float32, scene: SceneTree.Node): SceneTree.Node =
        SceneTree.stepCharacterBodies(dt, scene)
}
