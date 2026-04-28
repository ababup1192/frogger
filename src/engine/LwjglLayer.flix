// LWJGL rendering backend — handles Engine.Game effect with OpenGL

mod LwjglLayer {
    import org.lwjgl.glfw.GLFW
    import org.lwjgl.glfw.Callbacks
    import org.lwjgl.glfw.GLFWKeyCallbackI
    import org.lwjgl.opengl.GL
    import org.lwjgl.opengl.GL11
    import org.lwjgl.opengl.GL13
    import org.lwjgl.opengl.GL15
    import org.lwjgl.opengl.GL20
    import org.lwjgl.opengl.GL30
    import org.lwjgl.stb.STBImage
    import org.lwjgl.stb.STBTruetype
    import org.lwjgl.stb.STBTTFontinfo
    import org.lwjgl.system.MemoryStack
    import org.lwjgl.system.MemoryUtil
    import java.lang.System
    import java.io.FileInputStream
    import java.nio.ByteBuffer
    import java.nio.FloatBuffer
    import java.nio.ByteOrder
    import java.nio.file.Files
    import java.nio.file.Paths
    import org.lwjgl.openal.AL
    import org.lwjgl.openal.AL10
    import org.lwjgl.openal.ALC
    import org.lwjgl.openal.ALC10
    import org.lwjgl.stb.STBVorbis

    type alias GlyphEntry = TextLayout.GlyphMetrics

    // ============================================================================
    // Shader Sources (LearnOpenGL sprite shader)
    // ============================================================================

    def vertexShaderSource(): String =
        "#version 330 core\n" +
        "layout (location = 0) in vec4 vertex;\n" +
        "out vec2 TexCoords;\n" +
        "uniform mat4 model;\n" +
        "uniform mat4 projection;\n" +
        "uniform vec2 uvOffset;\n" +
        "uniform vec2 uvScale;\n" +
        "void main() {\n" +
        "    TexCoords = vertex.zw * uvScale + uvOffset;\n" +
        "    gl_Position = projection * model * vec4(vertex.xy, 0.0, 1.0);\n" +
        "}\n"

    def fragmentShaderSource(): String =
        "#version 330 core\n" +
        "in vec2 TexCoords;\n" +
        "out vec4 color;\n" +
        "uniform sampler2D image;\n" +
        "uniform vec3 spriteColor;\n" +
        "void main() {\n" +
        "    color = vec4(spriteColor, 1.0) * texture(image, TexCoords);\n" +
        "}\n"

    def textBatchVertexShaderSource(): String =
        "#version 330 core\n" +
        "layout (location = 0) in vec2 aPos;\n" +
        "layout (location = 1) in vec2 aTexCoord;\n" +
        "layout (location = 2) in vec3 aColor;\n" +
        "out vec2 TexCoords;\n" +
        "out vec3 vertColor;\n" +
        "uniform mat4 projection;\n" +
        "void main() {\n" +
        "    TexCoords = aTexCoord;\n" +
        "    vertColor = aColor;\n" +
        "    gl_Position = projection * vec4(aPos, 0.0, 1.0);\n" +
        "}\n"

    def textBatchFragmentShaderSource(): String =
        "#version 330 core\n" +
        "in vec2 TexCoords;\n" +
        "in vec3 vertColor;\n" +
        "out vec4 color;\n" +
        "uniform sampler2D image;\n" +
        "void main() {\n" +
        "    float alpha = texture(image, TexCoords).r;\n" +
        "    color = vec4(vertColor, alpha);\n" +
        "}\n"

    // ============================================================================
    // Key Mapping (Engine.Key → GLFW key code)
    // ============================================================================

