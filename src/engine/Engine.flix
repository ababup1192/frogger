// Engine module — shared types and effects for the game engine layer

mod Engine {
    import java.lang.ProcessBuilder
    import java.lang.System
    import java.util.ArrayList

    pub type alias Color = {r = Float32, g = Float32, b = Float32}

    /// テクスチャの論理名 → バックエンドが割り当てたハンドル ID
    pub type alias TextureRegistry = Map[String, Int32]

    /// テクスチャアセットのマニフェストエントリ
    /// - name: TextureRegistry のキーとなる論理名 (例: "playerGrey_walk1")
    /// - path: プロジェクトルートからの相対パス (例: "textures/playerGrey_walk1.png")
    /// - hasAlpha: アルファチャンネルを持つか (true=RGBA, false=RGB)
    pub type alias TextureEntry = { name = String, path = String, hasAlpha = Bool }

    /// オーディオアセットのマニフェストエントリ
    /// - name: AudioRegistry のキーとなる論理名 (例: "music", "death")
    /// - path: プロジェクトルートからの相対パス (例: "sounds/gameover.wav")
    /// - looping: ループ再生するか (true=ループ, false=ワンショット)
    pub type alias AudioEntry = { name = String, path = String, looping = Bool }

    /// オーディオクリップの論理名 → バックエンドが割り当てたハンドル ID
    pub type alias AudioRegistry = Map[String, Int32]

    /// エンジン初期化に必要な設定
    pub type alias EngineConfig = {
        screenWidth = Int32,
        screenHeight = Int32,
        title = String,
        textureManifest = List[TextureEntry],
        audioManifest = List[AudioEntry],
        fontPath = String,
        clearColor = Color
    }

    pub enum Key with Eq, Order, ToString {
        // Letters
        case A
        case B
        case C
        case D
        case E
        case F
        case G
        case H
        case I
        case J
        case K
        case L
        case M
        case N
        case O
        case P
        case Q
        case R
        case S
        case T
        case U
        case V
        case W
        case X
        case Y
        case Z
        // Numbers
        case Num0
        case Num1
        case Num2
        case Num3
        case Num4
        case Num5
        case Num6
        case Num7
        case Num8
        case Num9
        // Function keys
        case F1
        case F2
        case F3
        case F4
        case F5
        case F6
        case F7
        case F8
        case F9
        case F10
        case F11
        case F12
        // Arrow keys
        case Up
        case Down
        case Left
        case Right
        // Modifiers
        case LeftShift
        case RightShift
        case LeftCtrl
        case RightCtrl
        case LeftAlt
        case RightAlt
        // Special keys
        case Space
        case Enter
        case Escape
        case Tab
        case Backspace
        case Delete
        case Insert
        case Home
        case End
        case PageUp
        case PageDown

        case Minus
        case Equal
        case Comma
        case Period
    }

    pub eff Game {
        def render(scene: SceneTree.Node): Unit
        def shouldClose(): Bool
        def getDeltaTime(): Float32
        def isKeyPressed(key: Key): Bool
    }

    pub eff Mouse {
        def isMousePressed(): Bool
        def getMouseX(): Float32
        def getMouseY(): Float32
    }

    pub eff Audio {
        def playAudio(name: String): Unit
        def stopAudio(name: String): Unit
    }

    /// macOS では -XstartOnFirstThread 付きでプロセスを再起動する。
    /// 再起動した場合 true を返す（呼び出し元は終了すべき）。
    pub def ensureMainThread(): Bool \ IO =
        let osName = System.getProperty("os.name");
        if (Object.isNull(osName) or not String.contains({substr = "Mac"}, osName))
            false
        else if (not Object.isNull(System.getProperty("game.relaunched")))
            false
        else {
            println("Relaunching with -XstartOnFirstThread...");
            let javaHome = System.getProperty("java.home");
            let javaBin = "${javaHome}/bin/java";
            let args = new ArrayList();
            discard args.add(javaBin);
            discard args.add("-XstartOnFirstThread");
            discard args.add("-Dgame.relaunched=true");
            discard args.add("-jar");
            discard args.add("bin/flix.jar");
            discard args.add("run");
            let pb = new ProcessBuilder(args);
            discard pb.inheritIO();
            let proc = pb.start();
            let code = proc.waitFor();
            System.exit(code);
            true
        }
}
