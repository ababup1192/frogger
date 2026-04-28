// PropertyPanel — 選択ノードのプロパティを表示する右側パネル

mod PropertyPanel {
    /// プロパティ値の型（将来の編集対応）
    pub enum PropertyValue {
        case TextVal(String)
        case FloatVal(Float32)
        case BoolVal(Bool)
        case Vec2Val(Vec2D.Vec2)
        case ColorVal(Engine.Color)
    }

    /// PropertyValue を表示用文字列に変換する
    def formatValue(v: PropertyValue): String =
        match v {
            case PropertyValue.TextVal(s) => s
            case PropertyValue.FloatVal(f) => "${f}"
            case PropertyValue.BoolVal(b) => if (b) "true" else "false"
            case PropertyValue.Vec2Val(vec) => "(${vec#x}, ${vec#y})"
            case PropertyValue.ColorVal(c) => "(${c#r}, ${c#g}, ${c#b})"
        }

    /// ノードからプロパティリストを抽出する（Name, Type はヘッダーで表示するので含まない）
    pub def extractProperties(node: SceneTree.Node): List[(String, String, PropertyValue)] =
        let pos = SceneTree.nodePosition(node);
        let children = SceneTree.nodeChildren(node);
        let childCount = List.length(children);
        let kind = SceneTree.nodeKind(node);
        let common =
            ("pos", "Position", PropertyValue.Vec2Val(pos)) ::
            ("children", "Children", PropertyValue.TextVal("${childCount}")) ::
            Nil;
        let specific = extractKindProperties(kind);
        List.append(common, specific)

