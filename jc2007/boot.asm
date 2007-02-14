.intel_syntax ;# floppy boot segment

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
gdt: .word 0x17
    .long gdt0
.align 8 ;# more garbage possibly in disassembly here, ignore it
gdt0: .word 0, 0, 0, 0
    .word 0x0ffff, 0, 0x9a00, 0x0cf ;# code
    .word 0x0ffff, 0, 0x9200, 0x0cf ;# data

.code16
start0:
    mov  ax, 0x4f01 ;# get video mode info
    mov  cx, vesa ;# a 16-bit color linear video mode (5:6:5 rgb)
    mov  di, 0x7e00 ;# use buffer space just past loaded bootsector
    int  0x10
    mov  ax, 0x4f02 ;# set video mode
    mov  bx, cx ;# vesa mode
    int  0x10
.code32
    mov  ds, ax
;#    lgdt qword ptr gdt
    .byte 0x0f, 1, 0x16
    .word gdt-start
    mov  al, 1
    mov  cr0, eax
;#    jmp  8:protected
    .byte 0x0ea
    .word protected-start, 8

protected: ;# now in protected 32-bit mode
    mov  al, 0x10
    mov  ds, eax
    mov  es, eax
    mov  ss, eax
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
    mov  eax, 512*18*2-1 ;# DMA channel 2 (0x47ff)
    call dma
    shl  ebx, 4
    add  esi, ebx

cold:
    mov  esi, offset godd ;# 0x9f448, 3000 bytes below 0xa0000 (gods)
    xor  edi, edi ;# cylinder 0 on top of address 0
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

cmd:
    lea  edx, command
    mov  [edx], al
    push esi
    mov  esi, edx
0:  call ready
    jns  cmd0
    in   al, dx
    jmp  0b
cmd0:
    lodsb
    mov  ah, 0x1e  ;# delay loop in JF2005 code
    out  dx, al
1:
    dec  ah
    jne  1b
    loop 0b
    pop  esi
    ret
sense_: mov  al, 8
    mov  cl, 1
    call cmd
    call ready
    in   al, dx
    and  al, al
;#  cmp  al, 0x80
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
    mov  dword ptr trash, buffer*4 ;# 0x97000 in CM2001, used for DMA?
    mov  al, 0x0c
onoff:
    mov  dx, 0x3f2
    out  dx, al
    ret

dma:
    out  5, al ;# set DMA-1 ch.2 base and current count to 0x47ff
    mov  al, ah
    out  5, al
    mov  eax, buffer*4 ;# 0x97000 in CM2001
    out  4, al ;# set DMA-1 ch.2 base and current address to "trash" buffer
    mov  al, ah
    out  4, al
    shr  eax, 16 ;# load page register value into al (9)
    out  0x81, al ;# set DMA-1 page register 2 = 09
    mov  al, 0xb
    out  0xf, al ;# write all mask bits, address = 0xf, value = 0xb
    mov  word ptr command+1, 0x2a1 ;# 2 6 16 ms (e 2)
    mov  al, 3 ;# timing
    mov  cl, 3
    call cmd
    mov  word ptr command+1, 0
    ret

transfer:
    mov  cl, 9
    call cmd
    inc  byte ptr cylinder
0:  call ready
    jns  0b
    ret

read:
    mov  al, 0x16 ;# read DMA 2
    call seek
    mov  al, 0x0e6 ;# read normal data
    call transfer
;# about to read 0x4800, or 18432 bytes
;# total of 165888 (0x28800) bytes in 9 cylinders, 1.44 MB in 80 cylinders
;# note that the first call overwrites the cylinder number with 1 from
;# CM's color.com image; that's why it skips from cylinder 0 to 2
    push esi
    mov  esi, buffer*4
    mov  ecx, 512*18*2/4
    rep  movsd
    pop  esi  
    ret

;# don't need 'write' till after bootup
    .org 0x1fe
    .word 0x0aa55 ;# mark boot sector
    ;# end of boot sector
    .long 0x44444444 ;# mark color.com

write:
    mov  edi, buffer*4
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
    call flop
    push edi
    mov  edi, eax
0:  push ecx
    call read
    pop  ecx
    next 0b
    pop  edi
readf1:
    call stop
    drop
    ret

save_:
    dup_
    xor  eax, eax 
    dup_
    dup_
    mov  eax, nc

writef:
    call flop
    push esi
    mov  esi, eax
0:  push ecx
    call write
    pop  ecx
    next 0b
    pop  ESI
    jmp  readf1
