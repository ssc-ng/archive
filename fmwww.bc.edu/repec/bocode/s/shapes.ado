*! shapes v1.5 (06 Nov 2026)
*! Asjad Naqvi (asjadnaqvi@gmail.com)

* v1.5 (06 Nov 2026): Stata 15 minimum. Fixed separator allocation, custom square names, grouped rotation, polygon area, and rounding outputs; preserve user variables and validate subcommands and parameters.
* v1.4 (19 Nov 2025): major upgrades to various functions. translate, dilate, stretch, round added.
* v1.3 (05 Nov 2024): add append as sub for stack. Added square.
* v1.2 (15 Oct 2024): added support for generating pies. added x0,y0 to control center points.
* v1.1 (13 Oct 2024): Fixed a bug where an existing _N was resulting in additional rows being added below. This version tracks indices much better.
* v1.0 (11 Oct 2024): first release.



// main rountine
cap program drop shapes

program define shapes
 
version 15
	gettoken subcmd 0: 0, parse(", ")
    if !inlist("`subcmd'", "circle", "pie", "square", "rotate", "stretch", "round", "translate", "dilate", "area") {
        display as error "Unknown shapes subcommand: `subcmd'. See help shapes."
        exit 198
    }

	// draw //
	if "`subcmd'" == "circle" 		_circle  `0'
	if "`subcmd'" == "pie" 			_pie 	 `0'
	if "`subcmd'" == "square" 		_square  `0'
	
	// modify //
	if "`subcmd'" == "rotate" 		_rotate  	`0'
	if "`subcmd'" == "stretch" 		_stretch	`0'	
	if "`subcmd'" == "round" 		_round 	 	`0'
	if "`subcmd'" == "translate" 	_translate 	`0'
	if "`subcmd'" == "dilate" 		_dilate 	`0'
	
	// calculate //
	if "`subcmd'" == "area" 		_area 	 `0'			
	
end


**************
*** circle ***
**************

program define _circle 
version 15

	syntax, RADius(numlist max=1 >0) [ x0(real 0) y0(real 0) n(integer 100) ROtate(real 0) genx(name) geny(name) genid(name) genorder(name) replace stack append ]
    if missing(`n', `x0', `y0', `rotate') | `n' < 3 {
        display as error "n() must be at least 3; center and rotation must be nonmissing."
        exit 198
    }

	
