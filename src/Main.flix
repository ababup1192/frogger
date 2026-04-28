// Frogger — Flix game

def main(): Unit \ IO =
    if (Engine.ensureMainThread()) ()
    else {
        println("Frogger");
        let config = Game.engineConfig();
        discard run {
            Game.startGame()
        } with LwjglLayer.withLwjgl(config)
          with Math.Random.runWithIO
          with Fs.FileRead.runWithIO;
        println("Game ended.")
    }
