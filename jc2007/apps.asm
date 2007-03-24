BLOCK 64
FORTH [TEXTCAPITALIZED], mandelbrot, [TEXT], display, [EXECUTE], empty, [EXECUTE], forth, [VARIABLE], xl, [BINARY], 0, [VARIABLE], xr, [BINARY], 0, [VARIABLE], yt, [BINARY], 0, [VARIABLE], yb, [BINARY], 0, [VARIABLE], xspan, [BINARY], 0, [VARIABLE], yspan, [BINARY], 0, [VARIABLE], xnow, [BINARY], 0, [VARIABLE], ynow, [BINARY], 0
FORTH allot, [TEXT], n-a, here, swap, for, 0, ",", next, ";", [VARIABLE], z, [BINARY], 0, [EXECUTE], hp, [EXECUTE], vp, [EXECUTE], "*", [EXECUTE], dup, [EXECUTE], "+", [EXECUTE], allot, [EXECUTE], z, [EXECUTE], "!"
FORTH iter, [EXECUTE], hp, [EXECUTE], vp, [EXECUTE], "*",
 FORTH [COMPILEWORD], for, i, z, "@", over, "+",
 FORTH [COMPILESHORT], "-1", "+", ;# zero-base the index into 'z' table
 FORTH [COMPILEWORD], "!", next, ";"
FORTH init, [TEXT], "-2.1", [EXECUTE], fixed, nop, [EXECUTE], xl, "!", [TEXT], "1.1", [EXECUTE], fixed, nop, [EXECUTE], xr, "!", [TEXT], "1.2", [EXECUTE], fixed, nop, [EXECUTE], yt, "!", [TEXT], "-1.2", [EXECUTE], fixed, nop, [EXECUTE], yb, "!", [EXECUTE], xr, "@", [EXECUTE], xl, "@", negate, "+", [EXECUTE], xspan, "!", [EXECUTE], yt, "@", [EXECUTE], yb, "@", negate, "+", [EXECUTE], yspan, "!", ";"
FORTH ok, show, black, screen, iter, keyboard, ";"
BLOCK 65
FORTH [TEXT], xl, xr, yt, yb, are, the, start, limits, mapped, by, the, [TEXTCAPITALIZED], cartesian, "grid;", xspan, and, yspan, hold, the, x, and, y, ranges
FORTH allot, grabs, space, at, [COMPILEWORD], here, and, returns, that, "address;", z, points, to, the, array, of, values, as, generated, by, "z**2+z0"
FORTH iter, iterates, over, the, array, updating, continuously
FORTH init, initializes, variables
FORTH ok, sets, the, display, and, starts, the, generator
BLOCK
