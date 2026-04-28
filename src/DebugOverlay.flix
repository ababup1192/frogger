// DebugOverlay — デバッグモードのシーンツリーナビゲーションとオーバーレイ描画

mod DebugOverlay {

    // ========================================================================
    // Helpers
    // ========================================================================

    /// Bool を文字列に変換する
    def boolStr(b: Bool): String = if (b) "true" else "false"

    // ========================================================================
    // Constants
    // ========================================================================

    /// デバッグ情報に使用するフォントサイズ
    def fontSize(): Float32 = 16.0f32

    /// インスペクタの左上マージン
    def inspectorX(): Float32 = 8.0f32
    def inspectorY(): Float32 = 20.0f32

    /// インスペクタの行間
    def lineHeight(): Float32 = 20.0f32

    // ========================================================================
    // ボディ種別ごとの色定義
    // ========================================================================

    /// Area ノードの色（緑）
    def areaColor(): Engine.Color = {r = 0.0f32, g = 1.0f32, b = 0.0f32}

    /// Character ノードの色（青）
    def characterColor(): Engine.Color = {r = 0.3f32, g = 0.5f32, b = 1.0f32}

    /// Kinematic ノードの色（オレンジ）
    def kinematicColor(): Engine.Color = {r = 1.0f32, g = 0.6f32, b = 0.0f32}

    /// Fixed ノードの色（灰）
    def fixedColor(): Engine.Color = {r = 0.5f32, g = 0.5f32, b = 0.5f32}

    /// スプライト境界の色（白）
    def spriteColor(): Engine.Color = {r = 1.0f32, g = 1.0f32, b = 1.0f32}

    /// アニメ情報テキストの色（黄）
    def animInfoColor(): Engine.Color = {r = 1.0f32, g = 1.0f32, b = 0.3f32}

    /// インスペクタテキストの色（白）
    def inspectorColor(): Engine.Color = {r = 1.0f32, g = 1.0f32, b = 1.0f32}

    /// インスペクタ背景用のテキスト色（暗め）
    def inspectorBgColor(): Engine.Color = {r = 0.0f32, g = 0.0f32, b = 0.0f32}

    // ========================================================================
    // 空のオーバーレイ
    // ========================================================================

    /// 空のデバッグオーバーレイを返す
    pub def empty(): Engine.DebugOverlay =
        {rects = Nil, labels = Nil}

    // ========================================================================
    // ナビゲーション — パスベースのシーンツリー走査
    // ========================================================================

    /// パスを辿って対象ノードを取得する。
    /// path が空の場合は root 自身を返す。
    pub def nodeAtPath(path: List[Int32], root: SceneTree.Node): Option[SceneTree.Node] =
        match path {
            case Nil => Some(root)
            case idx :: rest =>
                let children = SceneTree.nodeChildren(root);
                List.nth(idx, children) |> Option.flatMap(child -> nodeAtPath(rest, child))
        }

    /// パスを辿って対象ノードのグローバル位置を計算する。
    /// ルートからの座標を累積して返す。
    pub def globalPosAtPath(path: List[Int32], root: SceneTree.Node): Option[Vec2D.Vec2] =
        globalPosAtPathHelper(path, root, Vec2D.zero())

    def globalPosAtPathHelper(path: List[Int32], node: SceneTree.Node, acc: Vec2D.Vec2): Option[Vec2D.Vec2] =
        let pos = Vec2D.add(acc, SceneTree.nodePosition(node));
        match path {
            case Nil => Some(pos)
            case idx :: rest =>
                List.nth(idx, SceneTree.nodeChildren(node))
                    |> Option.flatMap(child -> globalPosAtPathHelper(rest, child, pos))
        }

    /// 右の兄弟ノードに移動する（ラップ）。
    /// パスの末尾インデックスを +1 する。
    pub def navigateRight(path: List[Int32], root: SceneTree.Node): List[Int32] =
        match List.reverse(path) {
            case Nil => Nil
            case lastIdx :: revParent =>
                let parentPath = List.reverse(revParent);
                let siblingCount = nodeAtPath(parentPath, root)
                    |> Option.map(n -> List.length(SceneTree.nodeChildren(n)))
                    |> Option.getWithDefault(1);
                if (siblingCount <= 1) path
                else List.append(parentPath, Int32.remainder(lastIdx + 1, siblingCount) :: Nil)
        }

