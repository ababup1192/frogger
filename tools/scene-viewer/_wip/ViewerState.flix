// ViewerState — Scene Viewer の状態型定義

mod ViewerState {
    /// ツリーパネルの表示状態
    pub type alias TreeState = {
        /// 展開中のノード名セット
        expandedNodes = Set[String],
        /// 選択中のノード名
        selectedNode = Option[String],
        /// スクロール位置（Y軸）
        scrollY = Float32
    }

    /// キャンバスパネルの表示状態
    pub type alias CanvasState = {
        /// パンのオフセット
        panOffset = Vec2D.Vec2,
        /// ズーム倍率
        zoom = Float32
    }

    /// ビューワー全体の状態
    pub type alias State = {
        /// ディレクトリ内の .scene.json パスリスト
        sceneFiles = List[String],
        /// 現在選択中のファイルインデックス
        currentFileIndex = Int32,
        /// 読み込んだシーンツリー
        loadedScene = SceneTree.Node,
        /// ツリーパネルの状態
        treeState = TreeState,
        /// キャンバスパネルの状態
        canvasState = CanvasState,
        /// 前フレームの押下キーセット（エッジ検出用）
        prevKeys = Set[Engine.Key],
        /// 前フレームのマウスボタン状態（エッジ検出用）
        prevMousePressed = Bool
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
        prevKeys = Set.empty(),
        prevMousePressed = false
    }
}
