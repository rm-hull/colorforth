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
gdt: .word gdt_end - gdt0 - 1 ;# GDT limit
    .long gdt0 + loadaddr ;# pointer to start of table
.align 8
gdt0: .word 0, 0, 0, 0 ;# start of table must be a null entry
    .equ code32p, . - gdt0
    .word 0xffff, 0, 0x9a00, 0xcf ;# 32-bit protected-mode code
    .equ data32p, . - gdt0
    .word 0xffff, 0, 0x9200, 0xcf ;# 32-bit protected-mode data
    .equ code16r, . - gdt0
    .word 0xffff, 0, 0x9a00, 0x00 ;# 16-bit real-mode code
    .equ data16r, . - gdt0
    .word 0xffff, 0, 0x9200, 0x00 ;# 16-bit real-mode data
gdt_end:
.code16
start0:
    zero ss
    mov  sp, loadaddr  ;# stack pointer starts just below this code
    mov  ax, 0x4f02 ;# set video mode
    mov  bx, 1 ;# CGA 40 x 25 text mode, closest to CM2001 graphic mode text
    int  0x10
    call loading
;# (clear interrupts and relocate)
    xor  ax, ax
    mov  ds, ax
    mov  es, ax
    data32 call protected_mode
    data32 call a20 ;# set A20 gate to enable access to addresses with 1xxxxx
.code32
    call unreal_mode
.code16
    ;# fall through to cold-start routine
cold:
    mov  edi, loadaddr  ;# start by overwriting this code
    call loading_next
    call read
    inc  dword ptr cylinder + loadaddr
    mov  cx, nc + loadaddr ;# number of cylinders used
    dec  cx
0:  push cx
    call loading_next
    call read
    inc  dword ptr cylinder + loadaddr
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
    addr32 rep movsd ;# move to ES:EDI location preloaded by caller
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

protected_mode:
    cli  ;# we're not set up to handle interrupts in protected mode
    lgdt [gdt + loadaddr]
    mov  eax, cr0
    or   al, 1
    mov  cr0, eax
    jmp  code32p: offset pm + loadaddr
.code32
pm: mov  ax, data32p ;# set all segment registers to protected-mode selector
    mov  ds, ax
    mov  es, ax
    mov  ss, ax  ;# same base as before (0), or ret wouldn't work!
    ret  ;# now it's a 32-bit ret; no "ret far" needed

unreal_mode:
    jmp  code16r: offset code16p + loadaddr
.code16
code16p: ;# that far jump put us in 16-bit protected mode
;# now let's put at least the stack segment back to 16 bits
    mov  ax, data16r
;# any segments left commented out will be in "unreal" mode
    mov  ss, ax
    ;#mov  ds, ax
    ;#mov  es, ax
    mov  eax, cr0
    and  al, 0xfe ;# mask out bit 0, the PE (protected-mode enabled) bit
    mov  cr0, eax
    jmp  0:offset unreal + loadaddr
unreal:  ;# that far jump put us back to a realmode CS
    xor  ax, ax
    mov  ss, ax
    mov  ds, ax
    mov  es, ax
    sti  ;# re-enable interrupts
    data32 ret ;# adjust stack appropriately for call from protected mode

a20:
    mov  al, 0x0d1
    out  0x64, al ;# to keyboard
0:  in   al, 0x64
    and  al, 2
    jnz  0b
    mov  al, 0x4b
    out  0x60, al ;# to keyboard, enable A20
    ret

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
    mov  cx, [cylinder + loadaddr]
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
