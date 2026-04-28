// HomeSlot — home slot logic for the goal zone

mod HomeSlot {

    // ========================================================================
    // Constants
    // ========================================================================

    pub def containerName(): String = "HomeSlots"

    pub def slotCount(): Int32 = 5

    pub def slotName(i: Int32): String = "HS${i}"

    def emptySpriteName(i: Int32): String = "HSEmpty${i}"

    def filledSpriteName(i: Int32): String = "HSFilled${i}"

    // ========================================================================
    // Config — シーンツリー上のホームスロットからプロパティを取得
    // ========================================================================

    /// シーンから読み出すホームスロットの設定
    // slotPositions:  各スロットのX座標リスト（スロット数分）
    // slotSize:       スロットのスプライトサイズ
    // emptyTexture:   空きスロットのテクスチャ名
    // filledTexture:  埋まったスロットのテクスチャ名
    // filledVisible:  埋まったスロットの初期表示状態
    pub type alias Config = {
        slotPositions = List[Float32],
        slotSize      = Vec2D.Vec2,
        emptyTexture  = String,
        filledTexture = String,
        filledVisible = Bool
    }

    /// シーン内のホームスロットノードから設定を取り出す（純粋関数）
    pub def loadConfig(scene: SceneTree.Node): Config =
        let config = forM (
            container  <- SceneTree.findNode(containerName(), scene);
            emptyData  <- SceneTree.findSpriteData(emptySpriteName(0), container);
            filledData <- SceneTree.findSpriteData(filledSpriteName(0), container)
        ) yield {
            let positions = SceneTree.nodeChildren(container)
                |> List.map(slot -> SceneTree.nodePosition(slot)#x);
            {slotPositions = positions,
             slotSize      = emptyData#size,
             emptyTexture  = emptyData#texture,
             filledTexture = filledData#texture,
             filledVisible = filledData#visible}
        };
        match config {
            case Some(c) => c
            case None    => bug!("HomeSlot config extraction failed")
        }

    // ========================================================================
    // Home Zone Detection
    // ========================================================================

    pub def homeZoneMaxY(): Float32 = 64.0f32

    pub def isInHomeZone(playerY: Float32): Bool =
        playerY < homeZoneMaxY()

    // ========================================================================
    // Slot Match — find which slot the player overlaps (AABB check)
    // ========================================================================

    pub def findSlotAtPosition(scene: SceneTree.Node, playerX: Float32, filledSlots: Set[Int32]): Option[Int32] =
        let config = loadConfig(scene);
        let half = config#slotSize#x / 2.0f32;
        List.range(0, List.length(config#slotPositions))
            |> List.findMap(i ->
                let sx = config#slotPositions |> List.nth(i) |> Option.getWithDefault(0.0f32);
                if (Float32.abs(playerX - sx) < half and not Set.memberOf(i, filledSlots))
                    Some(i)
                else None)

    // ========================================================================
    // Win Condition
    // ========================================================================

    pub def allFilled(filledSlots: Set[Int32]): Bool =
        Set.size(filledSlots) >= slotCount()

    // ========================================================================
    // Build all home slots from scene JSON
    // ========================================================================

    /// scene.json からホームスロットのノードツリーを構築する
    pub def buildHomeSlots(): SceneTree.Node \ Fs.FileRead =
        SceneLoader.loadScene("src/scenes/HomeSlot.scene.json")

    // ========================================================================
    // Fill a slot — make the filled sprite visible
    // ========================================================================

    pub def fillSlot(slotIdx: Int32, scene: SceneTree.Node): SceneTree.Node =
        scene
            |> SceneTree.updateSprite(emptySpriteName(slotIdx), sd -> {visible = false | sd})
            |> SceneTree.updateSprite(filledSpriteName(slotIdx), sd -> {visible = true | sd})

}
