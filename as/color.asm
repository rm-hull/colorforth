.intel_syntax ;#colorforth, 2001 jul 22, chuck moore, public domain

;#.model tiny
;#.486p
;#only segment use32
;#assume ds:only

.macro next adr
    dec  ecx
    jnz  \adr
.endm

.macro dup_
    lea  esi, [esi-4]
    mov  [esi], eax
.endm

.macro drop
    lodsd
.endm

;#hp equ 800
;#vp equ 600
;#vesa equ 0x114
.equ hp, 1024
.equ vp, 768
.equ vesa, 0x117
.equ buffer, 604*256
.include "boot.asm" ;# boot boot0 hard

;#   100000 dictionary
;#    a0000 top of return stack
;#    9f800 top of data stack
;#    9d800 free
;#    97000 floppy buffer
;#     4800 source
.equ icons, 12*256*4 ;# 3000
;#     7c00 bios boot sector
;#        0 forth

warm: dup_
start1: call ati0
;#    mov  screen, offset nul
;#    xor  eax, eax
    call show0
    mov dword ptr  forths,  offset ((forth1-forth0)/4)
    mov dword ptr  macros,  offset ((macro1-macro0)/4)
    mov  eax, 18
    call load
    jmp  accept ;# wait for keyhit

.equ gods, 0x28000*4 ;# 0x0a0000
.equ godd, gods-750*4
.equ mains, godd-1500*4
.equ maind, mains-750*4
.align 4
    me: .long god
screen: .long 0 ;# logo

round: call unpause
god:     .long 0 ;# gods-2*4
    call unpause
main:    .long 0 ;# mains-2*4
    jmp  round

pause: dup_
    push esi
    mov  eax, me
    mov  [eax], esp
    add  eax, 4
    jmp  eax

unpause: pop  eax
    mov  esp, [eax]
    mov  me, eax
    pop  esi
    drop
    ret

act: mov  edx, maind-4
    mov  [edx], eax
    mov  eax, mains-4
    pop  [eax]
    sub  eax, 4
    mov  [eax], edx
    mov  main, eax
    drop
    ret

show0: call show
    ret
show: pop  screen ;# pops address of 'ret' just preceding
    dup_
    xor  eax, eax
    call act
0:     call graphic
        call [screen] ;# ret?
        call switch
        inc  eax
        jmp  0b

c_:  mov  esi, godd+4
    ret

mark: mov  ecx, macros
    mov  mk, ecx
    mov  ecx, forths
    mov  mk+4, ecx
    mov  ecx, h
    mov  mk+2*4, ecx
    ret

empty: mov  ecx, mk+2*4
    mov  h, ecx
    mov  ecx, mk+4
    mov  forths, ecx
    mov  ecx, mk
    mov  macros, ecx
    mov dword ptr  class, 0
    ret

mfind: mov  ecx, macros
    push edi
    lea  edi, [macro0-4+ecx*4]
    jmp  0f

find: mov  ecx, forths
    push edi
    lea  edi, [forth0-4+ecx*4]
0: std
    repne scasd
    cld
    pop  edi
    ret

ex1: dec dword ptr  words ;# from keyboard
    jz   0f
        drop
        jmp  ex1
0: call find
    jnz  abort1
        drop
        jmp  [forth2+ecx*4]

execute: mov dword ptr  lit, offset alit
    dup_
    mov  eax, [-4+edi*4]
ex2: and  eax, -020
    call find
    jnz  abort
        drop
        jmp  [forth2+ecx*4]

abort: mov  curs, edi
    shr  edi, 10-2
    mov  blk, edi
abort1: mov  esp, gods
    mov dword ptr  spaces+3*4, offset forthd
    mov dword ptr  spaces+4*4, offset qcompile
    mov dword ptr  spaces+5*4, offset cnum
    mov dword ptr  spaces+6*4, offset cshort
    mov  eax, 057 ;# ?
    call echo_
    jmp  accept

sdefine: pop  adefine
    ret
macro_: call sdefine
macrod: mov  ecx, macros
    inc dword ptr  macros
    lea  ecx, [macro0+ecx*4]
    jmp  0f

forth: call sdefine
forthd: mov  ecx, forths
    inc dword ptr  forths
    lea  ecx, [forth0+ecx*4]
0: mov  edx, [-4+edi*4]
    and  edx, -020
    mov  [ecx], edx
    mov  edx, h
    mov  [forth2-forth0+ecx], edx
    lea  edx, [forth2-forth0+ecx]
    shr  edx, 2
    mov  last, edx
    mov  list, esp
    mov dword ptr  lit, offset adup
    test dword ptr class, -1
    jz   0f
        jmp  [class]
0: ret

cdrop: mov  edx, h
    mov  list, edx
    mov  byte ptr [edx], 0x0ad ;# lodsd
    inc dword ptr  h
    ret

qdup: mov  edx, h
    dec  edx
    cmp  list, edx
    jnz  cdup
    cmp  byte ptr [edx], 0x0ad
    jnz  cdup
        mov  h, edx
        ret
cdup: mov  edx, h
    mov  dword ptr [edx], 0x89fc768d
    mov  byte ptr [4+edx], 06
    add dword ptr  h, 5
    ret

adup: dup_
    ret

var1: dup_
    mov  eax, [4+forth0+ecx*4]
    ret