quietly {	
	
	
	// prepare the variables
	local xvar _x
	local yvar _y
	local idvar _id
	local ordervar _order

	
	if "`genx'" 	!= "" local xvar 	 `genx'
	if "`geny'" 	!= "" local yvar 	 `geny'				
	if "`genid'" 	!= "" local idvar 	 `genid'				
	if "`genorder'" != "" local ordervar `genorder'				
	
	if "`replace'" != "" {
		cap drop `xvar'
		cap drop `yvar'
		cap drop `idvar'
		cap drop `ordervar'
		
	}		

	cap generate double `xvar' = .
	cap generate double `yvar' = .
	cap generate 		`idvar' = .
	cap generate 		`ordervar' = .
	
	
	if "`stack'" != "" | "`append'" !="" {
		
		tempvar temp
		gen `temp' = _n if !missing(`ordervar')
		summ `temp', meanonly
		
		if r(N)!= 0 {			
			local start = `=`r(max)' + 1'
			local end   = `=`r(max)' + `n' + 2'
			
			if _N < `=`r(max)'+`n'+2' set obs `end'
		}
		else {
			local start = 1
			local end = `=`n' + 2'
			if _N < `end' set obs `end'
		}
		
	} 
	else {
		local start = 1
		local end = `=`n' + 2'
		if _N < `end' set obs `end'
	}
	
	
	summ `idvar', meanonly
		
	if `r(N)'==0 {
		local k = 1
	}
	else {
		local k = `r(max)' + 1
	}
	
	summ `ordervar', meanonly
	replace `idvar' = `k' in  `start'/`end' 

		
	// generate the indices
	tempvar _temp _temp2 _seq _angle
	gen `_temp' = 1
	replace `ordervar' = sum(`_temp') if `idvar'==`k'	
	
	gen `_temp2' = _n
	
	summ `_temp2' if `idvar'==`k', meanonly
	local end = `end' - 2
 
	// add shape
	local rotate = `rotate' * _pi / 180  	
		
	gen double `_angle' = (`ordervar' * 2 * _pi / `n') + `rotate' in `start'/`end'

	replace `xvar' = `x0' + `radius' * cos(`_angle') in  `start'/`end' 
	replace `yvar' = `y0' + `radius' * sin(`_angle') in  `start'/`end'	


	// duplicate first row to complete the shape
	summ `xvar' in `start', meanonly
	replace `xvar' = `r(min)' in `=`end' + 1'

	summ `yvar' in `start', meanonly
	replace `yvar' = `r(min)' in `=`end' + 1'
	
	
}


end



**************
***   pie  ***
**************

program define _pie
 version 15
 
    syntax, RADius(numlist max=1 >0) end(numlist max=1) [ x0(real 0) y0(real 0) n(integer 30) ROtate(real 0) ] ///
			[ start(numlist max=1)  genx(string) geny(string) genid(string) genorder(string) replace stack dropbase append flip  ]

    
	// prepare the variables
	local xvar _x
	local yvar _y
	local idvar _id
	local ordervar _order
	
	if missing(`n', `x0', `y0', `rotate') | `n' < 2 {
		display as error "n() should be greater or equal to 2."
		exit 198
	}
    if "`start'" == "" local start 0
	
	if "`genx'" 	!= "" local xvar 	 `genx'
	if "`geny'" 	!= "" local yvar 	 `geny'				
	if "`genid'" 	!= "" local idvar 	 `genid'				
	if "`genorder'" != "" local ordervar `genorder'		
	
quietly {	
	
	if "`replace'" != "" {
		cap drop `xvar'
		cap drop `yvar'
		cap drop `idvar'
		cap drop `ordervar'
	}	
	
	cap generate double `xvar' = .
	cap generate double `yvar' = .
	cap generate `idvar' = .
	cap generate `ordervar' = .
	
	
	if "`flip'" != "" local end = `end' * -1
	
	// Calculate the range of angles from the starting angle to the ending angle in radians
    
    local theta_start = (`start' + `rotate') * _pi / 180
    local theta_end   = (`end'   + `rotate') * _pi / 180
	
	
	if "`stack'" != ""  | "`append'" !=""  {
		
		tempvar temp
		gen `temp' = _n if !missing(`ordervar')
		summ `temp', meanonly
		
		if r(N)!= 0 {			
			local start = `=`r(max)' + 1'
			local end   = `=`r(max)' + `n' + 4'
			
			if _N < `=`r(max)'+`n'+4' set obs `end'
		}
		else {
			local start = 1
			local end = `=`n' + 4'
			if _N < `end' set obs `end'
		}
		
	} 
	else {
		local start = 1
		local end = `=`n' + 4'
		if _N < `end' set obs `end'
	}
	
	summ `idvar', meanonly
		
	if `r(N)'==0 {
		local k = 1
	}
	else {
		local k = `r(max)' + 1
	}
	
	replace `idvar' = `k' in  `start'/`end' 	
	
	
	// generate the indices
	tempvar _temp _temp2 _seq _angle
	gen `_temp' = 1
	replace `ordervar' = sum(`_temp') if `idvar'==`k'	
	
	gen `_temp2' = _n	
	
	summ `_temp2' if `idvar'==`k', meanonly
	local end = `end' - 3
	
	tempvar theta
	gen double `theta' = `theta_start' + ((`ordervar'-1) /`n') * (`theta_end' - `theta_start')  in `start'/`end'

	// Calculate the x and y coordinates for this angle
	replace `xvar' = `x0' + `radius' * cos(`theta')  in `start'/`end'
	replace `yvar' = `y0' + `radius' * sin(`theta')  in `start'/`end'
		
	
	if "`dropbase'" == "" {
		// pad the centers
		replace `xvar' = `x0' in `=`end'+1'
		replace `yvar' = `y0' in `=`end'+1'
		
		// pad the starting value
		sum `xvar' if `ordervar'==1 & `idvar'==`k', meanonly
		replace `xvar' = `r(min)' in `=`end'+2'
			
		sum `yvar' if `ordervar'==1 & `idvar'==`k', meanonly
		replace `yvar' = `r(min)' in `=`end'+2'
	}
}
		
end


*****************
***   square  ***
*****************


** rotation taken out. do it this in the second step.

program define _square
 version 15

     syntax, [ x0(numlist max=1) y0(numlist max=1) LENgth(real 10) ROtate(real 0)  ] ///
			[ genx(string) geny(string) genid(string) genorder(string) replace stack append  ]
    if missing(`length', `rotate') | `length' <= 0 {
        display as error "length() must be positive and rotate() must be nonmissing."
        exit 198
    }
 
 
 	// prepare the variables
	local xvar _x
	local yvar _y
	local idvar _id
	local ordervar _order
	local n = 4
	
	// recenter 
	if "`x0'" == "" local x0 = `length' / 2
	if "`y0'" == "" local y0 = `length' / 2	

quietly {	
	if "`genx'" 	!= "" local xvar 	 `genx'
	if "`geny'" 	!= "" local yvar 	 `geny'				
	if "`genid'" 	!= "" local idvar 	 `genid'				
	if "`genorder'" != "" local ordervar `genorder'		
	
	if "`replace'" != "" {
		cap drop `xvar'
		cap drop `yvar'
		cap drop `idvar'
		cap drop `ordervar'
	}		
	

	cap generate double `xvar' = .
	cap generate double `yvar' = .
	cap generate `idvar' = .
	cap generate `ordervar' = .	
	
	if "`stack'" != ""  | "`append'" !=""  {
		tempvar temp
		gen `temp' = _n if !missing(`ordervar')
		summ `temp', meanonly
		
		if r(N)!= 0 {			
			local start = `=`r(max)' + 1'
			local end   = `=`r(max)' + `n' + 2'
			
			if _N < `=`r(max)'+`n'+2' set obs `end'
		}
		else {
			local start = 1
			local end = `=`n' + 2'
			if _N < `end' set obs `end'
		}
		
	} 
	else {
		local start = 1
		local end = `=`n' + 2'
		if _N < `end' set obs `end'
	}
	
	summ `idvar', meanonly
		
	if `r(N)'==0 {
		local k = 1
	}
	else {
		local k = `r(max)' + 1
	}
	
	replace `idvar' = `k' in  `start'/`end' 		
	
	tempvar _temp
	gen `_temp' = 1
	replace `ordervar' = sum(`_temp') if `idvar'==`k'		
	
	
	// add the coordinates
	replace `xvar' = ( `length' / 2) in `start'
	replace `yvar' = ( `length' / 2) in `start'
	
	replace `xvar' = (-`length' / 2) in `=`start' + 1'
	replace `yvar' = ( `length' / 2) in `=`start' + 1'
 
	replace `xvar' = (-`length' / 2) in `=`start' + 2'
	replace `yvar' = (-`length' / 2) in `=`start' + 2' 
	
	replace `xvar' = ( `length' / 2) in `=`start' + 3'
	replace `yvar' = (-`length' / 2) in `=`start' + 3' 	
	
	replace `xvar' = ( `length' / 2) in `=`start' + 4' // duplicate of the first row
	replace `yvar' = ( `length' / 2) in `=`start' + 4' 		
	
	
	replace `yvar' = `yvar' + `y0' in `start' / `=`start' + 4'
	replace `xvar' = `xvar' + `x0' in `start' / `=`start' + 4'
 
 	// rotation
	
	tempvar _mymod _angle
	
	gen `_mymod' = mod(`ordervar', 4)	// index
	recode `_mymod' (0=4)
		
	local rotate = (-45 + `rotate') * _pi / 180  	// compensate for square shape
	gen double `_angle' = (`_mymod' * 2 * _pi / `n') + `rotate' in `start'/`end'	
	
	local _radius = sqrt(2) * `length' / 2
	
	replace `xvar' = `x0' + `_radius' * cos(`_angle')  in `start'/`=`start' + 4'
	replace `yvar' = `y0' + `_radius' * sin(`_angle')  in `start'/`=`start' + 4'	
 
 
}
end 



