*******************************************************
* HSCC example
* Version 1.0.2
*******************************************************

clear all
set more off

* Load your strongly balanced panel
use "your_panel_data.dta", clear

* Declare panel structure
xtset id time

* HSCC with automatic DK lag
hscc y x1 x2 x3 x4

* HSCC with user-defined DK lag
hscc y x1 x2 x3 x4, lag(2)

* HSCC with common time fixed effects
hscc y x1 x2 x3 x4, timefe

* HSCC with common time fixed effects and user-defined DK lag
hscc y x1 x2 x3 x4, timefe lag(2)

* Stored results
matrix list e(b)
matrix list e(V)
matrix list e(mg_b)

display e(N)
display e(N_g)
display e(T)
display e(lag)
display e(r2_w)
display e(heterogeneity_trace)
display "`e(timefe)'"

* Recovered centered common time effects when timefe is used
matrix list e(timefe_b)