variable: call forthd
    mov dword ptr  [forth2-forth0+ecx], offset var1
    inc dword ptr  forths ;# dummy entry for source address
    mov  [4+ecx], edi
    call macrod
    mov dword ptr  [forth2-forth0+ecx], offset 0f
    inc dword ptr  macros
    mov  [4+ecx], edi
    inc  edi
    ret
0: call [lit]
    mov  eax, [4+macro0+ecx*4]
    jmp  0f

cnum: call [lit]
    mov  eax, [edi*4]
    inc  edi
    jmp  0f

cshort: call [lit]
    mov  eax, [-4+edi*4]
    sar  eax, 5
0: call literal
    drop
    ret

alit: mov dword ptr lit, offset adup
literal: call qdup
    mov  edx, list
    mov  list+4, edx
    mov  edx, h
    mov  list, edx
    mov  byte ptr [edx], 0x0b8
    mov  [1+edx], eax
    add dword ptr  h, 5
    ret

qcompile: call [lit]
    mov  eax, [-4+edi*4]
    and  eax, -020
    call mfind
    jnz  0f
        drop
        jmp  [macro2+ecx*4]
0: call find
    mov  eax, [forth2+ecx*4]
0: jnz  abort
call_: mov  edx, h
    mov  list, edx
    mov  byte ptr [edx], 0x0e8
    add  edx, 5
    sub  eax, edx
    mov  [-4+edx], eax
    mov  h, edx
    drop
    ret

compile: call [lit]
    mov  eax, [-4+edi*4]
    and  eax, -020
    call mfind
    mov  eax, [macro2+ecx*4]
    jmp  0b

short_: mov dword ptr lit, offset alit
    dup_
    mov  eax, [-4+edi*4]
    sar  eax, 5
    ret

num: mov dword ptr lit, offset alit
    dup_
    mov  eax, [edi*4]
    inc  edi
    ret

comma: mov  ecx, 4
0: mov  edx, h
    mov  [edx], eax
    mov  eax, [esi] ;# drop
    lea  edx, [edx+ecx]
    lea  esi, [esi+4]
    mov  h, edx
;#    drop
    ret

comma1: mov  ecx, 1
    jmp  0b

comma2: mov  ecx, 2
    jmp  0b

comma3: mov  ecx, 3
    jmp  0b

semi: mov  edx, h
    sub  edx, 5
    cmp  list, edx
    jnz  0f
    cmp  byte ptr [edx], 0x0e8
    jnz  0f
        inc  byte ptr [edx] ;# jmp
        ret
0: mov  byte ptr [5+edx], 0x0c3 ;# ret
    inc dword ptr  h
    ret

then: mov  list, esp
    mov  edx, h
    sub  edx, eax
    mov  [-1+eax], dl
    drop
    ret

begin: mov  list, esp
here: dup_
    mov  eax, h
    ret

qlit: mov  edx, h
    lea  edx, [edx-5]
    cmp  list, edx
    jnz  0f
    cmp  byte ptr [edx], 0x0b8
    jnz  0f
        dup_
        mov  eax, list+4
        mov  list, eax
        mov  eax, [1+edx]
        cmp  dword ptr [edx-5], 0x89fc768d ;# dup
        jz   q1
            mov  h, edx
            jmp  cdrop
q1:     add dword ptr  h, -10 ;# flag nz
        ret
0: xor  edx, edx ;# flag z
    ret

less: cmp  [esi], eax
    js   0f ;# flag nz
        xor  ecx, ecx ;# flag z
0: ret

qignore: test dword ptr [-4+edi*4], -020
    jnz  nul
        pop  edi
        pop  edi
nul: ret

jump: pop  edx
    add  edx, eax
    lea  edx, [5+eax*4+edx]
    add  edx, [-4+edx]
    drop
    jmp  edx

load: shl  eax, 10-2
    push edi
    mov  edi, eax
    drop
inter:  mov  edx, [edi*4]
        inc  edi
        and  edx, 017 ;# get only low 4 bits
        call spaces[edx*4]
        jmp  inter

.align 4
 spaces: .long qignore, execute, num
adefine: .long 5+macro_ ;# macrod ?
        .long qcompile, cnum, cshort, compile
        .long short_, nul, nul, nul
        .long variable, nul, nul, nul

   lit: .long adup
    mk: .long 0, 0, 0
     h: .long 0x40000*4
  last: .long 0
 class: .long 0
  list: .long 0, 0
macros: .long 0
forths: .long 0
;#macro0 .long (3 << 4+1)<< 24 ; or
;#       .long ((5 << 4+6)<< 7+0140)<< 17 ; and
;#       .long 0173 << 25 ; +
macro0: .long 0170 << 25 ;# ;
       .long ((0140 << 7+0146)<< 7+0142)<< 11 ;# dup
       .long (((0177 << 7+0140)<< 7+0146)<< 7+0142)<< 4 ;# ?dup
       .long (((0140 << 4+1)<< 4+3)<< 7+0142)<< 10 ;# drop
;#       .long ((6 << 4+7)<< 7+0142)<< 17 ; nip
       .long (((2 << 7+0144)<< 4+4)<< 4+6)<< 13 ;# then
       .long ((((0143 << 4+4)<< 5+025)<< 4+7)<< 4+6)<< 8 ;# begin
