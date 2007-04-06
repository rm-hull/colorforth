BLOCK 64
FORTH [TEXTCAPITALIZED], mandelbrot, [TEXT], display, [EXECUTE], empty, [EXECUTE], forth, [VARIABLE], xl, [BINARY], 0, [VARIABLE], xr, [BINARY], 0, [VARIABLE], yt, [BINARY], 0, [VARIABLE], yb, [BINARY], 0, [VARIABLE], xspan, [BINARY], 0, [VARIABLE], yspan, [BINARY], 0, [VARIABLE], dark, [BINARY], 0, [VARIABLE], pixel, [BINARY], 0, [VARIABLE], count, [BINARY], 0
FORTH zlen, [EXECUTE], hp, [EXECUTE], vp, [EXECUTE], *, [EXECUTE], 1+,
 FORTH [EXECUTE], dup, [EXECUTE], +, ";"
FORTH allot, [TEXT], n-a, align, here, dup, push, +, here!, pop, ";"
 FORTH [VARIABLE], z, [BINARY], 0, [EXECUTE], zlen, [EXECUTE], cells,
 FORTH [EXECUTE], allot, [EXECUTE], 1, [EXECUTE], cells, [EXECUTE], /,
 FORTH [EXECUTE], z, [EXECUTE], !
FORTH abs, 0, or, -if, negate, then, ";"
FORTH fixed, [COMPILELONGHEX], 10000000, [COMPILESHORT], 10000, */, ";"
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
 FORTH [COMPILEWORD], abs, [EXECUTESHORT], -40000, [EXECUTE], fixed,
 FORTH [COMPILEWORD], +, drop, -if, 0, drop, then, ";"
FORTH four, [TEXT], n-, dup, z@, ge4, if, drop, drop, ";",
 FORTH [COMPILEWORD], then, ge4, if, drop, ";",
 FORTH [COMPILEWORD], then, dup, z@, dup, fx*, ge4, if, drop, drop, ";"
 FORTH [COMPILEWORD], then, dup, fx*, ge4, if, drop, ";"
 FORTH [COMPILEWORD], then, z@, dup, fx*, swap, dup, fx*, +, ge4, ";"
FORTH z!, [TEXT], nni-, 2*, [EXECUTE], z, @, +, dup, push, 1+, !, pop, !, ";"
FORTH x0, [COMPILELONGHEX], 10000000, hp, */, ;# scale to A(3,28) fixed
 FORTH [EXECUTE], xspan, @, fx*, [EXECUTE], xl, @, +, ";"
FORTH [EXECUTESHORT], 2, [EXECUTE], +load,
 FORTH [EXECUTESHORT], 4, [EXECUTE], +load
 FORTH [EXECUTE], ok, [EXECUTE], h
BLOCK 65
FORTH zlen, helper, word, returns, length, of, z, array
FORTH allot, grabs, space, at, [COMPILEWORD], here, and, returns, that, "address;", z, points, to, the, array, of, values, as, generated, by, "z**2+z0"
FORTH abs, absolute, value
FORTH fixed, convert, to, fixed, point
FORTH clear, wipes, out, the, [COMPILEWORD], z, array, and, clears, screen
FORTH reinit, sets, [COMPILEWORD], xspan, and, [COMPILEWORD], yspan
FORTH init, sets, screen, boundaries, based, on, zoom, and, pan, settings
FORTH fb, returns, framebuffer, byte, address
FORTH darker, changes, pixel, color
FORTH z@, returns, complex, number, at, specified, index
FORTH ge4, checks, if, fixed-point, number, above, 4
FORTH four, check, if, complex, number, above, 4
FORTH z!, stores, complex, number, at, specified, index
FORTH x0, creates, real, part, of, complex, number, at, specified, index
BLOCK 66
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
FORTH +zoom, [EXECUTE], xl, @, 2/, [EXECUTE], xl, !,
 FORTH [EXECUTE], xr, @, 2/, [EXECUTE], xr, !, 
 FORTH [EXECUTE], yb, @, 2/, [EXECUTE], yb, !,
 FORTH [EXECUTE], yt, @, 2/, [EXECUTE], yt, !, 0, [EXECUTE], xspan, !, ";"
FORTH -zoom, [EXECUTE], xl, @, 2*, [EXECUTE], xl, !,
 FORTH [EXECUTE], xr, @, 2*, [EXECUTE], xr, !,
 FORTH [EXECUTE], yb, @, 2*, [EXECUTE], yb, !,
 FORTH [EXECUTE], yt, @, 2*, [EXECUTE], yt, !, 0, [EXECUTE], xspan, !, ";"
FORTH left, [EXECUTE], xspan, @, [COMPILESHORT], 10, /, negate, dup,
 FORTH [EXECUTE], xl, @, +, ge4, if, drop, ";", then, dup,
 FORTH [EXECUTE], xl, +!, [EXECUTE], xr, +!, 0, [EXECUTE], xspan, !, ";"
FORTH right, [EXECUTE], xspan, @, [COMPILESHORT], 10, /, dup,
 FORTH [EXECUTE], xr, @, +, ge4, if, drop, ";", then, dup,
 FORTH [EXECUTE], xl, +!, [EXECUTE], xr, +!, 0, [EXECUTE], xspan, !, ";"
BLOCK 67
FORTH y0, creates, imaginary, part, of, complex, number, at, specified, index
FORTH z0, returns, address, of, temporary, storage, for, z0, the, constant, value, for, this, index
FORTH z0!, generate, complex, number, z0, [TEXTALLCAPS], aka, c, of, z2+c, for, this, index
FORTH z**2, the, square, of, complex, number, "a,", "b", is,  a**2, -, b**2, ",", 2a*b
FORTH z2+c, calculate, z**2, +, c
FORTH update, z, and, pixel, if, not, already, past, the, limit
FORTH iter, iterates, over, the, array, updating, continuously
FORTH +zoom, zooms, in, 2, times, closer
FORTH -zoom, zooms, out
FORTH left, pans, left, 1/10, of, screen
FORTH right, pans, right
BLOCK 68
FORTH up, [EXECUTE], yspan, @, [COMPILESHORT], 10, /, dup,
 FORTH [EXECUTE], yt, @, +, ge4, if, drop, ";", then, dup,
 FORTH [EXECUTE], yt, +!, [EXECUTE], yb, +!, 0, [EXECUTE], xspan, !, ";"
FORTH down, [EXECUTE], yspan, @, [COMPILESHORT], 10, /, negate, dup,
 FORTH [EXECUTE], yb, @, +, ge4, if, drop, ";", then, dup,
 FORTH [EXECUTE], yt, +!, [EXECUTE], yb, +!, 0, [EXECUTE], xspan, !, ";"
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
FORTH up, pans, upwards
FORTH down, pans, downwards
FORTH h, sets, up, keypad
FORTH ok, sets, the, display, and, starts, the, generator
BLOCK
