// Scene Viewer — scene.json の可視化ツール

def main(): Unit \ IO =
    if (Engine.ensureMainThread()) ()
    else {
        println("Scene Viewer");
        let config = ViewerConfig.engineConfig();
        let scenesDir = ViewerConfig.defaultScenesDir();
        let sceneFiles = run { SceneBrowser.scanDir(scenesDir) } with Fs.DirList.runWithIO;
        if (List.isEmpty(sceneFiles))
            println("No .scene.json files found in ${scenesDir}")
        else {
            println("Found ${List.length(sceneFiles)} scene file(s)");
            discard run {
                ViewerApp.start(sceneFiles)
            } with LwjglLayer.withLwjgl(config)
              with Fs.FileRead.runWithIO;
            println("Scene Viewer ended.")
        }
    }
