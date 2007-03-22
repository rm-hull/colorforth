.intel_syntax ;# floppy boot segment
;# 0x000-0x400 is BIOS interrupt table
;# 0x400-0x500 is BIOS system information area
;# we can use starting at 0x500
.org 0 ;# actually 0x7c00, where the BIOS loads the bootsector
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
    .equ dos32p, . - gdt0
    .word 0xffff, 0, 0x9200, 0xcf ;# same but overwrite offset for MS-DOS load
    .equ code16r, . - gdt0
    .word 0xffff, 0, 0x9a00, 0x00 ;# 16-bit real-mode code
    .equ data16r, . - gdt0
    .word 0xffff, 0, 0x9200, 0x00 ;# 16-bit real-mode data
gdt_end:
.code16
start0:
    call textmode
    call loading
    zero es
    call relocate
init: ;# label used by relocate to calculate start address
    zero ss
    mov  sp, loadaddr  ;# stack pointer starts just below this code
    xor  eax, eax
    mov  ax, ds
    shl  eax, 4
    mov  [loadaddr + gdt0 + dos32p + 2], ax
    shr  eax, 16
    mov  [loadaddr + gdt0 + dos32p + 4], al
    zero ds
    data32 call protected_mode
.code32
    call a20 ;# set A20 gate to enable access to addresses with 1xxxxx
    cmp  si, 0x7e00 ;# boot from floppy?
    jz   0f  ;# continue if so...
    push ds
    mov  eax, dos32p
    mov  ds, eax
    mov  ecx, 63*0x100-0x80 ;# ... otherwise relocate color.com
    rep  movsd
    pop  ds
    mov  esi, offset godd ;# set up data stack pointer for 'god' task
    jmp  start1
0:  call unreal_mode
.code16
    ;# fall through to cold-start routine
cold:
    mov  edi, loadaddr  ;# start by overwriting this code
    ;# that's why it's so critical that 'cylinder' be reset to zero before
    ;# saving the image; if it's anything but that, when this block is
    ;# overwritten, 'cylinder' will be changed, and cylinders will be skipped
    ;# in loading, making the bootblock unusable
    call read
    call loaded_next
    inc  byte ptr cylinder + loadaddr
    mov  cx, nc + loadaddr ;# number of cylinders used
    dec  cx
0:  push cx
    call read
    call loaded_next
    inc  byte ptr cylinder + loadaddr
    pop  cx
    loop 0b
    call loaded
    call graphicsmode
    data32 call protected_mode
.code32
    mov esi, godd
    jmp start1 ;# start1 is outside of bootsector

.code16
textmode:
    mov  ax, 0x4f02 ;# set video mode
    mov  bx, 1 ;# CGA 40 x 25 text mode, closest to CM2001 graphic mode text
    int  0x10
    ret

graphicsmode:
    mov  ax, 0x4f01 ;# get video mode info
    mov  cx, vesa ;# a 16-bit color linear video mode (5:6:5 rgb)
    mov  di, iobuffer ;# use floppy buffer, not during floppy I/O!
    int  0x10
    mov  ax, 0x4f02 ;# set video mode
    mov  bx, cx ;# vesa mode
    int  0x10
    mov  ebx, iobuffer + 0x28 ;# linear frame buffer address
    mov  eax, [ebx]
    mov  [displ + loadaddr], eax
    ret

read:
;# about to read 0x4800, or 18432 bytes
;# total of 165888 (0x28800) bytes in 9 cylinders, 1.44 MB in 80 cylinders
;# (low 8 bits of) cylinder number is in CH, (6 bit) sector number in CL
    mov  ebx, iobuffer
    push ebx
    mov  ax, (2 << 8) + 36  ;# 18 sectors per head, 2 heads
    mov  dx, 0x0000 ;# head 0, drive 0
    mov  ch, [cylinder + loadaddr]
    mov  cl, 1  ;# sector number is 1-based, and we always read from first
    int  0x13
    mov  ebp, esi  ;# temporarily store parameter stack pointer in BP
    pop  esi  ;# load iobuffer
    mov  ecx, 512*18*2/4
    addr32 rep movsd ;# move to ES:EDI location preloaded by caller
    mov  esi, ebp  ;# restore parameter stack pointer
    ret
