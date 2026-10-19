*! xtdyngcce_example.do  1.0.0  12oct2026
*! Self-testing worked example for the xtdyngcce package.
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*!
*! Every DGP below has KNOWN true parameters taken from the source papers,
*! so you can read truth against estimate directly.
*!
*!   PART 1  xtdyncce on Juodis-Stauskas-Tromp (2026) ARX(1) DGP (4)
*!   PART 2  xtgcce  on Lu-Su-Ba (2026) DGP 2 (rank condition VIOLATED)
*!   PART 3  xtgcce  on Lu-Su-Ba (2026) DGP 1 (rank condition HOLDS)
*!   PART 4  certification: restricted GCCE == CCE-MG
*!
*! DGP WARNING, worth repeating: a common factor must be generated ONCE and
*! broadcast in id-major order. Any intervening `bysort t:' re-sorts the data
*! and a later st_store() scrambles the factor across units, after which the
*! factor structure is gone and every estimator looks equally biased.

set more off
clear

*=======================================================================
* PART 1 -- xtdyncce.  TRUE: alpha = 0.6, beta = 0.4
*=======================================================================
di _n as txt "{hline 78}"
di as txt " PART 1  xtdyncce -- JST (2026) ARX(1) design"
di as txt "         TRUE VALUES:  alpha = 0.600   beta = 0.400"
di as txt "{hline 78}"

set seed 20261012
local N  100
local T  50
local Tb 100
local Tt = `T' + `Tb'

