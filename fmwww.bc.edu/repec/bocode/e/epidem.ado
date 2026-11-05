program define epidem
    version 10
    *! Wrapper for subcommands: channel, rregmm, ppvalue
    *! Usage examples:
    *!   epidem channel  dengue year week, yeval(2007) yspan(5) wspan(2) met(regmean)
    *!   epidem rregmm   dengue year week, yeval(2008) ryspan(10)
    *!   epidem ppvalue  dengue year week, yeval(2007) yspan(5) wspan(2) met(regmean)
    
    /*Grab subcommand*/
    gettoken subcmd 0 : 0
    if ("`subcmd'" == "") {
        di as err "subcommand required: channel, rregmm, or ppvalue"
        exit 198
    }

    /*Normalize*/
    local subcmd = lower("`subcmd'")
    local valid_subcmds "channel rregmm ppvalue" 

    /*Match subcommand (allow abbreviations)*/
    local match ""
    foreach sc of local valid_subcmds {
        if (substr("`sc'", 1, length("`subcmd'")) == "`subcmd'") {
            if ("`match'" != "") {
                di as err ///
                    "subcommand abbreviation '`subcmd'' is ambiguous; " ///
                    "it matches both `match' and `sc'"
                exit 198
            }
            local match "`sc'"
        }
    }

    if ("`match'" == "") {
        di as err "unknown subcommand `subcmd'"
        di as err "valid subcommands are: `valid_subcmds'"
        exit 198
    }

    /*Pass on command*/
    if ("`match'" == "channel") {
        channel `0'
        exit
    }
    else if ("`match'" == "rregmm") {
        rregmm `0'
        exit
    }
    else if ("`match'" == "ppvalue") {
        ppvalue `0'
        exit
    }

end
