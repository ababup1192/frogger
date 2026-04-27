// Dodge the Creeps — tile-based game in Flix

def main(): Unit \ IO =
    if (Engine.ensureMainThread()) ()
    else {
        println("Dodge the Creeps");
        let config = Game.engineConfig();
        discard run {
            Game.startGame()
        } with LwjglLayer.withLwjgl(config)
          with Math.Random.runWithIO;
        println("Game ended.")
    }
