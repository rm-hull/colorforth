;# compile character map from data stored as "######........#######..........#"
;# the above should compile to the two bytes 0xfc 0x03 0xf8 0x01
.macro CHR32X32 row
 .equ packed, 0
 .irpc pixel, "\row"
  .equ packed, packed << 1
  .ifeqs "\pixel", "#"
   .equ packed, packed | 1
  .endif
 .endr
 .byte packed >> 24, packed >> 16 & 0xff, packed >> 8 & 0xff, packed & 0xff
.endm
