*! _tk_gsave 1.0.0  06oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Save the current graph to a file, choosing the right command for the
*! extension the caller asked for.
*!
*! Every THRESHKIT graph program accepts saving(). Routing it straight to
*! graph export was wrong in two ways. First, graph export refuses .gph
*! outright (rc 198), so a user asking for a Stata graph file -- the one
*! format that can be reopened and edited -- got an error. Second, export
*! to .png and .tif needs a Java runtime on some installations, and without
*! one every graph in the package fails with rc 5004 even though the graph
*! itself drew perfectly.
*!
*! So: .gph goes to graph save, everything else to graph export, and when
*! the export back end is missing the message says what to do about it
*! rather than leaving the caller with a bare 5004.

program define _tk_gsave
    version 15
    syntax anything(everything) [, NAMe(string) ]

    local f `anything'
    * saving() is declared string asis throughout the package, so the path
    * usually arrives still wrapped in quotes
    if substr(`"`f'"', 1, 1) == `"""' ///
        local f = substr(`"`f'"', 2, length(`"`f'"') - 2)
    if `"`f'"' == "" exit

    local dot = strrpos(`"`f'"', ".")
    local ext = cond(`dot' > 0, lower(substr(`"`f'"', `dot', .)), "")

    if "`ext'" == ".gph" {
        if "`name'" != "" graph save `name' `"`f'"', replace
        else             graph save `"`f'"', replace
        exit
    }

    if "`ext'" == "" {
        display as error `"saving("`f'") has no extension: the format is"'
        display as error "taken from it. Use .gph for a Stata graph file, or"
        display as error "one of .png .pdf .eps .ps .svg .tif .emf .wmf to"
        display as error "export."
        exit 198
    }

    capture noisily {
        if "`name'" != "" graph export `"`f'"', replace name(`name')
        else             graph export `"`f'"', replace
    }
    if _rc == 5004 {
        display as error `"could not export to "`ext'": this Stata reports"'
        display as error "no Java runtime, which it needs for that format."
        display as error "The graph itself was drawn. Save it as .gph"
        display as error "instead, or export to .pdf or .eps, neither of"
        display as error "which needs Java."
        exit 5004
    }
    if _rc exit _rc
end
