addi t0,x0,1
addi t1,x0,1
loop:
add t2,t0,t1
addi t0,t1,0
addi t1,t2,0
j loop