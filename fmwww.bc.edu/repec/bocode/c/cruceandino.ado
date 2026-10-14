*! cruceandino v0.9.2  2026  Juan Marcelo Gutierrez Miranda | TodoEconometria
*! Multiway cross of an outcome by 1-3 categoricals -> table (collect) + figure.
*! Aimed at household-survey consumption studies (coca/alcohol/tobacco). Requires
*! Stata 17+ (table/collect framework). In one command it emits an exportable
*! table and its coherent figure, with consistent labels and percentages.
*!
*! Syntax:
*!   cruceandino outcome factor1 [factor2 [factor3]] [if] [in] [weight] ,
*!        [ by(varname) statistic(name) pct freq line heatmap composition
*!          panel dual sort nby hbar title("...") subtitle("...") note("...")
*!          saving("table.md|.docx|.html|.tex|.xlsx") graph("figure.png")
*!          format(%fmt) scheme(name) color(colorstyle) gropts(...) nograph ]
*!   - outcome : outcome variable (binary -> with pct gives a prevalence in %).
*!               In -composition- mode there is NO outcome: all varlist are factors.
*!   - factorN : 1 to 3 categoricals to cross.
*!   - line       : LINE (series) plot; x = factor1 (e.g. year).
*!   - heatmap    : heatmap of the outcome over factor1 (x) by factor2 (y).
*!   - composition: % of the (sub)sample in each cell (as catplot -percent-);
*!                  best with an -if- (e.g. the composition of consumers).
*! v0.9.2: weights work in every mode (the "=" was lost); line/panel show value
*!         labels on x; legends wrap; auto-hbar also for long labels; dual legend,
*!         0-100 axis and fewer ticks; sum/count with thousands; by() var cannot be
*!         a factor (rc 198); long axes (e.g. 21 years) tilted and thinned; long
*!         category labels tilted; 2 decimals by default; compact table (one
*!         column per row factor, factor 3 and by() in columns, statistics side by
*!         side); year factors shown as numbers; axis/legend titles; lang(en|es).
*!         Tree table: groups merged on the left (by, f3, f2), f1 in columns, N row
*!         at the bottom; html/tex/xlsx/docx/md. Labels escaped for html/tex.
*!         r(table) and r(Ncol): the figures of the table as matrices. Heatmap with
*!         contiguous cells and room for long titles; yes/no panels carry the variable.
*!         Figure modes are mutually exclusive (rc 198); saving() accepts only the
*!         tree formats (rc 198); bar labels over 30 characters wrap instead of being
*!         cut at 32; titles lowercase accented labels; < > escaped in tex.
*! v0.9.1: line mode no longer prints the series levels; room for bar value labels
*!         (vertical: below the panel strip; horizontal: right edge).
*! v0.9: -dual- mode = the two margins of an ordinal outcome (0=none): extensive
*!       (% consuming) as bars + intensive (frequency among consumers) as a line
*!       on a second axis; the double hurdle drawn, with its table (ext+int+N).
*! v0.8: class-binned heatmap colour (scales to hundreds of cells without breaking);
*!       auto-hbar when the axis factor has >12 categories (legible labels); -panel-
*!       (small multiples); -gropts()- passes options through to the inner graph;
*!       -hbar- forces horizontal bars.
*! v0.7: clean out-of-the-box output in every mode -- aspect (xsize/ysize), ytitle
*!       with margin and horizontal ylabel (does not collide with axis numbers);
*!       composition with asyvars (no label clash); heatmap with no plotregion box
*!       nor subtitle overlap. v0.6: subtitle() and legible title/axis.
*!       v0.5: heatmap, composition and sort. v0.4: scheme()/color(). v0.3: note().
*! Built ONLY on official Stata commands (table/collect, graph bar, twoway,
*! collapse): no community-contributed dependencies.
program define cruceandino, rclass
    version 17.0
    syntax varlist(min=1 max=4 numeric) [if] [in] [fweight aweight pweight/] , ///
        [ BY(varname numeric) STATistic(name) PCT FReq LIne HEATmap COMPosition ///
          PANel DUAL SORT TItle(string) SUBtitle(string) NOTE(string) SAVing(string) ///
          GRAph(string) FORmat(string) SCHeme(string) COLor(string) ///
          GRopts(string asis) HBAR NOGraph LANG(string) NBY ]

    * --- outcome vs factors (in composition everything is a factor) ---
    if "`composition'"!="" {
        local out
        local facs `varlist'
    }
    else {
        gettoken out facs : varlist
        if `:word count `facs''==0 {
            di as error "need: outcome + at least 1 factor (or use the composition option)"
            exit 198
        }
    }
    local facs = strtrim(stritrim("`facs'"))
    capture matrix drop _cruceandino_T _cruceandino_N
    if "`statistic'"=="" local statistic mean
    if "`format'"=="" {
        * two decimals for every non-integer figure; sums and counts are integers
        if inlist("`statistic'", "sum", "count", "rawsum") local format %12.0fc
        else local format %6.2f
    }
    * texts the command writes itself (axis titles, legends) follow lang(); the
    * user's own labels are never translated
    if "`lang'"=="" local lang en
    if !inlist("`lang'", "en", "es") {
        di as error "lang() must be en or es"
        exit 198
    }
    if "`lang'"=="es" {
        local L_prev "Porcentaje (%)"
        local L_comp "% (composición)"
        local L_cons "% que consume"
        local L_fcon "Frecuencia media entre consumidores"
        local L_dsub "Barras: % que consume | Línea: frecuencia entre consumidores"
        local L_of   "de"
        local L_st : word `=1+inlist("`statistic'","median","p50")+2*("`statistic'"=="sum")' of Media Mediana Suma
    }
    else {
        local L_prev "Percent (%)"
        local L_comp "% (composition)"
        local L_cons "% consuming"
        local L_fcon "Mean frequency among consumers"
        local L_dsub "Bars: % consuming | Line: frequency among consumers"
        local L_of   "of"
        local L_st : word `=1+inlist("`statistic'","median","p50")+2*("`statistic'"=="sum")' of Mean Median Sum
    }
    if !inlist("`statistic'", "mean", "median", "p50", "sum") local L_st `statistic'
    if "`color'"==""     local color "56 142 60"
    local schopt
    if "`scheme'"!="" local schopt scheme(`scheme')
    local notopt
    if `"`note'"'!="" local notopt note(`"`note'"')

    local nf : word count `facs'
    if "`heatmap'"!="" & `nf'<2 {
        di as error "heatmap needs at least 2 factors (x and y)"
        exit 198
    }
    if "`panel'"!="" & `nf'<2 {
        di as error "panel (small multiples) needs at least 2 factors: axis + panel category"
        exit 198
    }
    if "`dual'"!="" & "`composition'"!="" {
        di as error "dual does not combine with composition: dual decomposes an ordinal outcome (0=none)"
        exit 198
    }
    local modos `line' `heatmap' `composition' `panel' `dual'
    if `: word count `modos''>1 {
        di as error "options `modos' are mutually exclusive: choose one figure mode"
        exit 198
    }
    if `"`saving'"'!="" {
        local sext = lower(substr(`"`saving'"', strrpos(`"`saving'"', ".")+1, .))
        if !inlist("`sext'", "md", "html", "htm", "tex", "xlsx", "xls", "docx") {
            di as error `"saving(): use .md, .html, .tex, .xlsx or .docx"'
            exit 198
        }
    }
    if "`by'"!="" & `: list by in facs' {
        di as error "by(`by') is also a factor: drop it from the varlist or from by()"
        exit 198
    }
    if "`dual'"!="" & `nf'<1 {
        di as error "dual needs: ordinal outcome + at least 1 factor (axis)"
        exit 198
    }

    marksample touse, strok
    markout `touse' `facs' `out' `by'
    * syntax `weight'/ strips the "=": rebuild it once for every inner command
    local wgt
    if "`weight'"!="" local wgt [`weight'=`exp']
    quietly count if `touse'
    if r(N)==0 {
        di as error "no observations after if/in/missing"
        exit 2000
    }
    local nobs = r(N)

    * --- quantity to plot (only when there is an outcome) ---
    if "`composition'"=="" {
        tempvar y
        if "`pct'"!="" {
            quietly summarize `out' if `touse'
            if r(min)<0 | r(max)>1 di as txt "  (note: pct scales x100; `out' does not look binary 0/1)"
            quietly gen double `y' = 100*`out' if `touse'
            * the axis says what is measured: "% Union worker"; a neutral word when
            * the outcome has no label or it is too long for an axis
            local olab : variable label `out'
            local yt "`L_prev'"
            if `"`olab'"'!="" & udstrlen(`"`olab'"')<=30 local yt `"% `olab'"'
        }
        else {
            quietly gen double `y' = `out' if `touse'
            local olab : variable label `out'
            if `"`olab'"'=="" local olab `out'
            local yt `"`L_st' `L_of' `olab'"'
        }
        * dual mode: the TWO margins of an ordinal outcome (0 = none)
        if "`dual'"!="" {
            tempvar dext dint
            quietly gen double `dext' = 100*(`out'>0) if `touse' & !missing(`out')
            quietly gen double `dint' = `out' if `touse' & `out'>0
            label variable `dext' "`L_cons'"
            label variable `dint' "`L_fcon'"
        }
    }
    else local yt "`L_comp'"
    * figure titles: main + secondary, legible in every mode
    local ttl title(`"`title'"', size(medlarge)) subtitle(`"`subtitle'"', size(small) color(gs6))
    * default subtitle explaining the two margins (if the user gave none)
    if "`dual'"!="" & `"`subtitle'"'=="" {
        local ttl title(`"`title'"', size(medlarge)) ///
            subtitle("`L_dsub'", size(small) color(gs6))
    }
    * common options so the output does not fall apart (aspect + clean axis)
    local szo xsize(10) ysize(6) graphregion(margin(l=5))
    local ylo ylabel(, angle(0) nogrid)
    if "`format'"=="%12.0fc" local ylo ylabel(, angle(0) nogrid format(%12.0fc))
    * room for the value labels: without it the tallest bar's label hits the panel strip
    local blo plotregion(margin(t=5 r=3))
    * labelled x axis (line/panel): one tick per level with its value label, so a
    * coded factor reads "20-29" instead of 1, 1.5, 2; unlabelled stays numeric
    local f1x : word 1 of `facs'
    local f2x : word 2 of `facs'
    * a factor holding years (1900-2100) is shown as the plain number: a label like
    * "Year 2006" only crowds the axis
    local f1yr 0
    quietly summarize `f1x' if `touse', meanonly
    if r(min)>=1900 & r(max)<=2100 & r(min)==floor(r(min)) local f1yr 1
    local f1min = r(min)
    local f1max = r(max)
    local xvl
    local xvlp
    if "`: value label `f1x''"!="" | `f1yr' {
        quietly levelsof `f1x' if `touse', local(_f1lv)
        local xr xscale(range(`=`f1min'-0.4' `=`f1max'+0.4'))
        local vl = cond(`f1yr', "", "valuelabel")
        * long axes (e.g. 21 survey years): tilt, and label every k-th level so that
        * at most 12 show (6 in the small panels of -panel-)
        local nlv : word count `_f1lv'
        local xang
        if `nlv'>8 local xang angle(45) labsize(small)
        foreach tope in 12 6 {
            local paso = ceil(`nlv'/`tope')
            local sub
            forvalues i = 1(`paso')`nlv' {
                local sub `sub' `: word `i' of `_f1lv''
            }
            if `tope'==12 local xvl  xlabel(`sub', `vl' `xang') `xr'
            else          local xvlp xlabel(`sub', `vl' angle(45) labsize(vsmall)) `xr'
        }
    }
    * x-axis title: the variable label, or nothing (a bare name like "year" mixes
    * languages with the labels)
    local xtl xtitle(`"`: variable label `f1x''"')
    * legend title: what the colours are (the second factor)
    local ltit
    if "`f2x'"!="" {
        local ltit title(`"`: variable label `f2x''"', size(small))
    }
    * total length of factor-1 labels: long ones are tilted on bar/composition axes
    local f1len 0
    quietly levelsof `f1x' if `touse', local(_f1all)
    foreach v of local _f1all {
        local f1len = `f1len' + udstrlen(`"`: label (`f1x') `v''"')
    }
    if "`by'"!="" local f1len = 2*`f1len'
    local xlang
    if `f1len'>60 local xlang angle(30)
    * graph bar cuts category labels at 32 characters: long ones go on several lines
    _cruce_relab `f1x' `touse'
    local rl1 `"`r(rl)'"'
    local rl2
    if "`f2x'"!="" {
        _cruce_relab `f2x' `touse'
        local rl2 `"`r(rl)'"'
    }

    * ===================== TABLE (table + collect) =====================
    local f1 : word 1 of `facs'
    local f2 : word 2 of `facs'
    local f3 : word 3 of `facs'
    * rows: factors 1-2, each in its own column (row split), no empty title rows;
    * columns: the cut -- factor 3 (the panels of the figure) and by()
    local rfacs `f1' `f2'
    if `nf'==1 local rfacs `f1'
    local cfacs `f3' `by'
    * several statistics (freq, composition, dual) go side by side, not stacked
    local multi = "`freq'`composition'`dual'"!=""
    if `multi' & "`dual'"!="" local cfacs `cfacs' var result
    else if `multi' local cfacs `cfacs' result
    local cols
    if "`: list retokenize cfacs'"!="" local cols (`cfacs')
    * year factors with labels like "Year 2012": table and figure show the plain
    * number; the labels go back on the user's data at the end, even after an error
    local yrlab
    foreach v in `facs' `by' {
        local vlb : value label `v'
        quietly summarize `v' if `touse', meanonly
        if "`vlb'"!="" & r(min)>=1900 & r(max)<=2100 {
            local yrlab `yrlab' `v' `vlb'
            label values `v'
        }
    }

    capture noisily {
    if "`dual'"!="" {
        * rich table: extensive (% consuming) + intensive (frequency|consumer) + N
        quietly table (`rfacs') `cols' if `touse' `wgt', ///
            statistic(mean `dext') statistic(mean `dint') statistic(frequency) ///
            nformat(`format' mean)
    }
    else if "`composition'"!="" {
        quietly table (`rfacs') `cols' if `touse' `wgt', ///
            statistic(frequency) statistic(percent) nformat(`format' percent)
    }
    else {
        local statspec statistic(`statistic' `y')
        if "`freq'"!="" local statspec `statspec' statistic(frequency)
        quietly table (`rfacs') `cols' if `touse' `wgt', `statspec' nformat(`format' `statistic')
    }
    collect style row split, dups(first)
    collect style header `rfacs', title(hide)
    collect style header result, title(hide)
    if "`lang'"=="es" {
        collect label levels result frequency "Frecuencia" percent "Porcentaje" ///
            mean "Media" median "Mediana" sum "Suma", modify
    }
    if 1 {
        * ---- TREE table: the groups on the left, from the widest to the narrowest
        * (by, factor 3, factor 2; the reverse of the figure), the categories of
        * factor 1 as columns, and one N row at the bottom. dual: every factor on
        * the left and its two margins as the columns. The collect table above
        * stays in memory for -putdocx/putpdf collect-.
        local rgrp `by' `f3'
        if `nf'>=2 local rgrp `rgrp' `f2'
        local cgrp `f1'
        if "`dual'"!="" {
            local rgrp `rgrp' `f1'
            local cgrp
        }
        local rgrp : list retokenize rgrp
        if "`rgrp'"=="" {
            local rgrp `f1'
            local cgrp
        }
        * a plain two-way cross (one group, no nesting to keep) with many columns
        * is turned to portrait: the long factor goes down, the short one across
        if `: word count `rgrp''==1 & "`cgrp'"!="" {
            quietly levelsof `cgrp' if `touse', local(_lc)
            quietly levelsof `rgrp' if `touse', local(_lr)
            if `: word count `_lc''>12 & `: word count `_lc''>`: word count `_lr'' {
                local _sw `rgrp'
                local rgrp `cgrp'
                local cgrp `_sw'
            }
        }
        * subsample in words ("pais==2" -> "País: Perú"); complex conditions stay raw
        local sub
        if `"`if'"'!="" & `"`title'"'=="" {
            _cruce_ifdesc `"`=strtrim(substr(`"`if'"', 3, .))'"'
            local sub = cond("`lang'"=="es", "Submuestra: ", "Subsample: ") + `"`r(desc)'"'
        }
        local nlab = cond("`lang'"=="es", "N (observaciones)", "N (observations)")
        * title: the user's, which must say what the figures are; without title(),
        * one is built with the measure first ("Prevalencia (%) de X por A y B")
        local meas
        local ttab `"`title'"'
        if `"`ttab'"'=="" {
            local olab
            if "`out'"!="" {
                local olab : variable label `out'
                if `"`olab'"'=="" local olab `out'
            }
            local flist `f1' `f2' `f3' `by'
            local nfl : word count `flist'
            local porq
            forvalues q = 1/`nfl' {
                local fv : word `q' of `flist'
                local fl : variable label `fv'
                if `"`fl'"'=="" local fl `fv'
                local sep = cond(`q'==1, "", cond(`q'==`nfl', cond("`lang'"=="es", " y ", " and "), ", "))
                local porq `"`porq'`sep'`=ustrlower(`"`fl'"')'"'
            }
            local por = cond("`lang'"=="es", " por ", " by ")
            if "`composition'"!="" local ttab = cond("`lang'"=="es", "% de las observaciones", "% of the observations") + `"`por'`porq'"'
            else if "`dual'"!="" local ttab = cond("`lang'"=="es", "% y frecuencia de «", "% and frequency of «") + `"`olab'»`por'`porq'"'
            else if "`pct'"!="" local ttab = `"% «`olab'»`por'`porq'"'
            else local ttab `"`L_st' `L_of' «`olab'»`por'`porq'"'
            if "`weight'"!="" local ttab = `"`ttab'"' + cond("`lang'"=="es", " (ponderado)", " (weighted)")
        }
        preserve
        quietly keep if `touse'
        tempvar tv tn tt one
        quietly gen byte `one' = 1
        if "`composition'"!="" {
            * % of the cell inside each by() group, as in the figure
            tempvar wv
            quietly gen double `wv' = 1
            if "`exp'"!="" quietly replace `wv' = `exp'
            collapse (sum) `tv'=`wv' (sum) `tn'=`one', by(`rgrp' `cgrp')
            if "`by'"!="" quietly bysort `by': egen double `tt' = total(`tv')
            else quietly egen double `tt' = total(`tv')
            quietly replace `tv' = 100*`tv'/`tt'
            drop `tt'
        }
        else if "`dual'"!="" {
            * % consuming, then how often among consumers: one column per level of
            * the outcome (they add up to 100), and the mean the figure draws
            * a non-integer outcome or one with more than 10 levels (tenure, spending)
            * gets a single column instead: its mean among consumers
            quietly levelsof `out' if `out'>0, local(_niv)
            capture assert `out'==int(`out') if `out'>0 & !missing(`out')
            local cont = _rc | `: word count `_niv''>10
            local vl : value label `out'
            local lista `tv'
            local hl `"`L_cons'"'
            local q 0
            if `cont' {
                local q 1
                tempvar ik1
                quietly gen double `ik1' = `out' if `out'>0
                local hl `"`hl'|`L_fcon'"'
            }
            else foreach k of local _niv {
                local ++q
                tempvar ik`q'
                quietly gen double `ik`q'' = 100*(`out'==`k') if `out'>0
                local lista `lista' `ik`q''
                local hk `k'
                if "`vl'"!="" local hk : label `vl' `k'
                local hl `"`hl'|`hk'"'
            }
            quietly bysort `rgrp': egen long `tn' = total(!missing(`out'))
            local cols_ik
            forvalues j = 1/`q' {
                local cols_ik `cols_ik' `ik`j''
            }
            collapse (mean) `tv'=`dext' `cols_ik' (first) `tn' `wgt', by(`rgrp')
            local dos vlist(`tv' `cols_ik') hlist(`"`hl'"')
            if !`cont' local dos `dos' ///
                cg(`"`=cond("`lang'"=="es", "Entre quienes consumen (%)", "Among consumers (%)")'"') cgf(2) cgt(`=`q'+1')
        }
        else {
            quietly bysort `rgrp' `cgrp': egen long `tn' = total(!missing(`y'))
            collapse (`statistic') `tv'=`y' (first) `tn' `wgt', by(`rgrp' `cgrp')
        }
        * sort: the table follows the ranking of the figure (one value column)
        local srt = cond("`sort'"!="" & "`dual'"=="", "sort", "")
        local _byv = cond("`nby'"!="" & "`by'"!="", "`by'", "")
        _cruce_tree, rows(`rgrp') col(`cgrp') v(`tv') n(`tn') vfmt(`format') vlab(`"`yt'"') `dos' ///
            title(`"`ttab'"') meas(`"`meas'"') sub(`"`sub'"') nlab(`"`nlab'"') file(`"`saving'"') `srt' ///
            pie(`"`note'"') byvar(`_byv')
        restore
        if `"`saving'"'!="" di as txt "  table  -> `saving'"
    }

    * ===================== FIGURE =====================
    if "`nograph'"=="" {
        if "`heatmap'"!="" {
            * ---------- HEATMAP: colour in K CLASSES (scales without breaking) ----
            * v0.8 key: one SERIES per colour class (not one plot per cell), so it
            * does not hit the twoway layer limit (r1003) at high cardinality
            preserve
            quietly keep if `touse'
            collapse (`statistic') `y' `wgt', by(`f1' `f2')
            quietly summarize `y'
            local lo = r(min)
            local hi = r(max)
            if `hi'<=`lo' local hi = `lo' + 1
            local K = 6
            local w = (`hi'-`lo')/`K'
            quietly gen int _bin = ceil((`y'-`lo')/`w')
            quietly replace _bin = 1  if _bin<1
            quietly replace _bin = `K' if _bin>`K'
            * 6 shades of green (light -> dark)
            local c1 "224 240 226"
            local c2 "199 227 204"
            local c3 "150 201 162"
            local c4 " 94 175 120"
            local c5 " 56 142  60"
            local c6 " 27  94  32"
            * grid dimensions -> marker size and aspect
            quietly levelsof `f1', local(_xv)
            local nx : word count `_xv'
            quietly levelsof `f2', local(_yv)
            local ny : word count `_yv'
            local big = max(`nx',`ny')
            local ms  = max(1.8, 30/`big')
            local hx  = max(7, min(20, `nx'*0.9))
            local hy  = max(6, min(15, `ny'*0.5))
            * never narrower than 1.5:1, nor than the title needs (a long title goes one
            * size down instead of stretching the grid): else it is cut at the sides
            local lt = udstrlen(`"`title'"')
            local hx  = min(20, max(`hx', 1.5*`hy', 0.14*`lt'))
            if 0.17*`lt' > `hx' local ttl = subinstr(`"`ttl'"', "size(medlarge)", "size(medium)", 1)
            * one series per PRESENT class (avoids empty legend keys)
            quietly levelsof _bin, local(_pb)
            local plots
            local leg
            local pos 0
            foreach k of local _pb {
                local ++pos
                local plots `plots' (scatter `f2' `f1' if _bin==`k', ///
                    msymbol(square) msize(*`ms') mcolor("`c`k''") mlcolor(white) mlwidth(vvthin))
                local a : display `format' `lo'+(`k'-1)*`w'
                local b : display `format' `lo'+`k'*`w'
                local leg `leg' `pos' "`a'-`b'"
            }
            * in-cell numbers only if the grid is small (otherwise they clutter)
            local txts
            if _N<=48 {
                forvalues i = 1/`=_N' {
                    local xv = `f1'[`i']
                    local yv = `f2'[`i']
                    local vv = `y'[`i']
                    local bb = _bin[`i']
                    local tc = cond(`bb'>=5, "white", "0 0 0")
                    local txts `txts' text(`yv' `xv' "`: display `format' `vv''", size(vsmall) color("`tc'"))
                }
            }
            * axis labels from value labels
            local xlab
            local xlen 0
            foreach x of local _xv {
                local e : label (`f1') `x'
                if `f1yr' local e `x'
                local xlab `xlab' `x' `"`e'"'
                local xlen = `xlen' + udstrlen(`"`e'"')
            }
            * tilt the column labels only when they would not fit side by side
            local xang = cond(`xlen' > 40 | `: word count `_xv'' > 12, "angle(45)", "")
            local ylab2
            foreach y2 of local _yv {
                local e : label (`f2') `y2'
                if `y2'>=1900 & `y2'<=2100 local e `y2'
                local ylab2 `ylab2' `y2' `"`e'"'
            }
            * range with slack (0.6) so edge cells can breathe
            quietly summarize `f1'
            local xmin = r(min) - 0.6
            local xmax = r(max) + 0.6
            quietly summarize `f2'
            local ymin = r(min) - 0.6
            local ymax = r(max) + 0.6
            twoway `plots', `txts' `schopt' `notopt' ///
                xlabel(`xlab', `xang' noticks nogrid labsize(vsmall)) ///
                ylabel(`ylab2', noticks nogrid labsize(vsmall) angle(0)) ///
                xscale(noline range(`xmin' `xmax')) ///
                yscale(noline range(`ymin' `ymax')) ///
                plotregion(margin(zero) lcolor(none) lstyle(none)) ///
                aspectratio(`=(`ny'+0.2)/(`nx'+0.2)') ///
                xtitle("") ytitle("") ///
                legend(order(`leg') cols(`=cond(`pos'>4, 3, `pos')') pos(6) size(vsmall) title("`yt'", size(vsmall))) ///
                `ttl' xsize(`hx') ysize(`hy') `gropts' ///
                name(cruceandino, replace)
            restore
        }
        else if "`composition'"!="" {
            * ---------- COMPOSITION: % of the (sub)sample per cell ----------
            preserve
            quietly keep if `touse'
            tempvar w
            quietly gen double `w' = 1
            if "`exp'"!="" quietly replace `w' = `exp'
            collapse (sum) `w', by(`facs' `by')
            if "`by'"!="" quietly bysort `by': egen double _tot = total(`w')
            else quietly egen double _tot = total(`w')
            quietly gen double _pct = 100*`w'/_tot
            * one factor: plain bars; 2+ : f1 on X and f2 on COLOUR+legend (asyvars),
            * which avoids the clash of two rows of X-axis labels
            if `nf'==1 local overs over(`f1', `rl1' label(labsize(small) `xlang'))
            else       local overs over(`f2', `rl2') over(`f1', `rl1' label(labsize(small) `xlang')) asyvars
            local bylist
            if `nf'==3 local bylist `f3'
            if "`by'"!="" local bylist `bylist' `by'
            local byopt
            local topttl `ttl'
            if "`bylist'"!="" {
                local byopt by(`bylist', legend(pos(6)) note(`"`note'"') `ttl')
                local topttl
                local notopt    // the note already goes inside by(); outside it repeats per panel
            }
            local colopt bar(1, color("`color'"))
            local legopt
            local cblab blabel(bar, format(`format') size(small))
            if `nf'>=2 {
                local colopt
                quietly levelsof `f2', local(_l2)
                local n2 : word count `_l2'
                local legopt legend(cols(`=cond(`n2'>6, 3, min(4,`n2'))') pos(6) size(small) `ltit')
                * more than 6 bars per group: the numbers overlap; the table has them
                if `n2'>6 local cblab
            }
            graph bar (mean) _pct if !missing(_pct), ///
                `overs' `byopt' ytitle("`yt'", margin(r=3)) `ylo' `notopt' `schopt' `topttl' ///
                `colopt' `legopt' `cblab' `blo' ///
                `szo' `gropts' name(cruceandino, replace)
            restore
        }
        else if "`dual'"!="" {
            * ---------- DUAL: the TWO margins of an ordinal outcome ----------
            * extensive (% consuming) as bars (left axis) + intensive (frequency
            * among consumers) as a line (right axis). The double hurdle drawn.
            preserve
            quietly keep if `touse'
            * COMMON, honest range of the intensive axis [1, max ordinal]; left on
            * auto, by() rescales it per panel and inflates tiny variations (misleading)
            quietly summarize `out'
            local maxo = r(max)
            local istep = cond(`maxo'<=4, 0.5, max(1, ceil(`maxo'/8)))
            tempvar ex inn
            quietly gen byte   `ex'  = (`out'>0) if !missing(`out')
            quietly gen double `inn' = `out' if `out'>0
            local panv `f2'
            if "`f3'"!="" local panv `panv' `f3'
            if "`by'"!="" local panv `panv' `by'
            collapse (mean) `ex' `inn' `wgt', by(`f1' `panv')
            quietly replace `ex' = 100*`ex'
            quietly levelsof `f1', local(_xl)
            local xlo : word 1 of `_xl'
            local xn  : word count `_xl'
            local xhi : word `xn' of `_xl'
            local byo
            local topttl `ttl'
            if "`panv'"!="" {
                local byo by(`panv', cols(2) ixaxes note(`"`note'"') legend(off) ///
                    graphregion(margin(l=5)) `ttl')
                local topttl
                local notopt    // the note already goes inside by(); outside it repeats per panel
            }
            * bars from 0 on a fixed 0-100 axis (auto range cut them at ~95 and
            * exaggerated tiny gaps); legend with readable names, not tempvars
            local dleg legend(order(1 "`L_cons'" 2 "`L_fcon'") rows(1) pos(6) size(small))
            if "`panv'"!="" local dleg
            twoway (bar `ex' `f1', yaxis(1) base(0) barwidth(0.65) color("`color'%80")) ///
                   (connected `inn' `f1', yaxis(2) lcolor("178 24 43") mcolor("178 24 43") ///
                        lwidth(medthick) msize(small)), ///
                `byo' `topttl' `notopt' `schopt' ///
                xlabel(`xlo'(`=ceil(`xn'/12)')`xhi', `=cond(`f1yr', "", "valuelabel")' `=cond(`xn'>8 | `f1len'>60, "angle(30)", "")' labsize(vsmall)) xtitle("") ///
                ytitle("`L_cons'", axis(1) margin(r=2)) ylabel(0(20)100, axis(1) angle(0) nogrid) ///
                yscale(axis(1) range(0 100)) `dleg' ///
                ytitle("`L_fcon'", axis(2)) ///
                ylabel(1(`istep')`maxo', axis(2) angle(0)) yscale(axis(2) range(1 `maxo')) ///
                `szo' `gropts' name(cruceandino, replace)
            restore
        }
        else if "`panel'"!="" {
            * ---------- SMALL MULTIPLES: one mini-panel per category ----------
            * f1 = axis (e.g. year); f2 (+f3,+by) = panel categories. Ideal for
            * "evolution of X across many categories" without crowding one axis.
            preserve
            quietly keep if `touse'
            local pan `f2'
            if "`f3'"!="" local pan `pan' `f3'
            if "`by'"!="" local pan `pan' `by'
            collapse (`statistic') `y' `wgt', by(`f1' `pan')
            quietly levelsof `f2', local(_pv)
            local ncol = min(5, `: word count `_pv'')
            twoway (connected `y' `f1', sort lcolor("`color'") mcolor("`color'") msize(vsmall) lwidth(medthin)), ///
                by(`pan', cols(`ncol') ixaxes note(`"`note'"') legend(off) ///
                   graphregion(margin(l=4)) `ttl') ///
                ytitle("`yt'", size(vsmall) margin(r=2)) `ylo' `schopt' ///
                xtitle("") xlabel(, labsize(vsmall)) `xvlp' ///
                xsize(13) ysize(7.5) `gropts' name(cruceandino, replace)
            restore
        }
        else if "`line'"!="" {
            * ---------- LINE plot (series; x = factor1) ----------
            local series
            local panelv
            if "`f2'"!="" {
                local series `f2'
                local panelv `f3'
                if "`by'"!="" local panelv `panelv' `by'
            }
            else if "`by'"!="" {
                local series `by'
                local panelv `f3'
            }
            else local panelv `f3'
            preserve
            quietly keep if `touse'
            collapse (`statistic') `y' `wgt', by(`f1' `series' `panelv')
            local byo
            local topttl `ttl'
            if "`panelv'"!="" {
                local byo by(`panelv', legend(pos(6)) ixaxes note(`"`note'"') `ttl')
                local topttl
                local notopt    // the note already goes inside by(); outside it repeats per panel
            }
            if "`series'"!="" {
                local lblname : value label `series'
                quietly levelsof `series', local(_lv)
                local plots
                local leg
                local k 0
                foreach v of local _lv {
                    local ++k
                    if "`lblname'"!="" local vl : label `lblname' `v'
                    else local vl "`series'=`v'"
                    local plots `plots' (connected `y' `f1' if `series'==`v', sort)
                    local leg `leg' `k' "`vl'"
                }
                twoway `plots', `byo' ytitle("`yt'", margin(r=3)) `ylo' `xvl' `xtl' `notopt' `schopt' `topttl' ///
                    legend(order(`leg') pos(6) cols(`=min(4,`k')') size(small) title(`"`: variable label `series''"', size(small))) `szo' `gropts' name(cruceandino, replace)
            }
            else {
                twoway (connected `y' `f1', sort lcolor("`color'") mcolor("`color'")), ///
                    `byo' ytitle("`yt'", margin(r=3)) `ylo' `xvl' `xtl' `notopt' `schopt' `topttl' ///
                    legend(off) `szo' `gropts' name(cruceandino, replace)
            }
            restore
        }
        else {
            * ---------- BAR plot (default) ----------
            local sorto
            if "`sort'"!="" local sorto sort(1) descending
            local bylist
            if `nf'==3 {
                local bylist `f3'
                * yes/no panels say nothing alone: prefix the variable ("Smokes: No")
                local vl3 : value label `f3'
                local vlab3 : variable label `f3'
                if "`vl3'"!="" & `"`vlab3'"'!="" {
                    quietly levelsof `f3' if `touse', local(_l3)
                    local corto 1
                    foreach v of local _l3 {
                        if udstrlen(`"`: label `vl3' `v''"')>3 local corto 0
                    }
                    if `corto' {
                        tempvar p3
                        tempname lp3
                        quietly gen `p3' = `f3'
                        foreach v of local _l3 {
                            label define `lp3' `v' `"`vlab3': `: label `vl3' `v''"', add
                        }
                        label values `p3' `lp3'
                        local bylist `p3'
                    }
                }
            }
            if "`by'"!="" local bylist `bylist' `by'
            * the title appears ONCE: inside by() if there are panels, else on top
            local byopt
            local topttl `ttl'
            if "`bylist'"!="" {
                local byopt by(`bylist', legend(pos(6)) note(`"`note'"') `ttl')
                local topttl
                local notopt    // the note already goes inside by(); outside it repeats per panel
            }
            * auto-hbar: if the axis factor has MANY categories (>12) the horizontal
            * labels collide; switch to horizontal bars (names stacked with room).
            * Also if the user forces -hbar-.
            quietly levelsof `f1' if `touse', local(_f1v)
            local nlev : word count `_f1v'
            * ...or if the labels are long: 12 industries of ~20 characters collide too
            local lablen 0
            foreach v of local _f1v {
                local lablen = `lablen' + strlen(`"`: label (`f1') `v''"')
            }
            local barcmd graph bar
            local barsz  `szo'
            if `nlev'>12 | `lablen'>90 | "`hbar'"!="" {
                local barcmd graph hbar
                local xlang
                local ht = max(6, min(16, `nlev'*0.38))
                local barsz xsize(12) ysize(`ht') graphregion(margin(l=5))
                local blo plotregion(margin(r=9))
            }
            if `nf'==1 {
                * one factor: bars over f1 with the number on top
                `barcmd' (`statistic') `y' if `touse' `wgt', ///
                    over(`f1', `sorto' `rl1' label(labsize(small) `xlang')) `byopt' ///
                    ytitle("`yt'", margin(r=3)) `ylo' `notopt' `schopt' `topttl' ///
                    bar(1, color("`color'")) blabel(bar, format(`format') size(small)) `blo' ///
                    `barsz' `gropts' name(cruceandino, replace)
            }
            else {
                * 2+ factors: f1 on the X axis and f2 on COLOUR + legend; this avoids
                * the clash of two rows of labels (which makes the graph illegible).
                * Legend wraps at 4 keys per row so long labels do not overlap.
                quietly levelsof `f2' if `touse', local(_l2)
                local n2 : word count `_l2'
                * the figure on each bar while it stays legible (<=6 per group, <=40 bars)
                local b2lab
                if `n2'<=6 & `nlev'*`n2'<=40 local b2lab blabel(bar, format(`format') size(vsmall))
                `barcmd' (`statistic') `y' if `touse' `wgt', ///
                    over(`f2', `rl2') over(`f1', `sorto' `rl1' label(labsize(small) `xlang')) asyvars ///
                    `byopt' ytitle("`yt'", margin(r=3)) `ylo' `notopt' `schopt' `topttl' `b2lab' `blo' ///
                    legend(cols(`=min(4,`n2')') pos(6) size(small) `ltit') `barsz' `gropts' name(cruceandino, replace)
            }
        }

        if `"`graph'"'!="" {
            graph export `"`graph'"', replace width(2200) name(cruceandino)
            di as txt "  figure -> `graph'"
        }
    }
    }
    local rc = _rc
    while "`yrlab'"!="" {
        gettoken v yrlab : yrlab
        gettoken vlb yrlab : yrlab
        label values `v' `vlb'
    }
    if `rc' exit `rc'

    * ===================== stored results =====================
    return local cmd       "cruceandino"
    return local outcome   "`out'"
    return local factors   "`facs'"
    return local by        "`by'"
    return local statistic "`statistic'"
    return local pct       = cond("`pct'"!="", "1", "0")
    return local mode      = cond("`heatmap'"!="","heatmap", cond("`composition'"!="","composition", cond("`dual'"!="","dual", cond("`panel'"!="","panel", cond("`line'"!="","line","bars")))))
    return scalar N        = `nobs'
    capture confirm matrix _cruceandino_T
    if !_rc {
        return matrix table = _cruceandino_T
        return matrix Ncol  = _cruceandino_N
    }
end

* Fill the empty corner of a markdown table header with the row-factor labels:
* -collect- leaves it blank once the row titles are hidden by -row split-.
program define _cruce_md_corner
    gettoken file vars : 0
    tempname fi fo
    tempfile tmp
    local n 0
    local sep 0
    file open `fi' using `"`file'"', read text
    file read `fi' line
    while r(eof)==0 {
        local ++n
        local L`n' `"`macval(line)'"'
        if `sep'==0 & ustrregexm(`"`macval(line)'"', "^\|[ |-]+\|$") local sep `n'
        file read `fi' line
    }
    file close `fi'
    if `sep'<2 exit
    * the last header row, cell by cell: the first k cells take the factor labels
    local h = `sep' - 1
    local row `"`macval(L`h')'"'
    local out "|"
    local k 0
    local rest = substr(`"`macval(row)'"', 2, .)
    while strpos(`"`macval(rest)'"', "|") {
        local p = strpos(`"`macval(rest)'"', "|")
        local cell = substr(`"`macval(rest)'"', 1, `p'-1)
        local rest = substr(`"`macval(rest)'"', `p'+1, .)
        local ++k
        local v : word `k' of `vars'
        if "`v'"!="" {
            local lab : variable label `v'
            if `"`lab'"'=="" local lab `v'
            local cell `" `lab' "'
        }
        local out `"`macval(out)'`macval(cell)'|"'
    }
    local L`h' `"`macval(out)'"'
    file open `fo' using `"`tmp'"', write text
    forvalues i = 1/`n' {
        file write `fo' `"`macval(L`i')'"' _n
    }
    file close `fo'
    copy `"`tmp'"' `"`file'"', replace
end

* TREE table from collapsed cells (one obs per row group x column level):
* groups on the left, merged and vertical where the format allows it (html, tex,
* xlsx; docx merges but keeps text horizontal), columns = levels of col(), and
* one N row at the bottom. Shown in the Results window; exported by extension.
program define _cruce_tree
    syntax, rows(varlist) v(varname) n(varname) vfmt(string) ///
        [col(string) vlab(string) vlist(string) hlist(string) cg(string) cgf(integer 0) ///
         cgt(integer 0) title(string) meas(string) sub(string) nlab(string) file(string) sort ///
         pie(string) byvar(string)]
    local K : word count `rows'
    * ---- column headers and wide layout
    tempvar cj
    if "`col'"!="" {
        local chead : variable label `col'
        quietly egen int `cj' = group(`col')
        quietly levelsof `cj', local(js)
        local J : word count `js'
        forvalues j = 1/`J' {
            quietly summarize `col' if `cj'==`j', meanonly
            local h`j' = cond(r(min)>=1900 & r(max)<=2100, string(r(min)), ///
                cond("`: value label `col''"!="", `"`: label (`col') `=r(min)''"', string(r(min), "%9.0g")))
        }
        * sort: columns from the highest to the lowest overall value
        if "`sort'"!="" {
            tempvar tot nn ord cj2
            quietly bysort `cj': egen double `tot' = total(`v'*`n')
            quietly bysort `cj': egen double `nn' = total(`n')
            quietly gen double `ord' = -`tot'/`nn'
            quietly egen int `cj2' = group(`ord')
            forvalues j = 1/`J' {
                quietly summarize `cj2' if `cj'==`j', meanonly
                local hh`=r(min)' `"`h`j''"'
            }
            forvalues j = 1/`J' {
                local h`j' `"`hh`j''"'
            }
            quietly replace `cj' = `cj2'
            drop `cj2' `tot' `nn' `ord'
        }
        keep `rows' `cj' `v' `n'
        rename (`v' `n') (_tv _tn)
        quietly reshape wide _tv _tn, i(`rows') j(`cj')
    }
    else if "`vlist'"!="" {
        * several statistics side by side (dual): the N goes under the first one
        local J : word count `vlist'
        local hrest `"`hlist'"'
        forvalues j = 1/`J' {
            local p = strpos(`"`hrest'"', "|")
            if `p' {
                local h`j' = substr(`"`hrest'"', 1, `p'-1)
                local hrest = substr(`"`hrest'"', `p'+1, .)
            }
            else local h`j' `"`hrest'"'
            local w : word `j' of `vlist'
            quietly gen double _tv`j' = `w'
            quietly gen double _tn`j' = cond(`j'==1, `n', .)
        }
        keep `rows' _tv* _tn*
    }
    else {
        local J 1
        local h1 `vlab'
        keep `rows' `v' `n'
        rename (`v' `n') (_tv1 _tn1)
    }
    sort `rows'
    local R = _N
    * ---- row-group texts and spans (a group spans the rows sharing its outer path)
    local prev
    forvalues k = 1/`K' {
        local r : word `k' of `rows'
        local hd`k' : variable label `r'
        if `"`hd`k''"'=="" local hd`k' `r'
        quietly gen strL _lb`k' = ""
        quietly summarize `r', meanonly
        local yr = r(min)>=1900 & r(max)<=2100
        forvalues i = 1/`R' {
            local x = `r'[`i']
            if !`yr' & "`: value label `r''"!="" quietly replace _lb`k' = `"`: label (`r') `x''"' in `i'
            else quietly replace _lb`k' = string(`x') in `i'
        }
        local prev `prev' `r'
        tempvar st`k' gr`k'
        quietly gen byte `st`k'' = _n==1
        foreach p of local prev {
            quietly replace `st`k'' = 1 if `p'!=`p'[_n-1]
        }
        quietly gen long `gr`k'' = sum(`st`k'')
        quietly bysort `gr`k'': gen long _sp`k' = _N
        sort `rows'
    }
    if "`sort'"!="" & `K'==1 & "`col'"=="" gsort -_tv1
    * ---- N rows: one per by() level when byvar() is given (option nby), else a
    * single pooled total. nNr=1 reproduces the original single total row exactly.
    local nNr 1
    local nl1 `"`nlab'"'
    local sel1 "1"
    local rnm1 N
    if "`byvar'"!="" {
        quietly levelsof `byvar', local(_bylv)
        local nNr : word count `_bylv'
        local _vlb : value label `byvar'
        local m 0
        foreach L of local _bylv {
            local ++m
            local _ll `L'
            if "`_vlb'"!="" local _ll `"`: label `_vlb' `L''"'
            local nl`m' `"`nlab' · `_ll'"'
            local sel`m' `"`byvar'==`L'"'
            local rnm`m' = usubstr(subinstr(strtrim(`"`_ll'"'), " ", "_", .), 1, 20)
        }
    }
    matrix _cruceandino_N = J(`nNr', `J', .)
    forvalues m = 1/`nNr' {
        forvalues j = 1/`J' {
            quietly summarize _tn`j' if `sel`m'', meanonly
            local N`m'_`j' = cond(r(N)==0, "", strtrim(string(r(sum), "%12.0fc")))
            if r(N) matrix _cruceandino_N[`m', `j'] = r(sum)
        }
    }
    * ---- the figures of the table as matrices, returned as r(table) and r(Ncol):
    * rows named "outer groups:inner level", columns by their headers
    local tl
    local cn
    forvalues j = 1/`J' {
        local tl `tl' _tv`j'
        local cn `"`cn' "`=usubstr(subinstr(subinstr(`"`h`j''"', ":", ";", .), char(34), "", .), 1, 32)'""'
    }
    quietly mkmat `tl', matrix(_cruceandino_T)
    local rn
    forvalues i = 1/`R' {
        local eq
        forvalues k = 1/`=`K'-1' {
            local eq `"`eq'`=cond(`k'>1, " / ", "")'`=_lb`k'[`i']'"'
        }
        local eq = usubstr(subinstr(subinstr(`"`eq'"', ":", ";", .), char(34), "", .), 1, 32)
        local nm = usubstr(subinstr(subinstr(_lb`K'[`i'], ":", ";", .), char(34), "", .), 1, 32)
        local rn `"`rn' "`=cond(`K'>1, `"`eq':"', "")'`nm'""'
    }
    matrix rownames _cruceandino_T = `rn'
    matrix colnames _cruceandino_T = `cn'
    matrix colnames _cruceandino_N = `cn'
    local _Nrn
    forvalues m = 1/`nNr' {
        local _Nrn `_Nrn' `rnm`m''
    }
    matrix rownames _cruceandino_N = `_Nrn'
    * ---- cell texts: value with the command's format, empty when missing
    forvalues j = 1/`J' {
        quietly gen strL _tx`j' = cond(missing(_tv`j'), "", strtrim(string(_tv`j', "`vfmt'")))
    }
    local ext = lower(substr(`"`file'"', strrpos(`"`file'"', ".")+1, .))
    if `"`file'"'=="" local ext none

    * ---- Results window and markdown (flat: the group shows on its first row)
    local L0 "|"
    local Ls "|"
    forvalues k = 1/`K' {
        local L0 `"`macval(L0)' `hd`k'' |"'
        local Ls "`Ls'---|"
    }
    forvalues j = 1/`J' {
        local hj `"`h`j''"'
        if `cgf' & `j'>=`cgf' & `j'<=`cgt' local hj `"`cg': `h`j''"'
        local L0 `"`macval(L0)' `hj' |"'
        local Ls "`Ls'--:|"
    }
    forvalues i = 1/`R' {
        local Li`i' "|"
        forvalues k = 1/`K' {
            local c = cond(`st`k''[`i'], _lb`k'[`i'], "")
            local Li`i' `"`macval(Li`i')' `c' |"'
        }
        forvalues j = 1/`J' {
            local Li`i' `"`macval(Li`i')' `=_tx`j'[`i']' |"'
        }
    }
    forvalues m = 1/`nNr' {
        local LN`m' `"| **`nl`m''** |"'
        forvalues k = 2/`K' {
            local LN`m' "`LN`m'' |"
        }
        forvalues j = 1/`J' {
            local LN`m' "`LN`m'' `N`m'_`j'' |"
        }
    }

    * ---- Results window: a Stata table (rules, aligned columns), the same tree as the
    * export; c`k' = first column of row label k, e`j' = last column of value j
    local pos 2
    forvalues k = 1/`K' {
        local w = udstrlen(`"`hd`k''"')
        forvalues i = 1/`R' {
            local w = max(`w', udstrlen(_lb`k'[`i']))
        }
        local c`k' = `pos'
        local pos = `pos' + `w' + 2
    }
    local _nlw = udstrlen(`"`nlab'"')
    forvalues m = 1/`nNr' {
        local _nlw = max(`_nlw', udstrlen(`"`nl`m''"'))
    }
    local bar = max(`pos', `_nlw' + 4)
    local wl = `bar' - 1
    * value columns: width w`j'; a table wider than the window goes in blocks of
    * columns (as Stata's own tables), the row labels repeated in each block
    local lim = min(max(c(linesize), 80), 250)
    local nb 1
    local pos = `bar' + 1
    forvalues j = 1/`J' {
        local w = udstrlen(`"`h`j''"')
        forvalues m = 1/`nNr' {
            local w = max(`w', udstrlen("`N`m'_`j''"))
        }
        forvalues i = 1/`R' {
            local w = max(`w', udstrlen(_tx`j'[`i']))
        }
        if `pos' + `w' + 2 > `lim' & `pos' > `bar' + 1 {
            local ++nb
            local pos = `bar' + 1
        }
        local pos = `pos' + `w' + 2
        local e`j' = `pos' - 1
        local blq`j' `nb'
    }
    di
    if `"`title'"'!="" di as res `"`title'"'
    if `"`meas'"'!="" di as txt `"`meas'"'
    if `"`sub'"'!="" di as txt `"`sub'"'
    forvalues b = 1/`nb' {
        local ja 0
        forvalues j = 1/`J' {
            if `blq`j''==`b' & `ja'==0 local ja `j'
            if `blq`j''==`b' local jb `j'
        }
        local wv = `e`jb'' - `bar' + 1
        if `b'>1 di
        di as txt "{hline `wl'}{c TT}{hline `wv'}"
        if `cgf' & `jb'>=`cgf' {
            local a = cond(`cgf'<=`ja', `bar' + 2, `e`=`cgf'-1'' + 3)
            di as txt _col(`bar') "{c |}" _col(`a') `"`cg'"'
        }
        else if !`cgf' & `"`chead'"'!="" {
            * the column factor, over the columns it names
            di as txt _col(`bar') "{c |}" _col(`=`e`jb''-udstrlen(`"`chead'"')+1') `"`chead'"'
        }
        local ln
        forvalues k = 1/`K' {
            local ln `"`macval(ln)' _col(`c`k'') `"`hd`k''"'"'
        }
        local ln `"`macval(ln)' _col(`bar') "{c |}""'
        forvalues j = `ja'/`jb' {
            local ln `"`macval(ln)' _col(`=`e`j''-udstrlen(`"`h`j''"')+1') `"`h`j''"'"'
        }
        di as txt `ln'
        di as txt "{hline `wl'}{c +}{hline `wv'}"
        forvalues i = 1/`R' {
            if `K'>1 & `i'>1 & `st1'[`i'] di as txt "{hline `wl'}{c +}{hline `wv'}"
            local ln
            forvalues k = 1/`K' {
                if `st`k''[`i'] local ln `"`macval(ln)' _col(`c`k'') `"`=_lb`k'[`i']'"'"'
            }
            local ln `"`macval(ln)' _col(`bar') "{c |}" as res"'
            forvalues j = `ja'/`jb' {
                local x = _tx`j'[`i']
                local ln `"`macval(ln)' _col(`=`e`j''-udstrlen("`x'")+1') "`x'""'
            }
            di as txt `ln'
        }
        di as txt "{hline `wl'}{c +}{hline `wv'}"
        forvalues m = 1/`nNr' {
            local ln `"_col(2) `"`nl`m''"' _col(`bar') "{c |}""'
            forvalues j = `ja'/`jb' {
                local ln `"`macval(ln)' _col(`=`e`j''-udstrlen("`N`m'_`j''")+1') "`N`m'_`j''""'
            }
            di as txt `ln'
        }
        di as txt "{hline `wl'}{c BT}{hline `wv'}"
    }
    if `"`pie'"'!="" di as txt `"`pie'"'

    tempname fh
    if "`ext'"=="md" {
        file open `fh' using `"`file'"', write text replace
        if `"`title'"'!="" file write `fh' `"**`title'**"' _n _n
        if `"`meas'"'!="" file write `fh' `"`meas'"' _n _n
        if `"`sub'"'!="" file write `fh' `"*`sub'*"' _n _n
        file write `fh' `"`macval(L0)'"' _n "`Ls'" _n
        forvalues i = 1/`R' {
            file write `fh' `"`macval(Li`i')'"' _n
        }
        forvalues m = 1/`nNr' {
            file write `fh' `"`macval(LN`m')'"' _n
        }
        if `"`pie'"'!="" file write `fh' _n `"<sub>`pie'</sub>"' _n
        file close `fh'
    }
    else if "`ext'"=="html" | "`ext'"=="htm" {
        * labels may carry & < > (e.g. "Q1 (<1000)"): escape them for HTML
        foreach m in title meas sub pie nlab cg {
            local `m' = subinstr(subinstr(subinstr(`"``m''"', "&", "&amp;", .), "<", "&lt;", .), ">", "&gt;", .)
        }
        forvalues k = 1/`K' {
            local hd`k' = subinstr(subinstr(subinstr(`"`hd`k''"', "&", "&amp;", .), "<", "&lt;", .), ">", "&gt;", .)
            quietly replace _lb`k' = subinstr(subinstr(subinstr(_lb`k', "&", "&amp;", .), "<", "&lt;", .), ">", "&gt;", .)
        }
        forvalues j = 1/`J' {
            local h`j' = subinstr(subinstr(subinstr(`"`h`j''"', "&", "&amp;", .), "<", "&lt;", .), ">", "&gt;", .)
        }
        file open `fh' using `"`file'"', write text replace
        file write `fh' `"<!doctype html><html><head><meta charset="utf-8"><style>"' _n ///
            "body{font-family:Arial,sans-serif;color:#18202c} table{border-collapse:collapse;font-size:14px}" _n ///
            "th,td{border:1px solid #c9d0d8;padding:5px 10px} thead th{background:#f1f4f7;text-align:center}" _n ///
            "td.n{text-align:right} td.g{text-align:center;vertical-align:middle;font-weight:600}" _n ///
            "td.v{writing-mode:vertical-rl;transform:rotate(180deg);text-align:center;vertical-align:middle;font-weight:700;background:#f1f4f7}" _n ///
            "tr.t td{background:#f7f7f2;border-top:2px solid #18202c;white-space:nowrap}" _n ///
            "p.pie{font-size:10px;color:#555;margin-top:4px}" _n "</style></head><body>" _n
        if `"`title'"'!="" file write `fh' `"<p><b>`title'</b></p>"' _n
        if `"`meas'"'!="" file write `fh' `"<p>`meas'</p>"' _n
        if `"`sub'"'!="" file write `fh' `"<p><i>`sub'</i></p>"' _n
        file write `fh' "<table><thead><tr>"
        local rs = cond(`cgf', `" rowspan="2""', "")
        forvalues k = 1/`K' {
            file write `fh' `"<th`rs'>`hd`k''</th>"'
        }
        forvalues j = 1/`J' {
            if `cgf' & `j'==`cgf' file write `fh' `"<th colspan="`=`cgt'-`cgf'+1'">`cg'</th>"'
            else if !(`cgf' & `j'>`cgf' & `j'<=`cgt') file write `fh' `"<th`rs'>`h`j''</th>"'
        }
        if `cgf' {
            file write `fh' "</tr><tr>"
            forvalues j = `cgf'/`cgt' {
                file write `fh' `"<th>`h`j''</th>"'
            }
        }
        file write `fh' "</tr></thead><tbody>" _n
        forvalues i = 1/`R' {
            file write `fh' "<tr>"
            forvalues k = 1/`K' {
                if `st`k''[`i'] {
                    local cls = cond(`k'==1 & `K'>1 & _sp`k'[`i']>1, "v", "g")
                    file write `fh' `"<td class="`cls'" rowspan="`=_sp`k'[`i']'">`=_lb`k'[`i']'</td>"'
                }
            }
            forvalues j = 1/`J' {
                file write `fh' `"<td class="n">`=_tx`j'[`i']'</td>"'
            }
            file write `fh' "</tr>" _n
        }
        forvalues m = 1/`nNr' {
            local _cls = cond(`m'==1, "t", "")
            file write `fh' `"<tr class="`_cls'"><td colspan="`K'"><b>`nl`m''</b></td>"'
            forvalues j = 1/`J' {
                file write `fh' `"<td class="n">`N`m'_`j''</td>"'
            }
            file write `fh' "</tr>" _n
        }
        file write `fh' "</tbody></table>" _n
        if `"`pie'"'!="" file write `fh' `"<p class="pie">`pie'</p>"' _n
        file write `fh' "</body></html>" _n
        file close `fh'
    }
    else if "`ext'"=="tex" {
        * needs \usepackage{booktabs,multirow,graphicx}
        file open `fh' using `"`file'"', write text replace
        file write `fh' "% \usepackage{booktabs,multirow,graphicx}" _n
        local spec = "l"*`K' + "r"*`J'
        quietly summarize _sp1 if `st1', meanonly
        local gira = `K'>1 & r(min)>=4
        file write `fh' "\begin{tabular}{`spec'}" _n "\toprule" _n
        local hl
        forvalues k = 1/`K' {
            _cruce_texesc `"`hd`k''"'
            local hl `"`macval(hl)'`=cond(`k'>1," & ","")'`r(s)'"'
        }
        forvalues j = 1/`J' {
            _cruce_texesc `"`h`j''"'
            local hl `"`macval(hl)' & `r(s)'"'
        }
        if `cgf' {
            local gl = "&"*(`K'+`cgf'-2)
            local gl `"`gl' & \multicolumn{`=`cgt'-`cgf'+1'}{c}{`=subinstr(`"`cg'"',"%","\%",.)'}"'
            file write `fh' `"`gl' \\"' _n "\cmidrule(lr){`=`K'+`cgf''-`=`K'+`cgt''}" _n
        }
        file write `fh' `"`macval(hl)' \\"' _n "\midrule" _n
        forvalues i = 1/`R' {
            if `i'>1 & `K'>1 & `st1'[`i'] file write `fh' "\midrule" _n
            local tl
            forvalues k = 1/`K' {
                local c
                if `st`k''[`i'] {
                    _cruce_texesc `"`=_lb`k'[`i']'"'
                    local c `"`r(s)'"'
                    if `k'==1 & `gira' local c "\multirow{`=_sp`k'[`i']'}{*}{\rotatebox[origin=c]{90}{`c'}}"
                    else if `k'<`K' & _sp`k'[`i']>1 local c "\multirow{`=_sp`k'[`i']'}{*}{`c'}"
                }
                local tl `"`macval(tl)'`=cond(`k'>1," & ","")'`c'"'
            }
            forvalues j = 1/`J' {
                local tl `"`macval(tl)' & `=_tx`j'[`i']'"'
            }
            file write `fh' `"`macval(tl)' \\"' _n
        }
        forvalues m = 1/`nNr' {
            local _rule = cond(`m'==1, "\midrule ", "")
            local tl "`_rule'\multicolumn{`K'}{l}{`=subinstr(subinstr(subinstr(subinstr(`"`nl`m''"',"%","\%",.),"&","\&",.),"_","\_",.),"#","\#",.)'}"
            forvalues j = 1/`J' {
                local tl "`tl' & `N`m'_`j''"
            }
            file write `fh' "`tl' \\" _n
        }
        file write `fh' "\bottomrule" _n
        file write `fh' "\end{tabular}" _n
        foreach nota in meas pie {
            if `"``nota''"'!="" {
                local ntx = subinstr(subinstr(`"``nota''"', "%", "\%", .), "&", "\&", .)
                file write `fh' `"\par\vspace{5pt}{\footnotesize `ntx'\par}"' _n
            }
        }
        file close `fh'
    }
    else if "`ext'"=="xlsx" | "`ext'"=="xls" {
        quietly putexcel set `"`file'"', replace
        local r0 = 1 + (`"`title'"'!="") + (`"`meas'"'!="") + (`"`sub'"'!="") + (`cgf'>0)
        if `"`title'"'!="" quietly putexcel A1 = `"`title'"', bold
        if `"`meas'"'!="" quietly putexcel A`=1+(`"`title'"'!="")' = `"`meas'"'
        if `"`sub'"'!="" quietly putexcel A`=`r0'-1' = `"`sub'"', italic
        forvalues c = 1/`=`K'+`J'' {
            local L`c' = cond(`c'<=26, char(64+`c'), char(64+floor((`c'-1)/26)) + char(65+mod(`c'-1,26)))
        }
        forvalues k = 1/`K' {
            quietly putexcel `L`k''`r0' = `"`hd`k''"', bold hcenter border(bottom)
        }
        if `cgf' {
            local ga = `K' + `cgf'
            local gb = `K' + `cgt'
            quietly putexcel `L`ga''`=`r0'-1':`L`gb''`=`r0'-1' = `"`cg'"', merge hcenter bold border(bottom)
        }
        forvalues j = 1/`J' {
            quietly putexcel `L`=`K'+`j'''`r0' = `"`h`j''"', bold hcenter border(bottom)
        }
        forvalues i = 1/`R' {
            local rr = `r0' + `i'
            forvalues k = 1/`K' {
                if `st`k''[`i'] {
                    local sp = _sp`k'[`i']
                    local re = `rr' + `sp' - 1
                    if `k'<`K' & `sp'>1 quietly putexcel `L`k''`rr':`L`k''`re' = `"`=_lb`k'[`i']'"', merge vcenter bold
                    else quietly putexcel `L`k''`rr' = `"`=_lb`k'[`i']'"'
                }
            }
            forvalues j = 1/`J' {
                if !missing(_tv`j'[`i']) quietly putexcel `L`=`K'+`j'''`rr' = _tv`j'[`i'], nformat("0.00")
            }
        }
        forvalues m = 1/`nNr' {
            local rn = `r0' + `R' + `m'
            if `m'==1 {
                quietly putexcel `L1'`rn' = `"`nl`m''"', bold border(top)
                forvalues k = 2/`K' {
                    quietly putexcel `L`k''`rn', border(top)
                }
                forvalues j = 1/`J' {
                    quietly putexcel `L`=`K'+`j'''`rn' = `=subinstr("`N`m'_`j''", ",", "", .)', nformat("#,##0") border(top)
                }
            }
            else {
                quietly putexcel `L1'`rn' = `"`nl`m''"', bold
                forvalues j = 1/`J' {
                    quietly putexcel `L`=`K'+`j'''`rn' = `=subinstr("`N`m'_`j''", ",", "", .)', nformat("#,##0")
                }
            }
        }
        if `"`pie'"'!="" quietly putexcel A`=`rn'+1' = `"`pie'"', italic font("Calibri", 9)
        quietly putexcel close
        * columns wide enough for their labels (putexcel cannot set widths; xl() can)
        local anchos
        forvalues k = 1/`K' {
            local w = udstrlen(`"`hd`k''"')
            forvalues i = 1/`R' {
                local w = max(`w', udstrlen(_lb`k'[`i']))
            }
            if `k'==1 {
                forvalues m = 1/`nNr' {
                    local w = max(`w', udstrlen(`"`nl`m''"'))
                }
            }
            local anchos `anchos' `=`w'+3'
        }
        forvalues j = 1/`J' {
            local anchos `anchos' `=max(10, udstrlen(`"`h`j''"')+3)'
        }
        mata: _cruce_xlanchos(`"`file'"', "`anchos'")
    }
    else if "`ext'"=="docx" {
        * Word: merged group cells, text horizontal (putdocx cannot rotate it)
        capture putdocx describe
        local abierto = _rc==0
        if !`abierto' {
            putdocx clear
            putdocx begin
        }
        if `"`title'"'!="" {
            putdocx paragraph
            putdocx text (`"`title'"'), bold
        }
        if `"`meas'"'!="" {
            putdocx paragraph
            putdocx text (`"`meas'"')
        }
        if `"`sub'"'!="" {
            putdocx paragraph
            putdocx text (`"`sub'"'), italic
        }
        local g = `cgf'>0
        local nr = `R' + 1 + `g' + `nNr'
        local nc = `K' + `J'
        putdocx table _ct = (`nr', `nc'), border(all, single) layout(autofitcontents)
        if `g' {
            local ncg = `cgt' - `cgf' + 1
            putdocx table _ct(1,`=`K'+`cgf'') = (`"`cg'"'), bold halign(center) colspan(`ncg')
        }
        forvalues k = 1/`K' {
            putdocx table _ct(`=1+`g'',`k') = (`"`hd`k''"'), bold halign(center)
        }
        forvalues j = 1/`J' {
            putdocx table _ct(`=1+`g'',`=`K'+`j'') = (`"`h`j''"'), bold halign(center)
        }
        forvalues i = 1/`R' {
            forvalues k = 1/`K' {
                if `st`k''[`i'] {
                    local sp = _sp`k'[`i']
                    if `k'<`K' & `sp'>1 putdocx table _ct(`=`i'+1+`g'',`k') = (`"`=_lb`k'[`i']'"'), rowspan(`sp') valign(center) halign(center) bold
                    else putdocx table _ct(`=`i'+1+`g'',`k') = (`"`=_lb`k'[`i']'"')
                }
            }
            forvalues j = 1/`J' {
                putdocx table _ct(`=`i'+1+`g'',`=`K'+`j'') = (`"`=_tx`j'[`i']'"'), halign(right)
            }
        }
        forvalues m = 1/`nNr' {
            local rN = `R' + 1 + `g' + `m'
            putdocx table _ct(`rN',1) = (`"`nl`m''"'), bold colspan(`K')
            forvalues j = 1/`J' {
                putdocx table _ct(`rN',`=`j'+1') = ("`N`m'_`j''"), halign(right)
            }
        }
        if `"`pie'"'!="" {
            putdocx paragraph
            putdocx text (`"`pie'"'), font(, 9) italic
        }
        if !`abierto' putdocx save `"`file'"', replace
    }
    else if "`ext'"!="none" {
        * other formats: the collect layout
        collect export `"`file'"', replace
    }
