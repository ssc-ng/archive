program multisite_regLATE, eclass
version 14.2
syntax varlist(min=4 max=4 numeric) [if] [aweight] [, outcomes(varlist numeric) cross(varlist numeric min=2 max=2)]
/* -------------------------------------------------------------------------
   multisite_regLATE (version 2, 2026-10-15)
   Relationships between site-specific LATEs in multi-site RCTs with
   imperfect compliance, Section 3.3.4 and Appendix A.4 of de Chaisemartin
   & Deeb (2026). Two targets, chosen by the option:

   outcomes(varlist): beta^d, eq. (late-within-treatment-target), the
      coefficients from the regression of the LATE on `outcome' (outcome 1)
      on the LATEs on the outcomes in outcomes() (outcomes 2..J), all for the
      same treatment arm, with weights proportional to the arm's squared
      first stage. Estimator eq. (late-within-beta-estimator-app), influence
      function eq. (late-within-beta-if-app).
   cross(treatment2 instrument2): beta^{12}, eq. (late-cross-treatment-target),
      the covariance-variance ratio relating arm 2's LATE on `outcome' to
      arm 1's LATE on the same outcome; arm 1 is (treatment, instrument),
      arm 2 is cross(). Estimator eq. (late-cross-treatment-estimator-app),
      influence functions eqs. (late-cross-cov-if-app), (late-cross-var-if-app),
      (late-cross-beta-if-app).

   Building blocks are corrected second moments of sites' ITT and first-stage
   estimators, eq. (late-reg-corrected-moment), with the within-arm
   covariance corrections of Proposition prop:rct-unbiased. Site weights:
   W(S_i) = number of units in the site, w_hat_i = n_i / nbar. [aweight]
   weights units within sites. Conventions (count-based n/(n-1) factors)
   follow multisite_varLATE.
   ------------------------------------------------------------------------- */
