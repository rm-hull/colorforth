BLOCK 64
FORTH [TEXTCAPITALIZED], mandelbrot, [TEXT], display, [EXECUTE], empty, [EXECUTE], forth, [VARIABLE], xl, [BINARY], 0, [VARIABLE], xr, [BINARY], 0, [VARIABLE], yt, [BINARY], 0, [VARIABLE], yb, [BINARY], 0, [VARIABLE], xspan, [BINARY], 0, [VARIABLE], yspan, [BINARY], 0, [VARIABLE], xnow, [BINARY], 0, [VARIABLE], ynow, [BINARY], 0
FORTH allot, [TEXT], n-a, here, swap, for, 0, ",", next, ";", [VARIABLE], z, [BINARY], 0, [EXECUTE], hp, [EXECUTE], vp, [EXECUTE], "*", [EXECUTE], dup, [EXECUTE], "+", [EXECUTE], allot, [EXECUTE], z, [EXECUTE], "!"
FORTH x, [EXECUTE], xnow, @, ";"
FORTH y, [EXECUTE], ynow, @, ";"
FORTH pnext, x, [COMPILESHORT], 1, +, hp, mod,
 FORTH [EXECUTE], xnow, "!", ;# increment x
 FORTH [COMPILEWORD], x, if, drop, ";", # done if x nonzero
 FORTH [COMPILEWORD], then, y, [COMPILESHORT], 1, +, vp, mod, ;# increment y
 FORTH [EXECUTE], ynow, "!", ";"
FORTH check, over, over, ;# leave two items on the stack
 FORTH [COMPILESHORT], 3, [COMPILESHORT], 200, h., space, h., ";"
FORTH iter, ;# iterate through the array of complex numbers, updating
 ;# this does one pixel at a time
 FORTH [COMPILEWORD], x, y, hp, *, over, over, +, ;# locate pixel
 FORTH [COMPILESHORT], -1, +, 2*, ;# zero-base index into 'z' table
 FORTH [EXECUTE], z, @, +, dup, !, ;# for now just store its own addr in it
 FORTH [COMPILEWORD], +, dup, vframe, +, !,  ;# store x+y in framebuffer
 FORTH [COMPILEWORD], pnext, ";"
FORTH init, [TEXT], "-2.1", [EXECUTE], fixed, nop, [EXECUTE], xl, "!", [TEXT], "1.1", [EXECUTE], fixed, nop, [EXECUTE], xr, "!", [TEXT], "1.2", [EXECUTE], fixed, nop, [EXECUTE], yt, "!", [TEXT], "-1.2", [EXECUTE], fixed, nop, [EXECUTE], yb, "!", [EXECUTE], xr, "@", [EXECUTE], xl, "@", negate, "+", [EXECUTE], xspan, "!", [EXECUTE], yt, "@", [EXECUTE], yb, "@", negate, "+", [EXECUTE], yspan, "!", ";"
FORTH ok, black, screen, show, keyboard, debug, iter, ";"
BLOCK 65
FORTH [TEXT], xl, xr, yt, yb, are, the, start, limits, mapped, by, the, [TEXTCAPITALIZED], cartesian, "grid;", xspan, and, yspan, hold, the, x, and, y, ranges
FORTH allot, grabs, space, at, [COMPILEWORD], here, and, returns, that, "address;", z, points, to, the, array, of, values, as, generated, by, "z**2+z0"
FORTH iter, iterates, over, the, array, updating, continuously
FORTH init, initializes, variables
FORTH ok, sets, the, display, and, starts, the, generator
BLOCK
