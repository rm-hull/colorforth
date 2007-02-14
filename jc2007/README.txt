In an attempt to simplify the colorForth bootcode, I am attempting the
following changes:

* using unreal mode to allow BIOS calls while having use of 32-bit registers
* doing all floppy I/O using BIOS calls
* using a text video mode rather than bitmapped graphics
* not creating a .com file, just a floppy image, avoiding MS-DOS problems

This will hopefully eliminate the weirdness that causes the binaries to fail
on QEMU, Bochs, and VMWare.

jc.jcomeau.com 2007-02-13
