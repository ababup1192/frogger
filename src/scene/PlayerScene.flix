// PlayerScene — Dodge the Creeps player (Area2D-based)

mod PlayerScene {
    use PlayerScene.playerSpeed
    use AnimatedSprite2D.{ animation, flipH, flipV, fps, play, stop }
    pub def playerName(): String = "Player"
    pub def playerSpeed(): Float32 = 400.0f32
    pub def playerSize(): Vec2D.Vec2 = {x = 54.0f32, y = 67.5f32}

    // ========================================================================
    // Child enum + SceneChild instance
    // ========================================================================

    pub enum Child with Eq, ToString {
        case Sprite
        case Shape
    }

    instance SceneTree.SceneChild[Child] {
        pub def sceneName(_c: Child): String = playerName()
        pub def childName(c: Child): String = match c {
            case Child.Sprite => "Sprite"
            case Child.Shape  => "Shape"
        }
    }

    // ========================================================================
    // Animation Definitions
    // ========================================================================

    pub def playerAnimations(): Map[String, SceneTree.AnimationEntry] =
        Map.insert("walk", {frames = "playerGrey_walk1" :: "playerGrey_walk2" :: Nil},
        Map.insert("up", {frames = "playerGrey_up1" :: "playerGrey_up2" :: Nil},
        Map.empty()))

    // ========================================================================
    // Movement
    // ========================================================================

    // Node accessors (like Godot's $ syntax)
    def player(f: SceneTree.Node -> SceneTree.Node, scene: SceneTree.Node): SceneTree.Node =
        SceneTree.mapNode(playerName(), f, scene)

    def sprite(f: SceneTree.Node -> SceneTree.Node, scene: SceneTree.Node): SceneTree.Node =
        SceneTree.mapChild(Child.Sprite, f, scene)

    pub def movePlayer(dirVelocity: Vec2D.Vec2, scene: SceneTree.Node): SceneTree.Node =
        let animated = if (dirVelocity#x != 0.0f32)
                scene |> sprite(s ->
                s |> animation("walk")
                     |> flipV(false)
                     |> flipH(dirVelocity#x < 0.0f32))
            else if (dirVelocity#y != 0.0f32)
                scene |> sprite(s ->
                s|> animation("up")
                |> flipV(dirVelocity#y > 0.0f32))
            else
                scene;

        if (Vec2D.length(dirVelocity) > 0.0f32)
            animated
                |> player(Area2D.velocity(Vec2D.mul(Vec2D.normalized(dirVelocity), playerSpeed())))
                |> sprite(play)
        else
            animated
                |> player(Area2D.velocity(Vec2D.zero()))
                |> sprite(stop)

    // ========================================================================
    // Player Node Building
    // ========================================================================

    pub def startPlayer(pos: Vec2D.Vec2, scene: SceneTree.Node): SceneTree.Node =
        scene
            |> SceneTree.setNodePosition(playerName(), pos)
            |> player(Area2D.velocity(Vec2D.zero()))
            |> sprite(s -> s |> AnimatedSprite2D.animation("walk") |> AnimatedSprite2D.playing(true))
            |> SceneTree.updateChildAnimatedSprite(playerName(), asd -> {visible = true | asd})

    pub def hidePlayer(scene: SceneTree.Node): SceneTree.Node =
        scene
            |> SceneTree.updateChildAnimatedSprite(playerName(), asd -> {visible = false | asd})

    pub def clampToScreen(screenSize: Vec2D.Vec2, scene: SceneTree.Node): SceneTree.Node =
        match SceneTree.globalPosition(playerName(), scene) {
            case None => scene
            case Some(pos) =>
                let size = playerSize();
                let maxPos = {x = screenSize#x - size#x, y = screenSize#y - size#y};
                SceneTree.setNodePosition(playerName(), Vec2D.clamp(pos, Vec2D.zero(), maxPos), scene)
        }

    pub def buildPlayer(startPos: Vec2D.Vec2): SceneTree.Node =
        let playerSprite = AnimatedSprite2D.init({
                name = "Sprite", pos = Vec2D.zero(),
                size = playerSize(),
                animations = playerAnimations(),
                initialAnimation = "walk"
            })
            |> fps(6.0f32);
        let playerShape = SceneTree.collisionShape2D("Shape",
            SceneTree.CollisionShapeData.CapsuleShape(27.0f32, 67.5f32));
        Area2D.init({
            name = playerName(), pos = startPos,
            children = playerSprite :: playerShape :: Nil
        })


}
