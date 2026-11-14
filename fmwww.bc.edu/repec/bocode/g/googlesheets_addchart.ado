*! googlesheets_addchart v0.2.3  2026-11-09
*! v0.2.3: the summary printed after a successful call no longer stops with
*!   an error when the tab name holds an apostrophe; the args file uses a
*!   temporary file handle; header comment lists subtitle(), header and the
*!   option's real name, piehole().
*! v0.2.2: type() is checked; an unknown type (a typo such as "colum") is an
*!   error (198) instead of being drawn silently as a column chart.
*! v0.2.1: option spelled TX2036style (TX2036STyle is read as a different name
*!   by older Stata, so "tx2036style" was rejected there).
*! Insert a chart object into a Google Sheet via spreadsheets.batchUpdate.
*! tx2036style is an INTERNAL house style for the authors' own workflows
*! (Montserrat title, navy title colour, house palette).  It is off unless
*! asked for; Sheets falls back to its default font if Montserrat is absent.
*!
*!   googlesheets addchart using "<id-or-url>" ,                          ///
*!       sheet("Sheet1")                                                  ///
*!       type(column | bar | stacked_column | stacked_bar | line | area | ///
*!            scatter | pie | donut)                                      ///
*!       domain("A2:A6")                                                  ///
*!       series("B2:B6")        (one or more, pipe-separated for multi)   ///
*!       [names("Texas|ESC 13|ESC 4")]                                    ///
*!       [colors("#1B2D55|#D44500|#2B6CB0")]                              ///
*!       [title("Finding-first headline")]                                ///
*!       [xlabel("...")] [ylabel("...")]                                  ///
*!       [legendpos(TOP|RIGHT|BOTTOM|LEFT|NONE)]                          ///
*!       [tx2036style]                                                    ///
*!       [subtitle("...")] [header]                                       ///
*!       [piehole(0.5)]     (donut hole; donut sets 0.5 by default)       ///
*!       [targetsheet("Charts")] [anchor(H1)]                            ///
*!       [width(540)] [height(360)]                                       ///
*!       [keyfile() tokenfile() verbose]
*!
*! Multiple series: pass them in `series()' separated by `|', and pass
*! parallel lists in `names()' and `colors()'.

