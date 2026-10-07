*! _jd_gstyle 1.0.0  06oct2026
*! Internal helper for the jointdiag package - not for direct use.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  Shared helpers live in their own ado-files on purpose: a secondary
*  program defined inside another ado-file is visible only to programs in
*  THAT file, so every helper called from more than one subcommand must be
*  auto-loadable by its own name.

program define _jd_gstyle, rclass
    version 14.0
    return local gopt `"graphregion(color(white) lwidth(medium)) plotregion(color(white) margin(medsmall)) ylabel(,angle(horizontal) grid glcolor(gs14) glwidth(thin) nogextend) xlabel(,nogextend) legend(region(lcolor(white)) cols(3) size(small))"'
    return local c1 "navy"
    return local c2 "maroon"
    return local c3 "forest_green"
    return local c4 "dkorange"
end

