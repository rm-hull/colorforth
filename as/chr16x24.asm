;# compile character map from data stored as "######       ###"
;# the above would compile to the two bytes 0xfc 0x03
.macro CHR16X24 row
 .equ packed, 0
 .irpc pixel, "\row"
  .equ packed, packed << 1
  .ifeqs "\pixel", "#"
   .equ packed, packed | 1
  .endif
 .endr
 .byte packed >> 8, packed & 0xff
.endm
