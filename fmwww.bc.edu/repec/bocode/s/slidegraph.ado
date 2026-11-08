*! version 1.3.0  06nov2026
*! slidegraph: Automated stepped/layered graph generation for presentations
*! Author: Aaron Wolf (aaron.wolf@u.northwestern.edu)
*! Project: https://github.com/aarondwolf/slidegraph
*! Issues: https://github.com/aarondwolf/slidegraph/issues
*! Program architecture: slidegraph set, slidegraph, & slidegraph export

/*==============================================================================
  Main Dispatcher: slidegraph
  Routes subcommands (set, export/tex/beamer, clear/reset, query/list/describe)
  or executes the multi-frame graph build sequence (slidegraph_run).
==============================================================================*/
program define slidegraph, rclass
    version 15.0

    // Display active configuration or usage summary when called without arguments
    if `"`0'"' == "" {
        if `"$SG_N"' != "" {
            slidegraph_query
            exit 0
        }
        else {
            di as text "slidegraph: Automated stepped/layered graph builds for slide presentations"
            di as text "Usage:"
            di as text "  {bf:slidegraph set}, patterns(color1 pat1 ...) [off(0)] [dim(20)]"
            di as text "  {bf:slidegraph set}, colors(color1 color2 ...) {bf:cumulative}|{bf:spotlight} [off(0)] [dim(20)]"
            di as text "  {bf:slidegraph} [, stub(string) saving(string) full] : {it:graph_cmd}"
            di as text "  {bf:slidegraph export} [using file.tex] [, path(string) saving(string) options(string) replace]"
            exit 0
        }
    }

    // Inspect first token to dispatch subcommands
    gettoken subcmd : 0, parse(" ,:")

    if "`subcmd'" == "set" {
        gettoken subcmd rest : 0, parse(" ,:")
        slidegraph_set `rest'
        return add
        exit 0
    }
    else if inlist("`subcmd'", "export", "tex", "beamer") {
        gettoken subcmd rest : 0, parse(" ,:")
        slidegraph_export `rest'
        return add
        exit 0
    }
    else if inlist("`subcmd'", "clear", "reset") {
        slidegraph_clear
        exit 0
    }
    else if inlist("`subcmd'", "query", "list", "describe") {
        slidegraph_query
        exit 0
    }
    else {
        slidegraph_run `0'
        return add
        exit 0
    }
end

/*==============================================================================
  Subcommand: slidegraph set
  Validates and stores color-pattern pairs, shorthand presets (cumulative or
  spotlight), and opacity modifiers (off and dim) in global macros SG_*.
==============================================================================*/
program define slidegraph_set, rclass
    version 15.0
    syntax [, patterns(string asis) colors(string asis) CUMulative SPOTlight off(integer 0) dim(integer 20)]

    // Ensure mutually exclusive and complete specification of patterns() vs. colors()
    if `"`patterns'"' != "" & `"`colors'"' != "" {
        di as error "cannot specify both patterns() and colors()"
        exit 198
    }
    if `"`patterns'"' == "" & `"`colors'"' == "" {
        di as error "must specify either patterns() or colors()"
        exit 198
    }

    // Expand preset patterns if colors() was provided
    if `"`colors'"' != "" {
        if "`cumulative'" == "" & "`spotlight'" == "" {
            di as error "must specify either cumulative or spotlight with colors()"
            exit 198
        }
        if "`cumulative'" != "" & "`spotlight'" != "" {
            di as error "cannot specify both cumulative and spotlight"
            exit 198
        }
        local preset = cond("`cumulative'" != "", "cumulative", "spotlight")
        mata: _sg_build_preset_patterns(st_local("colors"), st_local("preset"), "patterns")
    }

    // Validate opacity percentages are integers in [0, 100]
    if !inrange(`off', 0, 100) {
        di as error "off() must be an integer between 0 and 100"
        exit 198
    }
    if !inrange(`dim', 0, 100) {
        di as error "dim() must be an integer between 0 and 100"
        exit 198
    }

    local off_mod "%`off'"
    local dim_mod "%`dim'"

    // Verify non-empty pattern token list
    local ntokens : word count `patterns'
    if `ntokens' == 0 {
        di as error "option patterns() or colors() required"
        exit 198
    }

    // Check color slots (odd token indices) for unquoted RGB numbers (e.g. 255 0 0 11)
    forvalues idx = 1(2)`ntokens' {
        local tok : word `idx' of `patterns'
        if real("`tok'") != . {
            di as error `"unquoted RGB color value '`tok'' detected in patterns(); RGB colors must be enclosed in quotes, e.g. patterns("255 0 0" <pattern> ...)"'
            exit 198
        }
    }

    // Enforce even number of tokens (<color_token> <pattern> pairs)
    if mod(`ntokens', 2) != 0 {
        di as error "patterns() must contain an even number of tokens: <color_token> <pattern> pairs"
        exit 198
    }

    local npairs  = `ntokens' / 2
    local N       = 0
    local any_rgb = 0
    local has_2   = 0

    // Validate each <color_token> <pattern> pair before modifying global state
    forvalues p = 1/`npairs' {
        local c_idx   = 2 * `p' - 1
        local pat_idx = 2 * `p'
        local col_`p' : word `c_idx' of `patterns'
        local pat_`p' : word `pat_idx' of `patterns'

        local plen = length("`pat_`p''")
        if `plen' == 0 {
            di as error "pattern for color '`col_`p''' cannot be empty"
            exit 198
        }
        if `p' == 1 {
            local N = `plen'
        }
        else if `plen' != `N' {
            di as error "all patterns must have the exact same length (`N'); pattern for '`col_`p''' has length `plen'"
            exit 198
        }

        // Validate that pattern consists strictly of 0 (off), 1 (dim/on), or 2 (focus)
        forvalues k = 1/`plen' {
            local ch = substr("`pat_`p''", `k', 1)
            if !inlist("`ch'", "0", "1", "2") {
                di as error "invalid character '`ch'' in pattern '`pat_`p''' for color '`col_`p'''; patterns must contain only 0, 1, and 2"
                exit 198
            }
            if "`ch'" == "2" {
                local has_2 = 1
            }
        }

        // Detect custom RGB triples ("R G B") and warn about spacing sensitivity
        mata: st_local("rgb_`p'", strofreal(_sg_is_rgb(st_local("col_`p'"), .)))
        if `rgb_`p'' {
            local any_rgb = 1
            di as text "{p 0 4 2}{bf:warning:} RGB color detected (`col_`p''); using RGB opacity modifiers in Stata requires placing the modifier inside quotes (e.g., " as result `""`col_`p'' `off_mod'""' as text "), which can be sensitive to formatting and spacing. Named color styles are recommended, but proceeding anyway.{p_end}"
        }
    }

    // Clear any prior configuration globals to prevent stale state
    macro drop SG_*

    // Persist validated configuration in global macros
    forvalues p = 1/`npairs' {
        global SG_color_`p'  `"`col_`p''"'
        global SG_pat_`p'    `"`pat_`p''"'
        global SG_is_rgb_`p' `rgb_`p''
    }
    global SG_patterns `"`patterns'"'
    global SG_N        `N'
    global SG_off      `"`off_mod'"'
    global SG_dim      `"`dim_mod'"'
    global SG_has_2    `has_2'
    global SG_npairs   `npairs'
    global SG_any_rgb  `any_rgb'

    // Populate r() return values
    return scalar N       = `N'
    return scalar npairs  = `npairs'
    return scalar any_rgb = `any_rgb'
    return scalar off_val = `off'
    return scalar dim_val = `dim'
    return scalar has_2   = `has_2'
    return local patterns `"`patterns'"'
    return local off      `"`off_mod'"'
    return local dim      `"`dim_mod'"'

    if `has_2' {
        di as text "slidegraph configuration set: `npairs' pattern(s) across `N' frame(s), dim: " as result "`dim_mod'" as text ", off: " as result "`off_mod'"
    }
    else {
        di as text "slidegraph configuration set: `npairs' pattern(s) across `N' frame(s), off modifier: " as result "`off_mod'"
    }
