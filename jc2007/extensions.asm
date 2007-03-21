.intel_syntax
.code32
;# extensions to colorForth better written in assembly language
;# i'm not of the opinion that coding in machine language is a step forward
;# jc.unternet.net

.macro highlevel constant
 ;# make assembly source constants available to high-level routines
 dup_ ;# push anything in EAX onto stack
 mov eax, \constant
 ret ;# return with constant at TOS (top of stack = EAX)
.endm

hp_: highlevel hp ;# horizontal pixels
vp_: highlevel vp ;# vertical pixels
iw_: highlevel iw ;# icon width including padding
ih_: highlevel ih ;# icon height including padding
hc_: highlevel hc ;# horizontal characters
vc_: highlevel vc ;# vertical characters
vframe: highlevel frame+loadaddr ;# needed for low-level graphic stuff

fixed: ;# at compile time, take a text float and convert to fixed-point
 ;# use like this: [white] 1.25 [yellow] fixed
 dup_
 mov eax, [edi-2*4] ;# get the text number
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
