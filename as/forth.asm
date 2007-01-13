;# pad to block boundary
.macro BLOCK number
 .equ blocknumber, \number
 .ifdef ABSOLUTE_BLOCKNUMBER
  .org \number * 1024
 .else
  .align 1024, 0
 .endif
 .if blocknumber % 2  ;# even screens are code, odd are documentation
  .equ default_typetag, 9  ;# type 9 is plain text
 .else
  .equ default_typetag, 4  ;# type 4 is compile
 .endif
.endm

.macro SETTYPE word
 .equ type, 0
 .irp function [EXTENSION], [EXECUTE], [EXECUTELONG], [DEFINE], [COMPILEWORD] 
  .ifeqs "\word", "\function"
   .equ typetag, type
  .else
   .equ type, type + 1
  .endif
 .endr
 .irp function [COMPILELONG], [COMPILESHORT], [COMPILEMACRO], [EXECUTESHORT]
  .ifeqs "\word", "\function"
   .equ typetag, type
  .else
   .equ type, type + 1
  .endif
 .endr
 .irp function [TEXT], [TEXTCAPITALIZED], [TEXTALLCAPS], [VARIABLE]
  .ifeqs "\word", "\function"
   .equ typetag, type
  .else
   .equ type, type + 1
  .endif
 .endr
.endm

;# compile Forth words with Huffman coding
.macro FORTH words:vararg
 .equ wordcount, 0
 .irp word, \words
 .ifeq wordcount
  .equ typetag, 3  ;# first word is almost always definition
 .else
  .equ typetag, default_typetag
 .endif
 SETTYPE \word
 .ifeq type - 13  ;# means the SETTYPE macro didn't find a match
  FORTHWORD \word
 .endif
 .endr
.endm

.macro FORTHWORD word
 .equ packed, 0
 .equ bitcount, 32
 .equ compiled, 0
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
    .equ packed, packed | (huffcode << (bitcount - bitshift))
    .equ bitcount, bitcount - bitshift
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
.endm

