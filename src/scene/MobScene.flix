// MobScene — Dodge the Creeps enemy mob (RigidBody2D-based)

mod MobScene {

    // ========================================================================
    // Animation Definitions
    // ========================================================================

    pub def mobAnimations(): Map[String, SceneTree.AnimationEntry] =
        Map.empty()
            |> Map.insert("fly", {frames = "enemyFlyingAlt_1" :: "enemyFlyingAlt_2" :: Nil})
            |> Map.insert("swim", {frames = "enemySwimming_1" :: "enemySwimming_2" :: Nil})
            |> Map.insert("walk", {frames = "enemyWalking_1" :: "enemyWalking_2" :: Nil})

    // ========================================================================
    // Random Animation Selection
    // ========================================================================

    def pickAnimation(): String \ Math.Random =
        match Map.keysOf(mobAnimations()) |> Set.toList |> RandomUtil.pick {
            case Some(anim) => anim
            case None       => bug!("mobAnimations is empty")
        }

    // ========================================================================
    // Mob Node Building (Godot _ready() equivalent)
    // ========================================================================

    pub def buildMob(name: String, spawnPos: Vec2D.Vec2,
                     velocity: Vec2D.Vec2, direction: Float32): SceneTree.Node \ Math.Random =
        let animation = pickAnimation();
        let mobSprite = AnimatedSprite2D.init({
                name = "Sprite", pos = Vec2D.zero(),
                size = {x = 54.0f32, y = 67.5f32},
                animations = mobAnimations(),
                initialAnimation = animation
            })
            |> AnimatedSprite2D.fps(3.0f32)
            |> AnimatedSprite2D.play;
        let mobShape = SceneTree.collisionShape2D("Shape",
            SceneTree.CollisionShapeData.CapsuleShape(27.0f32, 67.5f32));
        let mobNotifier = VisibleOnScreenNotifier2D.init({
            name = "Notifier",
            rect = {x = 54.0f32, y = 67.5f32}
        });
        RigidBody2D.init({
            name = name, pos = spawnPos,
            children = mobSprite :: mobShape :: mobNotifier :: Nil
        })
            |> RigidBody2D.velocity(velocity)
            |> RigidBody2D.gravityScale(0.0f32)
            |> RigidBody2D.rotation(direction)
}
