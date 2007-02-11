BOCHS := /cygdrive/c/Program\ Files/Bochs-2.3
BOCHS_SRC := /usr/src/bochs
CF_SRC := ~/src
BXSHARE := $(shell cygpath -w $(BOCHS))
CFIMAGE := a.img
TIMESTAMP := $(shell date +%Y%m%d%H%M)
NSIS := /cygdrive/c/Program\ Files/NSIS/makensis.exe
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
	cp -f $(BOCHS_SRC)/$@ .
upload: cfbochs.zip
	ncftpput -C upload.sourceforge.net $< incoming/cfbochs-$(TIMESTAMP).zip
cfbochs.exe: cfbochs.nsi LICENSE.txt cfbochs.zip
	$(NSIS) $<
LICENSE.txt: NOLICENSE.txt /usr/src/bochs/COPYING
	cat $+ > $@
nsiscommands:
	$(NSIS) /CMDHELP
nsishelp:
	$(NSIS) /?
