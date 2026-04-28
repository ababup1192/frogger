// CanvasPanel — 右パネル: シーンのノードを2D描画する

mod CanvasPanel {
    /// キャンバスパネルの X 開始位置
    def panelX(): Float32 = ViewerConfig.treePanelWidth()

    /// キャンバスパネルの Y 開始位置（タブバーの下）
    def panelY(): Float32 = ViewerConfig.tabBarHeight()

    /// キャンバスの幅
    def panelWidth(): Float32 = Int32.toFloat32(ViewerConfig.screenWidth()) - panelX()

    /// キャンバスの高さ
    def panelHeight(): Float32 = Int32.toFloat32(ViewerConfig.screenHeight()) - panelY()

    /// シーンのバウンディングボックスを計算する
    def sceneBounds(node: SceneTree.Node, parentX: Float32, parentY: Float32): {minX = Float32, minY = Float32, maxX = Float32, maxY = Float32} =
        let SceneTree.Node.MkNode(_, pos, kind, nodeChildren) = node;
        let visual = NodeVisual.visualForKind(kind);
        let gx = parentX + pos#x;
        let gy = parentY + pos#y;
        let thisBox = {minX = gx, minY = gy, maxX = gx + visual#size#x, maxY = gy + visual#size#y};
        nodeChildren |> List.foldLeft((acc, child) -> {
            let cb = sceneBounds(child, gx, gy);
            {minX = Float32.min(acc#minX, cb#minX),
             minY = Float32.min(acc#minY, cb#minY),
             maxX = Float32.max(acc#maxX, cb#maxX),
             maxY = Float32.max(acc#maxY, cb#maxY)}
        }, thisBox)

    /// シーン全体がキャンバスに収まる初期ズームとオフセットを計算する
    pub def initialView(scene: SceneTree.Node): ViewerState.CanvasState =
        let bounds = sceneBounds(scene, 0.0f32, 0.0f32);
        let sceneW = bounds#maxX - bounds#minX;
        let sceneH = bounds#maxY - bounds#minY;
        if (sceneW < 1.0f32 and sceneH < 1.0f32)
            {panOffset = Vec2D.zero(), zoom = 1.0f32}
        else {
            let marginRatio = 0.8f32;
            let zoomX = panelWidth() * marginRatio / sceneW;
            let zoomY = panelHeight() * marginRatio / sceneH;
            let zoom = Float32.min(zoomX, zoomY) |> Float32.min(2.0f32) |> Float32.max(0.1f32);
            let sceneCenterX = (bounds#minX + bounds#maxX) / 2.0f32;
            let sceneCenterY = (bounds#minY + bounds#maxY) / 2.0f32;
            let panX = panelWidth() / 2.0f32 - sceneCenterX * zoom;
            let panY = panelHeight() / 2.0f32 - sceneCenterY * zoom;
            {panOffset = {x = panX, y = panY}, zoom = zoom}
        }

    /// パンオフセットをクランプして画面外に出ないようにする
    pub def clampPan(canvasState: ViewerState.CanvasState): ViewerState.CanvasState =
        let limit = 2000.0f32;
        let clampedX = canvasState#panOffset#x |> Float32.max(-limit) |> Float32.min(limit);
        let clampedY = canvasState#panOffset#y |> Float32.max(-limit) |> Float32.min(limit);
        {panOffset = {x = clampedX, y = clampedY} | canvasState}

    /// シーンツリーを走査し、ノードを描画する
    pub def build(scene: SceneTree.Node, canvasState: ViewerState.CanvasState,
                  selectedNode: Option[String], debugView: Bool): SceneTree.Node =
        let zoom = canvasState#zoom;
        let panX = canvasState#panOffset#x;
        let panY = canvasState#panOffset#y;
        let originX = panelX() + panX;
        let originY = panelY() + panY;
        let children = buildNodes(scene, originX, originY, zoom, selectedNode, debugView);
        SceneTree.node2D("CanvasPanel", Vec2D.zero(), children)

    /// ノードツリーを再帰的に走査し、各ノードを描画する
    def buildNodes(node: SceneTree.Node, parentX: Float32, parentY: Float32,
                   zoom: Float32, selectedNode: Option[String],
                   debugView: Bool): List[SceneTree.Node] =
        let SceneTree.Node.MkNode(name, pos, kind, nodeChildren) = node;
        let globalX = parentX + pos#x * zoom;
        let globalY = parentY + pos#y * zoom;
        // テクスチャモード or デバッグモードで描画内容を切り替え
        let spriteNodes = if (debugView)
            buildDebugSprite(name, kind, globalX, globalY, zoom)
        else
            buildTextureSprite(name, kind, globalX, globalY, zoom);
        // 選択中ノードのハイライト
        let visual = NodeVisual.visualForKind(kind);
        let scaledW = visual#size#x * zoom;
        let scaledH = visual#size#y * zoom;
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
        // ノード名ラベル（デバッグモードのみ）
        let labelNodes = if (debugView)
            Label2D.init({name = "cv_lbl_${name}",
                          pos = {x = globalX, y = globalY - 18.0f32},
                          text = name, fontSize = 16.0f32,
                          font = ViewerConfig.defaultFont()})
                |> Label2D.color({r = 0.9f32, g = 0.9f32, b = 0.9f32}) :: Nil
        else Nil;
        // 子ノードを再帰的に処理
        let childSprites = nodeChildren
            |> List.flatMap(child -> buildNodes(child, globalX, globalY, zoom, selectedNode, debugView));
        List.append(highlight, List.append(spriteNodes, List.append(labelNodes, childSprites)))

    /// デバッグモード: 色分け矩形で描画する
    def buildDebugSprite(name: String, kind: SceneTree.NodeKind,
                         globalX: Float32, globalY: Float32, zoom: Float32): List[SceneTree.Node] =
        let visual = NodeVisual.visualForKind(kind);
        let scaledW = visual#size#x * zoom;
        let scaledH = visual#size#y * zoom;
        Sprite2D.init({name = "cv_${name}", pos = {x = globalX, y = globalY},
                       size = {x = scaledW, y = scaledH}, texture = "white"})
            |> Sprite2D.color(visual#color) :: Nil

    /// テクスチャモード: スプライトの実テクスチャで描画する
    def buildTextureSprite(name: String, kind: SceneTree.NodeKind,
                           globalX: Float32, globalY: Float32, zoom: Float32): List[SceneTree.Node] =
        match kind {
            // Sprite2D: 実テクスチャを使用
            case SceneTree.NodeKind.Sprite(sd) =>
                let scaledW = sd#size#x * zoom;
                let scaledH = sd#size#y * zoom;
                Sprite2D.init({name = "cv_${name}", pos = {x = globalX, y = globalY},
                               size = {x = scaledW, y = scaledH}, texture = sd#texture})
                    |> Sprite2D.color(sd#color) :: Nil
            // AnimatedSprite2D: 現在のアニメーションの最初のフレームを使用
            case SceneTree.NodeKind.AnimatedSprite(asd) =>
                let scaledW = asd#size#x * zoom;
                let scaledH = asd#size#y * zoom;
                let texture = asd#animations
                    |> Map.get(asd#currentAnimation)
                    |> Option.flatMap(entry -> List.head(entry#frames))
                    |> Option.getWithDefault("white");
                Sprite2D.init({name = "cv_${name}", pos = {x = globalX, y = globalY},
                               size = {x = scaledW, y = scaledH}, texture = texture})
                    |> Sprite2D.color(asd#color) :: Nil
            // その他のノードは小さい半透明マーカーで表示
            case _ =>
                let visual = NodeVisual.visualForKind(kind);
                let scaledW = visual#size#x * zoom;
                let scaledH = visual#size#y * zoom;
                if (scaledW > 1.0f32 and scaledH > 1.0f32)
                    Sprite2D.init({name = "cv_${name}", pos = {x = globalX, y = globalY},
                                   size = {x = scaledW, y = scaledH}, texture = "white"})
                        |> Sprite2D.color({r = visual#color#r, g = visual#color#g, b = visual#color#b}) :: Nil
                else Nil
        }
}
