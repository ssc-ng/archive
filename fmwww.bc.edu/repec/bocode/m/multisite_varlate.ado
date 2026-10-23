program multisite_varLATE, eclass
version 14.2
syntax varlist(min=4 max=4 numeric)  [if] [aweight]
/* -------------------------------------------------------------------------
   multisite_varLATE
   Estimates, in a multi-site RCT with imperfect compliance:
   (1) LATE, the overall LATE with complier weights, eq. (overall-late);
   (2) sigma^2_LATE lower bound, a lower bound for the complier-weighted
       variance of site LATEs, Proposition prop:late-variance-identification,
       eq. (late-variance-lower-bound-hat):
       h_hat / FS + (r_hat - m2_hat LATE)^2 / (FS (FS - m2_hat));
   (3) LATE_{FS^2}, the average of site LATEs under weights proportional to
       squared first stages, eq. (q-late-hat): r_hat / m2_hat;
   (4) sigma^2_{LATE,FS^2}, the variance of site LATEs under the same
       weights, eq. (late-variance-hat): q_hat / m2_hat;
   (5) sqrt(sigma^2_{LATE,FS^2}) / LATE_{FS^2}.
   Standard errors use the influence functions of Section 3.5 of
   de Chaisemartin & Deeb (2026): eq. (AL-lambda-late-proof) for (1), eqs.
   (psi-late-bound-numerator), (psi-late-variance-lower-bound),
   (Vhat-late-variance-lower-bound) for (2), the delta method applied to
   r_hat/m2_hat for (3), and eqs. (psi-q-late), (psi-fs-second-moment),
   (psi-late-variance), (Vhat-late-variance) for (4).
   Site weights: W(S_i) = number of units in site i, so w_hat_i = n_i / nbar.
   The lower bound requires m2_hat < FS (first stages not all equal to one);
   otherwise it is reported as missing.
   ------------------------------------------------------------------------- */
