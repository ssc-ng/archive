*! googlechart_appendfile v0.2.0  2026-11-08
*! v0.2.0: copy the bytes with Mata instead of the shell (type on Windows, cat
*!   elsewhere).  No operating-system command runs, the output is
*!   byte-identical, and a failed copy now stops with an error instead of
*!   silently leaving the page without its data or drawing code.
*! v0.1.2 2026-08-16: Windows path normalization for cmd.exe type (retired).
*! Close an open file handle, append another file's contents byte-for-byte,
*! then reopen the same handle in append mode.
*!
*! Used by googlechart_writehtml to embed the JSON data payload and the
*! engine JS into the output HTML without going through Stata's `file
*! write' parser, which would otherwise mishandle the embedded `"'
*! sequences inside minified JS and long lines that exceed Stata's
*! macro-length limits.  INTERNAL helper -- not meant to be called
*! directly by users.
*!
*! The Mata function below is private to this file: Stata compiles it when the
*! file loads, only this file can call it, and it survives -mata clear-.  Do
*! not add a "mata drop" line for it: that would delete a user's own Mata
*! function of the same name, and reloading works without it.

program define googlechart_appendfile
    version 17.0
    syntax , FH(name) PATH(string) OUTPATH(string)

    file close `fh'
    mata: st_local("copyrc", strofreal(_googlechart_appendbytes(st_local("path"), st_local("outpath"))))
    if `copyrc' != 0 {
        display as error `"googlechart: could not copy "`path'" into "`outpath'" (error `copyrc')."'
        display as error "  The chart page would be incomplete, so googlechart stopped."
        exit `copyrc'
    }
    file open `fh' using `"`outpath'"', write text append
end

mata:
// Append the bytes of file src to file dst.  Returns 0 on success, or the
// positive Stata error code from _fopen().
real scalar _googlechart_appendbytes(string scalar src, string scalar dst)
{
    real scalar fi, fo
    string scalar s

    fi = _fopen(src, "r")
    if (fi < 0) return(-fi)
    fo = _fopen(dst, "a")
    if (fo < 0) {
        fclose(fi)
        return(-fo)
    }
    while ((s = fread(fi, 1048576)) != J(0, 0, "")) fwrite(fo, s)
    fclose(fi)
    fclose(fo)
    return(0)
}
end