macro1: .rept 128 .long 0; .endr
forth0: .long (((0143 << 4+3)<< 4+3)<< 4+2)<< 13 ;# boot
       .long (((027 << 4+5)<< 4+1)<< 5+021)<< 14 ;# warm
       .long ((((0142 << 4+5)<< 7+0146)<< 5+020)<< 4+4)<< 5 ;# pause
       .long ((((021 << 4+5)<< 5+022)<< 4+1)<< 4+3)<< 10 ;# .macro
       .long ((((026 << 4+3)<< 4+1)<< 4+2)<< 7+0144)<< 8 ;# forth
       .long 022 << 27 ;# c
       .long (((020 << 4+2)<< 4+3)<< 7+0142)<< 12 ;# stop
       .long (((1 << 4+4)<< 4+5)<< 7+0140)<< 13 ;# read
       .long ((((027 << 4+1)<< 4+7)<< 4+2)<< 4+4)<< 11 ;# write
       .long (6 << 5+022)<< 23 ;# nc
       .long (((((022 << 4+3)<< 5+021)<< 5+021)<< 4+5)<< 4+6)<< 5;# comman d
       .long (((020 << 4+4)<< 4+4)<< 7+0164)<< 12 ;# seek
       .long ((((1 << 4+4)<< 4+5)<< 7+0140)<< 5+023)<< 8 ;# ready
;#       .long (((022 << 5+024)<< 4+1)<< 4+7)<< 14 ; clri
       .long ((5 << 5+022)<< 4+2)<< 19 ;# act
       .long (((020 << 7+0144)<< 4+3) << 5+027)<< 11 ;# show
       .long (((024 << 4+3)<< 4+5)<< 7+0140)<< 12 ;# load
       .long (((0144 << 4+4)<< 4+1)<< 4+4)<< 13 ;# here
       .long (((0177 << 5+024)<< 4+7)<< 4+2)<< 12 ;# ?lit
       .long (0153 << 7+0176) << 18 ;# 3,
       .long (0152 << 7+0176) << 18 ;# 2,
       .long (0151 << 7+0176) << 18 ;# 1,
       .long 0176 << 25 ;# ,
       .long (((024 << 4+4)<< 5+020)<< 5+020)<< 13 ;# less
       .long (((0162 << 7+0146)<< 5+021)<< 7+0142)<< 6 ;# jump
       .long (((((5 << 5+022)<< 5+022)<< 4+4)<< 7+0142)<< 4+2)<< 3 ;# accept
       .long ((0142 << 4+5)<< 7+0140)<< 14 ;# pad
       .long ((((4 << 4+1)<< 4+5)<< 5+020)<< 4+4)<< 11 ;# erase
       .long (((022 << 4+3)<< 7+0142)<< 5+023)<< 11 ;# copy
       .long (((021 << 4+5)<< 4+1)<< 7+0164)<< 12 ;# mark
       .long (((4 << 5+021)<< 7+0142)<< 4+2)<< 12 ;# empt
       .long (((4 << 5+021)<< 4+7)<< 4+2)<< 15 ;# emit
       .long ((((0140 << 4+7)<< 5+025)<< 4+7)<< 4+2)<< 8 ;# digit
       .long ((((0152 << 4+4)<< 5+021)<< 4+7)<< 4+2)<< 8 ;# 2emit
       .long 0165 << 25 ;# .
       .long (0144 << 7+0165)<< 18 ;# h.
       .long ((0144 << 7+0165)<< 4+6)<< 14 ;# h.n
       .long (022 << 4+1)<< 23 ;# cr
       .long ((((020 << 7+0142)<< 4+5)<< 5+022)<< 4+4)<< 7 ;# space
       .long (((0140 << 4+3)<< 5+027)<< 4+6)<< 12 ;# down
       .long (((4 << 7+0140)<< 4+7)<< 4+2)<< 13 ;# edit
       .long 4 << 28 ;# e
;#       .long (((026 << 4+3)<< 4+6)<< 4+2)<< 15 ; font
       .long (024 << 5+021)<< 22 ;# lm
       .long (1 << 5+021)<< 23 ;# rm
       .long ((((025 << 4+1)<< 4+5)<< 7+0142)<< 7+0144)<< 5 ;# graph ic
       .long (((2 << 4+4)<< 7+0145)<< 4+2)<< 13 ;# text
;#       .long (0153 << 7+0140)<< 18 ; 3d
;#       .long (((((1 << 4+4)<< 4+6)<< 7+0140)<< 4+4)<< 4+1)<< 5 ; render
;#       .long ((((0141 << 4+4)<< 4+1)<< 4+2)<< 4+4)<< 9 ; verte x
;#       .long ((((026 << 4+1)<< 4+3)<< 4+6)<< 4+2)<< 11 ; front
;#       .long ((2 << 4+3)<< 7+0142)<< 17 ; top
;#       .long (((020 << 4+7)<< 7+0140)<< 4+4)<< 12 ; side
       .long ((((0164 << 4+4)<< 5+023)<< 7+0143)<< 4+3)<< 5 ;# keybo ard
       .long (((0140 << 4+4)<< 7+0143)<< 7+0146)<< 7 ;# debu g
       .long (5 << 4+2)<< 24 ;# at
       .long ((0173 << 4+5)<< 4+2)<< 17 ;# +at
       .long (0145 << 5+023)<< 20 ;# xy
       .long ((026 << 4+3)<< 7+0141)<< 16 ;# fov
       .long (((026 << 4+7)<< 5+026)<< 4+3)<< 14 ;# fifo
       .long ((0143 << 4+3)<< 7+0145)<< 14 ;# box
       .long (((024 << 4+7)<< 4+6)<< 4+4)<< 15 ;# line
       .long ((((022 << 4+3)<< 5+024)<< 4+3)<< 4+1)<< 10 ;# color
