// Tests for FroggerScene — board layout verification

@Test
def testBoardHasFiveZones(): Unit \ Assert =
    let scene = FroggerScene.buildInitialScene();
    let children = SceneTree.nodeChildren(scene);
    Assert.assertEq(expected = 5, List.length(children))

@Test
def testBoardZoneNames(): Unit \ Assert =
    let scene = FroggerScene.buildInitialScene();
    let names = SceneTree.nodeChildren(scene) |> List.map(SceneTree.nodeName);
    Assert.assertEq(expected = "HomeZone" :: "WaterZone" :: "MedianZone" :: "RoadZone" :: "StartZone" :: Nil, names)

@Test
def testBoardZonePositions(): Unit \ Assert =
    let scene = FroggerScene.buildInitialScene();
    let ys = SceneTree.nodeChildren(scene) |> List.map(n -> SceneTree.nodePosition(n)#y);
    Assert.assertEq(expected = 0.0f32 :: 64.0f32 :: 448.0f32 :: 512.0f32 :: 832.0f32 :: Nil, ys)
