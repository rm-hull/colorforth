#!/usr/bin/python
"""dump a colorForth image file

   public domain code based on Tim Neitz's cf2html"""

import sys, os, struct

# the old huffman code is from http://www.colorforth.com/chars.html
oldcode  = ' rtoeani' + 'smcylgfw' + 'dvpbhxuq' + 'kzj34567' + \
           '891-0.2/' + ';:!+@*,?'
newcode  = ' rtoeani' + 'smcylgfw' + 'dvpbhxuq' + '01234567' + \
           '89j-k.z/' + ';:!+@*,?'
code = newcode  # assume Tim knows what he's doing
#code = oldcode  # assume Chuck knows what he's saying

blocktext = '' # global, written by many subroutines

output = sys.stdout

hexadecimal = '0123456789abcdef'

escape = chr(0x1b)

colors = ['', 'red', 'green', 'yellow', 'blue',
 'magenta', 'cyan', 'white', '', 'normal'] # escape codes 30 to 39

# function and colortags are one-based, remember to subtract 1 before indexing

function = [
 'execute', 'execute', 'define', 'compile',
 'compile', 'compile', 'compilemacro', 'execute',
 'text', 'textcapitalized', 'textallcaps', 'variable',
 '', '', '', '',
 '', 'executehex', '', '',
 'compilehex', 'compilehex', '', 'executehex',
]

colortags = [
 'yellow', 'yellow', 'red', 'green',
 'green', 'green', 'cyan', 'yellow',
 'white', 'white', 'white', 'magenta',
 'normal', 'normal', 'normal', 'normal',
 'normal', 'yellow', 'normal', 'normal',
 'green', 'green', 'normal', 'yellow',
]

highbit =  0x80000000L
mask =     0xffffffffL

format = ''  # use 'html' or 'color', otherwise plain text with or without tag
formats = ['', 'html', 'color', 'plaintext']
print_formats = [] # filled in during initialization; nothing defined yet

printing = False

debugging = False

def debug(*args):
 if debugging:
  sys.stderr.write('%s\n' % repr(args))

def putchar(character):
 global blocktext
 debug('putchar "%s"' % character);
 blocktext += character

def print_normal(printing, fulltag):
 if printing and fulltag == 3:
  putchar('\n')
 if fulltag < 0x20:
  if fulltag != 3:
   putchar(' ')

def print_color(printing, fulltag):
 global blocktext
 if printing:
  blocktext += '%s[%d;%dm' % (escape, 0, 30 + colors.index('normal'))
 if printing and fulltag == 3:
  putchar('\n')
 if fulltag < 0x20:
  color = colortags[fulltag - 1]
  if fulltag != 3:
   putchar(' ')
  blocktext += '%s[%d;%dm' % (escape, color != 'normal',
   30 + colors.index(color))

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

def print_tags(printing, fulltag):
 global blocktext
 if printing:
  blocktext += '</code>'
 if printing and (fulltag == 3):
  blocktext += '<br>'
 if fulltag < 0x20:
  blocktext += '<code class=%s>' % function[fulltag - 1]
  if fulltag != 3:
   putchar(' ')

def print_format(printing, fulltag):
 index = formats.index(format)
 print_formats[index](printing, fulltag)

def print_hex(integer):
 global blocktext
 blocktext += '%x' % integer

def print_decimal(integer):
 global blocktext
 if (highbit & integer):
  integer -= 0x100000000
 blocktext += '%d' % integer

def print_colors(printing, color):
 if printing:
  print_color(colortags[(color & 0x1f) - 1])

def print_plain(printing, fulltag):
 global blocktext
 if printing and fulltag == 3:
  putchar('\n')
 if fulltag < 0x20:
  if fulltag != 3:
   putchar(' ')
  blocktext += '<%02x>' % (fulltag & 0x1f)

def dump_block(chunk):
 """see http://www.colorforth.com/parsed.html for meaning of bit patterns"""
 global printing, blocktext
 state = 'default'
 for index in range(0, len(chunk), 4):
  integer = struct.unpack('<L', chunk[index:index + 4])[0]
  fulltag = integer & 0x1f
  tag = integer & 0xf
  if state == 'print number as hex':
   print_hex(integer)
   state = 'default'
  elif state == 'print number as decimal':
   print_decimal(integer)
   state = 'default'
  elif tag == 0:
   print_text(integer)
  elif tag == 2 or tag == 5:
   print_format(printing, fulltag)
   if integer & 0x10:
    state = 'print number as hex'
   else:
    state = 'print number as decimal'
  elif tag == 6 or tag == 8:
   print_format(printing, fulltag)
   if integer & 0x10:
    if integer & highbit:
     print_hex((integer >> 5) | 0xf8000000)
    else:
     print_hex(integer >> 5)
   else:
    if integer & highbit:
     print_decimal((integer >> 5) | 0xf8000000)
    else:
     print_decimal(integer >> 5)
  elif tag == 0xc:
   print_format(printing, tag)
   print_text(integer & 0xfffffff0)
   state = 'print number as decimal'
   print_format(True, 4)
  else:
   print_format(printing, tag)
   print_text(integer & 0xfffffff0)
  printing = True
 print_format(printing, 0x20);
 if printing:
  blocktext += '\n'

def init():
 global print_formats
 print_formats = [print_normal, print_tags, print_color, print_plain]

def cfdump(filename):
 global printing, blocktext
 init()
 if not filename:
  file = sys.stdin
 else:
  file = open(filename)
 data = file.read()
 file.close()
 debug('dumping %d bytes' % len(data))
 if format == 'html':
  output.write('<html>\n')
  output.write('<link rel=stylesheet type="text/css" href="colorforth.css">\n')
 for block in range(0, len(data), 1024):
  chunk = data[block:block + 1024]
  blocktext = ''
  output.write('{block %d}\n' % (block / 1024))
  if format == 'html':
   output.write('<div class=code>\n')
  else:
   debug('dumping block %d' % (block / 1024))
  dump_block(chunk)
  output.write(blocktext)
  if printing:
   printing = False
   if format == 'html':
    output.write('</div>\n<hr>\n')
 if format == 'html':
  output.write('</html>\n')

def cf2text(filename):
 global format
 format = 'plaintext'
 cfdump(filename)

def cf2ansi(filename):
 global format
 format = 'color'
 cfdump(filename)

def cf2html(filename):
 global format
 format = 'html'
 cfdump(filename)

if __name__ == '__main__':
 os.path.split
 command = os.path.splitext(os.path.split(sys.argv[0])[1])[0]
 sys.argv += ['']  # make sure there's at least 1 arg
 (eval(command))(sys.argv[1])
else:
 pass
