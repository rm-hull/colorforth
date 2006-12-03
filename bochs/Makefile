BOCHS := /usr/src/bochs
export
bochs:
	cd $(BOCHS) && $(MAKE)
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
configure:
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
debug_config:
	$(MAKE) DEBUG_CONFIG="--enable-debugger --enable-disasm" configure
$(BOCHS)/bochs.exe:
	$(MAKE) configure
	cd $(BOCHS) && $(MAKE)
$(BOCHS)/bochsdbg.exe:
	$(MAKE) debug_config
	cd $(BOCHS) && $(MAKE) && mv bochs.exe bochsdbg.exe