if "`outcomes'" == "" & "`cross'" == "" {
	di as error "specify either outcomes(varlist) for beta^d or cross(treatment2 instrument2) for beta^12"
	exit 198
}
if "`outcomes'" != "" & "`cross'" != "" {
	di as error "outcomes() and cross() cannot be combined"
	exit 198
}
qui{
preserve

tokenize `varlist'
local yname `1'
tempvar y d z site wv
gen double `y'=`1'
gen double `d'=`2'
gen `z'=`3'
gen `site'=`4'

if `"`if'"' != "" {
keep `if'
}
local wexp ""
local wlist ""
if "`weight'" != "" {
gen double `wv' `exp'
local wexp "[`weight'=`wv']"
local wlist "`wv'"
}

/* ======================================================================= */
if "`outcomes'" != "" {
/* ---- beta^d: LATEs on several outcomes, same treatment arm ------------ */
local J1 : word count `outcomes'
local J = `J1' + 1
local K = `J' + 1
* x1 = outcome 1, x2..xJ = outcomes 2..J, xK = treatment
local x1 `y'
local k = 2
foreach v of local outcomes {
	tempvar o`k'
	gen double `o`k''=`v'
	local x`k' `o`k''
	local k = `k' + 1
}
local x`K' `d'
local xlist ""
forvalues p=1/`K' {
	local xlist "`xlist' `x`p''"
}
keep `xlist' `z' `site' `wlist'
foreach v of varlist `xlist' `z' `site' `wlist' {
	drop if `v'==.
}

* Sites with fewer than two assigned or two non-assigned units are dropped
bys `site': egen double multisite_n1 = total(`z')
bys `site': gen double multisite_ns = _N
gen double multisite_n0 = multisite_ns - multisite_n1
drop if multisite_n1 < 2 | multisite_n0 < 2
drop multisite_n1 multisite_ns multisite_n0

/* Site-level building blocks. Row: site, ns, I_1..I_J, F, then C_{p,q} for
   p<=q over the K variables (p,q = 1..K): the estimated covariance of the
   site-effect estimators for x_p and x_q, i.e. the sum over the two arms of
   (n_a/(n_a-1)) x weighted mean of cross-products / n_a.                  */
local npairs = `K'*(`K'+1)/2
local ncol = 2 + `K' + `npairs'
matrix A=J(1,`ncol',.)
levelsof `site', local(levels)
local num_site : word count `levels'
tempvar tmp
gen double `tmp'=.
foreach s of local levels {
	matrix R=J(1,`ncol',.)
	forvalues a=0/1 {
		forvalues p=1/`K' {
			sum `x`p'' `wexp' if `z'==`a' & `site'==`s'
			scalar m`a'_`p'=r(mean)
			scalar n`a'=r(N)
		}
		forvalues p=1/`K' {
			forvalues q=`p'/`K' {
				replace `tmp'=(`x`p''-m`a'_`p')*(`x`q''-m`a'_`q') if `z'==`a' & `site'==`s'
				sum `tmp' `wexp' if `z'==`a' & `site'==`s'
				scalar c`a'_`p'_`q'=(n`a'/(n`a'-1))*r(mean)/n`a'
			}
		}
	}
	matrix R[1,1]=`s'
	matrix R[1,2]=n1+n0
	forvalues p=1/`K' {
		matrix R[1,2+`p']=m1_`p'-m0_`p'
	}
	local col = 2 + `K'
	forvalues p=1/`K' {
		forvalues q=`p'/`K' {
			local col = `col' + 1
			matrix R[1,`col']=c1_`p'_`q'+c0_`p'_`q'
		}
	}
	matrix A=A\R
}
local total_obs = _N
clear
svmat double A
drop if A1==.
rename A1 site
rename A2 ns
forvalues p=1/`J' {
	rename A`=2+`p'' I_`p'
}
rename A`=2+`K'' F
local col = 2 + `K'
forvalues p=1/`K' {
	forvalues q=`p'/`K' {
		local col = `col' + 1
		rename A`col' c_`p'_`q'
	}
}

* site weights: prop2 = w_hat_i / n, wtilde = w_hat_i
sum ns
gen double prop2=ns/r(sum)
gen double wtilde=prop2*_N
local n = _N

* ---- Squared-first-stage-weighted mean LATEs, eq. (late-dj-fs2-estimator-app)
gen double for_m2=F^2-c_`K'_`K'
sum for_m2 [aw=prop2]
scalar m2_hat=r(sum)
forvalues j=1/`J' {
	gen double for_r_`j'=F*I_`j'-c_`j'_`K'
	sum for_r_`j' [aw=prop2]
	scalar L_`j'=r(sum)/m2_hat
	* U_j = ITT_j - FS x LATE_{j,FS^2}
	gen double U_`j'=I_`j'-F*L_`j'
}
* ---- Covariance corrections for the U's, eq. (late-transformed-correction-app)
forvalues j=1/`J' {
	forvalues l=`j'/`J' {
		gen double CU_`j'_`l'=c_`j'_`l'-L_`l'*c_`j'_`K'-L_`j'*c_`l'_`K'+L_`j'*L_`l'*c_`K'_`K'
		if `l' > `j' {
			gen double CU_`l'_`j'=CU_`j'_`l'
		}
	}
}
* ---- Estimator, eq. (late-within-beta-estimator-app) ----------------------
matrix AA=J(`J1',`J1',.)
matrix bb=J(`J1',1,.)
forvalues j=2/`J' {
	forvalues l=2/`J' {
		gen double aa_`j'_`l'=U_`j'*U_`l'-CU_`j'_`l'
		sum aa_`j'_`l' [aw=prop2]
		matrix AA[`j'-1,`l'-1]=r(sum)
	}
	gen double bb_`j'=U_`j'*U_1-CU_`j'_1
	sum bb_`j' [aw=prop2]
	matrix bb[`j'-1,1]=r(sum)
}
matrix Ainv=inv(AA)
matrix beta=Ainv*bb
* ---- Influence function, eq. (late-within-beta-if-app) -------------------
gen double resid=U_1
forvalues l=2/`J' {
	replace resid=resid-U_`l'*beta[`l'-1,1]
}
forvalues j=2/`J' {
	gen double g_`j'=U_`j'*resid-CU_`j'_1
	forvalues l=2/`J' {
		replace g_`j'=g_`j'+CU_`j'_`l'*beta[`l'-1,1]
	}
	replace g_`j'=wtilde*g_`j'
}
forvalues j=2/`J' {
	gen double psi_`j'=0
	forvalues l=2/`J' {
		replace psi_`j'=psi_`j'+Ainv[`j'-1,`l'-1]*g_`l'
	}
}
matrix V=J(`J1',`J1',.)
forvalues j=2/`J' {
	forvalues l=2/`J' {
		gen double pp=psi_`j'*psi_`l'
		sum pp
		matrix V[`j'-1,`l'-1]=r(mean)/`n'
		drop pp
	}
}
matrix b=beta'
matrix colnames b = `outcomes'
matrix rownames b = beta_d
matrix colnames V = `outcomes'
matrix rownames V = `outcomes'

matrix VV=V
ereturn post b V, depname(`yname') obs(`total_obs')
ereturn scalar Sites = `num_site'
ereturn scalar mean_FS2 = m2_hat
forvalues j=1/`J' {
	ereturn scalar LATE_FS2_`j' = L_`j'
}
ereturn local predictors "`outcomes'"
ereturn local target "beta_d"
ereturn local cmd "multisite_regLATE"

