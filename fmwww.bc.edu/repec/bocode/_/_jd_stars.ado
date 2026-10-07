*! _jd_stars 1.0.0  06oct2026
*! Internal helper for the jointdiag package - not for direct use.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  Shared helpers live in their own ado-files on purpose: a secondary
*  program defined inside another ado-file is visible only to programs in
*  THAT file, so every helper called from more than one subcommand must be
*  auto-loadable by its own name.

program define _jd_stars, rclass
    version 14.0
    args p
    local s ""
    if (`p' < .) {
        if      (`p' < 0.01)  local s "***"
        else if (`p' < 0.05)  local s "** "
        else if (`p' < 0.10)  local s "*  "
        else                  local s "   "
    }
    return local stars "`s'"
end


