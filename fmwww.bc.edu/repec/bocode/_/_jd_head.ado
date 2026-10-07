*! _jd_head 1.0.0  06oct2026
*! Internal helper for the jointdiag package - not for direct use.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  Shared helpers live in their own ado-files on purpose: a secondary
*  program defined inside another ado-file is visible only to programs in
*  THAT file, so every helper called from more than one subcommand must be
*  auto-loadable by its own name.

program define _jd_head
    version 14.0
    args title sub1 sub2
    di as txt ""
    di as txt "{hline 78}"
    di as res "  `title'"
    if (`"`sub1'"' != "") di as txt "  `sub1'"
    if (`"`sub2'"' != "") di as txt "  `sub2'"
    di as txt "{hline 78}"
end