qui{
preserve

tempvar outcome treatment instrument site
tokenize `varlist'
gen `outcome'=`1'
gen `treatment'=`2'
gen `instrument'=`3'
gen `site'=`4'

*Keeping if sample
if `"`if'"' != "" {
keep `if'
}

* Keep only the variables used, so that user variables cannot shadow the
* scalars defined below (Stata resolves a name to a variable before a scalar)
tempvar wv
local wexp ""
local wlist ""
if "`weight'" != "" {
gen double `wv' `exp'
local wexp "[`weight'=`wv']"
local wlist "`wv'"
}
keep `outcome' `treatment' `instrument' `site' `wlist'

* Drop sites with fewer than two units in either arm (needed for V_hat)
bys `site': egen multisiteITT_n1s = total(`instrument')
bys `site': gen multisiteITT_ns = _N
gen multisiteITT_n0s = multisiteITT_ns - multisiteITT_n1s
drop if multisiteITT_n1s < 2 | multisiteITT_n0s < 2
drop multisiteITT_ns multisiteITT_n1s multisiteITT_n0s

/* ---- Site-level building blocks (Proposition prop:rct-unbiased) ----------
   For each site: ITT_s = Ybar1 - Ybar0 and V_ITT,s; FS_s = Dbar1 - Dbar0 and
   V_FS,s; C_s = C_hat_{FS,ITT2,s}, the estimated covariance of the two
   difference-in-means estimators (sum of the two within-arm covariances of
   the arm means).                                                          */
matrix A=.,.,.,.,.,.,.,.,.
levelsof `site', local(levels)
local num_site : word count `levels'
foreach y of local levels {
sum `outcome' `wexp' if `instrument'==1 & `site'==`y'
scalar Ybar1=r(mean)
scalar nt=r(N)
sum `outcome' `wexp' if `instrument'==0 & `site'==`y'
scalar Ybar0=r(mean)
scalar nc=r(N)
scalar ns=nt+nc
gen diff1treat= (`outcome'-Ybar1)^2 if `instrument'==1 & `site'==`y'
gen diff1control= (`outcome'-Ybar0)^2 if `instrument'==0 & `site'==`y'
summ diff1treat `wexp'
scalar rY1S=(nt/(nt-1))*r(mean)
summ diff1control `wexp'
scalar rY0S=(nc/(nc-1))*r(mean)
scalar VI_s=(1/nt)*rY1S+(1/nc)*rY0S
drop diff*
scalar I_s=Ybar1 - Ybar0

sum  `treatment' `wexp' if `instrument'==1 & `site'==`y'
scalar Dbar1=r(mean)
sum `treatment' `wexp' if `instrument'==0 & `site'==`y'
scalar Dbar0=r(mean)
scalar F_s=Dbar1 - Dbar0

gen diff1treat= (`treatment'-Dbar1)^2 if `instrument'==1 & `site'==`y'
gen diff1control= (`treatment'-Dbar0)^2 if `instrument'==0 & `site'==`y'
summ diff1treat `wexp'
scalar rD1S=(nt/(nt-1))*r(mean)
summ diff1control `wexp'
scalar rD0S=(nc/(nc-1))*r(mean)
scalar VF_s=(1/nt)*rD1S+(1/nc)*rD0S
drop diff*

gen diff2treat= (`outcome'-Ybar1)*(`treatment'-Dbar1) if `instrument'==1 & `site'==`y'
gen diff2control= (`outcome'-Ybar0)*(`treatment'-Dbar0)  if `instrument'==0 & `site'==`y'
summ diff2treat `wexp'
scalar cDY1S=(nt/(nt-1))*r(mean)/nt
summ diff2control `wexp'
scalar cDY0S=(nc/(nc-1))*r(mean)/nc
scalar C_s=cDY1S+cDY0S
drop  diff*

matrix A=A\ `y',ns,F_s,VF_s,I_s,VI_s,nc,nt,C_s
}
local total_obs = _N
svmat A
keep A*
rename A1 site
rename A2 ns
rename A3 F_s
rename A4 VF_s
rename A5 I_s
rename A6 VI_s
rename A7 nc
rename A8 nt
rename A9 C_s
drop if site==.

* Site weights: prop2 = w_hat_i / n (so that sum prop2 * x = (1/n) sum w_hat_i x),
* wtildes = w_hat_i = n_i / nbar
sum ns
gen n=r(sum)
gen nbar=n/_N
gen prop2= ns/n
gen wtildes= ns/nbar

/* ---- (1) Overall LATE with complier weights, eq. (overall-late) --------- */
sum I_s [aw=prop2]
scalar Ibar=r(sum)
sum F_s [aw=prop2]
scalar Fbar=r(sum)
scalar Lbar=Ibar/Fbar

/* ---- (3) LATE_{FS^2} = r_hat / m2_hat, eq. (q-late-hat) -----------------
   r_hat  = (1/n) sum w_hat_i [FS_i ITT_i - C_i]     (corrected E_w[mu_FS mu_ITT2])
   m2_hat = (1/n) sum w_hat_i [FS_i^2 - V_FS,i]      (corrected E_w[mu_FS^2])   */
gen for_r = F_s*I_s - C_s
sum for_r [aw=prop2]
scalar r_hat=r(sum)
gen for_m2 = F_s^2 - VF_s
sum for_m2 [aw=prop2]
scalar m2_hat=r(sum)
scalar L_FS2=r_hat/m2_hat

/* ---- (4) sigma^2_{LATE,FS^2} = q_hat / m2_hat, eq. (late-variance-hat) ---
   nu_i(l)   = ITT_i - l FS_i
   V_nu,i(l) = V_ITT,i + l^2 V_FS,i - 2 l C_i
   g_i(l)    = nu_i(l)^2 - V_nu,i(l)
   q_hat     = Q_hat(LATE_FS2) = (1/n) sum w_hat_i g_i(LATE_FS2)             */
gen nu_s = I_s - L_FS2*F_s
gen V_nu_s = VI_s + (L_FS2^2)*VF_s - 2*L_FS2*C_s
gen g_s = nu_s^2 - V_nu_s
sum g_s [aw=prop2]
scalar q_hat=r(sum)
scalar var_FS2=q_hat/m2_hat

/* ---- (2) Lower bound for sigma^2_LATE, eq. (late-variance-lower-bound-hat)
   h_hat     = Q_hat(LATE) = (1/n) sum w_hat_i g_i(LATE)   (same g, at l = LATE)
   d_hat     = r_hat - m2_hat LATE
   delta_hat = FS - m2_hat                                  (must be > 0)
   bound     = h_hat / FS + d_hat^2 / (FS delta_hat)                          */
gen g_h = (I_s - Lbar*F_s)^2 - (VI_s + (Lbar^2)*VF_s - 2*Lbar*C_s)
sum g_h [aw=prop2]
scalar h_hat=r(sum)
scalar d_hat=r_hat - m2_hat*Lbar
scalar delta_hat=Fbar - m2_hat
if delta_hat > 0 {
scalar bound=h_hat/Fbar + d_hat^2/(Fbar*delta_hat)
}
else {
scalar bound=.
}

/* ---- Influence functions (sample analogues) ------------------------------
   psi_LATE,i = w_hat_i (ITT_i - LATE FS_i) / FS              eq. (AL-lambda-late-proof)
   psi_LFS2,i = w_hat_i [(FS_i ITT_i - C_i) - LATE_FS2 (FS_i^2 - V_FS,i)] / m2_hat
                (delta method on r_hat/m2_hat; the centering terms cancel
                 because r_hat = LATE_FS2 * m2_hat)
   psi_q,i    = w_hat_i [g_i(LATE_FS2) - q]                   eq. (psi-q-late)
   psi_FS2,i  = w_hat_i [FS_i^2 - V_FS,i - m2]                eq. (psi-fs-second-moment)
   psi_var,i  = (psi_q,i - sigma^2_{LATE,FS^2} psi_FS2,i)/m2  eq. (psi-late-variance)
   Lower bound:
   psi_r,i    = w_hat_i [FS_i ITT_i - C_i - r]
   psi_FS,i   = w_hat_i [FS_i - FS]
   psi_h,i    = w_hat_i [g_i(LATE) - h] + 2 (m2 LATE - r) psi_LATE,i
                                                               eq. (psi-late-bound-numerator)
   psi_d,i    = psi_r,i - LATE psi_FS2,i - m2 psi_LATE,i
   psi_delta,i= psi_FS,i - psi_FS2,i
   psi_bound,i= [psi_h,i + (2d/delta) psi_d,i - (d^2/delta^2) psi_delta,i
                 - bound psi_FS,i] / FS                      eq. (psi-late-variance-lower-bound)
   V_hat = (1/n) sum psi_i^2 and SE = sqrt(V_hat/n)           eqs. (Vhat-late-variance),
                                                               (Vhat-late-variance-lower-bound)
   (the sample means of the estimated IFs are exactly zero, so demeaning is
    immaterial)                                                             */
gen psi_LATE = wtildes*(I_s - Lbar*F_s)/Fbar
gen psi_LFS2 = wtildes*(for_r - L_FS2*for_m2)/m2_hat
gen psi_var  = (wtildes*(g_s - q_hat) - var_FS2*wtildes*(for_m2 - m2_hat))/m2_hat
gen psi_r    = wtildes*(for_r - r_hat)
gen psi_FS2  = wtildes*(for_m2 - m2_hat)
gen psi_FS   = wtildes*(F_s - Fbar)
gen psi_h    = wtildes*(g_h - h_hat) + 2*(m2_hat*Lbar - r_hat)*psi_LATE
gen psi_d    = psi_r - Lbar*psi_FS2 - m2_hat*psi_LATE
gen psi_delta= psi_FS - psi_FS2
gen psi_bound= (psi_h + (2*d_hat/delta_hat)*psi_d - (d_hat^2/delta_hat^2)*psi_delta - bound*psi_FS)/Fbar

foreach v in psi_LATE psi_LFS2 psi_var psi_bound {
sum `v'
gen sq_`v'=(`v'-r(mean))^2
sum sq_`v'
scalar se_`v'=sqrt(r(mean)/r(N))
}
scalar se_LATE=se_psi_LATE
scalar se_LFS2=se_psi_LFS2
scalar se_var=se_psi_var
scalar se_bound=se_psi_bound

ereturn clear
ereturn scalar LATE_hat=Lbar
ereturn scalar se_late_hat=se_LATE
ereturn scalar lb_CI_late=Lbar-1.96*se_LATE
ereturn scalar ub_CI_late=Lbar+1.96*se_LATE

ereturn scalar var_LATE_lb=bound
ereturn scalar se_var_late_lb=se_bound
ereturn scalar lb_CI_var_late_lb=bound-1.96*se_bound
ereturn scalar ub_CI_var_late_lb=bound+1.96*se_bound

ereturn scalar LATE_FS2_hat=L_FS2
ereturn scalar se_late_FS2_hat=se_LFS2
ereturn scalar lb_CI_late_FS2=L_FS2-1.96*se_LFS2
ereturn scalar ub_CI_late_FS2=L_FS2+1.96*se_LFS2

ereturn scalar var_LATE=var_FS2
ereturn scalar se_var_late=se_var
ereturn scalar lb_CI_var_late=var_FS2-1.96*se_var
ereturn scalar ub_CI_var_late=var_FS2+1.96*se_var

ereturn scalar ratio_sd_late=sqrt(var_FS2)/L_FS2
ereturn scalar mean_FS=Fbar
ereturn scalar mean_FS2=m2_hat

ereturn scalar N = `total_obs'
ereturn scalar Sites = `num_site'

// Output the Final Table
* Create the Output Matrix
matrix mat_res_XX = J(5, 6, .)

* Display Filling
matrix mat_res_XX[1, 1] = Lbar
matrix mat_res_XX[2, 1] = bound
matrix mat_res_XX[3, 1] = L_FS2
matrix mat_res_XX[4, 1] = var_FS2
matrix mat_res_XX[5, 1] = sqrt(var_FS2)/L_FS2

matrix mat_res_XX[1, 2] = se_LATE
matrix mat_res_XX[2, 2] = se_bound
matrix mat_res_XX[3, 2] = se_LFS2
matrix mat_res_XX[4, 2] = se_var

matrix mat_res_XX[1, 3] = Lbar - 1.96 * se_LATE // Lower bound
matrix mat_res_XX[2, 3] = bound - 1.96 * se_bound // Lower bound
matrix mat_res_XX[3, 3] = L_FS2 - 1.96 * se_LFS2 // Lower bound
matrix mat_res_XX[4, 3] = var_FS2 - 1.96 * se_var // Lower bound
matrix mat_res_XX[1, 4] = Lbar + 1.96 * se_LATE // Upper bound
matrix mat_res_XX[2, 4] = bound + 1.96 * se_bound // Upper bound
matrix mat_res_XX[3, 4] = L_FS2 + 1.96 * se_LFS2 // Upper bound
matrix mat_res_XX[4, 4] = var_FS2 + 1.96 * se_var // Upper bound

forvalues k=1/5 {
matrix mat_res_XX[`k', 5] = `num_site'  // Number of Sites
matrix mat_res_XX[`k', 6] = `total_obs'  // Total Observations
}
}

matrix rownames mat_res_XX = "LATE, complier weights" "Var. LATEs, compl. w., LB" "LATE, FS^2 weights" "Var. LATEs, FS^2 weights" "sd/LATE, FS^2 weights"
matrix colnames mat_res_XX = "Estimate" "SE"  "95% LB" "95% UB" "# Sites" "# Units"

* Display the Table
di "{hline 93}"
di _skip(25) "{bf: Estimators of Variance of LATE in Multi-site RCT}"
di "{hline 93}"
noisily matlist mat_res_XX, border(rows) twidth(25)
if delta_hat <= 0 {
di as error "The lower bound for the complier-weighted variance is not defined: the corrected mean of squared first stages is not below the mean first stage."
}
di as text "The development of this package was funded by the European Union (ERC, REALLYCREDIBLE,GA N°101043899)."

restore
end
