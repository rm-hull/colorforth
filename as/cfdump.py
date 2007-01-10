#!/usr/bin/python
"""dump a colorForth image file -- jc.unternet.net

   public domain code based on Tim Neitz's cf2html
   see http://www.colorforth.com/parsed.html for meaning of bit patterns"""

import sys, os, struct, re

# the old huffman code is from http://www.colorforth.com/chars.html
oldcode  = ' rtoeani' + 'smcylgfw' + 'dvpbhxuq' + 'kzj34567' + \
           '891-0.2/' + ';:!+@*,?'
newcode  = ' rtoeani' + 'smcylgfw' + 'dvpbhxuq' + '01234567' + \
           '89j-k.z/' + ';:!+@*,?'
code = newcode  # assume Tim knows what he's doing
#code = oldcode  # assume Chuck's webpage is up-to-date (bad idea as of 2006)

emptyblock = '\0' * 1024

icon_start_block = 12  # first block of character maps

high_level_block = 18  # first high-level code block in CM2001

output = sys.stdout

hexadecimal = '0123456789abcdef'

ESC = chr(0x1b)  # the 'escape' key (didn't save Neo from Trinity)

colors = ['', 'red', 'green', 'yellow', 'blue',
 'magenta', 'cyan', 'white', '', 'normal'] # escape codes 30 to 39

function = [
 'extension', 'execute', 'executelong', 'define',
 'compileword', 'compilelong', 'compileshort', 'compilemacro',
 'executeshort', 'text', 'textcapitalized', 'textallcaps',
 'variable', 'undefined', 'undefined', 'undefined',
]

fivebit_tags = [
 # use by cf2html to determine when to use 5 tag bits instead of 4
 function.index('executelong'),
 function.index('compilelong'),
 function.index('compileshort'),
 function.index('executeshort'),
]

codetag = [
 '', 'execute', 'execute', 'define',
 'compile', 'compile', 'compile', 'compilemacro',
 'execute', 'text', 'textcapitalized', 'textallcaps',
 'variable', '', '', '',
 '', '', 'executehex', '',
 '', 'compilehex', 'compilehex', '',
 'executehex', '', '', '',
 '', '', '', '',
]

colortags = [
 'normal', 'brightyellow', 'brightyellow', 'brightred',
 'brightgreen', 'brightgreen', 'brightgreen', 'brightcyan',
 'brightyellow', 'brightwhite', 'brightwhite', 'brightwhite',
 'brightmagenta', 'normal', 'normal', 'normal',
 'normal', 'normal', 'yellow', 'normal',
 'normal', 'green', 'green', 'normal',
 'yellow', 'normal', 'normal', 'normal',
 'normal', 'normal', 'normal', 'normal',
]

highbit =  0x80000000L
mask =     0xffffffffL

formats = ['', 'html', 'color', 'plaintext']

dump = {  # set up globals as dictionary to avoid declaring globals everywhere
 'printing': False,  # boolean to indicate we've started dumping the block
 'blockdata': [],  # 256 integers per 1024-byte block
 'print_formats': [],  # filled in during init; routines not yet defined
 'dump_formats': [],  # similar to print_formats but for binary dumps
 'debugging': False,  # set True for copious debugging messages
 'original': False,  # set True for output similar to Tim Neitz's cf2html.c
 'format': '',  # use 'html' or 'color', otherwise plain text
 'index': 0,  # index into block, to match cf2html.c bug
 'state': 'print according to tag',  # globally-manipulable state machine
 'default_state': 'print according to tag',
}

def extension(prefix, number, suffix):
 if not dump['original']:
  debug('extension(0x%x): should never be reached' % number)
 return text(prefix, number, suffix)

def undefined(prefix, number, suffix):
 if dump['original']:
  return text(prefix, number, suffix)
 else:
  return prefix + print_hex(number) + suffix

def variable(prefix, number, suffix):
 """this is significantly different from other word names.

    unlike the others, this always has a 32-bit value following it, and
    since that might have the low 4 bits zero, a variable name cannot have
    'extensions', that is, it must pack into 28 bits."""
 return prefix + unpack(number) + suffix + \
  print_format(function.index('compilelong'))

def text(prefix, number, suffix):
 string = unpack(number)
 while dump['index'] < len(dump['blockdata']):
  number = dump['blockdata'][dump['index']]
  if number == 0 or number & 0xf != 0:
   debug('0x%x (%s) not an extension' % (number, unpack(number)))
   break
  else:
   debug('found an extension')
   string += unpack(number)
   dump['index'] += 1
 debug('final string: %s' % string)
 return prefix + string + suffix

