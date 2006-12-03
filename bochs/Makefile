BOCHS := /usr/src/bochs
export
# make bochsdbg.exe first because it builds as bochs.exe!
all:	$(BOCHS)/bochsdbg.exe $(BOCHS)/bochs.exe
set:
	set
%.diff:
	-diff -y -W160 $* $(shell find $(BOCHS) -name "$*.orig")
test:
	cd ../test && $(MAKE)
checkin:
	cd .. && cvs commit
cvsdiff:
	cd .. && cvs diff
configure: Makefile
	cd $(BOCHS) && ./configure \
	 --enable-vbe \
	 --enable-cirrus \
	 --enable-usb \
	 --enable-sb16 \
	 --enable-pci \
	 --enable-ne2000 \
	 --enable-fast-function-calls \
	 --enable-icache \
	 --enable-repeat-speedups \
	 --enable-guest2host-tlb \
	 --enable-sep \
	 --enable-pge \
	 --enable-pae \
	 --enable-sse \
	 --enable-apic \
	 --enable-cpu-level=6 \
	 --enable-readline \
	 $(DEBUG_CONFIG)
	touch $@
debug_config: Makefile
	rm -f configure
	$(MAKE) DEBUG_CONFIG="--enable-debugger --enable-disasm" configure
	rm -f configure
	touch $@
$(BOCHS)/bochs.exe: configure
	cd $(BOCHS) && $(MAKE)
$(BOCHS)/bochsdbg.exe: debug_config
	cd $(BOCHS) && $(MAKE) && mv bochs.exe bochsdbg.exe
distclean:
	rm $(BOCHS)/bochs{,dbg}.exe
test:
	cd ../test && $(MAKE)
