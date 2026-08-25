const std = @import("std");
const rl = @import("raylib");

// Funcion main para inicializar la ventana y el bucle principal del juego
pub fn main() void {
    const window_width: i32 = @intFromFloat(@as(f32, @floatFromInt(map_width)) * cell_size);
    const window_height: i32 = @intFromFloat(@as(f32, @floatFromInt(map_height)) * cell_size);

    rl.initWindow(window_width, window_height, "Raycaster Doom");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    rl.hideCursor();

    while (!rl.windowShouldClose()) {
        const delta_time: f32 = rl.getFrameTime();
        updatePlayer(delta_time);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        //draw_map();

        draw3DView(window_width, window_height);

        draw_minimap(window_width);

        //draw_ray_debug();

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

// Dibja mapa en 2D para debugueo
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
var player_x: f32 = 1.5 * cell_size;
var player_y: f32 = 1.5 * cell_size;
var player_angle: f32 = 0.0;

const player_speed: f32 = 100.0;
const player_radius: f32 = 10.0;

const mouse_sensitivity: f32 = 0.003; //sensibilidad del mouse

// SISTEMA DE COLISOINES

// Función para verificar si una posición es una pared
fn isWall(x: f32, y: f32) bool {
    if (x < 0 or y < 0) return true;
    const col: usize = @intFromFloat(x / cell_size);
    const row: usize = @intFromFloat(y / cell_size);
    return get_map_tile(col, row) != 0;
}

// Intenta mover al jugador en la dirección especificada, verificando colisiones con paredes
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

// Actualiza la posición del jugador basado en la entrada del teclado y el movimiento del mouse
fn updatePlayer(delta_time: f32) void {
    const mouse_delta = rl.getMouseDelta();
    player_angle += mouse_delta.x * mouse_sensitivity;

    // Mantener el ángulo del jugador dentro del rango
    const screen_center_x = @divTrunc(rl.getScreenWidth(), 2);
    const screen_center_y = @divTrunc(rl.getScreenHeight(), 2);
    rl.setMousePosition(screen_center_x, screen_center_y);

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

// RAYCASTER
const RayHit = struct {
    distance: f32,
    wall_type: u8,
    side: u8, // 0 = pared vertical, 1 = pared horizontal
};

fn castRay(angle: f32) RayHit {
    const ray_dir_x = @cos(angle);
    const ray_dir_y = @sin(angle);

    var map_x: i32 = @intFromFloat(player_x / cell_size);
    var map_y: i32 = @intFromFloat(player_y / cell_size);

    const delta_dist_x = if (ray_dir_x == 0) std.math.inf(f32) else @abs(1.0 / ray_dir_x);
    const delta_dist_y = if (ray_dir_y == 0) std.math.inf(f32) else @abs(1.0 / ray_dir_y);

    var step_x: i32 = undefined;
    var step_y: i32 = undefined;
    var side_dist_x: f32 = undefined;
    var side_dist_y: f32 = undefined;

    if (ray_dir_x < 0) {
        step_x = -1;
        side_dist_x = (player_x / cell_size - @as(f32, @floatFromInt(map_x))) * delta_dist_x;
    } else {
        step_x = 1;
        side_dist_x = (@as(f32, @floatFromInt(map_x)) + 1.0 - player_x / cell_size) * delta_dist_x;
    }

    if (ray_dir_y < 0) {
        step_y = -1;
        side_dist_y = (player_y / cell_size - @as(f32, @floatFromInt(map_y))) * delta_dist_y;
    } else {
        step_y = 1;
        side_dist_y = (@as(f32, @floatFromInt(map_y)) + 1.0 - player_y / cell_size) * delta_dist_y;
    }

    var side: u8 = 0;
    var hit_wall: u8 = 0;

    while (hit_wall == 0) {
        if (side_dist_x < side_dist_y) {
            side_dist_x += delta_dist_x;
            map_x += step_x;
            side = 0;
        } else {
            side_dist_y += delta_dist_y;
            map_y += step_y;
            side = 1;
        }

        hit_wall = get_map_tile(@intCast(map_x), @intCast(map_y));
    }

    const perp_dist = if (side == 0)
        side_dist_x - delta_dist_x
    else
        side_dist_y - delta_dist_y;

    return RayHit{
        .distance = perp_dist * cell_size,
        .wall_type = hit_wall,
        .side = side,
    };
}

// Función para dibujar el rayo de depuración desde la posición del jugador hasta el punto de colisión
fn draw_ray_debug() void {
    const hit = castRay(player_angle);

    const end_x = player_x + @cos(player_angle) * hit.distance;
    const end_y = player_y + @sin(player_angle) * hit.distance;

    rl.drawLine(
        @intFromFloat(player_x),
        @intFromFloat(player_y),
        @intFromFloat(end_x),
        @intFromFloat(end_y),
        rl.Color.yellow,
    );
}

const fov: f32 = std.math.degreesToRadians(60.0);

fn draw3DView(screen_width: i32, screen_height: i32) void {
    const half_fov = fov / 2.0;

    // Calculo del FOV
    var col: i32 = 0;
    while (col < screen_width) : (col += 1) {
        const camera_x = @as(f32, @floatFromInt(col)) / @as(f32, @floatFromInt(screen_width));
        const ray_angle = (player_angle - half_fov) + camera_x * fov;

        const hit = castRay(ray_angle);

        // Corrección de fisheye
        const corrected_dist = hit.distance * @cos(ray_angle - player_angle);

        // Dibujo de la pared
        const wall_height: f32 = @as(f32, @floatFromInt(screen_height)) / corrected_dist * cell_size;

        const draw_start = -wall_height / 2.0 + @as(f32, @floatFromInt(screen_height)) / 2.0;
        const draw_end = wall_height / 2.0 + @as(f32, @floatFromInt(screen_height)) / 2.0;

        // Colores segun el tipo de pared
        var color = switch (hit.wall_type) {
            1 => rl.Color.gray,
            2 => rl.Color.red,
            3 => rl.Color.green,
            else => rl.Color.white,
        };

        // Oscurecer el color si es una pared horizontal
        if (hit.side == 1) {
            color = rl.Color{
                .r = color.r / 2,
                .g = color.g / 2,
                .b = color.b / 2,
                .a = color.a,
            };
        }

        // Dibuja la línea vertical de la pared
        rl.drawLine(
            col,
            @intFromFloat(draw_start),
            col,
            @intFromFloat(draw_end),
            color,
        );
    }
}

// Minimapa
const minimap_cell_size: f32 = 6.0;
const minimap_margin: f32 = 10.0;
const minimap_offset_y: f32 = 10.0;

fn draw_minimap(screen_width: i32) void {
    const minimap_width = @as(f32, @floatFromInt(map_width)) * minimap_cell_size;
    const minimap_offset_x = @as(f32, @floatFromInt(screen_width)) - minimap_width - minimap_margin;

    for (0..map_height) |y| {
        for (0..map_width) |x| {
            const tile = get_map_tile(x, y);
            const color = switch (tile) {
                0 => rl.Color.black,
                1 => rl.Color.gray,
                2 => rl.Color.red,
                3 => rl.Color.green,
                else => rl.Color.black,
            };

            const draw_x = minimap_offset_x + @as(f32, @floatFromInt(x)) * minimap_cell_size;
            const draw_y = minimap_offset_y + @as(f32, @floatFromInt(y)) * minimap_cell_size;

            rl.drawRectangle(
                @intFromFloat(draw_x),
                @intFromFloat(draw_y),
                @intFromFloat(minimap_cell_size),
                @intFromFloat(minimap_cell_size),
                color,
            );
        }
    }

    // Posición del jugador escalada al minimapa
    const player_map_x = minimap_offset_x + (player_x / cell_size) * minimap_cell_size;
    const player_map_y = minimap_offset_y + (player_y / cell_size) * minimap_cell_size;

    rl.drawCircle(
        @intFromFloat(player_map_x),
        @intFromFloat(player_map_y),
        3.0,
        rl.Color.yellow,
    );

    // Línea indicando hacia donde mira el jugador
    const dir_len: f32 = 10.0;
    const dir_end_x = player_map_x + @cos(player_angle) * dir_len;
    const dir_end_y = player_map_y + @sin(player_angle) * dir_len;

    rl.drawLine(
        @intFromFloat(player_map_x),
        @intFromFloat(player_map_y),
        @intFromFloat(dir_end_x),
        @intFromFloat(dir_end_y),
        rl.Color.yellow,
    );
}
