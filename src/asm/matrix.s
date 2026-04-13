.section .data
a: .double 1.6,2.5,3.4,4.3,5.2,6.1
b: .double 6.1,5.2,4.3,3.4,2.5,1.6
c: .double 0,0,0,0,0,0,0,0,0

.section .text

li t0,8

li s3,3 #m
li s4,2 #n
li s5,3 #s

li s0,0 #i

i_loop:
li s1,0 #j

j_loop:
li s2,0 #k

k_loop:
#i*n+k a[i][k]
mul s6,s0,s4
add s6,s6,s2
mul s6,s6,t0
la s7,a
add s6,s7,s6
fld f0,0(s6)
#k*s+j b[k][j]
mul s7,s2,s5
add s7,s7,s1
mul s7,s7,t0
la s8,b
add s7,s8,s7
fld f1,0(s7)
fmul.d f0,f0,f1    #a[i][k]*b[k][j]
#i*s+j c[i][j]
mul s7,s0,s5
add s7,s7,s1
mul s7,s7,t0
la s8,c
add s7,s8,s7
fld f1,0(s7)
fadd.d f0,f0,f1    #a[i][k]*b[k][j]+c[i][j]
fsd f0,0(s7)
addi s2,s2,1
blt s2,s4,k_loop

addi s1,s1,1
blt s1,s5,j_loop

addi s0,s0,1
blt s0,s3,i_loop

la s8,c
fld f1,0(s8)
fld f2,8(s8)
fld f3,16(s8)
fld f4,24(s8)
fld f5,32(s8)
fld f6,40(s8)
fld f7,48(s8)
fld f8,56(s8)
fld f9,64(s8)

loop:
j loop