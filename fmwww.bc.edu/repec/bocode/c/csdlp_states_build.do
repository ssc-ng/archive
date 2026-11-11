*! csdlp_states_build.do -- rebuilds csdlp_states.dta from the original sources
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* csdlp_states.dta ships with csdlp (net get csdlp), so this file is only
* needed to rebuild or update the data. It needs internet access.
*
* Sources
*   (1) Federal Reserve Bank of Philadelphia, State Coincident Indexes
*       (coincident-revised.xls), monthly, 50 states and the US, 2007 = 100.
*       https://www.philadelphiafed.org/surveys-and-data/regional-economic-analysis/state-coincident-indexes
*   (2) Jarocinski, M. and P. Karadi (2020), "Deconstructing monetary policy
*       surprises -- the role of information shocks", AEJ: Macroeconomics
*       12(2): 1-43, doi:10.1257/mac.20180090. Updated Fed shocks, frozen
*       release jkshocks_update_fed_202401 (monthly, 1990m2-2024m1).
*       https://github.com/marekjarocinski/jkshocks_update_fed_202401

version 15.0
clear
set more off

local ci_url "https://www.philadelphiafed.org/-/media/FRBP/Assets/Surveys-And-Data/coincident/coincident-revised.xls"
local jk_url "https://raw.githubusercontent.com/marekjarocinski/jkshocks_update_fed_202401/main/shocks_fed_jk_m.csv"
copy "`ci_url'" coincident-revised.xls, replace
copy "`jk_url'" shocks_fed_jk_m.csv, replace

* ---------------------------------------------------------------- states
import excel using coincident-revised.xls, clear firstrow
capture confirm string variable Date
if !_rc {
    gen mdate = monthly(Date, "M20Y")
}
else {
    gen mdate = mofd(Date)
}
format mdate %tm
drop Date
rename US us_ci
ds mdate us_ci, not
foreach v of varlist `r(varlist)' {
    rename `v' ci_`v'
}
qui reshape long ci_, i(mdate) j(state) string
rename ci_ ci
encode state, gen(sid)
xtset sid mdate

* ---------------------------------------------------------------- shocks
tempfile panel jk
save `panel'
import delimited using shocks_fed_jk_m.csv, clear
gen mdate = ym(year, month)
format mdate %tm
keep mdate mp_median cbi_median pc1_hf
save `jk'
use `panel', clear
merge m:1 mdate using `jk', keep(master match) nogen

* ---------------------------------------------------------------- variables
xtset sid mdate
gen double y   = 100*ln(ci)
gen double yus = 100*ln(us_ci)
gen double dy  = D.y
gen double rel = (y - L12.y) - (yus - L12.yus)
_pctile rel, p(1 99)
gen double relw = min(max(rel, r(r1)), r(r2)) if rel < .
qui summarize relw
gen double zw = (relw - r(mean))/r(sd)
gen byte pre = mdate <= ym(2019,12)
drop yus relw

label variable state      "State (USPS code)"
label variable sid        "State identifier"
label variable mdate      "Month"
label variable ci         "State coincident index (2007=100), Philadelphia Fed"
label variable us_ci      "US coincident index (2007=100), Philadelphia Fed"
label variable y          "100 x ln(state coincident index)"
label variable dy         "Monthly change in y (log points x 100)"
label variable rel        "12m growth of y minus 12m growth of US index"
label variable zw         "rel winsorised p1/p99, standardised (csdlp state)"
label variable mp_median  "JK (2020) monetary policy shock, median rotation (pp)"
label variable cbi_median "JK (2020) central bank information shock (pp)"
label variable pc1_hf     "JK (2020) high-frequency policy indicator surprise (pp)"
label variable pre        "1 if month <= 2019m12 (pre-COVID baseline sample)"

order state sid mdate ci us_ci y dy rel zw mp_median cbi_median pc1_hf pre
sort sid mdate
xtset sid mdate
label data "US states: activity and monetary policy shocks (csdlp example)"
notes drop _all
notes: Source (ci, us_ci): Federal Reserve Bank of Philadelphia, State Coincident Indexes, coincident-revised.xls.
notes: Source (shocks): Jarocinski and Karadi (2020), AEJ: Macroeconomics 12(2): 1-43, doi:10.1257/mac.20180090; updated Fed shocks, release jkshocks_update_fed_202401.
notes: Shocks are zero in months without FOMC announcements and missing outside 1990m2-2024m1.
notes: Built by csdlp_states_build.do (csdlp package, M. Roudane). Cite the original sources when using these data.
compress
saveold csdlp_states.dta, version(14) replace
describe
