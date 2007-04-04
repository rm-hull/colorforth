BOCHS := /cygdrive/c/Program\ Files/Bochs-2.3
BOCHS_SRC := /usr/src/bochs
CF_SRC := ~/src
BXSHARE := $(shell cygpath -w $(BOCHS))
TIMESTAMP := $(shell date +%Y%m%d%H%M)
NSIS := /cygdrive/c/Program\ Files/NSIS/makensis.exe
export
cf_emu.exe: cf_emu.nsi LICENSE.rtf README.rtf 1024x768.ima 800x600.ima \
 bochs.exe
	$(NSIS) $<
1024x768.ima: $(CF_SRC)/colorforth/jc2007/
	cd $< && $(MAKE) newcode
	dd if=/dev/zero of=$@ bs=1024 count=1440
	dd if=$</color.dat of=$@ conv=notrunc
800x600.ima: $(CF_SRC)/colorforth/jc2007/
	cd $< && $(MAKE) small
	dd if=/dev/zero of=$@ bs=1024 count=1440
	dd if=$</color.dat of=$@ conv=notrunc
%.ima.gz: %.ima
	gzip -c $< > $@
set:
	set
clean:
	rm -f *.exe a.ima *.zip *.rtf cfBochs/* LICENSE.txt *.zip
%.exe:
	cp -f $(BOCHS_SRC)/$@ .
upload: cf_emu.exe 800x600.ima.gz 1024x768.ima.gz
	for file in $+; do \
	 ncftpput -C upload.sourceforge.net $$file \
	  incoming/$(TIMESTAMP)-$$file; \
	done
LICENSE.txt: NOLICENSE.txt /usr/src/bochs/COPYING
	cat $+ > $@
nsiscommands:
	$(NSIS) /CMDHELP
nsishelp:
	$(NSIS) /?
%.rtf: %.txt  # to force association to something other than Notepad
	cp $< $@
