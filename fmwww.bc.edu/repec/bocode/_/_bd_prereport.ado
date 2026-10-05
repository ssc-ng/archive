*! _bd_prereport.ado — pretest-chosen B output for bootdiag
*! Version 1.0.0
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _bd_prereport
    version 16.0
    syntax , mat(string) test(string) alpha(real) beta(real) ///
             bmin(integer) bmax(integer) [ dgp(string) cmd(string) ]

    local s = `mat'[1, 1]
    local p = `mat'[1, 2]
    local B = `mat'[1, 3]

    di as txt ""
    di as txt "{hline 78}"
    di as res _col(3) "bootdiag" _col(14) as txt "Pretest choice of B"
    di as txt "{hline 78}"
    di as txt _col(3) "Test"           _col(32) ": " as res "`test'"
    di as txt _col(3) "Fitted by"      _col(32) ": " as res "`cmd'"
    di as txt _col(3) "Bootstrap DGP"  _col(32) ": " as res "`dgp'"
    di as txt _col(3) "Level of interest"  _col(32) ": " as res %6.3f `alpha'
    di as txt _col(3) "Pretest level"      _col(32) ": " as res %6.3f `beta'
    di as txt _col(3) "B range"            _col(32) ": " as res "`bmin' to `bmax'"
    di as txt ""
    di as txt "  {hline 74}"
    di as txt _col(3) "Observed statistic"      _col(43) as res %12.4f `s'
    di as txt _col(3) "Bootstrap p-value"       _col(43) as res %12.4f `p'
    di as txt _col(3) "Replications actually used" _col(43) as res %12.0f `B'
    di as txt "  {hline 74}"
    di as txt _col(3) "Davidson & MacKinnon (2000). B is raised as 2B+1 until the"
    di as txt _col(3) "p-value is decisively on one side of `alpha', which keeps"
    di as txt _col(3) "alpha*(B+1) an integer and makes B small when it can safely"
    di as txt _col(3) "be small and large only when power demands it."
    di as txt "{hline 78}"
end
