*! version 0.21 2026-03-26 Niels Henrik Bruun	
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2026-10-28 v0.21 Bugfix in bapm
*! 2026-03-26 v0.2 created
program define bapm, rclass
	version 15.1
	
	syntax varlist(min=3 max=6 numeric) [if], /*
	*/[ /*
		*/Graph /*
		*/Name(passthru) /*
		*/size(passthru) /*
		*/Formatgraph(passthru) /*
		*/Text(passthru) /*
		*/Scatterstyle(passthru) /*
		*/MEANLinestyle(passthru) /*
		*/MEANCIstyle(passthru) /*
		*/LOALinestyle(passthru) /*
		*/LOACIstyle(passthru) /*
		*/LOWess /*
		*/noCIMean /*
		*/noCILoa /*
	*/]

	local nvar = wordcount("`varlist'")
	tokenize `varlist'
	
	capture matrix drop bapladder
	forvalues r = 1/`nvar' {
		forvalues s = `r'/`nvar' {
			if `r' == `s' continue
			qui bap ``r'' ``s'' `if', nograph roweq(`r' vs `s')
			matrix bapladder = nullmat(bapladder) \ r(bap)
		}
	}
	matlist bapladder, tw(32)
	return matrix bapladder = bapladder
	
	if "`graph'" != "" | "`name'" != "" {
		if "`size'" == "" local size huge
		set graphics off
		forvalues r = 1/`nvar' {
			forvalues s = `r'/`nvar' {
				if `r' == `s' {
					* text must be centered according to neighbor graphs xycommon
					twoway (function y = 0, range(-1 1) lcolor(white)) , ///
					text(0 0 "`: var l ``r'''", size(`size')) xla(none) yla(none) yti("") xti("") ///
					name(_g`r'`s'_, replace)
				}
				else {
					qui bap ``r'' ``s'' `if', ///
						legend(off) ytitle("") name(_g`r'vs`s'_, replace) ///
						`formatgraph' `text' `scatterstyle' `meanlinestyle' ///
						`meancistyle' `loalinestyle' `loacistyle' `lowess' ///
						`cimean' `ciloa'						
					qui graph copy _g`r'vs`s'_ _g`s'vs`r'_, replace
				}
			}	
		}
		local grlst
		forvalues r = 1/`nvar' {
			forvalues s = 1/`nvar' {
				if `r' == `s' local grlst `grlst' _g`r'`s'_
				else if `r' < `s' local grlst `grlst' _g`r'vs`s'_
				else local grlst `grlst' _g`s'vs`r'_
			}
		}
		graph combine `grlst', /*xcommon ycommon*/ `name'
		set graphics on
		qui graph dir _g*_
		graph drop `r(list)'
		qui graph dir
		foreach gn in `r(list)' {
			graph display `gn'
		}
	}
end