    /// 左の兄弟ノードに移動する（ラップ）。
    /// パスの末尾インデックスを -1 する。
    pub def navigateLeft(path: List[Int32], root: SceneTree.Node): List[Int32] =
        match List.reverse(path) {
            case Nil => Nil
            case lastIdx :: revParent =>
                let parentPath = List.reverse(revParent);
                let siblingCount = nodeAtPath(parentPath, root)
                    |> Option.map(n -> List.length(SceneTree.nodeChildren(n)))
                    |> Option.getWithDefault(1);
                if (siblingCount <= 1) path
                else {
                    let newIdx = if (lastIdx <= 0) siblingCount - 1 else lastIdx - 1;
                    List.append(parentPath, newIdx :: Nil)
                }
        }

    /// 子ノードに入る（最初の子を選択）。
    /// 子がない場合は現在のパスを返す。
    pub def navigateDown(path: List[Int32], root: SceneTree.Node): List[Int32] =
        let current = nodeAtPath(path, root);
        match current {
            case Some(node) =>
                if (List.isEmpty(SceneTree.nodeChildren(node))) path
                else List.append(path, 0 :: Nil)
            case None => path
        }

    /// 親ノードに戻る（パスの末尾を削除）。
    /// ルートの場合はそのまま返す。
    pub def navigateUp(path: List[Int32]): List[Int32] =
        match List.reverse(path) {
            case Nil => Nil
            case _ :: revParent => List.reverse(revParent)
        }

    // ========================================================================
    // パス表示用
    // ========================================================================

    /// ナビゲーションパスを "Root > Player > Sprite" 形式の文字列に変換する
    pub def pathString(path: List[Int32], root: SceneTree.Node): String =
        pathStringHelper(path, root, SceneTree.nodeName(root) :: Nil)
            |> List.reverse
            |> List.join(" > ")

    def pathStringHelper(path: List[Int32], node: SceneTree.Node, acc: List[String]): List[String] =
        match path {
            case Nil => acc
            case idx :: rest =>
                match List.nth(idx, SceneTree.nodeChildren(node)) {
                    case Some(child) => pathStringHelper(rest, child, SceneTree.nodeName(child) :: acc)
                    case None => acc
                }
        }

    // ========================================================================
    // NodeKind の文字列表現
    // ========================================================================

    /// NodeKind を人間が読める文字列に変換する
    def kindToString(kind: SceneTree.NodeKind): String =
        match kind {
            case SceneTree.NodeKind.Plain               => "Plain"
            case SceneTree.NodeKind.Sprite(_)            => "Sprite2D"
            case SceneTree.NodeKind.AnimatedSprite(_)    => "AnimatedSprite2D"
            case SceneTree.NodeKind.Area(_)              => "Area2D"
            case SceneTree.NodeKind.Character(_)         => "Character2D"
            case SceneTree.NodeKind.Kinematic(_)         => "Kinematic2D"
            case SceneTree.NodeKind.Fixed(_)             => "StaticBody2D"
            case SceneTree.NodeKind.Rigid(_)             => "RigidBody2D"
            case SceneTree.NodeKind.Shape(_)             => "CollisionShape2D"
            case SceneTree.NodeKind.Timer(_)             => "Timer"
            case SceneTree.NodeKind.Label(_)             => "Label"
            case SceneTree.NodeKind.Button(_)            => "Button"
            case SceneTree.NodeKind.Camera(_)            => "Camera2D"
            case SceneTree.NodeKind.Raycast(_)           => "Raycast2D"
            case SceneTree.NodeKind.ScreenNotifier(_)    => "ScreenNotifier2D"
            case SceneTree.NodeKind.Marker               => "Marker2D"
            case SceneTree.NodeKind.Path(_)              => "Path2D"
            case SceneTree.NodeKind.PathFollow(_)        => "PathFollow2D"
            case SceneTree.NodeKind.CanvasLayer           => "CanvasLayer"
        }

    // ========================================================================
    // インスペクタ情報テキスト生成
    // ========================================================================

    /// テキスト行をTextDrawableに変換するヘルパー。
    /// 行番号に応じてY座標をずらす。
    def mkInspectorLine(lineIdx: Int32, text: String, font: String): SceneTree.TextDrawable =
        {text = text, font = font, fontSize = fontSize(),
         color = inspectorColor(),
         position = {x = inspectorX(), y = inspectorY() + Int32.toFloat32(lineIdx) * lineHeight()},
         centered = false, isButton = false, nodeName = "debug_inspector",
         wrapWidth = 0.0f32, bgColor = None, bgPadding = None}

