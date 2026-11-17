
*! ==================================================================
*!              Make a do-file from template
*! ==================================================================
*! version 2.5, 2026-11-11
*!   - first version prepared for SSC Archive submission
*!   - rename mkdo to xmkdo
*!   - some minor editing to xmkdo.ado, xmkdo.sthlp & xmkdo.pkg
*!   - add two new contributors / authors
*!     - Yancheng Chen <25120242201569@stu.xmu.edu.cn>
*!     - Jinle    Yan  <17420242200903@stu.xmu.edu.cn>
*! ------------------------------------------------------------------
*! version 2.4, 2022-11-06, yyzeng <zzyy@xmu.edu.cn>
*!   - fix the bug with -wsok- option
*!   - some minor treaks to mkdo.ado & mkdo.sthlp
*! ------------------------------------------------------------------
*! version 2.3, 2022-05-18, yyzeng <zzyy@xmu.edu.cn>
*!   - some minor editing to mkdo.sthlp & mkdo.pkg
*! ------------------------------------------------------------------
*! version 2.2, 2021-05-19, yyzeng <zzyy@xmu.edu.cn>
*!   - add -plain- option to plainify section headings
*!   - replace ws with _ ONLY in filename (not in path)
*! ------------------------------------------------------------------
*! version 2.1, 2021-04-11, yyzeng <zzyy@xmu.edu.cn>
*!   - add -noedit- option
*!   - add "note:    " meta data field in do-file
*!   - replace -describe- with 2 -codebook-s in dm-type do-file
*! ------------------------------------------------------------------
*! version 2.0, 2021-03-15, yyzeng <zzyy@xmu.edu.cn>
*!   - refactor using several subprograms, such -mk_main-, -mk_sa-
*!   - change the default type from sa to dm
*!   - replace ws with _ and add -wsok- option to ignore it
*! ------------------------------------------------------------------
*! version 1.0, 2010-05-18, yyzeng <zzyy@xmu.edu.cn>
*! ==================================================================

