const std = @import("std");
const linux = std.os.linux;
const open = linux.open;
const Stat = std.os.Stat;

pub fn main() anyerror!void {
    const argv = std.os.argv;

    for (argv[1..argv.len]) |arg| {
        dump(arg, linux.STDOUT_FILENO) catch |err| return err;
    }
}

const DumpError = error{
    NoFile,
    Stat,
    Map,
    Write,
};

fn dump(path: [*]const u8, out_fd: i32) DumpError!void {
    var fd = @intCast(i32, linux.open(path, linux.O_RDONLY, 0));

    if (fd < 0) {
        return error.NoFile;
    }

    var stat: Stat = undefined;

    var status = linux.fstat(fd, &stat);

    if (status < 0) {
        return error.Stat;
    }

    var mresult = @intCast(isize, linux.mmap(null, @intCast(u64, stat.size), linux.PROT_READ, linux.MAP_PRIVATE, fd, 0));

    if (mresult < 0) {
        return error.Map;
    }

    var addr = @intToPtr([*]const u8, @intCast(usize, mresult));

    defer {
        _ = linux.munmap(addr, @intCast(u64, stat.size));
    }

    var left = stat.size;

    while (left > 0) {
        const written = linux.write(out_fd, addr, @intCast(u64, left));
        left -= @intCast(i64, written);
    }
}
