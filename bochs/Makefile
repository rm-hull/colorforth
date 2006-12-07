BOCHS := /usr/src/bochs
CF_BOCHS := $(PWD)
BOCHS_LOGIN :=  cvs \
 -d:pserver:anonymous@bochs.cvs.sourceforge.net:/cvsroot/bochs login
BOCHS_CHECKOUT :=  cvs -z3 \
 -d:pserver:anonymous@bochs.cvs.sourceforge.net:/cvsroot/bochs co -P bochs
export
# make bochsdbg.exe first because it builds as bochs.exe!
all:	$(BOCHS)/bochsdbg.exe $(BOCHS)/bochs.exe
force:
	$(MAKE) distclean
	touch Makefile
	$(MAKE) all
set:
	set
%.diff:
	-diff -y -W160 $* $(shell find $(BOCHS) -name "$*.orig")
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
	rm -f $(BOCHS)/bochs{,dbg}.exe
test:
	cd ../test && $(MAKE)
%.link:
	cd $(BOCHS)/iodev && ln -sf floppy.cc.$* floppy.cc
	cd $(BOCHS)/iodev && ln -sf floppy.h.$* floppy.h
links:	*.cc *.h
	for file in $+; do \
	 declare original=$$(find $(BOCHS) -maxdepth 2 -name $$file); \
	 if [ -f $$original.orig ]; then \
	  rm -f $$original; else \
	  mv -f $$original $$original.orig; \
	 fi; \
	( cd $$(dirname $$original) && \
	  ln -sf $(CF_BOCHS)/$$file $$file) ; \
	done
checkout:
	@[ -d $(BOCHS) ] && echo Already checked out || \
	 cd $(shell dirname $(BOCHS)); $(BOCHS_LOGIN); $(BOCHS_CHECKOUT)
