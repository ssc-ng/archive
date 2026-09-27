*! cointvol_table 0.1.0  26sep2026
*! Display / export the main results table of the last cointvol subcommand
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Formats: .csv, .tex (booktabs), .html, .xlsx (putexcel), .docx (putdocx, Stata 15+),
*! .md (Markdown). The table is the matrix cached by _cointvol_store after the last
*! cointvol call, or any matrix given in matrix().

program define cointvol_table
    version 14.0
    syntax [, MATrix(name) EXPort(string) TItle(string) NOTEs(string) ///
        Format(string) REPLACE STARs(numlist >0 <1 max=3 sort) PCOLumn(string) ]

    tempname M
    if "`matrix'" != "" {
        matrix `M' = `matrix'
        local src "matrix `matrix'"
        local sub "user matrix"
    }
    else {
        capture confirm matrix __cointvol_last
        if _rc {
            di as err "no cointvol results found; run a cointvol subcommand first or use matrix()"
            exit 301
        }
        matrix `M' = __cointvol_last
        local src "$COINTVOL_LAST_src"
        local sub "cointvol $COINTVOL_LAST_sub"
    }
    if `"`title'"' == "" local title "`sub'"
    if "`format'" == "" local format "%9.3f"
    capture confirm numeric format `format'
    if _rc {
        di as err "format(): invalid numeric format"
        exit 120
    }

    local R = rowsof(`M')
    local C = colsof(`M')
    local rn : rownames `M'
    local cn : colnames `M'

    // p-value column for stars: pcolumn(name) or the first column named p* / *_p*
    local pc 0
    if "`stars'" != "" {
        local j 0
        foreach c of local cn {
            local j = `j' + 1
            if "`pcolumn'" != "" {
                if "`c'" == "`pcolumn'" local pc `j'
            }
            else if `pc' == 0 & (substr("`c'", 1, 1) == "p" | strpos("`c'", "_p")) {
                local pc `j'
            }
        }
        if `pc' == 0 {
            di as txt "(note: no p-value column found; stars not shown)"
        }
    }

    // ---------------- cell strings ------------------------------------------
    forvalues i = 1/`R' {
        forvalues j = 1/`C' {
            local v = `M'[`i', `j']
            if `v' >= . {
                local s`i'_`j' "."
            }
            else {
                local s`i'_`j' = strtrim(string(`v', "`format'"))
            }
            if `pc' == `j' & `v' < . {
                local st ""
                foreach a of local stars {
                    if `v' < `a' local st "`st'*"
                }
                local s`i'_`j' "`s`i'_`j''`st'"
            }
        }
    }

    // ---------------- screen ------------------------------------------------
    di
    di as txt "`title'"
    di as txt "{hline `=14 + 12*`C''}"
    local line "{txt}{space 14}"
    foreach c of local cn {
        local cc = abbrev("`c'", 11)
        local line `"`line'{ralign 12:`cc'}"'
    }
    di `"`line'"'
    di as txt "{hline `=14 + 12*`C''}"
    forvalues i = 1/`R' {
        local r : word `i' of `rn'
        local r = abbrev("`r'", 13)
        local line "{txt}{lalign 14:`r'}{res}"
        forvalues j = 1/`C' {
            local line `"`line'{ralign 12:`s`i'_`j''}"'
        }
        di `"`line'"'
    }
    di as txt "{hline `=14 + 12*`C''}"
    if "`stars'" != "" & `pc' > 0 {
        local sn ""
        local ns : word count `stars'
        local k 0
        foreach a of local stars {
            local k = `k' + 1
            local sn "`sn' `=substr("***", 1, `ns' - `k' + 1)' p<`a'"
        }
        di as txt "Stars on column `: word `pc' of `cn'':`sn'"
    }
    if `"`notes'"' != "" di as txt `"`notes'"'
    di as txt "Source: `src'"

    if `"`export'"' == "" {
        exit
    }

    // ---------------- export ------------------------------------------------
    local ext = strlower(substr(`"`export'"', strrpos(`"`export'"', ".") + 1, .))
    if "`replace'" == "" {
        capture confirm new file `"`export'"'
        if _rc {
            di as err `"file `export' already exists; specify replace"'
            exit 602
        }
    }

    if "`ext'" == "csv" | "`ext'" == "md" | "`ext'" == "tex" | "`ext'" == "html" {
        tempname fh
        quietly file open `fh' using `"`export'"', write text replace
        if "`ext'" == "csv" {
            local h `""""'
            foreach c of local cn {
                local h `"`h',"`c'""'
            }
            file write `fh' `"`h'"' _n
            forvalues i = 1/`R' {
                local r : word `i' of `rn'
                local line `""`r'""'
                forvalues j = 1/`C' {
                    local line `"`line',`s`i'_`j''"'
                }
                file write `fh' `"`line'"' _n
            }
        }
        if "`ext'" == "md" {
            file write `fh' "**`title'**" _n _n
            local h "|    |"
            local u "|:---|"
            foreach c of local cn {
                local h "`h' `c' |"
                local u "`u'---:|"
            }
            file write `fh' "`h'" _n "`u'" _n
            forvalues i = 1/`R' {
                local r : word `i' of `rn'
                local line "| `r' |"
                forvalues j = 1/`C' {
                    local line "`line' `s`i'_`j'' |"
                }
                file write `fh' "`line'" _n
            }
            if `"`notes'"' != "" file write `fh' _n `"`notes'"' _n
        }
        if "`ext'" == "tex" {
            local al "l"
            forvalues j = 1/`C' {
                local al "`al'r"
            }
            file write `fh' "\begin{table}[htbp]\centering" _n
            file write `fh' "\caption{`title'}" _n
            file write `fh' "\begin{tabular}{`al'}" _n "\toprule" _n
            local h ""
            foreach c of local cn {
                local c = subinstr("`c'", "_", "\_", .)
                local h "`h' & `c'"
            }
            file write `fh' "`h' \\" _n "\midrule" _n
            forvalues i = 1/`R' {
                local r : word `i' of `rn'
                local r = subinstr("`r'", "_", "\_", .)
                local line "`r'"
                forvalues j = 1/`C' {
                    local cell "`s`i'_`j''"
                    local base = subinstr("`cell'", "*", "", .)
                    local nst = strlen("`cell'") - strlen("`base'")
                    if `nst' > 0 local cell "`base'$^{`=substr("***", 1, `nst')'}$"
                    local line "`line' & `cell'"
                }
                file write `fh' "`line' \\" _n
            }
            file write `fh' "\bottomrule" _n "\end{tabular}" _n
            if `"`notes'"' != "" {
                file write `fh' "\par\smallskip\footnotesize `notes'" _n
            }
            file write `fh' "\end{table}" _n
        }
        if "`ext'" == "html" {
            file write `fh' "<table>" _n "<caption>`title'</caption>" _n "<thead><tr><th></th>"
            foreach c of local cn {
                file write `fh' "<th>`c'</th>"
            }
            file write `fh' "</tr></thead>" _n "<tbody>" _n
            forvalues i = 1/`R' {
                local r : word `i' of `rn'
                file write `fh' "<tr><th>`r'</th>"
                forvalues j = 1/`C' {
                    file write `fh' "<td>`s`i'_`j''</td>"
                }
                file write `fh' "</tr>" _n
            }
            file write `fh' "</tbody>" _n "</table>" _n
            if `"`notes'"' != "" file write `fh' "<p>`notes'</p>" _n
        }
        file close `fh'
    }
    else if "`ext'" == "xlsx" | "`ext'" == "xls" {
        quietly putexcel set `"`export'"', replace
        quietly putexcel A1 = ("`title'")
        local j 1
        foreach c of local cn {
            local j = `j' + 1
            local col = char(64 + `j')
            if `j' > 26 local col = char(64 + floor((`j' - 1)/26)) + char(65 + mod(`j' - 1, 26))
            quietly putexcel `col'2 = ("`c'")
        }
        forvalues i = 1/`R' {
            local r : word `i' of `rn'
            local row = `i' + 2
            quietly putexcel A`row' = ("`r'")
            forvalues j = 1/`C' {
                local jj = `j' + 1
                local col = char(64 + `jj')
                if `jj' > 26 local col = char(64 + floor((`jj' - 1)/26)) + char(65 + mod(`jj' - 1, 26))
                quietly putexcel `col'`row' = ("`s`i'_`j''")
            }
        }
        if `"`notes'"' != "" {
            quietly putexcel A`=`R' + 4' = ("`notes'")
        }
    }
    else if "`ext'" == "docx" {
        if c(stata_version) < 15 {
            di as err "export to .docx requires Stata 15 or newer"
            exit 198
        }
        capture putdocx clear
        quietly putdocx begin
        quietly putdocx paragraph
        quietly putdocx text (`"`title'"'), bold
        quietly putdocx table cvt = (`=`R' + 1', `=`C' + 1')
        local j 1
        foreach c of local cn {
            local j = `j' + 1
            quietly putdocx table cvt(1, `j') = ("`c'"), bold
        }
        forvalues i = 1/`R' {
            local r : word `i' of `rn'
            quietly putdocx table cvt(`=`i' + 1', 1) = ("`r'")
            forvalues j = 1/`C' {
                quietly putdocx table cvt(`=`i' + 1', `=`j' + 1') = ("`s`i'_`j''"), halign(right)
            }
        }
        if `"`notes'"' != "" {
            quietly putdocx paragraph
            quietly putdocx text (`"`notes'"')
        }
        quietly putdocx save `"`export'"', replace
    }
    else {
        di as err "export(): file extension must be .csv, .tex, .html, .md, .xlsx or .docx"
        exit 198
    }
    di as txt `"(table written to `export')"'
end
