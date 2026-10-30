*! xtboundpanico_cvgen.do   1.0.0  27oct2026
* Regenerates the asymptotic p-value grids embedded in xtboundpanico.ado
* (_xbp_pgrid and _xbp_qgrid).
* Author: Dr Merwan Roudane -- merwanroudane920@gmail.com
*         https://github.com/merwanroudane
*
* The per-unit ADF statistic on the recumulated idiosyncratic residual uhat*
* has two different limiting distributions, and neither is tabulated inside
* Stata:
*
*   case c   (Models 0 and 1) -- Bai and Ng (2004), Theorem 1.1:
*       ADF^c  =>  int W dW / (int W^2)^(1/2)
*     i.e. the Dickey-Fuller distribution with NO deterministic terms.
*
*   case tau (Model 2)        -- Bai and Ng (2004), Theorem 3.1:
*       ADF^tau  =>  -(1/2) (int_0^1 V(s)^2 ds)^(-1/2),   V a Brownian bridge
*     which is NOT a Dickey-Fuller distribution: it is proportional to the
*     reciprocal of a Brownian bridge functional.  Using Dickey-Fuller tables
*     here is a real and easy mistake -- the 5% points are -1.95 and -2.62.
*
* Both are simulated directly from their limiting functionals with S steps and
* R replications, exactly as the paper describes doing for its own moments.
*
* THE CHECK THAT THE READING IS RIGHT: the simulated moments must match
* footnote 3 of Banerjee and Carrion-i-Silvestre (2026),
*     (mu_c,   sigma^2_c  ) = (-0.42608, 0.95743)
*     (mu_tau, sigma^2_tau) = (-1.53627, 0.34107)
* and the case-c 5% point must match Bai and Ng's -1.95.
*
* Run time is a few minutes at R = 1,000,000.  Reduce R for a quick check.

clear all
set more off

local S 1000          // steps used to approximate the Brownian functionals
local R 1000000       // replications
local SEED 31415926

mata:
mata set matastrict off
S = `S'
R = `R'
rseed(`SEED')
tc  = J(R,1,.)
tt  = J(R,1,.)
idx = (1::S):/S
for (r=1; r<=R; r++) {
    e  = rnormal(S,1,0,1)
    w  = runningsum(e)
    wl = (0 \ w[|1 \ S-1|])
    // case c: the Dickey-Fuller statistic with no deterministic terms
    tc[r] = (wl'*e) / sqrt(wl'*wl)
    // case tau: -0.5 * (int V^2)^(-1/2) with V the Brownian bridge
    v  = w - idx:*w[S]
    tt[r] = -0.5 / sqrt((v'*v)/S^2)
}

printf("\n{hline 78}\n")
printf("Moment check against footnote 3 of the paper\n")
printf("{hline 78}\n")
printf("case c  : mean %10.5f  var %10.5f   (paper -0.42608  0.95743)\n",
       mean(tc), variance(tc))
printf("case tau: mean %10.5f  var %10.5f   (paper -1.53627  0.34107)\n",
       mean(tt), variance(tt))
sc = sort(tc,1)
st = sort(tt,1)
printf("case c   5%% point %9.4f   (Bai and Ng 2004: -1.95)\n", sc[round(.05*R)])
printf("case tau 5%% point %9.4f\n", st[round(.05*R)])
printf("{hline 78}\n")

// the grid actually embedded in the ado: denser in the tails
pg = (0.0004,0.0010,0.0020,0.0040,0.0060,0.0100,0.0140,0.0200,0.0260)'
pg = pg \ range(0.03,0.97,0.01)
pg = pg \ (0.9740,0.9800,0.9860,0.9900,0.9940,0.9960,0.9980,0.9996)'
st_matrix("PG", pg)
st_matrix("QC", sc[round(pg:*R)])
st_matrix("QT", st[round(pg:*R)])
printf("grid points: %g\n", rows(pg))
end

* write the three vectors out in the form pasted into _xbp_pgrid / _xbp_qgrid
tempname fh
file open `fh' using "xtboundpanico_cvgrids.txt", write replace text
local n = rowsof(PG)
foreach m in PG QC QT {
    file write `fh' "`m'  (`n' values)" _n
    forvalues i = 1/`n' {
        file write `fh' (string(`m'[`i',1], "%12.5f")) " "
        if (mod(`i',10) == 0) file write `fh' _n
    }
    file write `fh' _n _n
}
file close `fh'

di _n "Grids written to xtboundpanico_cvgrids.txt."
di    "Paste them into _xbp_pgrid() and _xbp_qgrid() in xtboundpanico.ado,"
di    "keeping the string-building form -- a single numeric literal of that"
di    "length exceeds Mata's per-statement token limit."
