// Tests for HomeSlot — slot positions, scene structure, slot matching, win condition

// ========================================================================
// Test Helper — HomeSlots を含むシーン
// ========================================================================

def testHomeSlotsScene(): SceneTree.Node \ Fs.FileRead =
    SceneTree.node2D("Root", Vec2D.zero(), HomeSlot.buildHomeSlots() :: Nil)

// ========================================================================
// loadConfig — JSON構築 + Config抽出の一括検証
// ========================================================================

@Test
def testLoadConfig(): Unit \ {Assert, Fs.FileRead} =
    // buildHomeSlots → loadConfig で全パラメータを一括検証する
    //
    //   HomeSlots (Node2D, pos=0,0)
    //   ├── HS0 (Node2D, pos=64,0)
    //   │   ├── HSEmpty0  (Sprite2D, "Home",     visible=true)
    //   │   └── HSFilled0 (Sprite2D, "HomeFrog", visible=false)
    //   ├── HS1 (Node2D, pos=256,0)
    //   │   ├── HSEmpty1  ...
    //   │   └── HSFilled1 ...
    //   ... (HS2〜HS4 も同構造)
    //
    let scene = testHomeSlotsScene();
    let config = HomeSlot.loadConfig(scene);
    // スロット数
    Assert.assertEq(expected = 5,
        config#slotPositions |> List.length);
    // 各スロットのX座標
    Assert.assertEq(expected = 64.0f32 :: 256.0f32 :: 384.0f32 :: 512.0f32 :: 704.0f32 :: Nil,
        config#slotPositions);
    // スプライトサイズ 64x64
    Assert.assertEq(expected = (64.0f32, 64.0f32),
        (config#slotSize#x, config#slotSize#y));
    // テクスチャ名
    Assert.assertEq(expected = "Home", config#emptyTexture);
    Assert.assertEq(expected = "HomeFrog", config#filledTexture);
    // 埋まったスロットは初期状態で非表示
    Assert.assertFalse(config#filledVisible)

// ========================================================================
// Slot Configuration Tests
// ========================================================================

@Test
def testSlotCount(): Unit \ Assert =
    // ホームスロットは5箇所
    Assert.assertEq(expected = 5, HomeSlot.slotCount())

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
def testFindSlotExactPosition(): Unit \ {Assert, Fs.FileRead} =
    // スロット0のX座標ちょうどにいるとき
    let scene = testHomeSlotsScene();
    Assert.assertEq(expected = Some(0), HomeSlot.findSlotAtPosition(scene, 64.0f32))

@Test
def testFindSlotCenterSlot(): Unit \ {Assert, Fs.FileRead} =
    // スロット2(中央)のX座標
    let scene = testHomeSlotsScene();
    Assert.assertEq(expected = Some(2), HomeSlot.findSlotAtPosition(scene, 384.0f32))

@Test
def testFindSlotWithTolerance(): Unit \ {Assert, Fs.FileRead} =
    // スロット0に近い位置（許容範囲内: |80-64| = 16 < 32）
    let scene = testHomeSlotsScene();
    Assert.assertEq(expected = Some(0), HomeSlot.findSlotAtPosition(scene, 80.0f32))

@Test
def testFindSlotOutsideTolerance(): Unit \ {Assert, Fs.FileRead} =
    // どのスロットからも離れている（スロット0=64とスロット1=256の間）
    let scene = testHomeSlotsScene();
    let result: Option[Int32] = HomeSlot.findSlotAtPosition(scene, 160.0f32);
    Assert.assertTrue(Option.isEmpty(result))

@Test
def testFindSlotSkipsFilledSlot(): Unit \ {Assert, Fs.FileRead} =
    // スロット0が埋まっている → スロット0にはマッチしない
    let scene = testHomeSlotsScene() |> HomeSlot.fillSlot(0);
    let result: Option[Int32] = HomeSlot.findSlotAtPosition(scene, 64.0f32);
    Assert.assertTrue(Option.isEmpty(result))

@Test
def testFindSlotDoesNotSkipUnfilledSlot(): Unit \ {Assert, Fs.FileRead} =
    // スロット1が埋まっていても、スロット0にはマッチする
    let scene = testHomeSlotsScene() |> HomeSlot.fillSlot(1);
    Assert.assertEq(expected = Some(0),
        HomeSlot.findSlotAtPosition(scene, 64.0f32))

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
    // 5個全部埋まり → 勝利
    Assert.assertTrue(HomeSlot.allFilled(Set#{0, 1, 2, 3, 4}))

// ========================================================================
// Fill Slot Tests
// ========================================================================

@Test
def testFillSlotMakesFilledSpriteVisible(): Unit \ {Assert, Fs.FileRead} =
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
def testFillSlotHidesEmptySprite(): Unit \ {Assert, Fs.FileRead} =
    // fillSlot でスロットを埋めると、EmptySprite が非表示になる
    let scene = SceneTree.node2D("Root", Vec2D.zero(),
        HomeSlot.buildHomeSlots() :: Nil);
    let filled = HomeSlot.fillSlot(0, scene);
    match SceneTree.findNode("HSEmpty0", filled) {
        case Some(sprite) => match SceneTree.nodeKind(sprite) {
            case SceneTree.NodeKind.Sprite(sd) =>
                Assert.assertFalse(sd#visible)
            case _ => bug!("HSEmpty0 should be Sprite")
        }
        case None => bug!("HSEmpty0 not found")
    }

@Test
def testUnfilledSlotSpriteNotVisible(): Unit \ {Assert, Fs.FileRead} =
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
def testInitialSceneContainsHomeSlots(): Unit \ {Assert, Fs.FileRead} =
    match SceneTree.findNode("HomeSlots", FroggerScene.buildInitialScene()) {
        case Some(container) =>
            Assert.assertEq(expected = "HomeSlots", SceneTree.nodeName(container))
        case None => bug!("HomeSlots not found in initial scene")
    }

@Test
def testInitialSceneHomeSlotsHas5Children(): Unit \ {Assert, Fs.FileRead} =
    match SceneTree.findNode("HomeSlots", FroggerScene.buildInitialScene()) {
        case Some(container) =>
            Assert.assertEq(expected = 5,
                SceneTree.nodeChildren(container) |> List.length)
        case None => bug!("HomeSlots not found in initial scene")
    }
