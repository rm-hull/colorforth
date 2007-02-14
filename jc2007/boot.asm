.intel_syntax ;# floppy boot segment
;# relocate past BIOS interrupt table (0x400 bytes) and floppy IO buffer
.equ iobuffer, 0x400
.equ buffersize, 0x4800
.equ moveto, iobuffer + buffersize
.org 0 ;# actually 7c00
start: jmp  start0
    nop
    .ascii "cmcf 1.0"
    .word 512     ;# bytes/sector
    .byte 1       ;# sector/cluster
    .word 1       ;# sector reserved
    .byte 2       ;# fats
    .word 16*14   ;# root directory entries
    .word 80*2*18 ;# sectors
    .byte 0x0f0    ;# media
    .word 9       ;# sectors/fat
    .word 18      ;# sectors/track
    .word 2       ;# heads
    .long 0       ;# hidden sectors
    .long 80*2*18 ;# sectors again
    .byte 0       ;# drive

command:
    .byte 0
    .byte 0   ;# head, drive
cylinder:
    .byte 0
    .byte 0   ;# head
    .byte 1   ;# sector
    .byte 2   ;# 512 bytes/sector
    .byte 18  ;# sectors/track
    .byte 0x1b ;# gap
    .byte 0x0ff
.align 4
nc: .long 9 ;# forth+icons+blocks 24-161 ;# number of cylinders, 9 (out of 80)
gdt: .word start0 - gdt0 - 1
    .long gdt0 + moveto
.align 8 ;# more garbage possibly in disassembly here, ignore it
gdt0: .word 0, 0, 0, 0 ;# null descriptor, not used
    .word 0x0ffff, 0, 0x9a00, 0x0cf ;# code, linear addressing from 0 to 4gb
    .word 0x0ffff, 0, 0x9200, 0x0cf ;# data, linear addressing from 0 to 4gb
    .word 0x0ffff, 0, 0x9a00, 0x000 ;# code, byte-granular, 16-bit
.code16
start0:
    mov  ax, 0x4f01 ;# get video mode info
    mov  cx, vesa ;# a 16-bit color linear video mode (5:6:5 rgb)
    mov  di, 0x7e00 ;# use buffer space just past loaded bootsector
    int  0x10
    mov  ax, 0x4f02 ;# set video mode
    mov  bx, cx ;# vesa mode
    int  0x10
    cli  ;# disable interrupts until we are set up to handle them (if ever)
    mov  ax, moveto  ;# move code past real mode interrupt table
    mov  di, ax
    mov  bx, cs
    mov  ds, bx
    xor  bx, bx  ;# zero out ES segment register for move to ES:EDI
    mov  es, bx  ;# not strictly necessary, BIOS zeroes it anyway
    call loc ;# where are we? ip+4*cs
loc: pop  si
    sub  si, offset loc-offset start
    mov  cx, 512/4 ;# only 256 bytes unless...
;# compile as 32-bit code here so it moves longwords and not words
    data32 rep movsw
    jmp 0:offset relocate + moveto
relocate: ;# this code is executed from an offset of 0, not 0x7c00
    mov  ds, bx ;# offset from zero
    lgdt [gdt + moveto]
    mov  al, 1
    mov  cr0, eax
    jmp  8: offset protected + moveto
.code32
protected: ;# now in protected 32-bit mode
    mov  bl, 0x10 ;# ebx zeroed above
    mov  ds, ebx
    mov  es, ebx
    mov  ss, ebx
    mov  esp, offset gods ;# assembles as a dword ptr without 'offset'
    push [ds:0x7e28] ;# physical memory pointer returned by VESA call
    xor  ecx, ecx
a20:
    mov  al, 0x0d1
    out  0x64, al ;# to keyboard
0:  in   al, 0x64
    and  al, 2
    jnz  0b
    mov  al, 0x4b
    out  0x60, al ;# to keyboard, enable A20
    jmp  0x18:offset sixteenbit + moveto ;# back to 16-bit protected mode
sixteenbit:
    mov  eax, cr0
    and  al, 0xfe ;# zero the PE bit in CR0 register
    mov  cr0, eax
    jmp  0:offset cold + moveto ;# far JMP puts us in unreal mode
cold:
.code16 ;# need 32-bit code prefix for 32-bit operations
    sti  ;# reenable interrupts
    addr32 mov esi, offset godd ;# 0x9f448, 3000 bytes below 0xa0000 (gods)
    mov edi, moveto ;# cylinder 0 overwrites this relocated bootcode
    ;# make sure we don't depend on any of the data we've modified since boot
    call read
    inc byte ptr cylinder
    mov  cl, byte ptr nc ;# number of cylinders used
    dec  cl
