*! rollbook  v2.0
*! Sampling students from Chinese-language Excel roll files
*!
*! Authors:
*!   (1) Wu Lianghai, School of Business, Anhui University of Technology (AHUT),
*!       Ma'anshan, China, Email: agd2010@yeah.net
*!   (2) Chen Liwen, School of Business, Anhui University of Technology (AHUT),
*!       Ma'anshan, China, Email: 2184844526@qq.com
*!   (3) Hu Fangfang, School of Finance and Economics, Wanjiang University of
*!       Technology (WJUT), Ma'anshan, China, Email: huff470@163.com
*!   (4) Jin Xuening, School of Business, Anhui University of Technology (AHUT),
*!       Ma'anshan, China, Email: 1418924481@qq.com
*!
*! v2.0  2026-09-28
*!   * reads .xls and .xlsx workbooks whose file names are Chinese, or a
*!     mixture of Chinese, letters and Arabic numerals (bare name or path)
*!   * reads worksheets whose names are Chinese or mixed
*!   * the four columns 序号, 学号, 姓名 and 专业 may be headed in English
*!     or pinyin instead (No / ID / Name / Major, ...)
*!   * n(), sheet(), even() and major() (and serial()) can be combined freely
*!   * new optional seed() for a reproducible random draw
*!
*! Save the ado-file (and any do-file that calls it) as UTF-8 so that the
*! Chinese column names 序号, 学号, 姓名, 专业 are read correctly.

