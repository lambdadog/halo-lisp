const std = @import("std");

pub const Lsrc = struct {
    expr: Expr,

    // Terminals
    pub const T = struct {
        // There's got to be a better way to specify this all
        pub const Primitive = enum {
            car,
            cdr,
            cons,

            const prims = std.ComptimeStringMap(Primitive, .{
                .{ "car", .car },
                .{ "cdr", .cdr },
                .{ "cons", .cons },
            });

            pub fn get(bytes: []const u8) ?Primitive {
                return prims.get(bytes);
            }

            // Way bigger result type than it needs to be...
            pub fn arity(prim: Primitive) usize {
                return switch (prim) {
                    .car => 1,
                    .cdr => 1,
                    .cons => 2,
                };
            }
        };

        pub const Symbol = []const u8;

        pub const Constant = enum {
            nil,
        };
    };

    // Pointer size
    pub const Expr = union(enum) {
        primitive: T.Primitive,
        symbol: T.Symbol,
        constant: T.Constant,

        sexpr: []Expr,
    };

    // Creates its own allocator since it's a debug function
    pub fn show(self: *const Lsrc) void {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();

        showInternal(arena.allocator(), 0, self.expr);
    }

    fn showInternal(ally: std.mem.Allocator, indent: usize, expr: Expr) void {
        var indent_string = ally.alloc(u8, indent) catch unreachable;

        var i: usize = 0;
        while (i < indent) : (i += 1) {
            indent_string[i] = ' ';
        }

        switch (expr) {
            .primitive => |p| {
                std.debug.print("{s}primitive({s})\n", .{
                    indent_string,
                    @tagName(p),
                });
            },
            .symbol => |symbol_name| {
                std.debug.print("{s}symbol({s})\n", .{
                    indent_string,
                    symbol_name,
                });
            },
            .constant => |c| {
                std.debug.print("{s}constant({s})\n", .{
                    indent_string,
                    @tagName(c),
                });
            },
            .sexpr => |es| {
                std.debug.print("{s}sexpr(\n", .{
                    indent_string,
                });
                for (es) |e| {
                    showInternal(ally, indent + 2, e);
                }
                std.debug.print("{s})\n", .{
                    indent_string,
                });
            },
        }
    }
};
