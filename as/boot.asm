.intel_syntax ;# floppy boot segment
;# Floppy boot segment. Modified 7/17/01 for Asus P2B-D Floppy I/O Terry Loveall

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
.ifdef QUESTIONABLE
    .byte 0xc5 ;# in compiled color.com from CM website
;# probably just there from save-system or similar command? just a guess
.else
    .byte 0
.endif
    .byte 0   ;# head, drive
cylinder:
.ifdef QUESTIONABLE
    .byte 1 ;# 1 in compiled color.com from CM website
;# causes load to skip from cylinder 0 directly to cylinder 2,
;# missing bytes 0x4800 to 0x9000 in color.com image
.else
    .byte 0
.endif
    .byte 0   ;# head
    .byte 1   ;# sector
    .byte 2   ;# 512 bytes/sector
    .byte 18  ;# sectors/track
    .byte 0x1b ;# gap
    .byte 0x0ff
.align 4  ;# if you see any crud in disassembly here it shouldn't matter
;# two nonsense bytes in CM's 2001 color.com are 0x8b 0xc0
nc: .long 9 ;# forth+icons+blocks 24-161 ;# number of cylinders, 9 (out of 80)
gdt: .word 0x17
    .long gdt0
.align 8
gdt0: .word 0, 0, 0, 0
    .word 0x0ffff, 0, 0x9a00, 0x0cf ;# code
    .word 0x0ffff, 0, 0x9200, 0x0cf ;# data

;# code is compiled in protected 32-bit mode.
;# hence;#  .org .-2  to fix 16-bit words
;# and 4 hand-assembled instructions.
;# and eax and ax exchanged
;# this code is in real 16-bit mode

.code16
start0:
.ifdef AGP
    mov  ax, 0x4f02 ;# video mode
    mov  bx, vesa ;# hp*vp rgb: 565
.else  # use VBE call to determine RAM address of desired video mode
    mov  ax, 0x4f01 ;# get video mode info
    mov  cx, vesa ;# a 16-bit color linear video mode (5:6:5 rgb)
    mov  di, 0x7e00 ;# use buffer space just past loaded bootsector
    int  0x10
    mov  ax, 0x4f02 ;# set video mode
    mov  bx, cx ;# vesa mode
.endif
    int  0x10
    cli
    xor  ax, ax    ;# move code to 0
.ifdef QUESTIONABLE  # some things in CM's source which can be left out?
    mov  bx, ax
    mov  bx, cs
    mov  ds, bx
    mov  es, ax
    mov  di, ax
    mov  si, ax
.else
    mov  di, ax
    mov  bx, cs
    mov  ds, bx
.endif
    call loc ;# where are we? ip+4*cs
loc: pop  si
    sub  si, offset loc-offset start
    mov  cx, 512/4 ;# only 256 bytes unless...
;# compile as 32-bit code here so it moves longwords and not words
.code32
    rep movsw
;#  jmp  0:relocate
    .byte 0x0ea
    .word relocate-start, 0

relocate: ;# this code is executed from an offset of 0, not 0x7c00
    mov  ds, ax
;#  lgdt fword ptr gdt
    .byte 0x0f, 1, 0x16
    .word gdt-start
    mov  al, 1
    mov  cr0, eax
;#  jmp  8:protected
    .byte 0x0ea
    .word protected-start, 8

protected: ;# now in protected 32-bit mode
    mov  al, 0x10
    mov  ds, eax
    mov  es, eax
    mov  ss, eax
    mov  esp, offset gods ;# assembles as a dword ptr without 'offset'
.ifndef AGP
    push [ds:0x7e28] ;# physical memory pointer returned by VESA call
.endif
    xor  ecx, ecx

a20: mov  al, 0x0d1
    out  0x64, al ;# to keyboard
0:  in   al, 0x64
    and  al, 2
    jnz  0b
    mov  al, 0x4b
    out  0x60, al ;# to keyboard, enable A20

    call dma ;# set up for non-dma floppy access
    shl  ebx, 4
    add  esi, ebx
    cmp  dword ptr [esi], 0x44444444 ;# boot?
    jnz  cold
    mov  cx, 63*0x100-0x80 ;# nope
    rep movsd
    mov  esi, offset godd ;# 0x9f448, 3000 bytes below 0xa0000 (gods)
    jmp  start2

