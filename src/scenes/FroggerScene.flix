// FroggerScene — Frogger のルートシーン

mod FroggerScene {
    pub def rootName(): String = "Root"

    pub enum Child with Eq, ToString {
        case Player
        case VehicleLanes
        case WaterLanes
        case TurtleLanes
        case HomeSlots
        case DeathTimer
        case HUD
    }

    instance SceneTree.SceneChild[Child] {
        pub def sceneName(_c: Child): String = FroggerScene.rootName()
        pub def childName(c: Child): String = match c {
            case Child.Player => FroggerPlayer.playerName()
            case Child.VehicleLanes => VehicleLane.containerName()
            case Child.WaterLanes => WaterLane.containerName()
            case Child.TurtleLanes => TurtleLane.containerName()
            case Child.HomeSlots => HomeSlot.containerName()
            case Child.DeathTimer => FroggerScene.deathTimerName()
            case Child.HUD => FroggerHUD.containerName()
        }
    }

    pub def deathTimerName(): String = "DeathTimer"

    def deathTimerWait(): Float32 = 2.0f32

    // ========================================================================
    // シーン状態
    // ========================================================================

    pub type alias SceneState = {
        scene         = SceneTree.Node,
        lives         = Int32,
        timeRemaining = Float32
    }

    pub def initSceneState(): SceneState \ Fs.FileRead = {
        scene = buildInitialScene(),
        lives = 3,
        timeRemaining = Game.initialTimeRemaining()
    }

    // ========================================================================
    // ゲーム終了条件
    // ========================================================================

