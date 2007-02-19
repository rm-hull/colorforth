.intel_syntax ;# floppy boot segment
;# 0x000-0x400 is BIOS interrupt table
;# 0x400-0x500 is BIOS system information area
;# we can use starting at 0x500
.equ iobuffer, 0x500
.equ buffersize, 0x4800
.org 0 ;# actually 0x7c00, where the BIOS loads the bootsector
.equ loadaddr, 0x7c00
.equ green, 10
.equ red, 12
.equ white, 15
.macro display string, color
 .ifeqs "\color", ""
  .ascii "\r"; .byte white; .ascii "\n"; .byte white
 .else
  .irpc char, "\string"
   .ascii "\char"; .byte \color
  .endr
 .endif
.endm
.macro zero register
    push 0
    pop \register
.endm
start: jmp  start0
    nop
    .ascii "cmcf 1.0"
    .word 512     ;# bytes/sector
    .byte 1       ;# sector/cluster
    .word 1       ;# sector reserved
    .byte 2       ;# fats
    .word 16*14   ;# root directory entries
    .word 80*2*18 ;# sectors
    .byte 0x0f0   ;# media
    .word 9       ;# sectors/fat
    .word 18      ;# sectors/track
    .word 2       ;# heads
    .long 0       ;# hidden sectors
    .long 80*2*18 ;# sectors again
    .byte 0       ;# drive
.align 4
cylinder: .long 0
nc: .long 9 ;# forth+icons+blocks 24-161 ;# number of cylinders, 9 (out of 80)
.code16
start0:
    mov  sp, loadaddr  ;# stack pointer starts just below this code
    mov  ax, 0x4f02 ;# set video mode
    mov  bx, 1 ;# CGA 40 x 25 text mode, closest to CM2001 graphic mode text
    int  0x10
    call loading
;# (clear interrupts and relocate)
    ;# fall through to cold-start routine
cold:
    mov  edi, loadaddr  ;# start by overwriting this code
    zero es
    call loading_next
    call read
    inc  dword ptr cylinder + loadaddr
    mov  cx, nc + loadaddr ;# number of cylinders used
    dec  cx
0:  push cx
    call loading_next
    call read
    pop  cx
    loop 0b
    call loaded
    hlt
    jmp  start1 ;# start1 is outside of bootsector

read:
;# about to read 0x4800, or 18432 bytes
;# total of 165888 (0x28800) bytes in 9 cylinders, 1.44 MB in 80 cylinders
;# note: old documentation shows cylinder number in high 10 bits of CX...
;# this is wrong, cylinder number is in CH, sector number in CL
    mov  ebx, iobuffer
    push ebx
    mov  ax, (2 << 8) + 18  ;# 18 sectors per head
    mov  dx, 0x0000 ;# head 0, drive 0
    mov  ch, [cylinder + loadaddr]
    mov  cl, 1  ;# sector number is 1-based, and we always read from first
    int  0x13
    mov  ax, (2 << 8) + 18  ;# 18 sectors per head
    mov  dh, 0x01  ;# head 1, drive 0
    add  bx, buffersize / 2  ;# second half of cylinder
    int  0x13
    mov  ebp, esi  ;# temporarily store parameter stack pointer in BP
    pop  esi  ;# load iobuffer
    mov  ecx, 512*18*2/4
    rep  movsd ;# move to ES:EDI location preloaded by caller
    mov  esi, ebp  ;# restore parameter stack pointer
    ret

loading: ;# show "colorForth loading..."
    call bootshow
    .word (1f - 0f) / 2
0:  display "color", green
    display "Forth", red
    display " loading...", white
    display ""
1:  ;# end display

loading_next:
    call bootshow
    .word (1f - 0f) / 2
0:  display "loading", white
    display " cylinder...", white
    display ""
1:  ;# end display

bootshow:
    pop  bp ;# pointer to length of string
    mov  bx, 0x0000 ;# video page
    mov  ax, 0x0300 ;# get cursor position
    int  0x10 ;# sets row/column in DX
    mov  cx, [bp]
    add  bp, 2  ;# now point to string itself
    mov  ax, 0x1303 ;# move cursor, attributes in-line
    int  0x10
    ret  ;# to caller of caller

;# don't need 'write' till after bootup
    .org 0x1fe + start
    .word 0x0aa55 ;# mark boot sector
    ;# end of boot sector
    .long 0x44444444 ;# mark color.com

loaded: ;# show a sign of life: "colorForth code loaded" to screen
    call bootshow
    .word (1f - 0f) / 2
0:  display "color", green; display "Forth", red
    display " code", white
    display " loaded", white
    display ""
1:  ;# end display

write:
    mov  di, iobuffer
    mov  bx, di
    mov  cx, 512*18
    rep  movsw
    mov  ax, 3 << 8 + 18  ;# 18 sectors per head
    mov  dx, 0x0000 ;# head 0, drive 0
    mov  cx, [cylinder]
    shl  cx, 6  ;# put cylinder number into high 10 bits, sector = 0
    push cx
    int  0x13
    mov  ax, 3 << 8 + 18  ;# 18 sectors per head
    mov  dx, 0x0100  ;# head 1, drive 0
    pop  cx
    add  bx, buffersize / 2  ;# second half of cylinder
    int  0x13
    ret

;# these must be defined elsewhere before use
readf:
writef:
seekf:
cmdf:
readyf:
stop:
    ret
