;# compile Forth words with Huffman coding
.macro FORTH words:vararg
 .equ wordcount, 0
 .irp word, \words
 .if blocknumber % 2  ;# even screens are code, odd are documentation
  .equ typetag, 9  ;# type 9 is plain text
 .else
  .equ typetag, 4  ;# type 4 is compile
 .endif
 .ifeq wordcount
  .equ typetag, 3  ;# first word is almost always definition
 .endif
 .equ packed, 0
 .equ bitcount, 32
 .equ compiled, 0
 .ifeqs "\word", "[EXECUTE]"
  .equ typetag, 1
 .else
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
    .long packed | typetag
    .equ compiled, 1
    .equ typetag, 0
   .endif
  .endr
  .ifeq compiled
   .long packed | typetag
  .endif
 .endif
 .endr
.endm
