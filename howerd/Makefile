TIMESTAMP := $(shell date +%Y%m%d%H%M)
GAS := as -R -Z -L
patch_sources := $(wildcard block???.asm)
patches = $(patch_sources:.asm=.dat)
test: ../test/b.img
	cd ../test && $(MAKE) minlog
../test/b.img: cfdos4.blk
	dd if=/dev/zero of=$@ bs=1024 count=1440
	dd if=$< of=$@ conv=notrunc
cfdos4.blk: /usr/src/howerd/cfdos4/CFDOS4.BLK ../jc2007/color.com $(patches)
	cd ../jc2007 && $(MAKE) newcode # need bigscreen
	dd if=/dev/zero of=$@ bs=1024 count=1440
	dd if=../jc2007/color.com of=$@ conv=notrunc bs=1024 count=12
	dd if=$< of=$@ conv=notrunc skip=12 seek=12 bs=1024
	for patch in $(patches); do \
	 declare block=$${patch:5:3} && \
	 dd if=patch.dat of=$@ conv=notrunc seek=$$block bs=1024; \
	done
cfdos4.ima.gz: ../test/b.img
	gzip -c $< > $@
upload: cfdos4.ima.gz
	for file in $+; do \
	 ncftpput -C upload.sourceforge.net $$file \
	  incoming/$(TIMESTAMP)-$$file; \
	done
qemu:	../test/b.img
	cd ../test && $(MAKE) vmclean qemu
vmware: ../test/b.img
	cd ../test && $(MAKE) vmclean vmware
clean:
	rm -f *.ima.gz *.blk
newcode.asm: ../jc2007/forth.asm
	cat $< > $@
	./cf2text cfdos4.blk | sed -n '/{block 18}/,$$p' | \
	 sed \
	 -e 's/\(.*\)/\L\1/' \
	 -e 's/\(\[\w*\]\)/\U\1/g' \
	 -e 's/{\(block [0-9]\+\)}/\U\1/' \
	 -e '/^[^B]/ s/\(\S\+\)/"\1",/g' \
	 -e 's/^\([^B]\)/FORTH \1/' \
	 -e 's/,\s*$$//' \
	 >> $@
	echo BLOCK >> $@
	echo BLOCK >> $@  # pad out one more block for even number
%.dat:	%.asm
	$(GAS) $(foreach definition,$(DEFINES),\
	 $(if $($(definition)),--defsym $(definition)=$($(definition)))) \
	 -ahlns=$*.lst --listing-cont-lines=10 \
	 --reduce-memory-overheads \
	 -o $*.o ../jc2007/forth.asm $<
	objcopy $*.o -O binary $@
