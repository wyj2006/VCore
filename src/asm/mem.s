.section .data
a: .int 1

.section .text

la x1, a
lw t0, 0(x1)
li t1, 10
add t0,t0,t1
sw t0, 0(x1)
lw t0, 0(x1)

loop:
j loop