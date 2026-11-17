
*! =======================================================================
*!    Tools to make, manage and build project in Stata
*! =======================================================================
*! version 0.4, 2026-11-11
*!   - first version prepared for SSC Archive submission
*!   - some minor tweaks to xproj.ado, xproj.sthlp & xproj.pkg
*!   - add two new contributors / authors
*!     - Yancheng Chen <25120242201569@stu.xmu.edu.cn>
*!     - Shangqi  Jin  <37620242205372@stu.xmu.edu.cn>
*! -----------------------------------------------------------------------
*! version 0.3, 2022-11-05, Yongyi Zeng <zzyy@xmu.edu.cn>
*!   - some minor tweaks to xproj.sthlp
*! -----------------------------------------------------------------------
*! version 0.2, 2022-05-18, Yongyi Zeng <zzyy@xmu.edu.cn>
*!   - fix the bug when creating XPROJ_LOOKUP_TABLE.txt 
*!         in the non-existent directory `c(sysdir_personal)'
*!   - some minor editing to xproj.sthlp & xproj.pkg
*! -----------------------------------------------------------------------
*! version 0.1, 2021-05-01, Yongyi Zeng <zzyy@xmu.edu.cn>
*!   - enhance mkproj v2.0
*!     - with subcommands make, add, list, goto & drop
*!     - with ideas from -fastcd-, -fileutils- & -workingdir-
*!   - TODO: add functions from -project-
*! =======================================================================

program define xproj
    version 14
    
    capture which xdtree
    if _rc {
        di as error "xproj requires xdtree. Install it from SSC:"
        di as error "    {stata ssc install xdtree}"
        exit 111
    }
    
    local subcmds make mk add goto go list ls drop // zip
    
    _parse comma lhs rhs: 0
    gettoken subcmd lhs: lhs
    
    if `"`subcmd'"' == "" {
        local subcmd "list"
    }
    
    local oksub 0
    foreach ok of local subcmds {
        if `"`ok'"' == "`subcmd'" {
            local oksub 1
            continue, break
        }
    }
    if !`oksub' { // assume that proj nickname is being used
        di as error _n "You have specified subcommand: {cmd:`subcmd'}, but " _c
        di as error    "xproj only support subcommands: {cmd:make}, " _c
        di as error    "{cmd:add}, {cmd:drop}, and {cmd:goto}."
        exit 199
    }
    
    xproj_`subcmd' `lhs' `rhs'
    
end