def textcapitalized(prefix, number, suffix):
 if dump['original']:
  return text(prefix, number, suffix)
 else:
  return prefix + text('', number, '').capitalize() + suffix

def textallcaps(prefix, number, suffix):
 if dump['original']:
  return text(prefix, number, suffix)
 else:
  return prefix + text('', number, '').upper() + suffix

def debug(*args):
 if dump['debugging']:
  sys.stderr.write('%s\n' % repr(args))

def executeshort(prefix, number, suffix):
 if hexadecimal(number):
  return prefix + print_hex(asr(number, 5)) + suffix
 else:
  return prefix + print_decimal(asr(number, 5)) + suffix

def asr(number, shift):
 "arithmetic shift right"
 if highbit & number:
  for i in range(shift):
   number >>= 1
   number |= highbit
 else:
  number >>= shift
 return number 

def executelong(prefix, number, suffix):
 """print 32-bit integer with specified prefix and suffix

    prepare for possible extension to 59-bit numbers"""
 if not dump['original']:
  long = (number & 0xffffffe0) << (32 - 5)
 else:
  long = 0
 long |= dump['blockdata'][dump['index']]
 dump['index'] += 1
 if hexadecimal(number):
  return prefix + print_hex(long) + suffix
 else:
  return prefix + print_decimal(long) + suffix

def compileshort(prefix, number, suffix):
 return executeshort(prefix, number, suffix)

def compilelong(prefix, number, suffix):
 return executelong(prefix, number, suffix)

def dump_normal(number):
 pass

def print_normal(number):
 if dump['printing'] and tag(number) == function.index('define'):
  output.write('\n')
 if dump['state'] != 'mark end of block':
  if dump['printing'] and tag(number) != function.index('define'):
   output.write(' ')

def dump_color(number):
 suffix = '%s[%d;%dm' % (ESC, 0, 30 + colors.index('normal'))
 if dump['state'].startswith('dump as binary'):
  if ' ' not in unpack(number):
   prefix = '%s[%d;%dm' % (ESC, 1, 30 + colors.index('blue'))
   return text(prefix, number, suffix + ' ')
  else:
   prefix = '%s[%d;%dm' % (ESC, 0, 30 + colors.index('red'))
   return prefix + print_hex(number) + suffix + ' '
 else:  # dump as character map
  prefix = '%s[%d;%dm' % (ESC, 0, 30 + colors.index('blue'))
  return dump_charmap(prefix, number, suffix)

def print_color(number):
 if not dump['printing'] and number == 0: return ''
 else: dump['printing'] = True
 prefix, suffix, wordtype = '', '', function[tag(number)]
 if dump['printing'] and wordtype == 'define':
  prefix = '\n'
 if dump['state'] != 'mark end of block':
  suffix = '%s[%d;%dm' % (ESC, 0, 30 + colors.index('normal')) + ' '
  color = colortags[fulltag(number)]
  bright = 0
  if color[0:6] == 'bright':
   bright, color = 1, color[6:]
  if function[tag(number)] != 'extension':
   prefix += '%s[%d;%dm' % (ESC, bright, 30 + colors.index(color))
  try:
   return eval(function[tag(number)])(prefix, number, suffix)
  except:
   return text(prefix, number, suffix)
 else:
  return '\n'

def dump_charmap(prefix, number, suffix):
 """dump two lines (32 bits) of a 16x24-pixel character map

    the idea is to dump it in such as way that an assembly language
    (GNU as) macro can be written to undump the fonts.
    the low 16-bit word holds the upper line, and the bits are inverted"""
 dumptext = prefix
 for word in [0x8000L, 0x80000000L]:
  for bit in [word / 0x100L, word]:
   done = bit / 0x100L
   while bit != done:
    if number & bit: dumptext += '#'
    else: dumptext += ' '
    bit >>= 1
  if word == 0x8000L: dumptext += '%s\n%s' % (suffix, prefix)
  else: dumptext += '%s\n' % suffix
 return dumptext

def unpack(coded):
 #debug('coded: %08x' % coded)
 bits = 32 - 4  # 28 bits used for compressed text
 coded &= ~0xf  # so zero low 4 bits
 text = ''
 while coded:
  nybble = coded >> 28
  coded = (coded << 4) & mask
  bits -= 4
  #debug('nybble: %01x, coded: %08x' % (nybble, coded))
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
 return text

