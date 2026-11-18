*! Output file validation for cdid result utilities; current StataNow19.5.
*! Resolves the suffix and refuses an existing file unless replace is given.
program define _cdid_ur_target
    version 19.5
    syntax name(name=target), FILE(string) [DEFault(string) ALLOWed(string) DISallowed(string) REQuire REPLACE]
    if `"`file'"'=="" {
        display as error "a file name is required"
        exit 198
    }
    mata: st_local("suffix", strlower(pathsuffix(st_local("file"))))
    if "`suffix'"=="" {
        if "`require'"!="" {
            display as error `"`file': a file suffix such as .png, .svg or .pdf is required"'
            exit 198
        }
        local file `"`file'`default'"'
        local suffix "`default'"
    }
    // temporary files (tempfile) are written under their own names, as by save
    local tmpdir = ustrregexra(c(tmpdir), "/+$", "")
    local istemp = (strpos(`"`file'"', "`tmpdir'")==1)
    if "`allowed'"!="" & !`istemp' {
        if !`: list suffix in allowed' {
            display as error `"`file': only `allowed' files are written here"'
            exit 198
        }
    }
    if "`disallowed'"!="" {
        if `: list suffix in disallowed' {
            display as error `"`file': `suffix' files are not written by this option"'
            exit 198
        }
    }
    capture confirm new file `"`file'"'
    local rc = _rc
    if `rc'==602 & "`replace'"=="" {
        display as error `"file `file' already exists; specify replace to overwrite it"'
        exit 602
    }
    if `rc' & `rc'!=602 {
        display as error `"cannot write `file'"'
        exit `rc'
    }
    c_local `target' `"`file'"'
end
