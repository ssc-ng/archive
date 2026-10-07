*! _jd_foot 1.0.0  06oct2026
*! Internal helper for the jointdiag package - not for direct use.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  Shared helpers live in their own ado-files on purpose: a secondary
*  program defined inside another ado-file is visible only to programs in
*  THAT file, so every helper called from more than one subcommand must be
*  auto-loadable by its own name.

program define _jd_foot
    version 14.0
    args extra
    di as txt "{hline 78}"
    di as txt "  Significance: {bf:*} 10%   {bf:**} 5%   {bf:***} 1%"
    if (`"`extra'"' != "") di as txt "  `extra'"
    di as txt ""
end


