;# compile Forth words with Huffman coding
.macro CHR16X24 row
 .equ packed, 0
 .irpc pixel, "\row"
  .equ packed, packed << 1
  .ifeqs "\pixel", "#"
   .equ packed, packed | 1
  .endif
 .endr
 .word packed
.endm