program define xproj_mk
    xproj_make `0'
end

program define xproj_make
    syntax name(name=pname id="project_name")  /// 
           [, INdir(string) Dirs(string) Note(string) noTree noREADME noCD noADD]
	
    // pname:      see [U] 11.3 Naming conventions
    // indir:      create pname in dir -indir-, default c(pwd)
    // dirs:       project's sub-dirs, default to docs, data/source, results, logs
    // note:       a short description of the project
    // notree:     not print dir tree (via user-contributed -xdtree-)
    // noreadme:   not create readme.md file under project's root dir
    // nocd:       not change directory to project's root dir
    // noadd:      not be added to projects' lookup table
    
    // eg., 1. mkproj foo
    //      2. mkproj foo, in(d:/yzworks)
    //      3. mkproj foo, dir(data dos outs docs) notree noreadme nocd
    //      4. mkproj foo, dir(+docs/readings -results +tbls +figs)
    
    local pwd = c(pwd)
    if ustrregexm(`"`pwd'"', "^[a-zA-Z]:$") {  // drive root
        local pwd `pwd'/
    }
    
    if `"`indir'"' == "" local indir = c(pwd)
    else local indir = ustrtrim(`"`indir'"')
    if ustrregexm(`"`indir'"', "^[a-zA-Z]:$") {  // drive root
        local indir `indir'/
    }
    if "`c(os)'"=="Windows" { // need to change /'s to \'s
        local indir : subinstr local indir "/" "\", all
    }
    // macro dir
    
    capture cd `"`indir'"'
    if _rc {
        di _n as err `"`indir' not exist."'
        exit 170
    }
    if `"`: dir . dirs "`pname'"'"' != "" {
        di _n as err "Directory " as text `"`pname' "' _c
        di as err "already exists in " as text `"`indir'"' as err ";"
        di as err "You should open " as text `"{browse `"`indir'"'}"' _c
        di as err " and remove / delete directory " `"`pname'"' " manually." _n
        quietly cd `"`pwd'"'  // back to WD
        exit 693
    }
    
    mkdir "`pname'"
    qui cd "`pname'"
    capture noisily mata mkdirtree(`"`dirs'"')
    local rc = _rc
    if `rc' {
        di _n as err "mata:mkdirtree() runs into error"
        di as err "You should open " as text `"{browse `"`indir'"'}"' _c
        di as err " and delect directory " `"`pname'"' " manually." _n
        quietly cd `"`pwd'"'  // back to WD
        exit `rc'
    }
    
    local note2 `"`note'"'
    if `"`note'"' == "" {
        local note2 "<A short description of the project>"
    }
    
    if "`readme'" == "" {
        write_readme using README.md, project(`pname') note(`note2') dirs(`alldirs') replace
    }
    
    if "`tree'" == "" {
        di as res _n "The created project `pname' is in " `"{browse `"`c(pwd)'"'}."'
        quietly cd ..
        di as res _n "The project's directory structure: "
        xdtree "`pname'", noclick
        quietly cd "`pname'"
    }
    
    if "`cd'" != "" { // nocd
        di as res _n "You are NOT in the project `pname''s root " _c
        di as res    "because you set option -nocd-." _n
    }
    else {
        di as res _n "You are now in the project `pname''s root." _n
    }
    	
    di as res "Hereafter you can take steps to:" _n
    
    if "`cd'" != "" { // nocd
        di as res `"    * {stata `"cd `"`c(pwd)'"'"':Change working directory to `pname'};"' _n
    }
    
    di as res "    * Copy your data into appropriate directory;" _n
    
    if "`readme'" == "" & "`cd'" == "" {
        di as res "    * Click >>> {stata doedit README.md:HERE} <<< to edit the README.md file;" _n
    }
    if "`readme'" == "" & "`cd'" != "" {
        di as res "    * doedit README.md file;" _n
    }
    
    di as res "    * Use {stata help mkdo:mkdo} command to create various do-files as you need;" _n
    
    di as res "    * and go forward ..." _n
    
    if "`add'" == "" {
        xproj_add `pname' using `"`c(pwd)'"', note(`note') nolist
    }
    
    if "`cd'" != "" {  // nocd
        qui cd `"`pwd'"'
    }
    
end

