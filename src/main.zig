const std = @import("std");
const rl = @import("raylib");

pub fn main() void {
    rl.initWindow(800, 450, "Raycaster Doom");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        rl.drawFPS(10, 10);
    }
}
