// Tests for MobScene — mob construction, animation, identification

def buildMobWithFixedRandom(name: String, pos: Vec2D.Vec2, vel: Vec2D.Vec2, fixedFloat: Float64): SceneTree.Node =
    let direction = Vec2D.angle(vel);
    run {
        MobScene.buildMob(name, pos, vel, direction)
    } with handler Math.Random {
        def randomFloat64(k) = k(fixedFloat)
        def randomInt64(k) = k(0i64)
    }

// ========================================================================
// buildMob structure
// ========================================================================

@Test
def testBuildMobStructure(): Unit \ Assert =
    let mob = buildMobWithFixedRandom("Mob_0", {x = 100.0f32, y = 200.0f32}, {x = 50.0f32, y = 0.0f32}, 0.0);
    // Root is RigidBody2D
    let isRigid = match SceneTree.nodeKind(mob) {
        case SceneTree.NodeKind.Rigid(_) => true
        case _ => false
    };
    Assert.assertTrue(isRigid);
    // 3 children: AnimatedSprite2D, CollisionShape2D, ScreenNotifier (unique name)
    Assert.assertEq(expected = 3, List.length(SceneTree.nodeChildren(mob)))

@Test
def testBuildMobGravityScaleZero(): Unit \ Assert =
    let mob = buildMobWithFixedRandom("Mob_0", {x = 100.0f32, y = 200.0f32}, {x = 50.0f32, y = 0.0f32}, 0.0);
    let gs = SceneTree.rigidBodyData(mob) |> Option.map(bd -> bd#gravityScale);
    Assert.assertEq(expected = Some(0.0f32), gs)

@Test
def testBuildMobVelocitySet(): Unit \ Assert =
    let mob = buildMobWithFixedRandom("Mob_0", {x = 100.0f32, y = 200.0f32}, {x = 123.0f32, y = -45.0f32}, 0.0);
    let vel = SceneTree.rigidBodyData(mob) |> Option.map(bd -> bd#velocity);
    let vx = vel |> Option.map(v -> v#x);
    let vy = vel |> Option.map(v -> v#y);
    Assert.assertEq(expected = Some(123.0f32), vx);
    Assert.assertEq(expected = Some(-45.0f32), vy)

// ========================================================================
// pickAnimation via Random handler
// ========================================================================

@Test
def testPickAnimationFly(): Unit \ Assert =
    // 0.0 < 0.333333 → "fly"
    let mob = buildMobWithFixedRandom("Mob_0", Vec2D.zero(), Vec2D.zero(), 0.0);
    let anim = SceneTree.findNode("Sprite", mob)
        |> Option.flatMap(n -> match SceneTree.nodeKind(n) {
            case SceneTree.NodeKind.AnimatedSprite(asd) => Some(asd#currentAnimation)
            case _ => None
        });
    Assert.assertEq(expected = Some("fly"), anim)

@Test
def testPickAnimationSwim(): Unit \ Assert =
    // 0.5 >= 0.333333 and < 0.666667 → "swim"
    let mob = buildMobWithFixedRandom("Mob_0", Vec2D.zero(), Vec2D.zero(), 0.5);
    let anim = SceneTree.findNode("Sprite", mob)
        |> Option.flatMap(n -> match SceneTree.nodeKind(n) {
            case SceneTree.NodeKind.AnimatedSprite(asd) => Some(asd#currentAnimation)
            case _ => None
        });
    Assert.assertEq(expected = Some("swim"), anim)

@Test
def testPickAnimationWalk(): Unit \ Assert =
    // 0.8 >= 0.666667 → "walk"
    let mob = buildMobWithFixedRandom("Mob_0", Vec2D.zero(), Vec2D.zero(), 0.8);
    let anim = SceneTree.findNode("Sprite", mob)
        |> Option.flatMap(n -> match SceneTree.nodeKind(n) {
            case SceneTree.NodeKind.AnimatedSprite(asd) => Some(asd#currentAnimation)
            case _ => None
        });
    Assert.assertEq(expected = Some("walk"), anim)

// ========================================================================
// Mob animation is playing
// ========================================================================

@Test
def testMobAnimationPlaying(): Unit \ Assert =
    let mob = buildMobWithFixedRandom("Mob_0", Vec2D.zero(), Vec2D.zero(), 0.0);
    let playing = SceneTree.findNode("Sprite", mob)
        |> Option.flatMap(n -> match SceneTree.nodeKind(n) {
            case SceneTree.NodeKind.AnimatedSprite(asd) => Some(asd#playing)
            case _ => None
        });
    Assert.assertEq(expected = Some(true), playing)
