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

vframe: ;# (-a) needed for low-level graphic stuff
 dup_
 mov eax, frame + loadaddr
 shr eax, 2 ;# divide by 4 for word address
 ret

cells: ;# (n-n) return number of bytes in a number of cells
 ;# ONLY WORKS for cell in [2, 4]
 shl eax, (cell / 2)
 ret

.equ nan, 0x80000000 ;# use minimum integer as NaN indicator
nan_: highlevel nan ;# Not a Number for use in fixed-point arithmetic

fx_mul: ;# fixed-point A(3,28) multiplication
 ;# for notation, see http://home.earthlink.net/~yatescr/fp.pdf
 ;# FIXME, get rid of this, make */ set flags for overrun instead
 push ecx ;# save registers which CM indicates have special uses
 push edx
 xor ebx, ebx ;# clear EBX register, use it for testing
 mov edx, eax ;# get multiplicand from TOS
 drop ;# now get multiplier
 imul edx ;# 64-bit signed multiplication
 ;# now the high-order 32 bits are in EDX, and the low-order in EAX
 ;# we need to shift the whole result right by 28 bits, which is
 ;# the same as rotating the top 4 bits of EAX into EDX
 mov ecx, 4
 test edx, edx
 jns 0f
 dec ebx ;# set EBX to -1 to check for overflow/carry
 ;# can't rely on processor flag bits for any of this; they are set based on
 ;# the low 32 bits of the result in EAX, hardly useful
0: ;# set up loop to adjust result to fit
 rol eax
 rol edx
 rol ebx ;# any carry bit goes into EBX, which should still be same when done
 loop 0b
 test ebx, ebx ;# see if it's either 0 or -1; anything else indicates error
 mov eax, edx  ;# result must be returned in EAX (Top Of Stack)
 pop edx
 pop ecx
 jz 9f ;# successful, return with valid result in EAX
 inc ebx ;# was it -1?
 jz 9f ;# if so, still OK
 mov eax, nan  ;# Not a Number
9: ;# done, for better or worse; Z flag and NaN both can be used to check
 ret

oneplus:
 inc eax
 ret

oneless:
 dec eax
 ret

;# don't use the following where flags matter
one:
 dup_
 xor eax, eax
 inc eax
 ret

minus1:
 dup_
 xor eax, eax
 dec eax
 ret

wat: ;# word at
 mov edx, eax
 xor eax, eax
 mov ax, [edx]
 ret

wstore: ;# word store
 mov edx, eax
 drop
 mov [edx], ax
 drop
 ret

pwstore: ;# plus word store
 mov edx, eax
 drop
 add [edx], ax
 drop
 ret

zero: ;# na- erase words of RAM
 push edi
 push ecx
 mov edi, eax
 shl edi, 2 ;# convert word address to byte address
 drop
 mov ecx, eax
 xor eax, eax
 rep stosd
 drop
 pop ecx
 pop edi
 ret

herestore: ;# a- directly manipulate the 'here' pointer
 mov h + loadaddr, eax
 drop
 ret

divide_error: ;# assuming 32-bit dividend, fix instruction to return NaN
 xor eax, eax 
 mov edx, [esp] ;# get pointer of instruction, div or idiv
 mov ah, [edx + 1] ;# what we want is the modr/m byte following it
 and ah, 0b11000111 ;# get rid of the nnn bits of the instruction
 mov edx, 0xc30089 ;# "mov r/m, eax; ret"
 or edx, eax ;# set the destination reg or memory, ASSUMING NO SIB
 xor ah, ah ;# clear EAX again
 inc eax  ;# set divisor to 1
 push edx ;# push "subroutine" on stack, won't work from register
 call esp ;# call the 3-byte "subroutine"
 pop edx
 xor edx, edx  ;# clear the high 32-bits of the dividend
 dec edx  ;# now make it an extension of the NaN sign bit
 mov eax, nan ;# "not a number"
 iret ;# return to try division again... endless loop if we don't get it right
