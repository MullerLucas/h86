pub fn count_bits(comptime val: comptime_int) comptime_int {
    if (val == 0) {
        return 0;
    }
    return 1 + count_bits(val >> 1);
}

pub fn count_enum_fields(comptime T: type) comptime_int {
    const ti = switch(@typeInfo(T)) {
        .Enum => |ti| ti,
        else  => @compileError("not an enum"),
    };
    return ti.fields.len;
}
