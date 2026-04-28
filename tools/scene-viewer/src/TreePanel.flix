// TreePanel — 左パネル: ノードツリーを Label で階層表示する

mod TreePanel {
    /// 1行の高さ（ピクセル）
    def rowHeight(): Float32 = 28.0f32

    /// インデントの幅（ピクセル／深さ1あたり）
    def indentWidth(): Float32 = 24.0f32

    /// テキストの開始 X 位置
    def textStartX(): Float32 = 8.0f32

    /// テキストの開始 Y 位置（タブバーの下）
    def textStartY(): Float32 = ViewerConfig.tabBarHeight() + 8.0f32

    /// ツリーパネルの背景 + ノードツリー行を構築する
    pub def build(scene: SceneTree.Node, treeState: ViewerState.TreeState): SceneTree.Node =
        // パネル背景
        let panelBg = Sprite2D.init({name = "treePanelBg",
                                     pos = {x = 0.0f32, y = ViewerConfig.tabBarHeight()},
                                     size = {x = ViewerConfig.treePanelWidth(),
                                             y = Int32.toFloat32(ViewerConfig.screenHeight()) - ViewerConfig.tabBarHeight()},
                                     texture = "white"})
                          |> Sprite2D.color({r = 0.12f32, g = 0.12f32, b = 0.15f32});
        // ツリー行を生成
        let rows = buildRows(scene, treeState, 0, 0);
        let rowNodes = rows |> List.map(row -> row#node);
        SceneTree.node2D("TreePanel", Vec2D.zero(),
            panelBg :: rowNodes)

    /// ツリーの行情報
    type alias TreeRow = {
        node = SceneTree.Node, // 表示用のノード
        rowIndex = Int32       // 行インデックス
    }

    /// ノードツリーを深さ優先で走査し、各行の Label ノードリストを生成する
    def buildRows(node: SceneTree.Node, treeState: ViewerState.TreeState,
                  depth: Int32, startRow: Int32): List[TreeRow] =
        let SceneTree.Node.MkNode(name, _, kind, nodeChildren) = node;
        let hasChildren = not List.isEmpty(nodeChildren);
        let isExpanded = Set.memberOf(name, treeState#expandedNodes);
        let isSelected = treeState#selectedNode == Some(name);
        // 展開アイコン
        let icon = if (hasChildren)
            (if (isExpanded) "v " else "> ")
        else "- ";
        // 型名
        let typeName = NodeVisual.kindName(kind);
        let displayText = "${icon}${name} [${typeName}]";
        // 位置計算
        let xPos = textStartX() + Int32.toFloat32(depth) * indentWidth();
        let yPos = textStartY() + Int32.toFloat32(startRow) * rowHeight();
        // 選択ハイライト背景
        let highlight = if (isSelected)
            Sprite2D.init({name = "tree_hl_${name}",
                           pos = {x = 0.0f32, y = yPos - 2.0f32},
                           size = {x = ViewerConfig.treePanelWidth(), y = rowHeight()},
                           texture = "white"})
                |> Sprite2D.color({r = 0.25f32, g = 0.35f32, b = 0.55f32}) :: Nil
        else Nil;
        // テキストラベル
        let label = Label2D.init({name = "tree_${name}",
                                  pos = {x = xPos, y = yPos},
                                  text = displayText, fontSize = 18.0f32,
                                  font = ViewerConfig.defaultFont()})
                        |> Label2D.color({r = 0.85f32, g = 0.85f32, b = 0.85f32});
        // この行を追加
        let thisRow = match highlight {
            case h :: _ =>
                {node = SceneTree.node2D("treeRow_${name}", Vec2D.zero(), h :: label :: Nil),
                 rowIndex = startRow}
            case Nil =>
                {node = label, rowIndex = startRow}
        };
        // 子ノードを展開中なら再帰的に行を追加
        if (hasChildren and isExpanded) {
            let childRows = buildChildRows(nodeChildren, treeState, depth + 1, startRow + 1);
            thisRow :: childRows
        } else {
            thisRow :: Nil
        }

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

    /// マウスクリック位置からノード名を特定する（ツリーパネル内のとき）
    pub def hitTest(mouseX: Float32, mouseY: Float32, scene: SceneTree.Node,
                    treeState: ViewerState.TreeState): Option[String] =
        if (mouseX >= ViewerConfig.treePanelWidth()) None
        else {
            let relY = mouseY - textStartY();
            if (relY < 0.0f32) None
            else {
                let rowIndex = Vec2D.floatToInt32(relY / rowHeight());
                let rows = buildRows(scene, treeState, 0, 0);
                findRowNode(rows, rowIndex)
            }
        }

    /// 指定行インデックスに対応するノード名を検索する
    def findRowNode(rows: List[TreeRow], targetRow: Int32): Option[String] =
        match rows {
            case Nil => None
            case row :: rest =>
                if (row#rowIndex == targetRow) {
                    // 行ノードの名前から "tree_" プレフィクスを除去
                    let SceneTree.Node.MkNode(rowNodeName, _, _, _) = row#node;
                    // treeRow_ プレフィクスの場合は内部の label 名を使う
                    if (String.startsWith({prefix = "treeRow_"}, rowNodeName))
                        Some(String.stripPrefix({substr = "treeRow_"}, rowNodeName)
                             |> Option.getWithDefault(rowNodeName))
                    else
                        Some(String.stripPrefix({substr = "tree_"}, rowNodeName)
                             |> Option.getWithDefault(rowNodeName))
                }
                else findRowNode(rest, targetRow)
        }

    /// ノードの展開状態をトグルする
    pub def toggleExpand(nodeName: String, treeState: ViewerState.TreeState): ViewerState.TreeState =
        if (Set.memberOf(nodeName, treeState#expandedNodes))
            {expandedNodes = Set.remove(nodeName, treeState#expandedNodes) | treeState}
        else
            {expandedNodes = Set.insert(nodeName, treeState#expandedNodes) | treeState}
}
