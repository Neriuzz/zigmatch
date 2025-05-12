const std = @import("std");

// The empty set
pub const Zero = struct {
    pub fn equals(_: *const Zero, other: *const RegularExpression) bool {
        return switch (other.*) {
            .Zero => true,
            else => false,
        };
    }
};

// The empty string
pub const One = struct {
    pub fn equals(_: *const One, other: *const RegularExpression) bool {
        return switch (other.*) {
            .One => true,
            else => false,
        };
    }
};

// Single character
pub const Char = struct {
    c: u8,

    pub fn equals(self: *const Char, other: *const RegularExpression) bool {
        return switch (other.*) {
            .Char => |case| self.c == case.c,
            else => false,
        };
    }
};

// Intersection e.g. A|B
pub const Alt = struct {
    r_1: *const RegularExpression,
    r_2: *const RegularExpression,

    pub fn equals(self: *const Alt, other: *const RegularExpression) bool {
        return switch (other.*) {
            .Alt => |case| (self.r_1.equals(case.r_1) and self.r_2.equals(case.r_2)) or (self.r_1.equals(case.r_2) and self.r_2.equals(case.r_1)),
            else => false,
        };
    }
};

// Represents a union e.g. AB
pub const Seq = struct {
    r_1: *const RegularExpression,
    r_2: *const RegularExpression,

    pub fn equals(self: *const Seq, other: *const RegularExpression) bool {
        return switch (other.*) {
            .Seq => |case| self.r_1.equals(case.r_1) and self.r_2.equals(case.r_2),
            else => false,
        };
    }
};

// Kleene star
pub const Star = struct {
    r: *const RegularExpression,

    pub fn equals(self: *const Star, other: *const RegularExpression) bool {
        return switch (other.*) {
            .Star => |case| self.r.equals(case.r),
            else => false,
        };
    }
};

// Range of values e.g. [ABC]
pub const Range = struct {
    bitset: std.StaticBitSet(256),

    pub fn init(comptime cs: []const u8) Range {
        // Constructs the bitset at compile-time, meaning equality and membership checks are O(1) at runtime.
        var bitset = std.StaticBitSet(256).initEmpty();
        inline for (cs) |c| bitset.setValue(c, true);

        return Range{ .bitset = bitset };
    }

    pub fn contains(self: Range, c: u8) bool {
        return self.bitset.isSet(c);
    }

    pub fn equals(self: *const Range, other: *const RegularExpression) bool {
        return switch (other.*) {
            .Range => |case| self.bitset.eql(case.bitset),
            else => false,
        };
    }
};

// One or more of nested RegularExpression
pub const Plus = struct {
    r: *const RegularExpression,

    pub fn equals(self: *const Plus, other: *const RegularExpression) bool {
        return switch (other.*) {
            .Plus => |case| self.r.equals(case.r),
            else => false,
        };
    }
};

// Zero or one of nested RegularExpression
pub const Optional = struct {
    r: *const RegularExpression,

    pub fn equals(self: *const Optional, other: *const RegularExpression) bool {
        return switch (other.*) {
            .Optional => |case| self.r.equals(case.r),
            else => false,
        };
    }
};

// n amount of nested RegularExpression
pub const NTimes = struct {
    r: *const RegularExpression,
    n: u32,

    pub fn equals(self: *const NTimes, other: *const RegularExpression) bool {
        return switch (other.*) {
            .NTimes => |case| self.n == case.n and self.r.equals(case.r),
            else => false,
        };
    }
};

// Zero to n amount of nested RegularExpression
pub const Upto = struct {
    r: *const RegularExpression,
    n: u32,

    pub fn equals(self: *const Upto, other: *const RegularExpression) bool {
        return switch (other.*) {
            .Upto => |case| self.n == case.n and self.r.equals(case.r),
            else => false,
        };
    }
};

// n or more amount of nested RegularExpression
pub const From = struct {
    r: *const RegularExpression,
    n: u32,

    pub fn equals(self: *const From, other: *const RegularExpression) bool {
        return switch (other.*) {
            .From => |case| self.n == case.n and self.r.equals(case.r),
            else => false,
        };
    }
};

// From n to m amount of nested RegularExpression
pub const Between = struct {
    r: *const RegularExpression,
    n: u32,
    m: u32,

    pub fn equals(self: *const Between, other: *const RegularExpression) bool {
        return switch (other.*) {
            .Between => |case| self.n == case.n and self.m == case.m and self.r.equals(case.r),
            else => false,
        };
    }
};

// Anything but nested RegularExpression
pub const Not = struct {
    r: *const RegularExpression,

    pub fn equals(self: *const Not, other: *const RegularExpression) bool {
        return switch (other.*) {
            .Not => |case| self.r.equals(case.r),
            else => false,
        };
    }
};

pub const RegularExpression = union(enum) {
    Zero: Zero,
    One: One,
    Char: Char,
    Alt: Alt,
    Seq: Seq,
    Star: Star,
    Range: Range,
    Plus: Plus,
    Optional: Optional,
    NTimes: NTimes,
    Upto: Upto,
    From: From,
    Between: Between,
    Not: Not,

    pub fn equals(self: *const RegularExpression, other: *const RegularExpression) bool {
        switch (self.*) {
            inline else => |*case| return case.equals(other),
        }
    }
};
