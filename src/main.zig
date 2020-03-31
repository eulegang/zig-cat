const std = @import("std");
const builtin = @import("builtin");

const dump = switch (builtin.os) {
    builtin.Os.linux => @import("dump_linux.zig"),
    else => @compileError("zig-cat only implements linux"),
};

pub fn main() anyerror!void {
    const argv = std.os.argv;

    for (argv[1..argv.len]) |arg| {
        dump.dump(arg) catch |err| return err;
    }
}
