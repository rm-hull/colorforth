BLOCK 64
FORTH "[TEXTCAPITALIZED]", "mandelbrot", "[TEXT]", "display", "[EXECUTE]", "empty", "[EXECUTE]", "forth", "[VARIABLE]", "xl", "[BINARY]", 0, "[VARIABLE]", "xr", "[BINARY]", 0, "[VARIABLE]", "yt", "[BINARY]", 0, "[VARIABLE]", "yb", "[BINARY]", 0, "[VARIABLE]", "xspan", "[BINARY]", 0, "[VARIABLE]", "yspan", "[BINARY]", 0
FORTH "allot", "[COMPILESHORT]", "-1", "+", "for", 0, ",", "next", ";", "[VARIABLE]", "z", "[BINARY]", 0, "[EXECUTE]", "hp", "[EXECUTE]", "vp", "[EXECUTE]", "*", "[EXECUTE]", "dup", "[EXECUTE]", "+", "[EXECUTE]", "allot"
FORTH "init", "[TEXT]", "-2.1", "[EXECUTE]", "fixed", "nop", "[EXECUTE]", "xl", "!", "[TEXT]", "1.1", "[EXECUTE]", "fixed", "nop", "[EXECUTE]", "xr", "!", "[TEXT]", "1.2", "[EXECUTE]", "fixed", "nop", "[EXECUTE]", "yt", "!", "[TEXT]", "-1.2", "[EXECUTE]", "fixed", "nop", "[EXECUTE]", "yb", "!", "[EXECUTE]", "xr", "@", "[EXECUTE]", "xl", "@", "negate", "+", "[EXECUTE]", "xspan", "!", "[EXECUTE]", "yt", "@", "[EXECUTE]", "yb", "@", "negate", "+", "[EXECUTE]", "yspan", "!", ";"
FORTH "ok", "show", "black", "screen", "keyboard", ";"
BLOCK 65
FORTH "[TEXT]", "xl", "xr", "yt", "yb", "are", "the", "start", "limits", "mapped", "by", "the", "[TEXTCAPITALIZED]", "cartesian", "grid;", "xspan", "and", "yspan", "hold", "the", "x", "and", "y", "ranges"
FORTH "allot", "subtracts", "one", "for", "the", "zero", "already", "compiled", "by", "the", "editor", "for", "every", "variable;", "z", "is", "the", "array", "of", "values", "as", "generated", "by", "z**2+z0"
FORTH "init", "initializes", "variables", "and", "sets", "the", "z", "array", "to", "the", "z0", "values"
FORTH "ok", "sets", "the", "display", "and", "starts", "the", "generator"
BLOCK