0:  push ecx
    call read
    pop  ecx
    loop 0b
start2:
    call stop
    jmp  start1 ;# start1 is outside of bootsector
.equ us, 1000/6
.equ ms, 1000*us
spin:
    mov  al, 0x1c
    call onoff
    mov  ecx, 400*ms ;# what processor speed was this set for?
0:  loop 0b  ;# damn but I hate busy-waits (jc)
    mov  al, 7 ;# recalibrate command
    mov  cl, 2
    jmp  cmdi

ready: ;#call delay
    mov  dx, 0x3f4
0:  in   al, dx
    shl  al, 1
    jnc  0b
    lea  edx, [edx+1] ;# doesn't affect flags as INC would
    ret

transfer: mov  cl, 9
cmd:
    lea  edx, command
    mov  [edx], al
cmd0:
    push esi
    mov  esi, edx
cmd1:
    call ready
    jns  0f
    in   al, dx
    jmp  cmd1
0:  lodsb
    out  dx, al
    loop cmd1
    pop  esi
    ret

seek:
    out 0xb, al
0:  call sense_
    jns  0b
    mov  al, 0xf
    mov  cl, 3
cmdi:
    call cmd
0:  call sense_
    jz   0b
    ret

stop:
    mov  dword ptr trash, offset buffer ;# initialize edit buffer
    mov  al, 0x0c
onoff:
    mov  dx, 0x3f2
    out  dx, al
    ret

dma:
    mov  word ptr command+1, 0x3a2 ;# l2 s6 u32 ms (e 2)
    mov  al, 3 ;# timing
    mov  cl, 3
    call cmd
    mov  word ptr command+1, 0x7000 ;# +seek -fifo -poll
    mov  al, 0x13 ;# configure
    mov  cl, 4
    call cmd
;# the following instruction clears the cylinder number among other things
    mov  dword ptr command, ecx ;# 0
    ret

read:
;# about to read 0x4800, or 18432 bytes
;# total of 165888 (0x28800) bytes in 9 cylinders, 1.44 MB in 80 cylinders
    mov  ebx, iobuffer
    push ebx  ;# needs to be 32 bits for xchg with esi below
    mov  ax, 2 << 8 + 18  ;# 18 sectors per head
    mov  dx, 0x0000 ;# head 0, drive 0
    xor  cx, cx
    mov  cl, [moveto + cylinder]
    shl  cx, 6  ;# put cylinder number into high 10 bits, sector = 0
    push cx
    int  0x13
    mov  ax, 2 << 8 + 18  ;# 18 sectors per head
    mov  dx, 0x0100 ;# head 1, drive 0
    pop  cx
    int  0x13
    xchg esi, [esp]  ;# save ESI (parameter stack) register and load iobuffer
    mov  ecx, 512*18*2/4
    rep  movsd ;# move to ES:EDI location preloaded by caller
    pop  esi  ;# restore parameter stack pointer
    ret

;# don't need 'write' till after bootup
    .org 0x1fe
    .word 0x0aa55 ;# mark boot sector
    ;# end of boot sector
    .long 0x44444444 ;# mark color.com

write:
    mov  edi, iobuffer
    mov  ecx, 512*18*2/4
    rep  movsd
    mov  al, 0x1a ;# write DMA 2
    call seek
    mov  al, 0xc5
    jmp  transfer

flop:
    dup_
    call spin
    drop
    mov  ecx, eax
    drop
    mov  cylinder, al
    drop
    shl  eax, 2
    ret

readf:
    call flop ;# ac-ac
    push edi
    mov  edi, [esi+4]
    shl  edi, 2
    call read
    pop  edi
readf1:
    drop
    inc  eax
    add  dword ptr [esi], 0x1200
    ret

writef:
    call flop ;# ac-ac
    push esi
    mov  esi, [esi+4]
    shl  esi, 2
    call write
    pop  esi
    jmp  readf1

seekf:
    call flop ;# c-c
    call seek
    mov  al, 0x0f
    mov  cl, 3
    call cmd
    call cmdi
    drop
    ret

cmdf: mov  ecx, eax ;# an
    drop
    lea  edx, [eax*4]
    call cmd0
    drop
    ret

readyf: dup_
    call ready
    drop
    ret
