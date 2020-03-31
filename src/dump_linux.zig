const std = @import("std");
const open = std.os.linux.open;
const Stat = std.os.Stat;
const fstat = std.os.linux.fstat;
const mmap = std.os.linux.mmap;
const munmap = std.os.linux.munmap;
const write = std.os.linux.write;

// CONSTANTS

const O_RDONLY = std.os.linux.O_RDONLY;
const PROT_READ = std.os.linux.PROT_READ;
const MAP_PRIVATE = std.os.linux.MAP_PRIVATE;
const STDOUT_FILENO = std.os.linux.STDOUT_FILENO;

pub const DumpError = error{
    NoFile,
    Stat,
    Map,
    Write,
};

pub fn dump(path: [*]const u8) DumpError!void {
    const out_fd = STDOUT_FILENO;
    var fd = @intCast(i32, open(path, O_RDONLY, 0));

    if (fd < 0) {
        return error.NoFile;
    }

    var stat: Stat = undefined;

    var status = fstat(fd, &stat);

    if (status < 0) {
        return error.Stat;
    }

    var mresult = @intCast(isize, mmap(null, @intCast(u64, stat.size), PROT_READ, MAP_PRIVATE, fd, 0));

    if (mresult < 0) {
        return error.Map;
    }

    var addr = @intToPtr([*]const u8, @intCast(usize, mresult));

    defer {
        _ = munmap(addr, @intCast(u64, stat.size));
    }

    var left = stat.size;

    while (left > 0) {
        const written = write(out_fd, addr, @intCast(u64, left));
        left -= @intCast(i64, written);
    }
}