program define googlesheets_addchart
    version 17.0
    syntax using/, SHeet(string) TYPE(string) DOMain(string) SEries(string) ///
        [ NAMEs(string) COLors(string)                                 ///
          TITLE(string) SUBtitle(string) XLAbel(string) YLAbel(string) ///
          LEGENDPos(string)                                            ///
          TX2036style                                                  ///
          PIEhole(real 0)                                             ///
          TARGETsheet(string) ANCHor(string)                          ///
          WIDTH(integer 540) HEIGHT(integer 360)                       ///
          HEADER                                                       ///
          KEYfile(string) TOKENfile(string) VERBose ]

    local type = lower(strtrim(`"`type'"'))
    local _types "column bar stacked_column stacked_bar line area scatter pie donut"
    if !`:list type in _types' {
        display as error `"googlesheets addchart: type(`type') -- valid: `_types'"'
        exit 198
    }

    if "`anchor'" == "" local anchor "H1"
    * Map user-supplied legendpos (top|right|bottom|left|none) to the
    * Sheets API enum (TOP_LEGEND, ..., NO_LEGEND).  Use explicit branches
    * rather than `upper() + "_LEGEND"' because Stata's expression parser
    * trips on the bare keyword "none" in some contexts.
    local _lp = lower("`legendpos'")
    if "`_lp'" == ""        local legendpos "BOTTOM_LEGEND"
    else if "`_lp'" == "top"    local legendpos "TOP_LEGEND"
    else if "`_lp'" == "right"  local legendpos "RIGHT_LEGEND"
    else if "`_lp'" == "bottom" local legendpos "BOTTOM_LEGEND"
    else if "`_lp'" == "left"   local legendpos "LEFT_LEGEND"
    else if "`_lp'" == "none"   local legendpos "NO_LEGEND"
    else if "`_lp'" == "labeled" local legendpos "LABELED_LEGEND"
    else {
        display as error "googlesheets addchart: legendpos(`legendpos') -- valid: top|right|bottom|left|none|labeled"
        exit 198
    }

    * Apply tx2036 defaults: Montserrat title, navy title colour, and (if
    * the user didn't pass colors()) the Texas 2036 palette for the
    * first few series.
    if "`tx2036style'" != "" {
        local font_family "Montserrat"
        local title_color "#1B2D55"
        if `"`macval(colors)'"' == "" {
            local colors "#1B2D55|#D44500|#2B6CB0|#6C7A8D|#7A9D54|#A67B36|#9C5BA5"
        }
    }

    googlesheets_auth, keyfile(`"`keyfile'"') tokenfile(`"`tokenfile'"')
    local client_json `"`r(client_json)'"'
    local token_json  `"`r(token_json)'"'

    _gs_jesc, raw(`"`macval(client_json)'"')
    mata: st_local("cj", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(token_json)'"')
    mata: st_local("tj", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(using)'"')
    mata: st_local("ss", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(sheet)'"')
    mata: st_local("sh", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(domain)'"')
    mata: st_local("dom", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(series)'"')
    mata: st_local("ser", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(names)'"')
    mata: st_local("nms", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(colors)'"')
    mata: st_local("cls", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(title)'"')
    mata: st_local("ti", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(subtitle)'"')
    mata: st_local("sb", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(xlabel)'"')
    mata: st_local("xl", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(ylabel)'"')
    mata: st_local("yl", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(targetsheet)'"')
    mata: st_local("tgs", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(anchor)'"')
    mata: st_local("anc", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(font_family)'"')
    mata: st_local("ff", st_global("r(escaped)"))
    _gs_jesc, raw(`"`macval(title_color)'"')
    mata: st_local("tc", st_global("r(escaped)"))

    tempfile argjson
    tempname h
    quietly file open `h' using `"`argjson'"', write text replace
    file write `h' `"{"' _n
    file write `h' `"  "subcommand":"add_chart","' _n
    file write `h' `"  "client_json":"`macval(cj)'","' _n
    file write `h' `"  "token_json":"`macval(tj)'","' _n
    file write `h' `"  "spreadsheet":"`macval(ss)'","' _n
    file write `h' `"  "sheet":"`macval(sh)'","' _n
    file write `h' `"  "chart_type":"`macval(type)'","' _n
    file write `h' `"  "domain_range":"`macval(dom)'","' _n
    file write `h' `"  "series_ranges":"`macval(ser)'""'
    if `"`macval(nms)'"' != "" {
        file write `h' `","' _n `"  "series_names":"`macval(nms)'""'
    }
    if `"`macval(cls)'"' != "" {
        file write `h' `","' _n `"  "series_colors":"`macval(cls)'""'
    }
    if `"`macval(ti)'"'  != "" {
        file write `h' `","' _n `"  "title":"`macval(ti)'""'
    }
    if `"`macval(sb)'"'  != "" {
        file write `h' `","' _n `"  "subtitle":"`macval(sb)'""'
    }
    if `"`macval(xl)'"'  != "" {
        file write `h' `","' _n `"  "xlabel":"`macval(xl)'""'
    }
    if `"`macval(yl)'"'  != "" {
        file write `h' `","' _n `"  "ylabel":"`macval(yl)'""'
    }
    file write `h' `","' _n `"  "legend_position":"`macval(legendpos)'""'
    if `"`macval(tgs)'"' != "" {
        file write `h' `","' _n `"  "target_sheet":"`macval(tgs)'""'
    }
    file write `h' `","' _n `"  "target_cell":"`macval(anc)'""'
    file write `h' `","' _n `"  "width":`macval(width)'"'
    file write `h' `","' _n `"  "height":`macval(height)'"'
    if `piehole' > 0 {
        * Stata prints .5 not 0.5; JSON requires the leading zero.
        local _ph = strofreal(`piehole', "%18.0g")
        if substr("`_ph'", 1, 1) == "." local _ph "0`_ph'"
        file write `h' `","' _n `"  "pie_hole":`macval(_ph)'"'
    }
    if "`header'" != "" {
        file write `h' `","' _n `"  "has_header":true"'
    }
    if `"`macval(ff)'"' != "" {
        file write `h' `","' _n `"  "font_family":"`macval(ff)'""'
    }
    if `"`macval(tc)'"' != "" {
        file write `h' `","' _n `"  "title_color":"`macval(tc)'""'
    }
    file write `h' _n `"}"' _n
    file close `h'

    googlesheets_runpy, args(`"`argjson'"') `verbose'
    if "`r(status)'" != "ok" {
        display as error "googlesheets addchart: `r(error)' -- `r(message)'"
        exit 198
    }
    local content `"`r(content)'"'
    _gs_field, content(`"`content'"') key("chartId")
    local cid `"`r(value)'"'

    display as result _n "[googlesheets addchart]"
    display as text   `"  spreadsheet:   `macval(using)'"'
    display as text   `"  data sheet:    `macval(sheet)'"'
    display as text   `"  chart type:    `macval(type)'"'
    * Block form, and no `=cond()', so a tab name holding an apostrophe or
    * a quote cannot break the line (the chart is already in the Sheet).
    if `"`macval(targetsheet)'"' != "" {
        display as text `"  anchored at:   `macval(targetsheet)'!`macval(anchor)'"'
    }
    else {
        display as text `"  anchored at:   `macval(sheet)'!`macval(anchor)'"'
    }
    display as text   `"  new chartId:   `macval(cid)'"'
end
