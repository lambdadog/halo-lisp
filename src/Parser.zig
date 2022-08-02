const Parser = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const Tokenizer = @import("Tokenizer.zig");
const Token = Tokenizer.Token;

const Lsrc = @import("micropass/languages.zig").Lsrc;

tk: Tokenizer,
ally: Allocator,

// Carry richer errors up to the top
pub fn ParseResult(comptime T: type) type {
    return union(enum) {
        err: ParseError,
        val: T,
    };
}

pub const ParseError = union(enum) {
    // TODO: better error type
    unexpectedEof: usize,
    unbalancedParens: usize,
    unhandledToken: Token,

    pub fn show(self: *const ParseError) void {
        switch (self.*) {
            .unexpectedEof => |pos| std.log.err("Unexpected EOF at {d}", .{pos}),
            .unbalancedParens => |pos| std.log.err("Unbalanced parens at {d}", .{pos}),
            .unhandledToken => |tk| std.log.err("Unhandled token '{s}' at {d}", .{
                @tagName(tk.is),
                tk.location.start,
            }),
        }
    }
};

pub fn init(tokenizer: Tokenizer, allocator: Allocator) Parser {
    return Parser{
        .tk = tokenizer,
        .ally = allocator,
    };
}

pub fn parse(self: *Parser) ParseResult(Lsrc) {
    switch (self.parseExpr()) {
        .err => |err| return ParseResult(Lsrc){
            .err = err,
        },
        .val => |expr| return ParseResult(Lsrc){
            .val = Lsrc{ .expr = expr },
        },
    }
}

fn parseExpr(self: *Parser) ParseResult(Lsrc.Expr) {
    const State = union(enum) {
        initial,
        quote,
        nil,
    };

    var state: State = .initial;
    var result: ParseResult(Lsrc.Expr) = undefined;

    top: while (self.tk.next()) |t0| switch (state) {
        .initial => switch (t0.is) {
            .eof => {
                result = ParseResult(Lsrc.Expr){
                    .err = ParseError{
                        .unexpectedEof = t0.location.start,
                    },
                };
                break;
            },
            .l_paren => {
                var exprs = std.ArrayList(Lsrc.Expr).init(self.ally);
                while (true) {
                    switch (self.parseExpr()) {
                        .err => |err| switch (err) {
                            .unbalancedParens => |pos| {
                                self.tk.goto(pos); // don't consume
                                break;
                            },
                            else => {
                                result = ParseResult(Lsrc.Expr){
                                    .err = err,
                                };
                                break :top;
                            },
                        },
                        .val => |expr| {
                            exprs.append(expr) catch unreachable;
                        },
                    }
                }

                result = ParseResult(Lsrc.Expr){
                    .val = Lsrc.Expr{ .sexpr = exprs.items },
                };
                break;
            },
            .r_paren => {
                result = ParseResult(Lsrc.Expr){
                    .err = ParseError{ .unbalancedParens = t0.location.start },
                };
                break;
            },
            .symbol_literal => |symbol_name| {
                if (Lsrc.T.Primitive.get(symbol_name)) |prim| {
                    result = ParseResult(Lsrc.Expr){
                        .val = Lsrc.Expr{ .primitive = prim },
                    };
                    break;
                } else {
                    result = ParseResult(Lsrc.Expr){
                        .val = Lsrc.Expr{ .symbol = symbol_name },
                    };
                    break;
                }
            },
            // We aren't sufficiently complex to recognize the difference yet
            .quote, .quasiquote => {
                state = .quote;
            },
            else => {
                result = ParseResult(Lsrc.Expr){
                    .err = ParseError{ .unhandledToken = t0 },
                };
                break;
            },
        },
        .quote => switch (t0.is) {
            .eof => {
                result = ParseResult(Lsrc.Expr){
                    .err = ParseError{ .unexpectedEof = t0.location.start },
                };
                break;
            },
            .l_paren => {
                state = .nil;
            },
            else => {
                result = ParseResult(Lsrc.Expr){
                    .err = ParseError{ .unhandledToken = t0 },
                };
                break;
            },
        },
        .nil => switch (t0.is) {
            .eof => {
                result = ParseResult(Lsrc.Expr){
                    .err = ParseError{ .unexpectedEof = t0.location.start },
                };
                break;
            },
            .r_paren => {
                result = ParseResult(Lsrc.Expr){
                    .val = Lsrc.Expr{ .constant = .nil },
                };
                break;
            },
            else => {
                result = ParseResult(Lsrc.Expr){
                    .err = ParseError{ .unhandledToken = t0 },
                };
                break;
            },
        },
    };

    return result;
}
