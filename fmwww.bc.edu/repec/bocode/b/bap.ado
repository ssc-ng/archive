*! version 0.2 2024-04-23 Niels Henrik Bruun	
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2026-05-18 v0.2 SEM calculating bug is fixed
*! 2026-04-14 v0.2 SEM calculating bug is fixed
*! 2026-04-14 v0.2 Minimal detechtable change (MDC) added in table r(bap)
*! 2026-03-26 v0.2 New command bapladder added
*! 2026-03-24 v0.2 confidens intervals added for mean and LOA bounds
* 2023-12-16 v0.1 created
*TODO different coloring of markers by a group variable?
program define bap, rclass
		version 14.2
		
    syntax varlist(min=2 max=2 numeric) [if], /* 
      */[ /* 
          */noGraph /* 
          */Formatgraph(string) /*
          */Text(string) /*
          */Scatterstyle(string) /*
          */MEANLinestyle(string) /*
          */MEANCIstyle(string) /*
          */LOALinestyle(string) /*
          */LOACIstyle(string) /*
          */Pointlabel(varname) /*
          */POintlabelsize(string) /*
          */Roweq(string) /*
          */LOWess /*
          */noCIMean /*
          */noCILoa /*
          */ * /* 
      */]

    if `"`formatgraph'"' == "" local formatgraph "%4.1f"
    if `"`scatterstyle'"' == "" local scatterstyle jitter(3)
    if `"`meanlinestyle'"' == "" local meanlinestyle lcolor(gs10) lpattern(solid)
	if `"`meancistyle'"' == "" local meancistyle lcolor(gs10%40) fcolor(gs10%40)
    if `"`loalinestyle'"' == "" local loalinestyle lcolor(gs10) lpattern(dash)
	if `"`loacistyle'"' == "" local loacistyle lcolor(gs10%15) fcolor(gs10%15)
    if `"`formatgraph'"' == "" local formatgraph "%4.1f"
    tokenize `"`varlist'"'
    local lbl1 `:var l `1''
    if "`lbl1'" == "" local lbl1 `1'
    local lbl2 `:var l `2''
    if "`lbl2'" == "" local lbl2 `2'
    if `"`text'"' == "" local text `lbl1' vs `lbl2'
		local w = min(max(5, strlen("`lbl1'"), strlen("`lbl2'"), strlen("`roweq'")) + 2, 32)
	tempname d m lb ub
    quietly generate `d' = `1' - `2' `if'
    quietly generate `m' = (`1' + `2') / 2 `if'
	quietly means `1' `if'
    matrix bap = r(N), r(mean), r(lb), r(ub)
	quietly means `2' `if'
    matrix bap = bap \ r(N), r(mean), r(lb), r(ub)
	quietly means `d' `if'
	scalar sem = sqrt(r(Var) / 2)
	scalar z_ulvl = invnormal(0.5 + c(level)/200)
	scalar mdc = sem * z_ulvl * sqrt(2)
    matrix bap = bap, ((r(mean), r(lb), r(ub), sem, mdc) \ J(1,5,.))
    *matrix bap[1,8] = bap[1,8] / sqrt(2)
	quietly generate `lb' = r(lb)
	quietly generate `ub' = r(ub)
    quietly summarize `d' `if'
	scalar scr_md = r(mean)
	scalar scr_sd = r(sd)
	scalar scr_n  = r(N)
	scalar scr_z = invnormal(0.5 + `c(level)'*0.005)
	scalar scr_se_loa = scr_sd * sqrt(1/scr_n + (1.96^2)/(2*(scr_n-1)))
	scalar scr_lb_loa = scr_md - scr_z * scr_sd
	scalar scr_ub_loa = scr_md + scr_z * scr_sd
	scalar scr_lb_loa_low  = scr_lb_loa - scr_z * scr_se_loa
	scalar scr_lb_loa_high = scr_lb_loa + scr_z * scr_se_loa
	scalar scr_ub_loa_low  = scr_ub_loa - scr_z * scr_se_loa
	scalar scr_ub_loa_high = scr_ub_loa + scr_z * scr_se_loa
	matrix biasloa = bap[1,5..7] \ ///
		scr_lb_loa, scr_lb_loa_low, scr_lb_loa_high \ ///
		scr_ub_loa, scr_ub_loa_low, scr_ub_loa_high
	matrix colnames biasloa = level [95% CI]
	matrix rownames biasloa = BIAS lLOA uLOA
	tempname lb_loa_low lb_loa_high ub_loa_low ub_loa_high
	if "`if'" == "" local if2 if !mi(`m')
	else local if2 `if' & !mi(`mi')
	quietly generate `lb_loa_low'  = scr_lb_loa_low  `if2'
	quietly generate `lb_loa_high' = scr_lb_loa_high `if2'
	quietly generate `ub_loa_low'  = scr_ub_loa_low  `if2'
	quietly generate `ub_loa_high' = scr_ub_loa_high `if2'

    matrix bap = bap, ((scr_lb_loa, scr_ub_loa) \ J(1,2,.))
    matrix coleq bap = Measurements Measurements Measurements ///
        Measurements Bias Bias Bias Agreement Agreement LOA LOA
    matrix colnames bap = n mean [95% CI] diff [95% CI] SEM MDC [lower upper]
		matrix roweq bap = `"`roweq'"'
		matrix rownames bap = "`lbl1'" "`lbl2'"
    if "`graph'" == "" {
		if "`pointlabelsize'" != "" local plblsz mlabsize(`pointlabelsize')
		if "`pointlabel'" != "" local plbl msymbol(none) mlabel(`pointlabel')
		if `"`lowess'"' == "" local lowess function y = scr_md, range(`m')
		else local lowess lowess `d' `m' `if',
		local grphcmd twoway ///
			(scatter `d' `m' `if', `scatterstyle' `plbl' `plblsz') ///
			(`lowess' `meanlinestyle') ///
			(function scr_ub_loa `if2', range(`m') `loalinestyle')  ///
			(function scr_lb_loa `if2', range(`m') `loalinestyle')
		local grphlegord 2 "BIAS = `=string(`=r(mean)', "`formatgraph'")'" ///
			3 `"LOA [`=string(scr_lb_loa, "`formatgraph'")'; `=string(scr_ub_loa, "`formatgraph'")']"'
		if "`cimean'" == "" {
			local grphcmd `grphcmd' (rarea `ub' `lb' `m', sort `meancistyle')
			local grphlegord `grphlegord' 5 "BIAS `c(level)'%CI"
		}
		if "`ciloa'" == "" {
			local grphcmd `grphcmd' ///
				(rarea `lb_loa_high' `lb_loa_low' `m', sort `loacistyle') ///
				(rarea `ub_loa_high' `ub_loa_low' `m', sort `loacistyle')
			local grphlegord `grphlegord' 6 "LOA `c(level)'%CI"
		}

		local grphcmd `grphcmd', legend(order(`grphlegord') rows(1) position(6)) ///
			xtitle("") ytitle(`"`text'"') `options'
		`grphcmd'
    }
	matlist bap, keepcoleq showcoleq(lcombined) twidth(`w')
    return matrix bap = bap
	return matrix biasloa = biasloa
	return local grphcmd = `"`grphcmd'"'
end