//////// tranformation functions //////


*****************
***  _rotate  ***
*****************


cap program drop _rotate

program _rotate, sortpreserve

version 15
	
	syntax varlist(numeric min=2 max=2) [if] [in],  [ ROtate(real 0) by(varname) x0(real 0) y0(real 0) replace genx(string) geny(string) center ] 
 
	tokenize `varlist'
	local vary `1'
	local varx `2'
	
	marksample touse, strok novarlist
	
quietly {

	if "`center'" != "" {
		if "`by'" == "" {
			summ `varx' if `touse', meanonly
			local x0 = (`r(min)' + `r(max)') / 2

			summ `vary' if `touse', meanonly
			local y0 = (`r(min)' + `r(max)') / 2
		}
		else {
			tempvar _meanx _meany _minx _miny _maxx _maxy
			sort `by', stable
			
			by `by': egen double `_minx' = min(`varx') if `touse'
			by `by': egen double `_miny' = min(`vary') if `touse'
			
			by `by': egen double `_maxx' = max(`varx') if `touse'
			by `by': egen double `_maxy' = max(`vary') if `touse'
			
			gen double `_meanx' = (`_minx' + `_maxx') / 2 if `touse'
			gen double `_meany' = (`_miny' + `_maxy') / 2 if `touse'

		}
	
	}
	

	local angle = `rotate' * _pi / 180

    
	local xvar _x_rot // default names
	local yvar _y_rot	
	
	if "`genx'" 	!= "" local xvar  `genx'
	if "`geny'" 	!= "" local yvar  `geny'				

	
	tempvar _x0 _y0 x_rot_t y_rot_t
	
	if "`by'" != "" & "`center'" != "" {
		local x0 `_meanx'
		local y0 `_meany'
	}
	
		
	gen double `_x0' = `varx' - `x0' if `touse'
	gen double `_y0' = `vary' - `y0' if `touse'
		
	gen double `x_rot_t' = `_x0' * cos(`angle') - `_y0' * sin(`angle') if `touse'
	gen double `y_rot_t' = `_x0' * sin(`angle') + `_y0' * cos(`angle') if `touse'
		
	if "`replace'" != "" {  // here replace is replacing the original variables. use carefully.
		replace `varx' = `x_rot_t' + `x0' if `touse'
		replace `vary' = `y_rot_t' + `y0' if `touse'
	}
	else {
		*cap drop `xvar'
		*cap drop `yvar'
		
		generate double `xvar' = `x_rot_t' + `x0' if `touse'
		generate double `yvar' = `y_rot_t' + `y0' if `touse'
	}
	

}	
	
