la x1, trap_handler
csrw mtvec, x1

li x2, 0x8
csrs mie, x2
csrs mip, x2
csrs mstatus, x2

loop:
    j loop

trap_handler:
    csrc mip, x2
    li x3, 1
    mret