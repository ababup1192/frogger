// Vehicle — vehicle node construction for road lanes

mod Vehicle {

    pub def size(): Vec2D.Vec2 = {x = 64.0f32, y = 48.0f32}

    def spriteName(): String = "Sprite"

    /// 車両ノードを構築（Area2D + Sprite + CollisionShape）
    pub def build(name: String, pos: Vec2D.Vec2, texture: String): SceneTree.Node =
        let sprite = Sprite2D.init({name = spriteName(), pos = Vec2D.zero(),
                                    size = size(), texture = texture});
        let shape = RectShape2D.init({name = "Shape", size = size()});
        Area2D.init({name = name, pos = pos, children = sprite :: shape :: Nil})
}
