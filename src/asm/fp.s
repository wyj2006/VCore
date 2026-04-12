li t0,0x3F800000
fmv.w.x f0,t0 # f0=1.0
li t0,0x40400000
fmv.w.x f1,t0 # f1=3.0
fdiv.s f2,f0,f1