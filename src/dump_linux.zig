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
    var fd = try fd_open(path);
    var size = try size_of(fd);
    var addr = try map(fd, size);

    defer unmap(addr, size);

    try write_out(STDOUT_FILENO, addr, size);
}

fn fd_open(path: [*]const u8) DumpError!i32 {
    var fd = @intCast(i32, open(path, O_RDONLY, 0));

    if (fd < 0) {
        return error.NoFile;
    }

    return fd;
}

fn size_of(fd: i32) DumpError!u64 {
    var stat: Stat = undefined;

    var status = fstat(fd, &stat);

    if (status < 0) {
        return error.Stat;
    }

    return @intCast(u64, stat.size);
}

fn map(fd: i32, size: usize) DumpError![*]const u8 {
    var mresult = @intCast(isize, mmap(null, @intCast(u64, size), PROT_READ, MAP_PRIVATE, fd, 0));

    if (mresult < 0) {
        return error.Map;
    }

    var addr = @intToPtr([*]const u8, @intCast(usize, mresult));

    return addr;
}

fn unmap(addr: [*]const u8, size: usize) void {
    _ = munmap(addr, @intCast(u64, size));
}

fn write_out(fd: i32, addr: [*]const u8, size: u64) DumpError!void {
    var left = @intCast(i64, size);
    var cur = addr;

    while (left > 0) {
        const written = write(fd, cur, @intCast(u64, left));
        left -= @intCast(i64, written);
        cur += written;
    }
}