program define write_readme
    // make readme.md
    syntax using/ [, PROJect(string) Note(string) DIRs(string) REPLACE]
    
    local ts = date(c(current_date), "DMY")
    local ts = string(`ts', "%dcy-N-D")
    
    quietly file open fh using `"`using'"', write `replace'
    
    file write fh "**[`project']**" _n
    file write fh "`project': `note'" _n
    file write fh "======================================================" _n(2)
    
    file write fh "## Date: `ts'" _n(2)
    
    file write fh "## Author(s)" _n(2)
    
    file write fh "   - San Zhan, Xiamen Univ., xxx@xmu.edu.cn" _n
    file write fh "   - Si Li, Peking Univ., yyy@pku.edu.cn" _n(3)
    
    file write fh "## Description" _n(2)
    file write fh "<Project Description ...>" _n(3)
    
    
    file write fh "## Directory structure" _n(2)
    
    while `"`dirs'"' != "" {
        gettoken dir dirs: dirs, parse(";")
        if `"`dir'"' != ";" {
            file write fh "   - `dir': for ..." _n(2)
        }
    }
    
    file write fh _n
    file write fh "## Data" _n(2)
    
    file write fh "1. data/source/idxrets.xlsx" _n
    file write fh "   - source: " _n
    file write fh "   - desc  : " _n(2)
    
    file write fh "2. data/source/stkrets.csv" _n
    file write fh "   - source: " _n
    file write fh "   - desc  : " _n(3)
    
    file write fh "## Memos" _n(2)
    
    file write fh "1. " _n(2)
    
    file write fh "2. " _n(2)
    
    file write fh "3. " _n(2)
    
    file close fh
end

program define xproj_add
    
    syntax name(name=pname id="project_name") [ using/ ][, Note(string) noList ]
    
    if `"`using'"' == "" {
        local using `"`c(pwd)'"'
    }
    
    mata: proj_add("`pname'", `"`using'"', `"`note'"')
    
    if "`list'" == "" {
        xproj_list `pname'
    }
    
end

program define xproj_ls
    xproj_list `0'
end

program define xproj_list
    // list project (specified)
    syntax [anything(name=pspec id="project_name(s)")]
    
    if `"`pspec'"' == "" {
        local pspec "*"
    }
    mata: list_lookup_table(`"`pspec'"')
    
end

program define xproj_go
    xproj_goto `0'
end

program define xproj_goto
    
    syntax name(name=pname id="project_name")
    
    capture mata: proj_goto("`pname'")
    local goto_rc = _rc
    if !`goto_rc' {
        di as text "Working directory has been changed to `proj_path' " _c
        di as text "(i.e., project `pname''s root directory)."
    }
    else if `goto_rc' == 111 {
        di as err "Project `pname' not found - Check it!"
        exit `goto_rc'
    }
    else {
        di as err "Can't change working directory to `proj_path' - Check it!"
        exit `goto_rc'
    }
    
end

program define xproj_drop
    
    syntax name(name=pname id="project_name")
    
    mata: proj_drop("`pname'")
    
    if r(DONE) {
        di as text _n `"`pname' have been dropped from projects' lookup table."'
        mata: list_lookup_table("*")
    }
    else {
        di as err _n `"`pname' can't been found in projects' lookup table."'
    }
    
end

// program define xproj_zip
//    
//     syntax name(name=pname id="project_name")
//    
//     mata: proj_zip_path("`pname'")
//    
//     local pwd0 `"`c(pwd)'"'
//     quietly cd `"`proj_path'"'
//     capture erase `"`proj_path'/`pname'.zip"'  // if exists
//     quietly cd ..
//     quietly zipfile `pname', saving(`pname', replace)
//     * -zipfile- will ONLY add not-empty directories to the .zip file!
//     quietly copy `pname'.zip `"`proj_path'/`pname'.zip"', replace
//     capture erase `pname'.zip
//     display `"The project {it:`pname'} has been zipped as {it:`pname'.zip}."'
//     quietly cd `"`pwd0'"'
//    
// end


version 14

local _saved_matastrict = c(matastrict)
set matastrict on

mata:

void mkdirtree(string scalar dirs) {
    // make dirs acording to xproj_make's option dirs() 
    string vector dirsV, dirV, dropV, pathV
    string scalar path, dir
    real   scalar i, j, k, drop
    
    dirs = usubinstr(dirs, ";", " ", .)      // change separator ";" to " "
    dirs = ustrregexra(dirs, "\+[ ]+", "+")  // trim ws after +
    dirs = ustrregexra(dirs, "-[ ]+", "-")   // trim ws after -
    if(dirs == "") { // default
        dirsV = tokens("docs data/source results logs")
    }
    else if(!ustrregexm(dirs, "^[+-].+")) { // such as "docs data/source outs"
        dirsV = tokens(dirs)
    }
    else {  // such as "+data/zip -results +tabs +figs"
        dirsV = tokens("docs data/source results logs")  // add default
        dirsV = dirsV, tokens(usubinstr(dirs, "+", "", .))
        dropV = select(dirsV, ustrpos(dirsV, "-") :== 1) // -* to dropV
        dropV = usubinstr(dropV, "-", "", .)
        dirsV = select(dirsV, ustrpos(dirsV, "-") :!= 1) // remove -*
    }
    
    pathV = J(0, 1, "")
    for(i=1; i<=length(dirsV); i++) {
        // split path into vector of parts
        dirV = J(1, 0, "")
        path = dirsV[i]
        
        while(path != J(1, 1, "")) {
            pathsplit(path, path, dir = "")
            dirV = dir, dirV
        }
        
        // make dirs recursively
        path = ""
        for(j=1; j<=length(dirV); j++) {
            path = pathjoin(path, dirV[j])
            
            drop = 0
            for(k=1; k<=length(dropV); k++) {
                if(ustrpos(path, path_normalize(dropV[k])) == 1) drop = 1
            }
            
            if(drop != 1 & !direxists(path)) {
                mkdir(path)
                pathV = pathV \ path
            }
        }
    }
    
    st_local("alldirs", invtokens((sort(pathV, 1))', ";"))
}

// mkdirtree(`"docs readings/ "figs data/source" docs/rd"')
// mkdirtree(`"docs;readings/; "figs data/source"; docs/rd"')
// mkdirtree(`"-docs +readings/ -data/source +data/backup +"figs tbls""')
// mkdirtree(`"-docs;+readings/; -data\source; +data/backup +"figs tbls""')
// mkdirtree(`"-docs +readings/ +"figs data/source" +docs/rd"')
// mkdirtree(`"-docs; +readings/ +"figs data/source"; +docs/rd"')

string scalar path_normalize(string scalar path) {
    // Convert file paths to canonical form for the OS platform
    string vector dirsV
    string scalar dirS
    real   scalar i
    
    dirsV = J(1, 0, "")
    while(path != J(1, 1, "")) {
        pathsplit(path, path, dirS = "")
        dirsV = dirS, dirsV
    }
    
    path = ""
    for(i=1; i<=length(dirsV); i++) {
        path = pathjoin(path, dirsV[i])
    }
    
    return(path)
}

// path_normalize("data x/source\zip")

void proj_add(string scalar pn, string scalar path, string scalar note) {
    // add pname info to XPROJ_LOOKUP_TABLE.txt
    
    string matrix lookupM
    real   scalar i
    
    lookupM = read_lookup_table()
    lookupM = lookupM \ (pn, path, note)
    
    if(length(uniqrows(lookupM[, 1])) != rows(lookupM)) {
        errprintf("project_name " + pn + " is duplicated. It won't be added.\n")
        exit(110)
    }
    
    lookupM = sort(lookupM, 1)
    
    write_lookup_table(lookupM)
}

string matrix read_lookup_table() {
    string scalar path, line
    string vector lookupV, pnV, pathV, noteV
    string matrix lookupM
    real scalar fh
    
    lookupV = J(0, 1, "")
    path = pathjoin(st_global("c(sysdir_personal)"), "XPROJ_LOOKUP_TABLE.txt")
    if(fileexists(path)) {
        lookupV = cat(path)
    }
    
    pnV     = usubstr(lookupV, 1, ustrpos(lookupV, "|") :- 1)
    lookupV = usubstr(lookupV, ustrpos(lookupV, "|") :+ 1, .)
    pathV   = usubstr(lookupV, 1, ustrpos(lookupV, "|") :- 1)
    noteV   = usubstr(lookupV, ustrpos(lookupV, "|") :+ 1, .)
    
    lookupM = pnV, pathV, noteV
    
    return(lookupM)
}

void write_lookup_table(string matrix lookupM) {
    string scalar path, line, dir
	string vector dirV
    real   scalar fh, i, j
    
	// make path `c(sysdir_personal)' if non-existent
	path = st_global("c(sysdir_personal)")
    if(!direxists(path)) {
		dirV = J(1, 0, "")
		while(path != J(1, 1, "")) {
            pathsplit(path, path, dir = "")
            dirV = dir, dirV
        }
		// make dirs recursively
        path = ""
        for(j=1; j<=length(dirV); j++) {
            path = pathjoin(path, dirV[j])
            if(!direxists(path)) {
                mkdir(path)
            }
        }
    }
    
    path = pathjoin(st_global("c(sysdir_personal)"), "XPROJ_LOOKUP_TABLE.txt")
    if(fileexists(path)) {
        unlink(path)
    }
    
    fh = fopen(path, "w")
    for(i=1; i<=rows(lookupM); i++ ) {
        fput(fh, lookupM[i, 1] + "|" + lookupM[i, 2] + "|" + lookupM[i, 3])
    }
    fclose(fh)
}

void list_lookup_table(string scalar pspec) {
    string matrix lookupM
    real   scalar i, wp, wn
    real   vector idx
    
    lookupM = read_lookup_table()
    
    idx = selectindex(lookupM[, 3] :== "")  // note == ""
    lookupM[idx, 3] = lookupM[idx, 2]
    
    pspec = glob2rx(pspec)
    lookupM = select(lookupM, ustrregexm(lookupM[, 1], pspec) :== 1)
    
    wp = max(max(udstrlen(lookupM[, 1])) \ 10)
    wn = max(max(udstrlen(lookupM[, 3])) \ 20)
    
    display(sprintf("{hline %s}", 
                    strofreal(min((st_numscalar("c(linesize)")-10 \ 70)))))
    for(i=1; i<=rows(lookupM); i++) {
        displayas("res")
        printf(sprintf(`"  %%%ss {stata xproj goto %%s:[goto]}"', strofreal(wp)), 
               lookupM[i,1], lookupM[i,1])
        printf(sprintf(`" {browse "%s":[open]}"', 
               subinstr(lookupM[i,2], "\", "\\", .)))
        printf(sprintf(`" {stata xproj drop %%s:[drop]} %%-%ss\n"', strofreal(wn)), 
               lookupM[i,1], lookupM[i,3])
    }
    display(sprintf("{hline %s}", 
                    strofreal(min((st_numscalar("c(linesize)")-10 \ 70)))))
}

string scalar glob2rx(string scalar pattern){
    // Change Wildcard or Globbing Pattern into RegEx, modified R's glob2rx()
    
    string scalar rx, spec, sp
    real   scalar i
    
    rx = usubinstr("^" + pattern + "$", ".", "\.", .)
    rx = usubinstr(rx, "*", ".*", .)
    rx = usubinstr(rx, "?", ".", .)
    rx = ustrregexra(rx, " +", "|")
    
    spec = "()[]{}+"
    for(i=1; i<=strlen(spec); i++) {
        sp = substr(spec, i, 1)
        rx = usubinstr(rx, sp, "\" + sp, .)
    }
    
    rx = usubinstr(rx, "^.*$", "", .)
    rx = usubinstr(rx, "^.*", "", .)  // trim . head
    rx = usubinstr(rx, ".*$", "", .)  // trim . tail
    
    return(rx)
}

void proj_goto(string scalar pname) {
    string matrix lookupM
    string scalar path
    
    lookupM = read_lookup_table()
    
    lookupM = select(lookupM, lookupM[, 1] :== pname)
    if (rows(lookupM) != 1) {
        errprintf("Project not found: %s\n", pname)
        exit(111)
    }
    path = lookupM[1, 2]
    st_local("proj_path", path)
    
    stata(sprintf(`"cd "%s""', path))
}

void proj_drop(string scalar pname) {
    string matrix lookupM
    real scalar rs
    
    lookupM = read_lookup_table()
    rs = rows(lookupM)
    
    lookupM = select(lookupM, lookupM[, 1] :!= pname)
    
    st_numscalar("r(DONE)", rs != rows(lookupM))
    
    if(rs != rows(lookupM)) {
        write_lookup_table(lookupM)
    }
}

end
set matastrict `_saved_matastrict'

exit