* Output matrix
matrix mat_res_XX = J(`J1', 6, .)
forvalues j=1/`J1' {
	matrix mat_res_XX[`j',1] = beta[`j',1]
	matrix mat_res_XX[`j',2] = sqrt(VV[`j',`j'])
	matrix mat_res_XX[`j',3] = beta[`j',1] - 1.96*sqrt(VV[`j',`j'])
	matrix mat_res_XX[`j',4] = beta[`j',1] + 1.96*sqrt(VV[`j',`j'])
	matrix mat_res_XX[`j',5] = `num_site'
	matrix mat_res_XX[`j',6] = `total_obs'
}
matrix rownames mat_res_XX = `outcomes'
matrix colnames mat_res_XX = "Estimate" "SE" "95% LB" "95% UB" "# Sites" "# Units"
local title "LATE on `yname' regressed on LATEs on other outcomes (FS^2 weights)"
}

/* ======================================================================= */
else {
/* ---- beta^12: LATEs on the same outcome, two treatment arms ------------ */
tokenize `cross'
tempvar d2 z2 arm
gen double `d2'=`1'
gen `z2'=`2'
keep `y' `d' `z' `d2' `z2' `site' `wlist'
foreach v of varlist `y' `d' `z' `d2' `z2' `site' `wlist' {
	drop if `v'==.
}
count if `z'==1 & `z2'==1
if r(N) > 0 {
	noisily di as error "`=r(N)' units are assigned to both treatments: the two instruments must be mutually exclusive"
	exit 459
}
* arm 0 = assigned to neither treatment, arm 1 = (treatment, instrument), arm 2 = cross()
gen `arm'=0 if `z'==0 & `z2'==0
replace `arm'=1 if `z'==1
replace `arm'=2 if `z2'==1
drop if `arm'==.

* Sites with fewer than two units in any of the three arms are dropped
forvalues a=0/2 {
	bys `site': egen double multisite_n`a' = total(`arm'==`a')
}
drop if multisite_n0 < 2 | multisite_n1 < 2 | multisite_n2 < 2
drop multisite_n0 multisite_n1 multisite_n2

/* Site-level building blocks. Columns:
   site ns F1 F2 I1 I2 VF1 VI1 CF1I1 CI1I2 CF1F2 CF2I1 CF1I2
   Arms are independent; the control arm is shared by both ITTs and first
   stages, which is where the cross-arm covariances come from.             */
matrix A=J(1,13,.)
levelsof `site', local(levels)
local num_site : word count `levels'
tempvar tmp
gen double `tmp'=.
foreach s of local levels {
	forvalues a=0/2 {
		sum `y' `wexp' if `arm'==`a' & `site'==`s'
		scalar Y`a'=r(mean)
		scalar n`a'=r(N)
	}
	sum `d' `wexp' if `arm'==1 & `site'==`s'
	scalar D1_1=r(mean)
	sum `d' `wexp' if `arm'==0 & `site'==`s'
	scalar D1_0=r(mean)
	sum `d2' `wexp' if `arm'==2 & `site'==`s'
	scalar D2_2=r(mean)
	sum `d2' `wexp' if `arm'==0 & `site'==`s'
	scalar D2_0=r(mean)
	scalar s_ns=n0+n1+n2

	replace `tmp'=(`y'-Y0)^2 if `arm'==0 & `site'==`s'
	sum `tmp' `wexp' if `arm'==0 & `site'==`s'
	scalar sY0=(n0/(n0-1))*r(mean)
	replace `tmp'=(`y'-Y1)^2 if `arm'==1 & `site'==`s'
	sum `tmp' `wexp' if `arm'==1 & `site'==`s'
	scalar sY1=(n1/(n1-1))*r(mean)
	replace `tmp'=(`d'-D1_1)^2 if `arm'==1 & `site'==`s'
	sum `tmp' `wexp' if `arm'==1 & `site'==`s'
	scalar sD1_1=(n1/(n1-1))*r(mean)
	replace `tmp'=(`d'-D1_0)^2 if `arm'==0 & `site'==`s'
	sum `tmp' `wexp' if `arm'==0 & `site'==`s'
	scalar sD1_0=(n0/(n0-1))*r(mean)
	replace `tmp'=(`d'-D1_1)*(`y'-Y1) if `arm'==1 & `site'==`s'
	sum `tmp' `wexp' if `arm'==1 & `site'==`s'
	scalar cD1Y_1=(n1/(n1-1))*r(mean)
	replace `tmp'=(`d'-D1_0)*(`y'-Y0) if `arm'==0 & `site'==`s'
	sum `tmp' `wexp' if `arm'==0 & `site'==`s'
	scalar cD1Y_0=(n0/(n0-1))*r(mean)
	replace `tmp'=(`d2'-D2_0)*(`y'-Y0) if `arm'==0 & `site'==`s'
	sum `tmp' `wexp' if `arm'==0 & `site'==`s'
	scalar cD2Y_0=(n0/(n0-1))*r(mean)
	replace `tmp'=(`d'-D1_0)*(`d2'-D2_0) if `arm'==0 & `site'==`s'
	sum `tmp' `wexp' if `arm'==0 & `site'==`s'
	scalar cD1D2_0=(n0/(n0-1))*r(mean)

	scalar s_I1=Y1-Y0
	scalar s_I2=Y2-Y0
	scalar s_F1=D1_1-D1_0
	scalar s_F2=D2_2-D2_0
	scalar s_VF1=sD1_1/n1+sD1_0/n0
	scalar s_VI1=sY1/n1+sY0/n0
	scalar s_CF1I1=cD1Y_1/n1+cD1Y_0/n0
	scalar s_CI1I2=sY0/n0
	scalar s_CF1F2=cD1D2_0/n0
	scalar s_CF2I1=cD2Y_0/n0
	scalar s_CF1I2=cD1Y_0/n0
	matrix A=A\(`s',s_ns,s_F1,s_F2,s_I1,s_I2,s_VF1,s_VI1,s_CF1I1,s_CI1I2,s_CF1F2,s_CF2I1,s_CF1I2)
}
local total_obs=_N
clear
svmat double A
drop if A1==.
rename A1 site
rename A2 ns
rename A3 F1
rename A4 F2
rename A5 I1
rename A6 I2
rename A7 VF1
rename A8 VI1
rename A9 CF1I1
rename A10 CI1I2
rename A11 CF1F2
rename A12 CF2I1
rename A13 CF1I2

sum ns
gen double prop2=ns/r(sum)
gen double wtilde=prop2*_N
local n = _N

* ---- Corrected second moments, eq. (late-reg-corrected-moment), and their
*      influence functions, eq. (late-reg-moment-if) -------------------------
gen double m_I1I2=I1*I2-CI1I2
gen double m_F1F2=F1*F2-CF1F2
gen double m_F2I1=F2*I1-CF2I1
gen double m_F1I2=F1*I2-CF1I2
gen double m_I1I1=I1^2-VI1
gen double m_F1F1=F1^2-VF1
gen double m_F1I1=F1*I1-CF1I1
foreach m in I1I2 F1F2 F2I1 F1I2 I1I1 F1F1 F1I1 {
	sum m_`m' [aw=prop2]
	scalar M_`m'=r(sum)
	gen double psi_`m'=wtilde*(m_`m'-M_`m')
}

* ---- Estimator, eq. (late-cross-treatment-estimator-app) ------------------
scalar C12=M_I1I2/M_F1F2-M_F2I1*M_F1I2/M_F1F2^2
scalar V1=M_I1I1/M_F1F1-M_F1I1^2/M_F1F1^2
scalar beta12=C12/V1

* ---- Influence functions, eqs. (late-cross-cov-if-app), (late-cross-var-if-app),
*      (late-cross-beta-if-app) ----------------------------------------------
gen double psi_C = psi_I1I2/M_F1F2 - M_I1I2*psi_F1F2/M_F1F2^2 ///
	- (M_F1I2*psi_F2I1+M_F2I1*psi_F1I2)/M_F1F2^2 ///
	+ 2*M_F2I1*M_F1I2*psi_F1F2/M_F1F2^3
gen double psi_V = psi_I1I1/M_F1F1 - M_I1I1*psi_F1F1/M_F1F1^2 ///
	- 2*M_F1I1*psi_F1I1/M_F1F1^2 + 2*M_F1I1^2*psi_F1F1/M_F1F1^3
gen double psi_beta=(psi_C-beta12*psi_V)/V1
foreach v in psi_C psi_V psi_beta {
	gen double sq_`v'=`v'^2
	sum sq_`v'
	scalar se_`v'=sqrt(r(mean)/r(N))
}

