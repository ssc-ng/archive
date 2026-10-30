*! ntcoint_ecbyields.do  1.0.0  27oct2026
*! Dr Merwan Roudane  -  github.com/merwanroudane
*!
*! Builds ntcoint_ecbyields.dta, the dataset behind the empirical application of
*! Hualde and Olmo (2026, JBES), Tables 3 and 4 and Figure 1.
*!
*! Source: European Central Bank Data Portal, "Financial market data - yield
*! curve (YC)".  Yield curve spot rate, n-year maturity - government bond,
*! nominal, all issuers whose rating is triple A - Euro area (changing
*! composition).  Daily, business week.
*! https://data.ecb.europa.eu/data/datasets/YC
*!
*! Sample: 6 September 2004 - 7 April 2025, T = 5,263 business days.
*! Maturities: 3 months, 1, 2, 5, 7, 10 and 30 years.  Levels, percent per annum,
*! no transformation (the paper argues the series carry no linear trend, so the
*! constant-only specification of its Section 3 applies).
*!
*! NOTE ON tsset.  The series is a business-week daily series, so the calendar
*! dates are not contiguous.  The authors' term_structure.m indexes the rows,
*! not the dates, so we tsset a sequential row counter and keep the calendar
*! date as a label.  Using the calendar date instead would insert weekend gaps
*! that the differencing and the HAC estimator would have to span.

version 16
clear

local src "C:/Users/HP/Documents/xtpmg/ntcoint/data/ECB Data Portal.xlsx"
local out "C:/Users/HP/Documents/xtpmg/ntcoint/ntcoint_ecbyields.dta"

import excel using "`src'", sheet("data") firstrow clear

* the workbook carries DATE and TIME PERIOD (identical) then the 7 maturities
rename (*) (v1 v2 v3 v4 v5 v6 v7 v8 v9)
keep v1 v3 v4 v5 v6 v7 v8 v9
rename (v1 v3 v4 v5 v6 v7 v8 v9) (edate y3m y1y y2y y5y y7y y10y y30y)

* drop any trailing blank rows the export may carry
drop if missing(y3m) & missing(y30y)

format edate %td
label variable edate "calendar date (business week)"
label variable y3m   "3-month spot yield, AAA euro area (% p.a.)"
label variable y1y   "1-year spot yield, AAA euro area (% p.a.)"
label variable y2y   "2-year spot yield, AAA euro area (% p.a.)"
label variable y5y   "5-year spot yield, AAA euro area (% p.a.)"
label variable y7y   "7-year spot yield, AAA euro area (% p.a.)"
label variable y10y  "10-year spot yield, AAA euro area (% p.a.)"
label variable y30y  "30-year spot yield, AAA euro area (% p.a.)"

generate int t = _n
label variable t "business-day index (1 = 6 Sep 2004)"
tsset t

compress
notes: ECB Data Portal, yield curve (YC), AAA euro-area government bonds.
notes: Sample 6 Sep 2004 - 7 Apr 2025, business-week daily, T = `=_N'.
notes: Replication data for Hualde and Olmo (2026), JBES, Tables 3-4 and Figure 1.
label data "ECB AAA euro-area nominal bond yields, daily 2004-2025"

save "`out'", replace

di as text _n "{hline 60}"
di as text "observations : " as result _N as text "   (paper reports 5,263)"
summarize edate, format
di as text "{hline 60}"