end



******************
***  _stretch  ***
******************


cap program drop _stretch

program _stretch, sortpreserve

version 15

	
	syntax varlist(numeric min=2 max=2) [if] [in],  [ x(numlist max=1 >0) y(numlist max=1 >0) replace ] 
 
 
	marksample touse, strok novarlist
 
 
 quietly {
	tokenize `varlist'
	local vary `1'
	local varx `2'
	
	if "`x'" == "" local x = 1
	if "`y'" == "" local y = 1

	replace `vary' = `vary' * (`y') if `touse'
	replace `varx' = `varx' * (`x') if `touse'
}
	

end

*****************
***   _area   ***  // apply the Meister's shoelace formula (shoelace formula: https://en.wikipedia.org/wiki/Shoelace_formula)
*****************

cap program drop _area

program _area, sortpreserve


version 15
	syntax varlist(numeric min=2 max=2), [by(varname) replace GENerate(name)]
	
	tokenize `varlist'
	local y `1'
	local x `2'	
	
quietly {	
	local myvar _area
	
	if "`generate'" != "" local myvar `generate'
    local inputs `varlist' `by'
    local overlap : list myvar & inputs
    if "`overlap'" != "" {
        noisily display as error "Area output must not overwrite input variables."
        exit 198
    }
    if "`replace'" == "" confirm new variable `myvar'
    tempvar sequence group valid rank firstx firsty last values result
    generate long `sequence' = _n
    if "`by'" == "" {
        generate byte `group' = 1
        local by `group'
    }
    sort `by' `sequence'
    generate byte `valid' = !missing(`x', `y')
    by `by': generate long `rank' = sum(`valid')
    by `by': egen double `firstx' = max(cond(`valid' & `rank' == 1, `x', .))
    by `by': egen double `firsty' = max(cond(`valid' & `rank' == 1, `y', .))
    by `by': egen long `last' = max(cond(`valid', `rank', .))
    // Place separators after vertices without changing their drawing order.
    sort `by' `valid' `sequence'
    by `by': generate double `values' = ///
        (`x' * `y'[_n+1] - `x'[_n+1] * `y') / 2 if `valid'
    replace `values' = (`x' * `firsty' - `firstx' * `y') / 2 ///
        if `valid' & `rank' == `last'
    by `by': egen double `result' = total(`values')
    replace `result' = abs(`result') if `last' >= 3
    replace `result' = . if missing(`last') | `last' < 3
    if "`replace'" != "" {
        capture confirm variable `myvar'
        if !_rc drop `myvar'
    }
    rename `result' `myvar'
}
	
