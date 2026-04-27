// HomeSlot — home slot logic for the goal zone

mod HomeSlot {

    // ========================================================================
    // Constants
    // ========================================================================

    pub def containerName(): String = "HomeSlots"

    pub def slotCount(): Int32 = 5

    pub def slotName(i: Int32): String = "HS${i}"

    def filledSpriteName(i: Int32): String = "HSFilled${i}"

    def slotSize(): Vec2D.Vec2 = {x = 64.0f32, y = 64.0f32}

    // ========================================================================
    // Slot X positions (aligned to 64px grid)
    //
    //   [H]       [H]     [H]     [H]       [H]
    //   x=64     x=256   x=384   x=512     x=704
    //     ↑               ↑                  ↑
    //   左寄り          中央              右寄り
    // ========================================================================

    pub def slotPositions(): List[Float32] =
        64.0f32 :: 256.0f32 :: 384.0f32 :: 512.0f32 :: 704.0f32 :: Nil

    pub def slotX(i: Int32): Float32 =
        slotPositions() |> List.nth(i) |> Option.getWithDefault(0.0f32)

    // ========================================================================
    // Home Zone Detection
    // ========================================================================

    pub def homeZoneMaxY(): Float32 = 64.0f32

    pub def isInHomeZone(playerY: Float32): Bool =
        playerY < homeZoneMaxY()

    // ========================================================================
    // Slot Match — find which slot the player overlaps (AABB check)
    // ========================================================================

    pub def findSlotAtPosition(playerX: Float32, filledSlots: Set[Int32]): Option[Int32] =
        List.range(0, slotCount())
            |> List.findMap(i ->
                let sx = slotX(i);
                if (Float32.abs(playerX - sx) < 32.0f32 and not Set.memberOf(i, filledSlots))
                    Some(i)
                else None)

    // ========================================================================
    // Win Condition
    // ========================================================================

    pub def allFilled(filledSlots: Set[Int32]): Bool =
        Set.size(filledSlots) >= slotCount()

    // ========================================================================
    // Build a single slot node (two sprites: empty + filled)
    // ========================================================================

    def buildSlot(i: Int32): SceneTree.Node =
        let emptySprite = Sprite2D.init({name = "EmptySprite",
                                         pos = Vec2D.zero(),
                                         size = slotSize(),
                                         texture = "Home"});
        let filledSprite = Sprite2D.init({name = filledSpriteName(i),
                                          pos = Vec2D.zero(),
                                          size = slotSize(),
                                          texture = "HomeFrog"})
            |> Sprite2D.visible(false);
        SceneTree.node2D(slotName(i),
                         {x = slotX(i), y = 0.0f32},
                         emptySprite :: filledSprite :: Nil)

    // ========================================================================
    // Build all home slots as a container Node2D
    // ========================================================================

    pub def buildHomeSlots(): SceneTree.Node =
        List.range(0, slotCount())
            |> List.map(buildSlot)
            |> SceneTree.node2D(containerName(), Vec2D.zero())

    // ========================================================================
    // Fill a slot — make the filled sprite visible
    // ========================================================================

    pub def fillSlot(slotIdx: Int32, scene: SceneTree.Node): SceneTree.Node =
        SceneTree.updateSprite(filledSpriteName(slotIdx),
            sd -> {visible = true | sd}, scene)

}
