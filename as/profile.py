#!/usr/bin/python
import sys, os, re
SYMDEF = re.compile('\s+\.text:([0-9a-f]+)\s+([\w]+)')
DEBUGTEXT = re.compile('\[(\d+)\]\s+\[(0x[0-9a-f]+)\]\s+\S+\s+[^:]+:(.*)')
symbol_table = {}
time_data = []
last_ticks = 0
symboldatafile = open('color.lst')
symboldata = symboldatafile.readlines()
symboldatafile.close()
for line in symboldata:
 match = SYMDEF.search(line)
 if match:
  address = eval('0x' + match.groups()[0])
  symbol = match.groups()[1]
  symbol_table[address] = symbol
#print repr(symbol_table)
addresses = symbol_table.keys()
addresses.sort()
print repr(addresses)
debugdatafile = open('../test/newbxnewcf.debug.txt')
debugdata = debugdatafile.readlines()
debugdatafile.close()
for line in debugdata:
 match = DEBUGTEXT.search(line)
 if match:
  ticks = eval(match.groups()[0])
  if last_ticks == 0:
   last_ticks = ticks
   ticks = 0
  else:
   ticks = ticks - last_ticks
   last_ticks = ticks
  address = eval(match.groups()[1])
  instruction = match.groups()[2]
  if symbol_table.has_key(address):
   print symbol_table[address]
