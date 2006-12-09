.intel_syntax ;#generic graphics

;# VESA mode numbers and screen sizes,
;# from http://www.mat.univie.ac.at/~gerald/laptop/vesafb.txt
;#    | 640x480  800x600  1024x768 1280x1024
;#----+-------------------------------------
;#256 |  0x101    0x103    0x105    0x107   
;#32k |  0x110    0x113    0x116    0x119   
;#64k |  0x111    0x114    0x117    0x11A   
;#16M |  0x112    0x115    0x118    0x11B   
.align 4
;# top of RAM is 0x2000000 with 32 megs; framebuffer is just below this
;# multiply vp (vertical pixels) by hp (horizontal pixels) by 2 bytes (16 bits)
;# to determine the location of the framebuffer
frame: .long 0x2000000-hp*vp*2 ;# 32 m
.ifdef QUESTIONABLE ;# match CM2001 color.com binary
displ: .long 0x0f5000000
fore:  .long 0x0f7c0
xc:    .long 0x0327
yc:    .long 0x02e5
.else
displ: .long 0x0f0000000 ;# fujitsu (physical address of video memory)
fore:  .long 0x0f7de ;# half-brightness white in 565 color mode
xc:    .long 0
yc:    .long 0
.endif

rgb: ror  eax, 8
    shr  ax, 2
    ror  eax, 6
    shr  al, 3
    rol  eax, 6+5
    and  eax, 0x0f7de
    ret

white: dup_
    mov  eax, 0x0ffffff
color: call rgb
    mov  fore, eax
    drop
    ret

.ifdef AGP # from CM's 2001 version at colorforth.com
north: mov  edx, 0x0cf8
    out  dx, eax
    add  edx, 4
    in   eax, dx
    ret

dev: mov  eax, 0x80001008 ;# find display, start at device 2
    mov  ecx, 31-1 ;# .end with agp: 10008, bus 1, dev 0
0:     dup_
        call north
        and  eax, 0x0ff000000
        cmp  eax, 0x3000000
        drop
        jz   0f
        add  eax, 0x800
        next 0b
0: ret

ati0: call dev
    or   dword ptr [eax-4], 2 ;# enable memory
    add  al, 0x24-8 ;# look for prefetch
    mov  cl, 5
0:     dup_
        call north
        xor  al, 8
        jz   0f
        drop
        sub  eax, 4
        next 0b
    dup_
    call north
    and  eax, 0x0fffffff0
0: mov  displ, eax
    drop
    ret
.endif # AGP 

fifof: drop
graphic: ret

switch:
;#    dup_
    push esi
    mov  esi, frame
    push edi
    mov  edi, displ ;# 0x0f2000000 emonster nvidia
;#    xor  eax, eax
    mov  ecx, hp*vp/2
;#@@:     lodsd
;#        add  eax, [edi]
;#        rcr  eax, 1
;#        and  eax, 0x0f7def7de
;#        stosd
;#        next 0b
    rep movsd
    pop  edi
    pop  esi
;#    drop
    jmp  pause

clip: mov  edi, xy
    mov  ecx, edi
    test cx, cx
    jns  0f
        xor  ecx, ecx
0: and  ecx, 0x0ffff
    mov  yc, ecx
    imul ecx, hp*2
;#    shl  ecx, 10+1
    sar  edi, 16
    jns  0f
        xor  edi, edi
0: mov  xc, edi
    lea  edi, [edi*2+ecx]
    add  edi, frame
    ret

bit16: lodsw
    xchg al, ah
    mov  ecx, 16
b16: shl  ax, 1
        jnc  0f
            mov  [edi], dx
0:     add  edi, 2
        next b16
    ret

bit32: lodsw
    xchg al, ah
    mov  ecx, 16
b32: shl  eax, 1
        jnc  0f
            mov  [edi], dx
            mov  [edi+2], dx
            mov  [edi+hp*2], dx
            mov  [edi+hp*2+2], dx
0:     add  edi, 4
        next b32
    ret

emit: call qcr
    push esi
    push edi
    push edx
    imul eax, 16*24/8
    lea  esi, icons[eax]
    call clip
    mov  edx, fore
    mov  ecx, 24
0:  push ecx
    call bit16
    add  edi, (hp-16)*2
    pop  ecx
    next 0b
    pop  edx
    pop  edi
    pop  esi
bl_: drop
space: add dword ptr  xy, iw*0x10000
    ret

emit2: push esi
    push edi
    push edx
     imul eax, 16*24/8
     lea  esi, icons[eax]
     call clip
     mov  edx, fore
     mov  ecx, 24
0:     push ecx
        call bit32
        add  edi, (2*hp-16*2)*2
        pop  ecx
        next 0b
    pop  edx
    pop  edi
    pop  esi
    add dword ptr  xy, iw*0x10000*2
    drop
    ret

text1: call white
    mov dword ptr  lm, 3
    mov dword ptr  rm, hc*iw
    jmp  top

line: call clip
    mov  ecx, [esi]
    shl  ecx, 1
    sub  edi, ecx
    mov  ecx, eax
    mov  eax, fore
    rep stosw
    inc dword ptr  xy
    drop
    drop
    ret

box: call clip
    cmp  eax, vp+1
    js   0f
        mov  eax, vp
0: mov  ecx, eax
    sub  ecx, yc
    jng  no
    cmp  dword ptr [esi], hp+1
    js   0f
        mov  dword ptr [esi], hp
0: mov  eax, xc
    sub  [esi], eax
    jng  no
    mov  edx, hp
    sub  edx, [esi]
    shl  edx, 1
    mov  eax, fore
0:     push ecx
         mov  ecx, [esi]
         rep stosw
         add  edi, edx
        pop  ecx
        next 0b
no: drop
    drop
    ret
