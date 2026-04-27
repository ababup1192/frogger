// Tests for FroggerScene — board layout and scene structure

@Test
def testBoardHasFiveZones(): Unit \ Assert =
    let zones = FroggerScene.buildBoard();
    Assert.assertEq(expected = 5, List.length(zones))

@Test
def testBoardZoneNames(): Unit \ Assert =
    let names = FroggerScene.buildBoard() |> List.map(SceneTree.nodeName);
    Assert.assertEq(expected = "HomeZone" :: "WaterZone" :: "MedianZone" :: "RoadZone" :: "StartZone" :: Nil, names)

@Test
def testBoardZonePositions(): Unit \ Assert =
    let ys = FroggerScene.buildBoard() |> List.map(n -> SceneTree.nodePosition(n)#y);
    Assert.assertEq(expected = 0.0f32 :: 64.0f32 :: 448.0f32 :: 512.0f32 :: 832.0f32 :: Nil, ys)

@Test
def testInitialSceneHasPlayerTarget(): Unit \ Assert =
    let scene = FroggerScene.buildInitialScene();
    match SceneTree.findNode("PlayerTarget", scene) {
        case Some(node) =>
            let pos = SceneTree.nodePosition(node);
            Assert.assertEq(expected = 384.0f32, pos#x);
            Assert.assertEq(expected = 832.0f32, pos#y)
        case None => Assert.assertTrue(false)
    }
