// Node builders — pipe-based constructors: init creates Node, setters modify it
//
// Usage:
//   Sprite2D.init({name = "Foo", pos = ..., size = ..., texture = "bar"})
//       |> Sprite2D.uv(offset, scale)

// ========================================================================
// Sprite2D
// ========================================================================

mod Sprite2D {
    pub def init(req: {name = String, pos = Vec2D.Vec2, size = Vec2D.Vec2, texture = String}): SceneTree.Node =
        SceneTree.sprite2D(req#name, req#pos, {
            size = req#size,
            color = {r = 1.0f32, g = 1.0f32, b = 1.0f32},
            texture = req#texture,
            visible = true,
            uvOffset = Vec2D.zero(),
            uvScale = Vec2D.one(),
            rotation = 0.0f32
        })

    pub def color(v: Engine.Color, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Sprite(sd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Sprite({color = v | sd}), ch)
            case _ => node
        }

    pub def visible(v: Bool, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Sprite(sd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Sprite({visible = v | sd}), ch)
            case _ => node
        }

    pub def uv(offset: Vec2D.Vec2, scale: Vec2D.Vec2, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Sprite(sd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Sprite({uvOffset = offset, uvScale = scale | sd}), ch)
            case _ => node
        }

    pub def rotation(v: Float32, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Sprite(sd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Sprite({rotation = v | sd}), ch)
            case _ => node
        }
}

// ========================================================================
// AnimatedSprite2D
// ========================================================================

mod AnimatedSprite2D {
    pub def init(req: {name = String, pos = Vec2D.Vec2, size = Vec2D.Vec2,
                       animations = Map[String, SceneTree.AnimationEntry],
                       initialAnimation = String}): SceneTree.Node =
        SceneTree.animatedSprite2D(req#name, req#pos, {
            size = req#size,
            color = {r = 1.0f32, g = 1.0f32, b = 1.0f32},
            visible = true,
            animations = req#animations,
            currentAnimation = req#initialAnimation,
            currentFrame = 0,
            frameTimer = 0.0f32,
            fps = 6.0f32,
            playing = true,
            flipH = false,
            flipV = false,
            rotation = 0.0f32
        })

    def modify(f: SceneTree.AnimatedSpriteData -> SceneTree.AnimatedSpriteData, node: SceneTree.Node): SceneTree.Node =
        SceneTree.updateAnimatedSprite(SceneTree.nodeName(node), f, node)

    pub def color(v: Engine.Color, node: SceneTree.Node): SceneTree.Node =
        modify(asd -> {color = v | asd}, node)

    pub def fps(v: Float32, node: SceneTree.Node): SceneTree.Node =
        modify(asd -> {fps = v | asd}, node)

    pub def playing(v: Bool, node: SceneTree.Node): SceneTree.Node =
        modify(asd -> {playing = v | asd}, node)

    pub def play(node: SceneTree.Node): SceneTree.Node =
        playing(true, node)

    pub def stop(node: SceneTree.Node): SceneTree.Node =
        playing(false, node)

    pub def animation(v: String, node: SceneTree.Node): SceneTree.Node =
        modify(asd -> {currentAnimation = v | asd}, node)

    pub def flipH(v: Bool, node: SceneTree.Node): SceneTree.Node =
        modify(asd -> {flipH = v | asd}, node)

    pub def flipV(v: Bool, node: SceneTree.Node): SceneTree.Node =
        modify(asd -> {flipV = v | asd}, node)

    pub def rotation(v: Float32, node: SceneTree.Node): SceneTree.Node =
        modify(asd -> {rotation = v | asd}, node)
}

// ========================================================================
// Area2D
// ========================================================================

mod Area2D {
    pub def init(req: {name = String, pos = Vec2D.Vec2, children = List[SceneTree.Node]}): SceneTree.Node =
        SceneTree.area2D(req#name, req#pos, {velocity = Vec2D.zero()}, req#children)

    pub def velocity(v: Vec2D.Vec2, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Area(ad) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Area({velocity = v | ad}), ch)
            case _ => node
        }
}

// ========================================================================
// StaticBody2D
// ========================================================================

