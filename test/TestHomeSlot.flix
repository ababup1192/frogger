// Tests for HomeSlot — slot positions, scene structure, slot matching, win condition

// ========================================================================
// Slot Configuration Tests
// ========================================================================

@Test
def testSlotCount(): Unit \ Assert =
    // ホームスロットは5箇所
    Assert.assertEq(expected = 5, HomeSlot.slotCount())

@Test
def testSlotPositionCount(): Unit \ Assert =
    // slotPositions のリスト長が slotCount と一致する
    Assert.assertEq(expected = HomeSlot.slotCount(),
        HomeSlot.slotPositions() |> List.length)

@Test
def testSlotPositionsValues(): Unit \ Assert =
    // 各スロットのX座標（64pxグリッドに配置）
    //   [H]       [H]     [H]     [H]       [H]
    //   x=64     x=256   x=384   x=512     x=704
    Assert.assertEq(
        expected = 64.0f32 :: 256.0f32 :: 384.0f32 :: 512.0f32 :: 704.0f32 :: Nil,
        HomeSlot.slotPositions())

@Test
def testSlotX0(): Unit \ Assert =
    Assert.assertEq(expected = 64.0f32, HomeSlot.slotX(0))

@Test
def testSlotX2Center(): Unit \ Assert =
    // スロット2はボード中央
    Assert.assertEq(expected = 384.0f32, HomeSlot.slotX(2))

@Test
def testSlotX4(): Unit \ Assert =
    Assert.assertEq(expected = 704.0f32, HomeSlot.slotX(4))

// ========================================================================
// Home Zone Detection Tests
// ========================================================================

@Test
def testIsInHomeZoneAtTop(): Unit \ Assert =
    // y=0 はホームゾーンの先頭
    Assert.assertTrue(HomeSlot.isInHomeZone(0.0f32))

@Test
def testIsInHomeZoneJustBelow(): Unit \ Assert =
    // y=32 もホームゾーン内
    Assert.assertTrue(HomeSlot.isInHomeZone(32.0f32))

@Test
def testNotInHomeZoneAtWater(): Unit \ Assert =
    // y=64 は水域（ホームゾーン外）
    Assert.assertFalse(HomeSlot.isInHomeZone(64.0f32))

@Test
def testNotInHomeZoneAtStart(): Unit \ Assert =
    // y=832 はスタート地点（ホームゾーン外）
    Assert.assertFalse(HomeSlot.isInHomeZone(832.0f32))

// ========================================================================
// Slot Match Tests — findSlotAtPosition
// ========================================================================

@Test
def testFindSlotExactPosition(): Unit \ Assert =
    // スロット0のX座標ちょうどにいるとき
    Assert.assertEq(expected = Some(0), HomeSlot.findSlotAtPosition(64.0f32, Set.empty()))

@Test
def testFindSlotCenterSlot(): Unit \ Assert =
    // スロット2(中央)のX座標
    Assert.assertEq(expected = Some(2), HomeSlot.findSlotAtPosition(384.0f32, Set.empty()))

@Test
def testFindSlotWithTolerance(): Unit \ Assert =
    // スロット0に近い位置（許容範囲内: |80-64| = 16 < 32）
    Assert.assertEq(expected = Some(0), HomeSlot.findSlotAtPosition(80.0f32, Set.empty()))

@Test
def testFindSlotOutsideTolerance(): Unit \ Assert =
    // どのスロットからも離れている（スロット0=64とスロット1=256の間）
    let result: Option[Int32] = HomeSlot.findSlotAtPosition(160.0f32, Set.empty());
    Assert.assertTrue(Option.isEmpty(result))

