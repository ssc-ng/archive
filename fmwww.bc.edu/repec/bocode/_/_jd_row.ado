*! _jd_row 1.0.0  06oct2026
*! Internal helper for the jointdiag package - not for direct use.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  Shared helpers live in their own ado-files on purpose: a secondary
*  program defined inside another ado-file is visible only to programs in
*  THAT file, so every helper called from more than one subcommand must be
*  auto-loadable by its own name.

program define _jd_row
    version 14.0
    args name stat df p note
    _jd_stars `p'
    local st "`r(stars)'"
    if (`df' >= .) {
        di as txt %-34s abbrev("`name'",34) " {c |}" ///
           as res %12.4f `stat' as txt %8s "--" ///
           as res %10.4f `p' "  " as res "`st'" as txt "  `note'"
    }
    else {
        di as txt %-34s abbrev("`name'",34) " {c |}" ///
           as res %12.4f `stat' as txt %8.0f `df' ///
           as res %10.4f `p' "  " as res "`st'" as txt "  `note'"
    }
end


