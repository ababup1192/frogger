// Log — log node construction for water lanes

mod Log {

    def segmentSize(): Float32 = 64.0f32

    pub def width(segments: Int32): Float32 =
        (Int32.toFloat32(segments) + 2.0f32) * segmentSize()

    pub def size(segments: Int32): Vec2D.Vec2 =
        {x = width(segments), y = 48.0f32}

    // ========================================================================
    // Build log sprites — Start + Middle (tiled) + End
    // ========================================================================

    def buildSprites(segments: Int32): List[SceneTree.Node] =
        let seg = segmentSize();
        let spriteH = 48.0f32;
        let spriteY = 8.0f32;
        let start = Sprite2D.init({name = "SpriteStart",
                                   pos = {x = 0.0f32, y = spriteY},
                                   size = {x = seg, y = spriteH},
                                   texture = "LogEnd"});
        let endX = (Int32.toFloat32(segments) + 1.0f32) * seg;
        let end = Sprite2D.init({name = "SpriteEnd",
                                 pos = {x = endX, y = spriteY},
                                 size = {x = seg, y = spriteH},
                                 texture = "LogStart"});
        if (segments <= 0)
            start :: end :: Nil
        else {
            let midW = Int32.toFloat32(segments) * seg;
            let mid = Sprite2D.init({name = "Sprite",
                                     pos = {x = seg, y = spriteY},
                                     size = {x = midW, y = spriteH},
                                     texture = "LogMiddle"})
                |> Sprite2D.uv(Vec2D.zero(), {x = Int32.toFloat32(segments), y = 1.0f32});
            start :: mid :: end :: Nil
        }

    /// 丸太ノードを構築（Area2D + Start/Middle/End Sprites + CollisionShape）
    pub def build(name: String, pos: Vec2D.Vec2, segments: Int32): SceneTree.Node =
        let sprites = buildSprites(segments);
        let shape = RectShape2D.init({name = "Shape", size = size(segments)});
        Area2D.init({name = name, pos = pos,
                     children = List.append(sprites, shape :: Nil)})
}
