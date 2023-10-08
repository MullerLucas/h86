pub const RegisterType = enum {
    // none,
    a,
    b,
    c,
    d,
    sp,
    bp,
    si,
    di,
    es,
    cs,
    ss,
    ds,
    ip,
    flags,
    // count,
};

pub const RegisterAccess = struct {
    reg:    RegisterType,
    offset: u8,
    count:  u8,
};

// ----------------------------------------------

pub const OperationType = enum {
    mov,
    add,
    sub,
};

// ----------------------------------------------

pub const EffectiveAddressOperationType = enum {
    direct,

    bx_si,
    bx_di,
    bp_si,
    bp_di,
    si,
    di,
    bp,
    bx,
};

pub const EffectiveAddressExpression = struct {
    reg:  RegisterType,
    op:   EffectiveAddressOperationType,
    disp: u16,
};

// ----------------------------------------------

pub const Operand = union(enum) {
    none,
    register:  EffectiveAddressExpression,
    memory:    RegisterAccess,
    immediate: u16,
    // relativeImmediate,
};

// ----------------------------------------------

pub const InstructionFlag = enum(u8)  {
    Inst_Lock    = (1 << 0),
    Inst_Rep     = (1 << 1),
    Inst_Segment = (1 << 2),
    Inst_Wide    = (1 << 3),
};

pub const Instruction = struct {
    ty:       OperationType,
    operands: [2]Operand,
};