    /// NodeKind 固有のプロパティを抽出する
    def extractKindProperties(kind: SceneTree.NodeKind): List[(String, String, PropertyValue)] =
        match kind {
            case SceneTree.NodeKind.Sprite(sd) =>
                ("sprite.size", "Size", PropertyValue.Vec2Val(sd#size)) ::
                ("sprite.texture", "Texture", PropertyValue.TextVal(sd#texture)) ::
                ("sprite.color", "Color", PropertyValue.ColorVal(sd#color)) ::
                ("sprite.visible", "Visible", PropertyValue.BoolVal(sd#visible)) ::
                ("sprite.rotation", "Rotation", PropertyValue.FloatVal(sd#rotation)) ::
                Nil
            case SceneTree.NodeKind.AnimatedSprite(asd) =>
                ("anim.size", "Size", PropertyValue.Vec2Val(asd#size)) ::
                ("anim.color", "Color", PropertyValue.ColorVal(asd#color)) ::
                ("anim.visible", "Visible", PropertyValue.BoolVal(asd#visible)) ::
                ("anim.currentAnim", "Animation", PropertyValue.TextVal(asd#currentAnimation)) ::
                ("anim.fps", "FPS", PropertyValue.FloatVal(asd#fps)) ::
                ("anim.playing", "Playing", PropertyValue.BoolVal(asd#playing)) ::
                ("anim.frame", "Frame", PropertyValue.TextVal("${asd#currentFrame}")) ::
                ("anim.flipH", "Flip H", PropertyValue.BoolVal(asd#flipH)) ::
                ("anim.flipV", "Flip V", PropertyValue.BoolVal(asd#flipV)) ::
                ("anim.rotation", "Rotation", PropertyValue.FloatVal(asd#rotation)) ::
                Nil
            case SceneTree.NodeKind.Label(ld) =>
                ("label.text", "Text", PropertyValue.TextVal(ld#text)) ::
                ("label.font", "Font", PropertyValue.TextVal(ld#font)) ::
                ("label.fontSize", "Font Size", PropertyValue.FloatVal(ld#fontSize)) ::
                ("label.color", "Color", PropertyValue.ColorVal(ld#color)) ::
                ("label.visible", "Visible", PropertyValue.BoolVal(ld#visible)) ::
                ("label.centered", "Centered", PropertyValue.BoolVal(ld#centered)) ::
                Nil
            case SceneTree.NodeKind.Character(cbd) =>
                ("char.targetPos", "Target Pos", PropertyValue.Vec2Val(cbd#targetPos)) ::
                ("char.moveSpeed", "Move Speed", PropertyValue.FloatVal(cbd#moveSpeed)) ::
                Nil
            case SceneTree.NodeKind.Area(ad) =>
                ("area.velocity", "Velocity", PropertyValue.Vec2Val(ad#velocity)) ::
                Nil
            case SceneTree.NodeKind.Camera(cd) =>
                ("cam.offset", "Offset", PropertyValue.Vec2Val(cd#offset)) ::
                ("cam.zoom", "Zoom", PropertyValue.Vec2Val(cd#zoom)) ::
                ("cam.smoothing", "Smoothing", PropertyValue.BoolVal(cd#smoothingEnabled)) ::
                ("cam.isCurrent", "Is Current", PropertyValue.BoolVal(cd#isCurrent)) ::
                Nil
            case SceneTree.NodeKind.Shape(SceneTree.CollisionShapeData.RectShape(size)) =>
                ("shape.size", "Size", PropertyValue.Vec2Val(size)) ::
                Nil
            case SceneTree.NodeKind.Shape(SceneTree.CollisionShapeData.CircleShape(r)) =>
                ("shape.radius", "Radius", PropertyValue.FloatVal(r)) ::
                Nil
            case SceneTree.NodeKind.Shape(SceneTree.CollisionShapeData.CapsuleShape(r, h)) =>
                ("shape.radius", "Radius", PropertyValue.FloatVal(r)) ::
                ("shape.height", "Height", PropertyValue.FloatVal(h)) ::
                Nil
            case SceneTree.NodeKind.Timer(td) =>
                ("timer.waitTime", "Wait Time", PropertyValue.FloatVal(td#waitTime)) ::
                ("timer.oneShot", "One Shot", PropertyValue.BoolVal(td#oneShot)) ::
                ("timer.running", "Running", PropertyValue.BoolVal(td#running)) ::
                Nil
            case SceneTree.NodeKind.Button(bd) =>
                ("btn.text", "Text", PropertyValue.TextVal(bd#text)) ::
                ("btn.fontSize", "Font Size", PropertyValue.FloatVal(bd#fontSize)) ::
                ("btn.color", "Color", PropertyValue.ColorVal(bd#color)) ::
                ("btn.bgColor", "Bg Color", PropertyValue.ColorVal(bd#bgColor)) ::
                ("btn.visible", "Visible", PropertyValue.BoolVal(bd#visible)) ::
                Nil
            case _ => Nil
        }

    /// プロパティパネルを構築する
    pub def build(scene: SceneTree.Node, selectedNode: Option[String]): SceneTree.Node =
        let px = ViewerConfig.propertyPanelX();
        let py = ViewerConfig.tabBarHeight();
        let pw = ViewerConfig.propertyPanelWidth();
        let ph = Int32.toFloat32(ViewerConfig.screenHeight()) - py;
        let font = ViewerConfig.defaultFont();
        // 背景
        let bg = Sprite2D.init({name = "propPanelBg",
                                pos = {x = px, y = py},
                                size = {x = pw, y = ph},
                                texture = "white"})
                    |> Sprite2D.color({r = 0.12f32, g = 0.12f32, b = 0.15f32});
        // 左端の境界線
        let border = Sprite2D.init({name = "propPanelBorder",
                                    pos = {x = px, y = py},
                                    size = {x = 2.0f32, y = ph},
                                    texture = "white"})
                        |> Sprite2D.color({r = 0.3f32, g = 0.3f32, b = 0.35f32});
        let content = match selectedNode {
            case Some(name) =>
                match SceneTree.findNode(name, scene) {
                    case Some(node) => buildProperties(node, px, py, font)
                    case None => buildPlaceholder(px, py, ph, font)
                }
            case None => buildPlaceholder(px, py, ph, font)
        };
        SceneTree.node2D("PropertyPanel", Vec2D.zero(),
            bg :: border :: content)

    /// 選択中ノードのプロパティを描画する
    def buildProperties(node: SceneTree.Node, px: Float32, py: Float32, font: String): List[SceneTree.Node] =
        let props = extractProperties(node);
        let name = SceneTree.nodeName(node);
        let typeName = NodeVisual.kindName(SceneTree.nodeKind(node));
        let headerPadding = 12.0f32;
        // ヘッダー: ノード名
        let nameLabel = Label2D.init({name = "prop_name",
                                      pos = {x = px + 10.0f32, y = py + headerPadding},
                                      text = name, fontSize = 16.0f32, font = font})
                           |> Label2D.color({r = 1.0f32, g = 1.0f32, b = 1.0f32});
        // ヘッダー: 型名
        let typeLabel = Label2D.init({name = "prop_type",
                                     pos = {x = px + 10.0f32, y = py + headerPadding + 22.0f32},
                                     text = typeName, fontSize = 14.0f32, font = font})
                           |> Label2D.color({r = 0.5f32, g = 0.5f32, b = 0.55f32});
        // 区切り線
        let separator = Sprite2D.init({name = "prop_sep",
                                       pos = {x = px + 8.0f32, y = py + headerPadding + 42.0f32},
                                       size = {x = ViewerConfig.propertyPanelWidth() - 16.0f32, y = 1.0f32},
                                       texture = "white"})
                           |> Sprite2D.color({r = 0.25f32, g = 0.25f32, b = 0.3f32});
        // プロパティ行
        let startY = py + headerPadding + 52.0f32;
        let rowHeight = 20.0f32;
        let rows = props |> List.mapWithIndex((i, prop) -> {
            let (fieldId, key, value) = prop;
            let rowY = startY + Int32.toFloat32(i) * rowHeight;
            buildPropertyRow(fieldId, key, value, px, rowY, font)
        }) |> List.flatMap(x -> x);
        nameLabel :: typeLabel :: separator :: rows

    /// プロパティの1行を構築する（キーラベル + 値ラベル）
    def buildPropertyRow(fieldId: String, key: String, value: PropertyValue,
                         px: Float32, rowY: Float32, font: String): List[SceneTree.Node] =
        let keyLabel = Label2D.init({name = "prop_k_${fieldId}",
                                     pos = {x = px + 10.0f32, y = rowY},
                                     text = key, fontSize = 14.0f32, font = font})
                          |> Label2D.color({r = 0.5f32, g = 0.5f32, b = 0.55f32});
        let valueLabel = Label2D.init({name = "prop_v_${fieldId}",
                                       pos = {x = px + 110.0f32, y = rowY},
                                       text = formatValue(value), fontSize = 14.0f32, font = font})
                            |> Label2D.color({r = 0.85f32, g = 0.85f32, b = 0.9f32});
        keyLabel :: valueLabel :: Nil

    /// 未選択時のプレースホルダーを構築する
    def buildPlaceholder(px: Float32, py: Float32, ph: Float32, font: String): List[SceneTree.Node] =
        Label2D.init({name = "prop_placeholder",
                      pos = {x = px + ViewerConfig.propertyPanelWidth() / 2.0f32, y = py + ph / 2.0f32},
                      text = "Select a node", fontSize = 14.0f32, font = font})
            |> Label2D.color({r = 0.4f32, g = 0.4f32, b = 0.45f32})
            |> Label2D.centered(true) :: Nil
}
