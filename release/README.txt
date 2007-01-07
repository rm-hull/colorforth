This is a demo of colorForth running under a patched Bochs emulator. You will
need to download the latest version of Bochs from bochs.sourceforge.net for
the necessary BIOS files. This has been tested with Bochs-2.3 only.

The emulation is incomplete. Currently you will not be able to write to the
floppy image, and keystroke recognition is slow, so be patient. You might
try changing the IPS (emulated instructions per second) in the bochsrc.bxrc
file, but I haven't had any luck with it higher or lower than its current
setting.

For documentation, see http://colorforth.com/. For a really quick start,
run cfbochs.bat, hit the spacebar once to get the numeric keyboard, and
type 56 (keys "kl"), space, then "load" (keys "psav"), then space. The "rose"
screen of hexagons should display. The keys uiojkl will adjust the red, green,
and blue settings, and keys "m" for minus and "/" for plus will adjust the
brightness. Alt-enter to get the top row of buttons back, and you can turn off
the emulator.

For even better documentation, search the web for "colorforth tutorial".
No coordinated effort has really yet emerged, but it's getting better.

Then there is always the source code! Follow the Code menu at
http://sourceforge.net/projects/colorforth/ to the CVS page, which gives
instructions for anonymous CVS access. The compilation (assembly, to be
precise) has only been tested under GNU/Cygwin under Windows XP.

Enjoy! -- jcATunternet.net
