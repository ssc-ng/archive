*! radscatter (v1.1) (06 Nov 2026)
*! Asjad Naqvi (asjadnaqvi@gmail.com)

* v1.1 (06 Nov 2026): Stata 15 minimum. Fixed sample-based IDs, angles, and normalization, genheight(), and centering; validate radial values and output names.
* v1.0 (17 Nov 2025): first release. Mark points and generate angles for a circle.


**********************
***   radscatter   *** // radial scatter points 
**********************


capture program drop radscatter

program define radscatter

	version 15

    syntax [ varlist(max=1 default=none numeric) ] [if] [in], [ ROtate(real 0) center Start(real 0) End(real 360) RADius(numlist max=1 >=0) flip DISplace(real 0) labangle genid(string) genx(string) geny(string) GENAngle(string) GENHeight(string) replace]


	marksample touse
    quietly count if `touse'
    local items = r(N)
    if `items' == 0 {
        display as error "No complete observations in the selected sample."
        exit 2000
    }
    foreach option in rotate start end displace {
        if missing(``option'') {
            display as error "`option'() must be a nonmissing number."
            exit 198
        }
    }
    if "`varlist'" != "" {
        quietly summarize `varlist' if `touse', meanonly
        if r(min) < 0 | r(max) <= 0 {
            display as error "Radial values must be nonnegative, with at least one positive value."
            exit 198
        }
        local maxheight = r(max)
    }
	
	
    // Parse inputs

	local xvar 	_radx
	local yvar 	_rady
	local avar 	_rada
	local hvar 	_radh
	local idvar _radid

	if "`genid'" 		!= "" local idvar `genid'
	if "`genx'" 		!= "" local xvar  `genx'
	if "`geny'" 		!= "" local yvar  `geny'				
	if "`genangle'" 	!= "" local avar  `genangle'			
	if "`genheight'" 	!= "" local hvar  `genheight'

    local outputs `idvar' `xvar' `yvar' `avar' `hvar'
    local unique : list uniq outputs
    local overlap : list outputs & varlist
    if wordcount("`unique'") != 5 | "`overlap'" != "" {
        display as error "Output names must be distinct and different from the input variable."
        exit 198
    }
    foreach output of local outputs {
        confirm name `output'
        if "`replace'" == "" {
            capture confirm variable `output'
            if !_rc confirm numeric variable `output'
        }
    }

	
quietly {	
	
	if "`replace'" != "" {
		cap drop `idvar'
		cap drop `xvar'
		cap drop `yvar'
		cap drop `avar'
		cap drop `hvar'
	}	

	cap generate double `idvar' = .
	cap generate double `xvar' = .
	cap generate double `yvar' = .
	cap generate double `avar' = .
	cap generate double `hvar' = .
	

    tempvar sequence
    generate long `sequence' = sum(`touse')
    replace `idvar' = `sequence' if `touse'


	if "`flip'" == "" {
		local mypi = _pi
	}
	else {
		local mypi = -_pi
	}

	local ro = (`rotate') 	* `mypi' / 180  	
	local st = (`start') 	* `mypi' / 180
	local en = (`end') 		* `mypi' / 180
	local span = `en' - `st'

	// predefine rotation offset for centering
	local rocenter = 0

	if "`center'" != "" {
		local rocenter = `span' / (2 * `items')
	}
	
	replace `avar' = ((`idvar' - 1) * `span' / (`items')) + `st' + `rocenter' + `ro'  if `touse'

	if "`radius'" == "" local radius = 5
	
	// note: displace is absolute and done after transformation to get consistent results. In percentage terms we get different displacements

	if "`varlist'" != "" {
		replace `hvar' = (`radius' * (`varlist' / `maxheight')) + `displace' if `touse'
	}
	else {
		replace `hvar' = (`radius' + `displace')  if `touse'
	}
	
	
	replace `xvar' = `hvar' * cos(`avar')	 if `touse'
	replace `yvar' = `hvar' * sin(`avar')	 if `touse'
	
	
	if "`labangle'" != "" { // ray angles from origin

		tempvar quad
		gen int `quad' = .  // quadrants
		replace `quad' = 1 if `xvar' >= 0 & `yvar' >= 0  & `touse'
		replace `quad' = 2 if `xvar' <  0 & `yvar' >= 0  & `touse'
		replace `quad' = 3 if `xvar' <  0 & `yvar' <  0  & `touse'
		replace `quad' = 4 if `xvar' >= 0 & `yvar' <  0  & `touse'
		

		cap gen double _labangle = .

		replace _labangle = (`avar'  * (180 / _pi)) - 180 if `avar' >  _pi   & `touse'
		replace _labangle = (`avar'  * (180 / _pi))  	  if `avar' <= _pi   & `touse'
		
		// correct rotations
		replace _labangle = (`avar'  * (180 / _pi))       if `quad'==4  	& `touse'
		replace _labangle = (`avar'  * (180 / _pi)) - 180 if `quad'==2  	& `touse'
	
	}
	
	
}
	
end