;#       .long (((022 << 5+024)<< 4+7)<< 7+0142)<< 11 ; clip
       .long (((((3 << 5+022)<< 4+2)<< 4+5)<< 4+6)<< 4+2)<< 7 ;# octant
       .long (020 << 7+0142)<< 20 ;# sp
       .long (((024 << 4+5)<< 5+020)<< 4+2)<< 14 ;# last
       .long (((((0146 << 4+6)<< 7+0142)<< 4+5)<< 5+022))<< 5 ;# unpac k
;#       .long (((0142 << 4+5)<< 5+022)<< 7+0164)<< 9 ; pack
forth1: .rept 512 .long 0; .endr
;#macro2 .long offset cor
;#       .long offset cand
;#       .long offset plus
macro2: .long semi
       .long cdup
       .long qdup
       .long cdrop
;#       .long offset nip
       .long then
       .long begin
       .rept 128 .long 0; .endr
forth2: .long boot
       .long warm
       .long pause
       .long macro_
       .long forth
       .long c_
       .long stop
       .long readf
       .long writef
       .long nc_
       .long cmdf
       .long seekf
       .long readyf
       .long act
       .long show
       .long load
       .long here
       .long qlit
       .long comma3
       .long comma2
       .long comma1
       .long comma
       .long less
       .long jump
       .long accept
       .long pad
       .long erase
       .long copy
       .long mark
       .long empty
       .long emit
       .long edig
       .long emit2
       .long dot10
       .long hdot
       .long hdotn
       .long cr
       .long space
       .long down
       .long edit
       .long e
;#       .long offset font
       .long lms
       .long rms
       .long graphic
       .long text1
;#       .long offset set3d
;#       .long offset render
;#       .long offset vertex
;#       .long offset front
;#       .long offset top_
;#       .long offset side
       .long keyboard
       .long debug
       .long at
       .long pat
       .long xy_
       .long fov_
       .long fifof
       .long box
       .long line
       .long color
;#       .long offset clip
       .long octant
       .long sps
       .long last_
       .long unpack
;#       .long offset pack
       .rept 512 .long 0; .endr

boot: mov  al, 0x0fe ;# reset
    out  0x64, al
    jmp  .

erase: mov  ecx, eax
    shl  ecx, 8
    drop
    push edi
     mov  edi, eax
     shl  edi, 2+8
     xor  eax, eax
     rep stosd
    pop edi
    drop
    ret

;#move: mov  ecx, eax
;#    drop
;#    mov  edi, eax
;#    shl  edi, 2
;#    drop
;#    push esi
;#     mov  esi, eax
;#     shl  esi, 2
;#     rep movsd
;#    pop  esi
;#    drop
;#    ret

copy: cmp  eax, 12
    jc   abort1
    mov  edi, eax
    shl  edi, 2+8
    push esi
     mov  esi, blk
     shl  esi, 2+8
     mov  ecx, 256
     rep movsd
    pop  esi
    mov  blk, eax
    drop
    ret

debug: mov dword ptr  xy,  offset (3*0x10000+(vc-2)*ih+3)
    dup_
    mov  eax, god
    push [eax]
    call dot
    dup_
    pop  eax
    call dot
    dup_
    mov  eax, main
    call dot
    dup_
    mov  eax, esi
    jmp  dot

.equ iw, 16+6
.equ ih, 24+6
.equ hc, hp/iw ;# 46
.equ vc, vp/ih ;# 25
.align 4
xy:  .long 3*0x10000+3
lm:  .long 3
rm:  .long hc*iw ;# 1012
xycr: .long 0
fov: .long 10*(2*vp+vp/2)

nc_: dup_
    mov  eax, (offset nc-offset start)/4
    ret

xy_: dup_
    mov  eax, (offset xy-offset start)/4
    ret

fov_: dup_
    mov  eax, (offset fov-offset start)/4
    ret

sps: dup_
    mov  eax, (offset spaces-offset start)/4
    ret

last_: dup_
    mov  eax, (offset last-offset start)/4
    ret

.include "gen.asm" ;# cce.asm pio.asm ati128.asm ati64.asm gen.asm

.equ yellow, 0x0ffff00
cyan: dup_
    mov  eax, 0x0ffff
    jmp  color
magenta: dup_
    mov  eax, 0x0ff00ff
    jmp  color
silver: dup_
    mov  eax, 0x0c0c0c0
    jmp  color
blue: dup_
    mov  eax, 0x4040ff
    jmp  color
red: dup_
    mov  eax, 0x0ff0000
    jmp  color
green: dup_
    mov  eax, 0x8000ff00
    jmp  color

history: .rept 11 .byte 0; .endr
echo_: push esi
     mov  ecx, 11-1
     lea  edi, history
     lea  esi, [1+edi]
     rep movsb
    pop  esi
    mov  history+11-1, al
    drop
    ret

right: dup_
    mov  ecx, 11
    lea  edi, history
    xor  eax, eax
    rep stosb
    drop
    ret

down: dup_
    xor  edx, edx
    mov  ecx, ih
    div  ecx
    mov  eax, edx
    add  edx, 3*0x10000+0x8000-ih+3
    mov  xy, edx
zero: test eax, eax
    mov  eax, 0
    jnz  0f
        inc  eax
0: ret

blank: dup_
    xor  eax, eax
    mov  xy, eax
    call color
    dup_
    mov  eax, hp
    dup_
    mov  eax, vp
    jmp  box

