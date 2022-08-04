const std = @import("std");

const Tokenizer = @import("Tokenizer.zig");
const Token = Tokenizer.Token;

const Parser = @import("Parser.zig");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const ally = arena.allocator();

    var args = std.process.args();
    _ = args.next(ally); // consume program name

    if (args.next(ally)) |arg| {
        var tk = Tokenizer.init(try arg);
        var ps = Parser.init(tk, ally);
        switch (ps.parse()) {
            .err => |err| err.show(),
            .val => |ast| ast.show(),
        }
    } else {
        std.log.err("Didn't receive any input.", .{});
    }
}
