// SceneBrowser — ディレクトリ内の .scene.json ファイルを列挙・切り替えする

mod SceneBrowser {
    /// 指定ディレクトリ内の .scene.json ファイルパスをソート済みリストで返す
    pub def scanDir(dirPath: String): List[String] \ Fs.DirList =
        match Fs.DirList.list(dirPath) {
            case Ok(files) =>
                files
                    |> List.filter(f -> String.endsWith({suffix = ".scene.json"}, f))
                    |> List.sort
            case Err(_) => Nil
        }

    /// 現在選択中のファイルパスを返す
    pub def currentFilePath(state: ViewerState.State): String =
        state#sceneFiles
            |> List.nth(state#currentFileIndex)
            |> Option.getWithDefault("")

    /// 次のファイルに切り替える（Tab）
    pub def switchNext(state: ViewerState.State): ViewerState.State \ Fs.FileRead =
        let count = List.length(state#sceneFiles);
        if (count <= 1) state
        else {
            let nextIndex = Int32.modulo(state#currentFileIndex + 1, count);
            loadAtIndex(nextIndex, state)
        }

    /// 前のファイルに切り替える（Shift+Tab）
    pub def switchPrev(state: ViewerState.State): ViewerState.State \ Fs.FileRead =
        let count = List.length(state#sceneFiles);
        if (count <= 1) state
        else {
            let prevIndex = Int32.modulo(state#currentFileIndex - 1 + count, count);
            loadAtIndex(prevIndex, state)
        }

    /// 現在のファイルを再読み込みする（R キー）
    pub def reload(state: ViewerState.State): ViewerState.State \ Fs.FileRead =
        loadAtIndex(state#currentFileIndex, state)

    /// 指定インデックスのファイルを読み込み、状態を更新する
    def loadAtIndex(index: Int32, state: ViewerState.State): ViewerState.State \ Fs.FileRead =
        let filePath = state#sceneFiles
            |> List.nth(index)
            |> Option.getWithDefault("");
        let scene = SceneLoader.loadScene(filePath);
        {currentFileIndex = index,
         loadedScene = scene,
         treeState = ViewerState.initialTreeState(scene),
         canvasState = ViewerState.initialCanvasState() | state}
}
