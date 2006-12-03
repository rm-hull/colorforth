#!/usr/bin/python
"""dump a colorForth image block

   public domain code based on Tim Neitz's cf2html"""

import sys, os, struct

# the old huffman code is from http://www.colorforth.com/chars.html
oldcode  = ' rtoeani' + 'smcylgfw' + 'dvpbhxuq' + 'kzj34567' + \
           '891-0.2/' + ';:!+@*,?'
newcode  = ' rtoeani' + 'smcylgfw' + 'dvpbhxuq' + '01234567' + \
           '89j-k.z/' + ';:!+@*,?'
code = newcode  # assume Tim knows what he's doing
#code = oldcode  # assume Chuck knows what he's saying

output = sys.stdout

hexadecimal = '0123456789abcdef'

escape = chr(0x1b)

colors = ['', 'red', 'green', 'yellow', 'blue',
 'magenta', 'cyan', 'white', '', 'normal'] # escape codes 30 to 39

function = ['execute', 'execute', 'define', 'compile',
 'compile', 'compile', 'compilemacro', 'execute',
 'text', 'textcapitalized', 'textallcaps', 'variable',
 '', '', '', '',
 '', 'executehex', '', '',
 'compilehex', 'compilehex', '', 'executehex']

colortags = ['yellow', 'yellow', 'red', 'green',
 'green', 'green', 'cyan', 'yellow',
 'white', 'white', 'white', 'magenta']

highbit =  0x80000000L
mask =     0xffffffffL

format = ''  # use 'html' or 'color', otherwise plain text
formats = ['', 'html', 'color']
print_formats = []

debugging = False

def debug(*args):
 if debugging:
  sys.stderr.write('%s\n' % repr(args))

def putchar(character):
 debug('putchar "%s"' % character);
 output.write(character)

def print_normal(printing, tagtype):
 if printing and tagtype == 3:
  putchar('\n')

def print_color(printing, tagtype):
 color = colortags[tagtype]
 output.write('%s[%d;%dm' % (escape, color != 'normal',
  30 + colors.index(color)))

def print_text(coded):
 debug('coded: %08x' % coded)
 while coded:
  nybble = coded >> 28
  coded = (coded << 4) & mask
  debug('nybble: %01x, coded: %08x' % (nybble, coded))
  if nybble < 0x8:  # 4-bit coded character
   putchar(code[nybble])
  elif nybble < 0xc: # 5-bit code
   putchar(code[(((nybble ^ 0xc) << 1) | (coded & highbit > 0))])
   coded = (coded << 1) & mask
  else:  # 7-bit code
   putchar(code[(coded >> 29) + (8 * (nybble - 10))])
   coded = (coded << 3) & mask

def print_tags(printing, tagtype):
 if printing:
  output.write('</code>')
 if printing and (tagtype == 3):
  output.write('</br>')
 output.write('<code class="%s">' % function[tagtype - 1])

def print_format(printing, tagtype):
 index = formats.index(format)
 print_formats[index](printing, tagtype)
 if tagtype != 3:
  putchar(' ')

def print_hex(integer):
 output.write('%x' % integer)

def print_decimal(integer):
 output.write('%d' % integer) 

def print_colors(printing, color):
 if printing:
  print_color(colortags[color & 0x1f])

def dump_block(chunk):
 """see http://www.colorforth.com/parsed.html for meaning of bit patterns"""
 state = 'default'
 printing = False
 for index in range(0, len(chunk), 4):
  integer = struct.unpack('<L', chunk[index:index + 4])[0]
  tagtype = integer & 0xf
  if state == 'print number as hex':
   print_hex(integer)
   state = 'default'
  elif state == 'print number as decimal':
   print_decimal(integer)
   state = 'default'
  elif not tagtype:
   print_text(integer)
  elif tagtype == 2 or tagtype == 5:
   print_format(printing, tagtype & 0x1f)
   if integer & 0x10:
    state = 'print number as hex'
   else:
    state = 'print number as decimal'
  elif tagtype == 6 or tagtype == 8:
   print_format(printing, tagtype & 0x1f)
   if integer & 0x10:
    print_hex(integer >> 5)
   else:
    print_decimal(integer >> 5)
  elif tagtype == 0xc:
   print_format(printing, tagtype & 0xf)
   print_text(integer & 0xfffffff0)
   state = 'print number as decimal'
  else:
   print_format(printing, tagtype & 0xf)
   print_text(integer & 0xfffffff0)
  printing = True

def init():
 global print_formats
 print_formats = [print_normal, print_color, print_tags]

def cfdump(filename):
 init()
 if not filename:
  file = sys.stdin
 else:
  file = open(filename)
 data = file.read()
 file.close()
 debug('dumping %d bytes' % len(data))
 for block in range(0, len(data), 1024):
  chunk = data[block:block + 1024]
  debug('dumping block %d' % (block / 1024))
  dump_block(chunk)

def dump_color(filename):
 format = 'color'
 cfdump(filename)

def dump_html(filename):
 format = 'html'
 cfdump(filename)

if __name__ == '__main__':
 os.path.split
 command = os.path.splitext(os.path.split(sys.argv[0])[1])[0]
 (eval(command))(sys.argv[1])
else:
 pass
