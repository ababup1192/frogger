// Vehicle — vehicle node construction for road lanes

mod Vehicle {

    /// 車両テンプレートから抽出する構造情報（size: Sprite の size から取得）
    pub type alias Config = {
        size = Vec2D.Vec2
    }

    /// JSONテンプレートを読み込み、SceneTree.Node として返す
    pub def loadTemplate(): SceneTree.Node \ Fs.FileRead =
        SceneLoader.loadScene("src/scenes/Vehicle.scene.json")

    /// テンプレートの Sprite ノードからサイズを抽出する（純粋）
    pub def loadConfig(template: SceneTree.Node): Config =
        match SceneTree.findSpriteData("Sprite", template) {
            case Some(sd) => {size = sd#size}
            case None     => bug!("Vehicle template: Sprite node not found")
        }

    /// Config のサイズを使って車両ノードを構築する（純粋）
    pub def build(config: Config, name: String, pos: Vec2D.Vec2, texture: String): SceneTree.Node =
        let sprite = Sprite2D.init({name = "Sprite", pos = Vec2D.zero(),
                                    size = config#size, texture = texture});
        let shape = RectShape2D.init({name = "Shape", size = config#size});
        Area2D.init({name = name, pos = pos, children = sprite :: shape :: Nil})
}