    def keyToGlfw(key: Engine.Key): Int32 = match key {
        case Engine.Key.A          => 65
        case Engine.Key.B          => 66
        case Engine.Key.C          => 67
        case Engine.Key.D          => 68
        case Engine.Key.E          => 69
        case Engine.Key.F          => 70
        case Engine.Key.G          => 71
        case Engine.Key.H          => 72
        case Engine.Key.I          => 73
        case Engine.Key.J          => 74
        case Engine.Key.K          => 75
        case Engine.Key.L          => 76
        case Engine.Key.M          => 77
        case Engine.Key.N          => 78
        case Engine.Key.O          => 79
        case Engine.Key.P          => 80
        case Engine.Key.Q          => 81
        case Engine.Key.R          => 82
        case Engine.Key.S          => 83
        case Engine.Key.T          => 84
        case Engine.Key.U          => 85
        case Engine.Key.V          => 86
        case Engine.Key.W          => 87
        case Engine.Key.X          => 88
        case Engine.Key.Y          => 89
        case Engine.Key.Z          => 90
        case Engine.Key.Num0       => 48
        case Engine.Key.Num1       => 49
        case Engine.Key.Num2       => 50
        case Engine.Key.Num3       => 51
        case Engine.Key.Num4       => 52
        case Engine.Key.Num5       => 53
        case Engine.Key.Num6       => 54
        case Engine.Key.Num7       => 55
        case Engine.Key.Num8       => 56
        case Engine.Key.Num9       => 57
        case Engine.Key.F1         => 290
        case Engine.Key.F2         => 291
        case Engine.Key.F3         => 292
        case Engine.Key.F4         => 293
        case Engine.Key.F5         => 294
        case Engine.Key.F6         => 295
        case Engine.Key.F7         => 296
        case Engine.Key.F8         => 297
        case Engine.Key.F9         => 298
        case Engine.Key.F10        => 299
        case Engine.Key.F11        => 300
        case Engine.Key.F12        => 301
        case Engine.Key.Up         => 265
        case Engine.Key.Down       => 264
        case Engine.Key.Left       => 263
        case Engine.Key.Right      => 262
        case Engine.Key.LeftShift  => 340
        case Engine.Key.RightShift => 344
        case Engine.Key.LeftCtrl   => 341
        case Engine.Key.RightCtrl  => 345
        case Engine.Key.LeftAlt    => 342
        case Engine.Key.RightAlt   => 346
        case Engine.Key.Space      => 32
        case Engine.Key.Enter      => 257
        case Engine.Key.Escape     => 256
        case Engine.Key.Tab        => 258
        case Engine.Key.Backspace  => 259
        case Engine.Key.Delete     => 261
        case Engine.Key.Insert     => 260
        case Engine.Key.Home       => 268
        case Engine.Key.End        => 269
        case Engine.Key.PageUp     => 266
        case Engine.Key.PageDown   => 267
    }

    // ============================================================================
    // Shader Compilation
    // ============================================================================

    def compileShader(source: String, shaderType: Int32): Int32 \ IO =
        let shader = GL20.glCreateShader(shaderType);
        GL20.glShaderSource(shader, source);
        GL20.glCompileShader(shader);

        let success = GL20.glGetShaderi(shader, GL20.GL_COMPILE_STATUS);
        if (success == GL11.GL_FALSE) {
            let log = GL20.glGetShaderInfoLog(shader, 1024);
            println("Shader compilation error: ${log}");
            bug!("Shader failed")
        } else ();

        shader

    def createShaderProgram(vertexSrc: String, fragmentSrc: String): Int32 \ IO =
        let vs = compileShader(vertexSrc, GL20.GL_VERTEX_SHADER);
        let fs = compileShader(fragmentSrc, GL20.GL_FRAGMENT_SHADER);

        let program = GL20.glCreateProgram();
        GL20.glAttachShader(program, vs);
        GL20.glAttachShader(program, fs);
        GL20.glLinkProgram(program);

        let success = GL20.glGetProgrami(program, GL20.GL_LINK_STATUS);
        if (success == GL11.GL_FALSE) {
            let log = GL20.glGetProgramInfoLog(program, 1024);
            println("Shader linking error: ${log}");
            bug!("Linking failed")
        } else ();

        GL20.glDeleteShader(vs);
        GL20.glDeleteShader(fs);
        program

    // ============================================================================
    // Texture Loading
    // ============================================================================