def dump_tags(number):
 pass

def print_tags(number):
 prefix, suffix = '', '</code>'
 tagbits = fulltag(number)
 if dump['printing']:
  if tagbits == function.index('define'): prefix = '<br>'
 if number:
  dump['printing'] = True
 if dump['state'] != 'mark end of block':
  if not dump['original'] or tag(number) != function.index('extension'):
   prefix += '<code class=%s>' % codetag[tagbits]
   if dump['original'] and tagbits != function.index('define'): prefix += ' '
  try:
   return eval(function[tag(number)])(prefix, number, suffix)
  except:
   return text(prefix, number, suffix)
 else:
  return prefix

def tag(number):
 return number & 0xf

def fulltag(number):
 basetag = tag(number)
 if basetag in fivebit_tags:
  return number & 0x1f
 else:
  return basetag

def hexadecimal(number):
 return number & 0x10 > 0

def print_format(number):
 index = formats.index(dump['format'])
 if dump['state'].startswith('dump '):
  debug('returning %s(0x%x)' % (repr(dump['dump_formats'][index]), number))
  return dump['dump_formats'][index](number)
 else:
  debug('returning %s(0x%x)' % (repr(dump['print_formats'][index]), number))
  return dump['print_formats'][index](number)

def print_hex(integer):
 return '%x' % integer

def print_decimal(integer):
 if (highbit & integer):
  integer -= 0x100000000
 return '%d' % integer

def dump_plain(number):
 pass

def print_plain(number):
 prefix, suffix = '', ''
 if dump['printing'] and tag(number) == function.index('define'):
  prefix += '\n'
 if dump['state'] != 'mark end of block':
  if dump['printing'] and tag(number) != function.index('define'):
   prefix += ' '
  output.write('%s ' % function[fulltag(number)].upper())
  return eval(function[tag(number)])(prefix, number, suffix)
 else:
  return prefix

def print_code(chunk):
 """dump as raw hex so it can be undumped"""
 output.write('%02x' * len(chunk) % tuple(map(ord, chunk)))

def set_default_state(state):
 "reset state machine at start of each block"
 dump['state'] = 'print according to tag'
 if state:
  dump['state'] = state
 elif (dump['block'] / 1024) < high_level_block and not dump['original']:
  dump['state'] = 'dump as binary unless packed word'
  if (dump['block'] / 1024) >= icon_start_block:
   dump['state'] = 'dump character map'
 dump['default_state'] = dump['state']
 dump['printing'] = False

def dump_block():
 set_default_state('')
 while dump['index'] < len(dump['blockdata']):
  if allzero(dump['blockdata'][dump['index']:]):
   break
  integer = dump['blockdata'][dump['index']]
  dump['index'] += 1
  debug('[0x%x]' % integer)
  output.write(print_format(integer))
 if not dump['original']:
  dump['state'] = 'mark end of block'
  output.write(print_format(0))
 if dump['printing'] and not dump['original']:
  output.write('\n')

def init():
 dump['debugging'] = os.getenv('DEBUGGING')
 if dump['format'] == 'html':
  dump['original'] = os.getenv('TIM_NEITZ')
 dump['print_formats'] = [print_normal, print_tags, print_color, print_plain]
 dump['dump_formats'] = [dump_normal, dump_tags, dump_color, dump_plain]

def allzero(array):
 return not filter(long.__nonzero__, array)

def cfdump(filename):
 init()
 if not filename: file = sys.stdin
 else: file = open(filename)
 data = file.read()
 file.close()
 if dump['format'] == 'html':
  output.write('<html>\n')
  output.write('<link rel=stylesheet type="text/css" href="colorforth.css">\n')
 for dump['block'] in range(0, len(data), 1024):
  chunk = data[dump['block']:dump['block'] + 1024]
  dump['blockdata'] = struct.unpack('<256L', chunk)
  output.write('{block %d}\n' % (dump['block'] / 1024))
  if dump['format'] == 'html': output.write('<div class=code>\n')
  dump['index'] = 0
  if not allzero(dump['blockdata']): dump_block()
  if dump['format'] == 'html': output.write('\n</div>\n<hr>\n')
 if dump['format'] == 'html': output.write('</html>\n')

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
