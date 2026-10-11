*program drop ages
qui program ages, eclass
version 13.0:

	syntax varlist (fv ts) [if] [in], Varname(string) Groups(string) np(integer) [Method(string) /*
	*/lagpol(integer 0) inter(string) bylag Factor(real 1) save(string) /*
	*/NOIsily conf(numlist max=2 integer) nograph LColor(string) LC0(string) LC1(string) TItle(string) LABel(string) LAB0(string) LAB1(string)/*
	*/TTItle(string asis) legend(string) Zero GRName(string) GRSave(string) as(string) GROpt(string) tlabel(string) predict * ]

*********************************************************************************************************************************************
*********************************************************************************************************************************************
*********************************************************************************************************************************************
*********************************************************************************************************************************************
capture tsset
if _rc>0 {
	di as err "time/panel variables not set, use tsset/xtset ..."
	exit 0003
}
loc panvar=r(panelvar)
loc timevar=r(timevar)
loc tform=r(unit1)
loc tunit=r(unit)

if "`panvar'"=="." {
	loc panvar _id_
	capture qui gen _id_=1
	if "`tunit'"=="0"|"`tunit'"=="." |"`tunit'"=="per : "" 0" qui xtset _id_ `timevar'
	else qui xtset _id_ `timevar', `tunit'
}
if "`panvar'"=="_id_" & "`method'"=="" loc method reg
else if "`method'"=="" loc method xtreg

*********************************************************************************************************************************************
*********************************************************************************************************************************************

loc nconf = wordcount("`conf'")
if `nconf'==0 loc conf=95
else if `nconf'>1 {
	tokenize `conf'
	loc conf "`1'"
	loc conf2 "`2'"
	if `conf2'<`conf' {
		loc conft `conf'
		loc conf `conf2'
		loc conf2 `conft'
	}
}

*********************************************************************************************************************************************
*********************************************************************************************************************************************

tokenize `varlist'
loc y "`1'"
macro shift 1
loc c "`*'"

tokenize `varname'
loc v1 "`1'"
loc v2 "`2'"

loc h=0
foreach g of local groups {
loc ++h
}

if "`inter'"=="" tempvar gr imp se up lo _zero up2 lo2
else tempvar gr imp0 se0 up0 lo0 _zero up02 lo02 imp1 se1 up1 lo1 up12 lo12
gen `gr'=_n
cap label drop groups


if "`inter'"=="" {
	qui gen `imp' = 0 if _n<=`h'
	qui gen `se' = 0 if _n<=`h'
	qui gen `up' = 0 if _n<=`h'
	qui gen `lo' = 0 if _n<=`h'
	if `nconf'>1 {
		qui gen `up2' = 0 if _n<=`h'
		qui gen `lo2' = 0 if _n<=`h'
	}
}

