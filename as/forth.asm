.equ blockstart, .; .equ blocknumber, -1

;# pad to block boundary
.macro BLOCK number
 .ifb \number
  .print "compiling next block"
  .equ blocknumber, blocknumber + 1
 .else
  .print "compiling block \number"
  .equ blocknumber, \number
 .endif
 .ifdef ABSOLUTE_BLOCKNUMBER
  .org blocknumber * 1024
 .else
  .org blockstart
  .equ blockstart, blockstart + 1024
 .endif
 SET_DEFAULT_TYPETAG
.endm

.macro SET_DEFAULT_TYPETAG
 .if blocknumber % 2  ;# even screens are code, odd are documentation
  .equ default_typetag, 9  ;# type 9 is plain text
 .else
  .equ default_typetag, 4  ;# type 4 is compile
 .endif
.endm

.macro SETTYPE word
 .equ type, 0
 .irp function [EXTENSION], [EXECUTE], [EXECUTELONG], [DEFINE], [COMPILEWORD]
  NEXTTYPE "\word", "\function"
 .endr
 .irp function [COMPILELONG], [COMPILESHORT], [COMPILEMACRO], [EXECUTESHORT]
  NEXTTYPE "\word", "\function"
 .endr
 .irp function [TEXT], [TEXTCAPITALIZED], [TEXTALLCAPS], [VARIABLE]
  NEXTTYPE "\word", "\function"
 .endr
 .irp function [], [], [], [], [], [EXECUTELONGHEX], [], [], [COMPILELONGHEX]
  NEXTTYPE "\word", "\function"
 .endr
 .irp function [COMPILESHORTHEX], [], [EXECUTESHORTHEX], [SKIP], [BINARY]
  NEXTTYPE "\word", "\function"
 .endr
.endm

.macro NEXTTYPE word, function
 .ifdef DEBUG_FORTH
  ;#.print "comparing \"\word\" with \"\function\""
 .endif
 .ifeqs "\word", "\function"
  .equ default_typetag, type
 .else
  .equ type, type + 1
 .endif
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
 SETTYPE "\word"
 COMPILETYPE "\word"
 .equ wordcount, wordcount + 1
 .endr
.endm

.macro COMPILETYPE word
 .ifeq type - 27  ;# means the SETTYPE macro didn't find a match
  SET_DEFAULT_TYPETAG
  .if typetag == 2 || typetag == 5
   .long typetag, \word
  .elseif typetag == (2 + 16) || typetag == (5 + 16)
   .long typetag, 0x\word
  .elseif typetag == 6 || typetag == 8
   .long typetag | (\word << 5)
  .elseif typetag == (6 + 16) || typetag == (8 + 16)
   .long typetag | (0x\word << 5)
  .elseif typetag == 25  ;# SKIP
   .fill \word, 4, 0
  .elseif typetag == 26  ;# BINARY
   .long 0x\word
  .else
   FORTHWORD "\word"
  .endif
 .endif
.endm

.macro FORTHWORD word
 .equ packed, 0; .equ savepacked, 0; .equ bitcount, 32; .equ compiled, 0
 .irpc letter, "\word"
  .equ huffindex, 0; .equ huffcode, 0
  GETCODE "\letter"
  ;#.long packed, huffcode, bitcount, bitshift ;# debugging
  .equ savepacked, packed
  .equ packed, packed | (huffcode << (bitcount - bitshift))
  .equ bitcount, bitcount - bitshift
  ;# low 4 bits reserved for word type tag
  .if (packed & 0xf > 0) || bitcount < 0
   .long savepacked | typetag; .equ packed, huffcode << (32 - bitshift)
   .equ bitcount, 32 - bitshift; .equ typetag, 0  ;# word "extension"
  .elseif bitcount < bitshift  ;# we can't shift more than once past 32 bits
   .long packed | typetag; .equ packed, 0; .equ bitcount, 32
   .equ typetag, 0  ;# any more letters form word "extension"
  .endif
 .endr
 .ifne packed
  .long packed | typetag
 .endif
.endm

.macro GETCODE letter
 .nolist  ;# don't pollute listing with all these byte comparisons
 .irpc huffman, " rtoeanismcylgfwdvpbhxuq0123456789j-k.z/;:!+@*,?"
  .ifeqs "\letter", "\huffman"
   .equ bitshift, 4 + (huffindex / 8)
   .ifge bitshift - 6
    .equ bitshift, 7
   .endif
   .exitm
  .else
   NEXTCODE
  .endif
 .endr
 .list  ;# go ahead and generate listing if enabled
.endm

.macro NEXTCODE
 .equ huffindex, huffindex + 1
 .equ huffcode, huffcode + 1
 .ifeq huffcode - 0b00001000 ;# going from 4-bit to 5-bit code
  .equ huffcode, 0b00010000
 .endif
 .ifeq huffcode - 0b00011000 ;# going from 5-bit to 7-bit code
  .equ huffcode, 0b01100000
 .endif
.endm
