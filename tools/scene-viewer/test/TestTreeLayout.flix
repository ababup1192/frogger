// TestTreeLayout — TreeLayout モジュールの座標計算ロジックのテスト

mod TestTreeLayout {

    /// 浮動小数点の近似比較
    def approx(a: Float32, b: Float32): Bool =
        Float32.abs(a - b) < 0.001f32

    /// テスト用 Plain ノードを作成する
    def mkPlainNode(name: String, children: List[SceneTree.Node]): SceneTree.Node =
        SceneTree.Node.MkNode(name, Vec2D.zero(), SceneTree.NodeKind.Plain, children)

    /// テスト用ツリー:
    ///   Root
    ///   ├── ChildA
    ///   │   └── GrandchildA1
    ///   └── ChildB
    def testTree(): SceneTree.Node =
        let grandchildA1 = mkPlainNode("GrandchildA1", Nil);
        let childA = mkPlainNode("ChildA", grandchildA1 :: Nil);
        let childB = mkPlainNode("ChildB", Nil);
        mkPlainNode("Root", childA :: childB :: Nil)

    /// テスト用のレイアウト設定（計算しやすい値）
    def testConfig(): TreeLayout.LayoutConfig = {
        rowHeight = 30.0f32,
        indentWidth = 20.0f32,
        textStartX = 10.0f32,
        contentStartY = 50.0f32,
        fontSize = 20.0f32
    }

    // ========================================================================
    // flattenTree
    // ========================================================================

