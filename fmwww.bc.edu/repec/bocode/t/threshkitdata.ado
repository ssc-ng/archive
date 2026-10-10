*! threshkitdata 1.0.0  07oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! The example datasets and the guided tour for THRESHKIT.
*!
*! WHY THESE ARE A SEPARATE PACKAGE. A Stata .pkg file can list at most 100
*! files, and threshkit's code and help come to exactly 100. The four example
*! datasets and the tour therefore cannot be listed in the same package, so
*! they live here. Both packages are on the SSC Archive and neither needs the
*! other to work: threshkit runs without the data, and the data are only
*! useful with threshkit installed.

program define threshkitdata, rclass
    version 15
    syntax [, GET ]

    local sets threshkit_dj threshkit_kink threshkit_ur threshkit_rates
    local what "cross-country growth (Durlauf-Johnson, as used by Hansen 2000)" ///
               "US debt and growth (Reinhart-Rogoff, as used by Hansen 2017)"   ///
               "US unemployment 1959m1-1996m7 (Hansen 1997)"                    ///
               "US interest rates 1959m1-1993m2 (Tsay 1998; Hansen-Seo 2002)"

    if "`get'" != "" {
        display as text "Fetching the example files into the current directory..."
        capture noisily net get threshkitdata, replace
        if _rc {
            display as error "could not fetch them. If you are offline, or"
            display as error "behind a proxy, download them by hand from"
            display as error "{browse "https://github.com/merwanroudane"}"
            exit _rc
        }
    }

    display _n as text "THRESHKIT example files"
    display as text "{hline 72}"
    local nhere 0
    local i 0
    foreach s of local sets {
        local ++i
        local d : word `i' of `"`what'"'
        capture confirm file "`s'.dta"
        local here = (_rc == 0)
        local ++nhere
        if !`here' local nhere = `nhere' - 1
        display as text "  " cond(`here', "{txt}[present]", "{err}[missing] ") ///
            " " as result %-18s "`s'.dta"
        display as text _col(33) "`d'"
    }
    capture confirm file "threshkit_example.do"
    local tour = (_rc == 0)
    display as text "  " cond(`tour', "{txt}[present]", "{err}[missing] ") ///
        " " as result %-18s "threshkit_example.do"
    display as text _col(33) "a guided tour over all four, in the order the"
    display as text _col(33) "questions actually arise"
    display as text "{hline 72}"

    if `nhere' == 4 & `tour' {
        display as text "All present. Start with:"
        display as text "    {bf:. do threshkit_example.do}"
    }
    else {
        display as text "Some files are not in the current directory. Get them"
        display as text "with:"
        display as text "    {bf:. threshkitdata, get}"
        display as text "which runs {bf:net get threshkitdata}. They are"
        display as text "{it:ancillary} files, so {bf:ssc install} does not"
        display as text "place them -- that is normal and applies to every"
        display as text "package that ships data."
    }

    return scalar n_present = `nhere'
    return local datasets "`sets'"
end