top: mov  ecx, lm
    shl  ecx, 16
    add  ecx, 3
    mov  xy, ecx
    mov  xycr, ecx
    ret

qcr: mov  cx, word ptr xy+2
    cmp  cx, word ptr rm
    js   0f
cr: mov  ecx, lm
    shl  ecx, 16
    mov  cx, word ptr xy
    add  ecx, ih
    mov  xy, ecx
0: ret

lms: mov  lm, eax
    drop
    ret

rms: mov  rm, eax
    drop
    ret

at: mov  word ptr xy, ax
    drop
    mov  word ptr xy+2, ax
    drop
    ret

pat: add  word ptr xy, ax
    drop
    add  word ptr xy+2, ax
    drop
    ret

;#cl1: xor  eax, eax
;#    mov  [esi], eax
;#    ret
;#clip: movsx edx, word ptr xy
;#    cmp  edx, vp
;#    jns  cl1
;#    add  eax, edx
;#    js   cl1
;#    test edx, edx
;#    jns  0f
;#        xor  edx, edx
;#@@: cmp  eax, vp
;#    js   0f
;#        mov  eax, vp
;#@@: sub  eax, edx
;#    mov  word ptr xy, dx
;#    movsx edx, word ptr xy+2
;#    cmp  edx, hp
;#    jns  cl1
;#    add  [esi], edx
;#    js   cl1
;#    test edx, edx
;#    jns  0f
;#        xor  edx, edx
;#@@: cmp  dword ptr [esi], hp
;#    js   0f
;#        mov  dword ptr [esi], hp
;#@@: sub  [esi], edx
;#    mov  word ptr xy+2, dx
;#    ret

octant: dup_
    mov  eax, 0x43 ;# poly -last y+ x+ ;0x23 ; last y+ x+
    mov  edx, [4+esi]
    test edx, edx
    jns  0f
        neg  edx
        mov  [4+esi], edx
        xor  al, 1
0: cmp  edx, [esi]
    jns  0f
        xor  al, 4
0: ret

;# keyboard
eight: add  edi, 12
    call four
    call space
    sub  edi, 16
four: mov  ecx, 4
four1:  push ecx
        dup_
        xor  eax, eax
        mov  al, [4+edi]
        inc  edi
        call emit
        pop  ecx
        next four1
    ret

stack: mov  edi, godd-4
0: mov  edx, god
    cmp  [edx], edi
    jnc  0f
        dup_
        mov  eax, [edi]
        sub  edi, 4
        call qdot
        jmp  0b
0: ret

keyboard: call text1
    mov  edi, board
    dup_
    mov  eax, keyc
    call color
    mov dword ptr  rm, hc*iw
    mov dword ptr  lm, hp-9*iw+3
    mov dword ptr  xy, (hp-9*iw+3)*0x10000+vp-4*ih+3
    call eight
    call eight
    call eight
    call cr
    add dword ptr  xy, 4*iw*0x10000
    mov  edi, shift
    add  edi, 4*4-4
    mov  ecx, 3
    call four1
    mov dword ptr  lm, 3
    mov  word ptr xy+2, 3
    call stack
    mov  word ptr xy+2, hp-(11+9)*iw+3
    lea  edi, history-4
    mov  ecx, 11
    jmp  four1

alpha: .byte 015, 012,  1 , 014
      .byte 024,  2 ,  6 , 010
      .byte 023, 011, 017, 021
      .byte 022, 013, 016,  7
      .byte  5 ,  3 ,  4 , 026
      .byte 027, 044, 025, 020
graphics: .byte 031, 032, 033,  0
         .byte 034, 035, 036, 030
         .byte 037, 040, 041, 057
         .byte 051, 050, 052, 054 ;# : ; ! @
         .byte 046, 042, 045, 056 ;# z j . ,
         .byte 055, 047, 053, 043 ;# * / + -
numbers: .byte 031, 032, 033,  0
        .byte 034, 035, 036, 030
        .byte 037, 040, 041,  0
        .byte  0,   0 ,  0 ,  0
        .byte  0,   0 ,  0 ,  0
        .byte  0,   0 ,  0 ,  0
octals: .byte 031, 032, 033,  0
       .byte 034, 035, 036, 030
       .byte 037, 040, 041,  0
       .byte  0 ,  5 , 023, 012
       .byte  0 , 020,  4 , 016
       .byte  0 ,  0 ,  0 ,  0
letter: cmp  al, 4
    js   0f
        mov  edx, board
        mov  al, [edx][eax]
0: ret

keys: .byte 16, 17, 18, 19,  0,  0,  4,  5 ;# 20
     .byte  6,  7,  0,  0,  0,  0, 20, 21
     .byte 22, 23,  0,  0,  8,  9, 10, 11 ;# 40
     .byte  0,  0,  0,  0, 24, 25, 26, 27
     .byte  0,  1, 12, 13, 14, 15,  0,  0 ;# 60 n
     .byte  3,  2 ;# alt space
key: dup_
    xor  eax, eax
0:     call pause
        in   al, 0144
        test al, 1
        jz   0b
    in   al, 0140
    test al, 0360
    jz   0b
    cmp  al, 072
    jnc  0b
    mov  al, [keys-020+eax]
    ret

.align 4
graph0: .long nul0, nul0, nul0, alph0
       .byte  0 ,  0 ,  5 , 0 ;#     a
graph1: .long word0, x, lj, alph
       .byte 025, 045,  5 , 0 ;# x . a
alpha0: .long nul0, nul0, number, star0
       .byte  0 , 041, 055, 0 ;#   9 *
