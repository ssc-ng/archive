*! _jd_coln 1.0.0  06oct2026
*! Internal helper for the jointdiag package - not for direct use.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  Shared helpers live in their own ado-files on purpose: a secondary
*  program defined inside another ado-file is visible only to programs in
*  THAT file, so every helper called from more than one subcommand must be
*  auto-loadable by its own name.

program define _jd_coln
    version 14.0
    args lab
    if (`"`lab'"' == "") local lab "Test"
    di as txt %-34s "`lab'" " {c |}" %12s "Statistic" %8s "df" %10s "p-value"
    di as txt "{hline 35}{c +}{hline 42}"
end


