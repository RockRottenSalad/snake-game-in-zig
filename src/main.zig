
const rl = @import("raylib");
const std = @import("std");

const ivec2_t = struct{ x: i32, y: i32 };
const uvec2_t = struct{ x: usize, y: usize };

const map_size = ivec2_t{.x = 1000, .y = 1000};
const tile_size = ivec2_t{.x = 25, .y = 25};

//var map_tiles: [(map_size.x/tile_size.x ) * (map_size.y/tile_size.y)]i32 = undefined;
var map_tiles: [(map_size.x/tile_size.x )][(map_size.y/tile_size.y)]u2 = undefined;

const direction_t = enum{north, east, south, west};
const FOOD_TILE: i8 = 2;
const SNAKE_TILE: i8 = 1;
const EMPTY_TILE: i8 = 0;

fn screen_to_tile(vec: ivec2_t) uvec2_t
{
//    std.debug.print("{d} {d}\n", .{vec.x, vec.y});
    const new_vec = uvec2_t{.x = @intCast(@divExact(vec.x, tile_size.x)), .y = @intCast(@divExact(vec.y, tile_size.y))};
    return new_vec;
}

fn round_to(num: i32, round: i32) i32
{
//    const ret: i32 = num % round_to;
    const rem: i32 = @mod(num, round) ;
    if(rem == 0)
    {
        return num;
    }
    return num + round - rem;
}

fn collision_check(vec1: uvec2_t, vec2: uvec2_t) bool
{
    if(vec1.x == vec2.x and vec1.y == vec2.y)
        return true;
    return false;
}

const food_t = struct {
    tile_position: uvec2_t,
    position: ivec2_t,
    eaten: bool,
    random: std.rand.Random,

    fn new_position(self: *food_t) void
    {
       var passed_check = false;

       while(!passed_check)
       {
           const random_num_x = self.*.random.intRangeLessThan(i32, 10, map_size.x-20);
           const random_num_y = self.*.random.intRangeLessThan(i32, 10, map_size.y-20);

           var random_position: ivec2_t = undefined;
           random_position.x = round_to(random_num_x, tile_size.x);
           random_position.y = round_to(random_num_y, tile_size.y);

           self.*.position = random_position;
           self.*.tile_position = screen_to_tile(random_position);

           if(map_tiles[self.*.tile_position.x][self.*.tile_position.y] != EMPTY_TILE)
               continue;

           map_tiles[self.*.tile_position.x][self.*.tile_position.y] = FOOD_TILE;
           passed_check = true;

           self.*.eaten = false;

       }

    }
};

const player_t = struct
{
    direction: direction_t,
    body: std.ArrayList(ivec2_t),
    food_ptr: *food_t,
    score: u16,
    dead: bool,

    fn move(self: *player_t) !void
    {
        var map_tile: uvec2_t = screen_to_tile(self.*.body.getLast());
        map_tiles[map_tile.x][map_tile.y] = EMPTY_TILE;

        var i: usize = self.*.body.items.len - 1;
        while(i > 0) : (i -= 1)
        {
            var vec: *ivec2_t = &self.*.body.items[i];

            vec.* = self.*.body.items[i-1];
        }

        
        var head: *ivec2_t = &self.*.body.items[0];
        switch (self.*.direction)
        {
            direction_t.north => head.*.y -= @as(i32, tile_size.y),
            direction_t.west =>  head.*.x -= @as(i32, tile_size.x),

            direction_t.south => head.*.y += @as(i32, tile_size.y),
            direction_t.east =>  head.*.x += @as(i32, tile_size.x),
        }

        if(head.*.x > map_size.x-tile_size.x)
        {
            head.*.x = 0;
        }else if(head.*.x < 0)
            head.*.x = map_size.x-(tile_size.x);

        if(head.*.y > map_size.y-tile_size.y)
        {
            head.*.y = 0;
        } else if(head.*.y < 0)
            head.*.y = map_size.y-(tile_size.y);

        map_tile = screen_to_tile(head.*);

        if(map_tiles[map_tile.x][map_tile.y] == 2)
        {
            self.*.food_ptr.eaten = true;
            self.*.score += 1;
            try self.*.grow();
        }else if(map_tiles[map_tile.x][map_tile.y] == 1)
            self.*.dead = true;

        map_tiles[map_tile.x][map_tile.y] = SNAKE_TILE;
    }

    fn grow(self: *player_t) !void
    {
        const tail = self.*.body.getLast();
        try self.*.body.append(tail);
    }

    fn change_direction(self: *player_t, direction: direction_t) void
    {
        if(direction == direction_t.west and self.*.direction != direction_t.east)
            self.*.direction = direction;

        if(direction == direction_t.east and self.*.direction != direction_t.west)
            self.*.direction = direction;
        
        if(direction == direction_t.north and self.*.direction != direction_t.south)
            self.*.direction = direction;

        if(direction == direction_t.south and self.*.direction != direction_t.north)
            self.*.direction = direction;
    }

    fn draw(self: *player_t) void
    {
        const length: usize = self.*.body.items.len;
        var i: usize = 0;

        while(i < length) : (i += 1)
        {
            rl.drawRectangle(self.*.body.items[i].x, self.*.body.items[i].y, tile_size.x-1, tile_size.y-1, rl.Color.white);
        }
    }
};



