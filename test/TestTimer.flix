// Tests for Timer, Path, and related scene tree additions

// ========================================================================
// Timer Tests
// ========================================================================

@Test
def testTimerInitialState(): Unit \ Assert =
    let timer = Timer2D.init({name = "T", waitTime = 1.0f32, oneShot = false});
    let running = match SceneTree.nodeKind(timer) {
        case SceneTree.NodeKind.Timer(td) => td#running
        case _ => true
    };
    Assert.assertFalse(running)

@Test
def testTimerStartStop(): Unit \ Assert =
    let timer = Timer2D.init({name = "T", waitTime = 1.0f32, oneShot = false});
    let root = SceneTree.node2D("Root", Vec2D.zero(), timer :: Nil);
    let started = SceneTree.startTimer("T", root);
    let isRunning = SceneTree.isTimerRunning("T", started);
    Assert.assertTrue(isRunning);
    let stopped = SceneTree.stopTimer("T", started);
    let isStopped = not SceneTree.isTimerRunning("T", stopped);
    Assert.assertTrue(isStopped)

@Test
def testTimerTickNotFired(): Unit \ Assert =
    // waitTime=1.0, step 0.5 → should not fire
    let timer = Timer2D.init({name = "T", waitTime = 1.0f32, oneShot = false}) |> Timer2D.start;
    let root = SceneTree.node2D("Root", Vec2D.zero(), timer :: Nil);
    let fired = run {
        discard SceneTree.stepTimers(0.5f32, root);
        false
    } with handler SceneTree.OnTimeout {
        def timeout(_name, _k) = true
    };
    Assert.assertFalse(fired)

@Test
def testTimerTickFired(): Unit \ Assert =
    // waitTime=1.0, step 1.0 → should fire
    let timer = Timer2D.init({name = "T", waitTime = 1.0f32, oneShot = false}) |> Timer2D.start;
    let root = SceneTree.node2D("Root", Vec2D.zero(), timer :: Nil);
    let fired = run {
        discard SceneTree.stepTimers(1.0f32, root);
        false
    } with handler SceneTree.OnTimeout {
        def timeout(_name, _k) = true
    };
    Assert.assertTrue(fired)

@Test
def testTimerOneShotStops(): Unit \ Assert =
    let timer = Timer2D.init({name = "T", waitTime = 1.0f32, oneShot = true}) |> Timer2D.start;
    let root = SceneTree.node2D("Root", Vec2D.zero(), timer :: Nil);
    let result = run {
        SceneTree.stepTimers(1.5f32, root)
    } with handler SceneTree.OnTimeout {
        def timeout(_name, k) = k(())
    };
    let running = SceneTree.isTimerRunning("T", result);
    Assert.assertFalse(running)

@Test
def testTimerRepeatingContinues(): Unit \ Assert =
    let timer = Timer2D.init({name = "T", waitTime = 1.0f32, oneShot = false}) |> Timer2D.start;
    let root = SceneTree.node2D("Root", Vec2D.zero(), timer :: Nil);
    let result = run {
        SceneTree.stepTimers(1.5f32, root)
    } with handler SceneTree.OnTimeout {
        def timeout(_name, k) = k(())
    };
    let running = SceneTree.isTimerRunning("T", result);
    Assert.assertTrue(running)

@Test
def testTimerFiresTimerName(): Unit \ Assert =
    let timer = Timer2D.init({name = "MyTimer", waitTime = 0.5f32, oneShot = true}) |> Timer2D.start;
    let root = SceneTree.node2D("Root", Vec2D.zero(), timer :: Nil);
    let firedName = run {
        discard SceneTree.stepTimers(1.0f32, root);
        "none"
    } with handler SceneTree.OnTimeout {
        def timeout(name, _k) = name
    };
    Assert.assertEq(expected = "MyTimer", firedName)

// ========================================================================
// Path Tests
// ========================================================================

@Test
def testPathSampleFirstPoint(): Unit \ Assert =
    let pd: SceneTree.PathData = {
        points =
            {x = 0.0f32, y = 0.0f32} ::
            {x = 480.0f32, y = 0.0f32} ::
            {x = 480.0f32, y = 720.0f32} ::
            {x = 0.0f32, y = 720.0f32} ::
            Nil
    };
    let (pos, _normal) = SceneTree.pathSample(0.0f32, pd);
    Assert.assertEq(expected = 0.0f32, pos#x);
    Assert.assertEq(expected = 0.0f32, pos#y)

@Test
def testPathSampleMidFirstEdge(): Unit \ Assert =
    let pd: SceneTree.PathData = {
        points =
            {x = 0.0f32, y = 0.0f32} ::
            {x = 480.0f32, y = 0.0f32} ::
            {x = 480.0f32, y = 720.0f32} ::
            {x = 0.0f32, y = 720.0f32} ::
            Nil
    };
    // t = 0.125 → midpoint of first edge (0,0)→(480,0)
    let (pos, _normal) = SceneTree.pathSample(0.125f32, pd);
    Assert.assertEq(expected = 240.0f32, pos#x);
    Assert.assertEq(expected = 0.0f32, pos#y)
