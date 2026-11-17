*! ==================================================================
*!      Display a directory's structure in a tree-like format
*! ==================================================================
*! version 1.2, 2026-11-11
*!   - first version prepared for SSC Archive submission
*!   - rename dirtree to xdtree
*!   - rewrite mata: dir_ls(), dir_tree(), print_leaf() with struct
*!   - some minor editing to xdtree.sthlp & xdtree.pkg
*!   - add two new contributors / authors
*!     - Yancheng Chen <25120242201569@stu.xmu.edu.cn>
*!     - Bowen    Wang <34520232201140@stu.xmu.edu.cn>
*! ------------------------------------------------------------------
*! version 1.1, 2022-05-18, yyzeng <zzyy@xmu.edu.cn>
*!   - change the default -levels()- from 10 to 3
*!   - some minor editing to dirtree.sthlp & dirtree.pkg
*! ------------------------------------------------------------------
*! version 1.0, 2021-04-01, yyzeng <zzyy@xmu.edu.cn>
*! ==================================================================

program define xdtree
    version 14
    syntax [anything(id="path" name=path)]    ///
           [, noRECurse Levels(integer 3)   ///
              Glob(string asis) Regex(string asis) Open noCLick ]

    // path:    A directory name (don't need enclosing quotes), default to current WD 
    // recurse: Whether to display the directory's contents recursively
    // levels:  The number of levels to recurse, default to 3
    // glob:    Wildcards / globbing pattern for file names - Not set for all files
    // regex:   Regular expression for file names - Not set for all files
    // Open:    Open directory/folder window in the operating system 
    // click:   Show "Click >>> HERE << to browse the directory"
    
    // eg., 1. xdtree
    //      2. xdtree, o
    //      3. xdtree foo, norec
    //      4. xdtree foo/bar, l(3) glob(*.do, rev noc)
    
    if `"`path'"' == "" {
        local path = "."
    }
    if ustrregexm(`"`path'"', `"^"(.+)"$"') {
        local path = ustrregexs(1)
    }
    qui mata path_normalize(`"`path'"')
    
    local pwd = c(pwd)
    if ustrregexm(`"`pwd'"', "^[a-zA-Z]:$") {  // drive root
        local pwd `"`pwd'/"'
    }
    capture cd `"`path'"'
    if _rc {
        di _n as err `"`path' not exist."'
        exit 601
    }
    qui cd `"`pwd'"'
    
    if "`recurse'" != "" {
        local levels = 1
    }
    if "`recurse'" == "" & `levels' < 1 {
        di as err "option {bf:levels()} must be a positive integer."
        exit 198
    }
    
    if `"`glob'"' != "" & `"`regex'"' != "" {
        di as err "option {bf:glob()} and {bf:regex()} can't be set simultaneously."
        exit 198
    }
    if `"`glob'"' != "" {
        parse_glob_regex `glob'
        local pat = `"`r(pat)'"'
        local rv  = "`r(rv)'"
        local cs  = "`r(cs)'"
        qui mata: glob2rx(`"`pat'"')  // return local rx
    }
    if `"`regex'"' != "" {
        parse_glob_regex `regex'
        local pat = `"`r(pat)'"'
        local rx  = `"`r(pat)'"'
        local rv  = "`r(rv)'"
        local cs  = "`r(cs)'"
    }
    
    mata: dir_tree(`"`path'"', "`recurse'"=="", `levels', ///
                    `"`rx'"', "`rv'"!="", `"`pat'"', "`cs'"!="")
    
    if ("`open'" == "" & "`click'" == "") {
        di _n `"Click >>> {bf:{browse `"`path'"':HERE}} <<< to browse the directory"'
    }
    else if ("`open'" != "") opendir `path'
    
    return clear
    
end

program define parse_glob_regex, rclass
    syntax [anything(name=pattern)] [, REVert noCase]
    
    if ustrregexm(`"`pattern'"', `"^"(.+)"$"') {
        local pattern = ustrregexs(1) // remove double quotes
    }
    
    return local pat = `"`pattern'"'
    return local rv  = "`revert'"
    return local cs  = "`case'"  // case sensitive?
end

program define opendir
    // credit to -opendir- by Bill Rising <brising@stata.com>
    syntax anything(id="path" name=path)
    
    if "`c(os)'" == "Windows" {
        local path: subinstr local path "/" "\", all
        local cmd "winexec explorer"
    }
    else {
        if ustrpos(`"`path'"', `"""') {
            if ustrpos(ustrtrim(usubstr(`"`path'"', 2, .)), "~") == 1 {
                local path = usubinstr(`"`path'"', "~", "\$HOME", 1)
            }
        }
        if "`c(os)'" == "MacOSX" {
            local cmd "! open"
        }
        else { // linux
            local cmd "! xdg-open"
        }
    }
    
    `cmd' `macval(path)'
    
