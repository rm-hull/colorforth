original := $(wildcard ../masm/*.asm)
sources := $(notdir $(original))
ftpfiles := $(foreach file, $(sources), \
 $(shell echo $(notdir $(file)) | tr 'a-z' 'A-Z'))
# sed recipes (commands) for converting MASM code to GNU 'as' assembler
label_if_any := \(\s*\w\+:\)\?
equ := -e 's/^\s*\(\w\+\)\s\+equ\s\+\(.\+\)/.equ \1, \2/gi'
includes := -e 's/\b\(include\)\(\s\+\)\(\S\+\)\(.*\)/.\1\2"\3"\4/i'
directives := -e 's/\b\(macro\|endm\|org\|end\|align\)\b/.\1/gi'
lowercase := -e 's/^\(.*\)$$/\L\1/'
orgminus := -e 's/\(\s*\.org\s*\.\s*-\s*2\)/;\#\1/'
org0x1fe := -e 's/\(\s*\.org\s*0x1fe\)/;\#\1/'
offset := -e '/^$(label_if_any)\s*\.\w\+/ s/\boffset\b\s//gi'
# need to use \x27 to represent tick "'" in regexp
ascii := -e 's/\.byte\s\+\x27\([^\x27]\+\)\x27/.ascii "\1"/'
dup := -e 's/\(\.\w\+\)\s\+\(\w\+\)\s\+dup\s*(\(\w\+\))/.rept \2 \1 \3; .endr/'
unused := -e 's/^\(\s*\(.model\|.486p\|only\|assume\)\b.*\)/;\#\1/i'
labels := -e 's/^\(\s*\w\+\)\(\s\+\.\w\+\s\+.*\)/\1:\2/'
macro := -e 's/^\(\s*\)\(\w\+\)\(\s\+\)\(macro\)\b/\1\4\3\2/gi'
reg8s := al\|bl\|cl\|dl\|ah\|bh\|ch\|dh
reg16s := ax\|bx\|cx\|dx\|si\|di\|bp\|sp\|cs\|ds\|es\|ss\|ip
reg32s := eax\|ebx\|ecx\|edx\|esi\|edi\|ebp\|esp\|eip
registers := -e 's/\b\($(reg8s)\|$(reg16s)\|$(reg32s)\)/%\1/gi'
shift := -e '/\bdd\b/ s/\bshl\b/<</g'
comment := -e 's/;/;\#/'
here := -e 's/\$$/./'
byte := -e 's/\bdb\b/.byte/i'
word := -e 's/\bdw\b/.word/i'
dword := -e 's/\bdd\b/.long/i'
local := -e 's/^\(\s*\)@@:/\10:/'
reference := -e 's/\B@\([FfBb]\)\b/0\1/'
octal := -e 's/\b\([0-7]\+\)o/0\1/g'
hex := -e 's/\b\([0-9a-fA-f]\{2,\}\)h\b/0x\1/g'
intel := -e '1 s/^/.intel_syntax /'
use32 := -e '/\bcr0\b/I i.code32'  # will mess up the error line no.
use16 := -e '/^start0:/ i.code16gcc' # will mess up the error line no.
code16 := -e '/\.code16/,/\.code32/ s/\be\(\w\{2\}\)\b/\1/gi'
offset_test := -n -e '/$(label_if_any).*offset/p'  # must be used alone
regex_test := sed $(foreach regex, $(REGEX), $($(regex)))
# order of the recipes can be important!
recipes := intel lowercase
recipes += shift comment local reference
recipes += octal hex macro includes directives unused
recipes += byte word dword here equ labels dup ascii
recipes += offset orgminus use16 use32
sed := sed $(foreach regex, $(recipes), $($(regex)))
GAS := as -R
export
%.dat:	%.asm
	$(GAS) -ahlmns=%.lis -o $*.o $<
	objcopy $*.o -O binary $@
color.com: $(sources) secondpass
	$(GAS) -ahlmns=color.lis -o color.o color.asm
	objcopy color.o -O binary color.bin
	# now get original color.com for its data blocks starting at 0x3000
	cp -f ../color.com .
	dd if=/dev/zero of=color.com bs=1024 count=12 conv=notrunc
	dd if=color.bin of=color.com bs=1024 count=12 conv=notrunc
$(sources): $(original)
	for file in $+; do \
	 $(sed) $$file | sed $(code16) | \
	 ./as_macro1.py > $$(basename $$file) \
	;done
/tmp/color.dsm: ../color.com
	objdump --target binary \
	 --architecture i386 \
	 --disassemble-all \
	 --disassembler-options=intel \
	 $< > $@
/tmp/gas_color.dsm: color.com
	objdump --target binary \
	 --architecture i386 \
	 --disassemble-all \
	 --disassembler-options=intel \
	 $< > $@
asmdiff: /tmp/color.dsm /tmp/gas_color.dsm
	diff -y -W180 $+
set:
	set
diff:	sources.txt original.txt
	-diff -W180 -y $+
sources.txt: $(sources)
	cat $+ > $@
original.txt: $(original)
	cat $+ > $@
clean:
	rm -f sources.txt original.txt *.{o,bin,out,dmp}
download: $(original) # in case we accidentally overwrote them (shit happens)
	for file in $+; do \
	fetch=$$(echo $$(basename $$file) | tr 'a-z' 'A-Z') && \
	 wget -O $$file http://ftp.ultratechnology.com/$$fetch \
	 ;done
	sed -i 's/\r//' $+ # get rid of embedded CRs from DOS
firstpass: color.asm instruction_fixup.sh
	$(GAS) $< 2>&1 | ./instruction_fixup.sh
	touch $@
secondpass: color.asm firstpass
	$(GAS) $< 2>&1 | ./instruction_fixup.sh 2
	touch $@
regex:
	@echo Use as follows: 'make REGEX="directives offset" regex'
	@echo Full list of recipes: $(recipes)
	@echo Remember that some depend on others to run first!
	[ "$(REGEX)" ] && $(regex_test) $(original)
errors:
	$(GAS) color.asm 2>&1 | ./show_error_lines.sh
errorcount:
	$(GAS) color.asm 2>&1 | wc -l
rcsdiff:
	cvs diff
ci:
	cvs commit
/tmp/color.xxd: ../color.com
	xxd $< > $@
/tmp/gas_color.xxd: color.com
	xxd $< > $@
bindiff: /tmp/color.xxd /tmp/gas_color.xxd
	diff -y -W180 $+
