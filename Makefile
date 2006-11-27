SUBDIRS := $(wildcard [a-z]*)
export
set:
	set
clean:
	$(foreach subdir, $(SUBDIRS), \
	 $(shell [ -d $(subdir) ] && cd $(subdir) && make clean))
upload:
	rsync -avuz . jcomeau_ictx@colorforth.sourceforge.net:/home/groups/c/co/colorforth/htdocs/