alpha1: .long word0, x, lj, graph
       .byte 025, 045, 055, 0 ;# x . *
 numb0: .long nul0, minus, alphn, octal
       .byte 043,  5 , 016, 0 ;# - a f
 numb1: .long number0, xn, endn, number0
       .byte 025, 045,  0 , 0 ;# x .

board:   .long alpha-4
shift:   .long alpha0
base:    .long 10
current: .long decimal
keyc:    .long yellow
chars:   .long 1
aword:   .long ex1
anumber: .long nul
words:   .long 1

nul0: drop
    jmp  0f
accept:
acceptn: mov dword ptr  shift, offset alpha0
    lea  edi, alpha-4
accept1: mov  board, edi
0: call key
    cmp  al, 4
    jns  first
    mov  edx, shift
    jmp  dword ptr [edx+eax*4]

bits: .byte 28
0: add  eax, 0120
    mov  cl, 7
    jmp  0f
pack: cmp  al, 020
    jnc  0b
        mov  cl, 4
        test al, 010
        jz   0f
        inc  ecx
        xor  al, 030
0: mov  edx, eax
    mov  ch, cl
0: cmp  bits, cl
    jnc  0f
        shr  al, 1
        jc   full
        dec  cl
        jmp  0b
0: shl  dword ptr [esi], cl
    xor  [esi], eax
    sub  bits, cl
    ret

lj0: mov  cl, bits
    add  cl, 4
    shl  dword ptr [esi], cl
    ret

lj: call lj0
    drop
    ret

full: call lj0
    inc dword ptr  words
    mov dword ptr  bits, 28
    sub  bits, ch
    mov  eax, edx
    dup_
    ret

x:  call right
    mov  eax, words
    lea  esi, [eax*4+esi]
    drop
    jmp  accept

word_: call right
    mov dword ptr  words, 1
    mov dword ptr  chars, 1
    dup_
    mov  dword ptr [esi], 0
    mov dword ptr  bits, 28
word1:  call letter
        jns  0f
            mov  edx, shift
            jmp  dword ptr [edx+eax*4]
0:     test al, al
        jz   word0
        dup_
        call echo_
        call pack
        inc dword ptr  chars
word0:  drop
        call key
        jmp  word1

decimal: mov dword ptr  base, 10
    mov dword ptr  shift, offset numb0
    mov dword ptr  board, offset numbers-4
    ret

hex: mov dword ptr  base, 16
    mov dword ptr  shift, offset numb0 ;# oct0
    mov dword ptr  board, offset octals-4
    ret

octal: xor dword ptr current, (offset decimal-offset start) xor (offset hex-offset start)
    xor  byte ptr numb0+18, 041 xor 016 ;# f vs 9
    call current
    jmp  number0

xn: drop
    drop
    jmp  acceptn

;#      .byte  0,  0,  0,  0
digit: .byte 14, 10,  0,  0
      .byte  0,  0, 12,  0,  0,  0, 15,  0
      .byte 13,  0,  0, 11,  0,  0,  0,  0
      .byte  0,  1,  2,  3,  4,  5,  6,  7
      .byte  8,  9
sign: .byte 0
minus: ;# mov  al, 043 ; -
    mov  sign, al
    jmp  number2

number0: drop
    jmp  number3
number: call current
    mov dword ptr  sign, 0
    xor  eax, eax
number3: call key
    call letter
    jns  0f
        mov  edx, shift
        jmp  dword ptr [edx+eax*4]
0: test al, al
    jz   number0
    mov  al, [digit-4+eax]
    test dword ptr sign, 037
    jz   0f
        neg  eax
0: mov  edx, [esi]
    imul edx, base
    add  edx, eax
0: mov  [esi], edx
number2: drop
    mov dword ptr  shift, offset numb1
    jmp  number3

endn: drop
    call [anumber]
    jmp  acceptn

alphn: drop
alph0: mov dword ptr  shift, offset alpha0
    lea  edi, alpha-4
    jmp  0f
star0: mov dword ptr  shift, offset graph0
    lea  edi, graphics-4
0: drop
    jmp  accept1

alph: mov dword ptr  shift, offset alpha1
    lea  edi, alpha-4
    jmp  0f
graph: mov dword ptr  shift, offset graph1
    lea  edi, graphics-4
0: mov  board, edi
    jmp  word0

first: add dword ptr  shift, 4*4+4
    call word_
    call [aword]
    jmp  accept

hicon: .byte 030, 031, 032, 033, 034, 035, 036, 037
      .byte 040, 041,  5 , 023, 012, 020,  4 , 016
edig1: dup_
edig: push ecx
     mov  al, hicon[eax]
     call emit
    pop  ecx
    ret

odig: rol  eax, 4
    dup_
    and  eax, 0x0f
    ret

hdotn: mov  edx, eax
    neg  eax
    lea  ecx, [32+eax*4]
    drop
    rol  eax, cl
    mov  ecx, edx
    jmp  0f
hdot: mov  ecx, 8
0:     call odig
        call edig
        next 0b
    drop
    ret

dot: mov  ecx, 7
0:     call odig
        jnz  @h
        drop
        next 0b
    inc  ecx
0:     call odig
@h1:    call edig
        next 0b
    call space
    drop
    ret
@h: inc  ecx
    jmp  @h1

qdot: cmp dword ptr  base, 10
    jnz  dot
dot10: mov  edx, eax
    test edx, edx
    jns  0f
        neg  edx
        dup_
        mov  eax, 043
        call emit