end

/*==============================================================================
  Subcommand: slidegraph_run
  Executes the stored multi-frame graph sequence, applying opacity modifiers
  per frame, injecting distinct memory names, and optionally saving/exporting
  each frame (plus an optional unsuffixed full figure).
==============================================================================*/
program define slidegraph_run, rclass
    version 15.0

    // Require an active configuration
    if `"$SG_N"' == "" | `"$SG_patterns"' == "" {
        di as error "no slidegraph configuration found; run {bf:slidegraph set} first"
        exit 198
    }

    // Parse colon syntax separating slidegraph options from the graph command
    cap _on_colon_parse `0'
    if _rc {
        di as error "syntax error: colon ':' required after slidegraph options"
        exit 198
    }

    local before `"`s(before)'"'
    local cmd    `"`s(after)'"'

    if strtrim(`"`cmd'"') == "" {
        di as error "graph command required after colon ':'"
        exit 198
    }

    // Parse slidegraph-specific options before the colon
    local 0 `"`before'"'
    syntax [, stub(string) saving(string) full]

    if `"`stub'"' == "" {
        local stub "sg"
    }

    // Warn (without exiting) if name() appears in the user's graph command
    if ustrregexm(`"`cmd'"', "\bname\s*\(") {
        di as text "{p 0 4 2}{bf:warning:} 'name()' option detected in graph command; specifying both stub() in slidegraph and name() in the graph command may cause issues{p_end}"
    }

    // Parse saving() into file stem, lowercase extension, and action type (save vs. export)
    local save_stem ""
    local save_ext  ""
    local save_type ""
    if `"`saving'"' != "" {
        mata: _slidegraph_parse_save(st_local("saving"), "save_stem", "save_ext", "save_type")
    }

    local N      = $SG_N
    local npairs = $SG_npairs
    local off    `"$SG_off"'
    local dim    `"$SG_dim"'

    // Render each frame i = 1, ..., N
    forvalues i = 1/`N' {
        local cur_cmd `"`cmd'"'

        // Substitute opacity modifiers for inactive (0) or dimmed (1 in 3-state mode) series
        forvalues p = 1/`npairs' {
            local color `"${SG_color_`p'}"'
            local pat   `"${SG_pat_`p'}"'
            local bit   = substr("`pat'", `i', 1)

            if "`bit'" == "0" {
                mata: _sg_replace_color(st_local("cur_cmd"), st_local("color"), st_local("off"), "cur_cmd")
            }
            else if "`bit'" == "1" & "$SG_has_2" == "1" {
                mata: _sg_replace_color(st_local("cur_cmd"), st_local("color"), st_local("dim"), "cur_cmd")
            }
        }

        _slidegraph_exec_frame `"`cur_cmd'"' "frame `i'/`N'" "`stub'_`i'" "`save_type'" `"`save_stem'_`i'`save_ext'"'
        local cmd_`i' `"`s(exec_cmd)'"'
    }

    // Optionally render unsuffixed full figure (all series at 100% opacity)
    if "`full'" != "" {
        _slidegraph_exec_frame `"`cmd'"' "full frame" "`stub'" "`save_type'" `"`save_stem'`save_ext'"'
        local cmd_full `"`s(exec_cmd)'"'
    }

    // Store run metadata for subsequent slidegraph export or query calls
    global SG_has_full  = ("`full'" != "")
    global SG_saving    `"`saving'"'
    global SG_save_stem `"`save_stem'"'
    global SG_save_ext  `"`save_ext'"'
    global SG_save_type `"`save_type'"'
    global SG_last_stub `"`stub'"'

    return scalar N   = `N'
    return local stub "`stub'"
    return local off  `"$SG_off"'
    return local dim  `"$SG_dim"'
    forvalues i = 1/`N' {
        return local cmd_`i' `"`cmd_`i''"'
    }
    if `"`saving'"' != "" {
        return local saving    `"`saving'"'
        return local save_stem `"`save_stem'"'
        return local save_ext  `"`save_ext'"'
    }
    if "`full'" != "" {
        return local full "1"
        return local cmd_full `"`cmd_full'"'
    }
