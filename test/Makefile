BOCHS := /cygdrive/c/Program\ Files/Bochs-2.3
BOCHS_SRC := /usr/src/bochs
CF_SRC := ~/src
VMWARE := /cygdrive/c/Program\ Files/VMWare/VMware\ Player
BXSHARE := $(shell cygpath -w $(BOCHS))
oldcf := a.img
newcf := b.img
export
default: newbxnewcf
oldbx%: template.bxrc a.img b.img
	-export BXRC=$@ && \
	export BOOTFLOPPY=$($*) && \
	export OTHERFLOPPY=$(filter-out $< $($*),$+) && \
	if [ "$(BXDEBUG)" ]; then \
	 $(BOCHS)/bochsdbg -f template.bxrc -q; \
	else \
	 $(BOCHS)/bochs -f $< -q; \
	fi
	sed -i 's/\r//' $@.txt
	uniq -f 1 -c $@.txt > $@.uniq.txt
	less $@.uniq.txt
newbx%: template.bxrc a.img b.img
	-export BXRC=$@ && \
	export BOOTFLOPPY=$($*) && \
	export OTHERFLOPPY=$(filter-out $< $($*),$+) && \
	if [ "$(BXDEBUG)" ]; then \
	 $(BOCHS_SRC)/bochsdbg -f $< -q; \
	else \
	 $(BOCHS_SRC)/bochs -f $< -q; \
	fi
	sed -i 's/\r//' $@.txt
	uniq -f 1 -c $@.txt > $@.uniq.txt
	less $@.uniq.txt
a.img:	$(CF_SRC)/colorforth/color.com
	dd if=/dev/zero of=$@ bs=1024 count=1440
	dd if=$< of=$@ conv=notrunc
b.img:	$(CF_SRC)/colorforth/as/color.com
	dd if=/dev/zero of=$@ bs=1024 count=1440
	dd if=$< of=$@ conv=notrunc
vmware: cf.vmx a.img
	$(VMWARE)/vmplayer.exe cf.vmx
clean:
	rm -f new*.txt old*.txt cf.{vmem,vmss,vmsd} *.img *.log *.vmem \
	 *.vmem.lck *.nvram *.dbg
set:
	set
