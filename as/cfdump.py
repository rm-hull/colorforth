#!/usr/bin/python
"""dump a colorForth image block

   public domain code based on Tim Neitz's cf2html"""

import sys

# the old huffman code is from http://www.colorforth.com/chars.html
oldcode  = ' rtoeanismcylgfwdvpbhxuqkzj34567891-0.2/;:!+@*,?'
newcode  = ' rtoeanismcylgfwdvpbhxuq0123456789j-k.z/;:!+@*,?'
code = newcode  # assume Tim knows what he's doing

highbit =  0x80000000L
mask =     0xffffffffL

def putchar(index):
 sys.stdout.write(code[index])

def print_text(coded):
 while coded:
  nybble = coded >> 28
  coded = (coded << 4) & mask
  if nybble < 0x8:  # 4-bit coded character
   putchar(nybble)
  elif nybble < 0xc: # 5-bit code
   putchar(((nybble << 1) + (coded & highbit > 0)))  # True is always 1
   coded = (coded << 1) & mask
  else:  # 7-bit code
   putchar((coded >> 29) + (8 << (nybble - 10)))
   coded = (coded << 3) & mask

if __name__ == '__main__':
 print_text(sys.argv[1])
else:
 pass
