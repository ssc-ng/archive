*! version 0.2 2026-03-26 Niels Henrik Bruun	
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2026-03-26 v0.2 created

cls
capture program drop bapm
program define bapm, rclass
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
					name(g`r'`s', replace)
				}
				else {
					qui bap ``r'' ``s'' `if', ///
						legend(off) ytitle("") name(g`r'vs`s', replace) ///
						`formatgraph' `text' `scatterstyle' `meanlinestyle' ///
						`meancistyle' `loalinestyle' `loacistyle' `lowess' ///
						`cimean' `ciloa'						
					qui graph copy g`r'vs`s' g`s'vs`r', replace
				}
			}	
		}
		local grlst
		forvalues r = 1/`nvar' {
			forvalues s = 1/`nvar' {
				if `r' == `s' local grlst `grlst' g`r'`s'
				else if `r' < `s' local grlst `grlst' g`r'vs`s'
				else local grlst `grlst' g`s'vs`r'
			}
		}
		graph combine `grlst', /*xcommon ycommon*/ `name'
		set graphics on
		graph display
	}
end