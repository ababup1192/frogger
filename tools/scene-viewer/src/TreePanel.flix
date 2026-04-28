// TreePanel — 左パネル: ノードツリーを階層表示する

mod TreePanel {
    /// ツリーパネル全体を構築する
    pub def build(scene: SceneTree.Node, treeState: ViewerState.TreeState, debugView: Bool): SceneTree.Node =
        let config = TreeLayout.defaultConfig();
        let panelBg = Sprite2D.init({name = "treePanelBg",
                                     pos = {x = 0.0f32, y = ViewerConfig.tabBarHeight()},
                                     size = {x = ViewerConfig.treePanelWidth(),
                                             y = Int32.toFloat32(ViewerConfig.screenHeight()) - ViewerConfig.tabBarHeight()},
                                     texture = "white"})
                          |> Sprite2D.color({r = 0.12f32, g = 0.12f32, b = 0.15f32});
        let rows = TreeLayout.flattenTree(scene, treeState#expandedNodes);
        let rowNodes = rows |> List.map(row -> buildRowNode(config, row, treeState, debugView));
        SceneTree.node2D("TreePanel", Vec2D.zero(), panelBg :: rowNodes)

    /// 1行分のノードを構築する（ハイライトとラベルを含む）
    def buildRowNode(config: TreeLayout.LayoutConfig, row: TreeLayout.FlatRow,
                     treeState: ViewerState.TreeState, debugView: Bool): SceneTree.Node =
        let name = row#nodeName;
        let isSelected = treeState#selectedNode == Some(name);
        let baseX = TreeLayout.labelX(config, row#depth);
        let yPos = TreeLayout.labelY(config, row#rowIndex);
        let text = TreeLayout.displayText(row);
        // デバッグモード時は色スウォッチを追加し、テキストを右にシフト
        let swatchSize = 12.0f32;
        let swatchGap = 4.0f32;
        let labelXPos = if (debugView) baseX + swatchSize + swatchGap else baseX;
        let swatchNodes = if (debugView) {
            let visual = NodeVisual.visualForKind(row#nodeKind);
            let rowY = TreeLayout.rowTopY(config, row#rowIndex);
            let swatchY = rowY + (config#rowHeight - swatchSize) / 2.0f32;
            Sprite2D.init({name = "tree_sw_${name}",
                           pos = {x = baseX, y = swatchY},
                           size = {x = swatchSize, y = swatchSize},
                           texture = "white"})
                |> Sprite2D.color(visual#color) :: Nil
        } else Nil;
        let label = Label2D.init({name = "tree_${name}",
                                  pos = {x = labelXPos, y = yPos},
                                  text = text, fontSize = config#fontSize,
                                  font = ViewerConfig.defaultFont()})
                        |> Label2D.color({r = 0.85f32, g = 0.85f32, b = 0.85f32});
        if (isSelected) {
            let rowY = TreeLayout.rowTopY(config, row#rowIndex);
            let highlight = Sprite2D.init({name = "tree_hl_${name}",
                                           pos = {x = 0.0f32, y = rowY},
                                           size = {x = ViewerConfig.treePanelWidth(), y = config#rowHeight},
                                           texture = "white"})
                                |> Sprite2D.color({r = 0.25f32, g = 0.35f32, b = 0.55f32});
            SceneTree.node2D("treeRow_${name}", Vec2D.zero(), List.append(highlight :: Nil, List.append(swatchNodes, label :: Nil)))
        } else
            SceneTree.node2D("treeRow_${name}", Vec2D.zero(), List.append(swatchNodes, label :: Nil))

    /// マウスクリック位置からノード名を特定する
    pub def hitTest(mouseX: Float32, mouseY: Float32, scene: SceneTree.Node,
                    treeState: ViewerState.TreeState): Option[String] =
        if (mouseX >= ViewerConfig.treePanelWidth()) None
        else {
            let config = TreeLayout.defaultConfig();
            let rows = TreeLayout.flattenTree(scene, treeState#expandedNodes);
            TreeLayout.hitTestRow(config, mouseY, rows)
        }

    /// ノードの展開状態をトグルする
    pub def toggleExpand(nodeName: String, treeState: ViewerState.TreeState): ViewerState.TreeState =
        if (Set.memberOf(nodeName, treeState#expandedNodes))
            {expandedNodes = Set.remove(nodeName, treeState#expandedNodes) | treeState}
        else
            {expandedNodes = Set.insert(nodeName, treeState#expandedNodes) | treeState}
}