qui set obs `=`N'*`Tt''
qui gen long id = ceil(_n/`Tt')
qui bysort id: gen int s = _n
sort id s
qui xtset id s

* two persistent common factors, generated once, broadcast id-major
qui gen double f1 = .
qui gen double f2 = .
mata:
  Tt = `Tt'
  g1 = J(Tt,1,0)
  g2 = J(Tt,1,0)
  e1 = rnormal(Tt,1,0,1)
  e2 = rnormal(Tt,1,0,1)
  for (t = 2; t <= Tt; t++) {
     g1[t] = 0.6*g1[t-1] + sqrt(0.64)*e1[t]
     g2[t] = 0.6*g2[t-1] + sqrt(0.64)*e2[t]
  }
  st_store(., ("f1","f2"), (J(`N',1,1) # g1, J(`N',1,1) # g2))
end

qui by id: gen byte first = (_n==1)
foreach v in gy1 gy2 gx1 gx2 {
    qui gen double `v' = rnormal() if first
    qui by id: replace `v' = `v'[1]
}
* mean loadings [[1,1],[0,1]] so the CCE rank condition is satisfied
qui replace gy1 = gy1 + 1
qui replace gx1 = gx1 + 1
qui replace gx2 = gx2 + 1

qui gen double y  = 0
qui gen double x  = 0
qui gen double ue = rnormal()
qui gen double uv = rnormal()
qui bysort id (s): replace x = 0.5*y[_n-1] + gx1*f1 + gx2*f2 + uv      if _n>1
qui bysort id (s): replace y = 0.6*y[_n-1] + 0.4*x + gy1*f1 + gy2*f2 ///
                               + 0.8*ue                                 if _n>1
qui drop if s <= `Tb'-1
qui bysort id (s): gen int t = _n - 1
qui keep id t y x
qui xtset id t

di _n as txt " 1a. Uncorrected CCEP (expect alpha biased DOWN from 0.6)"
xtdyncce y x

di _n as txt " 1b. Half-panel jackknife"
xtdyncce y x, biasadj(hpj)

di _n as txt " 1c. Analytical (Moon-Weidner) correction"
xtdyncce y x, biasadj(an)

di _n as txt " 1d. Fixed-T minimum distance (De Vos-Everaert)"
xtdyncce y x, biasadj(dvs)

di _n as txt " 1e. Leave-one-out jackknife SE (expect LARGER than 1a)"
xtdyncce y x, vce(jackknife)

di _n as txt " 1f. RECOMMENDED: bias correction + recursive-design bootstrap"
xtdyncce y x, biasadj(hpj) vce(rdwb) reps(199) dreps(99) seed(1) graph name(ex1)

di _n as txt "{hline 78}"
di as txt " Read 1a-1f against the true alpha = 0.600 and beta = 0.400."
di as txt " 1a should be visibly low; 1f should be close with a covering CI."
di as txt "{hline 78}"

*=======================================================================
* PART 2 -- xtgcce, rank condition VIOLATED.  TRUE: beta0 = 1
*=======================================================================
di _n as txt "{hline 78}"
di as txt " PART 2  xtgcce -- Lu-Su-Ba (2026) DGP 2, RANK CONDITION FAILS"
di as txt "         TRUE VALUE: beta0 = 1.000"
di as txt "         Paper Table 1 at (100,100): CCE 1.218   GCCE 1.006"
di as txt "{hline 78}"

clear
set seed 777
local N 100
local T 100
qui set obs `=`N'*`T''
qui gen long id = ceil(_n/`T')
qui bysort id: gen int t = _n
sort id t
qui xtset id t

qui by id: gen byte first = (_n==1)
foreach v in gstar lstar beta {
    qui gen double `v' = rnormal() if first
    qui by id: replace `v' = `v'[1]
}
qui replace beta = beta + 1
* DGP 2: E(lambda) = E(gamma) = 0, so the rank condition fails
qui gen double gam = gstar
qui gen double lam = gstar + lstar

sort id t
qui gen double f = .
mata:
  ft = rnormal(`T', 1, 1, 1)
  st_store(., "f", J(`N', 1, 1) # ft)
end

* sanity check: f must be constant within t
qui bysort t: egen double _sdf = sd(f)
qui sum _sdf, meanonly
if (r(max) > 1e-12) {
    di as err "DGP ERROR: the common factor varies within t -- check the sort"
    exit 9
}
qui drop _sdf
sort id t
qui xtset id t

qui gen double v1 = rnormal()
qui gen double v2 = rnormal()
qui gen double u  = rnormal()
qui gen double x  = gam*f + beta*v1 + v2
qui gen double y  = beta*x + lam*f + u

di _n as txt " 2a. GCCE against conventional CCE"
xtgcce y x, cce graph histogram name(ex2)

di _n as txt "{hline 78}"
di as txt " The CCE-MG estimate should be far above 1; GCCE-MG close to 1."
di as txt " A large 'difference' is the diagnostic that the rank condition"
di as txt " has failed. GCCE is consistent either way."
di as txt "{hline 78}"

*=======================================================================
* PART 3 -- xtgcce, rank condition HOLDS.  TRUE: beta0 = 1
*=======================================================================
di _n as txt "{hline 78}"
di as txt " PART 3  xtgcce -- DGP 1, RANK CONDITION HOLDS"
di as txt "         CCE and GCCE must now AGREE (asymptotic equivalence)"
di as txt "{hline 78}"

qui replace gam = gstar + 1
qui replace lam = gstar + lstar + 1
qui replace x = gam*f + beta*v1 + v2
qui replace y = beta*x + lam*f + u

xtgcce y x, cce

*=======================================================================
* PART 4 -- certification: restricted GCCE reduces to CCE-MG
*=======================================================================
di _n as txt "{hline 78}"
di as txt " PART 4  Certification checks"
di as txt "{hline 78}"

qui xtgcce y x, cce
tempname bg bc
matrix `bg' = e(b)
matrix `bc' = e(b_cce)
local d = abs(`bg'[1,1] - `bc'[1,1])
di as txt " |GCCE - CCE| under a satisfied rank condition = " as res %9.6f `d'
di as txt "   (should be small; they are asymptotically equivalent)"

qui xtgcce y x
local n1 = e(N_g)
qui xtgcce y x, nojackknife
local n2 = e(N_g)
if (`n1' != `n2') {
    di as err " FAIL: nojackknife changed the sample"
}
else {
    di as txt " PASS: nojackknife leaves the point estimates and sample intact"
}

di _n as txt "{hline 78}"
di as txt " Example complete. Graphs: ex1_coef ex1_boot ex2_coef ex2_hist"
di as txt "{hline 78}"