    def loadTexture(path: String, alpha: Bool): Int32 \ IO =
        let stack = MemoryStack.stackPush();
        let w = stack.mallocInt(1);
        let h = stack.mallocInt(1);
        let c = stack.mallocInt(1);
        STBImage.stbi_set_flip_vertically_on_load(false);
        let channels = if (alpha) 4 else 3;
        let data = STBImage.stbi_load(path, w, h, c, channels);
        if (Object.isNull(data)) {
            discard MemoryStack.stackPop();
            bug!("Failed to load texture: ${path}")
        } else {
            let textureID = GL11.glGenTextures();
            GL11.glBindTexture(GL11.GL_TEXTURE_2D, textureID);
            let format = if (alpha) GL11.GL_RGBA else GL11.GL_RGB;
            GL11.glTexImage2D(GL11.GL_TEXTURE_2D, 0, format, w.get(0), h.get(0), 0, format, GL11.GL_UNSIGNED_BYTE, data);
            GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_WRAP_S, GL11.GL_REPEAT);
            GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_WRAP_T, GL11.GL_REPEAT);
            GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MIN_FILTER, GL11.GL_NEAREST);
            GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MAG_FILTER, GL11.GL_NEAREST);
            STBImage.stbi_image_free(data);
            discard MemoryStack.stackPop();
            textureID
        }

    /// Load all textures from manifest into a registry (Map-based, data-driven)
    def loadTextureRegistry(manifest: List[Engine.TextureEntry]): Engine.TextureRegistry \ IO =
        List.foldLeft((registry, entry) -> {
            let texId = loadTexture(entry#path, entry#hasAlpha);
            println("  ${entry#path} loaded");
            Map.insert(entry#name, texId, registry)
        }, Map.empty(), manifest)

    // ============================================================================
    // Sprite Renderer
    // ============================================================================

    def initSpriteRenderer(): (Int32, Int32) \ IO =
        let vao = GL30.glGenVertexArrays();
        let vbo = GL15.glGenBuffers();

        let vertices = Array#{
            0.0f32, 1.0f32, 0.0f32, 1.0f32,
            1.0f32, 0.0f32, 1.0f32, 0.0f32,
            0.0f32, 0.0f32, 0.0f32, 0.0f32,
            0.0f32, 1.0f32, 0.0f32, 1.0f32,
            1.0f32, 1.0f32, 1.0f32, 1.0f32,
            1.0f32, 0.0f32, 1.0f32, 0.0f32
        } @ Static;

        GL30.glBindVertexArray(vao);
        GL15.glBindBuffer(GL15.GL_ARRAY_BUFFER, vbo);
        GL15.glBufferData(GL15.GL_ARRAY_BUFFER, vertices, GL15.GL_STATIC_DRAW);

        GL20.glEnableVertexAttribArray(0);
        GL20.glVertexAttribPointer(0, 4, GL11.GL_FLOAT, false, 16, 0i64);

        GL15.glBindBuffer(GL15.GL_ARRAY_BUFFER, 0);
        GL30.glBindVertexArray(0);

        (vao, vbo)

    def initTextBatchRenderer(): (Int32, Int32) \ IO =
        let tvao = GL30.glGenVertexArrays();
        let tvbo = GL15.glGenBuffers();
        GL30.glBindVertexArray(tvao);
        GL15.glBindBuffer(GL15.GL_ARRAY_BUFFER, tvbo);
        // Vertex format: vec2 pos, vec2 uv, vec3 color = 7 floats = 28 bytes
        GL20.glEnableVertexAttribArray(0);
        GL20.glVertexAttribPointer(0, 2, GL11.GL_FLOAT, false, 28, 0i64);
        GL20.glEnableVertexAttribArray(1);
        GL20.glVertexAttribPointer(1, 2, GL11.GL_FLOAT, false, 28, 8i64);
        GL20.glEnableVertexAttribArray(2);
        GL20.glVertexAttribPointer(2, 3, GL11.GL_FLOAT, false, 28, 16i64);
        GL15.glBindBuffer(GL15.GL_ARRAY_BUFFER, 0);
        GL30.glBindVertexArray(0);
        (tvao, tvbo)

    def putTextQuad(buf: FloatBuffer, x0: Float32, y0: Float32, x1: Float32, y1: Float32,
                    s0: Float32, t0: Float32, s1: Float32, t1: Float32,
                    cr: Float32, cg: Float32, cb: Float32): Unit \ IO =
        // Triangle 1: top-left, bottom-right, bottom-left
        discard buf.put(x0); discard buf.put(y0);
        discard buf.put(s0); discard buf.put(t0);
        discard buf.put(cr); discard buf.put(cg); discard buf.put(cb);
        discard buf.put(x1); discard buf.put(y1);
        discard buf.put(s1); discard buf.put(t1);
        discard buf.put(cr); discard buf.put(cg); discard buf.put(cb);
        discard buf.put(x0); discard buf.put(y1);
        discard buf.put(s0); discard buf.put(t1);
        discard buf.put(cr); discard buf.put(cg); discard buf.put(cb);
        // Triangle 2: top-left, top-right, bottom-right
        discard buf.put(x0); discard buf.put(y0);
        discard buf.put(s0); discard buf.put(t0);
        discard buf.put(cr); discard buf.put(cg); discard buf.put(cb);
        discard buf.put(x1); discard buf.put(y0);
        discard buf.put(s1); discard buf.put(t0);
        discard buf.put(cr); discard buf.put(cg); discard buf.put(cb);
        discard buf.put(x1); discard buf.put(y1);
        discard buf.put(s1); discard buf.put(t1);
        discard buf.put(cr); discard buf.put(cg); discard buf.put(cb)

    def setProjectionMatrix(shader: Int32, width: Float32, height: Float32): Unit \ IO =
        GL20.glUseProgram(shader);

        let left = 0.0f32;
        let right = width;
        let bottom = height;
        let top = 0.0f32;

        let proj = Array#{
            2.0f32 / (right - left), 0.0f32, 0.0f32, 0.0f32,
            0.0f32, 2.0f32 / (top - bottom), 0.0f32, 0.0f32,
            0.0f32, 0.0f32, -1.0f32, 0.0f32,
            -1.0f32 * (right + left) / (right - left), -1.0f32 * (top + bottom) / (top - bottom), 0.0f32, 1.0f32
        } @ Static;

        let loc = GL20.glGetUniformLocation(shader, "projection");
        GL20.glUniformMatrix4fv(loc, false, proj)

    def setCameraProjection(shader: Int32, viewCenter: Vec2D.Vec2, zoom: Vec2D.Vec2, width: Float32, height: Float32): Unit \ IO =
        GL20.glUseProgram(shader);
        let halfW = width / (2.0f32 * zoom#x);
        let halfH = height / (2.0f32 * zoom#y);
        let left = viewCenter#x - halfW;
        let right = viewCenter#x + halfW;
        let top = viewCenter#y - halfH;
        let bottom = viewCenter#y + halfH;
        let proj = Array#{
            2.0f32 / (right - left), 0.0f32, 0.0f32, 0.0f32,
            0.0f32, 2.0f32 / (top - bottom), 0.0f32, 0.0f32,
            0.0f32, 0.0f32, -1.0f32, 0.0f32,
            -1.0f32 * (right + left) / (right - left), -1.0f32 * (top + bottom) / (top - bottom), 0.0f32, 1.0f32
        } @ Static;
        let loc = GL20.glGetUniformLocation(shader, "projection");
        GL20.glUniformMatrix4fv(loc, false, proj)

    def drawSprite(shader: Int32, texture: Int32, vao: Int32, pos: Vec2D.Vec2, size: Vec2D.Vec2, color: Engine.Color, uvOff: Vec2D.Vec2, uvSc: Vec2D.Vec2, rot: Float32): Unit \ IO =
        GL20.glUseProgram(shader);

        let c = Vec2D.cos32(rot);
        let s = Vec2D.sin32(rot);
        let sx = size#x;
        let sy = size#y;
        let tx = pos#x + sx / 2.0f32 - c * sx / 2.0f32 + s * sy / 2.0f32;
        let ty = pos#y + sy / 2.0f32 - s * sx / 2.0f32 - c * sy / 2.0f32;
        let model = Array#{
            c * sx, s * sx, 0.0f32, 0.0f32,
            -1.0f32 * s * sy, c * sy, 0.0f32, 0.0f32,
            0.0f32, 0.0f32, 1.0f32, 0.0f32,
            tx, ty, 0.0f32, 1.0f32
        } @ Static;

        let modelLoc = GL20.glGetUniformLocation(shader, "model");
        GL20.glUniformMatrix4fv(modelLoc, false, model);

        let colorLoc = GL20.glGetUniformLocation(shader, "spriteColor");
        GL20.glUniform3f(colorLoc, color#r, color#g, color#b);

        let uvOffsetLoc = GL20.glGetUniformLocation(shader, "uvOffset");
        GL20.glUniform2f(uvOffsetLoc, uvOff#x, uvOff#y);
        let uvScaleLoc = GL20.glGetUniformLocation(shader, "uvScale");
        GL20.glUniform2f(uvScaleLoc, uvSc#x, uvSc#y);

        GL13.glActiveTexture(GL13.GL_TEXTURE0);
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture);

        GL30.glBindVertexArray(vao);
        GL11.glDrawArrays(GL11.GL_TRIANGLES, 0, 6);
        GL30.glBindVertexArray(0)

    // ============================================================================
    // Rendering (SceneTree-based, generic — no changes needed for new entities)
    // ============================================================================

    def renderScene(scene: SceneTree.Node, registry: Engine.TextureRegistry, shader: Int32, vao: Int32,
                    screenW: Float32, screenH: Float32, clearColor: Engine.Color,
                    renderText: SceneTree.Node -> Unit \ IO): Unit \ IO =
        GL11.glClearColor(clearColor#r, clearColor#g, clearColor#b, 1.0f32);
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT);

        match SceneTree.findCurrentCamera(scene) {
            case Some((cd, _camGlobalPos)) =>
                let viewCenter = Vec2D.add(cd#smoothedPos, cd#offset);
                setCameraProjection(shader, viewCenter, cd#zoom, screenW, screenH)
            case None =>
                setProjectionMatrix(shader, screenW, screenH)
        };

        let drawables = SceneTree.collectDrawables(scene, Vec2D.zero());
        List.forEach(match (spriteData, globalPos, rot) -> {
            match Map.get(spriteData#texture, registry) {
                case Some(texId) => drawSprite(shader, texId, vao, globalPos, spriteData#size, spriteData#color, spriteData#uvOffset, spriteData#uvScale, rot)
                case None => ()
            }
        }, drawables);

        renderText(scene)

    // ============================================================================
    // Audio Loading
    // ============================================================================

    def loadOggToALBuffer(path: String): Int32 \ IO =
        let stack = MemoryStack.stackPush();
        let channelsBuf = stack.mallocInt(1);
        let sampleRateBuf = stack.mallocInt(1);
        let pcm = STBVorbis.stb_vorbis_decode_filename(path, channelsBuf, sampleRateBuf);
        if (Object.isNull(pcm)) {
            discard MemoryStack.stackPop();
            bug!("Failed to decode OGG: ${path}")
        } else {
            let channels = channelsBuf.get(0);
            let sampleRate = sampleRateBuf.get(0);
            discard MemoryStack.stackPop();
            let format = if (channels == 1) AL10.AL_FORMAT_MONO16 else AL10.AL_FORMAT_STEREO16;
            let buffer = AL10.alGenBuffers();
            AL10.alBufferData(buffer, format, pcm, sampleRate);
            MemoryUtil.memFree(pcm);
            buffer
        }

    def loadWavToALBuffer(path: String): Int32 \ IO =
        let wavBytes = Files.readAllBytes(Paths.get(path));
        let hdr = ByteBuffer.wrap(wavBytes);
        discard hdr.order(ByteOrder.LITTLE_ENDIAN);
        let channels = Int16.toInt32(hdr.getShort(22));
        let sampleRate = hdr.getInt(24);
        let bitsPerSample = Int16.toInt32(hdr.getShort(34));
        let dataOffset = match AudioUtil.findDataChunkOffset(i -> hdr.get(i), i -> hdr.getInt(i), hdr.limit(), 12) {
            case Some(off) => off
            case None      => bug!("WAV data chunk not found: ${path}")
        };
        let dataSize = hdr.getInt(dataOffset + 4);
        let pcmStart = dataOffset + 8;
        let pcmBuf = MemoryUtil.memAlloc(dataSize);
        discard pcmBuf.put(wavBytes, pcmStart, dataSize);
        discard pcmBuf.flip();
        let format = AudioUtil.alFormat(channels, bitsPerSample);
        let buffer = AL10.alGenBuffers();
        AL10.alBufferData(buffer, format, pcmBuf, sampleRate);
        MemoryUtil.memFree(pcmBuf);
        buffer


    /// Load all audio from manifest into a registry (name → AL source ID)
    def loadAudioRegistry(manifest: List[Engine.AudioEntry]): Engine.AudioRegistry \ IO =
        List.foldLeft((reg, entry) -> {
            let buffer = if (String.endsWith({suffix = ".ogg"}, entry#path))
                loadOggToALBuffer(entry#path)
            else
                loadWavToALBuffer(entry#path);
            let source = AL10.alGenSources();
            AL10.alSourcei(source, AL10.AL_BUFFER, buffer);
            AL10.alSourcei(source, AL10.AL_LOOPING, if (entry#looping) AL10.AL_TRUE else AL10.AL_FALSE);
            println("  ${entry#path} loaded");
            Map.insert(entry#name, source, reg)
        }, Map.empty(), manifest)

    // ============================================================================
    // LWJGL Handler for Engine.Game effect
    // ============================================================================

    pub def withLwjgl(config: Engine.EngineConfig, f: Unit -> a \ ef): a \ ef - Engine.Game - Engine.Mouse - Engine.Audio + IO =
        if (not GLFW.glfwInit()) {
            println("GLFW init failed");
            bug!("GLFW failed")
        } else ();

        // OpenGL 3.3 Core (LearnOpenGL standard)
        GLFW.glfwWindowHint(GLFW.GLFW_CONTEXT_VERSION_MAJOR, 3);
        GLFW.glfwWindowHint(GLFW.GLFW_CONTEXT_VERSION_MINOR, 3);
        GLFW.glfwWindowHint(GLFW.GLFW_OPENGL_PROFILE, GLFW.GLFW_OPENGL_CORE_PROFILE);
        GLFW.glfwWindowHint(GLFW.GLFW_OPENGL_FORWARD_COMPAT, GL11.GL_TRUE);
        GLFW.glfwWindowHint(GLFW.GLFW_RESIZABLE, GL11.GL_FALSE);

        let window = GLFW.glfwCreateWindow(config#screenWidth, config#screenHeight, config#title, MemoryUtil.NULL, MemoryUtil.NULL);
        GLFW.glfwMakeContextCurrent(window);
        GLFW.glfwSwapInterval(1);
        discard GL.createCapabilities();

        // Retina display support — query actual framebuffer size from GLFW
        let fbStack = MemoryStack.stackPush();
        let fbWidthBuf = fbStack.mallocInt(1);
        let fbHeightBuf = fbStack.mallocInt(1);
        GLFW.glfwGetFramebufferSize(window, fbWidthBuf, fbHeightBuf);
        let fbWidth = fbWidthBuf.get(0);
        let fbHeight = fbHeightBuf.get(0);
        discard MemoryStack.stackPop();
        println("Framebuffer size: ${fbWidth}x${fbHeight}");

        GL11.glViewport(0, 0, fbWidth, fbHeight);
        GL11.glEnable(GL11.GL_BLEND);
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE_MINUS_SRC_ALPHA);

        let screenW = Int32.toFloat32(config#screenWidth);
        let screenH = Int32.toFloat32(config#screenHeight);

        let shader = createShaderProgram(vertexShaderSource(), fragmentShaderSource());
        setProjectionMatrix(shader, screenW, screenH);

        let textBatchShader = createShaderProgram(textBatchVertexShaderSource(), textBatchFragmentShaderSource());
        let (textVao, textVbo) = initTextBatchRenderer();

        let (vao, _vbo) = initSpriteRenderer();

        println("Loading textures...");
        let registry = loadTextureRegistry(config#textureManifest);

        // Font initialization — dynamic glyph atlas
        println("Loading fonts...");
        let atlasW = 1024;
        let atlasH = 1024;
        let fontBakeSize = 48.0f32;

        let fontBytes = Files.readAllBytes(Paths.get(config#fontPath));
        let fontBuf = MemoryUtil.memAlloc(Array.length(fontBytes));
        discard fontBuf.put(fontBytes);
        discard fontBuf.flip();

        let fontInfo = STBTTFontinfo.create();
        if (not STBTruetype.stbtt_InitFont(fontInfo, fontBuf)) {
            bug!("Failed to init font")
        } else ();
        let fontScale = STBTruetype.stbtt_ScaleForPixelHeight(fontInfo, fontBakeSize);

        // Create empty atlas texture
        GL11.glPixelStorei(GL11.GL_UNPACK_ALIGNMENT, 1);
        let emptyAtlasBuf = MemoryUtil.memCalloc(atlasW * atlasH);
        let fontTexId = GL11.glGenTextures();
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, fontTexId);
        GL11.glTexImage2D(GL11.GL_TEXTURE_2D, 0, GL11.GL_RED, atlasW, atlasH, 0, GL11.GL_RED, GL11.GL_UNSIGNED_BYTE, emptyAtlasBuf);
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MIN_FILTER, GL11.GL_LINEAR);
        GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MAG_FILTER, GL11.GL_LINEAR);
        MemoryUtil.memFree(emptyAtlasBuf);

        // Write a 2x2 white pixel block for solid rectangle rendering (button backgrounds)
        let solidPixelBuf = MemoryUtil.memAlloc(4);
        discard solidPixelBuf.put(0, -1i8);
        discard solidPixelBuf.put(1, -1i8);
        discard solidPixelBuf.put(2, -1i8);
        discard solidPixelBuf.put(3, -1i8);
        GL11.glTexSubImage2D(GL11.GL_TEXTURE_2D, 0, atlasW - 2, atlasH - 2, 2, 2, GL11.GL_RED, GL11.GL_UNSIGNED_BYTE, solidPixelBuf);
        MemoryUtil.memFree(solidPixelBuf);
        let solidU = Int32.toFloat32(atlasW - 1) / Int32.toFloat32(atlasW);
        let solidV = Int32.toFloat32(atlasH - 1) / Int32.toFloat32(atlasH);

        // Glyph cache + atlas cursor (mutable state)
        let emptyGlyphMap: Map[Int32, GlyphEntry] = Map.empty();
        let glyphCacheRef = Array#{emptyGlyphMap} @ Static;
        let atlasCursor = Array#{0, 0, 0} @ Static;
        let glyphTmpBuf = MemoryUtil.memAlloc(256 * 256);

        // Glyph lookup/cache: renders glyph on first use, caches in atlas
        let getGlyph = (cp: Int32) -> {
            let cache = Array.get(0, glyphCacheRef);
            match Map.get(cp, cache) {
                case Some(entry) => entry
                case None =>
                    let metStack = MemoryStack.stackPush();
                    let bx0 = metStack.mallocInt(1);
                    let by0 = metStack.mallocInt(1);
                    let bx1 = metStack.mallocInt(1);
                    let by1 = metStack.mallocInt(1);
                    STBTruetype.stbtt_GetCodepointBitmapBox(fontInfo, cp, fontScale, fontScale, bx0, by0, bx1, by1);
                    let gwi = bx1.get(0) - bx0.get(0);
                    let ghi = by1.get(0) - by0.get(0);
                    let xOff = Int32.toFloat32(bx0.get(0));
                    let yOff = Int32.toFloat32(by0.get(0));
                    let advBuf = metStack.mallocInt(1);
                    let lsbBuf = metStack.mallocInt(1);
                    STBTruetype.stbtt_GetCodepointHMetrics(fontInfo, cp, advBuf, lsbBuf);
                    let adv = Int32.toFloat32(advBuf.get(0)) * fontScale;
                    discard MemoryStack.stackPop();
                    if (gwi > 0 and ghi > 0) {
                        let cx = Array.get(0, atlasCursor);
                        let cy = Array.get(1, atlasCursor);
                        let rowH = Array.get(2, atlasCursor);
                        let (px, py, rh) = if (cx + gwi > atlasW) (0, cy + rowH + 1, 0) else (cx, cy, rowH);
                        discard glyphTmpBuf.clear();
                        STBTruetype.stbtt_MakeCodepointBitmap(fontInfo, glyphTmpBuf, gwi, ghi, gwi, fontScale, fontScale, cp);
                        GL11.glTexSubImage2D(GL11.GL_TEXTURE_2D, 0, px, py, gwi, ghi, GL11.GL_RED, GL11.GL_UNSIGNED_BYTE, glyphTmpBuf);
                        let s0 = Int32.toFloat32(px) / Int32.toFloat32(atlasW);
                        let t0 = Int32.toFloat32(py) / Int32.toFloat32(atlasH);
                        let s1 = Int32.toFloat32(px + gwi) / Int32.toFloat32(atlasW);
                        let t1 = Int32.toFloat32(py + ghi) / Int32.toFloat32(atlasH);
                        let entry: GlyphEntry = {
                            s0 = s0, t0 = t0, s1 = s1, t1 = t1,
                            xOff = xOff, yOff = yOff,
                            glyphW = Int32.toFloat32(gwi), glyphH = Int32.toFloat32(ghi),
                            advance = adv
                        };
                        Array.put(px + gwi + 1, 0, atlasCursor);
                        Array.put(py, 1, atlasCursor);
                        Array.put(Int32.max(rh, ghi), 2, atlasCursor);
                        Array.put(Map.insert(cp, entry, cache), 0, glyphCacheRef);
                        entry
                    } else {
                        let entry: GlyphEntry = {
                            s0 = 0.0f32, t0 = 0.0f32, s1 = 0.0f32, t1 = 0.0f32,
                            xOff = 0.0f32, yOff = 0.0f32, glyphW = 0.0f32, glyphH = 0.0f32,
                            advance = adv
                        };
                        Array.put(Map.insert(cp, entry, cache), 0, glyphCacheRef);
                        entry
                    }
            }
        };
        println("  ${config#fontPath} loaded (dynamic atlas ${atlasW}x${atlasH})");

        // ===== OpenAL audio init =====
        println("Initializing audio...");
        let alDevice = ALC10.nalcOpenDevice(MemoryUtil.NULL);
        if (alDevice == 0i64) {
            println("Failed to open OpenAL device");
            bug!("Failed to open OpenAL device")
        } else ();
        let alcCaps = ALC.createCapabilities(alDevice);
        let alContext = ALC10.nalcCreateContext(alDevice, MemoryUtil.NULL);
        if (alContext == 0i64) {
            println("Failed to create OpenAL context");
            bug!("Failed to create OpenAL context")
        } else ();
        if (not ALC10.alcMakeContextCurrent(alContext)) {
            println("Failed to make OpenAL context current");
            bug!("Failed to make OpenAL context current")
        } else ();
        discard AL.createCapabilities(alcCaps);

        println("  Loading sounds...");
        let audioRegistry = loadAudioRegistry(config#audioManifest);
        println("  Audio ready");

        // Text drawing closure — batched rendering with dynamic glyph atlas
        let maxTextChars = 16384;
        let textVertBuf = MemoryUtil.memAllocFloat(maxTextChars * 42);
        let drawTextOnScreen = (scene: SceneTree.Node) -> {
            setProjectionMatrix(textBatchShader, screenW, screenH);
            let textDrawables = SceneTree.collectTextDrawables(scene, Vec2D.zero());
            // Bind atlas texture (needed for both caching new glyphs and drawing)
            GL13.glActiveTexture(GL13.GL_TEXTURE0);
            GL11.glBindTexture(GL11.GL_TEXTURE_2D, fontTexId);
            discard textVertBuf.clear();
            List.forEach(td -> {
                let scale = td#fontSize / fontBakeSize;
                let chars = String.toList(td#text);
                let lineH = fontBakeSize * TextLayout.lineHeightMultiplier();
                // Phase 1: collect glyph data (caches new glyphs as side effect)
                let glyphData = List.map(ch -> {
                    let g = getGlyph(TextLayout.charToCodePoint(ch));
                    (g#advance, g)
                }, chars);
                let advances = List.map(p -> fst(p), glyphData);
                // Phase 2: compute layout positions (pure)
                let positions = TextLayout.layoutPositions(advances, td#wrapWidth, scale, lineH);
                let offsetX = if (td#centered and td#wrapWidth <= 0.0f32)
                    TextLayout.centerOffset(TextLayout.totalAdvance(advances), scale)
                else 0.0f32;
                // Button background: emit a colored rectangle before text glyphs
                match (td#bgColor, td#bgPadding) {
                    case (Some(bgc), Some(bgp)) =>
                        if (textVertBuf.remaining() >= 42) {
                            let textWidth = TextLayout.totalAdvance(advances) * scale;
                            let padX = td#fontSize * bgp#x;
                            let padY = td#fontSize * bgp#y;
                            let bgX0 = td#position#x - textWidth / 2.0f32 - padX;
                            let bgY0 = td#position#y - td#fontSize * 0.75f32 - padY;
                            let bgX1 = td#position#x + textWidth / 2.0f32 + padX;
                            let bgY1 = td#position#y + td#fontSize * 0.2f32 + padY;
                            putTextQuad(textVertBuf, bgX0, bgY0, bgX1, bgY1,
                                solidU, solidV, solidU, solidV,
                                bgc#r, bgc#g, bgc#b)
                        } else ()
                    case _ => ()
                };
                // Phase 3: emit quads using layout positions
                List.forEach(match ((_, g), penPos) -> {
                    if (g#glyphW > 0.0f32 and textVertBuf.remaining() >= 42) {
                        let q = TextLayout.glyphQuadBounds(penPos, g, scale, td#position, offsetX);
                        putTextQuad(textVertBuf, q#x0, q#y0, q#x1, q#y1,
                            g#s0, g#t0, g#s1, g#t1,
                            td#color#r, td#color#g, td#color#b)
                    } else ()
                }, List.zip(glyphData, positions))
            }, textDrawables);
            let totalFloats = textVertBuf.position();
            if (totalFloats > 0) {
                discard textVertBuf.flip();
                GL20.glUseProgram(textBatchShader);
                GL30.glBindVertexArray(textVao);
                GL15.glBindBuffer(GL15.GL_ARRAY_BUFFER, textVbo);
                GL15.glBufferData(GL15.GL_ARRAY_BUFFER, textVertBuf, GL15.GL_DYNAMIC_DRAW);
                GL11.glDrawArrays(GL11.GL_TRIANGLES, 0, totalFloats / 7);
                GL30.glBindVertexArray(0)
            } else ()
        };

        let timeHolder = Array#{System.nanoTime()} @ Static;
        let mousePrevHolder = Array#{false} @ Static;
        // Store mouse position as Float32 — updated each frame in shouldClose
        let mousePosHolder = Array#{0.0f32, 0.0f32} @ Static;
        // Allocate DoubleBuffers once for glfwGetCursorPos
        let cursorXBuf = MemoryUtil.memAllocDouble(1);
        let cursorYBuf = MemoryUtil.memAllocDouble(1);

        let result = run {
            f()
        } with handler Engine.Mouse {
            def isMousePressed(k) = {
                let pressed = GLFW.glfwGetMouseButton(window, 0) == 1;
                let wasPrev = Array.get(0, mousePrevHolder);
                Array.put(pressed, 0, mousePrevHolder);
                k(pressed and not wasPrev)
            }
            def getMouseX(k) = {
                k(Array.get(0, mousePosHolder))
            }
            def getMouseY(k) = {
                k(Array.get(1, mousePosHolder))
            }
        } with handler Engine.Audio {
            def playAudio(name, k) = {
                match Map.get(name, audioRegistry) {
                    case Some(src) => AL10.alSourceStop(src); AL10.alSourcePlay(src)
                    case None      => ()
                };
                k(())
            }
            def stopAudio(name, k) = {
                match Map.get(name, audioRegistry) {
                    case Some(src) => AL10.alSourceStop(src)
                    case None      => ()
                };
                k(())
            }
        } with handler Engine.Game {
            def render(scene, k) = {
                renderScene(scene, registry, shader, vao, screenW, screenH, config#clearColor, drawTextOnScreen);
                GLFW.glfwSwapBuffers(window);
                k(())
            }
            def shouldClose(k) = {
                GLFW.glfwPollEvents();
                GLFW.nglfwGetCursorPos(window, MemoryUtil.memAddress(cursorXBuf), MemoryUtil.memAddress(cursorYBuf));
                Array.put(Float64.truncateToFloat32(cursorXBuf.get(0)), 0, mousePosHolder);
                Array.put(Float64.truncateToFloat32(cursorYBuf.get(0)), 1, mousePosHolder);
                discard cursorXBuf.rewind();
                discard cursorYBuf.rewind();
                k(GLFW.glfwWindowShouldClose(window))
            }
            def getDeltaTime(k) = {
                let currentTime = System.nanoTime();
                let prev = Array.get(0, timeHolder);
                Array.put(currentTime, 0, timeHolder);
                let dtNanos = currentTime - prev;
                let dtf = Int64.toFloat32(dtNanos) / 1000000000.0f32;
                k(dtf)
            }
            def isKeyPressed(key, k) = {
                let code = keyToGlfw(key);
                k(GLFW.glfwGetKey(window, code) == 1)
            }
        };

        // OpenAL cleanup
        Map.forEach((_, src) -> AL10.alDeleteSources(src), audioRegistry);
        ALC10.alcDestroyContext(alContext);
        discard ALC10.alcCloseDevice(alDevice);

        Callbacks.glfwFreeCallbacks(window);
        GLFW.glfwDestroyWindow(window);
        GLFW.glfwTerminate();

        result
}