cold: call sense_
    jns  cold
    mov  esi, offset godd ;# 0x9f448, 3000 bytes below 0xa0000 (gods)
    xor  edi, edi ;# cylinder 0 on top of address 0
    mov  cl, byte ptr nc ;# number of cylinders used
0:  push ecx
    call read
    inc dword ptr  cylinder
    pop  ecx
    loop 0b
start2: call stop
    jmp  start1

.equ us, 1000/6
.equ ms, 1000*us
spin: mov  cl, 0x1c
    call onoff
;#  mov  dx, 0x3f2
;#  out  dx, al
0:  call sense_
    jns  0b
    mov dword ptr  cylinder, 0 ;# calibrate
    mov  al, 7
    mov  cl, 2
    call cmd
    mov  ecx, 500*ms
0:  loop 0b
cmdi: call sense_
    js   cmdi
    ret

ready: ;#call delay
    mov  dx, 0x3f4
0:  in   al, dx
.ifdef QUESTIONABLE
    debugout
.endif
    shl  al, 1
    jnc  0b
    lea  edx, [edx+1]
    ret

transfer: mov  cl, 9
cmd: lea  edx, command
    mov  [edx], al
cmd0: push esi
    mov  esi, edx
cmd1: call ready
    jns  0f
    in   al, dx
    jmp  cmd1
0:  lodsb
    out  dx, al
.ifdef QUESTIONABLE
    debugout
.endif
    loop cmd1
    pop  esi
    ret

sense_: mov  al, 8
    mov  ecx, 1
    call cmd
0:  call ready
    jns  0b
    in   al, dx
.ifdef QUESTIONABLE
    debugout
.endif
    and  al, al
;#  cmp  al, 0x80
    ret

seek: call sense_
    jns  seek
    ret

stop: mov  cl, 0x0c ;# motor off
onoff: dup_
    mov  al, cl
    mov  dx, 0x3f2
    out  dx, al
.ifdef QUESTIONABLE
    debugout
.endif
    drop
    ret

dma: mov  word ptr command+1, 0x3a2 ;# l2 s6 u32 ms (e 2)
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

read: call seek
    mov  al, 0x0e6 ;# read normal data
    call transfer
;# about to read 0x4800, or 18432 bytes
;# total of 165888 (0x28800) bytes in 9 cylinders, 1.44 MB in 80 cylinders
;# note that the first call overwrites the cylinder number with 1 from
;# CM's color.com image; that's why it skips from cylinder 0 to 2
    mov  cx, 18*2*512 ;# two heads, 18 sectors/track, 512 bytes/sector
0:  call ready
    in   al, dx
.ifdef QUESTIONABLE
    debugout
.endif
    stosb
    next 0b
    ret

write: call seek
    mov  al, 0x0c5 ;# write data
    call transfer
    mov  cx, 18*2*512 ;#two heads, 18 sectors/track, 512 bytes/sector
0:  call ready
    lodsb
    out  dx, al
.ifdef QUESTIONABLE
    debugout
.endif
    next 0b
    ret

.org 0x1fe ;# mark boot sector
    .word 0x0aa55
;# end of boot sector
    .long 0x44444444 ;# mark color.com

flop: mov  cylinder, al ;# c-cx
    dup_
    mov  dx, 0x3f2
    in   al, dx
.ifdef QUESTIONABLE
    debugout
.endif
    test al, 0x10
    jnz  0f
    jmp  spin
0:  ret

readf: call flop ;# ac-ac
    push edi
    mov  edi, [esi+4]
    shl  edi, 2
    call read
    pop  edi
readf1: drop
    inc  eax
    add  dword ptr [esi], 0x1200
    ret

writef: call flop ;# ac-ac
    push esi
    mov  esi, [esi+4]
    shl  esi, 2
    call write
    pop  esi
    jmp  readf1

seekf: call flop ;# c-c
;#  call delay
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
