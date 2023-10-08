pub fn count_bits(comptime val: comptime_int) comptime_int {
    if (val == 0) {
        return 0;
    }
    return 1 + count_bits(val >> 1);
}
