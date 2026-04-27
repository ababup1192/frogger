// TurtleGroup — turtle group node construction for water lanes

mod TurtleGroup {

    def spriteW(): Float32 = 64.0f32

    def spriteH(): Float32 = 48.0f32

    pub def width(turtleCount: Int32): Float32 =
        Int32.toFloat32(turtleCount) * spriteW()

    pub def size(turtleCount: Int32): Vec2D.Vec2 =
        {x = width(turtleCount), y = spriteH()}

    // ========================================================================
    // Build turtle sprites for a section (turtleCount sprites side by side)
    // ========================================================================

    def animations(): Map[String, SceneTree.AnimationEntry] =
        Map.insert("swim", {frames = "Turtle_01" :: "Turtle_02" :: "Turtle_03" :: Nil}, Map.empty())

    def buildSprites(turtleCount: Int32, direction: Float32): List[SceneTree.Node] =
        let spriteY = 8.0f32;
        List.range(0, turtleCount)
            |> List.map(i ->
                AnimatedSprite2D.init({name = "Sprite${i}",
                               pos = {x = Int32.toFloat32(i) * spriteW(), y = spriteY},
                               size = {x = spriteW(), y = spriteH()},
                               animations = animations(),
                               initialAnimation = "swim"})
                    |> AnimatedSprite2D.fps(3.0f32)
                    |> AnimatedSprite2D.flipH(direction > 0.0f32))

    /// 亀グループノードを構築（Area2D + AnimatedSprites + CollisionShape）
    /// direction: 流れる方向（負=左向き、正=右向き）でスプライトを反転する
    pub def build(name: String, pos: Vec2D.Vec2, turtleCount: Int32, direction: Float32): SceneTree.Node =
        let sprites = buildSprites(turtleCount, direction);
        let shape = Shape2D.rect({name = "Shape", size = size(turtleCount)});
        Area2D.init({name = name, pos = pos,
                     children = List.append(sprites, shape :: Nil)})
}
