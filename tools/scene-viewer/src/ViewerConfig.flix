// ViewerConfig — Scene Viewer の画面設定とエンジン構成

mod ViewerConfig {
    /// 画面幅（ピクセル）
    pub def screenWidth(): Int32 = 1500

    /// プロパティパネルの幅（ピクセル）
    pub def propertyPanelWidth(): Float32 = 300.0f32

    /// プロパティパネルの X 開始位置
    pub def propertyPanelX(): Float32 = Int32.toFloat32(screenWidth()) - propertyPanelWidth()

    /// 画面高さ（ピクセル）
    pub def screenHeight(): Int32 = 800

    /// ツリーパネルの幅（ピクセル）
    pub def treePanelWidth(): Float32 = 350.0f32

    /// ファイルタブの高さ（ピクセル）
    pub def tabBarHeight(): Float32 = 44.0f32

    /// デフォルトのフォントパス
    pub def defaultFont(): String = "textures/UDEVGothic-Regular.ttf"

    /// デフォルトの scenes ディレクトリパス
    pub def defaultScenesDir(): String = "../../src/scenes"

    /// テクスチャマニフェスト（ゲームのテクスチャを含む）
    pub def textureManifest(): List[Engine.TextureEntry] =
        {name = "white", path = "textures/white_1x1.png", hasAlpha = true} ::
        {name = "FroggerIdle", path = "textures/FroggerIdle.png", hasAlpha = true} ::
        {name = "FroggerLeap", path = "textures/FroggerLeap.png", hasAlpha = true} ::
        {name = "Car1", path = "textures/Car1.png", hasAlpha = true} ::
        {name = "Car2", path = "textures/Car2.png", hasAlpha = true} ::
        {name = "Car3", path = "textures/Car3.png", hasAlpha = true} ::
        {name = "Car4", path = "textures/Car4.png", hasAlpha = true} ::
        {name = "Car5", path = "textures/Car5.png", hasAlpha = true} ::
        {name = "FroggerDead", path = "textures/FroggerDead.png", hasAlpha = true} ::
        {name = "LogStart", path = "textures/LogStart.png", hasAlpha = true} ::
        {name = "LogMiddle", path = "textures/LogMiddle.png", hasAlpha = true} ::
        {name = "LogEnd", path = "textures/LogEnd.png", hasAlpha = true} ::
        {name = "Turtle_01", path = "textures/Turtle_01.png", hasAlpha = true} ::
        {name = "Turtle_02", path = "textures/Turtle_02.png", hasAlpha = true} ::
        {name = "Turtle_03", path = "textures/Turtle_03.png", hasAlpha = true} ::
        {name = "Home", path = "textures/Home.png", hasAlpha = true} ::
        {name = "HomeFrog", path = "textures/HomeFrog.png", hasAlpha = true} ::
        {name = "Road", path = "textures/Road.png", hasAlpha = true} ::
        {name = "Water", path = "textures/Water.png", hasAlpha = true} ::
        {name = "Median", path = "textures/Median.png", hasAlpha = true} ::
        Nil

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
