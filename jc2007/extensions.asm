.intel_syntax
.code32
;# extensions to colorForth better written in assembly language

fx_multiply: ;# fixed-point A(3,28) multiplication
 mov edx, eax ;# get multiplicand from TOS
 drop ;# now get multiplier
 imul edx ;# 64-bit signed multiplication
 ;# now the high-order 32 bits are in EDX, and the low-order in EAX
 ;# we need to shift the whole result right by 28 bits, which is
 ;# the same as rotating the top 4 bits of EAX into EDX
 .rept 4
 rol eax
 rol edx
 .endr
 mov eax, edx  ;# result must be returned in EAX (Top Of Stack)
 ret
