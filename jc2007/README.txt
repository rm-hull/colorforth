In an attempt to simplify the colorForth bootcode, I am attempting the
following changes:

* using unreal mode to allow BIOS calls while having use of 32-bit registers
* doing all floppy I/O using BIOS calls
? using a text video mode rather than bitmapped graphics
  (did that, but only during startup)
? not creating a .com file, just a floppy image, avoiding MS-DOS problems
  (saved it for later, but am working on color.com now that BIOS stuff works)

This will hopefully, eventually, eliminate the weirdness that causes the 
binaries to fail on QEMU, Bochs, and VMWare. As of this version, there are
still problems with VMWare at least. I'd like to hear from anyone who has
tested this version under QEMU or natively on a real desktop computer using
a boot floppy created from the image file.

Programmer's notes:

* this Forth doesn't actually put the top stack element ON the stack; it leaves
  it in EAX. So, if you want a routine to return something on the data stack,
  FIRST do a 'dup' to save what's in EAX to the stack; then load EAX with
  whatever and return.

* to make programs compatible with both 800x600 and 1024x768 video modes, use
  the "vp", "hp", "iw", and "ih" constants now available in high-level Forth.

* to make programs compatible with the load offset, which in this version is
  no longer 0, use "off" (in 32-bit words) or "off 4 *" in bytes.

jcATunternet.net