end

local _saved_matastrict = c(matastrict)
set matastrict on

mata:

version 14
//mata clear

struct dirlist {
    string vector name
    string vector parent
    real   vector isdir
}

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
    st_local("path", path)
    
    return(path)
}

string scalar glob2rx(string scalar pattern){
    // Change Wildcard or Globbing Pattern into RegEx, modified R's glob2rx()
    
    string scalar rx, spec, sp
    real   scalar i
    
    rx = usubinstr("^" + pattern + "$", ".", "\.", .)
    rx = usubinstr(rx, "*", ".*", .)
    rx = usubinstr(rx, "?", ".", .)
    
    spec = "()[]{}+"
    for(i=1; i<=strlen(spec); i++) {
        sp = substr(spec, i, 1)
        rx = usubinstr(rx, sp, "\" + sp, .)
    }
    
    rx = usubinstr(rx, "^.*", "", .)  // trim.head
    rx = usubinstr(rx, ".*$", "", .)  // trim.tail
    rx = usubinstr(rx, "^$", "", .)   // -glob- not set
    st_local("rx", rx)
    
    return(rx)
}

struct dirlist scalar dir_ls(string scalar path,      ///
                             real   scalar recurse,   ///
                             real   scalar levels,    ///
                             string scalar regex,     ///
                             real   scalar revert,    ///
                             string scalar pattern,   ///
                             real   scalar nocase) {
    // Collect dirs and files in the path (recursively) to struct dirlist R

    struct dirlist scalar R, C
    string         vector dirsV, filesV
    string         scalar pathJ, name
    real           scalar i

    while(regexm(path, "[/\\]$")) path = substr(path, 1, strlen(path)-1)

    R.name   = J(0, 1, "")
    R.parent = J(0, 1, "")
    R.isdir  = J(0, 1, .)

    dirsV = dir(path, "dirs", "*", 1)
    if(length(dirsV)) {
        dirsV = dirsV[order(ustrlower(dirsV), 1), ]
        for(i=1; i<=length(dirsV); i++) {
            name  = pathbasename(dirsV[i])
            pathJ = pathjoin(path, name)
            R.name   = R.name   \ name
            R.parent = R.parent \ path
            R.isdir  = R.isdir  \ 1
            if(recurse == 1 & levels > 1) {
                C        = dir_ls(pathJ, 1, levels-1, regex, revert, pattern, nocase)
                R.name   = R.name   \ C.name
                R.parent = R.parent \ C.parent
                R.isdir  = R.isdir  \ C.isdir
            }
        }
    }

    filesV = dir(path, "files", "*", 1)  // prefix = 1
    if(length(filesV)) {
        filesV = filesV[order(ustrlower(filesV), 1), ]
        filesV = files_rx(filesV, regex, revert, nocase)  // handle glob / regex
        for(i=1; i<=length(filesV); i++) {
            R.name   = R.name   \ pathbasename(filesV[i])
            R.parent = R.parent \ path
            R.isdir  = R.isdir  \ 0
        }
    }

    return(R)
}

string vector files_rx(string vector filesV, ///
                       string scalar regex,  ///
                       real   scalar revert, ///
                       real   scalar nocase) {
    // handle files vector according to regex and revert
    
    string vector fV, fV_match, fV_nomatch
    string scalar dirS, fileS, placeholderS
    real   vector matchV
    real   scalar i, len
    
    if(filesV == J(0, 1, "") | regex == "") {
        if(!revert) return(filesV)  // return asis
        else return(J(0, 1, ""))    // return null
    }
    else {
        fV = J(0, 1, "")
        for(i=1; i<=length(filesV); i++) {
            pathsplit(filesV[i], dirS="", fileS="")
            fV = fV \ fileS
        }
        matchV = ustrregexm(fV, regex, nocase)  // if nocase=1: ignore case
        fV_match = select(fV, matchV)
        fV_nomatch = select(fV, !matchV)
    }
    
    if(!revert) {
        if((len=length(fV_nomatch)) > 0) {
            if(length(fV_match) == 0) fV_match = J(0, 1, "")
            if(len>1) {
                placeholderS = sprintf("[%s_files_not_match_<%s>]", ///
                                        strofreal(len), "*PAT*")
            }
            else placeholderS = sprintf("[%s_file_not_match_<%s>]", ///
                                        strofreal(len), "*PAT*")
            fV_match = fV_match \ placeholderS
        }
        for(i=1; i<=length(fV_match); i++) {
            fV_match[i] = pathjoin(dirS, fV_match[i])
        }
        return(fV_match)
    }
    else {  // revert
        if((len=length(fV_match)) > 0) {
            if(length(fV_nomatch) == 0) fV_nomatch = J(0, 1, "")
            if(len>1) {
                placeholderS = sprintf("[%s_files_match_<%s>]", ///
                                        strofreal(len), "*PAT*")
            }
            else placeholderS = sprintf("[%s_file_match_<%s>]", ///
                                        strofreal(len), "*PAT*")
            fV_nomatch = fV_nomatch \ placeholderS
        }
        for(i=1; i<=length(fV_nomatch); i++) {
            fV_nomatch[i] = pathjoin(dirS, fV_nomatch[i])
        }
        return(fV_nomatch)
    }
}

// void left_align(string vector strV) {
//     real scalar i
//     
//     for(i=1; i<=length(strV); i++) {
//         printf("%-60s\n", strV[i,])
//     }
// }

void dir_tree(string scalar path,       ///
              real   scalar recurse,    ///
              real   scalar levels,     ///
              string scalar regex,      ///
              real   scalar revert,     ///
              string scalar pattern,    ///
              real   scalar nocase) {
    // print path in tree-like format (recursively)

    struct dirlist scalar L
    string vector ch

    L = dir_ls(path, recurse, levels, regex, revert, pattern, nocase)
    L.name = usubinstr(L.name, "*PAT*", pattern, .)

    ch = "-", "|", "\", "+", "📂", "📄"
    // ch = "─", "│", "└", "├", "📂", "📄"

    display(sprintf("{hline %s}", ///
            strofreal(rowmin((st_numscalar("c(linesize)")-10, 70)))))
    displayas("text")
    printf("    " + ch[5] + " " + path + "/" + "\n")
    print_leaf(L, path, ch, "    ")
    display(sprintf("{hline %s}", ///
            strofreal(rowmin((st_numscalar("c(linesize)")-10, 70)))))
}

void print_leaf(struct dirlist scalar L, ///
                string scalar path,      ///
                string vector ch,        ///
                string scalar indent) {

    string scalar pathJ, name, icon
    real   vector idx
    real   scalar k, j

    if(!length(L.name)) return

    idx = select(1::length(L.name), L.parent :== path)
    for(k=1; k<=length(idx); k++) {
        j     = idx[k]
        name  = L.name[j]
        pathJ = pathjoin(path, name)

        if(L.isdir[j]) {
            shown = name + "/"
            icon = ch[5] + " "
        }
        else {
            shown = name
            icon = ch[6] + " "
        }

        if(k == length(idx)) {
            printf(indent + ch[3] + ch[1] + ch[1] + icon + shown  + "\n")
            if(L.isdir[j]) print_leaf(L, pathJ, ch, indent + "    ")
        }
        else {
            printf(indent + ch[4] + ch[1] + ch[1] + icon + shown + "\n")
            if(L.isdir[j]) print_leaf(L, pathJ, ch, indent + ch[2] + "   ")
        }
    }
}

end

exit



mata: 

// unit test path_normalize()
path_normalize("data x/123 source\456.zip")     // data x\123 source\456.zip
path_normalize(`""data x/123 source\456.zip""') // "data x\123 source\456.zip"

// unit test glob2rx()
assert(glob2rx("abc.*") == "^abc\.")
assert(glob2rx("a?b.*") == "^a.b\.")
assert(glob2rx("a?b.*") == "^a.b\.")
assert(glob2rx("*.doc") == "\.doc$")
assert(glob2rx("*.t*")  == "\.t")
assert(glob2rx("*.t??") == "\.t..$")
assert(glob2rx("*[*")  == "\[")

// test files_rx()
filesV = "abc/x123.do" \ "abc/xyz.do" \ "abc/xyz.dta" \ "abc/XYZ.log"
files_rx(filesV, ".*\.do$", 0, 0)
files_rx(filesV, ".*\.do$", 1, 0)
files_rx(filesV, "^xyz\..*$", 0, 0)
files_rx(filesV, "^xyz\..*$", 1, 0)
files_rx(filesV, "", 0, 0)
files_rx(filesV, "^xyz\..*$", 1, 0)
files_rx(filesV, "^xyz\..*$", 1, 1)

end
