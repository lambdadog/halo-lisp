const Tokenizer = @This();

const std = @import("std");

pub const Token = struct {
    is: Value,
    location: Location,

    pub const Location = struct {
        start: usize,
        end: usize,
    };

    pub const Value = union(enum) {
        eof,
        quote,
        quasiquote,
        unquote,
        unquote_splicing,
        l_paren,
        r_paren,
        string_literal: []const u8,
        number_literal: isize,
        symbol_literal: []const u8,
        invalid,
    };
};

buffer: [:0]const u8,
index: usize,

pub fn init(buffer: [:0]const u8) Tokenizer {
    // Skip the UTF-8 BOM
    const initial_index: usize = if (std.mem.startsWith(u8, buffer, "\xEF\xBB\xBF")) 3 else 0;
    return Tokenizer{
        .buffer = buffer,
        .index = initial_index,
    };
}

// For not consuming tokens
pub fn goto(self: *Tokenizer, index: usize) void {
    self.index = index;
}

const State = enum {
    initial,
    minus,
    unquote,
    string_literal,
    number_literal,
    symbol_literal,
};

pub fn next(self: *Tokenizer) ?Token {
    if (self.index > self.buffer.len) {
        return null;
    } else {
        var state: State = .initial;
        var result = Token{
            .is = .eof,
            .location = .{
                .start = self.index,
                .end = undefined,
            },
        };
        while (true) : (self.index += 1) {
            const c = self.buffer[self.index];
            switch (state) {
                .initial => switch (c) {
                    0 => break,
                    ' ', '\n', '\t', '\r' => {
                        result.location.start = self.index + 1;
                    },
                    '\'' => {
                        result.is = .quote;
                        break;
                    },
                    '`' => {
                        result.is = .quasiquote;
                        break;
                    },
                    ',' => {
                        state = .unquote;
                    },
                    '(' => {
                        result.is = .l_paren;
                        break;
                    },
                    ')' => {
                        result.is = .r_paren;
                        break;
                    },
                    '"' => {
                        state = .string_literal;
                    },
                    '-' => {
                        state = .minus;
                    },
                    '0'...'9' => {
                        state = .number_literal;
                    },
                    else => {
                        // TODO: check validity of symbol characters
                        state = .symbol_literal;
                    },
                },
                .unquote => switch (c) {
                    '@' => {
                        result.is = .unquote_splicing;
                        break;
                    },
                    else => {
                        self.index -= 1; // do not consume
                        result.is = .unquote;
                        break;
                    },
                },
                .minus => switch (c) {
                    0, ' ', '\n', '\t', '\r', '(', ')' => {
                        self.index -= 1; // don't consume
                        result.is = Token.Value{ .symbol_literal = self.buffer[result.location.start .. self.index + 1] };
                        break;
                    },
                    '0'...'9' => {
                        state = .number_literal;
                    },
                    else => {
                        // TODO: check validity of symbol characters
                        state = .symbol_literal;
                    },
                },
                .string_literal => switch (c) {
                    0, '\n', '\r' => {
                        result.is = .invalid;
                        break;
                    },
                    '"' => {
                        result.is = Token.Value{ .string_literal = self.buffer[result.location.start + 1 .. self.index] };
                        break;
                    },
                    else => {
                        // TODO: check validity of literal characters
                    },
                },
                .number_literal => switch (c) {
                    0, ' ', '\n', '\t', '\r', '(', ')' => {
                        self.index -= 1; // don't consume
                        const maybeValue: ?isize = std.fmt.parseInt(isize, self.buffer[result.location.start .. self.index + 1], 10) catch null;
                        result.is = if (maybeValue) |value|
                            Token.Value{ .number_literal = value }
                        else
                            .invalid;
                        break;
                    },
                    else => {
                        // TODO: check validity of symbol characters
                        state = .symbol_literal;
                    },
                },
                .symbol_literal => switch (c) {
                    0, ' ', '\n', '\t', '\r', '(', ')' => {
                        self.index -= 1; // don't consume
                        result.is = Token.Value{ .symbol_literal = self.buffer[result.location.start .. self.index + 1] };
                        break;
                    },
                    else => {
                        // TODO: check validity of symbol characters
                    },
                },
            }
        }
        if (result.is == .eof) {
            result.location.start = self.index;
        }
        // Consider switching the order of these 2 lines:
        result.location.end = self.index;
        self.index += 1;
        return result;
    }
}
