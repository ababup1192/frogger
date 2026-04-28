// ViewerApp — Scene Viewer のゲームループ（状態管理 + update + render）

mod ViewerApp {
    /// ビューワーを開始し、ゲームループに入る
    pub def start(sceneFiles: List[String]): Unit \ {Engine.Game, Engine.Mouse, Fs.FileRead} =
        let firstFile = sceneFiles |> List.head |> Option.getWithDefault("");
        let scene = SceneLoader.loadScene(firstFile);
        let state = ViewerState.initialState(sceneFiles, scene)
            |> applyInitialView;
        discard runLoop(state)

    /// シーンに合わせた初期ビューを適用する
    def applyInitialView(state: ViewerState.State): ViewerState.State =
        {canvasState = CanvasPanel.initialView(state#loadedScene) | state}

    /// メインループ（末尾再帰）
    @Tailrec
    def runLoop(state: ViewerState.State): ViewerState.State \ {Engine.Game, Engine.Mouse, Fs.FileRead} =
        if (Engine.Game.shouldClose() or Engine.Game.isKeyPressed(Engine.Key.Escape)) state
        else {
            let newState = update(state);
            let viewerScene = buildViewerScene(newState);
            Engine.Game.render(viewerScene);
            runLoop(newState)
        }

    // ========================================================================
    // 入力処理
    // ========================================================================

    /// 監視対象のキーを収集する
    def collectPressedKeys(): Set[Engine.Key] \ Engine.Game =
        let keys = Engine.Key.Tab :: Engine.Key.R :: Engine.Key.F :: Engine.Key.D ::
                   Engine.Key.Up :: Engine.Key.Down :: Engine.Key.Left :: Engine.Key.Right ::
                   Engine.Key.Equal :: Engine.Key.Minus :: Engine.Key.Semicolon ::
                   Engine.Key.LeftShift :: Engine.Key.RightShift :: Nil;
        List.foldLeft((acc, key) ->
            if (Engine.Game.isKeyPressed(key)) Set.insert(key, acc) else acc,
            Set.empty(), keys)

    /// エッジ検出（今フレームで新たに押されたキーを検出する）
    def justPressed(curr: Set[Engine.Key], prev: Set[Engine.Key]): Set[Engine.Key] =
        Set.difference(curr, prev)

    /// Shift キーが押されているかどうか
    def isShiftHeld(keys: Set[Engine.Key]): Bool =
        Set.memberOf(Engine.Key.LeftShift, keys) or Set.memberOf(Engine.Key.RightShift, keys)

    // ========================================================================
    // 状態更新
    // ========================================================================

    /// フレームごとの状態更新
    def update(state: ViewerState.State): ViewerState.State \ {Engine.Game, Engine.Mouse, Fs.FileRead} =
        let currKeys = collectPressedKeys();
        let jp = justPressed(currKeys, state#prevKeys);
        let mousePressed = Engine.Mouse.isMousePressed();
        let mouseX = Engine.Mouse.getMouseX();
        let mouseY = Engine.Mouse.getMouseY();
        // ファイル切り替え（Tab / Shift+Tab）
        let afterSwitch =
            if (Set.memberOf(Engine.Key.Tab, jp)) {
                let switched = if (isShiftHeld(currKeys))
                    SceneBrowser.switchPrev(state)
                else
                    SceneBrowser.switchNext(state);
                ensureTabVisible(switched)
            }
            else if (Set.memberOf(Engine.Key.R, jp))
                SceneBrowser.reload(state)
            else state;
        // キャンバスのパン操作（矢印キー）
        let panSpeed = 8.0f32;
        let afterPan = {
            let dx = (if (Engine.Game.isKeyPressed(Engine.Key.Right)) panSpeed else 0.0f32) -
                     (if (Engine.Game.isKeyPressed(Engine.Key.Left)) panSpeed else 0.0f32);
            let dy = (if (Engine.Game.isKeyPressed(Engine.Key.Down)) panSpeed else 0.0f32) -
                     (if (Engine.Game.isKeyPressed(Engine.Key.Up)) panSpeed else 0.0f32);
            if (dx != 0.0f32 or dy != 0.0f32)
                let newPan = Vec2D.add(afterSwitch#canvasState#panOffset, {x = dx, y = dy});
                {canvasState = {panOffset = newPan | afterSwitch#canvasState} |> CanvasPanel.clampPan | afterSwitch}
            else afterSwitch
        };
        // ズーム操作（+: ズームイン / -: ズームアウト）— キャンバス中心を基準にズーム
        // Equal = US配列の +/= キー、Shift+Semicolon = JIS配列の + キー
        let zoomInPressed = Set.memberOf(Engine.Key.Equal, jp) or
            (Set.memberOf(Engine.Key.Semicolon, jp) and isShiftHeld(currKeys));
        let afterZoom =
            if (zoomInPressed) {
                let newZoom = Float32.min(4.0f32, afterPan#canvasState#zoom + 0.25f32);
                {canvasState = CanvasPanel.zoomAtCenter(newZoom, afterPan#canvasState) | afterPan}
            } else if (Set.memberOf(Engine.Key.Minus, jp)) {
                let newZoom = Float32.max(0.25f32, afterPan#canvasState#zoom - 0.25f32);
                {canvasState = CanvasPanel.zoomAtCenter(newZoom, afterPan#canvasState) | afterPan}
            } else if (Set.memberOf(Engine.Key.F, jp)) {
                {canvasState = CanvasPanel.initialView(afterPan#loadedScene) | afterPan}
            } else afterPan;
        // デバッグ表示トグル（D キー）
        let afterDebug =
            if (Set.memberOf(Engine.Key.D, jp))
                {debugView = not afterZoom#debugView | afterZoom}
            else afterZoom;
        // マウスクリック処理
        let afterClick =
            if (mousePressed and not state#prevMousePressed) {
                if (mouseX < ViewerConfig.treePanelWidth()) {
                    // ツリーパネルのクリック
                    match TreePanel.hitTest(mouseX, mouseY, afterDebug#loadedScene, afterDebug#treeState) {
                        case Some(nodeName) =>
                            let newTreeState = afterDebug#treeState
                                |> TreePanel.toggleExpand(nodeName);
                            {treeState = {selectedNode = Some(nodeName) | newTreeState} | afterDebug}
                        case None =>
                        {treeState = {selectedNode = None | afterDebug#treeState} | afterDebug}
                    }
                } else if (mouseY > ViewerConfig.tabBarHeight()) {
                    // キャンバスパネルのクリック — 選択解除
                    {treeState = {selectedNode = None | afterDebug#treeState} | afterDebug}
                } else {
                    // タブバーのクリック — ファイル選択
                    handleTabClick(mouseX, afterDebug)
                }
            } else afterDebug;
        // アニメーションを進める
        let dt = Engine.Game.getDeltaTime();
        let afterAnim = {loadedScene = SceneTree.stepAnimations(dt, afterClick#loadedScene) | afterClick};
        // 入力状態を更新
        {prevKeys = currKeys, prevMousePressed = mousePressed | afterAnim}

    /// テキストの文字数からタブ幅を推定する（fontSize 18 で 1文字あたり約 10px + 左右パディング）
    def tabWidth(fileName: String): Float32 =
        let charWidth = 10.0f32;
        let padding = 20.0f32;
        Int32.toFloat32(String.length(fileName)) * charWidth + padding

    /// ファイル名リストからタブの累積X座標を計算する（各要素は対応するタブの左端）
    def tabOffsets(fileNames: List[String]): List[Float32] =
        let gap = 2.0f32;
        fileNames
            |> List.foldLeft((acc, name) -> {
                let offset = match List.last(acc) {
                    case Some((prevOffset, prevName)) => prevOffset + tabWidth(prevName) + gap
                    case None => 0.0f32
                };
                List.append(acc, (offset, name) :: Nil)
            }, Nil)
            |> List.map(match (offset, _) -> offset)

    /// アクティブタブが表示領域に収まるようスクロールオフセットを調整する
    def ensureTabVisible(state: ViewerState.State): ViewerState.State =
        let fileNames = state#sceneFiles |> List.map(extractFileName);
        let offsets = tabOffsets(fileNames);
        let activeOffset = offsets |> List.nth(state#currentFileIndex) |> Option.getWithDefault(0.0f32);
        let activeName = fileNames |> List.nth(state#currentFileIndex) |> Option.getWithDefault("");
        let activeWidth = tabWidth(activeName);
        let visibleWidth = Int32.toFloat32(ViewerConfig.screenWidth()) - ViewerConfig.treePanelWidth();
        let scrollX = state#tabScrollX;
        // タブの右端が表示領域の右端より右にはみ出ている場合
        let scrollX1 =
            if (activeOffset + activeWidth + scrollX > visibleWidth)
                visibleWidth - activeOffset - activeWidth
            else scrollX;
        // タブの左端が表示領域の左端より左にはみ出ている場合
        let scrollX2 =
            if (activeOffset + scrollX1 < 0.0f32)
                0.0f32 - activeOffset
            else scrollX1;
        // スクロールは0以下（左方向のみ）
        let finalScrollX = Float32.min(0.0f32, scrollX2);
        {tabScrollX = finalScrollX | state}

    /// タブバーのクリックでファイルを切り替える
    def handleTabClick(mouseX: Float32, state: ViewerState.State): ViewerState.State \ Fs.FileRead =
        let relX = mouseX - ViewerConfig.treePanelWidth() - state#tabScrollX;
        let fileNames = state#sceneFiles |> List.map(extractFileName);
        let offsets = tabOffsets(fileNames);
        let clickedIndex = List.zip(fileNames, offsets)
            |> List.mapWithIndex((index, nameAndOffset) -> (index, nameAndOffset))
            |> List.findMap(match (index, (name, offset)) ->
                if (relX >= offset and relX < offset + tabWidth(name)) Some(index) else None);
        match clickedIndex {
            case Some(index) if index != state#currentFileIndex =>
                SceneBrowser.reload({currentFileIndex = index | state})
                    |> ensureTabVisible
            case _ => state
        }

    // ========================================================================
    // シーン構築
    // ========================================================================

    /// ヘルプバーの高さ（ピクセル）
    def helpBarHeight(): Float32 = 28.0f32

    /// ビューワー UI 全体を SceneTree.Node として構築する
    def buildViewerScene(state: ViewerState.State): SceneTree.Node =
        let tabBar = buildTabBar(state);
        let treePanel = TreePanel.build(state#loadedScene, state#treeState, state#debugView);
        let canvasPanel = CanvasPanel.build(state#loadedScene, state#canvasState, state#treeState#selectedNode, state#debugView);
        let helpBar = buildHelpBar(state);
        // パネル境界線
        let divider = Sprite2D.init({name = "divider",
                                     pos = {x = ViewerConfig.treePanelWidth() - 1.0f32,
                                            y = ViewerConfig.tabBarHeight()},
                                     size = {x = 2.0f32,
                                             y = Int32.toFloat32(ViewerConfig.screenHeight()) - ViewerConfig.tabBarHeight()},
                                     texture = "white"})
                          |> Sprite2D.color({r = 0.3f32, g = 0.3f32, b = 0.35f32});
        SceneTree.node2D("ViewerRoot", Vec2D.zero(),
            tabBar :: treePanel :: canvasPanel :: divider :: helpBar :: Nil)

    /// ファイルタブバーを構築する
    def buildTabBar(state: ViewerState.State): SceneTree.Node =
        // タブバー背景
        let tabBg = Sprite2D.init({name = "tabBarBg",
                                   pos = Vec2D.zero(),
                                   size = {x = Int32.toFloat32(ViewerConfig.screenWidth()),
                                           y = ViewerConfig.tabBarHeight()},
                                   texture = "white"})
                        |> Sprite2D.color({r = 0.1f32, g = 0.1f32, b = 0.13f32});
        let fileNames = state#sceneFiles |> List.map(extractFileName);
        let offsets = tabOffsets(fileNames);
        let tabs = List.zip(fileNames, offsets)
            |> List.mapWithIndex((index, nameAndOffset) -> {
                let (fileName, offset) = nameAndOffset;
                let isActive = index == state#currentFileIndex;
                let tabX = ViewerConfig.treePanelWidth() + offset + state#tabScrollX;
                let tw = tabWidth(fileName);
                let bgColor = if (isActive) {r = 0.25f32, g = 0.28f32, b = 0.35f32}
                              else {r = 0.1f32, g = 0.1f32, b = 0.13f32};
                let tabBgSprite = Sprite2D.init({name = "tab_bg_${index}",
                                                 pos = {x = tabX, y = 0.0f32},
                                                 size = {x = tw, y = ViewerConfig.tabBarHeight()},
                                                 texture = "white"})
                                     |> Sprite2D.color(bgColor);
                let textColor = if (isActive) {r = 1.0f32, g = 1.0f32, b = 1.0f32}
                                else {r = 0.6f32, g = 0.6f32, b = 0.6f32};
                let tabLabel = Label2D.init({name = "tab_lbl_${index}",
                                            pos = {x = tabX + 8.0f32, y = 18.0f32},
                                            text = fileName, fontSize = 18.0f32,
                                            font = ViewerConfig.defaultFont()})
                                   |> Label2D.color(textColor);
                SceneTree.node2D("tab_${index}", Vec2D.zero(), tabBgSprite :: tabLabel :: Nil)
            });
        SceneTree.node2D("TabBar", Vec2D.zero(), tabBg :: tabs)

    /// 画面下部にキー操作ヒントとズーム倍率を表示するバーを構築する
    def buildHelpBar(state: ViewerState.State): SceneTree.Node =
        let screenH = Int32.toFloat32(ViewerConfig.screenHeight());
        let screenW = Int32.toFloat32(ViewerConfig.screenWidth());
        let barY = screenH - helpBarHeight();
        // 背景
        let bg = Sprite2D.init({name = "helpBarBg",
                                pos = {x = 0.0f32, y = barY},
                                size = {x = screenW, y = helpBarHeight()},
                                texture = "white"})
                    |> Sprite2D.color({r = 0.08f32, g = 0.08f32, b = 0.1f32});
        // キーヒントテキスト
        let zoomPct = Vec2D.floatToInt32(state#canvasState#zoom * 100.0f32);
        let modeText = if (state#debugView) "Debug" else "Texture";
        let helpText = "Tab: File Switch | Arrows: Pan | +/-: Zoom | F: Fit | D: ${modeText} | R: Reload | Zoom: ${zoomPct}%";
        let label = Label2D.init({name = "helpBarLabel",
                                  pos = {x = 8.0f32, y = barY + 8.0f32},
                                  text = helpText, fontSize = 14.0f32,
                                  font = ViewerConfig.defaultFont()})
                       |> Label2D.color({r = 0.6f32, g = 0.6f32, b = 0.65f32});
        SceneTree.node2D("HelpBar", Vec2D.zero(), bg :: label :: Nil)

    /// ファイルパスから表示用の短いファイル名を抽出する（.scene.json を除去）
    def extractFileName(path: String): String =
        path
            |> String.split({regex = "/"})
            |> List.last
            |> Option.getWithDefault(path)
            |> String.replace({src = ".scene.json"}, {dst = ""})
}
