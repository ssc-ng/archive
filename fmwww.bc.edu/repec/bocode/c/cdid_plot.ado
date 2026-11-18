*! version 1.0.0.0  16nov2026
*! cdid_plot: graph cdid estimates
*! Graph layout (rcap + scatter by Pre/Post series, navy/maroon, dashed zero line,
*! invisible zero series, at-value ticks up to 20 levels, by-cohort cell panels)
*! adapted from csdid_plot 2.0.2, Copyright (c) 2026 Brantly Callaway, Fernando
*! Rios-Avila, and Pedro H. C. Sant'Anna, MIT License; see
*! references/csdid-MIT-LICENSE.txt. The cdid adaptation is distributed under GPL-3.
program define cdid_plot
    version 19.5
    if "`e(cmd)'"=="cdid" & "`e(design)'"=="static" {
        display as error "cdid_plot is not available after dvar() estimation; see {help cdid##dvar:dvar()}"
        exit 198
    }
    syntax [, GROUP(numlist) SAVing(string asis) EXPort(string asis) PLOTData(string asis) REPLACE CELLS *]
    * Keep top-level options before suboption parsing reuses syntax.
    local useropts `"`options'"'
    local top_replace "`replace'"
    local want_cells = ("`cells'"!="")
    local groups "`group'"
    local spec_s `"`saving'"'
    local spec_e `"`export'"'
    local spec_p `"`plotdata'"'

    * Output specifications: file[, replace]; export() also passes graph export options.
    local gfile ""
    local gph_repl "`top_replace'"
    local xfile ""
    local exp_repl "`top_replace'"
    local exp_opts ""
    local exp_as ""
    local dfile ""
    local pdf_repl "`top_replace'"
    if `"`spec_s'"'!="" {
        mata: cdid_ur_split("spec_s", "s_file", "s_opts")
        local 0 `", `s_opts'"'
        capture syntax [, REPLACE]
        if _rc {
            display as error "saving() accepts only the replace suboption"
            exit 198
        }
        if "`replace'"!="" local gph_repl "replace"
        local gfile `"`s_file'"'
    }
    if `"`spec_e'"'!="" {
        mata: cdid_ur_split("spec_e", "e_file", "e_opts")
        local 0 `", `e_opts'"'
        syntax [, REPLACE AS(string) *]
        if "`replace'"!="" local exp_repl "replace"
        local exp_as `"`as'"'
        local exp_opts `"`options'"'
        local xfile `"`e_file'"'
    }
    if `"`spec_p'"'!="" {
        mata: cdid_ur_split("spec_p", "p_file", "p_opts")
        local 0 `", `p_opts'"'
        capture syntax [, REPLACE]
        if _rc {
            display as error "plotdata() accepts only the replace suboption"
            exit 198
        }
        if "`replace'"!="" local pdf_repl "replace"
        local dfile `"`p_file'"'
    }
    if "`top_replace'"!="" & `"`spec_s'`spec_e'`spec_p'"'=="" {
        display as error "replace has no effect without saving(), export() or plotdata()"
        exit 198
    }

    * Native graph options: titles go inside by() for by-cohort cell panels; a
    * user-supplied axis title, legend, tick list or note replaces the default.
    local twopts ""
    local titleopts ""
    foreach o in title subtitle note caption xtitle ytitle legend xlabel by name {
        local has_`o' 0
    }
    local rest `"`useropts'"'
    while `"`rest'"'!="" {
        gettoken tok rest : rest, bind
        mata: st_local("oname", cdid_ur_optname(st_local("tok")))
        if "`oname'"!="" local has_`oname' 1
        if inlist("`oname'","title","subtitle","note","caption") local titleopts `"`titleopts' `tok'"'
        else local twopts `"`twopts' `tok'"'
    }

    local rng0 `"`c(rngstate)'"'
    local sort0 `"`c(sortrngstate)'"'
    tempname prior_r pframe zero
    tempfile tg te tp
    local tg `"`tg'.gph"'
    local written ""
    _return hold `prior_r'
    capture noisily {
        quietly mata: mata mlib index
        mata: cdid_ur_check("plot")
        * Early output validation, before any graph is drawn.
        if `"`gfile'"'!="" _cdid_ur_target gfile, file(`"`gfile'"') default(.gph) allowed(.gph) `gph_repl'
        if `"`xfile'"'!="" {
            _cdid_ur_target xfile, file(`"`xfile'"') require disallowed(.gph .dta) `exp_repl'
            mata: st_local("exp_suffix", strlower(pathsuffix(st_local("xfile"))))
            if `"`exp_as'"'=="" local exp_as=substr("`exp_suffix'",2,.)
            local te `"`te'`exp_suffix'"'
        }
        if `"`dfile'"'!="" _cdid_ur_target dfile, file(`"`dfile'"') default(.dta) allowed(.dta) `pdf_repl'
        if (`"`gfile'"'!="" & (`"`gfile'"'==`"`xfile'"' | `"`gfile'"'==`"`dfile'"')) | (`"`xfile'"'!="" & `"`xfile'"'==`"`dfile'"') {
            display as error "saving(), export() and plotdata() must name different files"
            exit 198
        }
        frame create `pframe'
        frame `pframe' {
            mata: cdid_ur_plot_data(`want_cells', "`groups'")
            quietly generate byte `zero' = 0
            local plots ""
            local legorder ""
            local j 0
            foreach s in Pre Post Reference {
                local color = cond("`s'"=="Pre","navy",cond("`s'"=="Post","maroon","gs8"))
                local msym = cond("`s'"=="Reference","msymbol(Oh)","")
                if `ur_cap_`s'' {
                    local plots `"`plots' (rcap ci_high ci_low x if series=="`s'" & drawn, lcolor(`color'))"'
                    local j = `j' + 1
                }
                if `ur_n_`s'' {
                    local plots `"`plots' (scatter estimate x if series=="`s'" & drawn, mcolor(`color') `msym')"'
                    local j = `j' + 1
                    local lab = cond("`s'"=="Reference","Reference","`s'-treatment")
                    local legorder `"`legorder' `j' "`lab'""'
                }
            }
            local plots `"`plots' (scatter `zero' x if drawn, msymbol(none))"'
            local defaults `"yline(0, lpattern(dash) lcolor(gs8))"'
            if !`has_xlabel' & `"`ur_xlevels'"'!="" local defaults `"`defaults' xlabel(`ur_xlevels')"'
            if !`has_xtitle' local defaults `"`defaults' xtitle("`ur_xtitle'")"'
            if !`has_ytitle' local defaults `"`defaults' ytitle("`ur_ytitle'")"'
            if !`has_legend' local defaults `"`defaults' legend(order(`legorder'))"'
            local noteopt ""
            if !`has_note' local noteopt `"note("`ur_note'")"'
            local saveopt ""
            if `"`gfile'"'!="" local saveopt `"saving(`"`tg'"', replace)"'
            if "`ur_byvar'"!="" & !`has_by' {
                if !`has_note' local noteopt `"note("`ur_note'", size(vsmall))"'
                twoway `plots', `defaults' `twopts' ///
                    by(`ur_byvar', legend(position(6)) `noteopt' `titleopts') `saveopt'
            }
            else twoway `plots', `defaults' `noteopt' `twopts' `titleopts' `saveopt'
            if `"`xfile'"'!="" quietly graph export `"`te'"', replace as(`exp_as') `exp_opts'
            if `"`dfile'"'!="" {
                quietly drop `zero'
                label data "cdid plot data"
                quietly save `"`tp'"'
            }
        }
        if `"`gfile'"'!="" {
            if "`gph_repl'"!="" quietly copy `"`tg'"' `"`gfile'"', replace
            else quietly copy `"`tg'"' `"`gfile'"'
            local written `"`written' `"`gfile'"'"'
        }
        if `"`xfile'"'!="" {
            if "`exp_repl'"!="" quietly copy `"`te'"' `"`xfile'"', replace
            else quietly copy `"`te'"' `"`xfile'"'
            local written `"`written' `"`xfile'"'"'
        }
        if `"`dfile'"'!="" {
            if "`pdf_repl'"!="" quietly copy `"`tp'"' `"`dfile'"', replace
            else quietly copy `"`tp'"' `"`dfile'"'
            local written `"`written' `"`dfile'"'"'
        }
    }
    local rc = _rc
    capture frame drop `pframe'
    capture erase `"`tg'"'
    if `"`xfile'"'!="" capture erase `"`te'"'
    quietly set sortrngstate `sort0'
    quietly set rngstate `rng0'
    _return restore `prior_r'
    if `rc' {
        if `"`written'"'!="" display as error `"files written before the failure:`written'"'
        exit `rc'
    }
    display as text `"`ur_note'"'
    if `"`ur_gnote'"'!="" display as text `"(`ur_gnote')"'
    if `"`written'"'!="" display as text `"(written:`written')"'
end
