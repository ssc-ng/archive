*! _bd_fdbreport.ado — fast double bootstrap output for bootdiag
*! Version 1.0.0
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

*-----------------------------------------------------------------------
* _bd_fdbreport — output for the fast double bootstrap
*-----------------------------------------------------------------------
program define _bd_fdbreport
    version 16.0
    syntax , mat(string) test(string) reps(integer) [ dgp(string) cmd(string) ]

    local s  = `mat'[1, 1]
    local p1 = `mat'[1, 2]
    local q  = `mat'[1, 3]
    local pf = `mat'[1, 4]

    di as txt ""
    di as txt "{hline 78}"
    di as res _col(3) "bootdiag" _col(14) as txt "Fast double bootstrap"
    di as txt "{hline 78}"
    di as txt _col(3) "Test"              _col(32) ": " as res "`test'"
    di as txt _col(3) "Fitted by"         _col(32) ": " as res "`cmd'"
    di as txt _col(3) "Bootstrap DGP"     _col(32) ": " as res "`dgp'"
    di as txt _col(3) "Replications"      _col(32) ": " as res "`reps'" ///
       as txt "  (" as res `=2*`reps'+1' as txt " statistics in total)"
    di as txt ""
    di as txt "  {hline 74}"
    di as txt _col(3) "Quantity" _col(45) "Value"
    di as txt "  {hline 74}"
    di as txt _col(3) "Observed statistic"          _col(43) as res %12.4f `s'
    di as txt _col(3) "Single-bootstrap p-value"    _col(43) as res %12.4f `p1'
    di as txt _col(3) "1-p quantile of 2nd level"   _col(43) as res %12.4f `q'
    di as txt _col(3) "Fast double bootstrap p"     _col(43) as res %12.4f `pf'
    di as txt "  {hline 74}"
    di as txt _col(3) "Davidson & MacKinnon (2007). The FDB costs 2B+1 statistics"
    di as txt _col(3) "instead of B(B+1) and normally has a lower-order error in"
    di as txt _col(3) "rejection probability than the single bootstrap."
    di as txt "{hline 78}"
end
