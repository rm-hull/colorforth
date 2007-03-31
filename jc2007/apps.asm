BLOCK 64
FORTH [TEXTCAPITALIZED], mandelbrot, [TEXT], display, [EXECUTE], empty, [EXECUTE], forth, [VARIABLE], xl, [BINARY], 0, [VARIABLE], xr, [BINARY], 0, [VARIABLE], yt, [BINARY], 0, [VARIABLE], yb, [BINARY], 0, [VARIABLE], xspan, [BINARY], 0, [VARIABLE], yspan, [BINARY], 0, [VARIABLE], dark, [BINARY], 0, [VARIABLE], pause, [BINARY], 0, [VARIABLE], pixel, [BINARY], 0
FORTH allot, [TEXT], n-a, here, [COMPILESHORT], 3, +, [COMPILESHORT], 4, /, swap, for, 0, ",", next, ";", [VARIABLE], z, [BINARY], 0, [EXECUTE], hp, [EXECUTE], vp, [EXECUTE], "*", [EXECUTE], [EXECUTESHORT], 1, [EXECUTE], +, [EXECUTE], dup, [EXECUTE], "+", [EXECUTE], allot, [EXECUTE], z, [EXECUTE], "!" 
FORTH fixed, [EXECUTELONGHEX], 10000000, [EXECUTESHORT], 1000, [EXECUTE], /, *, ";"
FORTH abs, 0, or, -if, negate, then, ";"
FORTH z@, [TEXT], i-nn, [EXECUTE], z, @, +, dup, @, swap, 1+, @, ";"
FORTH ge4, [TEXT], n-f, ;# sets Z flag if abs(n) > 4
 FORTH [COMPILEWORD], abs, [EXECUTESHORT], -4000, [EXECUTE], fixed,
 FORTH [COMPILEWORD], +, drop, -if, 0, drop, then, ";"
;#FORTH g, ge4, if, 1, ";", then, 0, ";" ;# test word
FORTH four, [TEXT], n-, dup, z@, ge4, if, drop, drop, ";",
 FORTH [COMPILEWORD], then, ge4, if, drop, ";",
 FORTH [COMPILEWORD], then, dup, z@, dup, fx*, ge4, if, drop, drop, ";"
 FORTH [COMPILEWORD], then, dup, fx*, ge4, if, drop, ";"
 FORTH [COMPILEWORD], then, z@, dup, fx*, swap, dup, fx*, +, ge4, ";"
;#FORTH f, four, if, 1, ";", then, 0, ";" ;# test word
FORTH z!, [TEXT], nni-, [EXECUTE], z, @, +, dup, push, 1+, !, pop, !, ";"
FORTH [EXECUTESHORT], 66, [EXECUTE], load

BLOCK 65
FORTH allot, grabs, space, at, [COMPILEWORD], here, and, returns, that, "address;", z, points, to, the, array, of, values, as, generated, by, "z**2+z0"
FORTH [TEXT], xl, xr, yt, yb, are, the, start, limits, mapped, by, the, [TEXTCAPITALIZED], cartesian, "grid;", xspan, and, yspan, hold, the, x, and, y, ranges
FORTH z0, we, left, an, extra, space, at, end, of, [COMPILEWORD], z, array, for, z0, [TEXTALLCAPS], aka, c, in, z**2+c
FORTH z**2, the, square, of, complex, number, "a,", "b", is,  a**2, -, b**2, ",", 2a*b
FORTH iter, iterates, over, the, array, updating, continuously
FORTH init, initializes, variables
FORTH ok, sets, the, display, and, starts, the, generator

BLOCK 66
FORTH z0, [TEXT], -a, [EXECUTE], z, [EXECUTE], @,
 FORTH [EXECUTE], vp, [EXECUTE], hp, [EXECUTE], *, [EXECUTE], dup,
 FORTH [EXECUTE], +, [EXECUTE], +, ";"
FORTH x0, [COMPILELONGHEX], 10000000, hp, */, ;# scale to A(3,28) fixed
 FORTH [EXECUTE], xspan, @, fx*, [EXECUTE], xl, @, +, ";"
FORTH y0, [COMPILELONGHEX], 10000000, vp, */, ;# make fixed-point number
 FORTH [EXECUTE], yspan, @, fx*, negate, [EXECUTE], yt, @, +, ";"
FORTH check, over, over, ;# leave two items on the stack
 FORTH [COMPILESHORT], 3, [COMPILESHORT], 200, at, h., space, h., ";"
FORTH p, [EXECUTE], pause, dup, @, 1, or, swap, !, ";" ;# toggle
FORTH z**2, [TEXT], n-, dup, push, z@, dup, fx*, dup, ge4, swap, ;# b**2 a
 FORTH [COMPILEWORD], if, pop, z!, ";", then, dup, fx*, dup, ge4, swap,
 FORTH [COMPILEWORD], if, pop, z!, ";", then, negate, +,
 FORTH [COMPILEWORD], pop, dup, push, z@, fx*, dup, ge4,
 FORTH [COMPILEWORD], if, pop, z!, ";", then, 2*, pop, z!, ";"
FORTH z0!, [TEXT], n-, hp, /mod, y0, z0, 1+, !, x0, z0, !, ";"
FORTH z2+c, [TEXT], n-, dup, z**2, dup, four, if, drop, ";"
 FORTH [COMPILEWORD], then, dup, dup, push, z0!, z@,
 FORTH [COMPILEWORD], z0, 1+, @, +, swap, z0, @, +, swap, pop, z!, ";"
FORTH init, [TEXT], -2.1,
 FORTH [EXECUTESHORT], -2100, [EXECUTE], fixed, nop, [EXECUTE], xl, "!",
 FORTH [TEXT], 1.1,
 FORTH [EXECUTESHORT], 1100, [EXECUTE], fixed, nop, [EXECUTE], xr, "!",
 FORTH [TEXT], 1.2,
 FORTH [EXECUTESHORT], 1200, [EXECUTE], fixed, nop, [EXECUTE], yt, "!",
 FORTH [TEXT], -1.2,
 FORTH [EXECUTESHORT], -1200, [EXECUTE], fixed, nop, [EXECUTE], yb, "!",
 FORTH [EXECUTE], xr, @, [EXECUTE], xl, @, negate, +,
 FORTH [EXECUTE], xspan, !,
 FORTH [EXECUTE], yt, @, [EXECUTE], yb, @, negate, +,
 FORTH [EXECUTE], yspan, !,
 FORTH [COMPILESHORT], -8, [EXECUTE], dark, !
 FORTH [COMPILEWORD], ";"
FORTH wait, [TEXT], n-, for, next, ";"
FORTH update, [TEXT], n-, dup, four, if, drop, ";", then,
 FORTH [COMPILEWORD], dup, z2+c, dup, four, if, drop, ";", then,
 FORTH [COMPILEWORD], 2/, vframe, +, [EXECUTE], dark, @, swap, +!, ";"
FORTH u, [EXECUTESHORT], 300, [EXECUTE], hp, [EXECUTE], *, [COMPILESHORT], 10,
 FORTH [COMPILEWORD], for, over, +, update, next, ";"
;# put "show" before "blue, screen" for debugging; after for raster graphics
FORTH ok, init, blue, screen, show, keyboard, debug,
 FORTH [EXECUTE], pixel, @, update,
 FORTH [EXECUTE], pixel, @, z@, swap, check, drop, drop,
 FORTH [EXECUTE], pixel, @, 1+, [EXECUTE], hp, [EXECUTE], vp, [EXECUTE], *,
 FORTH [COMPILEWORD], mod, [EXECUTE], pixel, !, ";"
BLOCK