else {
	qui gen `imp0' = 0 if _n<=`h'
	qui gen `se0' = 0 if _n<=`h'
	qui gen `up0' = 0 if _n<=`h'
	qui gen `lo0' = 0 if _n<=`h'
	if `nconf'>1 {
		qui gen `up02' = 0 if _n<=`h'
		qui gen `lo02' = 0 if _n<=`h'
	}
	qui gen `imp1' = 0 if _n<=`h'
	qui gen `se1' = 0 if _n<=`h'
	qui gen `up1' = 0 if _n<=`h'
	qui gen `lo1' = 0 if _n<=`h'
	if `nconf'>1 {
		qui gen `up12' = 0 if _n<=`h'
		qui gen `lo12' = 0 if _n<=`h'
	}
}
qui {
	loc pols
	forval i=1/`np' {
		loc pols `pols' pol`i'
		loc k=0
		cap drop pol`i'
		qui gen pol`i'=0
		foreach g of local groups {
			loc ++k
			qui replace pol`i'=pol`i'+(`k'^`i')*`v1'`g'`v2' - (`k'^`i')/`h'
		}	
	}
	if `lagpol'>0 loc lpols L(1/`lagpol').(`pols')

	tokenize `groups'

	if "`inter'"=="" `noisily' `method' `y' `pols' `lpols' `c' `if' `in' [`weight'`exp'], `options'
	else `noisily' `method' `y' `inter'#c.(`pols' `lpols') `c' `if' `in' [`weight'`exp'], `options'
	mat V = e(V)
	matrix beta = e(b)
	local nvar = colsof(beta)
	if e(df_m)!=. local df=e(df_m)
	else local df=e(N)-nvar

	if "`inter'"=="" {
		
		if `lagpol'>0 {
			forval i=1/`np' {
				matrix a`i' = J(1, `nvar', 0)
				local cpol`i' = colnumb(beta, "pol`i'")
				matrix a`i'[1, `cpol`i''] = 1
				forval lp=1/`lagpol' {
					local c`lp'pol`i' = colnumb(beta, "L`lp'.pol`i'")
					matrix a`i'[1, `c`lp'pol`i''] = 1
				}
			}

			matrix VB = J(`np',`np',.)
			forval i=1/`np' {
				forval j=1/`np' {
					matrix VB[`i',`j'] = a`i'*V*a`j''
				}	
			}
				forval i=1/`np' {
					scalar p`i'=_b[pol`i']
					forval lp=1/`lagpol' {
					scalar p`i'=p`i'+_b[L`lp'.pol`i']
					}
				}			
		}
		
		else if `lagpol'==0 {
			matrix VB = J(`np',`np',.)
			forval i=1/`np' {
				forval j=1/`np' {
					matrix VB[`i',`j'] = V[rownumb(V,"pol`i'"),colnumb(V,"pol`j'")]
				}	
			}
			forval i=1/`np' {
				scalar p`i'=_b[pol`i']
			}
		}

		scalar p0=0
		forval k=1/`h' {
			forval p=1/`np' {
				scalar p0=p0-p`p'*((`k'^`p')/`h')
			}
		}
		matrix B = J(`h',`np',.)

		forval k=1/`h' {
			scalar b`k'=0
			forval p=0/`np' {
				scalar b`k'=b`k'+p`p'*(`k'^`p')
			}
		}

		forval p=1/`np' {
			scalar f`p'= 0
		}
		forval k=1/`h' {
			forval p=1/`np' {
				scalar f`k'`p'= 0
			}
		}

		forval k=1/`h' {
			forval p=1/`np' {
				scalar f`k'`p'=(`k'^`p')/`h'
			}
		}
		forval p=1/`np' {
			forval k=1/`h' {
				scalar f`p'=f`p'+f`k'`p'
			}
		}

		forval k=1/`h' {
			forval p=1/`np' {
				mat B[`k',`p'] = `k'^`p'-f`p'
			}
		}

		mat VBB=B*VB*B'

		forval l=0/`lagpol' {
			matrix gamma`l' = J(1,`np',.)
			forval p=1/`np' {
				mat gamma`l'[1,`p'] = _b[l`l'.pol`p']
			}
			mat B1`l'=B*gamma`l''
			matrix VB`l' = J(`np',`np',.)
			if `l'==0 {
				forval i=1/`np' {
					forval j=1/`np' {
						matrix VB`l'[`i',`j'] = V[rownumb(V,"pol`i'"),colnumb(V,"pol`j'")]
					}	
				}
			}
			else {
				forval i=1/`np' {
					forval j=1/`np' {
						matrix VB`l'[`i',`j'] = V[rownumb(V,"l`l'.pol`i'"),colnumb(V,"l`l'.pol`j'")]
					}	
				}
			}
			mat VBB`l' = B*VB`l'*B'
			if `nconf'>1 mat agesbl`l' = J(`h',8,.)
			else mat agesbl`l' = J(`h',6,.)
			forval k=1/`h' {
				scalar b`l'_`k'=B1`l'[`k',1]
				scalar se`l'_`k'=VBB`l'[`k',`k']^(1/2)
				scalar t`l'_`k'=(b`l'_`k')/(se`l'_`k')
				scalar pval`l'_`k'= (1-t(`df',abs(t`l'_`k')))*2
				scalar up`l'_`k'=b`k'+invt(`df',1-(1-`conf'/100)/2)*se`l'_`k'
				scalar lo`l'_`k'=b`k'-invt(`df',1-(1-`conf'/100)/2)*se`l'_`k'
				if `nconf'>1 {
					scalar up2`k'=b`k'+invt(`df',1-(1-`conf2'/100)/2)*se`k'
					scalar lo2`k'=b`k'-invt(`df',1-(1-`conf2'/100)/2)*se`k'
				}
				matrix agesbl`l'[`k',1]=`factor'*B1`l'[`k',1]
				matrix agesbl`l'[`k',2]=`factor'*VBB`l'[`k',`k']^(1/2)
				matrix agesbl`l'[`k',3]=t`l'_`k'
				matrix agesbl`l'[`k',4]=pval`l'_`k'
				matrix agesbl`l'[`k',5]=`factor'*up`l'_`k'
				matrix agesbl`l'[`k',6]=`factor'*lo`l'_`k'
				if `nconf'>1 {
					matrix agesbl`l'[`k',7]=`factor'*lo2`k'
					matrix agesbl`l'[`k',8]=`factor'*up2`k'				
				}
			}
		}
		
		if `nconf'>1 mat agesb = J(`h',8,.)
		else mat agesb = J(`h',6,.)

		local labels
		local namegroups
		forval k=1/`h' {
			scalar se`k'=VBB[`k',`k']^(1/2)
			scalar t`k'=b`k'/se`k'
			scalar pval`k'= (1-t(`df',abs(t`k')))*2
			scalar up`k'=b`k'+invt(`df',1-(1-`conf'/100)/2)*se`k'
			scalar lo`k'=b`k'-invt(`df',1-(1-`conf'/100)/2)*se`k'
			if `nconf'>1 {
				scalar up2`k'=b`k'+invt(`df',1-(1-`conf2'/100)/2)*se`k'
				scalar lo2`k'=b`k'-invt(`df',1-(1-`conf2'/100)/2)*se`k'
			}
			matrix agesb[`k',1]=`factor'*b`k'
			matrix agesb[`k',2]=`factor'*se`k'
			matrix agesb[`k',3]=t`k'
			matrix agesb[`k',4]=pval`k'
			matrix agesb[`k',5]=`factor'*lo`k'
			matrix agesb[`k',6]=`factor'*up`k'
			if `nconf'>1 {
				matrix agesb[`k',7]=`factor'*lo2`k'
				matrix agesb[`k',8]=`factor'*up2`k'				
			}
			replace `imp'=`factor'*b`k' in `k'
			replace `se'=`factor'*se`k' in `k'
			replace `lo'=`factor'*lo`k' in `k'
			replace `up'=`factor'*up`k' in `k'
			if `nconf'>1 {
				replace `lo2'=`factor'*lo2`k' in `k'
				replace `up2'=`factor'*up2`k' in `k'
			}
			loc kk = regexr("``k''","_","-")
			local labels `labels' `k' "`kk'"
			local namegroups `namegroups' "`kk' "
		}
		matrix rownames agesb = `namegroups'
		if `nconf'>1 matrix colnames agesb = "Coefficient" "Std. err." "t" "P>|t|" "[`conf'% conf." "interval]" "[`conf2'% conf." "interval]"
		else matrix colnames agesb = "Coefficient" "Std. err." "t" "P>|t|" "[`conf'% conf." "interval]"
		if `lagpol'==0 noisily matlist agesb, format(%9.5f) title("Estimated coefficients by Age Groups") lines(oneline) aligncolnames(center)
		else noisily matlist agesb, format(%9.5f) title("Estimated coefficients by Age Groups, Sum of All Lags") lines(oneline) aligncolnames(center)
		
		forval l=0/`lagpol' {
			matrix rownames agesbl`l' = `namegroups'
			if `nconf'>1 matrix colnames agesbl`l' = "Coefficient" "Std. err." "t" "P>|t|" "[`conf'% conf." "interval]" "[`conf2'% conf." "interval]"
			else matrix colnames agesbl`l' = "Coefficient" "Std. err." "t" "P>|t|" "[`conf'% conf." "interval]"
			if "`bylag'"=="bylag" noisily matlist agesbl`l', format(%9.5f) title("Estimated coefficients by Age Groups, Lag=`l'") lines(oneline) aligncolnames(center)			
		}

	}	
	************************************************************************************************************************************
	/* Interactions */
	************************************************************************************************************************************
	
	else {
		
		matrix VB0 = J(`np',`np',.)
		forval i=1/`np' {
			forval j=1/`np' {
				matrix VB0[`i',`j'] = V[rownumb(V,"0.`inter'#c.pol`i'"),colnumb(V,"0.`inter'#c.pol`j'")]
			}	
		}

		forval i=1/`np' {
			scalar p`i'=_b[0.`inter'#c.pol`i']
		}

		scalar p0=0
		forval k=1/`h' {
			forval p=1/`np' {
				scalar p0=p0-p`p'*((`k'^`p')/`h')
			}
		}

		matrix B0 = J(`h',`np',.)

		forval k=1/`h' {
			scalar b`k'=0
			forval p=0/`np' {
				scalar b`k'=b`k'+p`p'*(`k'^`p')
			}
		}

		forval p=1/`np' {
			scalar f`p'= 0
		}
		forval k=1/`h' {
			forval p=1/`np' {
				scalar f`k'`p'= 0
			}
		}

		forval k=1/`h' {
			forval p=1/`np' {
				scalar f`k'`p'=(`k'^`p')/`h'
			}
		}
		forval p=1/`np' {
			forval k=1/`h' {
				scalar f`p'=f`p'+f`k'`p'
			}
		}

		forval k=1/`h' {
			forval p=1/`np' {
				mat B0[`k',`p'] = `k'^`p'-f`p'
			}
		}

		mat VBB0=B0*VB0*B0'
		
		if `nconf'>1 mat agesb0 = J(`h',8,.)
		else mat agesb0 = J(`h',6,.)
		
		local labels
		local namegroups
		forval k=1/`h' {
			scalar se`k'=VBB0[`k',`k']^(1/2)
			scalar se`k'=se`k'
			scalar t`k'=b`k'/se`k'
			scalar pval`k'= (1-t(`df',abs(t`k')))*2
			scalar up`k'=b`k'+invt(`df',1-(1-`conf'/100)/2)*se`k'
			scalar lo`k'=b`k'-invt(`df',1-(1-`conf'/100)/2)*se`k'
			if `nconf'>1 {
				scalar up2`k'=b`k'+invt(`df',1-(1-`conf2'/100)/2)*se`k'
				scalar lo2`k'=b`k'-invt(`df',1-(1-`conf2'/100)/2)*se`k'
			}
			matrix agesb0[`k',1]=`factor'*b`k'
			matrix agesb0[`k',2]=`factor'*se`k'
			matrix agesb0[`k',3]=t`k'
			matrix agesb0[`k',4]=pval`k'
			matrix agesb0[`k',5]=`factor'*lo`k'
			matrix agesb0[`k',6]=`factor'*up`k'
			if `nconf'>1 {
				matrix agesb0[`k',7]=`factor'*lo2`k'
				matrix agesb0[`k',8]=`factor'*up2`k'			
			}
			replace `imp0'=`factor'*b`k' in `k'
			replace `lo0'=`factor'*lo`k' in `k'
			replace `up0'=`factor'*up`k' in `k'
			if `nconf'>1 {
				replace `lo02'=`factor'*lo2`k' in `k'
				replace `up02'=`factor'*up2`k' in `k'
			}
			loc kk = regexr("``k''","_","-")
			local labels `labels' `k' "`kk'"
			local namegroups `namegroups' "`kk' "
		}
		matrix rownames agesb0 = `namegroups'
		if `nconf'>1  matrix colnames agesb0 = "Coefficient" "Std. err." "t" "P>|t|" "[`conf'% conf." "interval]" "[`conf2'% conf." "interval]"
		else  matrix colnames agesb0 = "Coefficient" "Std. err." "t" "P>|t|" "[`conf'% conf." "interval]"
		noisily matlist agesb0, format(%9.5f) title("Estimated coefficients by Age Groups, `inter' = 0") lines(oneline) aligncolnames(center)
		
		
		matrix VB1 = J(`np',`np',.)
		forval i=1/`np' {
			forval j=1/`np' {
				matrix VB1[`i',`j'] = V[rownumb(V,"1.`inter'#c.pol`i'"),colnumb(V,"1.`inter'#c.pol`j'")]
			}	
		}

		forval i=1/`np' {
			scalar p`i'=_b[1.`inter'#c.pol`i']
		}

		scalar p0=0
		forval k=1/`h' {
			forval p=1/`np' {
				scalar p0=p0-p`p'*((`k'^`p')/`h')
			}
		}

		matrix B1 = J(`h',`np',.)

		forval k=1/`h' {
			scalar b`k'=0
			forval p=0/`np' {
				scalar b`k'=b`k'+p`p'*(`k'^`p')
			}
		}

		forval p=1/`np' {
			scalar f`p'= 0
		}
		forval k=1/`h' {
			forval p=1/`np' {
				scalar f`k'`p'= 0
			}
		}

		forval k=1/`h' {
			forval p=1/`np' {
				scalar f`k'`p'=(`k'^`p')/`h'
			}
		}
		forval p=1/`np' {
			forval k=1/`h' {
				scalar f`p'=f`p'+f`k'`p'
			}
		}

		forval k=1/`h' {
			forval p=1/`np' {
				mat B1[`k',`p'] = `k'^`p'-f`p'
			}
		}

		mat VBB1=B1*VB1*B1'
		
		if `nconf'>1 mat agesb1 = J(`h',8,.)
		else mat agesb1 = J(`h',6,.)

		local labels
		local namegroups
		forval k=1/`h' {
			scalar se`k'=VBB1[`k',`k']^(1/2)
			scalar se`k'=se`k'
			scalar t`k'=b`k'/se`k'
			scalar pval`k'= (1-t(`df',abs(t`k')))*2
			scalar up`k'=b`k'+invt(`df',1-(1-`conf'/100)/2)*se`k'
			scalar lo`k'=b`k'-invt(`df',1-(1-`conf'/100)/2)*se`k'
			if `nconf'>1 {
				scalar up2`k'=b`k'+invt(`df',1-(1-`conf2'/100)/2)*se`k'
				scalar lo2`k'=b`k'-invt(`df',1-(1-`conf2'/100)/2)*se`k'
			}
			matrix agesb1[`k',1]=b`k'
			matrix agesb1[`k',2]=se`k'
			matrix agesb1[`k',3]=t`k'
			matrix agesb1[`k',4]=pval`k'
			matrix agesb1[`k',5]=lo`k'
			matrix agesb1[`k',6]=up`k'
			if `nconf'>1 {
				matrix agesb1[`k',7]=`factor'*lo2`k'
				matrix agesb1[`k',8]=`factor'*up2`k'			
			}
			
		
			replace `imp1'=b`k' in `k'
			replace `lo1'=lo`k' in `k'
			replace `up1'=up`k' in `k'
			if `nconf'>1 {
				replace `lo12'=lo2`k' in `k'
				replace `up12'=up2`k' in `k'
			}
			loc kk = regexr("``k''","_","-")
			local labels `labels' `k' "`kk'"
			local namegroups `namegroups' "`kk' "
		}
		matrix rownames agesb1 = `namegroups'
		if `nconf'>1  matrix colnames agesb1 = "Coefficient" "Std. err." "t" "P>|t|" "[`conf'% conf." "interval]" "[`conf2'% conf." "interval]"
		else  matrix colnames agesb1 = "Coefficient" "Std. err." "t" "P>|t|" "[`conf'% conf." "interval]"
		noisily matlist agesb1, format(%9.5f) title("Estimated coefficients by Age Groups, `inter' = 1") lines(oneline) aligncolnames(center)
	}	

}


*********************************************************************************************************************************************
*********************************************************************************************************************************************

if "`zero'"=="zero" qui gen `_zero' = 0
else qui gen `_zero' = .

if "`inter'"=="" {
	if "`label'"=="" loc off off
	else lab var `imp' "`label'"

	if "`graph'"!="nograph" {
		
		if "`lcolor'"=="" loc lcolor blue
		if `nconf'>1 {
			if "`legend'"=="" loc legend `off' order(4) position(6)
			else loc legend `legend' `off' order(4) position(6) 

			qui twoway (rarea `up2' `lo2' `gr', fcolor(`lcolor'%15) lc(`lcolor'%7)) ///
			(rarea `up' `lo' `gr', fcolor(`lcolor'%30) lc(`lcolor'%15)) ///
			(line `_zero' `gr', lcolor(gs5) lpattern(dash)) ///
			(line `imp' `gr', lcolor(`lcolor') lpattern(solid)) if _n>=1 & _n<=`h', ///
			legend(`legend') xtitle("") xlabel(`labels', angle(45)) name(`grname', replace) title(`title') `gropt'
		}
		else {
			if "`legend'"=="" loc legend `off' order(3) position(6)
			else loc legend `legend' `off' order(3) position(6) 
			
			qui twoway (rarea `up' `lo' `gr', fcolor(`lcolor'%15) lc(`lcolor'%7)) ///
			(line `_zero' `gr', lcolor(gs5) lpattern(dash)) ///
			(line `imp' `gr', lcolor(`lcolor') lpattern(solid)) if _n>=1 & _n<=`h', ///
			legend(`legend') xtitle("") xlabel(`labels', angle(45)) name(`grname', replace) title(`title') `gropt'

		}
	}
}

else {
	if "`lab0'"=="" label var `imp0' "Effect when `inter' = 0"
	else label var `imp0' "`lab0'"
	if "`lab1'"=="" label var `imp1' "Effect when `inter' = 1"
	else label var `imp1' "`lab1'"

	if "`graph'"!="nograph" {
		
		if "`lc0'"=="" loc lc0 blue
		if "`lc1'"=="" loc lc1 green
		if `nconf'>1 {
			if "`legend'"=="" loc legend `off' order(6 7) position(6)
			else loc legend `legend' `off' order(6 7) position(6) 

			qui twoway (rarea `up02' `lo02' `gr', fcolor(`lc0'%15) lcolor(`lc0'%7)) ///
			(rarea `up0' `lo0' `gr', fcolor(`lc0'%30) lcolor(`lc0'%15)) ///
			(rarea `up12' `lo12' `gr', fcolor(`lc1'%15) lcolor(`lc1'%7)) ///
			(rarea `up1' `lo1' `gr', fcolor(`lc1'%30) lcolor(`lc1'%15)) ///			
			(line `_zero' `gr', lc(gs5) lpattern(dash)) ///
			(line `imp0' `gr', lc(`lc0') lpattern(solid)) ///
			(line `imp1' `gr', lc(`lc1') lpattern(solid)) if _n>=1 & _n<=`h', ///
			legend(`legend') xtitle("") xlabel(`labels', angle(45)) name(`grname', replace) title(`title') `gropt'

		}
		else {
			if "`legend'"=="" loc legend `off' order(4 5) position(6)
			else loc legend `legend' `off' order(4 5) position(6) 

			qui twoway (rarea `up0' `lo0' `gr', fcolor(`lc0'%15) lcolor(`lc0'%7)) ///
			(rarea `up1' `lo1' `gr', fcolor(`lc1'%15) lcolor(`lc1'%7)) ///
			(line `_zero' `gr', lcolor(gs5) lpattern(dash)) ///
			(line `imp0' `gr', lcolor(`lc0') lpattern(solid)) ///
			(line `imp1' `gr', lcolor(`lc1') lpattern(solid)) if _n>=1 & _n<=`h', ///
			legend(`legend') xtitle("") xlabel(`labels', angle(45)) name(`grname', replace) title(`title') `gropt'
		}
	}
}
if "`grsave'"!="" {
	if "`as'"=="" graph save "`grsave'.gph", replace
	else graph export "`grsave'.`as'", as(`as') replace
}
*********************************************************************************************************************************************
*********************************************************************************************************************************************

if "`save'"!="" {
	if "`inter'"=="" {
		cap drop `save'
		foreach d in _se _up _lo _up2 _lo2 {
			cap drop `save'`d' 
		}
		qui gen `save' = `imp'
		qui gen `save'_se = `se'
		qui gen `save'_up = `up'
		qui gen `save'_lo = `lo'
		if `nconf'>1 {
			qui gen `save'_up2 = `up2'
			qui gen `save'_lo2 = `lo2'
		}
		label var `save' "`label'"	
	}	
	else {
		cap drop `save'0 `save'0_se `save'0_up `save'0_lo
		cap drop `save'0_up2 `save'0_lo2
		qui gen `save'0 = `imp0'
		qui gen `save'0_se = `se0'
		qui gen `save'0_up = `up0'
		qui gen `save'0_lo = `lo0'
		if `nconf'>1 {
			qui gen `save'0_up2 = `up02'
			qui gen `save'0_lo2 = `lo02'
		}
		label var `save'0 "`label'"	
		
		cap drop `save'1 `save'1_se `save'1_up `save'1_lo
		cap drop `save'1_up2 `save'1_lo2
		qui gen `save'1 = `imp1'
		qui gen `save'1_se = `se1'
		qui gen `save'1_up = `up1'
		qui gen `save'1_lo = `lo1'
		if `nconf'>1 {
			qui gen `save'1_up2 = `up12'
			qui gen `save'1_lo2 = `lo12'
		}
		label var `save'1 "`label'"	
	}	
}
*********************************************************************************************************************************************
*********************************************************************************************************************************************

if "`panvar'"=="_id_" {
	qui drop _id_
	qui tsset `timevar'
}

if "`inter'"=="" ereturn matrix ages agesb 
else {
	if `nconf'>1  matrix colnames agesb0 = "b" "se" "t" "pvalue" "ll1" "ul1" "ll2" "ul2"
	else  matrix colnames agesb1 = "b" "se" "t" "pvalue" "ll" "ul"
	if `nconf'>1  matrix colnames agesb1 = "b" "se" "t" "pvalue" "ll1" "ul1" "ll2" "ul2"
	else  matrix colnames agesb1 = "b" "se" "t" "pvalue" "ll" "ul"

	ereturn matrix ages0 agesb0
	ereturn matrix ages1 agesb1		
} 
		
end