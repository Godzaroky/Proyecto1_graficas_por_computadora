const std = @import("std");
const rl = @import("raylib");

// Funcion main para inicializar la ventana y el bucle principal del juego
pub fn main() void {
    const window_width: i32 = @intFromFloat(@as(f32, @floatFromInt(map_width)) * cell_size);
    const window_height: i32 = @intFromFloat(@as(f32, @floatFromInt(map_height)) * cell_size);

    rl.initWindow(window_width, window_height, "Raycaster Doom");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        draw_map();

        rl.drawFPS(10, 10);
    }
}

// Mapa del juego
const map_width: usize = 16;
const map_height: usize = 16;

const game_map = [map_height][map_width]u8{
    .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    .{ 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 },
    .{ 1, 0, 2, 0, 1, 0, 3, 3, 3, 0, 1, 0, 4, 4, 0, 1 },
    .{ 1, 0, 0, 0, 1, 0, 3, 0, 3, 0, 1, 0, 0, 0, 0, 1 },
    .{ 1, 0, 0, 0, 0, 0, 3, 0, 3, 0, 0, 0, 0, 0, 0, 1 },
    .{ 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1 },
    .{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    .{ 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1 },
    .{ 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1 },
    .{ 1, 0, 1, 0, 2, 2, 0, 0, 1, 0, 4, 0, 1, 0, 1, 1 },
    .{ 1, 0, 0, 0, 2, 2, 0, 0, 0, 0, 4, 0, 0, 0, 1, 1 },
    .{ 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1 },
    .{ 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    .{ 1, 0, 3, 3, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1 },
    .{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
};

const cell_size: f32 = 64.0;

fn get_map_tile(x: usize, y: usize) u8 {
    if (x >= map_width or y >= map_height) {
        return 1; // Return wall for out of bounds
    }
    return game_map[y][x];
}

fn draw_map() void {
    for (0..map_height) |y| {
        for (0..map_width) |x| {
            const tile = get_map_tile(x, y);
            const color = switch (tile) {
                0 => rl.Color.black, // espacio vaio
                1 => rl.Color.gray, // pared
                2 => rl.Color.red, // enemigo
                3 => rl.Color.green, // jugador
                else => rl.Color.black,
            };
            rl.drawRectangle(
                @intCast(x * @as(usize, @intFromFloat(cell_size))),
                @intCast(y * @as(usize, @intFromFloat(cell_size))),
                @intFromFloat(cell_size),
                @intFromFloat(cell_size),
                color,
            );
        }
    }
}
