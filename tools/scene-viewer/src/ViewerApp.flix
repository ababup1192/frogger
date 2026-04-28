// ViewerApp — Scene Viewer のゲームループ（シーン読み込み + 表示）

mod ViewerApp {
    /// ビューワーを開始し、ゲームループに入る
    pub def start(sceneFiles: List[String]): Unit \ {Engine.Game, Fs.FileRead} =
        let firstFile = sceneFiles |> List.head |> Option.getWithDefault("");
        let scene = SceneLoader.loadScene(firstFile);
        let state = ViewerState.initialState(sceneFiles, scene);
        discard runLoop(state)

    /// メインループ（末尾再帰）
    @Tailrec
    def runLoop(state: ViewerState.State): ViewerState.State \ {Engine.Game, Fs.FileRead} =
        if (Engine.Game.shouldClose() or Engine.Game.isKeyPressed(Engine.Key.Escape)) state
        else {
            let currKeys = collectPressedKeys();
            let jp = justPressed(currKeys, state#prevKeys);
            // ファイル切り替え（Tab / Shift+Tab）
            let afterSwitch =
                if (Set.memberOf(Engine.Key.Tab, jp)) {
                    if (isShiftHeld(currKeys))
                        SceneBrowser.switchPrev(state)
                    else
                        SceneBrowser.switchNext(state)
                }
                else if (Set.memberOf(Engine.Key.R, jp))
                    SceneBrowser.reload(state)
                else state;
            let newState = {prevKeys = currKeys | afterSwitch};
            // 読み込んだシーンをそのままレンダリング
            Engine.Game.render(newState#loadedScene);
            runLoop(newState)
        }

    /// 監視対象のキーを収集する
    def collectPressedKeys(): Set[Engine.Key] \ Engine.Game =
        let keys = Engine.Key.Tab :: Engine.Key.R ::
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
}
