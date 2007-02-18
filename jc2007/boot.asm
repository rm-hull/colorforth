.intel_syntax ;# floppy boot segment
.equ iobuffer, 0x400
.equ buffersize, 0x4800
.org 0 ;# actually 0x7c00, where the BIOS loads the bootsector
.equ loadaddr, 0x7c00
.equ green, 10
.equ red, 12
.equ white, 15
.macro display string, color
 .irpc char, "\string"
  .ascii "\char"; .byte \color
 .endr
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
    mov  ax, 0x4f02 ;# set video mode
    mov  bx, 1 ;# CGA 40 x 25 text mode, closest to CM2001 graphic mode text
    int  0x10
    call loading
;# clear interrupts and relocate here if desired
    mov  sp, loadaddr
    ;# fall through to cold-start routine
cold:
    mov  si, loadaddr
    call read
    inc  dword ptr cylinder + loadaddr
    mov  cl, nc ;# number of cylinders used
    dec  cl
0:  push ecx
    call read
    pop  ecx
    loop 0b
    call loaded
    jmp  start1 ;# start1 is outside of bootsector

read:
;# about to read 0x4800, or 18432 bytes
;# total of 165888 (0x28800) bytes in 9 cylinders, 1.44 MB in 80 cylinders
    mov  bx, iobuffer
    push bx
    mov  ax, (2 << 8) + 18  ;# 18 sectors per head
    mov  dx, 0x0000 ;# head 0, drive 0
    mov  cx, [cylinder + loadaddr]
    shl  cx, 6  ;# put cylinder number into high 10 bits, sector = 0
    inc  cx  ;# 1-base sector number
    push cx
    int  0x13
    mov  ax, (2 << 8) + 18  ;# 18 sectors per head
    mov  dx, 0x0100  ;# head 1, drive 0
    pop  cx
    add  bx, buffersize / 2  ;# second half of cylinder
    int  0x13
    xchg esi, [esp]  ;# save SI (parameter stack) register and load iobuffer
    mov  cx, 512*18*2/4
    rep  movsd ;# move to ES:DI location preloaded by caller
    pop  si  ;# restore parameter stack pointer
    ret

loading: ;# show "colorForth loading..."
    call 1f
0:  display "color", green
    display "Forth", red
    display " loading...", white
1:  pop  bp ;# pointer to string
    mov  ax, 0x1303 ;# move cursor, attributes in-line
    mov  bx, 0x0000
    mov  cx, (1b - 0b) / 2
    mov  dx, 0x0000 ;# row, column
    int  0x10
    ret

;# don't need 'write' till after bootup
    .org 0x1fe + start
    .word 0x0aa55 ;# mark boot sector
    ;# end of boot sector
    .long 0x44444444 ;# mark color.com

loaded: ;# show a sign of life: "colorForth code loaded" to screen
    call 1f
0:  display "color", green; display "Forth", red
    display " code loaded", white
1:  pop  bp ;# pointer to string
    mov  ax, 0x1303 ;# move cursor, attributes in-line
    mov  bx, 0x0000
    mov  cx, (1b - 0b) / 2
    mov  dx, 0x0100 ;# row, column
    int  0x10
    ret

write:
    mov  di, iobuffer
    mov  bx, di
    mov  cx, 512*18*2/4
    rep  movsd
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