capture program drop rollbook
program define rollbook
    version 15

    syntax using/, [n(integer 0) serial(string) even(string) major(string) ///
                     sheet(string) seed(integer 0)]

    if `n' < 0 {
        di as error "n() must be a nonnegative integer"
        exit 198
    }

    *---- 1. Locate a readable copy of the workbook.  The name is used as
    *        typed first; if Stata cannot open it (this happens with some
    *        non-ASCII file names), a temporary ASCII-named copy is used
    *        instead.  import excel reads .xls and .xlsx workbooks. -------
    local ascfile ""
    local f ""
    capture import excel using "`using'", describe
    if _rc == 0 {
        local f "`using'"
    }
    else {
        local dot = strrpos("`using'", ".")
        local ext ""
        if `dot' > 0 local ext = lower(substr("`using'", `dot', .))
        if "`ext'" != ".xls" & "`ext'" != ".xlsx" local ext ".xlsx"
        tempfile rollbook_tmp
        local ascfile "`rollbook_tmp'`ext'"
        capture copy "`using'" "`ascfile'", replace
        if _rc == 0 {
            capture import excel using "`ascfile'", describe
            if _rc == 0 local f "`ascfile'"
        }
    }
    if "`f'" == "" {
        if `"`ascfile'"' != "" capture erase "`ascfile'"
        di as error "cannot read Excel file `using'"
        di as error "  * the file must exist and be a valid .xls or .xlsx workbook"
        exit 601
    }

    *---- 2. Worksheet names.  sheet() may be a worksheet name (Chinese or
    *        mixed) or a worksheet number. ---------------------------------
    local nsw = r(N_worksheet)
    forvalues j = 1/`nsw' {
        local shname_`j' `"`r(worksheet_`j')'"'
    }

    local sheetopt ""
    if `"`sheet'"' != "" {
        local usedsheet ""
        forvalues j = 1/`nsw' {
            local snm "`shname_`j''"
            if `"`sheet'"' == `"`snm'"' local usedsheet "`sheet'"
        }
        if `"`usedsheet'"' == "" & !missing(real("`sheet'")) {
            local idx = real("`sheet'")
            if `idx' == int(`idx') & `idx' >= 1 & `idx' <= `nsw' {
                local usedsheet "`shname_`idx''"
            }
        }
        if `"`usedsheet'"' == "" {
            di as error "worksheet `sheet' was not found in `using'"
            di as error "  available worksheets:"
            forvalues j = 1/`nsw' {
                di as error "    `j': `shname_`j''"
            }
            if `"`ascfile'"' != "" capture erase "`ascfile'"
            exit 198
        }
        local sheetopt `"sheet("`usedsheet'")"'
    }

    *---- 3. Read the worksheet ------------------------------------------
    capture import excel using "`f'", clear firstrow `sheetopt'
    local ir = _rc
    if `"`ascfile'"' != "" capture erase "`ascfile'"
    if `ir' != 0 {
        di as error "cannot read Excel file `using'"
        exit 601
    }

    *---- 4. Find the four columns.  The exact Chinese names 序号, 学号,
    *        姓名 and 专业 are used when present; otherwise common English
    *        (or pinyin) names are recognised, ignoring case, spaces and
    *        punctuation, so "Student ID" and "student_id" are both found.
    local v_serial ""
    local v_id ""
    local v_name ""
    local v_major ""

    unab allvars : _all

    * exact Chinese names first
    foreach v of local allvars {
        if "`v'" == "序号" local v_serial "`v'"
        if "`v'" == "学号" local v_id     "`v'"
        if "`v'" == "姓名" local v_name   "`v'"
        if "`v'" == "专业" local v_major  "`v'"
    }

    * then English / pinyin aliases
    local serial_aliases "no num number serial serialno serialnum serialnumber index seq order xuhao 序号 编号 排序"
    local id_aliases     "id sid stuid studentid stuno studentno studentnumber studentcode idno idnumber xuehao 学号 学籍号 学生学号"
    local name_aliases   "name stuname studentname username fullname xingming 姓名 学生姓名 名字"
    local major_aliases  "major majorname specialty speciality department dept profession program zhuanye 专业 专业名称 系别 学院"

    foreach v of local allvars {
        local nv = lower("`v'")
        local nv : subinstr local nv "_" "", all
        local nv : subinstr local nv "-" "", all
        local nv : subinstr local nv "." "", all
        local nv : subinstr local nv " " "", all
        foreach a of local serial_aliases {
            if "`nv'" == "`a'" & "`v_serial'" == "" local v_serial "`v'"
        }
        foreach a of local id_aliases {
            if "`nv'" == "`a'" & "`v_id'" == "" local v_id "`v'"
        }
        foreach a of local name_aliases {
            if "`nv'" == "`a'" & "`v_name'" == "" local v_name "`v'"
        }
        foreach a of local major_aliases {
            if "`nv'" == "`a'" & "`v_major'" == "" local v_major "`v'"
        }
    }

    if "`v_serial'" == "" | "`v_id'" == "" | "`v_name'" == "" | "`v_major'" == "" {
        di as error "required columns were not found; Chinese or English names work:"
        di as error "   序号 | No / Serial         (serial number)"
        di as error "   学号 | ID / StudentID      (student ID)"
        di as error "   姓名 | Name               (name)"
        di as error "   专业 | Major / Specialty  (major)"
        di as error "  columns in the worksheet: `allvars'"
        exit 111
    }

    *---- 5. Keep the key columns as trimmed strings, so that numeric
    *        serial numbers / student IDs are handled as well. ------------
    foreach v in `v_serial' `v_id' `v_name' `v_major' {
        capture confirm numeric variable `v'
        if _rc == 0 {
            if "`v'" == "`v_serial'" | "`v'" == "`v_id'" {
                quietly tostring `v', replace format(%25.0f)
            }
            else {
                quietly tostring `v', replace
            }
        }
        quietly replace `v' = strtrim(`v')
    }

    di as txt "file    : `using'"
    if `"`sheet'"' != "" {
        if `"`usedsheet'"' == `"`sheet'"' {
            di as txt "sheet   : `sheet'"
        }
        else {
            di as txt "sheet   : `usedsheet'  (requested `sheet')"
        }
    }
    di as txt "records : " _N
    if "`v_serial'" != "序号" | "`v_id'" != "学号" | "`v_name'" != "姓名" | "`v_major'" != "专业" {
        di as txt "columns : 序号->`v_serial'  学号->`v_id'  姓名->`v_name'  专业->`v_major'"
    }

    *---- 6. major() filter ----------------------------------------------
    if `"`major'"' != "" {
        keep if `v_major' == strtrim("`major'")
        if _N == 0 {
            di as error "no record with 专业 (`v_major') = `major'"
            exit 198
        }
    }

    *---- 7. serial() filter; several values may be separated by spaces
    *        or by commas. -----------------------------------------------
    if `"`serial'"' != "" {
        local slist : subinstr local serial "," " ", all
        gen byte __pick = 0
        foreach s of local slist {
            quietly replace __pick = 1 if `v_serial' == strtrim("`s'")
        }
        quietly keep if __pick == 1
        drop __pick
        if _N == 0 {
            di as error "no record with 序号 (`v_serial') equal to `serial'"
            exit 198
        }
    }

    *---- 8. even() filter: parity of the last digit of 学号.  Accepts
    *        odd / even (also 奇数 / 偶数). -------------------------------
    if `"`even'"' != "" {
        local par = lower(strtrim("`even'"))
        if "`par'" == "奇"   local par "odd"
        if "`par'" == "奇数" local par "odd"
        if "`par'" == "偶"   local par "even"
        if "`par'" == "偶数" local par "even"
        if !inlist("`par'", "odd", "even") {
            di as error "even() must be odd or even"
            exit 198
        }
        quietly gen str1 __last = substr(`v_id', -1, 1)
        quietly gen double __d = real(__last)
        quietly gen byte __isdig = !missing(__d)
        if "`par'" == "even" {
            quietly keep if __isdig == 1 & mod(__d, 2) == 0
        }
        else {
            quietly keep if __isdig == 1 & mod(__d, 2) == 1
        }
        drop __last __d __isdig
        if _N == 0 {
            di as error "no 学号 (`v_id') ends in a `par' digit"
            exit 198
        }
    }

    *---- 9. n(): draw at random from whatever observations are left. ----
    if `n' > 0 {
        if `n' < _N {
            if `seed' > 0 {
                set seed `seed'
            }
            else {
                local now = clock("`c(current_time)'", "hms")
                set seed `=1 + mod(`now' + floor(runiform() * 1000000), 2000000000)'
            }
            quietly gen double __u = runiform()
            quietly sort __u
            quietly keep in 1/`n'
            drop __u
        }
        else {
            di as txt "n(`n') >= number of candidates (" _N "); all are listed"
        }
    }

    *---- 10. Show the roll call. ----------------------------------------
    local what ""
    if `"`major'"'  != "" local what "`what' major=`major';"
    if `"`serial'"' != "" local what "`what' serial=`serial';"
    if `"`even'"'   != "" local what "`what' even=`even';"
    if `n' > 0             local what "`what' n=`n';"
    if "`what'" == ""      local what " all students"

    di _n
    di as txt "================================================================"
    di as txt "rollbook:" as res "`what'"
    di as txt "================================================================"
    forvalues i = 1/`=_N' {
        di as txt "序号 " as res `v_serial'[`i'] as txt "   学号 " as res `v_id'[`i'] ///
           as txt "   姓名 " as res `v_name'[`i'] as txt "   专业 " as res `v_major'[`i']
    }
    di as txt "================================================================"
    di as txt "total: " _N " student(s); the sample is left in memory"
end