mod StaticBody2D {
    pub def init(req: {name = String, pos = Vec2D.Vec2, children = List[SceneTree.Node]}): SceneTree.Node =
        SceneTree.staticBody2D(req#name, req#pos,
            {isSolid = true, destroyed = false}, req#children)

    pub def isSolid(v: Bool, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Fixed(bd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Fixed({isSolid = v | bd}), ch)
            case _ => node
        }

    pub def destroyed(v: Bool, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Fixed(bd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Fixed({destroyed = v | bd}), ch)
            case _ => node
        }
}

// ========================================================================
// CharacterBody2D
// ========================================================================

mod CharacterBody2D {
    pub def init(req: {name = String, pos = Vec2D.Vec2, children = List[SceneTree.Node]}): SceneTree.Node =
        SceneTree.characterBody2D(req#name, req#pos,
            {targetPos = req#pos, moveSpeed = 0.0f32}, req#children)

    pub def moveSpeed(v: Float32, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Character(cbd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Character({moveSpeed = v | cbd}), ch)
            case _ => node
        }

    pub def targetPos(v: Vec2D.Vec2, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Character(cbd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Character({targetPos = v | cbd}), ch)
            case _ => node
        }
}

// ========================================================================
// Raycast2D
// ========================================================================

mod Raycast2D {
    pub def init(req: {name = String, pos = Vec2D.Vec2, direction = Vec2D.Vec2}): SceneTree.Node =
        SceneTree.raycast2DNode(req#name, req#pos,
            {direction = req#direction, maxDistance = 32.0f32, enabled = true})

    pub def maxDistance(v: Float32, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Raycast(rd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Raycast({maxDistance = v | rd}), ch)
            case _ => node
        }

    pub def enabled(v: Bool, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Raycast(rd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Raycast({enabled = v | rd}), ch)
            case _ => node
        }
}

// ========================================================================
// Camera2D
// ========================================================================

mod Camera2D {
    pub def init(req: {name = String, pos = Vec2D.Vec2}): SceneTree.Node =
        SceneTree.camera2DNode(req#name, req#pos, {
            offset = Vec2D.zero(),
            zoom = Vec2D.one(),
            smoothingEnabled = false,
            smoothingSpeed = 5.0f32,
            limitLeft = -10000000.0f32,
            limitRight = 10000000.0f32,
            limitTop = -10000000.0f32,
            limitBottom = 10000000.0f32,
            isCurrent = false,
            smoothedPos = Vec2D.zero()
        })

    pub def offset(v: Vec2D.Vec2, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Camera(cd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Camera({offset = v | cd}), ch)
            case _ => node
        }

    pub def zoom(v: Vec2D.Vec2, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Camera(cd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Camera({zoom = v | cd}), ch)
            case _ => node
        }

    pub def smoothingEnabled(v: Bool, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Camera(cd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Camera({smoothingEnabled = v | cd}), ch)
            case _ => node
        }

    pub def smoothingSpeed(v: Float32, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Camera(cd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Camera({smoothingSpeed = v | cd}), ch)
            case _ => node
        }

    pub def limits(l: Float32, r: Float32, t: Float32, b: Float32, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Camera(cd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Camera({limitLeft = l, limitRight = r, limitTop = t, limitBottom = b | cd}), ch)
            case _ => node
        }

    pub def makeCurrent(v: Bool, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Camera(cd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Camera({isCurrent = v | cd}), ch)
            case _ => node
        }
}

// ========================================================================
// RigidBody2D
// ========================================================================

mod RigidBody2D {
    pub def init(req: {name = String, pos = Vec2D.Vec2, children = List[SceneTree.Node]}): SceneTree.Node =
        SceneTree.rigidBody2D(req#name, req#pos,
            {velocity = Vec2D.zero(), gravityScale = 1.0f32, rotation = 0.0f32}, req#children)

    pub def velocity(v: Vec2D.Vec2, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Rigid(bd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Rigid({velocity = v | bd}), ch)
            case _ => node
        }

    pub def gravityScale(v: Float32, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Rigid(bd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Rigid({gravityScale = v | bd}), ch)
            case _ => node
        }

    pub def rotation(v: Float32, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Rigid(bd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Rigid({rotation = v | bd}), ch)
            case _ => node
        }
}

// ========================================================================
// VisibleOnScreenNotifier2D
// ========================================================================

mod VisibleOnScreenNotifier2D {
    pub def init(req: {name = String, rect = Vec2D.Vec2}): SceneTree.Node =
        SceneTree.screenNotifier2D(req#name, {rect = req#rect})
}

// ========================================================================
// Timer2D
// ========================================================================

mod Timer2D {
    pub def init(req: {name = String, waitTime = Float32, oneShot = Bool}): SceneTree.Node =
        SceneTree.timerNode(req#name, {
            elapsed = 0.0f32, waitTime = req#waitTime,
            running = false, oneShot = req#oneShot
        })

    pub def start(node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Timer(td) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Timer({elapsed = 0.0f32, running = true | td}), ch)
            case _ => node
        }

    pub def stop(node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Timer(td) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Timer({elapsed = 0.0f32, running = false | td}), ch)
            case _ => node
        }
}

// ========================================================================
// Marker2D
// ========================================================================

mod Marker2D {
    pub def init(req: {name = String, pos = Vec2D.Vec2}): SceneTree.Node =
        SceneTree.marker2D(req#name, req#pos)
}

// ========================================================================
// Path2D
// ========================================================================

mod Path2D {
    pub def init(req: {name = String, pos = Vec2D.Vec2, points = List[Vec2D.Vec2]}): SceneTree.Node =
        SceneTree.path2D(req#name, req#pos, {points = req#points}, Nil)
}

// ========================================================================
// PathFollow2D
// ========================================================================

mod PathFollow2D {
    pub def init(req: {name = String}): SceneTree.Node =
        SceneTree.pathFollow2D(req#name, {progressRatio = 0.0f32})

    pub def progressRatio(v: Float32, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.PathFollow(pfd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.PathFollow({progressRatio = v | pfd}), ch)
            case _ => node
        }
}

// ========================================================================
// Label2D
// ========================================================================

mod Label2D {
    pub def init(req: {name = String, pos = Vec2D.Vec2, text = String, fontSize = Float32, font = String}): SceneTree.Node =
        SceneTree.label2D(req#name, req#pos, {
            text = req#text,
            font = req#font,
            fontSize = req#fontSize,
            color = {r = 1.0f32, g = 1.0f32, b = 1.0f32},
            visible = true,
            centered = false,
            wrapWidth = 0.0f32
        })

    pub def text(v: String, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Label(ld) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Label({text = v | ld}), ch)
            case _ => node
        }

    pub def visible(v: Bool, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Label(ld) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Label({visible = v | ld}), ch)
            case _ => node
        }

    pub def centered(v: Bool, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Label(ld) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Label({centered = v | ld}), ch)
            case _ => node
        }

    pub def font(v: String, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Label(ld) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Label({font = v | ld}), ch)
            case _ => node
        }

