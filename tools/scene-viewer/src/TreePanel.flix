// TreePanel — 左パネル: ノードツリーを階層表示する

mod TreePanel {
    /// 1行の高さ（ピクセル）
    def rowHeight(): Float32 = 28.0f32

    /// インデントの幅（ピクセル／深さ1あたり）
    def indentWidth(): Float32 = 24.0f32

    /// テキストの開始 X 位置
    def textStartX(): Float32 = 8.0f32

    /// ツリー領域の Y 開始位置（タブバーの下 + マージン）
    def contentStartY(): Float32 = ViewerConfig.tabBarHeight() + 8.0f32

    /// フォントサイズ
    def fontSize(): Float32 = 18.0f32

    /// ツリーの行情報（描画とヒットテストの座標を共有する）
    type alias TreeRow = {
        node = SceneTree.Node, // 描画用ノード
        nodeName = String,     // 元のノード名（ヒットテスト結果として返す）
        rowY = Float32         // 行の上端 Y 座標（ハイライト・ヒットテスト共通）
    }

    /// ツリーパネル全体を構築する
    pub def build(scene: SceneTree.Node, treeState: ViewerState.TreeState): SceneTree.Node =
        // パネル背景
        let panelBg = Sprite2D.init({name = "treePanelBg",
                                     pos = {x = 0.0f32, y = ViewerConfig.tabBarHeight()},
                                     size = {x = ViewerConfig.treePanelWidth(),
                                             y = Int32.toFloat32(ViewerConfig.screenHeight()) - ViewerConfig.tabBarHeight()},
                                     texture = "white"})
                          |> Sprite2D.color({r = 0.12f32, g = 0.12f32, b = 0.15f32});
        let rows = buildRows(scene, treeState, 0, 0);
        let rowNodes = rows |> List.map(row -> row#node);
        SceneTree.node2D("TreePanel", Vec2D.zero(), panelBg :: rowNodes)

    /// ノードツリーを深さ優先で走査し、行リストを生成する
    def buildRows(node: SceneTree.Node, treeState: ViewerState.TreeState,
                  depth: Int32, startRow: Int32): List[TreeRow] =
        let SceneTree.Node.MkNode(name, _, kind, nodeChildren) = node;
        let hasChildren = not List.isEmpty(nodeChildren);
        let isExpanded = Set.memberOf(name, treeState#expandedNodes);
        let isSelected = treeState#selectedNode == Some(name);
        // 行の上端 Y 座標（ハイライトとヒットテストで共有）
        let rowY = contentStartY() + Int32.toFloat32(startRow) * rowHeight();
        // 展開アイコン
        let icon = if (hasChildren)
            (if (isExpanded) "v " else "> ")
        else "- ";
        let typeName = NodeVisual.kindName(kind);
        let displayText = "${icon}${name} [${typeName}]";
        let xPos = textStartX() + Int32.toFloat32(depth) * indentWidth();
        // 行ノードを構築（ハイライト背景 + ラベルを1つのグループにまとめる）
        let rowNode = buildRowNode(name, displayText, xPos, rowY, isSelected);
        let thisRow = {node = rowNode, nodeName = name, rowY = rowY};
        if (hasChildren and isExpanded) {
            let childRows = buildChildRows(nodeChildren, treeState, depth + 1, startRow + 1);
            thisRow :: childRows
        } else {
            thisRow :: Nil
        }

    /// 1行分のノードを構築する（ハイライトとラベルを含むグループ）
    def buildRowNode(name: String, displayText: String,
                     xPos: Float32, rowY: Float32, isSelected: Bool): SceneTree.Node =
        // ラベル（行の上端から少し下にオフセットして縦中央に寄せる）
        let labelY = rowY + (rowHeight() - fontSize()) / 2.0f32;
        let label = Label2D.init({name = "tree_${name}",
                                  pos = {x = xPos, y = labelY},
                                  text = displayText, fontSize = fontSize(),
                                  font = ViewerConfig.defaultFont()})
                        |> Label2D.color({r = 0.85f32, g = 0.85f32, b = 0.85f32});
        if (isSelected) {
            // ハイライト背景（行の上端に配置、行高さ分のサイズ）
            let highlight = Sprite2D.init({name = "tree_hl_${name}",
                                           pos = {x = 0.0f32, y = rowY},
                                           size = {x = ViewerConfig.treePanelWidth(), y = rowHeight()},
                                           texture = "white"})
                                |> Sprite2D.color({r = 0.25f32, g = 0.35f32, b = 0.55f32});
            SceneTree.node2D("treeRow_${name}", Vec2D.zero(), highlight :: label :: Nil)
        } else label

    /// 子ノードリストを順に処理し、行インデックスを累積しながら行を生成する
    def buildChildRows(children: List[SceneTree.Node], treeState: ViewerState.TreeState,
                       depth: Int32, startRow: Int32): List[TreeRow] =
        match children {
            case Nil => Nil
            case child :: rest =>
                let rows = buildRows(child, treeState, depth, startRow);
                let nextRow = startRow + List.length(rows);
                let restRows = buildChildRows(rest, treeState, depth, nextRow);
                List.append(rows, restRows)
        }

    /// マウスクリック位置からノード名を特定する（行の実際の Y 座標と照合する）
    pub def hitTest(mouseX: Float32, mouseY: Float32, scene: SceneTree.Node,
                    treeState: ViewerState.TreeState): Option[String] =
        if (mouseX >= ViewerConfig.treePanelWidth()) None
        else {
            let rows = buildRows(scene, treeState, 0, 0);
            findRowByY(rows, mouseY)
        }

    /// マウス Y 座標が行の範囲内にあるか順に判定する
    def findRowByY(rows: List[TreeRow], mouseY: Float32): Option[String] =
        match rows {
            case Nil => None
            case row :: rest =>
                if (mouseY >= row#rowY and mouseY < row#rowY + rowHeight())
                    Some(row#nodeName)
                else findRowByY(rest, mouseY)
        }

    /// ノードの展開状態をトグルする
    pub def toggleExpand(nodeName: String, treeState: ViewerState.TreeState): ViewerState.TreeState =
        if (Set.memberOf(nodeName, treeState#expandedNodes))
            {expandedNodes = Set.remove(nodeName, treeState#expandedNodes) | treeState}
        else
            {expandedNodes = Set.insert(nodeName, treeState#expandedNodes) | treeState}
}
