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
def testInitialSceneHasPlayerWithTargetPos(): Unit \ {Assert, Fs.FileRead} =
    let scene = FroggerScene.buildInitialScene();
    match SceneTree.findNode("Player", scene) {
        case Some(player) => match SceneTree.characterBodyData(player) {
            case Some(cbd) =>
                Assert.assertEq(expected = 384.0f32, cbd#targetPos#x);
                Assert.assertEq(expected = 832.0f32, cbd#targetPos#y)
            case None => bug!("Player should be CharacterBody")
        }
        case None => bug!("Player not found")
    }

// 初期シーンに HUD (CanvasLayer) が含まれること
@Test
def testInitialSceneContainsHUD(): Unit \ {Assert, Fs.FileRead} =
    let scene = FroggerScene.buildInitialScene();
    match SceneTree.findNode("HUD", scene) {
        case Some(hud) => match SceneTree.nodeKind(hud) {
            case SceneTree.NodeKind.CanvasLayer => Assert.assertTrue(true)
            case _ => bug!("HUD should be CanvasLayer")
        }
        case None => bug!("HUD not found in initial scene")
    }