matrix b=J(1,1,.)
matrix b[1,1]=beta12
matrix V=J(1,1,.)
matrix V[1,1]=se_psi_beta^2
matrix colnames b = "LATE1"
matrix rownames b = beta_12
matrix colnames V = "LATE1"
matrix rownames V = "LATE1"

ereturn post b V, depname("LATE2") obs(`total_obs')
ereturn scalar beta12=beta12
ereturn scalar se_beta12=se_psi_beta
ereturn scalar lb_CI_beta12=beta12-1.96*se_psi_beta
ereturn scalar ub_CI_beta12=beta12+1.96*se_psi_beta
ereturn scalar cov12=C12
ereturn scalar se_cov12=se_psi_C
ereturn scalar var1=V1
ereturn scalar se_var1=se_psi_V
ereturn scalar LATE1_FS2=M_F1I1/M_F1F1
ereturn scalar Sites = `num_site'
ereturn local target "beta_12"
ereturn local cmd "multisite_regLATE"

matrix mat_res_XX = J(3, 6, .)
matrix mat_res_XX[1,1] = beta12
matrix mat_res_XX[1,2] = se_psi_beta
matrix mat_res_XX[1,3] = beta12-1.96*se_psi_beta
matrix mat_res_XX[1,4] = beta12+1.96*se_psi_beta
matrix mat_res_XX[2,1] = C12
matrix mat_res_XX[2,2] = se_psi_C
matrix mat_res_XX[2,3] = C12-1.96*se_psi_C
matrix mat_res_XX[2,4] = C12+1.96*se_psi_C
matrix mat_res_XX[3,1] = V1
matrix mat_res_XX[3,2] = se_psi_V
matrix mat_res_XX[3,3] = V1-1.96*se_psi_V
matrix mat_res_XX[3,4] = V1+1.96*se_psi_V
forvalues k=1/3 {
	matrix mat_res_XX[`k',5] = `num_site'
	matrix mat_res_XX[`k',6] = `total_obs'
}
matrix rownames mat_res_XX = "beta^12, LATE_2 on LATE_1" "Cov_{FS1 FS2}(LATE_1,LATE_2)" "Var_{FS1^2}(LATE_1)"
matrix colnames mat_res_XX = "Estimate" "SE" "95% LB" "95% UB" "# Sites" "# Units"
local title "Arm-2 LATE on arm-1 LATE, outcome `yname'"
}
}

di "{hline 93}"
di _skip(10) "{bf: `title'}"
di "{hline 93}"
noisily matlist mat_res_XX, border(rows) twidth(30)
di as text "The development of this package was funded by the European Union (ERC, REALLYCREDIBLE,GA N°101043899)."

restore
end