fn draw_map() void
{
    for(0..map_size.x/tile_size.x) |x|
    {
        for(0..map_size.y/tile_size.y) |y| 
        {
            rl.drawRectangle(
                @as(i32, @intCast(x))*tile_size.x,
                @as(i32, @intCast(y))*tile_size.y,
                tile_size.x-1, tile_size.y-1, 
                rl.Color{.r = 100, .g = 100, .b = 100, .a = 255} );
        }
    }
}

pub fn main() anyerror!void
{
    map_tiles = std.mem.zeroes([map_size.x/tile_size.x][map_size.y/tile_size.y]u2);

    rl.initWindow(map_size.x, map_size.y, "Snake");
    defer rl.closeWindow(); 

    rl.setTargetFPS(60); 

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();


    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    var food: food_t = food_t{ .eaten = false, .tile_position = undefined, .random = prng.random(), .position = undefined };


    food.new_position();

    var player: player_t = player_t
    {
        .direction = direction_t.east,
        .body = std.ArrayList(ivec2_t).init(arena.allocator()),
        .food_ptr = &food,
        .score = 0,
        .dead = false
    };

    try player.body.append(ivec2_t{.x = map_size.x/2, .y = map_size.y/2} );
    try player.body.append(ivec2_t{.x = (map_size.x/2)-tile_size.x, .y = map_size.y/2});

    

    var delta_a: f64 = rl.getTime();
    var delta_b: f64 = rl.getTime();
    var delta_time: f64 = rl.getTime();
    const tick_rate: f64 = 0.05;

    while (!rl.windowShouldClose())
    { 
        delta_b = rl.getTime();
        delta_time = delta_b - delta_a;

        if(delta_time >= tick_rate)
        {
            try player.move();
            delta_a = delta_b;
        }
        switch (rl.getKeyPressed())
        {
            rl.KeyboardKey.key_right => player.change_direction(direction_t.east),
            rl.KeyboardKey.key_left => player.change_direction(direction_t.west),
            rl.KeyboardKey.key_down => player.change_direction(direction_t.south),
            rl.KeyboardKey.key_up => player.change_direction(direction_t.north),
            else => {}
        }

        if(player.dead)
        {
            var idc = arena.reset(std.heap.ArenaAllocator.ResetMode.retain_capacity);
            _ = idc;
            player.body.deinit();
            player.body = std.ArrayList(ivec2_t).init(arena.allocator());

            map_tiles = std.mem.zeroes([map_size.x/tile_size.x][map_size.y/tile_size.y]u2);
            try player.body.append(ivec2_t{.x = map_size.x/2, .y = map_size.y/2} );
            try player.body.append(ivec2_t{.x = (map_size.x/2)-tile_size.x, .y = map_size.y/2});
            player.dead = false;
            food.eaten = true;
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        draw_map();
        if(food.eaten == true)
            food.new_position();
        rl.drawRectangle(food.position.x, food.position.y, tile_size.x-1, tile_size.y-1, rl.Color.red);
        player.draw();

//        const score_str: [:0]u8 = blk:{
//            var buffer: [10:0]u8 = undefined;
//            break :blk try std.fmt.bufPrint(&buffer, "{}", .{player.score});
//        };

//        const score_str = [_:0]u8{'0', 0};
//        rl.drawText(&score_str, 190, 200, 20, rl.Color.light_gray);
    }
}
