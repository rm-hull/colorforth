;# compile Forth words with Huffman coding
.macro packword words:vararg
 .irp word, \words
 .equ packed, 0
 .equ bitcount, 32
 .equ stoppacking, 0
 .irpc letter, "\word"
  .equ savepacked, packed
  .equ huffindex, 0
  .equ huffcode, 0
  .irpc huffman, " rtoeanismcylgfwdvpbhxuq0123456789j-k.z/;:!+@*,?"
   .ifeqs "\letter", "\huffman"
    .equ bitshift, 4 + (huffindex / 8)
    .ifge bitshift - 6
     .equ bitshift, 7
    .endif
    .ifeq stoppacking
     .equ packed, packed | (huffcode << (bitcount - bitshift))
     .equ bitcount, bitcount - bitshift
    .endif
   .else
    .equ huffindex, huffindex + 1
    .equ huffcode, huffcode + 1
    .ifeq huffcode - 0b00001000 ;# going from 4-bit to 5-bit code
     .equ huffcode, 0b00010000
    .endif
    .ifeq huffcode - 0b00011000 ;# going from 5-bit to 7-bit code
     .equ huffcode, 0b01100000
    .endif
   .endif
  .endr
  .ifne packed & 0xf ;# low 4 bits cannot be occupied with packed stuff
   .equ packed, savepacked
   .equ stoppacking, -1
  .endif
 .endr
 .long packed
 .endr
.endm