    pub def isWon(state: SceneState): Bool =
        HomeSlot.isAllFilled(state#scene)

    pub def isGameOver(state: SceneState): Bool =
        state#lives <= 0 and not isPlayerDead(state#scene)

    // ========================================================================
    // 物理設定
    // ========================================================================

    pub def physicsConfig(): SceneTree.PhysicsConfig =
        {screenSize = {x = Int32.toFloat32(Game.screenWidth()),
                       y = Int32.toFloat32(Game.screenHeight())}}

    // ========================================================================
    // ボードレイアウト定数
    // ========================================================================

    def screenW(): Float32 = Int32.toFloat32(Game.screenWidth())

    def homeZoneY(): Float32      = 0.0f32
    def homeZoneH(): Float32      = 64.0f32

    def waterZoneY(): Float32     = 64.0f32
    def waterZoneH(): Float32     = 384.0f32

    def medianZoneY(): Float32    = 448.0f32
    def medianZoneH(): Float32    = 64.0f32

    def roadZoneY(): Float32      = 512.0f32
    def roadZoneH(): Float32      = 320.0f32

    def startZoneY(): Float32     = 832.0f32
    def startZoneH(): Float32     = 64.0f32

    // ========================================================================
    // プレイヤー移動範囲
    // ========================================================================

    /// プレイヤーが移動できるグリッド座標の範囲（min, max）
    pub def playerBounds(): (Vec2D.Vec2, Vec2D.Vec2) =
        ({x = 0.0f32, y = homeZoneY()},
         {x = screenW() - tileSize(), y = startZoneY()})

    // ========================================================================
    // ゾーン色
    // ========================================================================

    def greenColor(): Engine.Color  = {r = 0.2f32, g = 0.5f32, b = 0.2f32}

    // ========================================================================
    // ヘルパー
    // ========================================================================

    def coloredRect(name: String, y: Float32, h: Float32, col: Engine.Color): SceneTree.Node =
        Sprite2D.init({name = name, pos = {x = 0.0f32, y = y}, size = {x = screenW(), y = h}, texture = "white"})
            |> Sprite2D.color(col)

    // 16x16 テクスチャを 4 倍スケール = 64px タイル
    def tileSize(): Float32 = 64.0f32

    def tiledRect(name: String, y: Float32, h: Float32, texture: String): SceneTree.Node =
        Sprite2D.init({name = name, pos = {x = 0.0f32, y = y}, size = {x = screenW(), y = h}, texture = texture})
            |> Sprite2D.uv(Vec2D.zero(), {x = screenW() / tileSize(), y = h / tileSize()})

    // ========================================================================
    // ボード構築
    // ========================================================================

    pub def buildBoard(): List[SceneTree.Node] =
        coloredRect("HomeZone",   homeZoneY(),   homeZoneH(),   greenColor()) ::
        tiledRect("WaterZone",    waterZoneY(),  waterZoneH(),  "Water") ::
        tiledRect("MedianZone",   medianZoneY(), medianZoneH(), "Median") ::
        tiledRect("RoadZone",     roadZoneY(),   roadZoneH(),   "Road") ::
        coloredRect("StartZone",  startZoneY(),  startZoneH(),  greenColor()) ::
        Nil

    // ========================================================================
    // シーン構築
    // ========================================================================

    pub def buildInitialScene(): SceneTree.Node \ Fs.FileRead =
        let deathTimer = Timer2D.init({name = deathTimerName(), waitTime = deathTimerWait(), oneShot = true});
        (buildBoard() ::: HomeSlot.buildHomeSlots() :: WaterLane.buildWaterLanes() :: TurtleLane.buildTurtleLanes() :: VehicleLane.buildVehicleLanes() :: FroggerPlayer.buildPlayer() :: deathTimer :: FroggerHUD.buildHUD() :: Nil)
            |> SceneTree.node2D(rootName(), Vec2D.zero())

    // ========================================================================
    // 死亡状態 — DeathTimer の稼働状態から導出
    // ========================================================================

    pub def isPlayerDead(scene: SceneTree.Node): Bool =
        SceneTree.isTimerRunning(SceneTree.childName(Child.DeathTimer), scene)

    // ========================================================================
    // 死亡トリガー — 車両衝突・溺死の共通ヘルパー
    // ========================================================================

    pub def triggerDeath(state: SceneState): SceneState =
        {scene = state#scene
            |> FroggerPlayer.showDeathSprite
            |> SceneTree.startTimer(SceneTree.childName(Child.DeathTimer)),
         lives = state#lives - 1 | state}

    // ========================================================================
    // 全レーン折り返し — 車両・丸太・亀を一括ラップ
    // ========================================================================

    def wrapAllLanes(scene: SceneTree.Node): SceneTree.Node =
        scene
            |> VehicleLane.wrapVehicles
            |> WaterLane.wrapLogs
            |> TurtleLane.wrapTurtles

    // ========================================================================
    // 水域プラットフォーム処理 — 乗り移動（丸太＋亀）＋溺死判定
    // ========================================================================

    def stepWaterPlatforms(dt: Float32, scene: SceneTree.Node):
            {scene = SceneTree.Node, atTarget = Bool, shouldDrown = Bool} =
        let ridingScene = scene
            |> WaterLane.applyPlatformRiding(dt)
            |> TurtleLane.applyPlatformRiding(dt);
        let atTarget = FroggerPlayer.isAtTarget(ridingScene);
        let onPlatform = not Option.isEmpty(WaterLane.findOverlappingLogVelocity(ridingScene))
            or not Option.isEmpty(TurtleLane.findOverlappingTurtleVelocity(ridingScene));
        {scene = ridingScene, atTarget = atTarget,
         shouldDrown = WaterLane.shouldDrown(atTarget, onPlatform, ridingScene)}

    // ========================================================================
    // ホームスロット判定 — プレイヤーがホームゾーンに到達
    // ========================================================================

    def checkHomeSlot(atTarget: Bool, playerPos: Option[Vec2D.Vec2],
                      state: SceneState): SceneState =
        match playerPos {
            case None => state
            case Some(pos) =>
                if (not atTarget or not HomeSlot.isInHomeZone(pos#y)) state
                else match HomeSlot.tryFillSlot(pos, state#scene) {
                    case Some(filledScene) =>
                        {scene = FroggerPlayer.respawn(filledScene),
                         timeRemaining = Game.initialTimeRemaining() | state}
                    case None =>
                        triggerDeath(state)
                }
        }

    // ========================================================================
    // フレーム更新（死亡中）— 物理演算 + ラップ + 死亡タイマー
    // ========================================================================

    def stepFrameDead(dt: Float32, state: SceneState): SceneState =
        let movedScene = run {
            SceneTree.stepAndCollide(state#scene, dt, physicsConfig())
        } with handler SceneTree.OnCollision {
            def bodyEntered(_name, _pos, _body, k) = k(())
            def areaEntered(_name, _pos, _body, k) = k(())
        };
        let wrappedScene = movedScene
            |> wrapAllLanes
            |> SceneTree.stepAnimations(dt);
        run {
            let s = SceneTree.stepTimers(dt, wrappedScene);
            {scene = s | state}
        } with handler SceneTree.OnTimeout {
            def timeout(name, k) =
                let st = k(());
                if (name == SceneTree.childName(Child.DeathTimer))
                    if (st#lives > 0)
                        {scene = FroggerPlayer.respawn(st#scene),
                         timeRemaining = Game.initialTimeRemaining() | st}
                    else
                        st
                else st
        }

    // ========================================================================
    // フレーム更新（生存中）— プレイヤー移動 + 物理衝突 + 水域判定
    // ========================================================================

    def stepFrameAlive(dt: Float32, state: SceneState): SceneState =
        let hitboxName = SceneTree.childName(FroggerPlayer.Child.Hitbox);
        let playerScene = FroggerPlayer.stepFrame(dt, state#scene);
        let collisionState = run {
            let s = SceneTree.stepAndCollide(playerScene, dt, physicsConfig());
            {scene = s |> wrapAllLanes |> SceneTree.stepAnimations(dt) | state}
        } with handler SceneTree.OnCollision {
            def bodyEntered(_name, _pos, _body, k) = k(())
            def areaEntered(name, _pos, body, k) =
                let st = k(());
                if (VehicleLane.isVehicleCollision(hitboxName, name, body#name)
                    and not isPlayerDead(st#scene))
                    triggerDeath(st)
                else st
        };
        // 水域: 乗り移動（丸太＋亀）＋溺死判定
        let water = stepWaterPlatforms(dt, collisionState#scene);
        let playerPos = SceneTree.globalPosition(FroggerPlayer.playerName(), water#scene);
        let afterCollisions = if (water#shouldDrown and not isPlayerDead(water#scene))
            triggerDeath({scene = water#scene | collisionState})
        else
            checkHomeSlot(water#atTarget, playerPos, {scene = water#scene | collisionState});
        // 制限時間カウントダウン（死亡中はスキップ）
        if (isPlayerDead(afterCollisions#scene))
            afterCollisions
        else {
            let newTime = afterCollisions#timeRemaining - dt;
            if (newTime <= 0.0f32)
                triggerDeath({timeRemaining = 0.0f32 | afterCollisions})
            else
                {timeRemaining = newTime | afterCollisions}
        }

    // ========================================================================
    // フレーム更新 — 入力 → シミュレーション → 表示
    // ========================================================================

    pub def stepFrame(dt: Float32, dir: Option[SceneTree.Direction],
                      state: SceneState): SceneState =
        let inputState = {scene = match dir {
            case Some(d) => FroggerPlayer.applyInput(d, state#scene)
            case None    => state#scene
        } | state};
        let simState = if (isPlayerDead(inputState#scene))
            stepFrameDead(dt, inputState)
        else
            stepFrameAlive(dt, inputState);
        // 3. HUD 更新
        let hudScene = FroggerHUD.update(simState);
        // 4. ゲーム終了メッセージ
        let finalScene = if (isGameOver(simState))
            hudScene |> FroggerHUD.showMessage("You Lost!") |> FroggerHUD.showRestart
        else if (isWon(simState))
            hudScene |> FroggerHUD.showMessage("You Won!") |> FroggerHUD.showRestart
        else hudScene;
        {scene = finalScene | simState}
}
