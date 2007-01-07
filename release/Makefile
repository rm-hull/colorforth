BOCHS := /cygdrive/c/Program\ Files/Bochs-2.3
BOCHS_SRC := /usr/src/bochs
CF_SRC := ~/src
BXSHARE := $(shell cygpath -w $(BOCHS))
CFIMAGE := a.img
export
cfbochs.zip: bochs.exe bochsdbg.exe a.img bochsrc.bxrc cfbochs.bat README.txt
	cp -f $+ cfBochs
	zip -r $@ cfBochs
a.img:	$(CF_SRC)/colorforth/as/color.com
	dd if=/dev/zero of=$@ bs=1024 count=1440
	dd if=$< of=$@ conv=notrunc
set:
	set
test:	cfbochs.zip
	cp $< /cygdrive/c/WINDOWS/Temp/
clean:
	rm -f *.exe a.img *.zip cfBochs/*
%.exe:
	ln -sf $(BOCHS_SRC)/$@ .
