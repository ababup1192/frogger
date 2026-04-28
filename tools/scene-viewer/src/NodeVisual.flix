// NodeVisual — NodeKind ごとの表示色とサイズを定義する

mod NodeVisual {
    /// ノードの表示情報（色とサイズ）
    pub type alias Visual = {
        /// 矩形の色
        color = Engine.Color,
        /// 矩形のサイズ
        size = Vec2D.Vec2
    }

    /// NodeKind に対応する表示色とデフォルトサイズを返す
    pub def visualForKind(kind: SceneTree.NodeKind): Visual =
        match kind {
            // Node2D (Plain) — グレー 16x16
            case SceneTree.NodeKind.Plain =>
                {color = {r = 0.6f32, g = 0.6f32, b = 0.6f32},
                 size = {x = 16.0f32, y = 16.0f32}}

            // Sprite2D — 緑、JSON の size を使用
            case SceneTree.NodeKind.Sprite(sd) =>
                {color = {r = 0.2f32, g = 0.8f32, b = 0.3f32},
                 size = sd#size}

            // AnimatedSprite2D — ライム、JSON の size を使用
            case SceneTree.NodeKind.AnimatedSprite(asd) =>
                {color = {r = 0.5f32, g = 1.0f32, b = 0.0f32},
                 size = asd#size}

            // CharacterBody2D — オレンジ 32x32
            case SceneTree.NodeKind.Character(_) =>
                {color = {r = 1.0f32, g = 0.6f32, b = 0.2f32},
                 size = {x = 32.0f32, y = 32.0f32}}

            // Area2D — シアン 32x32
            case SceneTree.NodeKind.Area(_) =>
                {color = {r = 0.0f32, g = 0.9f32, b = 0.9f32},
                 size = {x = 32.0f32, y = 32.0f32}}

            // RectShape2D — 赤、JSON の size を使用
            case SceneTree.NodeKind.Shape(SceneTree.CollisionShapeData.RectShape(shapeSize)) =>
                {color = {r = 1.0f32, g = 0.2f32, b = 0.2f32},
                 size = shapeSize}

            // CircleShape2D — 赤 (直径 x 直径)
            case SceneTree.NodeKind.Shape(SceneTree.CollisionShapeData.CircleShape(radius)) =>
                {color = {r = 1.0f32, g = 0.2f32, b = 0.2f32},
                 size = {x = radius * 2.0f32, y = radius * 2.0f32}}

            // CapsuleShape2D — 赤
            case SceneTree.NodeKind.Shape(SceneTree.CollisionShapeData.CapsuleShape(radius, height)) =>
                {color = {r = 1.0f32, g = 0.2f32, b = 0.2f32},
                 size = {x = radius * 2.0f32, y = height}}

            // RigidBody2D — 紫 32x32
            case SceneTree.NodeKind.Rigid(_) =>
                {color = {r = 0.7f32, g = 0.3f32, b = 0.9f32},
                 size = {x = 32.0f32, y = 32.0f32}}

            // StaticBody2D — 茶 32x32
            case SceneTree.NodeKind.Fixed(_) =>
                {color = {r = 0.6f32, g = 0.4f32, b = 0.2f32},
                 size = {x = 32.0f32, y = 32.0f32}}

            // Camera2D — 水色 24x24（十字マーク的なサイズ）
            case SceneTree.NodeKind.Camera(_) =>
                {color = {r = 0.4f32, g = 0.7f32, b = 1.0f32},
                 size = {x = 24.0f32, y = 24.0f32}}

            // Label — 白 (テキストサイズ近似)
            case SceneTree.NodeKind.Label(_) =>
                {color = {r = 1.0f32, g = 1.0f32, b = 1.0f32},
                 size = {x = 80.0f32, y = 16.0f32}}

            // Button — 白
            case SceneTree.NodeKind.Button(_) =>
                {color = {r = 1.0f32, g = 1.0f32, b = 1.0f32},
                 size = {x = 80.0f32, y = 24.0f32}}

            // その他 — 暗いグレー 8x8
            case _ =>
                {color = {r = 0.3f32, g = 0.3f32, b = 0.3f32},
                 size = {x = 8.0f32, y = 8.0f32}}
        }

    /// NodeKind のツリー表示用型名を返す
    pub def kindName(kind: SceneTree.NodeKind): String =
        match kind {
            case SceneTree.NodeKind.Plain              => "Node2D"
            case SceneTree.NodeKind.Sprite(_)          => "Sprite2D"
            case SceneTree.NodeKind.AnimatedSprite(_)   => "AnimatedSprite2D"
            case SceneTree.NodeKind.Character(_)       => "CharacterBody2D"
            case SceneTree.NodeKind.Area(_)            => "Area2D"
            case SceneTree.NodeKind.Shape(SceneTree.CollisionShapeData.RectShape(_))    => "RectShape2D"
            case SceneTree.NodeKind.Shape(SceneTree.CollisionShapeData.CircleShape(_))  => "CircleShape2D"
            case SceneTree.NodeKind.Shape(SceneTree.CollisionShapeData.CapsuleShape(_, _)) => "CapsuleShape2D"
            case SceneTree.NodeKind.Rigid(_)           => "RigidBody2D"
            case SceneTree.NodeKind.Fixed(_)           => "StaticBody2D"
            case SceneTree.NodeKind.Camera(_)          => "Camera2D"
            case SceneTree.NodeKind.Kinematic(_)       => "KinematicBody2D"
            case SceneTree.NodeKind.Raycast(_)         => "Raycast2D"
            case SceneTree.NodeKind.ScreenNotifier(_)  => "ScreenNotifier2D"
            case SceneTree.NodeKind.Timer(_)           => "Timer"
            case SceneTree.NodeKind.Marker             => "Marker2D"
            case SceneTree.NodeKind.Path(_)            => "Path2D"
            case SceneTree.NodeKind.PathFollow(_)      => "PathFollow2D"
            case SceneTree.NodeKind.Label(_)           => "Label"
            case SceneTree.NodeKind.Button(_)          => "Button"
            case SceneTree.NodeKind.CanvasLayer         => "CanvasLayer"
        }
}