end

// Internal helper: inject name(..., replace), execute graph command, and save/export
program define _slidegraph_exec_frame, sclass
    version 15.0
    args cmd label graphname save_type save_file

    local name_opt `"name(`graphname', replace)"'
    mata: _slidegraph_inject_name(st_local("cmd"), st_local("name_opt"), "exec_cmd")

    di as text _col(2) "{hline 64}"
    di as text "slidegraph `label' ({bf:`graphname'}):"
    di as result `"  `exec_cmd'"'
    `exec_cmd'

    if "`save_type'" == "save" {
        graph save `graphname' `"`save_file'"', replace
        di as text `"  Saved graph: `save_file'"'
    }
    else if "`save_type'" == "export" {
        graph export `"`save_file'"', name(`graphname') replace
        di as text `"  Exported image: `save_file'"'
    }

    sreturn local exec_cmd `"`exec_cmd'"'
end

/*==============================================================================
  Subcommand: slidegraph export
  Writes a ready-to-\input LaTeX Beamer overlay file (\only<i...>{...}) for the
  active slide sequence, optionally remapping image directory paths via path().
==============================================================================*/
program define slidegraph_export, rclass
    version 15.0
    syntax [using/] [, path(string) saving(string) options(string) replace]

    if `"$SG_N"' == "" {
        di as error "no slidegraph configuration found; run {bf:slidegraph set} and {bf:slidegraph} first"
        exit 198
    }

    // Fall back to saving() from the previous slidegraph run if not explicitly supplied
    if `"`saving'"' == "" {
        local saving `"$SG_saving"'
    }
    if `"`saving'"' == "" {
        di as error "no saving() filename found; specify saving() in slidegraph export or run slidegraph with saving() first"
        exit 198
    }

    local save_stem ""
    local save_ext  ""
    local save_type ""
    mata: _slidegraph_parse_save(st_local("saving"), "save_stem", "save_ext", "save_type")

    if "`save_ext'" == ".gph" {
        di as text "{p 0 4 2}{bf:note:} saving() has .gph extension; LaTeX typically expects image formats like .pdf, .png, etc.{p_end}"
    }

    local N = $SG_N
    local target_tex ""

    // Format LaTeX image paths and resolve target .tex filename in Mata
    mata: _slidegraph_format_tex_paths(st_local("save_stem"), st_local("save_ext"), st_local("path"), st_local("using"), `N', "tex_img", "target_tex")

    // Guard against overwriting an existing .tex file unless replace is specified
    if "`replace'" == "" {
        capture confirm file `"`target_tex'"'
        if _rc == 0 {
            di as error `"file '`target_tex'' already exists; specify replace option to overwrite"'
            exit 602
        }
    }

    if `"`options'"' == "" {
        local options "width=\linewidth"
    }

    // Write LaTeX Beamer overlay file
    tempname fh
    file open `fh' using `"`target_tex'"', write text replace
    file write `fh' `"% LaTeX Beamer overlay sequence generated by slidegraph"' _n
    forvalues i = 1/`N' {
        file write `fh' `"\only<`i'>{\includegraphics[`options']{`tex_img_`i''}}%"' _n
    }
    if "$SG_has_full" == "1" {
        file write `fh' `"% Standalone full figure (no overlays):"' _n
        file write `fh' `"% \includegraphics[`options']{`tex_img_full'}"' _n
    }
    file close `fh'

    // Display generated code in Results window
    di as text _newline _col(2) "{hline 64}"
    di as text "LaTeX Beamer overlay code generated:"
    forvalues i = 1/`N' {
        di as result `"  \only<`i'>{\includegraphics[`options']{`tex_img_`i''}}%"'
    }
    if "$SG_has_full" == "1" {
        di as text "  % Standalone full figure:"
        di as text `"  % \includegraphics[`options']{`tex_img_full'}"'
    }
    di as text _col(2) "{hline 64}"
    di as text `"Overlay file written to: {bf:`target_tex'}"'
    di as text "In your LaTeX presentation, insert:"
    di as result `"  \input{`target_tex'}"'

    return local file    `"`target_tex'"'
    return local options `"`options'"'
    return local path    `"`path'"'
    return scalar N      = `N'
end

/*==============================================================================
  Subcommands: slidegraph clear & slidegraph query
==============================================================================*/
program define slidegraph_clear
    version 15.0
    macro drop SG_*
    di as text "slidegraph configuration cleared"
end

program define slidegraph_query
    version 15.0
    if `"$SG_N"' == "" {
        di as text "No slidegraph configuration is currently active."
        di as text "Use {bf:slidegraph set, patterns(...)} or {bf:slidegraph set, colors(...) cumulative} to set up a configuration."
    }
    else {
        di as text "Active slidegraph configuration:"
        di as text "  Frames (N)   : " as result "$SG_N"
        di as text "  Patterns     : " as result `"$SG_patterns"'
        if "$SG_has_2" == "1" {
            di as text "  Dim modifier : " as result `"$SG_dim"'
        }
        di as text "  Off modifier : " as result `"$SG_off"'
        if "$SG_any_rgb" == "1" {
            di as text "  RGB detected : " as result "yes (inside-quote modifier applied)"
        }
        if `"$SG_saving"' != "" {
            di as text "  Last saving  : " as result `"$SG_saving"'
        }
    }
end

/*==============================================================================
  Mata String & Path Processing Helpers
==============================================================================*/
mata:
mata set matastrict on

// Return 1 if color is a valid RGB triple ("R G B" with R,G,B in [0,255]), storing values in rgb_vals
real scalar _sg_is_rgb(string scalar color, real vector rgb_vals)
{
    string scalar clean
    real scalar r, g, b

    clean = strtrim(subinstr(color, char(34), ""))
    if (ustrregexm(clean, "^\s*([0-9]{1,3})\s+([0-9]{1,3})\s+([0-9]{1,3})\s*$")) {
        r = strtoreal(ustrregexs(1))
        g = strtoreal(ustrregexs(2))
        b = strtoreal(ustrregexs(3))
        if (r >= 0 & r <= 255 & g >= 0 & g <= 255 & b >= 0 & b <= 255) {
            rgb_vals = (r, g, b)
            return(1)
        }
    }
    return(0)
}

// Apply opacity modifier mod_str (e.g. "%0" or "%20") to all occurrences of color in cmd_in:
// - RGB colors: places modifier inside quotes ("R G B" -> "R G B %0")
// - Named styles: appends modifier to exact color token (e.g. navy -> navy%0, navy*1 -> navy*1%0),
//   treating navy, navy*1, and navy*1.0 as distinct tokens so visually identical aliases work
void _sg_replace_color(string scalar cmd_in, string scalar color, string scalar mod_str, string scalar s_out)
{
    real vector rgb
    string scalar r_str, g_str, b_str, escaped, pat, rep, q

    rgb = J(1, 0, .)
    q = char(34)
    if (_sg_is_rgb(color, rgb)) {
        r_str = strofreal(rgb[1])
        g_str = strofreal(rgb[2])
        b_str = strofreal(rgb[3])
        pat = q + "(\s*" + r_str + "\s+" + g_str + "\s+" + b_str + "(?:\*[0-9.]+)?\s*)" + q
        rep = q + "$1 " + mod_str + q
        st_local(s_out, ustrregexra(cmd_in, pat, rep))
    }
    else {
        escaped = subinstr(subinstr(color, ".", "\."), "*", "\*")
        pat = "\b(" + escaped + ")\b(?!\*|\.[0-9]|%)"
        rep = "$1" + mod_str
        st_local(s_out, ustrregexra(cmd_in, pat, rep))
    }
}

// Append name(..., replace) to graph command, adding a top-level comma only if none exists
// Respects both parenthesis nesting and double-quoted string literals
void _slidegraph_inject_name(string scalar raw, string scalar name_opt, string scalar s_out)
{
    real scalar i, n, depth, in_quotes, has_comma
    string scalar ch, trimmed, q

    trimmed   = strtrim(raw)
    n         = strlen(trimmed)
    q         = char(34)
    depth     = 0
    in_quotes = 0
    has_comma = 0

    for (i = 1; i <= n; i++) {
        ch = bsubstr(trimmed, i, 1)
        if (ch == q) {
            in_quotes = !in_quotes
        }
        else if (!in_quotes) {
            if (ch == "(")      depth++
            else if (ch == ")") depth--
            else if (ch == "," & depth == 0) {
                has_comma = 1
                break
            }
        }
    }

    st_local(s_out, trimmed + (has_comma ? " " : ", ") + name_opt)
}

// Parse saving() filename into stem, lowercase extension, and operation type ("save" or "export")
void _slidegraph_parse_save(string scalar arg, string scalar s_stem, string scalar s_ext, string scalar s_type)
{
    string scalar clean, stem, ext, type

    clean = strtrim(subinstr(arg, char(34), ""))
    if (strpos(clean, ",")) {
        clean = strtrim(bsubstr(clean, 1, strpos(clean, ",") - 1))
    }
    ext  = pathsuffix(clean)
    stem = pathrmsuffix(clean)

    if (ext == "" | strlower(ext) == ".gph") {
        if (ext == "") ext = ".gph"
        type = "save"
    }
    else {
        type = "export"
    }

    st_local(s_stem, stem)
    st_local(s_ext, strlower(ext))
    st_local(s_type, type)
}

// Generate pattern string from colors() list and preset ("cumulative" or "spotlight")
void _sg_build_preset_patterns(string scalar colors_str, string scalar preset, string scalar s_out)
{
    string rowvector cols
    real scalar k, K, f
    string scalar pat, out_str, q

    cols = tokens(colors_str)
    K    = length(cols)
    if (K == 0) {
        errprintf("option colors() cannot be empty\n")
        exit(198)
    }

    q       = char(34)
    out_str = ""
    for (k = 1; k <= K; k++) {
        if (strtoreal(cols[k]) != .) {
            errprintf("unquoted RGB color value '%s' detected in colors(); RGB colors must be enclosed in quotes, e.g. colors(%s255 0 0%s ...)\n", cols[k], q, q)
            exit(198)
        }

        pat = ""
        for (f = 1; f <= K; f++) {
            if (preset == "cumulative") {
                pat = pat + (f < k ? "0" : "2")
            }
            else {
                pat = pat + (f < k ? "0" : (f == k ? "2" : "1"))
            }
        }

        if (strpos(cols[k], " ")) {
            out_str = out_str + (k > 1 ? " " : "") + q + cols[k] + q + " " + pat
        }
        else {
            out_str = out_str + (k > 1 ? " " : "") + cols[k] + " " + pat
        }
    }
    st_local(s_out, out_str)
}

// Format LaTeX image paths and resolve target .tex filename for slidegraph export
void _slidegraph_format_tex_paths(
    string scalar save_stem,
    string scalar save_ext,
    string scalar path_in,
    string scalar using_in,
    real scalar N,
    string scalar s_macro_prefix,
    string scalar s_target_tex)
{
    string scalar bare_name, clean_path, img_base, fwd_stem, dummy_p, target_tex
    real scalar i

    dummy_p    = ""
    bare_name  = ""
    fwd_stem   = subinstr(save_stem, "\", "/")
    clean_path = strtrim(subinstr(path_in, char(34), ""))

    if (clean_path != "") {
        clean_path = subinstr(clean_path, "\", "/")
        if (bsubstr(clean_path, strlen(clean_path), 1) != "/") {
            clean_path = clean_path + "/"
        }
        pathsplit(fwd_stem, dummy_p, bare_name)
        img_base = clean_path + bare_name
    }
    else {
        img_base = fwd_stem
    }

    for (i = 1; i <= N; i++) {
        st_local(s_macro_prefix + "_" + strofreal(i), img_base + "_" + strofreal(i) + save_ext)
    }
    st_local(s_macro_prefix + "_full", img_base + save_ext)

    if (strtrim(using_in) != "") {
        target_tex = strtrim(using_in)
        if (pathsuffix(target_tex) == "") {
            target_tex = target_tex + ".tex"
        }
    }
    else {
        target_tex = save_stem + ".tex"
    }
    st_local(s_target_tex, target_tex)
}
end
