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

.macro tenshift register
 ;# shift one decimal point using only binary shifts
 shl \register, 1 ;# this multiplies by 2
 push \register ;# save on stack
 shl \register, 2 ;# multiply by 4 for total of 8
 add [esp], \register ;# add to what we saved is total of 10 times
 pop \register ;# off the stack and back into the register
.endm

hp_: highlevel hp ;# horizontal pixels
vp_: highlevel vp ;# vertical pixels
iw_: highlevel iw ;# icon width including padding
ih_: highlevel ih ;# icon height including padding
hc_: highlevel hc ;# horizontal characters
vc_: highlevel vc ;# vertical characters
vframe: highlevel frame+loadaddr ;# needed for low-level graphic stuff

cells: ;# (n-n) return number of bytes in a number of cells
 ;# ONLY WORKS for cell in [2, 4]
 shl eax, (cell / 2)
 ret

fixed: ;# at compile time, take a text float and convert to fixed-point
 ;# use like this: [white] 1.25 [yellow] fixed
 ;# don't try any more than 4 characters in the number including the point;
 ;# since numbers and the decimal point are all 7-bitters that's all that
 ;# can fit in a 28-bit packed source word.
 ;# so the resolution is .001, or 1/1000
 dup_ ;# indicate that an element is on the stack
 mov eax, [loadaddr-8+edi*4] ;# get the text number
 and eax, 0xfffffff0 ;# get rid of the 9 in the tagbits (low nybble)
 xor ebx, ebx ;# zero out the registers we'll be using
 xor ecx, ecx
 xor edx, edx
 jmp 1f ;# skip the 'drop' first time around
0: ;# set up a loop
 drop ;# 'unpack' does a 'dup', this is to undo it
1: ;# remainder of number, if any, is in EAX
 call unpack ;# get next Huffman code from the packed word
 ;# test al, al ;# isn't necessary because flags are set in 'unpack'
 jz  4f  ;# this only works because space, the 0 character, isn't valid
 cmp al, 0x23 ;# is it '-'? (Huffman codes, remember, not ASCII)
 jnz 2f  ;# skip if not
 inc dl ;# else indicate negative
 jmp 0b ;# loop
2: ;# now check for decimal point
 cmp al, 0x25 ;# is it '.'? (this routine assumes there is one and one only)
 jnz 3f ;# skip if not
 mov dh, cl ;# number of digits that occurred before the point
 jmp 0b ;# loop
3: ;# neither '-' nor '.', so assume it's a number
 inc cl  ;# count digits
 sub eax, 0x18 ;# Huffman code for zero
 tenshift ebx ;# shift left one decimal point, same as 2* + 8*
 add ebx, eax ;# add the number
 jmp 0b
4: ;# now we finalize the number
 drop ;# get rid of the 0 on the data stack
 mov eax, ebx ;# get the number out of EBX
 mov ebx, 0x10000000 / 1000 ;# bit 28 is where the decimal point is
 push edx ;# save EDX so we don't lose counts
 mul ebx ;# multiply, clobbering EDX
 pop edx ;# restore EDX from stack
 sub cl, dh ;# number of digits to the right of decimal point
 ;# in the case of "1.2", this leaves 1; "1.25", 2; ".125", 3
 ;# we need to shift all numbers as if there were 3 digits to right of d.p.
 neg cl  ;# we want a positive number
 add cl, 3 ;# anything from 0 to 3
 jz 6f ;# Z bit set means we don't have to shift
5: ;# shift to the left of the decimal point if necessary
 tenshift eax ;# multiply by 10
 loop 5b ;# use ECX as implied counter
6: ;# negate for each '-' seen
 dec dl ;# decrement count
 js 9f ;# sign bit set means it went below 0
 neg eax
 jmp 6b
9: ;# done
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
