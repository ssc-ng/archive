*! 2.1.0 NJC 25 Oct 2026 
*! 2.0.0 NJC 29 Nov 2003
*! 1.1.1 NJC 15 Dec 1998
*! 1.0.0 NJC 21 July 1998
program mexplot, sort
	version 8.2
	syntax varname(numeric) [if] [in] ///
	[, MEAN(str) MEDian MEDian2(str) PLOT(str asis) ADDPLOT(str asis) /// 
	SHOWN SHOWN2(numlist max=1) *] 

	marksample touse
	qui count if `touse' 
	if r(N) == 0 error 2000 
	local N = r(N) 

	tempvar nvar meanot n 

	quietly { 
		gen `nvar' = -`varlist'
		replace `touse' = -`touse' 
		bysort `touse' (`nvar') : gen `meanot' = /// 
			sum(`varlist'[_n - 1]) / (_n - 1) - `varlist' if `touse'
		by `touse' `nvar' : replace `meanot' = `meanot'[1]
		by `touse' `nvar' : gen `n' = _N * (_n == 1) 
		by `touse' : replace `n' = sum(`n') 
 
		if "`shown2'" != "" { 
			tempvar sn 
			gen `sn' = string(`n') if `n' <= `shown2'   
			local n "`sn'" 
		}

		label var `meanot' "mean excess"
	}

	quietly if "`median'`median2'" != "" {
		tempvar excess medot
		gen `excess' = .
		gen `medot' = .
		forval i = 1/`=`N'-1' { 
			local j = `i' + 1
			replace `excess' = `varlist' - `varlist'[`j']
			local lowmed = `j' / 2
			local himed = (`j' + 1) / 2
			replace `medot' = (`excess'[`lowmed'] + `excess'[`himed']) / 2 in `j'
		}
		by `touse' `nvar' : replace `medot' = `medot'[1]
		label var `medot' "median excess"
	}

	if "`shown'`shown2'" != "" { 
		local shown "mlabel(`n') mlabpos(12)" 
	}

	twoway connect `meanot' `medot' `varlist', ms(O Dh) clp(solid dash) ///
	`shown' `options'  /// 
	|| `plot' || `addplot'

	if "`mean'" != "" {
		confirm new variable `mean'
		qui gen `mean' = `meanot'
		label var `mean' "`varlist' mean excess"
	}

	if "`median2'" != "" {
		confirm new variable `median2'
		qui gen `median2' = `medot'
		label var `median2' "`varlist' median excess"
	}

end