@Test
def testFindSlotSkipsFilledSlot(): Unit \ Assert =
    // スロット0が埋まっている → スロット0にはマッチしない
    let result: Option[Int32] = HomeSlot.findSlotAtPosition(64.0f32, Set#{0});
    Assert.assertTrue(Option.isEmpty(result))

@Test
def testFindSlotDoesNotSkipUnfilledSlot(): Unit \ Assert =
    // スロット1が埋まっていても、スロット0にはマッチする
    Assert.assertEq(expected = Some(0),
        HomeSlot.findSlotAtPosition(64.0f32, Set#{1}))

// ========================================================================
// Win Condition Tests
// ========================================================================

@Test
def testNotAllFilledEmpty(): Unit \ Assert =
    // 0個埋まり → 勝利でない
    Assert.assertFalse(HomeSlot.allFilled(Set.empty()))

@Test
def testNotAllFilled3(): Unit \ Assert =
    // 3個埋まり → 勝利でない
    Assert.assertFalse(HomeSlot.allFilled(Set#{0, 1, 2}))

@Test
def testAllFilled5(): Unit \ Assert =
    // 5個全部埋まり ��� 勝利
    Assert.assertTrue(HomeSlot.allFilled(Set#{0, 1, 2, 3, 4}))

// ========================================================================
// Scene Build Tests
// ========================================================================

@Test
def testHomeSlotsContainerName(): Unit \ Assert =
    Assert.assertEq(expected = "HomeSlots",
        HomeSlot.buildHomeSlots() |> SceneTree.nodeName)

@Test
def testHomeSlotsHas5Children(): Unit \ Assert =
    // コンテナ直下に5つのスロットノード
    Assert.assertEq(expected = 5,
        HomeSlot.buildHomeSlots() |> SceneTree.nodeChildren |> List.length)

@Test
def testSlotNodeNames(): Unit \ Assert =
    // 各スロットの名前が HS0 ~ HS4
    let names = HomeSlot.buildHomeSlots()
        |> SceneTree.nodeChildren
        |> List.map(SceneTree.nodeName);
    Assert.assertEq(
        expected = "HS0" :: "HS1" :: "HS2" :: "HS3" :: "HS4" :: Nil,
        names)

@Test
def testSlotNodePositions(): Unit \ Assert =
    // 各スロットのX座標
    let xs = HomeSlot.buildHomeSlots()
        |> SceneTree.nodeChildren
        |> List.map(n -> SceneTree.nodePosition(n)#x);
    Assert.assertEq(
        expected = 64.0f32 :: 256.0f32 :: 384.0f32 :: 512.0f32 :: 704.0f32 :: Nil,
        xs)

@Test
def testSlotHasTwoSprites(): Unit \ Assert =
    // 各スロットはEmptySpriteとFilledSpriteの2つの子を持つ
    match SceneTree.findNode("HS0", HomeSlot.buildHomeSlots()) {
        case Some(slot) => Assert.assertEq(expected = 2,
            SceneTree.nodeChildren(slot) |> List.length)
        case None => bug!("HS0 not found")
    }

@Test
def testSlotEmptySpriteTexture(): Unit \ Assert =
    // EmptySprite のテクスチャは "Home"
    match SceneTree.findNode("HS0", HomeSlot.buildHomeSlots()) {
        case Some(slot) =>
            match SceneTree.findNode("EmptySprite", slot) {
                case Some(sprite) => match SceneTree.nodeKind(sprite) {
                    case SceneTree.NodeKind.Sprite(sd) =>
                        Assert.assertEq(expected = "Home", sd#texture)
                    case _ => bug!("EmptySprite should be Sprite")
                }
                case None => bug!("EmptySprite not found")
            }
        case None => bug!("HS0 not found")
    }

// ========================================================================
// Fill Slot Tests
// ========================================================================

@Test
def testFillSlotMakesFilledSpriteVisible(): Unit \ Assert =
    // fillSlot でスロットを埋めると、FilledSprite が visible になる
    let scene = SceneTree.node2D("Root", Vec2D.zero(),
        HomeSlot.buildHomeSlots() :: Nil);
    let filled = HomeSlot.fillSlot(0, scene);
    match SceneTree.findNode("HSFilled0", filled) {
        case Some(sprite) => match SceneTree.nodeKind(sprite) {
            case SceneTree.NodeKind.Sprite(sd) =>
                Assert.assertTrue(sd#visible)
            case _ => bug!("HSFilled0 should be Sprite")
        }
        case None => bug!("HSFilled0 not found")
    }

@Test
def testUnfilledSlotSpriteNotVisible(): Unit \ Assert =
    // 初期状態では FilledSprite は非表示
    match SceneTree.findNode("HSFilled0", HomeSlot.buildHomeSlots()) {
        case Some(sprite) => match SceneTree.nodeKind(sprite) {
            case SceneTree.NodeKind.Sprite(sd) =>
                Assert.assertFalse(sd#visible)
            case _ => bug!("HSFilled0 should be Sprite")
        }
        case None => bug!("HSFilled0 not found")
    }

// ========================================================================
// Scene Integration Tests
// ========================================================================

@Test
def testInitialSceneContainsHomeSlots(): Unit \ Assert =
    match SceneTree.findNode("HomeSlots", FroggerScene.buildInitialScene()) {
        case Some(container) =>
            Assert.assertEq(expected = "HomeSlots", SceneTree.nodeName(container))
        case None => bug!("HomeSlots not found in initial scene")
    }

@Test
def testInitialSceneHomeSlotsHas5Children(): Unit \ Assert =
    match SceneTree.findNode("HomeSlots", FroggerScene.buildInitialScene()) {
        case Some(container) =>
            Assert.assertEq(expected = 5,
                SceneTree.nodeChildren(container) |> List.length)
        case None => bug!("HomeSlots not found in initial scene")
    }
