// ViewerConfig — Scene Viewer の画面設定とエンジン構成

mod ViewerConfig {
    /// 画面幅（ピクセル）
    pub def screenWidth(): Int32 = 1200

    /// 画面高さ（ピクセル）
    pub def screenHeight(): Int32 = 800

    /// ツリーパネルの幅（ピクセル）
    pub def treePanelWidth(): Float32 = 350.0f32

    /// ファイルタブの高さ（ピクセル）
    pub def tabBarHeight(): Float32 = 40.0f32

    /// デフォルトのフォントパス
    pub def defaultFont(): String = "textures/UDEVGothic-Regular.ttf"

    /// デフォルトの scenes ディレクトリパス
    pub def defaultScenesDir(): String = "../../src/scenes"

    /// テクスチャマニフェスト（白テクスチャのみ）
    pub def textureManifest(): List[Engine.TextureEntry] =
        {name = "white", path = "textures/white_1x1.png", hasAlpha = true} :: Nil

    /// オーディオマニフェスト（不使用）
    pub def audioManifest(): List[Engine.AudioEntry] = Nil

    /// エンジン設定を生成する
    pub def engineConfig(): Engine.EngineConfig = {
        screenWidth = screenWidth(),
        screenHeight = screenHeight(),
        title = "Scene Viewer",
        textureManifest = textureManifest(),
        audioManifest = audioManifest(),
        fontPath = defaultFont(),
        clearColor = {r = 0.15f32, g = 0.15f32, b = 0.18f32}
    }
}
