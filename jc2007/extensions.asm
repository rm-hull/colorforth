.intel_syntax
.code32
;# extensions to colorForth better written in assembly language

;# make assembly source constants available to high-level routines
hp_: ;# horizontal pixels
    dup_
    mov  eax, hp
    ret

vp_:  ;# vertical pixels
    dup_
    mov  eax, vp
    ret

hc_:  ;# horizontal characters
    dup_
    mov  eax, hc
    ret

vc_:  ;# vertical characters
    dup_
    mov  eax, vc
    ret

vframe:  ;# needed by Mandelbrot program for low-level graphic stuff
    dup_
    mov eax, frame + loadaddr
    ret

fx_mul: ;# fixed-point A(3,28) multiplication
 ;# for notation, see http://home.earthlink.net/~yatescr/fp.pdf
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
