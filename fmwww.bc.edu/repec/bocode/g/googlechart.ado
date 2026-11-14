*! googlechart v0.1.7  2026-11-12
*! v0.1.7: the value axis of bar, column, and area charts always includes
*!   zero, so bar lengths are proportional to the values (the axis used to
*!   start near the smallest value).
*! v0.1.6: timeline startvar()/endvar() with a %tc or %tC datetime format are
*!   written as date-times (they were read as %td days, giving wrong dates);
*!   %tw/%tm/%tq/%th dates are written as the day their period starts.
*! v0.1.5: numbers are written at full precision (floats at the precision they
*!   hold, doubles exactly) and no longer depend on set dp; string data is
*!   written without macro expansion, so "$" and "`" in values survive and a
*!   value ending in a double quote no longer stops the command; newlines,
*!   tabs, other control characters and "</" are escaped in the page data;
*!   legendpos(), innerradius() and centerlevel() are checked with clear
*!   errors.  filters() works again (it drew a blank chart): each row now
*!   carries its filter values, the page draws its own dropdown / range
*!   controls, and a change re-filters the rows and rebuilds the chart, for
*!   every type().
*! v0.1.4: options read the same on every Stata version (TX2036style); the
*!   authors' house style is opt-in only -- default palette is now Google
*!   Charts' standard colors (geo: blues; divbar: rdbu); unknown scheme()
*!   names fall back to the default with a note; the page is assembled with
*!   Mata instead of shell type/cat; a leading "~" in export() is expanded
*!   here; the house font falls back to a system sans-serif if it can't load.
*! Stata wrapper for the Google Charts (Visualization API) library.
*!
*! SIBLING to sparkta2 -- different use case, not a replacement.
*! Trade-off:
*!   - sparkta2 ships d3 + topojson inline; HTML works offline.
*!   - googlechart uses Google Charts CDN (https://www.gstatic.com);
*!     HTML requires network at view time per Google ToS.  In return:
*!     14 native chart types, interactive filters (filters()) on every
*!     type, native animations, polished default tooltips.
*!
*! Authorship: Eric Booth, Texas 2036.  Built atop Google Charts
*! (https://developers.google.com/chart) -- not affiliated with Google.
*!
*! Supported types (v0.1):
*!   column, bar, line, area, combo, pie, donut, scatter, bubble, geo,
*!   timeline, table, histogram, divbar.
*!
*! Common features (apply to most types):
*!   tx2036style    INTERNAL: the authors' house style (off by default)
*!   download       Export menu (PNG/SVG)
*!   datatable      View data table + CSV download
*!   animate        IntersectionObserver-gated initial draw
*!   filters()      Filter dropdowns / range sliders (every type)
*!   downloadpos    side (default) | below | none

program define googlechart, rclass
    version 17.0

    syntax [varlist(numeric default=none)] [if] [in], TYPE(string) [ ///
        NAME(varname)                                              ///
        OVER(varname)                                              ///
        LEVel(varname)                                             ///
        LEVELORDer(string)                                         ///
        CENTERlevel(string)                                        ///
        TIME(varname)                                              ///
        STARTvar(varname)                                          ///
        ENDvar(varname)                                            ///
        SIZEvar(varname numeric)                                   ///
        HORIzontal                                                 ///
        STACKed                                                    ///
        NORMAlize                                                  ///
        DIRECTlabels                                               ///
        SCHEME(string)                                             ///
        TX2036style                                                ///
        DOWNload                                                   ///
        DATATable                                                  ///
        ANIMate                                                    ///
        DOWNLOADPos(string)                                        ///
        FILTERS(varlist)                                           ///
        TOOLTIPvars(varlist)                                       ///
        TITLE(string) SUBtitle(string) NOTE(string)                ///
        XLABel(string) YLABel(string)                              ///
        NAMELabel(string) VALUELabel(string)                       ///
        LABELWRap(string)                                          ///
        LEGENDPos(string)                                          ///
        TABLESEArch                                                ///
        TABLEHEAdersticky                                          ///
        TABLEFRozencols(integer 0)                                 ///
        GEOREGion(string) GEORESolution(string)                    ///
        COMBOTypes(string) COMBODflt(string)                        ///
        INNERradius(real 0.45)                                     ///
        BUCKETSize(real 0)                                         ///
        WIDTH(integer 980) HEIGHT(integer 644)                     ///
        EXPORT(string) NOOPEN                                      ///
    ]

    marksample touse, novarlist

    local type = lower("`type'")
    local _valid_types "column bar line area combo pie donut scatter bubble geo timeline table histogram divbar"
    if !`:list type in _valid_types' {
        display as error "googlechart: type(`type') not recognised."
        display as error "  Valid: `_valid_types'"
        exit 198
    }

    * Validation of feature flags
    local is_tx2036st   = cond("`tx2036style'"  != "", 1, 0)
    local is_download   = cond("`download'"     != "", 1, 0)
    local is_datatable  = cond("`datatable'"    != "", 1, 0)
    local is_animate    = cond("`animate'"      != "", 1, 0)
    local is_stacked    = cond("`stacked'"      != "", 1, 0)
    local is_normalize  = cond("`normalize'"    != "", 1, 0)
    local is_directlbl  = cond("`directlabels'" != "", 1, 0)
    local is_tblsearch  = cond("`tablesearch'"   != "", 1, 0)
    local is_tblsticky  = cond("`tableheadersticky'" != "", 1, 0)

    * Guard: on a bar/column chart, directlabels adds an annotation-role
    * column, and Google Charts throws on animation.startup when that column
    * is present -- the chart then renders blank.  The two options are
    * mutually exclusive here, so drop animate and tell the user rather than
    * emit a page that silently fails to draw.
    if `is_animate' & `is_directlbl' & inlist("`type'","bar","column") {
        display as text "googlechart: animate is incompatible with directlabels on " ///
            "type(`type') (Google Charts errors on the annotation column); ignoring animate."
        local is_animate = 0
    }

    local legendpos = lower(strtrim(`"`macval(legendpos)'"'))
    if `"`macval(legendpos)'"' != "" {
        local _vl "top right bottom left none"
        if !`:list legendpos in _vl' {
            display as error `"googlechart: legendpos(`macval(legendpos)') -- valid: top | right | bottom | left | none"'
            exit 198
        }
    }

    if !(`innerradius' > 0 & `innerradius' < 1) {
        display as error "googlechart: innerradius(`innerradius') must be greater than 0 and less than 1 (the hole's share of the radius)"
        exit 198
    }

    * centerlevel() names one of the divbar levels.  When levelorder() is
    * given, check it against that list now; otherwise check it against the
    * levels found in the data once the rows are read.
    local _chk_center 0
    local _clhit 0
    if "`type'" == "divbar" & `"`macval(centerlevel)'"' != "" {
        if `"`macval(levelorder)'"' != "" {
            mata: st_local("_clok", strofreal(strpos("|" + st_local("levelorder") + "|", "|" + st_local("centerlevel") + "|") > 0))
            if !`_clok' {
                display as error `"googlechart: centerlevel(`macval(centerlevel)') is not one of the levels in levelorder(`macval(levelorder)')"'
                exit 198
            }
        }
        else {
            local _chk_center 1
            mata: st_local("_jcl", _gc_jstr(st_local("centerlevel")))
            local _clhit 0
        }
    }

    if "`downloadpos'" == "" local downloadpos "side"
    local downloadpos = lower("`downloadpos'")
    local _vd "side below none"
    if !`:list downloadpos in _vd' {
        display as error "googlechart: downloadpos(`downloadpos') -- valid: side | below | none"
        exit 198
    }

    * Default palette.  The authors' house palette (tx2036) is used only when
    * tx2036style or scheme(tx2036) asks for it; everyone else gets Google
    * Charts' standard colors, a sequential ramp for maps, and a diverging
    * pair for Likert bars.
    if "`scheme'" == "" {
        if `is_tx2036st'               local scheme "tx2036"
        else if "`type'" == "divbar"   local scheme "rdbu"
        else if "`type'" == "geo"      local scheme "blues"
        else                           local scheme "default"
    }
    local scheme = lower("`scheme'")
    local _known "default tx2036 blues reds greens oranges purples rdbu rdylgn viridis"
    if !`: list scheme in _known' {
        display as text "googlechart: note: scheme(`scheme') is not a built-in palette; using scheme(default)."
        local scheme "default"
    }

    * For BAR type, the user often expects HORIZONTAL.  Google Charts'
    * BarChart class IS horizontal; ColumnChart is vertical.  Resolve here.
    local _engine_type "`type'"
    if "`type'" == "column" & "`horizontal'" != "" local _engine_type "bar"
    if "`type'" == "bar"    & "`horizontal'" == "" {
        * Bar in googlechart means horizontal by convention.
        * No change needed.
    }

    * Per-type required-input checks (kept minimal so the engine can
    * surface its own errors when something's off)
    local nvar : word count `varlist'
    local _v1 : word 1 of `varlist'
    local _v2 : word 2 of `varlist'

    * When user calls `googlechart y x, over(series) type(line|area|combo)'
    * with 2 numeric vars and no explicit name(), treat _v2 as the category
    * dimension (x-axis) and _v1 as the value.  Without this, the engine
    * gets every row with name="" and reshapes them onto a single x slot.
    if (inlist("`type'","line","area","combo")) & (`nvar' == 2) & ("`name'" == "") {
        local name "`_v2'"
        local _v2 ""
        local nvar = 1
        display as txt "googlechart: type(`type') with two vars + no name() -- using `name' as the x-axis category."
    }

    * String inlist() caps at ~10 args -- split.
    if inlist("`type'","column","bar","line","area","combo") | ///
       inlist("`type'","pie","donut","geo","histogram","divbar") {
        if `nvar' < 1 {
            display as error "googlechart: type(`type') requires at least one numeric var"
            exit 198
        }
    }
    if inlist("`type'","scatter","bubble") {
        if `nvar' < 2 {
            display as error "googlechart: type(`type') requires two numeric vars (x y)"
            exit 198
        }
    }
    if "`type'" == "divbar" {
        if "`level'" == "" {
            display as error "googlechart: type(divbar) requires level(varname)"
            exit 198
        }
        if "`name'" == "" {
            display as error "googlechart: type(divbar) requires name(varname) -- the item label"
            exit 198
        }
    }
    if "`type'" == "timeline" {
        if "`startvar'" == "" | "`endvar'" == "" {
            display as error "googlechart: type(timeline) requires startvar() and endvar()"
            exit 198
        }
        if "`name'" == "" {
            display as error "googlechart: type(timeline) requires name(varname) -- the row label"
            exit 198
        }
    }
    if "`type'" == "geo" {
        if "`name'" == "" {
            display as error "googlechart: type(geo) requires name(varname) -- region/country code"
            exit 198
        }
        display as txt "googlechart: type(geo) supports country and US-state level only."
        display as txt "  For county or school-district choropleths, use a mapping command"
        display as txt "  that reads shapefiles."
    }

    if `"`macval(title)'"' == "" {
        if      "`type'" == "donut"    local title "Donut chart"
        else if "`type'" == "divbar"   local title "Diverging stacked bar"
        else if "`type'" == "timeline" local title "Timeline"
        else {
            local _tprop = proper("`type'")
            local title  "`_tprop' chart"
        }
    }
    if "`export'" == "" local export "`c(pwd)'/googlechart_`type'.html"
    * If export() starts with "~", expand it here so the HTML writer and the
    * copy step get the same full path; how "~" is handled otherwise differs
    * across operating systems and Stata versions.
    _gc_expandtilde, local(export) path(`"`export'"')

    * --- Discover the engine and helpers --------------------------
    * The engine is shipped as googlechart_engine.sthlp because Stata's
    * net install only copies files with a small set of recognised
    * extensions (.ado, .sthlp, .mata, .mlib, .dta, ...).  .js is NOT in
    * that list -- net install silently skips it -- so we use .sthlp as
    * a safe container for the JavaScript text.  The contents are not
    * Stata syntax; the file is treated as opaque text and embedded
    * into the output HTML via googlechart_embedjs.
    capture findfile googlechart_engine.sthlp
    if _rc {
        display as error "googlechart: googlechart_engine.sthlp not on adopath."
        display as error "  Make sure the googlechart package is in your _codeshare or local clone."
        exit 601
    }
    local engpath "`r(fn)'"

    * --- Build the long-form row JSON ------------------------------------
    * Schema: each row is one observation with optional fields --
    * name, value, g (series), lev (level), t (time), x, y, start, end,
    * size, t__VAR.  Empty values omitted to keep the JSON tight.
    *
    * Every value is turned into JSON text by the Mata helpers at the end of
    * this file: _gc_jnum() writes numbers at full precision with a "."
    * decimal point whatever -set dp- says, and _gc_jtext()/_gc_jtip() read
    * strings straight from the data (no macro expansion) and escape them.
    * The results are written with `macval()' inside compound quotes.
    tempfile rowjson
    tempname rfh
    quietly file open `rfh' using "`rowjson'", write text replace

    * 1 when the variable is stored as float (written at float precision).
    foreach _w in _v1 _v2 sizevar time {
        local _fl`_w' 0
        if "``_w''" != "" {
            local _st : type ``_w''
            local _fl`_w' = ("`_st'" == "float")
        }
    }
    local _f1 `_fl_v1'
    local _f2 `_fl_v2'
    local _fs `_flsizevar'
    local _ft `_fltime'

    local _first 1
    local _rows_written = 0
    quietly {
        forvalues _i = 1/`=_N' {
            if !`touse'[`_i'] continue

            * --- Build the per-row record -----------------------------
            * For bubble: _v1=x, _v2=y.  For scatter: _v1=x, _v2=y.
            * For timeline: no varlist; uses start/end.
            * For everything else: _v1=value, _v2 unused.
            * The engine knows which fields to consume per type.
            local _x1miss 1
            local _x2miss 1
            if `nvar' >= 1 local _x1miss = missing(`_v1'[`_i'])
            if `nvar' >= 2 local _x2miss = missing(`_v2'[`_i'])

            * Skip rows where the primary numeric is missing.  Two
            * exceptions: divbar treats missing share as 0; timeline
            * relies on start/end (no primary numeric).
            if "`type'" != "timeline" & "`type'" != "table" & `_x1miss' {
                if "`type'" != "divbar" continue
            }
            if inlist("`type'","scatter","bubble") & `_x2miss' continue

            * Resolve string-or-label fields (already JSON-escaped)
            local _nm ""
            local _ov ""
            local _lv ""
            if "`name'"  != "" mata: st_local("_nm", _gc_jtext(`_i', "`name'"))
            if "`over'"  != "" mata: st_local("_ov", _gc_jtext(`_i', "`over'"))
            if "`level'" != "" mata: st_local("_lv", _gc_jtext(`_i', "`level'"))

            * Date / number helper fields
            local _start ""
            local _end   ""
            if "`startvar'" != "" {
                if missing(`startvar'[`_i']) continue
                mata: st_local("_start", _gc_jdate(`_i', "`startvar'"))
            }
            if "`endvar'" != "" {
                if missing(`endvar'[`_i']) continue
                mata: st_local("_end", _gc_jdate(`_i', "`endvar'"))
            }

            if `_chk_center' {
                if `"`macval(_lv)'"' == `"`macval(_jcl)'"' local _clhit 1
            }

            * Emit the row
            if `_first' local _first 0
            else file write `rfh' "," _n
            file write `rfh' "        {"

            * Map varlist to fields per type.  _gc_jnum() returns `null'
            * for a missing value: Stata's own "." is not valid JSON, and
            * the type=table case has no varlist at all.
            if inlist("`type'","scatter","bubble") {
                mata: st_local("_s", _gc_jnum(st_data(`_i', "`_v1'"), `_f1'))
                file write `rfh' `""x":`_s'"'
                mata: st_local("_s", _gc_jnum(st_data(`_i', "`_v2'"), `_f2'))
                file write `rfh' `","y":`_s'"'
                if "`type'" == "bubble" {
                    if "`sizevar'" != "" mata: st_local("_s", _gc_jnum(st_data(`_i', "`sizevar'"), `_fs'))
                    else                 local _s "null"
                    file write `rfh' `","size":`_s'"'
                }
            }
            else if "`type'" == "table" {
                * type(table) typically passes no varlist -- columns come
                * from tooltipvars() instead.  Emit an opening placeholder
                * so the row JSON is valid even when no fields follow.
                file write `rfh' `""_":null"'
            }
            else {
                * For column/bar/line/area/pie/donut/geo/divbar/histogram/combo:
                * primary numeric is the value, optionally with a series.
                if `nvar' >= 1 mata: st_local("_s", _gc_jnum(st_data(`_i', "`_v1'"), `_f1'))
                else           local _s "null"
                file write `rfh' `""value":`_s'"'
            }

            * Block form on purpose: the one-line "if exp command" form
            * expands macros in the command a second time.
            if `"`macval(_nm)'"' != "" {
                file write `rfh' `","name":""' `"`macval(_nm)'"' `"""'
            }
            if `"`macval(_ov)'"' != "" {
                file write `rfh' `","g":""' `"`macval(_ov)'"' `"""'
            }
            if `"`macval(_lv)'"' != "" {
                file write `rfh' `","lev":""' `"`macval(_lv)'"' `"""'
            }
            if `"`_start'"' != ""      file write `rfh' `","start":"`_start'""'
            if `"`_end'"'   != ""      file write `rfh' `","end":"`_end'""'

            * Time dimension (numeric) -- used by bubble/play and reserved
            * for future per-type uses.
            if "`time'" != "" {
                if !missing(`time'[`_i']) {
                    mata: st_local("_s", _gc_jnum(st_data(`_i', "`time'"), `_ft'))
                    file write `rfh' `","t":`_s'"'
                }
            }

            * Tooltipvars (extra columns shown in the data table)
            if "`tooltipvars'" != "" {
            foreach _tv of varlist `tooltipvars' {
                mata: st_local("_s", _gc_jtip(`_i', "`_tv'"))
                file write `rfh' `","t__`_tv'":"' `"`macval(_s)'"'
            }
            }

            * filters() values (f__VAR): what the page filters rows on.  A
            * string or value-labeled variable is written as text (the
            * label), any other numeric as a number; missing as null.
            if "`filters'" != "" {
            foreach _fv of local filters {
                mata: st_local("_s", _gc_jtip(`_i', "`_fv'"))
                file write `rfh' `","f__`_fv'":"' `"`macval(_s)'"'
            }
            }

            file write `rfh' "}" _n
            local ++_rows_written
        }
    }
    file close `rfh'

    if `_rows_written' == 0 {
        display as error "googlechart: no rows to plot (check [if] / [in] / missing values)"
        exit 459
    }

    if `_chk_center' & !`_clhit' {
        display as error `"googlechart: centerlevel(`macval(centerlevel)') does not match any value of `level' in the rows plotted"'
        exit 198
    }

    * --- Build filter spec JSON ------------------------------------------
    tempfile filterjson
    quietly file open `rfh' using "`filterjson'", write text replace
    file write `rfh' "["
    local _fcount = 0
    if "`filters'" != "" {
    foreach _fv of varlist `filters' {
        if `_fcount' > 0 file write `rfh' ","
        local ++_fcount
        mata: st_local("_lbl", _gc_jstr(st_varlabel("`_fv'")))
        if `"`macval(_lbl)'"' == "" local _lbl "`_fv'"
        capture confirm numeric variable `_fv'
        local _isnum = (_rc == 0)
        local _vlab : value label `_fv'
        * Treat numeric with a value label as categorical, not numeric range
        local _numeric_filter = cond(`_isnum' & "`_vlab'" == "", 1, 0)
        file write `rfh' `"{"var":"`_fv'","label":""' `"`macval(_lbl)'"' `"","numeric":`_numeric_filter'"'
        * Dropdown order for a categorical filter: sorted values (strings),
        * or the labels in order of the underlying codes (value-labeled).
        if !`_numeric_filter' {
            mata: st_local("_lv", _gc_jlevels("`_fv'", "`touse'"))
            file write `rfh' `","levels":"' `"`macval(_lv)'"'
        }
        file write `rfh' "}"
    }
    }

    * filters() narrows the rows; the chart then places one value per
    * category (and per over() series).  When several rows share a cell the
    * last one is drawn, so say so when that will happen before filtering.
    if "`filters'" != "" & "`name'" != "" & inlist("`type'","column","bar","line","area","combo") {
        mata: st_local("_gcdup", strofreal(_gc_hasdup("`name' `over'", "`touse'")))
        if `_gcdup' {
            display as text "googlechart: note: some `name'" cond("`over'" != "", " x `over'", "") ///
                " cells have more than one row; until filters() narrow them to one row," ///
                " the chart shows the last row in each cell."
        }
    }
    file write `rfh' "]"
    file close `rfh'

    * --- Build placeholder meta JSON (engine still needs the meta block) -
    tempfile metajson
    quietly file open `rfh' using "`metajson'", write text replace
    file write `rfh' "{}"
    file close `rfh'

    * --- Emit final HTML -------------------------------------------------
    local _v1_name "`_v1'"
    if "`_v1_name'" == "" local _v1_name "value"
    local _v2_name "`_v2'"

    googlechart_writehtml,                                                  ///
        engpath("`engpath'") rowjson("`rowjson'") metajson("`metajson'")    ///
        filterjson("`filterjson'") export(`"`export'"')                     ///
        type("`_engine_type'") scheme("`scheme'")                           ///
        title(`"`macval(title)'"') subtitle(`"`macval(subtitle)'"')         ///
        note(`"`macval(note)'"')                                            ///
        xlabel(`"`macval(xlabel)'"') ylabel(`"`macval(ylabel)'"')           ///
        xvar("`_v1_name'") yvar("`_v2_name'") name("`name'") over("`over'") ///
        level("`level'") time("`time'")                                     ///
        namelabel(`"`macval(namelabel)'"') valuelabel(`"`macval(valuelabel)'"') ///
        levelorder(`"`macval(levelorder)'"') centerlevel(`"`macval(centerlevel)'"') ///
        labelwrap(`"`macval(labelwrap)'"')                                  ///
        isdownload(`is_download') isdatatable(`is_datatable')               ///
        isanimate(`is_animate') istx2036style(`is_tx2036st')                ///
        downloadpos("`downloadpos'")                                        ///
        isstacked(`is_stacked') isnormalize(`is_normalize')                 ///
        isdirectlabels(`is_directlbl')                                      ///
        innerradius(`innerradius') bucketsize(`bucketsize')                 ///
        georegion(`"`macval(georegion)'"') georesolution(`"`macval(georesolution)'"') ///
        combotypes(`"`macval(combotypes)'"') combodefault(`"`macval(combodflt)'"') ///
        legendpos("`legendpos'")                                            ///
        istblsearch(`is_tblsearch') istblsticky(`is_tblsticky')              ///
        tblfrozencols(`tablefrozencols')                                    ///
        width(`width') height(`height')

    display as text _n "[googlechart]  `type' written:"
    display as text `"  {browse "`export'":`export'}"'
    display as text "  Rows: `_rows_written'  Scheme: `scheme'"

    return local export "`export'"
    return local type   "`type'"
    return scalar n_rows = `_rows_written'

end


* Expand a leading "~" (bare "~", "~/" or "~\") to the home directory, without
* relying on the operating system, Stata, or Mata to do it.  "~otheruser/..."
* and a "~" anywhere else are left alone.  Result goes to the caller's local.
program define _gc_expandtilde
    version 17.0
    syntax , LOCAL(name) [ PATH(string) ]
    local p `"`path'"'
    if `"`p'"' == "~" | strpos(`"`p'"', "~/") == 1 | strpos(`"`p'"', "~\") == 1 {
        if lower("`c(os)'") == "windows" local order "USERPROFILE HOMEDRIVEPATH HOME"
        else                              local order "HOME USERPROFILE HOMEDRIVEPATH"
        local home ""
        foreach src of local order {
            if `"`home'"' != "" continue
            if "`src'" == "HOMEDRIVEPATH" {
                local drive : env HOMEDRIVE
                local hpath : env HOMEPATH
                if `"`drive'`hpath'"' != "" local home `"`drive'`hpath'"'
            }
            else local home : env `src'
        }
        if `"`home'"' != "" {
            local rest = substr(`"`p'"', 2, .)
            if `"`rest'"' != "" {
                local cl = substr(`"`home'"', -1, 1)
                if `"`cl'"' == "/" | `"`cl'"' == "\" {
                    if length(`"`home'"') > 1 local home = substr(`"`home'"', 1, length(`"`home'"') - 1)
                    else local rest = substr(`"`rest'"', 2, .)
                }
            }
            local p `"`home'`rest'"'
        }
    }
    c_local `local' `"`p'"'
end


* ---------------------------------------------------------------------------
* JSON helpers.  Private to this file (Stata compiles them when the file
* loads; only this file can call them).  Do not add a "mata drop" for them.
* Backslash, quote and other awkward characters are built with char() so the
* source holds no escape sequences.
* ---------------------------------------------------------------------------
mata:
// A number as JSON/JavaScript text, or "null" when missing.  Floats are
// written at the precision a float holds (8 significant digits, 9 when 8
// would not give back the same float), so 14.2 stays 14.2 rather than
// 14.19999980926514.  Other types are written so the value reads back
// exactly.  strofreal() always uses "." whatever -set dp- says.
string scalar _gc_jnum(real scalar x, real scalar isfloat)
{
    real scalar y, e
    string scalar s

    if (missing(x)) return("null")
    y = x
    if (isfloat) {
        y = strtoreal(strofreal(x, "%15.7e"))
        // Mata has no float(): keep the 8-digit value only when it is less
        // than half a float step from x, so it reads back as the same float.
        if (x != 0) {
            e = floor(log(abs(x))/log(2))
            if (2^e > abs(x))      e = e - 1
            if (2^(e+1) <= abs(x)) e = e + 1
            if (abs(y - x) >= 2^(e - 24)) y = strtoreal(strofreal(x, "%16.8e"))
        }
    }
    if (y == floor(y) & abs(y) <= 9007199254740992) s = strofreal(y, "%21.0f")
    else {
        s = strofreal(y, "%17.0g")
        if (strtoreal(s) != y) s = strofreal(y, "%21.0g")
        if (strtoreal(s) != y) s = strofreal(y, "%24.16e")
    }
    s = strtrim(s)
    if (substr(s, 1, 1) == ".")       s = "0" + s
    else if (substr(s, 1, 2) == "-.") s = "-0" + substr(s, 2, .)
    return(s)
}

// Escape a string for use inside a double-quoted JSON string that sits in an
// inline <script> block and is written by -file write- in compound quotes.
string scalar _gc_jstr(string scalar s)
{
    real scalar i
    string scalar bs, q

    bs = char(92)
    q  = char(34)
    s = subinstr(s, bs, bs + bs)
    s = subinstr(s, q, bs + q)
    s = subinstr(s, char(10), bs + "n")
    s = subinstr(s, char(13), bs + "r")
    s = subinstr(s, char(9),  bs + "t")
    s = subinstr(s, char(8),  bs + "b")
    s = subinstr(s, char(12), bs + "f")
    for (i = 1; i <= 31; i++) {
        if (i != 8 & i != 9 & i != 10 & i != 12 & i != 13) {
            s = subinstr(s, char(i), bs + "u00" + (i < 16 ? "0" : "1") + substr("0123456789abcdef", mod(i, 16) + 1, 1))
        }
    }
    // "</" would end the <script> block early.
    s = subinstr(s, "<" + "/", "<" + bs + "/")
    // Keep -file write-'s compound quotes intact: a quote followed by an
    // apostrophe would close them early, and a backtick right before the
    // closing quote would open a nested pair.
    s = subinstr(s, q + char(39), q + bs + "u0027")
    if (substr(s, 1, 1) == char(39))  s = bs + "u0027" + substr(s, 2, .)
    if (substr(s, -1, 1) == char(96)) s = substr(s, 1, strlen(s) - 1) + bs + "u0060"
    return(s)
}

// The text of observation i of variable v, JSON-escaped: the string itself,
// the value label of a labeled numeric, or the number; "" when missing.
string scalar _gc_jtext(real scalar i, string scalar v)
{
    real scalar x
    string scalar lab, t

    if (st_isstrvar(v)) return(_gc_jstr(st_sdata(i, v)))
    x = st_data(i, v)
    if (missing(x)) return("")
    lab = st_varvaluelabel(v)
    if (lab != "") {
        if (st_vlexists(lab)) {
            t = st_vlmap(lab, x)
            if (t != "") return(_gc_jstr(t))
        }
    }
    return(_gc_jnum(x, st_vartype(v) == "float"))
}

// A tooltip/table cell as a complete JSON token: a quoted string for string
// and value-labeled variables, a number otherwise, null when missing.
string scalar _gc_jtip(real scalar i, string scalar v)
{
    string scalar q

    q = char(34)
    if (st_isstrvar(v)) return(q + _gc_jstr(st_sdata(i, v)) + q)
    if (missing(st_data(i, v))) return("null")
    if (st_varvaluelabel(v) != "") return(q + _gc_jtext(i, v) + q)
    return(_gc_jnum(st_data(i, v), st_vartype(v) == "float"))
}

// The distinct non-missing values of v among observations where tu != 0,
// as a JSON array of strings: sorted strings for a string variable; for a
// numeric one, codes in ascending order written as _gc_jtext() writes them
// (the value label when there is one).
string scalar _gc_jlevels(string scalar v, string scalar tu)
{
    real colvector x
    string colvector sx
    string scalar out, q, lab, t
    real scalar i, isfl

    q = char(34)
    out = ""
    if (st_isstrvar(v)) {
        sx = uniqrows(st_sdata(., v, tu))
        for (i = 1; i <= rows(sx); i++) {
            if (sx[i] == "") continue
            out = out + (out == "" ? "" : ",") + q + _gc_jstr(sx[i]) + q
        }
    }
    else {
        x = uniqrows(st_data(., v, tu))
        lab = st_varvaluelabel(v)
        isfl = (st_vartype(v) == "float")
        for (i = 1; i <= rows(x); i++) {
            if (missing(x[i])) continue
            t = ""
            if (lab != "") {
                if (st_vlexists(lab)) t = st_vlmap(lab, x[i])
            }
            if (t != "") t = _gc_jstr(t)
            else         t = _gc_jnum(x[i], isfl)
            out = out + (out == "" ? "" : ",") + q + t + q
        }
    }
    return("[" + out + "]")
}

// 1 when two observations with tu != 0 share the same values of vars.
// Does not change the sort order of the data.
real scalar _gc_hasdup(string scalar vars, string scalar tu)
{
    string rowvector vv
    string colvector key
    real scalar j

    vv = tokens(vars)
    key = J(rows(st_data(., tu, tu)), 1, "")
    for (j = 1; j <= cols(vv); j++) {
        if (st_isstrvar(vv[j])) key = key :+ char(31) :+ st_sdata(., vv[j], tu)
        else                    key = key :+ char(31) :+ strofreal(st_data(., vv[j], tu), "%21.0g")
    }
    return(rows(uniqrows(key)) < rows(key))
}

// A timeline start/end value.  A %tc / %tC datetime becomes an ISO date-time
// (YYYY-MM-DDTHH:MM:SS, with .sss when there are milliseconds); a %td date
// an ISO date (YYYY-MM-DD); a %tw / %tm / %tq / %th date the ISO date its
// period starts on; a %ty year, or a variable without a date format, the
// number (the page reads a four-digit number as 1 January of that year).
string scalar _gc_jdate(real scalar i, string scalar v)
{
    real scalar x
    string scalar f, k

    x = st_data(i, v)
    f = subinstr(st_varformat(v), "-", "")
    if (substr(f, 1, 2) == "%d") k = "d"
    else if (substr(f, 1, 2) == "%t") k = substr(f, 3, 1)
    else k = ""
    if (k == "c" | k == "C") {
        if (k == "C") x = cofC(x)
        if (mod(x, 1000) != 0) return(strofreal(x, "%tcCCYY-NN-DD!THH:MM:SS.sss"))
        return(strofreal(x, "%tcCCYY-NN-DD!THH:MM:SS"))
    }
    if (k == "d") return(strofreal(x, "%tdCCYY-NN-DD"))
    if (k == "w") return(strofreal(dofw(x), "%tdCCYY-NN-DD"))
    if (k == "m") return(strofreal(dofm(x), "%tdCCYY-NN-DD"))
    if (k == "q") return(strofreal(dofq(x), "%tdCCYY-NN-DD"))
    if (k == "h") return(strofreal(dofh(x), "%tdCCYY-NN-DD"))
    return(_gc_jnum(x, st_vartype(v) == "float"))
}
end
