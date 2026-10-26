*! 1.4.0 NJC 25 Oct 2026
*! 1.3.0 NJC 10 Mar 2021
*! 1.2.0 NJC 25 Feb 2021
*! 1.1.0 NJC 24 Feb 2021
*! 1.0.0 NJC 14 May 2000
* code assumes a tab of 4 spaces and may look messy otherwise 
program hillplot, rclass sortpreserve  
	version 8.2 
	syntax varlist(max=1 numeric) [if] [in] [, * Pscale Log10 Report(int 25) Format(str) ] 

	tempvar hill negvar id last 
	marksample touse

	capture assert `varlist' > 0 if `touse'
	if _rc == 9 error 411 

	quietly {
		replace `touse' = -`touse'
		gen `negvar' = - `varlist' 
		bysort `touse' `negvar': gen byte `last' = _n == _N 
		count if `touse'
		if r(N) == 0 error 2000
		local n = r(N) 
		
		gen double `hill' = /* 
		*/ (sum(log(`varlist')) / _n) - log(`varlist'[_n + 1])
		replace `hill' = 1 / `hill' 	
		gen long `id' = _n if `touse'
		label var `hill' "Hill estimate of alpha"
		if "`pscale'" != "" { 
			local log = cond("`log10'" == "", "log", "log10")
			replace `id' = `log'(`id') - `log'(`n') 
			label var `id' "`log' P(`varlist' > this value)"
		}
		else label var `id' "Number of order statistics"
	}

    su `hill' if `id' == `report' & `last', meanonly  
	di _n "Hill estimate of alpha for {it:k} = `report':  " `format' r(min)
	return scalar alpha = r(min) 
	
    * su `varlist', meanonly 
	* local N = r(N)  	
    * su `varlist' if `id' == `report', meanonly 
    * return scalar A = (`report'/`N') * r(min)^(return(alpha))  
    * di _n "A: " `format' return(A) 
	
	if "`format'" != "" local alpha : di `format' return(alpha)
	else local alpha = return(alpha)  

	local subtitle : var label `varlist' 
	if `"`subtitle'"' == "" local subtitle "`varlist'" 

	scatter `hill' `id' if `last', yla(, ang(h)) ms(Oh) ///
    subtitle(`"`subtitle'"') note("{&alpha} for {it:k}= `report': `alpha'") `options'
end
