`ifndef OPCODE_SVH
`define OPCODE_SVH 

`define INT_REG_NUM 32
`define FP_REG_NUM 32

`define MSTATUS_ADDR 'h300
`define MIE_ADDR 'h304
`define MTVEC_ADDR 'h305
`define MEPC_ADDR 'h341
`define MCAUSE_ADDR 'h342
`define MIP_ADDR 'h344

typedef enum bit [6:0] {
    Lui,
    Auipc,
    Jal,
    Jalr,
    BEq,
    BNe,
    BLt,
    BGe,
    BLtU,
    BGeU,
    LB,
    LH,
    LW,
    LBU,
    LHU,
    SB,
    SH,
    SW,
    AddI,
    SltI,
    SltIU,
    XorI,
    OrI,
    AndI,
    SllI,
    SrlI,
    SraI,
    Add,
    Sub,
    Sll,
    Slt,
    SltU,
    Xor,
    Srl,
    Sra,
    Or,
    And,
    Mul,
    MulH,
    MulHU,
    MulHSU,
    Div,
    DivU,
    Rem,
    RemU,
    FLW,
    FSW,
    FAddS,
    FSubS,
    FMulS,
    FDivS,
    FSqrtS,
    FSgnJS,
    FSgnJNS,
    FSgnJXS,
    FMinS,
    FMaxS,
    FCvtWS,
    FMoveXW,
    FEqS,
    FLtS,
    FLeS,
    FClassS,
    FCvtSW,
    FMoveWX,
    FLD,
    FSD,
    FAddD,
    FSubD,
    FMulD,
    FDivD,
    FSqrtD,
    FSgnJD,
    FSgnJND,
    FSgnJXD,
    FMinD,
    FMaxD,
    FCvtSD,
    FCvtDS,
    FEqD,
    FLtD,
    FLeD,
    FClassD,
    FCvtWD,
    FMoveDW,
    LRW,
    SCW,
    AMOSwapW,
    AMOAddW,
    AMOXorW,
    AMOAndW,
    AMOOrW,
    AMOMinW,
    AMOMaxW,
    AMOMinUW,
    AMOMaxUW,
    Fence,
    FenceI,
    ECall,
    EBreak,
    CSRRW,
    CSRRS,
    CSRRC,
    CSRRWI,
    CSRRSI,
    CSRRCI,
    SRet,
    MRet,
    WFI,
    SFenceVMA,
    Illegal
} Opcode;

typedef enum bit [3:0] {
    Byte = 1,
    HalfWord = 2,
    Word = 4,
    DoubleWord = 8
} DataWidth;

typedef struct {
    bit enable;
    bit [31:0] val;
} WritePCReq;

typedef enum bit [1:0] {
    IntReg,
    UIntReg,
    FloatReg,
    DoubleReg
} RegKind;

typedef struct {
    bit enable;
    bit [31:0] addr;
    DataWidth width;
    RegKind kind;
    bit [4:0] target;
} ReadMemReq;

typedef struct {
    bit enable;
    bit [31:0] addr;
    DataWidth width;
    bit [63:0] data;
} WriteMemReq;

typedef struct {
    bit enable;
    bit [4:0] index;
    RegKind kind;
    bit [63:0] val;
} WriteRegReq;

typedef struct {
    bit enable;
    bit [11:0] addr;
    bit [31:0] val;
} WriteCSRReq;

typedef enum bit [1:0] {
    User = 'b00,
    Supervisor = 'b01,
    Machine = 'b11
} Mode;

typedef struct {
    bit [31:0] mstatus;
    bit [31:0] mie;
    bit [31:0] mtvec;
    bit [31:0] mepc;
    bit [31:0] mip;
} TrapRelatedCSRs;

`endif