loading: ;# show "colorForth loading..."
    call textshow
    .word (1f - 0f) / 2
0:  display "c", green
    display "F", red
    display " ", white
1:  ;# end display

loaded_next:
    mov  al, cylinder + loadaddr
    ;# fall through to numbershow

numbershow:
    aam  10  ;# split byte into BCD
    xchg ah, al ;# put high byte first
    add  ax, 0x3030 ;# make it into an ASCII number
    push ax
    mov  bp, sp
    mov  bx, 0x0000 | white ;# video page 0, white characters
    mov  ax, 0x0300 ;# get cursor position
    int  0x10 ;# sets row/column in DX
    mov  ax, 0x1300 ;# leave cursor where it is, attributes in BL
    mov  cx, 2 ;# write the 2-byte string to the console
    int  0x10
    pop  ax  ;#clean up stack before returning
    ret

textshow:
    pop  bp ;# pointer to length of string
    mov  bx, 0x0000 ;# video page
    xor  dx, dx  ;# show at top of screen (row=0, column=0)
    mov  cx, [bp]
    add  bp, 2  ;# now point to string itself
    mov  ax, 0x1303 ;# move cursor, attributes in-line
    int  0x10
    ret  ;# to caller of caller

relocate:  ;# move code from where DOS or BIOS put it, to where we want it
    pop  si  ;# just using return address for calculation...
    ;# we know to where to 'return'
    sub  si, offset init-offset start  ;# locate where 'start' actually is
    mov  edi, loadaddr ;# destination of relocation
    mov  cx, 512/4 ;# 128 longwords
    addr32 rep movsd
    jmp  0: (offset init) + loadaddr

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

loaded: ;# "colorForth code loaded" to screen
    call textshow
    .word (1f - 0f) / 2
0:  display "color", green; display "Forth", red
    display " code", white
    display " loaded", white
    display ""
1:  ;# end display

write:
    mov  edi, iobuffer ;# destination address
    mov  ebx, edi  ;# save in EBX for BIOS call
    mov  ecx, 512*18*2/4 ;# using 32-bit MOVS instruction
    addr32 rep movsd
    mov  ax, (3 << 8) + 36  ;# 18 sectors per head, 2 heads
    mov  dx, 0x0000 ;# head 0, drive 0
    mov  ch, [cylinder + loadaddr] ;# cylinder number in CH
    mov  cl, 1  ;# sector number is 1-based
    int  0x13  ;# let BIOS handle the nitty-gritty floppy I/O
    ret

.code32 ;# these routines called from high-level Forth (protected mode)
readf:
    mov  cylinder + loadaddr, al
    dup_ ;# save cylinder number
    push edi
    mov  edi, [esi+4]
    shl  edi, 2  ;# convert longwords to bytes...
    add  edi, loadaddr ;# ... and then to absolute address
    call unreal_mode
.code16
    call read
    data32 call protected_mode
.code32
    pop  edi
    ;# fall through to common code

;# common code for both reads and writes
readf1:
    drop ;# restore EAX, cylinder number
    inc  eax  ;# next cylinder
    add  dword ptr [esi], 0x1200  ;# move memory pointer up this many longwords
    ret

writef:  ;# write cylinder to floppy disk
;# called with cylinder number in AL, source address, in longwords, in ESI
    mov  cylinder + loadaddr, al
    dup_ ;# save cylinder number
    push esi  ;# save data stack pointer, we need it for memory transfer
    mov  esi, [esi+4]  ;# get memory offset
    shl  esi, 2  ;# convert from longwords to bytes...
    add  esi, loadaddr  ;# ... and then to absolute address
    call unreal_mode
.code16
    call write
    data32 call protected_mode
.code32
    pop  esi  ;# restore stack pointer
    jmp  readf1  ;# join common code

buffer:  ;# return IO buffer address in words, for compatibility reasons
    dup_
    mov  eax, iobuffer >> 2
    ret

off:  ;# return loadaddr expressed in words
;# this is the offset in RAM to where block 0 is loaded
    dup_
    mov  eax, loadaddr >> 2
    ret

;# these must be defined elsewhere before use
seekf:
cmdf:
readyf:
stop:
    ret