end

* Subsample in words, using variable and value labels: "pais==2" -> "País: Perú",
* "inlist(year,2012,2025)" -> "Año: 2012, 2025", "inrange(edad,15,22)" -> "Edad:
* 15–22". Pieces joined by & only; anything else is returned as written.
program define _cruce_ifdesc, rclass
    args cond
    local resto `"`cond'"'
    local desc
    local ok 1
    while `"`resto'"'!="" & `ok' {
        local p = strpos(`"`resto'"', "&")
        if `p' {
            local pieza = strtrim(substr(`"`resto'"', 1, `p'-1))
            local resto = substr(`"`resto'"', `p'+1, .)
        }
        else {
            local pieza = strtrim(`"`resto'"')
            local resto
        }
        local txt
        if ustrregexm(`"`pieza'"', "^([A-Za-z_][A-Za-z0-9_]*)\s*(==|!=|>=|<=|>|<)\s*(-?[0-9.]+)$") {
            local v = ustrregexs(1)
            local op = ustrregexs(2)
            local x = ustrregexs(3)
            capture confirm variable `v'
            if _rc local ok 0
            else {
                local vlab : variable label `v'
                if `"`vlab'"'=="" local vlab `v'
                local val `x'
                local vl : value label `v'
                if "`vl'"!="" & inlist("`op'", "==", "!=") local val : label `vl' `x'
                local sim = cond("`op'"=="==", " =", cond("`op'"=="!=", " ≠", cond("`op'"==">=", " ≥", cond("`op'"=="<=", " ≤", " `op'"))))
                local txt `"`vlab'`sim' `val'"'
            }
        }
        else if ustrregexm(`"`pieza'"', "^(inlist|inrange)\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,(.*)\)$") {
            local fn = ustrregexs(1)
            local v = ustrregexs(2)
            local args = ustrregexs(3)
            capture confirm variable `v'
            if _rc local ok 0
            else {
                local vlab : variable label `v'
                if `"`vlab'"'=="" local vlab `v'
                local vl : value label `v'
                local lista
                local args = subinstr(`"`args'"', ",", " ", .)
                foreach a of local args {
                    local e `a'
                    if "`vl'"!="" & "`fn'"=="inlist" local e : label `vl' `a'
                    local lista `"`lista'`=cond(`"`lista'"'=="", "", cond("`fn'"=="inrange", "–", ", "))'`e'"'
                }
                local txt `"`vlab': `lista'"'
            }
        }
        else local ok 0
        if `ok' local desc `"`desc'`=cond(`"`desc'"'=="", "", "; ")'`txt'"'
    }
    if !`ok' local desc `"`cond'"'
    return local desc `"`desc'"'