0: mov  ecx, 8
0:     mov  eax, edx
        xor  edx, edx
        div dword ptr  tens[ecx*4]
        test eax, eax
        jnz  d_1
        dec  ecx
        jns  0b
    jmp  d_2
0:     mov  eax, edx
        xor  edx, edx
        div dword ptr  tens[ecx*4]
d_1:    call edig1
        dec  ecx
        jns  0b
d_2: mov  eax, edx
    call edig1
    call space ;# spcr
    drop
    ret

unpack: dup_
    test eax, eax
    js   0f
        shl  dword ptr [esi], 4
        rol  eax, 4
        and  eax, 7
        ret
0: shl  eax, 1
    js   0f
        shl  dword ptr [esi], 5
        rol  eax, 4
        and  eax, 7
        xor  al, 010
        ret
0: shl  dword ptr [esi], 7
    rol  eax, 6
    and  eax, 077
    sub  al, 020
    ret

qring: dup_
    inc  dword ptr [esi]
    cmp  curs, edi ;# from abort, insert
    jnz  0f
        mov  curs, eax
0: cmp  eax, curs
    jz   ring
    jns  0f
        mov  pcad, edi
0: drop
    ret

ring: mov  cad, edi
    sub dword ptr  xy, iw*0x10000 ;# bksp
    dup_
    mov  eax, 0x0e04000
    call color
    mov  eax, 060
    mov  cx, word ptr xy+2
    cmp  cx, word ptr rm
    js   0f
        call emit
        sub dword ptr  xy, iw*0x10000 ;# bksp
        ret
0: jmp  emit

rw: mov  cx, word ptr xy+2
    cmp  cx, word ptr lm
    jz   0f
        call cr
0: call red
    jmp  type_

gw: call green
    jmp  type_
mw: call cyan
    jmp  type_
ww: dup_
    mov  eax, yellow
    call color
    jmp  type_

type0: sub dword ptr  xy, iw*0x10000 ;# call bspcr
    test dword ptr [-4+edi*4], -020
    jnz  type1
        dec  edi
        mov  lcad, edi
        call space
        call qring
        pop  edx ;# .end of block
        drop
        jmp  keyboard

cap: call white
    dup_
    mov  eax, [-4+edi*4]
    and  eax, -020
    call unpack
    add  al, 48
    call emit
    jmp  type2

caps: call white
    dup_
    mov  eax, [-4+edi*4]
    and  eax, -020
0:     call unpack
        jz   0f
        add  al, 48
        call emit
        jmp  0b

text: call white
type_:
type1: dup_
    mov  eax, [-4+edi*4]
    and  eax, -020
type2:  call unpack
        jz   0f
        call emit
        jmp  type2
0: call space
    drop
    drop
    ret

gsw: mov  edx, [-4+edi*4]
    sar  edx, 5
    jmp  gnw1

var: call magenta
    call type_
gnw: mov  edx, [edi*4]
    inc  edi
gnw1: dup_
    mov  eax, 0x0f800 ;# green
    cmp dword ptr  bas, offset dot10
    jz   0f
        mov  eax, 0x0c000 ;# dark green
    jmp  0f

sw: mov  edx, [-4+edi*4]
    sar  edx, 5
    jmp  nw1

nw: mov  edx, [edi*4]
    inc  edi
nw1: dup_
    mov  eax, yellow
    cmp dword ptr  bas, offset dot10
    jz   0f
        mov  eax, 0x0c0c000 ;# dark yellow
0: call color
    dup_
    mov  eax, edx
    jmp  [bas]

refresh: call show
    call blank
    call text1
    dup_            ;# counter
    mov  eax, lcad
    mov  cad, eax ;# for curs beyond .end
    xor  eax, eax
    mov  edi, blk
    shl  edi, 10-2
    mov  pcad, edi ;# for curs=0
ref1:   test dword ptr [edi*4], 0x0f
        jz   0f
            call qring
0:     mov  edx, [edi*4]
        inc  edi
        mov dword ptr  bas, offset dot10
        test dl, 020
        jz   0f
            mov dword ptr  bas, offset dot
0:     and  edx, 017
        call display[edx*4]
        jmp  ref1

.align 4
display: .long type0, ww, nw, rw
        .long gw, gnw, gsw, mw
        .long sw, text, cap, caps
        .long var, nul, nul, nul
tens: .long 10, 100, 1000, 10000, 100000, 1000000
     .long 10000000, 100000000, 1000000000
bas: .long dot10
blk:    .long 18
curs:   .long 0
cad:    .long 0
pcad:   .long 0
lcad:   .long 0
trash:  .long buffer*4
ekeys: .long nul, del, eout, destack
      .long act1, act3, act4, shadow
      .long mcur, mmcur, ppcur, pcur
      .long mblk, actv, act7, pblk
      .long nul, act11, act10, act9
      .long nul, nul, nul, nul
ekbd0: .long nul, nul, nul, nul
     .byte 025, 045,  7 ,  0  ;# x  .  i
ekbd: .byte 017,  1 , 015, 055 ;# w  r  g  *
     .byte 014, 026, 020,  1  ;# l  u  d  r
     .byte 043, 011, 012, 053 ;# -  m  c  +
     .byte  0 , 070, 072,  2  ;#    s  c  t
     .byte  0 ,  0 ,  0 ,  0
     .byte  0 ,  0 ,  0 ,  0