program define xmkdo
    // version 14    // would affect the generated do-file templates
    local version = c(version)
    syntax using/ [, Main SA Version(real `version') Lsize(integer 80) ///
                     LOG(string) AUthor(string) TS(string) REPLACE     ///
                     WSok Plain noEDit]
    
    // version: version control, default c(version)
    // lsize:   linesize, default 80
    // log:     logfile type, default smcl, can be abbreviated to s|t
    // author:  author name, default c(username)
    // ts:      time stamp, default c(current_date)
    // replace: replace if exist
    // wsok:    just keep whitespace(s) in filename
    // plain:   plainify baroque section headings
    // noedit:  do not open do-file in do-editor
    
    // eg., 1. xmkdo using dm01_import.do, v(15) l(90) log(s) au(zen) ts(2021/03/18) replace
    //      2. xmkdo using dm02_clean.do, replace
    //      3. xmkdo using sa01_regress.do, sa replace
    //      4. xmkdo using _main_.do, main replace
    
    local using = ustrtrim(`"`using'"')
    if "`wsok'" == "" {
        local ru = reverse(`"`using'"')
        local fname = usubstr(`"`ru'"', 1, strpos(`"`ru'"', "/") - 1)
        if `"`fname'"' == "" {
            local fname = usubstr(`"`ru'"', 1, strpos(`"`ru'"', "\") - 1)
        }
        if `"`fname'"' == "" { // if there is no path in `using'
            local fname = `"`ru'"'
        }
        if ustrpos(`"`fname'"', " ") != 0 {
            di in red `"  Whitespace(s) in filename "`using'" replaced with _,"' _c
            di in red `" unless option {bf:wsok} is set."' _n
            local fn = ustrregexra(`"`fname'"', "[ ]+", "_")
            local using = reverse(usubinstr(`"`ru'"', `"`fname'"', `"`fn'"', 1))
        }
    }
    if usubstr("`using'", -3, 3) == ".do" {
        // local using = usubinstr("`using'", ".do", "", .)
        local using = usubstr("`using'", 1, ustrlen("`using'") - 3)
    }
    
    if ("`main'" != "") & ("`sa'" != "") {
        di as err "option {bf:main} and {bf:sa} shouldn't be set at the same time!"
        error 198
    }
    
    if (`version' < 9) | (`version' > c(version)) {
        di as err "option {bf:version()} must be bigger than 9.0 & smaller than Stata that you run!"
        error 198
    }
    
    if "`log'" == "" {  // default to text log
        local log = "text"
    }
    local lng = strlen("`log'")
    if !inlist("`log'", substr("text", 1, `lng'), substr("smcl", 1, `lng')) {
        di as err "The logtype option {bf:log()} must be " in w "smcl " as err "or " in w "text"
        error 198
    }
    
    if "`author'" == "" {
        local author = c(username)
    }
    
    if "`ts'" == "" {
        local ts = date(c(current_date), "DMY")
        local ts = string(`ts', "%dcy-N-D")
    }
    
    // make dofile template
    if "`main'" != "" { // main dofile template for do dofiles in sequence
        capture file close fh
        nobreak mk_main using "`using'", lsize(`lsize') ///
                        log(`log') author(`author') ts(`ts') `replace'
    }
    else if "`sa'" == "sa" { // individual dofile template for SA task
        capture file close fh
        nobreak mk_sa using "`using'", version(`version') lsize(`lsize') ///
                      log(`log') author(`author') ts(`ts') `replace'
    }
    else { // individual dofile template for DM task
        capture file close fh
        nobreak mk_dm using "`using'", version(`version') lsize(`lsize') ///
                      log(`log') author(`author') ts(`ts') `replace'
    }
    
    // simplify baroque section headings
    if ("`plain'" != "") {
        plainify `"`using'.do"'
    }
    
    // open it in Do-file Editor by default
    if ("`edit'" == "") {
        doedit `"`using'.do"'
    }
end

program define mk_main
    // make main dofile template
    syntax using/ [, Lsize(integer 80) LOG(string) ///
                     AUthor(string) TS(string) REPLACE]
    
    file open fh using `"`using'.do"', write `replace'
    
    write_head, fh(fh) using(`using') lsize(`lsize') log(`log') logname(main)
    
    write_meta, fh(fh) using(`using') author(`author') ts(`ts')
    
    file write fh "* do dofiles for data management in sequence" _n
    file write fh "* ======================================================>>>" _n
    file write fh "// do dm01_import.do" _n
    file write fh "// do dm02_clean.do" _n(2)
    
    file write fh "* do dofiles for statistical analysis in sequence" _n
    file write fh "* ======================================================>>>" _n
    file write fh "// do sa01_desc.do" _n
    file write fh "// do sa02_regress.do" _n(2)
    
    file write fh "log close main" _n
    file write fh "exit" _n
    
    file close fh
end

program define mk_sa
    // make statistical-analysis dofile template
    syntax using/ [, Version(real 15) Lsize(integer 80) LOG(string) ///
                     AUthor(string) TS(string) REPLACE]
    
    file open fh using `"`using'.do"', write `replace'
    
    write_head, fh(fh) using(`using') lsize(`lsize') log(`log')
    
    write_meta, fh(fh) using(`using') author(`author') ts(`ts')
    
    write_setup, fh(fh) version(`version')
    
    file write fh "//-----------------------------------------------------------------------/" _n
    file write fh "//  #1" _n
    file write fh "//  datasignature confirm" _n
    file write fh "//----------------------------------------/" _n
    file write fh "use <...>, clear" _n
    file write fh "datasignature confirm" _n(2)
    
    file write fh "//-----------------------------------------------------------------------/" _n
    file write fh "//  #2" _n
    file write fh "//  describe task 2" _n
    file write fh "//----------------------------------------/" _n
    file write fh "* my commands start here" _n(2)
    
    file write fh "log close" _n
    file write fh "exit" _n
    
    file close fh
end

program define mk_dm
    // make data-management dofile template
    syntax using/ [, Version(real 15) Lsize(integer 80) LOG(string) ///
                     AUthor(string) TS(string) REPLACE]
    
    file open fh using `"`using'.do"', write `replace'
    
    write_head, fh(fh) using(`using') lsize(`lsize') log(`log')
    
    write_meta, fh(fh) using(`using') author(`author') ts(`ts')
    
    write_setup, fh(fh) version(`version')
    
    file write fh "//-----------------------------------------------------------------------/" _n
    file write fh "//  #1" _n
    file write fh "//  datasignature confirm" _n
    file write fh "//----------------------------------------/" _n
    file write fh "use <...>, clear" _n
    file write fh "datasignature confirm" _n(2)
    
    file write fh "//-----------------------------------------------------------------------/" _n
    file write fh "//  #2" _n
    file write fh "//  describe task 2" _n
    file write fh "//----------------------------------------/" _n
    file write fh "* my commands start here" _n(2)
    
    file write fh "//-----------------------------------------------------------------------/" _n
    file write fh "//  #3" _n
    file write fh "//  finishing touches" _n
    file write fh "//----------------------------------------/" _n
    file write fh "quietly compress" _n
    file write fh "label data <...>" _n
    file write fh "notes _dta: <...>\ " "`using'.do \ "
    file write fh "`author' @ " "TS" _n     // real-time TS when saving
    file write fh "datasignature set, reset" _n
    file write fh "codebook, problems" _n
    file write fh "codebook, compact" _n
    if ustrpos("`using'", " ") != 0 {
        file write fh `"save "`using'.dta", replace"' _n(2)
    }
    else file write fh "save `using'.dta, replace" _n(2)
    
    file write fh "log close" _n
    file write fh "exit" _n
    
    file close fh
end

program define write_head
    
    syntax , FH(string) USING(string) Lsize(string) LOG(string) [LOGName(string)]
    
    file write fh "capture log close `logname'" _n
    
    if "`logname'" != "" {
        local logname = " name(`logname')"
    }
    local lng = strlen("`log'")
    if "`log'" == substr("text", 1, `lng') {
        if strpos("`using'", " ") != 0 {
            file write fh ///
                `"log using "`using'.txt",`logname' replace text"' _n(2)
        }
        else file write fh ///
                "log using `using'.txt,`logname' replace text" _n(2)
    }
    else {
        if strpos("`using'", " ") != 0 {
            file write fh ///
                `"log using "`using'.smcl",`logname' replace"' _n(2)
        }
        else file write fh ///
                "log using `using'.smcl,`logname' replace" _n(2)
    }
    
    file write fh "set more off" _n
    file write fh "set linesize `lsize'" _n(2)
    
end

program define write_meta
    
    syntax , FH(string) USING(string) AUthor(string) TS(string)
    
    file write fh "//  project:  " _n
    file write fh "//  task:     " _n
    file write fh "//  script:   `using'.do" _n
    file write fh "//  author:   " "`author' @ " "`ts'" _n
    file write fh "//  note:     " _n(2)
    
end

program define write_setup
    
    syntax , FH(string) Version(string)
    
    file write fh "//-----------------------------------------------------------------------/" _n
    file write fh "//  #0" _n
    file write fh "//  program setup" _n
    file write fh "//----------------------------------------/" _n
    file write fh "version `version'" _n
    file write fh "clear all" _n
    file write fh "macro drop _all" _n(2)
    
end

program define plainify
    
    syntax anything(name=filename)
    
    tempfile tfile
    copy `filename' `"`tfile'"'
    
    tempname in out
    file open `in'  using `"`tfile'"', read
    file open `out' using `filename', write replace
    
    file read `in' line
    while r(eof) == 0 {
        if `"`line'"' == "* ======================================================>>>" {
            file write `out' "* ===============================================" _n
        }
        else if `"`line'"' == "//-----------------------------------------------------------------------/" {
            file write `out'  "//======================================" _n
        }
        else if `"`line'"' == "//----------------------------------------/" {
            file write `out'  "//--------------------------------------" _n
        }
        else if strpos(`"`line'"', "//  #") == 1 {
            file read `in' line2
            local line  = subinstr(`"`line'"',  "//  #", "// #", 1)
            local line2 = subinstr(`"`line2'"', "//  ",  "", 1)
            file write `out' `"`line' `line2'"' _n
        }
        else {
            file write `out' `"`line'"' _n
        }
        
        file read `in' line
    }
    file close `in'
    file close `out'
    
end

exit
