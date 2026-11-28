*! labsplit v1.3 (06 Nov 2026)
*! Asjad Naqvi (asjadnaqvi@gmail.com)

* v1.3 (06 Nov 2026): Stata 15 minimum. Fixed sample restrictions and strict wrapping; Unicode-aware character counts, safe word splitting, n() alias, and validated replacement.

capture program drop labsplit
program define labsplit
    version 15
    syntax varlist(string max=1) [if] [in], ///
        [wrap(numlist max=1 >0 integer) n(numlist max=1 >0 integer) ///
        word(numlist max=1 >0 integer) strict GENerate(name) replace]

    if "`wrap'" != "" & "`n'" != "" {
        display as error "Specify either wrap() or n(), not both."
        exit 198
    }
    if "`n'" != "" local wrap `n'
    if ("`wrap'" == "" & "`word'" == "") | ("`wrap'" != "" & "`word'" != "") {
        display as error "Specify exactly one of wrap() or word()."
        exit 198
    }
    if "`strict'" != "" & "`wrap'" == "" {
        display as error "strict requires wrap() or n()."
        exit 198
    }
    if "`generate'" == "" local generate _labsplit
    marksample touse, strok
    if "`replace'" == "" confirm new variable `generate'

    tempvar output words current token length
    quietly {
        generate strL `output' = ""
        generate long `words' = wordcount(`varlist') if `touse'
        if "`word'" != "" {
            generate strL `current' = trim(`varlist') if `touse'
            forvalues i = 1/`word' {
                replace `output' = `output' + word(`varlist', `i') + " " ///
                    if `touse' & `words' > `word'
                replace `current' = ustrregexrf(`current', "^\s*\S+\s*", "") ///
                    if `touse' & `words' > `word'
            }
            replace `output' = `output' + char(10) + `current' ///
                if `touse' & `words' > `word'
            replace `output' = trim(`varlist') if `touse' & `words' <= `word'
        }
        else if "`strict'" != "" {
            generate long `length' = ustrlen(`varlist') if `touse'
            summarize `length', meanonly
            if r(N) > 0 {
                local chunks = ceil(r(max) / `wrap')
                if `chunks' > 0 {
                    forvalues i = 1/`chunks' {
                        local start = (`i' - 1) * `wrap' + 1
                        replace `output' = `output' + ///
                            cond(`i' > 1, char(10), "") + ///
                            usubstr(`varlist', `start', `wrap') ///
                            if `touse' & `length' >= `start'
                    }
                }
            }
        }
        else {
            generate strL `current' = word(`varlist', 1) if `touse'
            generate strL `token' = ""
            summarize `words', meanonly
            if r(N) > 0 {
                local items = r(max)
                if `items' >= 2 {
                    forvalues i = 2/`items' {
                        replace `token' = word(`varlist', `i') if `touse'
                        replace `output' = `output' + `current' + char(10) ///
                            if `touse' & `token' != "" & ///
                            ustrlen(`current') + ustrlen(`token') + 1 > `wrap'
                        replace `current' = cond(ustrlen(`current') + ///
                            ustrlen(`token') + 1 > `wrap', `token', ///
                            `current' + " " + `token') if `touse' & `token' != ""
                    }
                }
            }
            replace `output' = `output' + `current' if `touse'
        }
        if "`replace'" != "" {
            capture confirm variable `generate'
            if !_rc drop `generate'
        }
        rename `output' `generate'
    }
end
