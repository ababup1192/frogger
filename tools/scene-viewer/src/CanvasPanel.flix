// CanvasPanel — 右パネル: シーンのノードを色付き矩形で2D描画する

mod CanvasPanel {
    /// キャンバスパネルの X 開始位置
    def panelX(): Float32 = ViewerConfig.treePanelWidth()

    /// キャンバスパネルの Y 開始位置（タブバーの下）
    def panelY(): Float32 = ViewerConfig.tabBarHeight()

    /// シーンツリーを走査し、各ノードを色付き矩形として配置した Node を構築する
    pub def build(scene: SceneTree.Node, canvasState: ViewerState.CanvasState,
                  selectedNode: Option[String]): SceneTree.Node =
        let zoom = canvasState#zoom;
        let panX = canvasState#panOffset#x;
        let panY = canvasState#panOffset#y;
        // キャンバス原点（パネル中央にオフセット）
        let originX = panelX() + 200.0f32 + panX;
        let originY = panelY() + 100.0f32 + panY;
        let children = buildNodes(scene, originX, originY, zoom, selectedNode, 0);
        SceneTree.node2D("CanvasPanel", Vec2D.zero(), children)

    /// ノードツリーを再帰的に走査し、各ノードの矩形 Sprite を生成する
    def buildNodes(node: SceneTree.Node, parentX: Float32, parentY: Float32,
                   zoom: Float32, selectedNode: Option[String],
                   depth: Int32): List[SceneTree.Node] =
        let SceneTree.Node.MkNode(name, pos, kind, nodeChildren) = node;
        let visual = NodeVisual.visualForKind(kind);
        // グローバル位置（親の累積位置 + 自身のローカル位置）
        let globalX = parentX + pos#x * zoom;
        let globalY = parentY + pos#y * zoom;
        let scaledW = visual#size#x * zoom;
        let scaledH = visual#size#y * zoom;
        // ノードの矩形を Sprite2D で描画
        let sprite =
            Sprite2D.init({name = "cv_${name}", pos = {x = globalX, y = globalY},
                           size = {x = scaledW, y = scaledH}, texture = "white"})
                |> Sprite2D.color(visual#color);
        // 選択中ノードのハイライト（少し大きい半透明矩形を背面に配置）
        let highlight = match selectedNode {
            case Some(sel) if sel == name =>
                let pad = 3.0f32;
                Sprite2D.init({name = "cv_hl_${name}",
                               pos = {x = globalX - pad, y = globalY - pad},
                               size = {x = scaledW + pad * 2.0f32, y = scaledH + pad * 2.0f32},
                               texture = "white"})
                    |> Sprite2D.color({r = 1.0f32, g = 1.0f32, b = 0.3f32}) :: Nil
            case _ => Nil
        };
        // ノード名ラベル
        let label = Label2D.init({name = "cv_lbl_${name}",
                                  pos = {x = globalX, y = globalY - 14.0f32},
                                  text = name, fontSize = 11.0f32,
                                  font = ViewerConfig.defaultFont()})
                        |> Label2D.color({r = 0.9f32, g = 0.9f32, b = 0.9f32});
        // 子ノードを再帰的に処理
        let childSprites = nodeChildren
            |> List.flatMap(child -> buildNodes(child, globalX, globalY, zoom, selectedNode, depth + 1));
        List.append(highlight, sprite :: label :: childSprites)
}
