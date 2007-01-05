This is the current focus of my (jc's) development of colorForth. Originally
a bunch of sed recipes translated the masm sources into something acceptable
to GNU's "as" assembler, but now it's gone far beyond that, with even a macro
that creates the packed words.

Some items to note.

When you 'make debug' using the fullscreen image, be aware that you'll need to
click the screen in order for colorForth to see the keystrokes. Even though
the whole screen is occupied by the colorForth logo, in actuality the console
is in the foreground as far as Windows events are concerned, until you click
somewhere in the logo.

When colorForth starts up with the default Dvorak keyboard, you need to hit
the spacebar to get it into numeric entry mode. The 'alt' key also shows
numeric digits, but those are actually just text characters of decimal digits;
you can't enter "20 load" using this extended keyboard because it treats the
"20" as a text word, which it can't find in the dictionary.

The screen refresh takes up so much time in the Bochs emulator, you will get
very slow recognition of keyhits. Take your time and try not to curse.
