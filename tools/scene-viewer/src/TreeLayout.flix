// TreeLayout — ツリーパネルの座標計算ロジック（レンダリング非依存）

mod TreeLayout {
    /// レイアウトの設定値
    pub type alias LayoutConfig = {
        rowHeight = Float32,      // 1行の高さ（ピクセル）
        indentWidth = Float32,    // インデント幅（深さ1あたりのピクセル）
        textStartX = Float32,     // テキストの開始 X 位置
        contentStartY = Float32,  // ツリー領域の Y 開始位置
        fontSize = Float32        // フォントサイズ
    }

    /// ツリーをフラットにした1行の情報
    pub type alias FlatRow = {
        nodeName = String,        // ノード名（ヒットテスト結果として使用）
        depth = Int32,            // ネストの深さ（0始まり）
        rowIndex = Int32,         // 行番号（0始まり）
        hasChildren = Bool,       // 子ノードを持つか
        isExpanded = Bool,        // 展開中か
        typeName = String,        // 表示用の型名
        nodeKind = SceneTree.NodeKind  // ノードの種別（色スウォッチ用）
    }

    /// デフォルトのレイアウト設定を返す
    pub def defaultConfig(): LayoutConfig = {
        rowHeight = 28.0f32,
        indentWidth = 24.0f32,
        textStartX = 8.0f32,
        contentStartY = ViewerConfig.tabBarHeight() + 8.0f32,
        fontSize = 18.0f32
    }

    /// シーンツリーを展開状態に従ってフラットな行リストに変換する
    pub def flattenTree(scene: SceneTree.Node, expandedNodes: Set[String]): List[FlatRow] =
        flattenNode(scene, expandedNodes, 0, 0) |> fst

    /// ノードを再帰的にフラット化する（行リストと次の行番号を返す）
    def flattenNode(node: SceneTree.Node, expandedNodes: Set[String],
                    depth: Int32, startRow: Int32): (List[FlatRow], Int32) =
        let SceneTree.Node.MkNode(name, _, kind, children) = node;
        let hasChildren = not List.isEmpty(children);
        let isExpanded = Set.memberOf(name, expandedNodes);
        let typeName = NodeVisual.kindName(kind);
        let row = {nodeName = name, depth = depth, rowIndex = startRow,
                   hasChildren = hasChildren, isExpanded = isExpanded, typeName = typeName,
                   nodeKind = kind};
        if (hasChildren and isExpanded) {
            let (childRows, nextRow) = flattenChildren(children, expandedNodes, depth + 1, startRow + 1);
            (row :: childRows, nextRow)
        } else {
            (row :: Nil, startRow + 1)
        }

    /// 子ノードリストを順に処理し、行インデックスを累積する
    def flattenChildren(children: List[SceneTree.Node], expandedNodes: Set[String],
                        depth: Int32, startRow: Int32): (List[FlatRow], Int32) =
        match children {
            case Nil => (Nil, startRow)
            case child :: rest =>
                let (rows, nextRow) = flattenNode(child, expandedNodes, depth, startRow);
                let (restRows, finalRow) = flattenChildren(rest, expandedNodes, depth, nextRow);
                (List.append(rows, restRows), finalRow)
        }

    /// 行の上端 Y 座標を計算する
    pub def rowTopY(config: LayoutConfig, rowIndex: Int32): Float32 =
        config#contentStartY + Int32.toFloat32(rowIndex) * config#rowHeight

    /// ラベルのベースライン Y 座標を計算する（行内でテキストを縦中央に配置）
    ///
    /// Label2D の Y はベースライン位置として解釈される:
    ///   テキスト上端 = Y - fontSize * 0.75
    ///   テキスト下端 = Y + fontSize * 0.2
    ///   テキスト中心 = Y - fontSize * 0.275
    /// 行の中央にテキスト中心を合わせるため:
    ///   baseline = rowTopY + rowHeight/2 + fontSize * 0.275
    pub def labelY(config: LayoutConfig, rowIndex: Int32): Float32 =
        rowTopY(config, rowIndex) + config#rowHeight / 2.0f32 + config#fontSize * 0.275f32

    /// ラベルの X 位置を計算する
    pub def labelX(config: LayoutConfig, depth: Int32): Float32 =
        config#textStartX + Int32.toFloat32(depth) * config#indentWidth

    /// マウス Y 座標から該当する行のノード名を特定する
    pub def hitTestRow(config: LayoutConfig, mouseY: Float32, rows: List[FlatRow]): Option[String] =
        match rows {
            case Nil => None
            case row :: rest =>
                let top = rowTopY(config, row#rowIndex);
                if (mouseY >= top and mouseY < top + config#rowHeight)
                    Some(row#nodeName)
                else
                    hitTestRow(config, mouseY, rest)
        }

    /// FlatRow から表示テキストを生成する
    pub def displayText(row: FlatRow): String =
        let icon = if (row#hasChildren)
            (if (row#isExpanded) "v " else "> ")
        else "- ";
        "${icon}${row#nodeName} [${row#typeName}]"
}
