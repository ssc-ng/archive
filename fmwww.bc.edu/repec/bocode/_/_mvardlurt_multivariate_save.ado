*! _mvardlurt_multivariate_save  version 1.1.2  03oct2026
*! Export headline results of the last estimation to Excel (savepath() option)

capture program drop _mvardlurt_multivariate_save
program define _mvardlurt_multivariate_save
    version 14
    syntax , PATH(string)

    if "`e(cmd)'" != "mvardlurt_multivariate" {
        di as err "last estimates not found"
        exit 301
    }
    if !regexm(lower("`path'"), "\.xlsx?$") local path "`path'.xlsx"

    tempname cv
    matrix `cv' = e(cv)
    local dv "`e(depvar)'"
    local xv "`e(indepvars)'"
    local oq "`e(opt_q)'"
    local cn "`e(casename)'"
    local ic "`e(ic)'"
    local tstat = e(tstat)
    local fstat = e(fstat)
    local pt = e(p_t)
    local pf = e(p_f)
    local nn = e(N)
    local pp = e(opt_p)
    local kk = e(k)
    local cs = e(case)
    local r2 = e(r2)
    local aic = e(aic)
    local bic = e(bic)
    local t10 = el(`cv', 1, 1)
    local t5  = el(`cv', 1, 2)
    local t1  = el(`cv', 1, 4)
    local f10 = el(`cv', 2, 1)
    local f5  = el(`cv', 2, 2)
    local f1  = el(`cv', 2, 4)

    preserve
    drop _all
    qui set obs 1
    qui gen str40 command = "mvardlurt_multivariate"
    qui gen str32 depvar = "`dv'"
    qui gen str244 covariates = "`xv'"
    qui gen byte k = `kk'
    qui gen byte case = `cs'
    qui gen str30 casename = "`cn'"
    qui gen byte opt_p = `pp'
    qui gen str40 opt_q = "`oq'"
    qui gen str5 ic = "`ic'"
    qui gen long obs = `nn'
    qui gen double tstat = `tstat'
    qui gen double fstat = `fstat'
    qui gen double t_cv10 = `t10'
    qui gen double t_cv05 = `t5'
    qui gen double t_cv01 = `t1'
    qui gen double f_cv10 = `f10'
    qui gen double f_cv05 = `f5'
    qui gen double f_cv01 = `f1'
    qui gen double p_t_boot = `pt'
    qui gen double p_f_boot = `pf'
    qui gen double r2 = `r2'
    qui gen double aic = `aic'
    qui gen double bic = `bic'
    qui export excel using "`path'", firstrow(variables) replace
    di as txt _col(3) "Results saved to " as res "`path'"
    restore
end
