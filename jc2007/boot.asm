.intel_syntax ;# floppy boot segment
;# 0x000-0x400 is BIOS interrupt table
;# 0x400-0x500 is BIOS system information area
;# we can use starting at 0x500

.equ upper_right, 158 ;# address of upper-right corner of screen

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
    .equ code16r, . - gdt0
    .word 0xffff, 0, 0x9a00, 0x00 ;# 16-bit real-mode code
    .equ data16r, . - gdt0
    .word 0xffff, 0, 0x9200, 0x00 ;# 16-bit real-mode data
gdt_end:
.code16
start0:
    cli
    call settrap
    call relocate
    zero ss
    mov  sp, loadaddr  ;# stack pointer starts just below this code
    zero ds
    data32 call protected_mode
.code32
    call a20 ;# set A20 gate to enable access to addresses with 1xxxxx
    cmp  si, 0x7e00 ;# boot from floppy?
    jz   0f  ;# continue if so...
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
    inc  byte ptr cylinder + loadaddr
    mov  cx, nc + loadaddr ;# number of cylinders used
    dec  cx
0:  push cx
    call read
    inc  byte ptr cylinder + loadaddr
    pop  cx
    loop 0b
    data32 call protected_mode
.code32
    mov esi, godd
    jmp start1 ;# start1 is outside of bootsector

.code16
settrap: ;# catch pseudo-GPF, and set EBP as PC-relative pointer
    xor  ebp, ebp ;# clear first or this might not work
    mov  bp, cs ;# get CS segment register
    shl  ebp, 4 ;# shift segment to where it belongs in 32-bit absolute addr
    pop  ax ;# get return address
    push ax ;# we still need to return to it
    ;# note: the following only works if this called from first 256 bytes
    and  ax, 0xff00 ;# clear low 8 bits of address
    mov  bp, ax ;# EBP now contains 32-bit absolute address of 'start'
    add  ax, offset trap - offset start
    mov  [fs:0x0d * 4 + 2], cs ;# FS assumed to be 0
    mov  [fs:0x0d * 4], ax
    ret

read:
;# about to read 0x4800, or 18432 bytes
;# total of 165888 (0x28800) bytes in 9 cylinders, 1.44 MB in 80 cylinders
;# (low 8 bits of) cylinder number is in CH, (6 bit) sector number in CL
    push edx  ;# used for debugging during boot
    mov  ebx, iobuffer
    push ebx
    mov  ax, (2 << 8) + 36  ;# 18 sectors per head, 2 heads
    mov  dx, 0x0000 ;# head 0, drive 0
    mov  ch, [cylinder + loadaddr]
    mov  cl, 1  ;# sector number is 1-based, and we always read from first
    int  0x13
    mov  edx, esi  ;# temporarily store parameter stack pointer in EDX
    pop  esi  ;# load iobuffer
    mov  ecx, 512*18*2/4
    addr32 rep movsd ;# move to ES:EDI location preloaded by caller
    mov  esi, edx  ;# restore parameter stack pointer
    pop  edx
    ret

progress: ;# show progress indicator
    pop  dx  ;# grab return address
    push dx  ;# and put back on stack
shownumber: ;# alternate entry point, preload DX register
    push ax
    push bx
    push cx
    push es
    push 0xb800 ;# video display RAM
    pop  es
    mov  cx, 4  ;# four digit address to display
    mov  bx, upper_right ;# corner of screen
    xor  ax, ax ;# zero AX
0:  mov  al, dl ;# get number as hex digit
    and  al, 0xf
    push bp
    add  bp, ax
    mov  al, cs:[digits + bp]
    pop  bp
    mov  [es:bx], al ;# assumes ES=0xb800, text mode 3 video RAM
    shr  dx, 4 ;# next higher hex digit
    sub  bx, 2 ;# move to previous screen position
    loop 0b
    pop  es ;# restore registers except dx and bp
    pop  cx
    pop  bx
    pop  ax
    ret
digits: .ascii "0123456789abcdef"

trap:  ;# handle interrupt 0xd, the "pseudo GPF"
    pop  bx
0:  inc  bx
    cmp  byte ptr [bx], 0x90 ;# check for nop
    jnz  0b
    push bx
    iret

relocate:  ;# move code from where DOS or BIOS put it, to where we want it
    pop  ax ;# get return address, we'll need to munge it
    push es
    ;# clearing ES unnecessary in Bochs, it's already 0 on bootup
    call progress
    zero es ;# should only be necessary when booting from MSDOS
    call progress
    ;#hlt ;# shows up if you grep halt vmware.log
    mov  edi, loadaddr ;# destination of relocation
    and  ax, 0xff ;# must be called from first 256 bytes!
    add  ax, di ;# correct offset to destination
    mov  bx, [es:0x0d * 4] ;# get trap address
    sub  bx, offset trap - offset start
    xor  esi, esi ;# clear upper 16 bits to avoid GPF and/or wrong location
    mov  si, bx ;# source address
    call progress
    cmp  bx, 0x7c00 ;# is this bootup from floppy?
    jne  5f  ;# nope, color.com launched from MS-DOS
    mov  cx, 512/4 ;# 128 longwords
4:  addr32 rep movsd
    jmp  9f
5:  ;# relocate 64K color.com
    shr  bx, 4 ;# match shift of segment address
    add  bx, [es:0x0d * 4 + 2] ;# complete address, shifted 4 right
    cmp  bx, loadaddr >> 4 ;# see where we are relative to where we want to be
    je   9f ;# same place? done
    mov  cx, 0x10000 / 4 ;# 64K in longwords
    jc   7f ;# we're lower, need to move up
    std  ;# otherwise we're higher, and we move downwards to destination
    jmp  4b
7:  push ax
    mov  ax, ds ;# we need to point to the end of both blocks
    add  ax, 0x1000
    mov  ds, ax
    dec  si
    pop  ax ;# THIS ISN'T DONE, MUST FIX DS, ES, SI, DI
9:  pop  es ;# restore extra segment register
    push ax
    cld  ;# in case we changed direction
    ret

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

setgraphics:
    call unreal_mode
.code16
    call graphicsmode
    data32 call protected_mode
.code32
    ret

;# these must be defined elsewhere before use
seekf:
cmdf:
readyf:
stop:
    ret