    pub def color(v: Engine.Color, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Label(ld) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Label({color = v | ld}), ch)
            case _ => node
        }

    pub def wrapWidth(v: Float32, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Label(ld) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Label({wrapWidth = v | ld}), ch)
            case _ => node
        }
}

// ========================================================================
// Button2D
// ========================================================================

mod Button2D {
    pub def init(req: {name = String, pos = Vec2D.Vec2, text = String, fontSize = Float32, font = String}): SceneTree.Node =
        SceneTree.button2D(req#name, req#pos, {
            text = req#text,
            font = req#font,
            fontSize = req#fontSize,
            color = {r = 1.0f32, g = 1.0f32, b = 1.0f32},
            visible = false,
            bgColor = {r = 0.15f32, g = 0.17f32, b = 0.2f32},
            bgPadding = {x = 0.5f32, y = 0.25f32}
        })

    pub def text(v: String, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Button(bd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Button({text = v | bd}), ch)
            case _ => node
        }

    pub def visible(v: Bool, node: SceneTree.Node): SceneTree.Node =
        let SceneTree.Node.MkNode(n, p, kind, ch) = node;
        match kind {
            case SceneTree.NodeKind.Button(bd) =>
                SceneTree.Node.MkNode(n, p, SceneTree.NodeKind.Button({visible = v | bd}), ch)
            case _ => node
        }
}

// ========================================================================
// CanvasLayer2D
// ========================================================================

mod CanvasLayer2D {
    pub def init(req: {name = String, children = List[SceneTree.Node]}): SceneTree.Node =
        SceneTree.canvasLayer(req#name, req#children)
}