end


******************
***   _round   *** edge rounding
******************

cap program drop _round


program _round, sortpreserve

	version 15
	syntax varlist(numeric min=2 max=2) [if] [in], Roundness(numlist max=1 >0) [ n(integer 20) Factor(real 1.3) genx(name) geny(name) genid(name) genorder(name) gensegvar(name) replace stack append ]
    if missing(`n', `factor') | `n' < 5 | `factor' <= 0 | `factor' > 2 {
        display as error "n() must be at least 5; factor() must be in (0,2]."
        exit 198
    }

	tokenize `varlist'
	local vary `1'
	local varx `2'		
	
	local xvar 		_rx
	local yvar 		_ry
	local idvar 	_rid
	local ordervar 	_rorder
	local segvar	_segvar
	
	if "`genx'" 		!= "" local xvar 	 `genx'
	if "`geny'" 		!= "" local yvar 	 `geny'				
	if "`genid'" 		!= "" local idvar 	 `genid'				
	if "`genorder'" 	!= "" local ordervar `genorder'				
	if "`gensegvar'" 	!= "" local segvar 	 `gensegvar'
    local outputs `xvar' `yvar' `idvar' `ordervar' `segvar'
    local unique : list uniq outputs
    local overlap : list outputs & varlist
    if wordcount("`unique'") != 5 | "`overlap'" != "" {
        display as error "Output names must be distinct and different from input variables."
        exit 198
    }
    marksample touse
    quietly count if `touse'
    if r(N) < 4 {
        display as error "At least four complete points of a closed polygon are required."
        exit 2001
    }
	
quietly {	
	
	if "`replace'" != "" {
		cap drop `xvar'
		cap drop `yvar'
		cap drop `idvar'
		cap drop `ordervar'
		cap drop `segvar'
	}	

	cap generate double 	 `xvar' = .
	cap generate double 	 `yvar' = .
	cap generate 			`idvar' = .
	cap generate		   `segvar' = .
	cap generate 		 `ordervar' = .
	
	
	// segmentize and shorten
	count if !missing(`varx') & `touse'==1
	local last = `r(N)' - 1
	
	count if !missing(`idvar')
	
    local needed = r(N) + `last' * 3
    if _N < `needed' set obs `needed'
	
	local counter = 1 
	
    tempvar counter
    generate long `counter' = sum(`touse') if `touse' == 1
	
	
	forval i = 1/`last' {
	
	
		*** ending point of segment1 ***
		local start = `=`i'+0'
		local end 	= `=`i'+1'	
		
		// seg start //
		summ `vary' if `counter' == `start', meanonly
		local y0 = r(min)
		summ `varx' if `counter' == `start', meanonly
		local x0 = r(min)
		

		// seg end //
		summ `vary' if `counter' == `end', meanonly
		local y1 = r(min)
		summ `varx' if `counter' == `end', meanonly
		local x1 = r(min)
		
		
		// segment //
		local dx = `x1' - `x0'
		local dy = `y1' - `y0'
		local L  = sqrt((`dx')^2 + (`dy')^2)
		local s  = abs(`roundness') / `L'
		
		local arcx0 = `x1' - (`s' * `dx')
		local arcy0 = `y1' - (`s' * `dy')
		
		if `i' == 1 {
			local startx = `arcx0'
			local starty = `arcy0'
		}		
		
		
		*** starting point of segment1 ***
		local start = `=`i'+1'
		local end 	= `=`i'+2'	
		
		if `i' == `last' {
			local start = 1
			local end 	= 2
		}
		
	
		// seg start //
		summ `vary' if `counter' == `start', meanonly
		local y0 = r(min)
		summ `varx' if `counter' == `start', meanonly
		local x0 = r(min)
		

		// seg end //
		summ `vary' if `counter' == `end', meanonly
		local y1 = r(min)
		summ `varx' if `counter' == `end', meanonly
		local x1 = r(min)
		
		
		// segment //
		local dx = `x1' - `x0'
		local dy = `y1' - `y0'
		local L  = sqrt((`dx')^2 + (`dy')^2)
		local s  = abs(`roundness') / `L'
		
		local arcx1 = `x0' + (`s' * `dx')
		local arcy1 = `y0' + (`s' * `dy')		
		
	
	// generate arc segments
	
	*** arc start ***
	
		local rad = sqrt((`arcx1' - `arcx0')^2 + (`arcy1' - `arcy0')^2) / `factor'

		// get the mid point
		summ `vary', meanonly
		local midy = r(mean)
		
		summ `varx', meanonly
		local midx = r(mean)
		

		// mark the orientation
		local side = (`arcx1' - `arcx0') * (`midy' - `arcy0') - (`arcy1' - `arcy0') * (`midx' - `arcx0')
		
		// orientation is now always assumed convex
		arc, x1(`arcx0') y1(`arcy0') x2(`arcx1') y2(`arcy1') n(`n') rad(`rad') genx(`xvar') geny(`yvar') genid(`segvar') genorder(`ordervar') append dropbase

		
		
	}
	
	
	// append last segment with base
		
	qui count if !missing(`ordervar')
	local maxobs = r(N)
    if _N < `maxobs' + 2 set obs `=`maxobs' + 2'
	
	replace `xvar'     = `startx'   in `=`maxobs' + 1' 
	replace `yvar'     = `starty'   in `=`maxobs' + 1'
	
	summ `segvar', meanonly
	local lastval = `r(max)' + 1
	
	replace `segvar'   = `lastval'	 	in `=`maxobs' + 1' 
	replace `segvar'   = `lastval' 	 	in `=`maxobs' + 2'
	replace `ordervar' = 1 				in `=`maxobs' + 1'
	replace `ordervar' = 2 				in `=`maxobs' + 2'
	
	

	
	summ `idvar', meanonly
	if r(N) == 0 {
		replace `idvar' = 1 if missing(`idvar') & !missing(`segvar')
	}
	else {
		replace `idvar' = r(max) + 1 if missing(`idvar')  & !missing(`segvar') 
	}
	

}
	
end

**********************
***   _translate   *** 
**********************

cap program drop _translate

program _translate, sortpreserve

	version 15
	syntax varlist(numeric min=2 max=2) [if] [in], [ x(numlist max=1) y(numlist max=1) genx(string) geny(string) replace   ] 

	tokenize `varlist'
	local vary `1'
	local varx `2'		
	
	local xvar 		_x
	local yvar 		_y
	local idvar 	_id
	local ordervar 	_order

	
	if "`genx'" 	!= "" local xvar 	 `genx'
	if "`geny'" 	!= "" local yvar 	 `geny'				
	if "`genid'" 	!= "" local idvar 	 `genid'				
	if "`genorder'" != "" local ordervar `genorder'				
	

quietly {	
	if "`replace'" != "" {
		local xvar `varx'
		local yvar `vary'
	}	
	else {
		cap generate double `xvar' 	= .
		cap generate double `yvar' 	= .
		cap generate `idvar' 		= .
		cap generate `ordervar' 	= .
	}
	
	
	
	marksample touse, strok novarlist
	
	// translate x
	if "`x'" != "" {
		replace `xvar' = `varx' + `x'	if `touse'
	}
	else {
		replace `xvar' = `varx'			if `touse'
	}
	
	// translate y
	if "`y'" != "" {
		replace `yvar' = `vary' + `y'  	if `touse'
	}
	else {
		replace `yvar' = `vary'			if `touse'
	}
		
}		
	

end

*******************
***   _dilate   *** 
*******************

capture program drop _dilate

program define _dilate
    version 15

    syntax varlist(min=2 max=2 numeric) [if] [in], [ Factor(numlist max=1) genx(string) geny(string)  replace]

    // Parse inputs
	tokenize `varlist'
	local vary `1'
	local varx `2'		
	
	local xvar 	_dx
	local yvar 	_dy

quietly {	
	if "`genx'" 	!= "" local xvar 	 `genx'
	if "`geny'" 	!= "" local yvar 	 `geny'				
	
	
	if "`replace'" != "" {
		local xvar `varx'
		local yvar `vary'
	}	
	else {
		cap generate double `xvar' = .
		cap generate double `yvar' = .
	}	
	
	
	marksample touse, strok novarlist

	replace `xvar' = `varx' * `factor' 	if `touse'
	replace `yvar' = `vary' * `factor' 	if `touse'
}		
       
end




*********************************
******** END OF PROGRAM *********
*********************************

