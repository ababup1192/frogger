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

    pub def playerName(): String = "Player"

    /// プレイヤーの初期スポーン位置
    pub def startPos(): Vec2D.Vec2 = {x = 384.0f32, y = 832.0f32}

    // ========================================================================
    // PlayerConfig — シーンツリー上のプレイヤーノードからプロパティを取得
    // ========================================================================

    pub type alias PlayerConfig = {
        cellSize  = Float32,
        moveSpeed = Float32
    }

    /// シーン内のプレイヤーノードから設定を取り出す（純粋関数）
    pub def loadConfig(scene: SceneTree.Node): PlayerConfig =
        let config = forM (
            player <- SceneTree.findNode(playerName(), scene);
            cbd    <- SceneTree.characterBodyData(player);
            asd    <- SceneTree.findAnimatedSpriteData(SceneTree.childName(Child.Sprite), player)
        ) yield {cellSize = asd#size#x, moveSpeed = cbd#moveSpeed};
        match config {
            case Some(c) => c
            case None => bug!("Player config extraction failed")
        }

    /// プレイヤーのスプライト中心座標を返す（プラットフォーム乗り判定用）
    pub def playerCenter(pos: Vec2D.Vec2, config: PlayerConfig): Vec2D.Vec2 =
        {x = pos#x + config#cellSize / 2.0f32, y = pos#y + config#cellSize / 2.0f32}

    // ========================================================================
    // Node Builder
    // ========================================================================

    /// シーンファイルからプレイヤーノードを構築する
    pub def buildPlayer(): SceneTree.Node \ Fs.FileRead =
        SceneLoader.loadScene("src/scenes/FroggerPlayer.scene.json")

    // ========================================================================
    // Movement — Compute New Target (pure)
    // ========================================================================

    pub def computeNewTarget(dir: SceneTree.Direction, currentTarget: Vec2D.Vec2, config: PlayerConfig): Vec2D.Vec2 =
        let delta = Vec2D.mul(SceneTree.directionToVec(dir), config#cellSize);
        let raw = Vec2D.add(currentTarget, delta);
        let (minB, maxB) = FroggerScene.playerBounds();
        Vec2D.clamp(raw, minB, maxB)

    // ========================================================================
    // Input Application — update targetPos on CharacterBody + rotate sprite
    // ========================================================================

    pub def applyInput(dir: SceneTree.Direction, scene: SceneTree.Node): SceneTree.Node =
        let config = loadConfig(scene);
        scene
            |> SceneTree.updateCharacterBody(playerName(), cbd ->
                {targetPos = computeNewTarget(dir, cbd#targetPos, config) | cbd})
            |> SceneTree.updateChildAnimatedSprite(playerName(), asd ->
                {rotation = SceneTree.directionToRotation(dir) | asd})

    // ========================================================================
    // Death & Respawn
    // ========================================================================

    pub def showDeathSprite(scene: SceneTree.Node): SceneTree.Node =
        SceneTree.updateChildAnimatedSprite(playerName(),
            AnimatedSprite2D.switchAnimation("dead", false), scene)

    pub def respawn(scene: SceneTree.Node): SceneTree.Node =
        let sp = startPos();
        scene
            |> SceneTree.setNodePosition(playerName(), sp)
            |> SceneTree.updateCharacterBody(playerName(), cbd -> {targetPos = sp | cbd})
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
