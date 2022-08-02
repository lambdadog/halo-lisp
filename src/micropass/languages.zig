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
};