    /// ルートのみ展開 → Root, ChildA, ChildB の3行
    @Test
    def testFlattenTreeRootExpanded(): Unit \ Assert =
        let rows = TreeLayout.flattenTree(testTree(), Set#{"Root"});
        let names = rows |> List.map(row -> row#nodeName);
        Assert.assertTrue(names == "Root" :: "ChildA" :: "ChildB" :: Nil)

    /// ルートと ChildA を展開 → 4行（Root, ChildA, GrandchildA1, ChildB）
    @Test
    def testFlattenTreeChildAExpanded(): Unit \ Assert =
        let rows = TreeLayout.flattenTree(testTree(), Set#{"Root", "ChildA"});
        let names = rows |> List.map(row -> row#nodeName);
        Assert.assertTrue(names == "Root" :: "ChildA" :: "GrandchildA1" :: "ChildB" :: Nil)

    /// 何も展開しない → Root のみの1行
    @Test
    def testFlattenTreeNoneExpanded(): Unit \ Assert =
        let rows = TreeLayout.flattenTree(testTree(), Set.empty());
        let names = rows |> List.map(row -> row#nodeName);
        Assert.assertTrue(names == "Root" :: Nil)

    /// 行の depth が正しい（Root=0, ChildA=1, GrandchildA1=2, ChildB=1）
    @Test
    def testFlattenTreeDepths(): Unit \ Assert =
        let rows = TreeLayout.flattenTree(testTree(), Set#{"Root", "ChildA"});
        let depths = rows |> List.map(row -> row#depth);
        Assert.assertTrue(depths == 0 :: 1 :: 2 :: 1 :: Nil)

    /// rowIndex が連番になっている
    @Test
    def testFlattenTreeRowIndices(): Unit \ Assert =
        let rows = TreeLayout.flattenTree(testTree(), Set#{"Root", "ChildA"});
        let indices = rows |> List.map(row -> row#rowIndex);
        Assert.assertTrue(indices == 0 :: 1 :: 2 :: 3 :: Nil)

    /// hasChildren フラグが正しい
    @Test
    def testFlattenTreeHasChildren(): Unit \ Assert =
        let rows = TreeLayout.flattenTree(testTree(), Set#{"Root", "ChildA"});
        let flags = rows |> List.map(row -> row#hasChildren);
        // Root=true, ChildA=true, GrandchildA1=false, ChildB=false
        Assert.assertTrue(flags == true :: true :: false :: false :: Nil)

    /// isExpanded フラグが正しい
    @Test
    def testFlattenTreeIsExpanded(): Unit \ Assert =
        let rows = TreeLayout.flattenTree(testTree(), Set#{"Root", "ChildA"});
        let flags = rows |> List.map(row -> row#isExpanded);
        // Root=expanded, ChildA=expanded, GrandchildA1=not, ChildB=not
        Assert.assertTrue(flags == true :: true :: false :: false :: Nil)

    // ========================================================================
    // rowTopY
    // ========================================================================

    /// row 0 → contentStartY
    @Test
    def testRowTopYFirst(): Unit \ Assert =
        let config = testConfig();
        Assert.assertTrue(approx(TreeLayout.rowTopY(config, 0), 50.0f32))

    /// row 1 → contentStartY + rowHeight
    @Test
    def testRowTopYSecond(): Unit \ Assert =
        let config = testConfig();
        Assert.assertTrue(approx(TreeLayout.rowTopY(config, 1), 80.0f32))

    /// row N → contentStartY + N * rowHeight
    @Test
    def testRowTopYNth(): Unit \ Assert =
        let config = testConfig();
        Assert.assertTrue(approx(TreeLayout.rowTopY(config, 5), 200.0f32))

    // ========================================================================
    // labelY
    // ========================================================================

    /// labelY は rowTopY より下にある（ベースラインは行の上端より下）
    @Test
    def testLabelYAboveRowTop(): Unit \ Assert =
        let config = testConfig();
        Assert.assertTrue(TreeLayout.labelY(config, 0) > TreeLayout.rowTopY(config, 0))

    /// labelY は rowTopY + rowHeight より上にある（ベースラインは行の下端より上）
    @Test
    def testLabelYBelowRowBottom(): Unit \ Assert =
        let config = testConfig();
        let top = TreeLayout.rowTopY(config, 0);
        Assert.assertTrue(TreeLayout.labelY(config, 0) < top + config#rowHeight)

    /// テキスト上端（labelY - fontSize*0.75）が rowTopY 以上
    @Test
    def testLabelYTextTopWithinRow(): Unit \ Assert =
        let config = testConfig();
        let ly = TreeLayout.labelY(config, 0);
        let textTop = ly - config#fontSize * 0.75f32;
        Assert.assertTrue(textTop >= TreeLayout.rowTopY(config, 0))

    /// テキスト下端（labelY + fontSize*0.2）が rowTopY + rowHeight 以下
    @Test
    def testLabelYTextBottomWithinRow(): Unit \ Assert =
        let config = testConfig();
        let ly = TreeLayout.labelY(config, 0);
        let textBottom = ly + config#fontSize * 0.2f32;
        let rowBottom = TreeLayout.rowTopY(config, 0) + config#rowHeight;
        Assert.assertTrue(textBottom <= rowBottom)

    /// labelY の具体値を検証
    /// rowTopY(0) = 50, labelY = 50 + 30/2 + 20*0.275 = 50 + 15 + 5.5 = 70.5
    @Test
    def testLabelYConcreteValue(): Unit \ Assert =
        let config = testConfig();
        Assert.assertTrue(approx(TreeLayout.labelY(config, 0), 70.5f32))

    // ========================================================================
    // labelX
    // ========================================================================

    /// depth 0 → textStartX
    @Test
    def testLabelXDepthZero(): Unit \ Assert =
        let config = testConfig();
        Assert.assertTrue(approx(TreeLayout.labelX(config, 0), 10.0f32))

    /// depth 2 → textStartX + 2 * indentWidth = 10 + 40 = 50
    @Test
    def testLabelXDepthTwo(): Unit \ Assert =
        let config = testConfig();
        Assert.assertTrue(approx(TreeLayout.labelX(config, 2), 50.0f32))

    // ========================================================================
    // hitTestRow
    // ========================================================================

    /// 行の中央をクリック → 正しいノード名が返る
    @Test
    def testHitTestRowCenter(): Unit \ Assert =
        let config = testConfig();
        let rows = TreeLayout.flattenTree(testTree(), Set#{"Root"});
        // row 1 (ChildA) の中央: rowTopY(1) + rowHeight/2 = 80 + 15 = 95
        let result = TreeLayout.hitTestRow(config, 95.0f32, rows);
        Assert.assertTrue(result == Some("ChildA"))

    /// 行の上端をクリック → 正しいノード名が返る
    @Test
    def testHitTestRowTop(): Unit \ Assert =
        let config = testConfig();
        let rows = TreeLayout.flattenTree(testTree(), Set#{"Root"});
        // row 0 (Root) の上端: rowTopY(0) = 50
        let result = TreeLayout.hitTestRow(config, 50.0f32, rows);
        Assert.assertTrue(result == Some("Root"))

    /// 行の下端（-0.1px）をクリック → 正しいノード名が返る
    @Test
    def testHitTestRowBottomEdge(): Unit \ Assert =
        let config = testConfig();
        let rows = TreeLayout.flattenTree(testTree(), Set#{"Root"});
        // row 0 (Root) の下端直前: rowTopY(0) + rowHeight - 0.1 = 50 + 30 - 0.1 = 79.9
        let result = TreeLayout.hitTestRow(config, 79.9f32, rows);
        Assert.assertTrue(result == Some("Root"))

    /// contentStartY より上をクリック → None
    @Test
    def testHitTestRowAboveContent(): Unit \ Assert =
        let config = testConfig();
        let rows = TreeLayout.flattenTree(testTree(), Set#{"Root"});
        let result = TreeLayout.hitTestRow(config, 40.0f32, rows);
        Assert.assertTrue(result == None)

    /// 全行の下をクリック → None
    @Test
    def testHitTestRowBelowAll(): Unit \ Assert =
        let config = testConfig();
        let rows = TreeLayout.flattenTree(testTree(), Set#{"Root"});
        // 3行あるので最下端 = rowTopY(2) + rowHeight = 110 + 30 = 140
        let result = TreeLayout.hitTestRow(config, 150.0f32, rows);
        Assert.assertTrue(result == None)

    /// 折り畳まれたノードの子はヒットしない
    @Test
    def testHitTestRowCollapsedChildNotHit(): Unit \ Assert =
        let config = testConfig();
        // ChildA を折り畳む → GrandchildA1 は表示されない
        let rows = TreeLayout.flattenTree(testTree(), Set#{"Root"});
        // rows は Root, ChildA, ChildB の3行のみ
        // row 2 は ChildB であって GrandchildA1 ではない
        let result = TreeLayout.hitTestRow(config, 115.0f32, rows);
        Assert.assertTrue(result == Some("ChildB"))

    // ========================================================================
    // displayText
    // ========================================================================

    /// 子あり展開 → "v Name [Type]"
    @Test
    def testDisplayTextExpandedWithChildren(): Unit \ Assert =
        let row: TreeLayout.FlatRow = {nodeName = "Root", depth = 0, rowIndex = 0,
                                        hasChildren = true, isExpanded = true, typeName = "Node2D",
                                        nodeKind = SceneTree.NodeKind.Plain};
        Assert.assertTrue(TreeLayout.displayText(row) == "v Root [Node2D]")

    /// 子あり折り畳み → "> Name [Type]"
    @Test
    def testDisplayTextCollapsedWithChildren(): Unit \ Assert =
        let row: TreeLayout.FlatRow = {nodeName = "Root", depth = 0, rowIndex = 0,
                                        hasChildren = true, isExpanded = false, typeName = "Node2D",
                                        nodeKind = SceneTree.NodeKind.Plain};
        Assert.assertTrue(TreeLayout.displayText(row) == "> Root [Node2D]")

    /// 子なし → "- Name [Type]"
    @Test
    def testDisplayTextLeaf(): Unit \ Assert =
        let row: TreeLayout.FlatRow = {nodeName = "Leaf", depth = 1, rowIndex = 1,
                                        hasChildren = false, isExpanded = false, typeName = "Node2D",
                                        nodeKind = SceneTree.NodeKind.Plain};
        Assert.assertTrue(TreeLayout.displayText(row) == "- Leaf [Node2D]")
}
