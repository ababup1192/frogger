// SceneLoader — JSONファイルからシーンツリーを構築する

mod SceneLoader {
    use Json.JsonElement.{JsonObject, JsonArray}
    use Json.JsonError.JsonError
    use Json.Path.Path
    use Json.Path.Path.{Root, AtKey}

    /// JSONファイルを読み込み、SceneTree.Node に変換する。
    /// $ プレフィックス付きテンプレート参照を自動的に解決する。失敗時はクラッシュする
    pub def loadScene(path: String): SceneTree.Node \ Fs.FileRead =
        let content = run { Fs.ReadFile.read(path) } with Fs.ReadFile.runWithFileRead;
        let textResult = content |> Result.mapErr(e -> "failed to read: ${e}");
        let jsonResult = Result.flatMap(text ->
            Json.Parse.parse(text) |> Option.toOk("JSON parse failed"), textResult);
        match jsonResult {
            case Ok(json) =>
                let templates = collectTemplateRefs(json) |> loadTemplates;
                match parseNode(Root, json, templates)
                        |> Result.mapErr(match JsonError(errPath, expected) ->
                            "at ${errPath}: expected ${expected}") {
                    case Ok(node) => node
                    case Err(msg) => bug!("SceneLoader: ${path}: ${msg}")
                }
            case Err(msg) => bug!("SceneLoader: ${path}: ${msg}")
        }

    // ========================================================================
    // テンプレート参照機構
    // ========================================================================

