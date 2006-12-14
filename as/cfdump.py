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

emptyblock = '\0' * 1024

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

formats = ['', 'html', 'color', 'plaintext']

dump = {  # set up globals as dictionary to avoid declaring globals everywhere
 'dirty': False,  # low-level code detected in a block
 'blocktext': '',  # decompiled high-level Forth
 'print_formats': [],  # filled in during init; routines not yet defined
 'debugging': False,
 'original': False,  # set True for output similar to Tim Neitz's cf2html.c
 'format': ''  # use 'html' or 'color', otherwise plain text
}

def debug(*args):
 if dump['debugging']:
  sys.stderr.write('%s\n' % repr(args))

def print_normal(fulltag):
 if dump['blocktext'] and fulltag == 3:
  dump['blocktext'] += '\n'
 if fulltag < 0x20:  # 0x20 is fake 'tag' for end-of-block closure
  if dump['blocktext'] and fulltag != 3:
   dump['blocktext'] += ' '

def print_color(fulltag):
 debug('print_color(0x%x)' % fulltag)
 if dump['blocktext']:  # close previous color tag
  dump['blocktext'] += '%s[%d;%dm' % (escape, 0, 30 + colors.index('normal'))
 if dump['blocktext'] and fulltag == 3: # newline before definition
  dump['blocktext'] += '\n'
 if fulltag < 0x20:  # 0x20 is fake 'tag' for end-of-block closure
  color = colortags[fulltag - 1]
  if dump['blocktext'] and fulltag != 3:
   dump['blocktext'] += ' '
  dump['blocktext'] += '%s[%d;%dm' % (escape, color != 'normal',
   30 + colors.index(color))

def print_text(coded):
 debug('coded: %08x' % coded)
 bits = 32 - 4  # 28 bits used for compressed text
 text = ''
 while coded:
  nybble = coded >> 28
  coded = (coded << 4) & mask
  bits -= 4
  debug('nybble: %01x, coded: %08x' % (nybble, coded))
  if nybble < 0x8:  # 4-bit coded character
   text += code[nybble]
  elif nybble < 0xc: # 5-bit code
   text += code[(((nybble ^ 0xc) << 1) | (coded & highbit > 0))]
   coded = (coded << 1) & mask
   bits -= 1
  else:  # 7-bit code
   text += code[(coded >> 29) + (8 * (nybble - 10))]
   coded = (coded << 3) & mask
   bits -= 3
 debug('text: "%s"' % text)
 dump['blocktext'] += text

def print_tags(fulltag):
 if dump['blocktext']:
  dump['blocktext'] += '</code>'
 if dump['blocktext'] and (fulltag == 3):
  dump['blocktext'] += '<br>'
 if fulltag < 0x20:
  dump['blocktext'] += '<code class=%s>' % function[fulltag - 1]
  if fulltag != 3:
   dump['blocktext'] += ' '

def print_format(fulltag):
 index = formats.index(dump['format'])
 dump['print_formats'][index](fulltag)

def print_hex(integer):
 dump['blocktext'] += '%x' % integer

def print_decimal(integer):
 if (highbit & integer):
  integer -= 0x100000000
 dump['blocktext'] += '%d' % integer

def print_colors(color):
 if dump['blocktext']:
  print_color(colortags[(color & 0x1f) - 1])

def print_plain(fulltag):
 if dump['blocktext'] and fulltag == 3:
  dump['blocktext'] += '\n'
 if fulltag < 0x20:
  if fulltag != 3:
   dump['blocktext'] += ' '
  dump['blocktext'] += '<%02x>' % (fulltag & 0x1f)

def dump_code(chunk):
 """dump block as raw hex so it can be undumped"""
 dump['blocktext'] += '%02x' * len(chunk) % tuple(map(ord, chunk))

def dump_block(chunk):
 """see http://www.colorforth.com/parsed.html for meaning of bit patterns"""
 state = 'default'
 dump['dirty'] = False  # assume high-level code until proven otherwise
 for index in range(0, len(chunk), 4):
  integer = struct.unpack('<L', chunk[index:index + 4])[0]
  fulltag = integer & 0x1f
  tag = integer & 0xf
  debug('fulltag: 0x%x' % fulltag)
  if state == 'print number as hex':
   print_hex(integer)
   state = 'default'
  elif state == 'print number as decimal':
   print_decimal(integer)
   state = 'default'
  elif tag == 0:
   print_text(integer)
  elif tag == 2 or tag == 5:
   print_format(fulltag)
   if integer & 0x10:
    state = 'print number as hex'
   else:
    state = 'print number as decimal'
  elif tag == 6 or tag == 8:
   print_format(fulltag)
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
   print_format(tag)
   print_text(integer & 0xfffffff0)
   state = 'print number as decimal'
   print_format(4)
  elif not dump['original'] and tag > 0xc:
   debug('block is dirty: tag = 0x%x' % tag)
   dump['dirty'] = True
   dump_code(struct.pack('<L', integer))
  else:
   print_format(tag)
   print_text(integer & 0xfffffff0)
 print_format(0x20)  # 'fake' format that just closes previous tags
 if dump['blocktext']:
  dump['blocktext'] += '\n'

def init():
 dump['debugging'] = os.getenv('DEBUGGING')
 dump['original'] = os.getenv('TIM_NEITZ')
 dump['print_formats'] = [print_normal, print_tags, print_color, print_plain]

def cfdump(filename):
 init()
 if not filename:
  file = sys.stdin
 else:
  file = open(filename)
 data = file.read()
 file.close()
 debug('dumping %d bytes' % len(data))
 if dump['format'] == 'html':
  output.write('<html>\n')
  output.write('<link rel=stylesheet type="text/css" href="colorforth.css">\n')
 for block in range(0, len(data), 1024):
  chunk = data[block:block + 1024]
  output.write('{block %d}\n' % (block / 1024))
  if dump['format'] == 'html':
   output.write('<div class=code>\n')
  else:
   debug('dumping block %d' % (block / 1024))
  dump_block(chunk)
  output.write(dump['blocktext'])
  if dump['blocktext']:
   dump['blocktext'] = ''
  if dump['format'] == 'html':
   output.write('</div>\n<hr>\n')
 if dump['format'] == 'html':
  output.write('</html>\n')

def cf2text(filename):
 dump['format'] = 'plaintext'
 cfdump(filename)

def cf2ansi(filename):
 dump['format'] = 'color'
 cfdump(filename)

def cf2html(filename):
 dump['format'] = 'html'
 cfdump(filename)

if __name__ == '__main__':
 os.path.split
 command = os.path.splitext(os.path.split(sys.argv[0])[1])[0]
 sys.argv += ['']  # make sure there's at least 1 arg
 (eval(command))(sys.argv[1])
else:
 pass
