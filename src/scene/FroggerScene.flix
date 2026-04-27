// FroggerScene — root scene for Frogger

mod FroggerScene {
    pub def rootName(): String = "Root"

    pub def buildInitialScene(): SceneTree.Node =
        SceneTree.node2D(rootName(), Vec2D.zero(), Nil)
}