actc: .long yellow, 0, 0x0ff0000, 0x0c000, 0, 0, 0x0ffff
     .long 0, 0x0ffffff, 0x0ffffff, 0x0ffffff, 0x8080ff
vector: .long 0
action: .byte 1

act1: mov  al, 1
    jmp  0f
act3: mov  al, 3
    jmp  0f
act4: mov  al, 4
    jmp  0f
act9: mov  al, 9
    jmp  0f
act10: mov  al, 10
    jmp  0f
act11: mov  al, 11
    jmp  0f
act7: mov  al, 7
0: mov  action, al
    mov  eax, [actc-4+eax*4]
    mov dword ptr  aword, offset insert
actn: mov  keyc, eax
    pop  eax
    drop
    jmp  accept

actv: mov dword ptr  action, 12
    mov  eax, 0x0ff00ff ;# magenta
    mov dword ptr  aword, offset 0f
    jmp  actn

0: dup_
    xor  eax, eax
    inc dword ptr  words
    jmp  insert

mcur: dec dword ptr  curs
    jns  0f
pcur: inc dword ptr  curs
0: ret

mmcur: sub dword ptr  curs, 8
    jns  0f
        mov dword ptr  curs, 0
0: ret
ppcur: add dword ptr  curs, 8
    ret

pblk: add dword ptr  blk, 2
    add  dword ptr [esi], 2
    ret
mblk: cmp dword ptr  blk, 20
    js   0f
        sub dword ptr  blk, 2
        sub  dword ptr [esi], 2
0: ret

shadow: xor dword ptr  blk, 1
    xor  dword ptr [esi], 1
    ret

e0: drop
    jmp  0f

edit: mov  blk, eax
    drop
e:  dup_
    mov  eax, blk
    mov dword ptr  anumber, offset format
    mov  byte ptr alpha0+4*4, 045 ;# .
    mov dword ptr  alpha0+4, offset e0
    call refresh
0: mov dword ptr  shift, offset ekbd0
    mov dword ptr  board, offset ekbd-4
    mov dword ptr  keyc, yellow
0:     call key
        call ekeys[eax*4]
        drop
        jmp  0b

eout: pop  eax
    drop
    drop
    mov dword ptr  aword, offset ex1
    mov dword ptr  anumber, offset nul
    mov  byte ptr alpha0+4*4, 0
    mov dword ptr  alpha0+4, offset nul0
    mov dword ptr  keyc, yellow
    jmp  accept

destack: mov  edx, trash
    cmp  edx, buffer*4
    jnz  0f
        ret
0: sub  edx, 2*4
    mov  ecx, [edx+1*4]
    mov  words, ecx
0:     dup_
        mov  eax, [edx]
        sub  edx, 1*4
        next 0b
    add  edx, 1*4
    mov  trash, edx

insert0: mov  ecx, lcad  ;# room available?
     add  ecx, words
     xor  ecx, lcad
     and  ecx, -0x100
     jz   insert1
         mov  ecx, words ;# no
0:          drop
             next 0b
         ret
insert1: push esi
     mov  esi, lcad
     mov  ecx, esi
     dec  esi
     mov  edi, esi
     add  edi, words
     shl  edi, 2
     sub  ecx, cad
     js   0f
         shl  esi, 2
         std
         rep movsd
         cld
0: pop  esi
    shr  edi, 2
    inc  edi
    mov  curs, edi ;# like abort
    mov  ecx, words
0:     dec  edi
        mov  [edi*4], eax
        drop ;# requires cld
        next 0b
    ret

insert: call insert0
    mov  cl, action
    xor  [edi*4], cl
    jmp  accept

format: test dword ptr action, 012 ;# ignore 3 and 9
    jz   0f
        drop
        ret
0: mov  edx, eax
    and  edx, 0x0fc000000
    jz   0f
        cmp  edx, 0x0fc000000
        jnz  format2
0: shl  eax, 5
    xor  al, 2 ;# 6
    cmp dword ptr  action, 4
    jz   0f
        xor  al, 013 ;# 8
0: cmp dword ptr  base, 10
    jz   0f
        xor  al, 020
0: mov dword ptr  words, 1
    jmp  insert

format2: dup_
    mov  eax, 1 ;# 5
    cmp dword ptr  action, 4
    jz   0f
        mov  al, 3 ;# 2
0: cmp dword ptr  base, 10
    jz   0f
        xor  al, 020
0: xchg eax, [esi]
    mov dword ptr  words, 2
    jmp  insert

del: call enstack
    mov  edi, pcad
    mov  ecx, lcad
    sub  ecx, edi
    shl  edi, 2
    push esi
     mov  esi, cad
     shl  esi, 2
     rep movsd
    pop  esi
    jmp  mcur

enstack: dup_
    mov  eax, cad
    sub  eax, pcad
    jz   ens
      mov  ecx, eax
      xchg eax, edx
      push esi
       mov  esi, cad
       lea  esi, [esi*4-4]
       mov  edi, trash
0:      std
         lodsd
         cld
         stosd
         next 0b
       xchg eax, edx
       stosd
       mov  trash, edi
    pop  esi
ens: drop
    ret

pad: pop  edx
    mov  vector, edx
    add  edx, 28*5
    mov  board, edx
    sub  edx, 4*4
    mov  shift, edx
0:     call key
        mov  edx, vector
        add  edx, eax
        lea  edx, [5+eax*4+edx]
        add  edx, [-4+edx]
        drop
        call edx
        jmp  0b

.org (0x1200-1)*4
    .long 0
.end start