end

* relabel() for graph bar: labels over 30 characters wrapped in lines of up to 28
program define _cruce_relab, rclass
    args v touse
    local vl : value label `v'
    if "`vl'"=="" exit
    quietly levelsof `v' if `touse', local(lv)
    local rl
    local i 0
    foreach x of local lv {
        local ++i
        local t : label `vl' `x'
        if udstrlen(`"`t'"')<=30 continue
        local lin
        local cur
        foreach w of local t {
            if `"`cur'"'!="" & udstrlen(`"`cur' `w'"')>28 {
                local lin `"`lin' `"`cur'"'"'
                local cur `"`w'"'
            }
            else local cur = strtrim(`"`cur' `w'"')
        }
        local lin `"`lin' `"`cur'"'"'
        local rl `"`rl' `i' `"`lin'"'"'
    }
    if `"`rl'"'!="" return local rl `"relabel(`rl')"'
end

* LaTeX-safe text: % & _ # $ escaped one at a time (a single nested expression is too long)
program define _cruce_texesc, rclass
    args s
    * by character code: a literal backslash or $ inside the ado would be read as
    * a macro escape (35 #, 36 $, 37 %, 38 &, 95 _; 92 is the backslash)
    foreach c in 35 37 38 95 {
        local s = subinstr(`"`s'"', char(`c'), char(92) + char(`c'), .)
    }
    * "\$" would come back as "$" through the macro: use \textdollar{}
    local s = subinstr(`"`s'"', char(36), char(92) + "textdollar{}", .)
    * < and > print as inverted marks in the default OT1 encoding
    local s = subinstr(`"`s'"', char(60), char(92) + "textless{}", .)
    local s = subinstr(`"`s'"', char(62), char(92) + "textgreater{}", .)
    return local s `"`s'"'
end

* column widths of an exported .xlsx, one per column, in characters
version 17.0
mata:
void _cruce_xlanchos(string scalar f, string scalar anchos)
{
    class xl scalar b
    real rowvector w
    real scalar c
    w = strtoreal(tokens(anchos))
    b.load_book(f)
    b.set_sheet(b.get_sheets()[1])
    for (c = 1; c <= cols(w); c++) b.set_column_width(c, c, w[c])
    b.close_book()
}
end