    /// JSON ツリーから $ プレフィックス付きテンプレート参照名を収集する
    def collectTemplateRefs(json: Json.JsonElement): Set[String] =
        match json {
            case JsonObject(map) =>
                let typeRef = match (Json.getAtKey(Root, "type", map): Result[Json.JsonError, String]) {
                    case Ok(t) =>
                        if (String.startsWith({prefix = "$"}, t))
                            Set#{String.dropLeft(1, t)}
                        else Set#{}
                    case Err(_) => Set#{}
                };
                let childRefs = match Map.get("children", map) {
                    case Some(JsonArray(arr)) =>
                        List.foldLeft((acc, child) ->
                            Set.union(acc, collectTemplateRefs(child)),
                            Set#{}, Vector.toList(arr))
                    case _ => Set#{}
                };
                Set.union(typeRef, childRefs)
            case _ => Set#{}
        }

    /// テンプレート参照名のセットから、各テンプレートの SceneTree.Node をロードする
    def loadTemplates(refs: Set[String]): Map[String, SceneTree.Node] \ Fs.FileRead =
        Set.foldLeft((acc, name) -> {
            let templatePath = "src/scenes/${name}.scene.json";
            let node = loadScene(templatePath);
            Map.insert(name, node, acc)
        }, Map#{}, refs)

    /// テンプレートをインスタンス化する（name, pos, velocity, texture をオーバーライド）
    def buildTemplateRef(path: Path, templateNode: SceneTree.Node,
                         map: Map[String, Json.JsonElement]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            name        <- Json.getAtKey(path, "name", map);
            pos         <- parseVec2(path, "pos", map);
            velocityOpt <- parseVec2Opt(path, "velocity", map);
            textureOpt  <- (Json.getAtKeyOpt(path, "texture", map): Result[Json.JsonError, Option[String]])
        ) yield {
            let SceneTree.Node.MkNode(_, _, kind, children) = templateNode;
            // velocity オーバーライド
            let newKind = match (kind, velocityOpt) {
                case (SceneTree.NodeKind.Area(ad), Some(vel)) =>
                    SceneTree.NodeKind.Area({velocity = vel | ad})
                case _ => kind
            };
            // texture オーバーライド（子 Sprite の texture を置換）
            let newChildren = match textureOpt {
                case Some(tex) => List.map(child -> match SceneTree.nodeKind(child) {
                    case SceneTree.NodeKind.Sprite(sd) =>
                        let SceneTree.Node.MkNode(cn, cp, _, cch) = child;
                        SceneTree.Node.MkNode(cn, cp, SceneTree.NodeKind.Sprite({texture = tex | sd}), cch)
                    case _ => child
                }, children)
                case None => children
            };
            SceneTree.Node.MkNode(name, pos, newKind, newChildren)
        }

    // ========================================================================
    // JSON → Node 変換
    // ========================================================================

    /// JsonElement を再帰的に SceneTree.Node に変換する
    def parseNode(path: Path, json: Json.JsonElement,
                  templates: Map[String, SceneTree.Node]): Result[Json.JsonError, SceneTree.Node] =
        match json {
            case JsonObject(map) =>
                forM (
                    nodeType <- Json.getAtKey(path, "type", map);
                    name <- Json.getAtKey(path, "name", map);
                    node <- buildByType(path, nodeType, name, map, templates)
                ) yield node
            case _ => Err(JsonError(path, Set#{"JsonObject"}))
        }

    /// "type" フィールドに応じて対応するノードビルダーを呼び出す。
    /// $ プレフィックスはテンプレート参照として解決する
    def buildByType(path: Path, nodeType: String, name: String,
                    map: Map[String, Json.JsonElement],
                    templates: Map[String, SceneTree.Node]): Result[Json.JsonError, SceneTree.Node] =
        match nodeType {
            case "CharacterBody2D"  => buildCharacterBody2D(path, name, map, templates)
            case "AnimatedSprite2D" => buildAnimatedSprite2D(path, name, map)
            case "Area2D"           => buildArea2D(path, name, map, templates)
            case "RectShape2D"      => buildRectShape2D(path, name, map)
            case "Node2D"           => buildNode2D(path, name, map, templates)
            case "Sprite2D"         => buildSprite2D(path, name, map)
            case "Label2D"          => buildLabel2D(path, name, map)
            case "CanvasLayer2D"    => buildCanvasLayer2D(path, name, map, templates)
            case unknown            =>
                if (String.startsWith({prefix = "$"}, unknown)) {
                    let templateName = String.dropLeft(1, unknown);
                    match Map.get(templateName, templates) {
                        case Some(tmpl) => buildTemplateRef(path, tmpl, map)
                        case None => Err(JsonError(path, Set#{"known template (got: ${templateName})"}))
                    }
                } else
                    Err(JsonError(path, Set#{"known node type (got: ${unknown})"}))
        }

    // ========================================================================
    // ヘルパー
    // ========================================================================

    /// JSON配列 [x, y] を Vec2D.Vec2 に変換する
    def parseVec2(path: Path, key: String,
                  map: Map[String, Json.JsonElement]): Result[Json.JsonError, Vec2D.Vec2] =
        forM (
            pair <- (Json.getAtKey(path, key, map): Result[Json.JsonError, (Float32, Float32)])
        ) yield {
            let (x, y) = pair;
            {x = x, y = y}
        }

    /// JSON配列 [x, y] をオプショナルに Vec2D.Vec2 に変換する（キーがなければ None）
    def parseVec2Opt(path: Path, key: String,
                     map: Map[String, Json.JsonElement]): Result[Json.JsonError, Option[Vec2D.Vec2]] =
        forM (
            pairOpt <- (Json.getAtKeyOpt(path, key, map): Result[Json.JsonError, Option[(Float32, Float32)]])
        ) yield match pairOpt {
            case Some((x, y)) => Some({x = x, y = y})
            case None         => None
        }

    /// JSON配列 [r, g, b] を Option[Engine.Color] に変換する
    def parseColorOpt(path: Path, key: String,
                      map: Map[String, Json.JsonElement]): Result[Json.JsonError, Option[Engine.Color]] =
        forM (
            tripleOpt <- (Json.getAtKeyOpt(path, key, map): Result[Json.JsonError, Option[(Float32, Float32, Float32)]])
        ) yield match tripleOpt {
            case Some((r, g, b)) => Some({r = r, g = g, b = b})
            case None            => None
        }

    /// オプション値が Some の場合のみノードに適用する
    def optApply(opt: Option[a], f: a -> (SceneTree.Node -> SceneTree.Node),
                 node: SceneTree.Node): SceneTree.Node =
        match opt {
            case Some(v) => f(v, node)
            case None    => node
        }

    /// children 配列を再帰的にパースする。キーがなければ空リストを返す
    def parseChildren(path: Path, map: Map[String, Json.JsonElement],
                      templates: Map[String, SceneTree.Node]): Result[Json.JsonError, List[SceneTree.Node]] =
        let childPath = Json.Path.atKey("children", path);
        match Map.get("children", map) {
            case None              => Ok(Nil)
            case Some(JsonArray(arr)) =>
                parseChildList(childPath, Vector.toList(arr), 0, templates)
            case Some(_)           => Err(JsonError(childPath, Set#{"JsonArray"}))
        }

    /// JsonElement のリストを順にパースして SceneTree.Node のリストに変換する
    def parseChildList(path: Path, elems: List[Json.JsonElement], idx: Int32,
                       templates: Map[String, SceneTree.Node]): Result[Json.JsonError, List[SceneTree.Node]] =
        match elems {
            case Nil => Ok(Nil)
            case x :: xs =>
                forM (
                    node <- parseNode(Json.Path.atIndex(idx, path), x, templates);
                    rest <- parseChildList(path, xs, idx + 1, templates)
                ) yield node :: rest
        }

    /// アニメーション定義をパースする。{"name": ["frame1", ...]} → Map[String, AnimationEntry]
    def parseAnimations(path: Path,
                        map: Map[String, Json.JsonElement]): Result[Json.JsonError, Map[String, SceneTree.AnimationEntry]] =
        forM (
            raw <- (Json.getAtKey(path, "animations", map): Result[Json.JsonError, Map[String, List[String]]])
        ) yield {
            raw |> Map.map(frames -> ({frames = frames}: SceneTree.AnimationEntry))
        }

    // ========================================================================
    // ノードタイプ別ビルダー
    // ========================================================================

    /// CharacterBody2D ノードを構築する
    def buildCharacterBody2D(path: Path, name: String, map: Map[String, Json.JsonElement],
                             templates: Map[String, SceneTree.Node]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            pos         <- parseVec2(path, "pos", map);
            speedOpt    <- (Json.getAtKeyOpt(path, "moveSpeed", map): Result[Json.JsonError, Option[Float32]]);
            children    <- parseChildren(path, map, templates)
        ) yield {
            let node = CharacterBody2D.init({name = name, pos = pos, children = children});
            match speedOpt {
                case Some(s) => node |> CharacterBody2D.moveSpeed(s)
                case None    => node
            }
        }

    /// AnimatedSprite2D ノードを構築する
    def buildAnimatedSprite2D(path: Path, name: String,
                              map: Map[String, Json.JsonElement]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            pos              <- parseVec2(path, "pos", map);
            size             <- parseVec2(path, "size", map);
            animations       <- parseAnimations(path, map);
            initialAnimation <- Json.getAtKey(path, "initialAnimation", map);
            fpsOpt           <- (Json.getAtKeyOpt(path, "fps", map): Result[Json.JsonError, Option[Float32]])
        ) yield {
            let node = AnimatedSprite2D.init({name = name, pos = pos, size = size,
                                              animations = animations,
                                              initialAnimation = initialAnimation});
            match fpsOpt {
                case Some(f) => node |> AnimatedSprite2D.fps(f)
                case None    => node
            }
        }

    /// Area2D ノードを構築する（velocity はオプション）
    def buildArea2D(path: Path, name: String, map: Map[String, Json.JsonElement],
                    templates: Map[String, SceneTree.Node]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            pos         <- parseVec2(path, "pos", map);
            velocityOpt <- parseVec2Opt(path, "velocity", map);
            children    <- parseChildren(path, map, templates)
        ) yield {
            let node = Area2D.init({name = name, pos = pos, children = children});
            optApply(velocityOpt, Area2D.velocity, node)
        }

    /// RectShape2D ノードを構築する
    def buildRectShape2D(path: Path, name: String,
                         map: Map[String, Json.JsonElement]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            size <- parseVec2(path, "size", map)
        ) yield RectShape2D.init({name = name, size = size})

    /// Node2D ノードを構築する（子ノードを持つ汎用コンテナ）
    def buildNode2D(path: Path, name: String, map: Map[String, Json.JsonElement],
                    templates: Map[String, SceneTree.Node]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            pos      <- parseVec2(path, "pos", map);
            children <- parseChildren(path, map, templates)
        ) yield SceneTree.node2D(name, pos, children)

    /// Sprite2D ノードを構築する（visible はオプション、デフォルト true）
    def buildSprite2D(path: Path, name: String,
                      map: Map[String, Json.JsonElement]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            pos        <- parseVec2(path, "pos", map);
            size       <- parseVec2(path, "size", map);
            texture    <- Json.getAtKey(path, "texture", map);
            visibleOpt <- (Json.getAtKeyOpt(path, "visible", map): Result[Json.JsonError, Option[Bool]])
        ) yield {
            let node = Sprite2D.init({name = name, pos = pos, size = size, texture = texture});
            match visibleOpt {
                case Some(v) => node |> Sprite2D.visible(v)
                case None    => node
            }
        }

    /// Label2D ノードを構築する
    def buildLabel2D(path: Path, name: String,
                     map: Map[String, Json.JsonElement]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            pos         <- parseVec2(path, "pos", map);
            text        <- Json.getAtKey(path, "text", map);
            fontSize    <- (Json.getAtKey(path, "fontSize", map): Result[Json.JsonError, Float32]);
            font        <- Json.getAtKey(path, "font", map);
            visibleOpt  <- (Json.getAtKeyOpt(path, "visible", map): Result[Json.JsonError, Option[Bool]]);
            centeredOpt <- (Json.getAtKeyOpt(path, "centered", map): Result[Json.JsonError, Option[Bool]]);
            colorOpt    <- parseColorOpt(path, "color", map)
        ) yield {
            let node = Label2D.init({name = name, pos = pos, text = text, fontSize = fontSize, font = font});
            node
                |> optApply(visibleOpt, Label2D.visible)
                |> optApply(centeredOpt, Label2D.centered)
                |> match colorOpt {
                    case Some(c) => Label2D.color(c)
                    case None    => identity
                }
        }

    /// CanvasLayer2D ノードを構築する
    def buildCanvasLayer2D(path: Path, name: String, map: Map[String, Json.JsonElement],
                           templates: Map[String, SceneTree.Node]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            children <- parseChildren(path, map, templates)
        ) yield CanvasLayer2D.init({name = name, children = children})
}
