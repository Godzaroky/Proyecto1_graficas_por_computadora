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
const map_width: usize = 10;
const map_height: usize = 10;

const game_map = [map_height][map_width]u8{
    .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    .{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    .{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    .{ 1, 0, 0, 2, 2, 0, 0, 0, 0, 1 },
    .{ 1, 0, 0, 2, 2, 0, 0, 0, 0, 1 },
    .{ 1, 0, 0, 0, 0, 0, 0, 3, 0, 1 },
    .{ 1, 0, 0, 0, 0, 0, 0, 3, 0, 1 },
    .{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    .{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
};

const cell_size: f32 = 64.0;

fn get_map_tile(x: usize, y: usize) u8 {
    if (x >= map_width or y >= map_height) {
        return 1;
    }
    return game_map[y][x];
}

fn draw_map() void {
    for (0..map_height) |y| {
        for (0..map_width) |x| {
            const tile = get_map_tile(x, y);
            const color = switch (tile) {
                0 => rl.Color.black, // espacio vacio
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

// Estado inicial del jugador
var player_x: f32 = 1.5 * cell_size; // centro de la celda [1][1]
var player_y: f32 = 1.5 * cell_size;
var player_angle: f32 = 0.0;

const player_speed: f32 = 100.0;
const player_radius: f32 = 10.0;

fn isWall(x: f32, y: f32) bool {
    if (x < 0 or y < 0) return true;
    const col: usize = @intFromFloat(x / cell_size);
    const row: usize = @intFromFloat(y / cell_size);
    return get_map_tile(col, row) != 0;
}

fn tryMovePlayer(dx: f32, dy: f32) void {
    // Revisa el eje X de forma independiente
    const new_x = player_x + dx;
    if (!isWall(new_x + player_radius * std.math.sign(dx), player_y) and
        !isWall(new_x - player_radius, player_y))
    {
        player_x = new_x;
    }

    // Revisa el eje Y de forma independiente
    const new_y = player_y + dy;
    if (!isWall(player_x, new_y + player_radius * std.math.sign(dy)) and
        !isWall(player_x, new_y - player_radius))
    {
        player_y = new_y;
    }
}

// Actualiza la posición del jugador basado en la entrada del teclado
fn updatePlayer(delta_time: f32) void {
    var move_x: f32 = 0.0;
    var move_y: f32 = 0.0;

    if (rl.isKeyDown(.w)) {
        move_x += @cos(player_angle) * player_speed * delta_time;
        move_y += @sin(player_angle) * player_speed * delta_time;
    }
    if (rl.isKeyDown(.s)) {
        move_x -= @cos(player_angle) * player_speed * delta_time;
        move_y -= @sin(player_angle) * player_speed * delta_time;
    }

    tryMovePlayer(move_x, move_y);
}
