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
            .val => |lsrc| lsrc.show(),
        }
        // while (tk.next()) |token| {
        //     switch (token.is) {
        //         .eof => {
        //             std.debug.print(
        //                 "input[{d}] = eof\n",
        //                 .{
        //                     token.location.start,
        //                 },
        //             );
        //         },
        //         .quote => {
        //             std.debug.print(
        //                 "input[{d}] = quote\n",
        //                 .{
        //                     token.location.start,
        //                 },
        //             );
        //         },
        //         .quasiquote => {
        //             std.debug.print(
        //                 "input[{d}] = quasiquote\n",
        //                 .{
        //                     token.location.start,
        //                 },
        //             );
        //         },
        //         .unquote => {
        //             std.debug.print(
        //                 "input[{d}] = unquote\n",
        //                 .{
        //                     token.location.start,
        //                 },
        //             );
        //         },
        //         .unquote_splicing => {
        //             std.debug.print(
        //                 "input[{d}..{d}] = unquote_splicing\n",
        //                 .{
        //                     token.location.start,
        //                     token.location.end + 1,
        //                 },
        //             );
        //         },
        //         .l_paren => {
        //             std.debug.print(
        //                 "input[{d}] = l_paren\n",
        //                 .{
        //                     token.location.start,
        //                 },
        //             );
        //         },
        //         .r_paren => {
        //             std.debug.print(
        //                 "input[{d}] = r_paren\n",
        //                 .{
        //                     token.location.start,
        //                 },
        //             );
        //         },
        //         .string_literal => |string| {
        //             std.debug.print(
        //                 "input[{d}..{d}] = string_literal(\"{s}\")\n",
        //                 .{
        //                     token.location.start,
        //                     token.location.end + 1,
        //                     string,
        //                 },
        //             );
        //         },
        //         .number_literal => |number| {
        //             if (token.location.start == token.location.end) {
        //                 std.debug.print(
        //                     "input[{d}] = number_literal({d})\n",
        //                     .{
        //                         token.location.start,
        //                         number,
        //                     },
        //                 );
        //             } else {
        //                 std.debug.print(
        //                     "input[{d}..{d}] = number_literal({d})\n",
        //                     .{
        //                         token.location.start,
        //                         token.location.end + 1,
        //                         number,
        //                     },
        //                 );
        //             }
        //         },
        //         .symbol_literal => |symbol_name| {
        //             if (token.location.start == token.location.end) {
        //                 std.debug.print(
        //                     "input[{d}] = symbol_literal(\"{s}\")\n",
        //                     .{
        //                         token.location.start,
        //                         symbol_name,
        //                     },
        //                 );
        //             } else {
        //                 std.debug.print(
        //                     "input[{d}..{d}] = symbol_literal(\"{s}\")\n",
        //                     .{
        //                         token.location.start,
        //                         token.location.end + 1,
        //                         symbol_name,
        //                     },
        //                 );
        //             }
        //         },
        //         .invalid => {
        //             std.log.err("Invalid parse at {d}\n", .{token.location.start});
        //             break;
        //         },
        //     }
        // }
    } else {
        std.log.err("Didn't receive any input.", .{});
    }
}
