import os
from enum import Enum, auto

os.chdir(os.path.dirname(__file__))


class Instruction(Enum):
    LUI = 1
    AUIPC = auto()

    JAL = auto()
    JALR = auto()

    B_TYPE_START = auto()
    BEQ = auto()
    BNE = auto()
    BLT = auto()
    BGE = auto()
    BLTU = auto()
    BGEU = auto()
    B_TYPE_END = auto()

    L_TYPE_START = auto()
    LB = auto()
    LH = auto()
    LW = auto()
    LBU = auto()
    LHU = auto()
    L_TYPE_END = auto()

    SB = auto()
    SH = auto()
    SW = auto()

    ADDI = auto()
    SLTI = auto()
    SLTIU = auto()
    XORI = auto()
    ORI = auto()
    ANDI = auto()
    SLLI = auto()
    SRLI = auto()
    SRAI = auto()

    ADD = auto()
    SUB = auto()
    SLL = auto()
    SLT = auto()
    SLTU = auto()
    XOR = auto()
    SRL = auto()
    SRA = auto()
    OR = auto()
    AND = auto()

    FENCE = auto()
    FENCE_I = auto()
    ECALL = auto()
    EBREAK = auto()
    CSRRW = auto()
    CSRRS = auto()
    CSRRC = auto()
    CSRRWI = auto()
    CSSRRSI = auto()
    CSRRCI = auto()


with open("inst_def.vh", mode="w", encoding="utf-8") as file:
    for i in Instruction:
        print(f"`define {i.name} {i.value}", file=file)
