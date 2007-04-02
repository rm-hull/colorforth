BLOCK 64
FORTH [TEXTCAPITALIZED], mandelbrot, [TEXT], display, [EXECUTE], empty, [EXECUTE], forth, [VARIABLE], xl, [BINARY], 0, [VARIABLE], xr, [BINARY], 0, [VARIABLE], yt, [BINARY], 0, [VARIABLE], yb, [BINARY], 0, [VARIABLE], xspan, [BINARY], 0, [VARIABLE], yspan, [BINARY], 0, [VARIABLE], dark, [BINARY], 0, [VARIABLE], pixel, [BINARY], 0, [VARIABLE], count, [BINARY], 0
FORTH zlen, [EXECUTE], hp, [EXECUTE], vp, [EXECUTE], *, [EXECUTE], 1+,
 FORTH [EXECUTE], dup, [EXECUTE], +, ";"
FORTH allot, [TEXT], n-a, align, here, dup, push, +, here!, pop, ";"
 FORTH [VARIABLE], z, [BINARY], 0, [EXECUTE], zlen, [EXECUTE], cells,
 FORTH [EXECUTE], allot, [EXECUTE], 1, [EXECUTE], cells, [EXECUTE], /,
 FORTH [EXECUTE], z, [EXECUTE], !
FORTH abs, 0, or, -if, negate, then, ";"
FORTH fixed, [EXECUTELONGHEX], 10000000, [EXECUTESHORT], 10000, [EXECUTE], /, *, ";"
FORTH clear, blue, screen, zlen, [EXECUTE], z, @, zero, 0,
 FORTH [EXECUTE], pixel, !, ";"
FORTH reinit,
 FORTH [EXECUTE], xr, @, [EXECUTE], xl, @, negate, +,
 FORTH [EXECUTE], xspan, !,
 FORTH [EXECUTE], yt, @, [EXECUTE], yb, @, negate, +,
 FORTH [EXECUTE], yspan, !,
 FORTH [COMPILEWORD], ";"
FORTH init, [TEXT], -2.1,
 FORTH [EXECUTESHORT], -21000, [EXECUTE], fixed, nop, [EXECUTE], xl, "!",
 FORTH [TEXT], 1.1,
 FORTH [EXECUTESHORT], 11000, [EXECUTE], fixed, nop, [EXECUTE], xr, "!",
 FORTH [TEXT], 1.2,
 FORTH [EXECUTESHORT], 12000, [EXECUTE], fixed, nop, [EXECUTE], yt, "!",
 FORTH [TEXT], -1.2,
 FORTH [EXECUTESHORT], -12000, [EXECUTE], fixed, nop, [EXECUTE], yb, "!",
 FORTH [COMPILESHORT], -1, [EXECUTE], dark, !
 FORTH [COMPILESHORT], 5000, [EXECUTE], count, !
 FORTH [COMPILEWORD], ";"
FORTH fb, [TEXT], -a, [TEXT], framebuffer, [EXECUTE], vframe,
 FORTH [EXECUTESHORT], 4, [EXECUTE], *, ";"
FORTH darker, [TEXT], n-, 2*, fb, +, dup, w@, 0, +, drop, if,
 FORTH [EXECUTE], dark, @, swap, +w!, ";", then, drop, ";"
FORTH z@, [TEXT], i-nn, 2*, [EXECUTE], z, @, +, dup, @, swap, 1+, @, ";"
FORTH ge4, [TEXT], n-f, ;# sets Z flag if abs(n) > 4
 FORTH [COMPILEWORD], abs, [EXECUTESHORT], -40001, [EXECUTE], fixed,
 FORTH [COMPILEWORD], +, drop, -if, 0, drop, then, ";"
FORTH four, [TEXT], n-, dup, z@, ge4, if, drop, drop, ";",
 FORTH [COMPILEWORD], then, ge4, if, drop, ";",
 FORTH [COMPILEWORD], then, dup, z@, dup, fx*, ge4, if, drop, drop, ";"
 FORTH [COMPILEWORD], then, dup, fx*, ge4, if, drop, ";"
 FORTH [COMPILEWORD], then, z@, dup, fx*, swap, dup, fx*, +, ge4, ";"
FORTH [EXECUTESHORT], 2, [EXECUTE], +load,
 FORTH [EXECUTESHORT], 4, [EXECUTE], +load
 FORTH [EXECUTE], ok, [EXECUTE], h
BLOCK 65
FORTH allot, grabs, space, at, [COMPILEWORD], here, and, returns, that, "address;", z, points, to, the, array, of, values, as, generated, by, "z**2+z0"
FORTH [TEXT], xl, xr, yt, yb, are, the, start, limits, mapped, by, the, [TEXTCAPITALIZED], cartesian, "grid;", xspan, and, yspan, hold, the, x, and, y, ranges
FORTH z0, we, left, an, extra, space, at, end, of, [COMPILEWORD], z, array, for, z0, [TEXTALLCAPS], aka, c, in, z**2+c
FORTH z**2, the, square, of, complex, number, "a,", "b", is,  a**2, -, b**2, ",", 2a*b
FORTH iter, iterates, over, the, array, updating, continuously
FORTH init, initializes, variables
FORTH ok, sets, the, display, and, starts, the, generator

