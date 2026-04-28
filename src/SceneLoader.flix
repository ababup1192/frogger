// SceneLoader — JSONファイルからシーンツリーを構築する

mod SceneLoader {
    use Json.JsonElement.{JsonObject, JsonArray}
    use Json.JsonError.JsonError
    use Json.Path.Path
    use Json.Path.Path.{Root, AtKey}

    /// JSONファイルを読み込み、SceneTree.Node に変換する。失敗時はクラッシュする
    pub def loadScene(path: String): SceneTree.Node \ Fs.FileRead =
        let content = run { Fs.ReadFile.read(path) } with Fs.ReadFile.runWithFileRead;
        let result = forM (
            text <- content |> Result.mapErr(e -> "failed to read: ${e}");
            json <- Json.Parse.parse(text) |> Option.toOk("JSON parse failed");
            node <- parseNode(Root, json)
                        |> Result.mapErr(match JsonError(errPath, expected) ->
                            "at ${errPath}: expected ${expected}")
        ) yield node;
        match result {
            case Ok(node) => node
            case Err(msg) => bug!("SceneLoader: ${path}: ${msg}")
        }

    // ========================================================================
    // JSON → Node 変換
    // ========================================================================

    /// JsonElement を再帰的に SceneTree.Node に変換する
    def parseNode(p: Path, json: Json.JsonElement): Result[Json.JsonError, SceneTree.Node] =
        match json {
            case JsonObject(map) =>
                forM (
                    nodeType <- Json.getAtKey(p, "type", map);
                    name <- Json.getAtKey(p, "name", map);
                    node <- buildByType(p, nodeType, name, map)
                ) yield node
            case _ => Err(JsonError(p, Set#{"JsonObject"}))
        }

    /// "type" フィールドに応じて対応するノードビルダーを呼び出す
    def buildByType(p: Path, nodeType: String, name: String,
                    map: Map[String, Json.JsonElement]): Result[Json.JsonError, SceneTree.Node] =
        match nodeType {
            case "CharacterBody2D"  => buildCharacterBody2D(p, name, map)
            case "AnimatedSprite2D" => buildAnimatedSprite2D(p, name, map)
            case "Area2D"           => buildArea2D(p, name, map)
            case "RectShape2D"      => buildRectShape2D(p, name, map)
            case "Node2D"           => buildNode2D(p, name, map)
            case "Sprite2D"         => buildSprite2D(p, name, map)
            case unknown            => Err(JsonError(p, Set#{"known node type (got: ${unknown})"}))
        }

    // ========================================================================
    // ヘルパー
    // ========================================================================

    /// JSON配列 [x, y] を Vec2D.Vec2 に変換する
    def parseVec2(p: Path, key: String,
                  map: Map[String, Json.JsonElement]): Result[Json.JsonError, Vec2D.Vec2] =
        forM (
            pair <- (Json.getAtKey(p, key, map): Result[Json.JsonError, (Float32, Float32)])
        ) yield {
            let (x, y) = pair;
            {x = x, y = y}
        }

    /// children 配列を再帰的にパースする。キーがなければ空リストを返す
    def parseChildren(p: Path,
                      map: Map[String, Json.JsonElement]): Result[Json.JsonError, List[SceneTree.Node]] =
        let childPath = Json.Path.atKey("children", p);
        match Map.get("children", map) {
            case None              => Ok(Nil)
            case Some(JsonArray(arr)) =>
                parseChildList(childPath, Vector.toList(arr), 0)
            case Some(_)           => Err(JsonError(childPath, Set#{"JsonArray"}))
        }

    /// JsonElement のリストを順にパースして SceneTree.Node のリストに変換する
    def parseChildList(p: Path, elems: List[Json.JsonElement],
                       idx: Int32): Result[Json.JsonError, List[SceneTree.Node]] =
        match elems {
            case Nil => Ok(Nil)
            case x :: xs =>
                forM (
                    node <- parseNode(Json.Path.atIndex(idx, p), x);
                    rest <- parseChildList(p, xs, idx + 1)
                ) yield node :: rest
        }

    /// アニメーション定義をパースする。{"name": ["frame1", ...]} → Map[String, AnimationEntry]
    def parseAnimations(p: Path,
                        map: Map[String, Json.JsonElement]): Result[Json.JsonError, Map[String, SceneTree.AnimationEntry]] =
        forM (
            raw <- (Json.getAtKey(p, "animations", map): Result[Json.JsonError, Map[String, List[String]]])
        ) yield {
            raw |> Map.map(frames -> ({frames = frames}: SceneTree.AnimationEntry))
        }

    // ========================================================================
    // ノードタイプ別ビルダー
    // ========================================================================

    /// CharacterBody2D ノードを構築する
    def buildCharacterBody2D(p: Path, name: String,
                             map: Map[String, Json.JsonElement]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            pos         <- parseVec2(p, "pos", map);
            speedOpt    <- (Json.getAtKeyOpt(p, "moveSpeed", map): Result[Json.JsonError, Option[Float32]]);
            children    <- parseChildren(p, map)
        ) yield {
            let node = CharacterBody2D.init({name = name, pos = pos, children = children});
            match speedOpt {
                case Some(s) => node |> CharacterBody2D.moveSpeed(s)
                case None    => node
            }
        }

    /// AnimatedSprite2D ノードを構築する
    def buildAnimatedSprite2D(p: Path, name: String,
                              map: Map[String, Json.JsonElement]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            pos              <- parseVec2(p, "pos", map);
            size             <- parseVec2(p, "size", map);
            animations       <- parseAnimations(p, map);
            initialAnimation <- Json.getAtKey(p, "initialAnimation", map);
            fpsOpt           <- (Json.getAtKeyOpt(p, "fps", map): Result[Json.JsonError, Option[Float32]])
        ) yield {
            let node = AnimatedSprite2D.init({name = name, pos = pos, size = size,
                                              animations = animations,
                                              initialAnimation = initialAnimation});
            match fpsOpt {
                case Some(f) => node |> AnimatedSprite2D.fps(f)
                case None    => node
            }
        }

    /// Area2D ノードを構築する
    def buildArea2D(p: Path, name: String,
                    map: Map[String, Json.JsonElement]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            pos      <- parseVec2(p, "pos", map);
            children <- parseChildren(p, map)
        ) yield Area2D.init({name = name, pos = pos, children = children})

    /// RectShape2D ノードを構築する
    def buildRectShape2D(p: Path, name: String,
                         map: Map[String, Json.JsonElement]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            size <- parseVec2(p, "size", map)
        ) yield RectShape2D.init({name = name, size = size})

    /// Node2D ノードを構築する（子ノードを持つ汎用コンテナ）
    def buildNode2D(p: Path, name: String,
                    map: Map[String, Json.JsonElement]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            pos      <- parseVec2(p, "pos", map);
            children <- parseChildren(p, map)
        ) yield SceneTree.node2D(name, pos, children)

    /// Sprite2D ノードを構築する（visible はオプション、デフォルト true）
    def buildSprite2D(p: Path, name: String,
                      map: Map[String, Json.JsonElement]): Result[Json.JsonError, SceneTree.Node] =
        forA (
            pos        <- parseVec2(p, "pos", map);
            size       <- parseVec2(p, "size", map);
            texture    <- Json.getAtKey(p, "texture", map);
            visibleOpt <- (Json.getAtKeyOpt(p, "visible", map): Result[Json.JsonError, Option[Bool]])
        ) yield {
            let node = Sprite2D.init({name = name, pos = pos, size = size, texture = texture});
            match visibleOpt {
                case Some(v) => node |> Sprite2D.visible(v)
                case None    => node
            }
        }
}