    /// 選択ノードの詳細テキストを画面左上に生成する
    pub def inspectorText(node: SceneTree.Node, path: List[Int32],
                          root: SceneTree.Node, font: String): List[SceneTree.TextDrawable] =
        let ps = pathString(path, root);
        let kind = SceneTree.nodeKind(node);
        let pos = SceneTree.nodePosition(node);
        let childCount = List.length(SceneTree.nodeChildren(node));
        // 共通行
        let header = "[Debug] ${ps}" :: "Type: ${kindToString(kind)}" :: Nil;
        let posLine = "Position: (${Float32.toString(pos#x)}, ${Float32.toString(pos#y)})" :: Nil;
        let childLine = "Children: ${Int32.toString(childCount)}" :: Nil;
        // 種別固有の情報行
        let kindLines = match kind {
            case SceneTree.NodeKind.Sprite(sd) =>
                "Size: ${Float32.toString(sd#size#x)}x${Float32.toString(sd#size#y)}" ::
                "Texture: ${sd#texture}" ::
                "Visible: ${boolStr(sd#visible)}" ::
                "Rotation: ${Float32.toString(sd#rotation)}" :: Nil
            case SceneTree.NodeKind.AnimatedSprite(asd) =>
                let fc = asd#animations
                    |> Map.get(asd#currentAnimation)
                    |> Option.map(e -> List.length(e#frames))
                    |> Option.getWithDefault(0);
                "Size: ${Float32.toString(asd#size#x)}x${Float32.toString(asd#size#y)}" ::
                "Animation: ${asd#currentAnimation} [${Int32.toString(asd#currentFrame)}/${Int32.toString(fc)}]" ::
                "FPS: ${Float32.toString(asd#fps)}  Playing: ${boolStr(asd#playing)}" ::
                "FlipH: ${boolStr(asd#flipH)}  FlipV: ${boolStr(asd#flipV)}" ::
                "Rotation: ${Float32.toString(asd#rotation)}" :: Nil
            case SceneTree.NodeKind.Area(ad) =>
                "Velocity: (${Float32.toString(ad#velocity#x)}, ${Float32.toString(ad#velocity#y)})" :: Nil
            case SceneTree.NodeKind.Character(cbd) =>
                "TargetPos: (${Float32.toString(cbd#targetPos#x)}, ${Float32.toString(cbd#targetPos#y)})" ::
                "MoveSpeed: ${Float32.toString(cbd#moveSpeed)}" :: Nil
            case SceneTree.NodeKind.Kinematic(kbd) =>
                "Velocity: (${Float32.toString(kbd#velocity#x)}, ${Float32.toString(kbd#velocity#y)})" :: Nil
            case SceneTree.NodeKind.Fixed(bd) =>
                "IsSolid: ${boolStr(bd#isSolid)}" ::
                "Destroyed: ${boolStr(bd#destroyed)}" :: Nil
            case SceneTree.NodeKind.Rigid(bd) =>
                "Velocity: (${Float32.toString(bd#velocity#x)}, ${Float32.toString(bd#velocity#y)})" ::
                "GravityScale: ${Float32.toString(bd#gravityScale)}" :: Nil
            case SceneTree.NodeKind.Shape(shape) =>
                match shape {
                    case SceneTree.CollisionShapeData.RectShape(sz) =>
                        "Shape: Rect ${Float32.toString(sz#x)}x${Float32.toString(sz#y)}" :: Nil
                    case SceneTree.CollisionShapeData.CircleShape(r) =>
                        "Shape: Circle r=${Float32.toString(r)}" :: Nil
                    case SceneTree.CollisionShapeData.CapsuleShape(r, h) =>
                        "Shape: Capsule r=${Float32.toString(r)} h=${Float32.toString(h)}" :: Nil
                }
            case SceneTree.NodeKind.Timer(td) =>
                "Elapsed: ${Float32.toString(td#elapsed)} / ${Float32.toString(td#waitTime)}" ::
                "Running: ${boolStr(td#running)}  OneShot: ${boolStr(td#oneShot)}" :: Nil
            case SceneTree.NodeKind.Label(ld) =>
                "Text: ${ld#text}" ::
                "FontSize: ${Float32.toString(ld#fontSize)}" ::
                "Visible: ${boolStr(ld#visible)}" :: Nil
            case SceneTree.NodeKind.Button(bd) =>
                "Text: ${bd#text}" ::
                "Visible: ${boolStr(bd#visible)}" :: Nil
            case _ => Nil
        };
        // 背景用の半透明黒帯（最初の行）
        let allLines = List.append(header, List.append(posLine, List.append(kindLines, childLine)));
        let lineCount = List.length(allLines);
        let bgHeight = Int32.toFloat32(lineCount) * lineHeight() + 8.0f32;
        let bgRect: SceneTree.TextDrawable = {
            text = "", font = font, fontSize = fontSize(),
            color = inspectorBgColor(),
            position = {x = 0.0f32, y = 0.0f32},
            centered = false, isButton = false, nodeName = "debug_bg",
            wrapWidth = 0.0f32,
            bgColor = Some({r = 0.0f32, g = 0.0f32, b = 0.0f32}),
            bgPadding = None
        };
        // 各行をTextDrawableに変換（空テキストのbg行はスキップ）
        let _ = bgRect;
        let _ = bgHeight;
        List.mapWithIndex((idx, line) -> mkInspectorLine(idx, line, font), allLines)

    // ========================================================================
    // オーバーレイ収集 — 選択ノード配下のヒットボックス・スプライト境界
    // ========================================================================

    /// ボディの親ノード種別からヒットボックスの色を決定する
    def bodyKindColor(kind: SceneTree.NodeKind): Engine.Color =
        match kind {
            case SceneTree.NodeKind.Area(_)      => areaColor()
            case SceneTree.NodeKind.Character(_)  => characterColor()
            case SceneTree.NodeKind.Kinematic(_)  => kinematicColor()
            case SceneTree.NodeKind.Fixed(_)      => fixedColor()
            case _ => spriteColor()
        }

    /// 選択ノード配下を再帰走査し、ヒットボックス矩形・スプライト境界・アニメ情報を収集する
    pub def collectOverlay(selectedNode: SceneTree.Node, globalPos: Vec2D.Vec2,
                           font: String): Engine.DebugOverlay =
        collectOverlayHelper(selectedNode, globalPos, SceneTree.NodeKind.Plain, font)

    def collectOverlayHelper(node: SceneTree.Node, parentPos: Vec2D.Vec2,
                              parentKind: SceneTree.NodeKind,
                              font: String): Engine.DebugOverlay =
        let SceneTree.Node.MkNode(_name, pos, kind, children) = node;
        let gpos = Vec2D.add(parentPos, pos);
        match kind {
            case SceneTree.NodeKind.Shape(shape) =>
                // コリジョンシェイプ → 親ボディの色で矩形枠を生成
                let sz = match shape {
                    case SceneTree.CollisionShapeData.RectShape(s) => s
                    case SceneTree.CollisionShapeData.CircleShape(r) => {x = 2.0f32 * r, y = 2.0f32 * r}
                    case SceneTree.CollisionShapeData.CapsuleShape(r, h) => {x = 2.0f32 * r, y = h}
                };
                let c = bodyKindColor(parentKind);
                let rect: Engine.DebugRect = {pos = gpos, size = sz, color = c};
                {rects = rect :: Nil, labels = Nil}
            case SceneTree.NodeKind.Sprite(sd) =>
                if (sd#visible) {
                    let rect: Engine.DebugRect = {pos = gpos, size = sd#size, color = spriteColor()};
                    {rects = rect :: Nil, labels = Nil}
                } else empty()
            case SceneTree.NodeKind.AnimatedSprite(asd) =>
                if (asd#visible) {
                    let rect: Engine.DebugRect = {pos = gpos, size = asd#size, color = spriteColor()};
                    let fc = asd#animations
                        |> Map.get(asd#currentAnimation)
                        |> Option.map(e -> List.length(e#frames))
                        |> Option.getWithDefault(0);
                    let info = "${asd#currentAnimation} [${Int32.toString(asd#currentFrame)}/${Int32.toString(fc)}] flipH=${boolStr(asd#flipH)}";
                    let label: SceneTree.TextDrawable = {
                        text = info, font = font, fontSize = 12.0f32,
                        color = animInfoColor(),
                        position = {x = gpos#x, y = gpos#y - 14.0f32},
                        centered = false, isButton = false, nodeName = "debug_anim_info",
                        wrapWidth = 0.0f32, bgColor = None, bgPadding = None
                    };
                    {rects = rect :: Nil, labels = label :: Nil}
                } else empty()
            case _ =>
                // 再帰的に子ノードを走査（親の種別を引き継ぐ）
                let effectiveParentKind = match kind {
                    case SceneTree.NodeKind.Area(_)      => kind
                    case SceneTree.NodeKind.Character(_)  => kind
                    case SceneTree.NodeKind.Kinematic(_)  => kind
                    case SceneTree.NodeKind.Fixed(_)      => kind
                    case SceneTree.NodeKind.Rigid(_)      => kind
                    case _                               => parentKind
                };
                List.foldLeft((acc, child) -> {
                    let childOverlay = collectOverlayHelper(child, gpos, effectiveParentKind, font);
                    {rects = List.append(acc#rects, childOverlay#rects),
                     labels = List.append(acc#labels, childOverlay#labels)}
                }, empty(), children)
        }

}
