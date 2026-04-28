// ViewerState — Scene Viewer の状態型定義

mod ViewerState {
    /// ツリーパネルの表示状態
    pub type alias TreeState = {
        expandedNodes = Set[String],    // 展開中のノード名セット
        selectedNode = Option[String],  // 選択中のノード名
        scrollY = Float32               // スクロール位置（Y軸）
    }

    /// キャンバスパネルの表示状態
    pub type alias CanvasState = {
        panOffset = Vec2D.Vec2, // パンのオフセット
        zoom = Float32          // ズーム倍率
    }

    /// ビューワー全体の状態
    pub type alias State = {
        sceneFiles = List[String],      // ディレクトリ内の .scene.json パスリスト
        currentFileIndex = Int32,       // 現在選択中のファイルインデックス
        loadedScene = SceneTree.Node,   // 読み込んだシーンツリー
        treeState = TreeState,          // ツリーパネルの状態
        canvasState = CanvasState,      // キャンバスパネルの状態
        tabScrollX = Float32,          // タブバーの横スクロールオフセット（0以下の値）
        debugView = Bool,              // true: 色分け矩形表示、false: テクスチャ表示
        prevKeys = Set[Engine.Key],     // 前フレームの押下キーセット（エッジ検出用）
        prevMousePressed = Bool         // 前フレームのマウスボタン状態（エッジ検出用）
    }

    /// ツリーパネルの初期状態を生成する（ルートノードは展開済み）
    pub def initialTreeState(scene: SceneTree.Node): TreeState =
        let SceneTree.Node.MkNode(rootName, _, _, _) = scene;
        {expandedNodes = Set#{rootName}, selectedNode = None, scrollY = 0.0f32}

    /// キャンバスパネルの初期状態を生成する
    pub def initialCanvasState(): CanvasState =
        {panOffset = Vec2D.zero(), zoom = 1.0f32}

    /// 初期状態を生成する
    pub def initialState(sceneFiles: List[String], scene: SceneTree.Node): State = {
        sceneFiles = sceneFiles,
        currentFileIndex = 0,
        loadedScene = scene,
        treeState = initialTreeState(scene),
        canvasState = initialCanvasState(),
        tabScrollX = 0.0f32,
        debugView = false,
        prevKeys = Set.empty(),
        prevMousePressed = false
    }
}