BLOCK 66
FORTH z!, [TEXT], nni-, 2*, [EXECUTE], z, @, +, dup, push, 1+, !, pop, !, ";"
FORTH x0, [COMPILELONGHEX], 10000000, hp, */, ;# scale to A(3,28) fixed
 FORTH [EXECUTE], xspan, @, fx*, [EXECUTE], xl, @, +, ";"
FORTH y0, [COMPILELONGHEX], 10000000, vp, */, ;# make fixed-point number
 FORTH [EXECUTE], yspan, @, fx*, negate, [EXECUTE], yt, @, +, ";"
FORTH z0, [TEXT], -a, [EXECUTE], z, [EXECUTE], @, [EXECUTE], zlen,
 FORTH [EXECUTESHORT], -2, [EXECUTE], +, [EXECUTE], +, ";"
FORTH z0!, [TEXT], n-, hp, /mod, y0, z0, 1+, !, x0, z0, !, ";"
FORTH z**2, [TEXT], n-, dup, push, z@, dup, fx*, dup, ge4, swap, ;# b**2 a
 FORTH [COMPILEWORD], if, pop, z!, ";", then, dup, fx*, dup, ge4, swap,
 FORTH [COMPILEWORD], if, pop, z!, ";", then, negate, +,
 FORTH [COMPILEWORD], pop, dup, push, z@, fx*, dup, ge4,
 FORTH [COMPILEWORD], if, pop, z!, ";", then, 2*, pop, z!, ";"
FORTH z2+c, [TEXT], n-, dup, z**2, dup, four, if, drop, ";"
 FORTH [COMPILEWORD], then, dup, dup, push, z0!, z@,
 FORTH [COMPILEWORD], z0, 1+, @, +, swap, z0, @, +, swap, pop, z!, ";"
FORTH update, [TEXT], n-, dup, four, if, drop, ";", then,
 FORTH [COMPILEWORD], dup, z2+c, dup, four, if, drop, ";", then, darker, ";"
FORTH iter,
 FORTH [EXECUTE], count, @, for,
 FORTH [EXECUTE], pixel, @, update,
 FORTH [EXECUTE], pixel, @, 1+, [EXECUTE], hp, [EXECUTE], vp, [EXECUTE], *,
 FORTH [COMPILEWORD], mod, [EXECUTE], pixel, !, next, ";"
BLOCK 67
BLOCK 68
FORTH +zoom, [EXECUTE], xl, @, 2/, [EXECUTE], xl, !,
 FORTH [EXECUTE], xr, @, 2/, [EXECUTE], xr, !, 
 FORTH [EXECUTE], yb, @, 2/, [EXECUTE], yb, !,
 FORTH [EXECUTE], yt, @, 2/, [EXECUTE], yt, !, 0, [EXECUTE], xspan, !, ";"
FORTH -zoom, [EXECUTE], xl, @, 2*, [EXECUTE], xl, !,
 FORTH [EXECUTE], xr, @, 2*, [EXECUTE], xr, !,
 FORTH [EXECUTE], yb, @, 2*, [EXECUTE], yb, !,
 FORTH [EXECUTE], yt, @, 2*, [EXECUTE], yt, !, 0, [EXECUTE], xspan, !, ";"
FORTH left, [EXECUTE], xspan, @, [COMPILESHORT], 10, /, negate, dup,
 FORTH [EXECUTE], xl, @, +, ge4, if, drop, drop, ";", then, dup,
 FORTH [EXECUTE], xl, +!, [EXECUTE], xr, +!, 0, [EXECUTE], xspan, !, ";"
FORTH right, [EXECUTE], xspan, @, [COMPILESHORT], 10, /, dup,
 FORTH [EXECUTE], xr, @, +, ge4, if, drop, drop, ";", then, dup,
 FORTH [EXECUTE], xl, +!, [EXECUTE], xr, +!, 0, [EXECUTE], xspan, !, ";"
FORTH up, ";"
FORTH down, ";"
FORTH nul, ";"
FORTH h, pad, nul, accept, -zoom, +zoom,
 FORTH [COMPILEWORD], nul, nul, nul, nul,  nul, nul, nul, nul,
 FORTH [COMPILEWORD], left, up, down, right, nul, nul, nul, nul,
 FORTH [COMPILEWORD], nul, nul, nul, nul,  nul, nul, nul, nul,
 FORTH [EXECUTESHORTHEX], 2b2325 [EXECUTE], ",",
 FORTH [EXECUTESHORT], 0, [EXECUTE], ","
 FORTH [EXECUTESHORT], 0, [EXECUTE], ",",
 FORTH [EXECUTELONGHEX], 110160c, [EXECUTE], ","
 FORTH [EXECUTESHORT], 0, [EXECUTE], ",",
 FORTH [EXECUTESHORT], 0, [EXECUTE], ","
 FORTH [EXECUTESHORT], 0, [EXECUTE], ","
;# put "show" before "blue, screen" for debugging; after for raster graphics
;# actually, the latter doesn't work with vmware when "ok'd" from source
FORTH  ok, init, show, [EXECUTE], xspan, @, -1, +, drop, -if,
 FORTH [COMPILEWORD], reinit, clear, then, iter, keyboard, ";"
BLOCK 69
FORTH clear, wipes, out, the, [COMPILEWORD], z, array, and, clears, screen
FORTH +zoom, zooms, in, 2, times, closer
FORTH h, sets, up, keypad
BLOCK
