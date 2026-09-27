*! cointvol_simulate 0.1.0  26sep2026
*! Data-generating processes used in the Monte Carlo studies of the cointegration-
*! under-volatility literature (GARCH family, SV, variance breaks, BEKK, CCC, FIGARCH,
*! OU volatility, stochastic / heteroskedastic cointegration, cointegrated VAR)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (full map in cointvol_simulate.sthlp):
*!   garch/ccc : h = w + a e2 + b h, w = 1-a-b default, burn-in 500
*!               -> Lee & Tse (1996) s.2, Tables 1-6; Franses, Kofman & Moser (1994) s.3
*!   egarch    : ln h = w + a(|z| - E|z|) + th z + b ln h -> Lee & Tse (1996) Table 6; CRT (2010, ET) model C
*!   agarch    : h = w + a(e - g)^2 + b h -> CRT (2010, ET) model D (Engle 1990)
*!   gjr       : h = w + a e2 + g 1(e<0) e2 + b h -> CDRT (2018) case A; CRT (2010, ET) model E
*!   skewt     : Hansen (1994) eqs (10)-(13), exact inverse-CDF draws; CDRT case A maps
*!               (nu, delta) = (5, -0.1) to Hansen's (eta, lambda); omega = 1 - a - g kappa - b,
*!               kappa = E[z^2 1(z<0)] in closed form (unit unconditional variance)
*!   sv        : e = v exp(h), h = lam h + 0.5 xi -> CRT (2010, ET) model F; CDRT case B
*!   break     : variance shifts at floor(tau T) -> CRT (2010, JoE) s.5; CDRT case C; BCDT s.5;
*!               Cavaliere & Taylor (2006) eq (9); Maki (2013) eqs (50)-(51); BCRT (2016) s.5
*!   bekk      : H = C + A e e' A' + B H B' -> Maki (2013) eqs (37)-(38); Kurita (2009) s.4
*!   figarch   : CCC-FIGARCH(1,d,1), truncation 1000 -> Maki (2013) eqs (43)-(45)
*!   oupath    : Sigma_t = exp(2H(t/T)) Sigma, dH = -kappa H du + zeta dB -> Boswijk & Zu (2022) case 4
*!   stochcoint: Harris, McCabe & Leybourne (2002) s.4; McCabe, Leybourne & Harris (2006) eq (10)
*!   hci       : Hansen (1992) eqs (1)-(4)
*!   vecm      : dX = a(b'X + rho') + sum G dX + mu + e -> CRT (2010ab), CDRT (2018), BCRT (2016)

program define cointvol_simulate, rclass
    version 14.0
    syntax , Nobs(integer) DGP(string) [ CLEAR SEED(string) BURNin(integer -1)       ///
        NVars(integer -1) PREfix(name) HPREfix(name) EPREfix(name) TVar(name)          ///
        PRESET(string) OMEGA(string) ARCH(string) GARCH(string) ASYM(string)           ///
        SHIFT(string) THETA(string) SQuared NOCENTER DISTribution(string)              ///
        DF(real 5) SKEW(string) LAMbda(string) SIGXI(string)                           ///
        TAU(numlist >0 <1) SDRatio(numlist >0) VARRatio(numlist >0)                    ///
        SERies(numlist integer >0) BSPEC(name) BASE(string) VCASE(integer 2)           ///
        RHO(string) SIGma(name) CMAT(name) AMAT(name) BMAT(name)                       ///
        FRACD(string) FCONst(string) FPHI(string) TRUNC(integer 1000)                  ///
        KAPPA(real 1) ZETA(real 1) PATHSEED(string)                                    ///
        TYPE(string) PHI(real 0) PIY(real 1) PIX(real 1) RHO34(real 0)                 ///
        VSD(real 0.2236068) D1(real 0) D2(real 0) D3(real 0) PHIEY(real 0)             ///
        PHIEX(real 0) PHIVY(real 0) PHIVX(real 0) B0(real 0) B1(real 1)                ///
        SIGMA0(real 1) S2(real 1) R12(real 0) R13(real 0) R23(real 0)                  ///
        ALPha(name) BETa(name) GAMma(name) RCONst(name) MU(name) INNOV(string)         ///
        PRESample(integer 0) ]

    // ---------------- load the Mata engines (core first) -------------------
    capture mata: st_local("__cvver", cv_engine_version())
    if _rc {
        capture program drop cointvol_engine
        quietly findfile cointvol_engine.ado
        quietly run `"`r(fn)'"'
    }
    capture mata: st_local("__cvdver", cvd_version())
    if _rc {
        capture program drop cointvol_eng_diag
        quietly findfile cointvol_eng_diag.ado
        quietly run `"`r(fn)'"'
    }

    // ---------------- dgp / innovation model ---------------------------------
    local dgp = strlower(strtrim(`"`dgp'"'))
    local dgps "iid garch egarch agarch gjr sv break bekk ccc figarch oupath stochcoint hci vecm"
    local okd : list dgp in dgps
    if !`okd' {
        di as err "dgp() must be one of: `dgps'"
        exit 198
    }
    local innov = strlower(strtrim(`"`innov'"'))
    local ins "iid garch egarch agarch gjr sv break bekk ccc figarch oupath"
    if "`dgp'" == "vecm" {
        if "`innov'" == "" local innov "iid"
        local oki : list innov in ins
        if !`oki' {
            di as err "innov() must be one of: `ins'"
            exit 198
        }
    }
    else {
        if "`innov'" != "" {
            di as err "innov() is only allowed with dgp(vecm)"
            exit 198
        }
        local innov "`dgp'"
    }
    local it "`innov'"
    local preset = strlower(strtrim(`"`preset'"'))
    if `nobs' < 10 {
        di as err "nobs() must be at least 10"
        exit 198
    }
    if `presample' < 0 {
        di as err "presample() must be non-negative"
        exit 198
    }
    if "`clear'" == "" {
        if c(N) > 0 | c(k) > 0 {
            di as err "no; data in memory would be lost (specify option clear)"
            exit 4
        }
    }
    if "`prefix'"  == "" local prefix "y"
    if "`eprefix'" == "" local eprefix "e"
    if "`hprefix'" == "" local hprefix "h"
    if "`tvar'"    == "" local tvar "t"
    foreach o in omega arch garch asym shift theta skew lambda sigxi fracd fconst fphi base rho {
        if `"``o''"' != "" {
            capture confirm number ``o''
            if _rc {
                di as err "`o'() must be a number"
                exit 198
            }
        }
    }
    local distribution = strlower(strtrim(`"`distribution'"'))
    local userdist = (`"`distribution'"' != "")
    if !`userdist' local distribution "normal"
    if inlist("`distribution'", "gauss", "gaussian", "n") local distribution "normal"
    if inlist("`distribution'", "student") local distribution "t"
    if !inlist("`distribution'", "normal", "t", "skewt") {
        di as err "distribution() must be normal, t or skewt"
        exit 198
    }

    // ---------------- number of series -------------------------------------
    if "`dgp'" == "stochcoint" local nvars 2
    if "`it'" == "bekk" & "`cmat'" != "" {
        local nvars = rowsof(`cmat')
    }
    if "`dgp'" == "vecm" & "`alpha'" != "" {
        local nvars = rowsof(`alpha')
    }
    if `nvars' == -1 local nvars 2
    if `nvars' < 1 {
        di as err "nvars() must be positive"
        exit 198
    }
    if "`dgp'" == "hci" & `nvars' < 2 {
        di as err "dgp(hci) needs nvars() >= 2 (y and at least one regressor)"
        exit 198
    }
    local p `nvars'

    // ---------------- innovation-model parameters -------------------------
    local src ""
    local plab ""
    local P_omega .
    local P_arch .
    local P_garch .
    local P_asym .
    local P_shift .
    local P_theta .
    local P_center 1
    local P_sq 0
    local P_lambda .
    local P_sigxi .
    local P_fracd .
    local P_fconst .
    local P_fphi .
    local P_trunc `trunc'
    local P_kappa `kappa'
    local P_zeta `zeta'
    local P_base .
    local P_vcase `vcase'
    local P_oufix 0
    local rhodef 0
    local omnote ""
    if "`skew'" == "" local skew 0
    if !inlist(`vcase', 2, 3) {
        di as err "vcase() must be 2 or 3"
        exit 198
    }

    if inlist("`it'", "garch", "ccc") {
        local pa .3
        local pb .65
        local pw ""
        if "`it'" == "ccc" local rhodef .5
        if "`preset'" == "lt1"   {
            local pa .3
            local pb .6
        }
        if "`preset'" == "lt2"   {
            local pa .3
            local pb .65
        }
        if "`preset'" == "lt3"   {
            local pa .3
            local pb .699
        }
        if "`preset'" == "lt4"   {
            local pa .1
            local pb .8
        }
        if "`preset'" == "lt5"   {
            local pa .1
            local pb .85
        }
        if "`preset'" == "lt6"   {
            local pa .1
            local pb .899
        }
        if "`preset'" == "ltig"  {
            local pa .3
            local pb .7
            local pw 1
        }
        if "`preset'" == "ks1"   {
            local pa .3
            local pb .7
            local pw .01
        }
        if "`preset'" == "ks09"  {
            local pa .09
            local pb .91
            local pw .0009
        }
        if "`preset'" == "ks001" {
            local pa .03
            local pb .97
            local pw .0001
        }
        if "`preset'" == "maki1" {
            local pa .09
            local pb .09
            local pw 1
        }
        if "`preset'" == "maki2" {
            local pa .36
            local pb .36
            local pw 1
        }
        if "`preset'" == "maki3" {
            local pa .16
            local pb .64
            local pw 1
        }
        if "`preset'" == "maki4" {
            local pa .64
            local pb .16
            local pw 1
        }
        if "`preset'" == "crt1" {
            local pa 0
            local pb 0
        }
        if "`preset'" == "crt2" {
            local pa .5
            local pb 0
        }
        if "`preset'" == "crt3" {
            local pa .3
            local pb .65
        }
        if "`preset'" == "crt4" {
            local pa .2
            local pb .79
        }
        if "`preset'" == "crt5" {
            local pa .05
            local pb .94
        }
        if "`preset'" != "" & !inlist("`preset'", "lt1", "lt2", "lt3", "lt4", "lt5", "lt6", "ltig") ///
            & !inlist("`preset'", "ks1", "ks09", "ks001", "maki1", "maki2", "maki3", "maki4") ///
            & !inlist("`preset'", "crt1", "crt2", "crt3", "crt4", "crt5") {
            di as err "preset(`preset') not available for `it'"
            exit 198
        }
        if "`arch'"  == "" local arch  `pa'
        if "`garch'" == "" local garch `pb'
        if "`omega'" == "" {
            if "`pw'" != "" local omega `pw'
            else if `arch' + `garch' < 1 local omega = 1 - `arch' - `garch'
            else {
                local omega 1
                local omnote "(a + b >= 1: omega = 1 as in Franses, Kofman & Moser 1994)"
            }
        }
        local P_omega `omega'
        local P_arch  `arch'
        local P_garch `garch'
        local plab "omega = `omega', arch a = `arch', garch b = `garch'"
        local src "Lee & Tse (1996) s.2; Franses, Kofman & Moser (1994); CRT (2010, ET) model A"
        if "`it'" == "ccc" local src "Lee & Tse (1996) Table 6 (CCC); Maki (2013)"
    }
    if "`it'" == "egarch" {
        if "`preset'" == "" local preset "leetse"
        if !inlist("`preset'", "leetse", "leetse50", "crt") {
            di as err "preset() for egarch must be leetse, leetse50 or crt"
            exit 198
        }
        local pw -.0082
        local pa .19
        local pt -.19
        local pb .91
        local cen 1
        if "`preset'" == "leetse50" local pt -.5
        if "`preset'" == "crt" {
            local pw -.23
            local pa .25
            local pt -.075
            local pb .9
            local cen 0
        }
        if "`omega'" == "" local omega `pw'
        if "`arch'"  == "" local arch  `pa'
        if "`theta'" == "" local theta `pt'
        if "`garch'" == "" local garch `pb'
        if "`nocenter'" != "" local cen 0
        local P_omega  `omega'
        local P_arch   `arch'
        local P_theta  `theta'
        local P_garch  `garch'
        local P_center `cen'
        local P_sq = ("`squared'" != "")
        local plab "omega = `omega', a = `arch', theta = `theta', b = `garch', centred = `cen', squared = `P_sq'"
        local src "Lee & Tse (1996) Table 6 (French & Sichel 1993); CRT (2010, ET) model C"
    }
    if "`it'" == "agarch" {
        if "`preset'" != "" & "`preset'" != "crt" {
            di as err "preset() for agarch must be crt"
            exit 198
        }
        if "`omega'" == "" local omega .0216
        if "`arch'"  == "" local arch  .3174
        if "`shift'" == "" local shift .1108
        if "`garch'" == "" local garch .6896
        local P_omega `omega'
        local P_arch  `arch'
        local P_shift `shift'
        local P_garch `garch'
        local plab "omega = `omega', a = `arch', shift = `shift', b = `garch'"
        local src "CRT (2010, ET) model D (Engle 1990 asymmetric GARCH)"
    }
    if "`it'" == "gjr" {
        if "`preset'" == "" local preset "cdrt"
        if !inlist("`preset'", "cdrt", "crt") {
            di as err "preset() for gjr must be cdrt or crt"
            exit 198
        }
        if "`preset'" == "cdrt" {
            local pa .03
            local pg .04
            local pb .92
            local pw ""
            if !`userdist' local distribution "skewt"
            if "`skew'" == "0" local skew -.1
        }
        else {
            local pa .166012
            local pg .2576
            local pb .7
            local pw .005
        }
        if "`arch'"  == "" local arch  `pa'
        if "`asym'"  == "" local asym  `pg'
        if "`garch'" == "" local garch `pb'
        * kappa = E[z^2 1(z < 0)]: 1/2 for symmetric shocks, closed form for the Hansen (1994) skewed t
        local gkap 0.5
        if "`distribution'" == "skewt" & `df' > 2 & abs(`skew') < 1 {
            mata: st_local("gkap", strtrim(strofreal(cvd_skt_kappa(`df', `skew'), "%20.15f")))
        }
        if "`omega'" == "" {
            if "`pw'" != "" local omega `pw'
            else local omega = 1 - `arch' - `asym'*`gkap' - `garch'
            if "`pw'" == "" {
                local omnote : display "(omega = 1 - a - g kappa - b, kappa = E[z^2 1(z<0)] = " %8.6f `gkap'
                local omnote "`omnote': unit unconditional variance; CDRT 2018 do not report omega)"
            }
        }
        local P_omega `omega'
        local P_arch  `arch'
        local P_asym  `asym'
        local P_garch `garch'
        local plab : display "omega = " %9.7f `omega' ", a = `arch', g = `asym', b = `garch'"
        local src "CDRT (2018) case A (skewed t: Hansen 1994, eqs 10-13); CRT (2010, ET) model E"
    }
    if "`it'" == "sv" {
        if "`preset'" == "" local preset "crt"
        if !inlist("`preset'", "crt", "crt2") {
            di as err "preset() for sv must be crt or crt2"
            exit 198
        }
        local pl .951
        local ps .314
        if "`preset'" == "crt2" {
            local pl .936
            local ps .424
        }
        if "`lambda'" == "" local lambda `pl'
        if "`sigxi'"  == "" local sigxi  `ps'
        local P_lambda `lambda'
        local P_sigxi  `sigxi'
        local plab "lambda = `lambda', sigma_xi = `sigxi'"
        local src "CRT (2010, ET) model F; CDRT (2018) case B; BCDT (2022)"
    }
    if "`it'" == "figarch" {
        if "`preset'" == "" local preset "maki1"
        local ok 0
        forvalues j = 1/12 {
            if "`preset'" == "maki`j'" local ok `j'
        }
        if !`ok' {
            di as err "preset() for figarch must be maki1, ..., maki12"
            exit 198
        }
        local jj = mod(`ok' - 1, 6) + 1
        local pd = cond(`jj' <= 3, .4, .8)
        local pa = cond(inlist(`jj', 1, 4), .4, cond(inlist(`jj', 2, 5), .2, .6))
        local pb = cond(inlist(`jj', 1, 4), .4, cond(inlist(`jj', 2, 5), .6, .2))
        local rhodef = cond(`ok' > 6, .8, 0)
        if "`fracd'"  == "" local fracd `pd'
        if "`arch'"   == "" local arch  `pa'
        if "`garch'"  == "" local garch `pb'
        if "`fconst'" == "" {
            local fconst .1
            local omnote "(c = 0.1 is provisional: Maki 2013 does not report c)"
        }
        if "`fphi'"   == "" local fphi = 1 - `arch' - `garch'
        if `trunc' < 10 {
            di as err "trunc() must be at least 10"
            exit 198
        }
        local P_fracd  `fracd'
        local P_fconst `fconst'
        local P_fphi   `fphi'
        local P_garch  `garch'
        local P_arch   `arch'
        local plab "c = `fconst', d = `fracd', a = `arch', b = `garch', phi = `fphi', truncation = `trunc'"
        local src "Maki (2013) eqs (43)-(45), FIGARCH`ok' (Brunetti & Gilbert 2000); provisional"
    }
    if "`it'" == "bekk" {
        tempname Cm Am Bm
        if "`cmat'`amat'`bmat'" != "" {
            if "`cmat'" == "" | "`amat'" == "" | "`bmat'" == "" {
                di as err "bekk: specify all of cmat(), amat() and bmat()"
                exit 198
            }
            matrix `Cm' = `cmat'
            matrix `Am' = `amat'
            matrix `Bm' = `bmat'
            local preset "user"
        }
        else {
            if "`preset'" == "" local preset "maki5"
            local ps ""
            local pw ""
            if "`preset'" == "maki5" {
                local ps .3
                local pw .3
            }
            if "`preset'" == "maki6" {
                local ps .6
                local pw .6
            }
            if "`preset'" == "maki7" {
                local ps .4
                local pw .8
            }
            if "`preset'" == "maki8" {
                local ps .8
                local pw .4
            }
            if "`ps'" != "" {
                matrix `Cm' = (1, .5 \ .5, 1)
                matrix `Am' = (`ps', .5 \ 0, `ps')
                matrix `Bm' = (`pw', .5 \ 0, `pw')
            }
            local pf ""
            if "`preset'" == "kurita70" local pf .7
            if "`preset'" == "kurita80" local pf .8
            if "`preset'" == "kurita85" local pf .85
            if "`preset'" == "kurita90" local pf .9
            if "`pf'" != "" {
                matrix `Cm' = 0.0036*(1, .5 \ .5, 1)
                matrix `Am' = (.5, .5 \ 0, .5)
                matrix `Bm' = (`pf', .5 \ 0, `pf')
            }
            if "`ps'`pf'" == "" {
                di as err "preset() for bekk must be maki5-maki8 or kurita70/80/85/90"
                exit 198
            }
            local nvars 2
            local p 2
        }
        if rowsof(`Cm') != `p' | colsof(`Cm') != `p' | rowsof(`Am') != `p' | colsof(`Am') != `p' ///
            | rowsof(`Bm') != `p' | colsof(`Bm') != `p' {
            di as err "bekk: cmat(), amat() and bmat() must all be `p' x `p'"
            exit 503
        }
        local P_C `Cm'
        local P_A `Am'
        local P_B `Bm'
        local plab "BEKK(1,1) preset `preset' (see r(C), r(A), r(B))"
        local src "Maki (2013) eqs (37)-(38), GARCH5-8; Kurita (2009) eq (2) and s.4"
    }
    if "`it'" == "break" {
        local pbase 1
        local ptau ""
        local pvr ""
        if "`preset'" == "" local preset "cdrt"
        if "`preset'" == "cdrt" {
            local ptau .6666667
            local pvr 3
        }
        else if "`preset'" == "bcdt" {
            local ptau .6666667
            local pvr 9
        }
        else if "`preset'" == "bz" {
            local ptau .8
            local pvr 6
            local pbase .5
            local rhodef .4
        }
        else if "`preset'" == "bcrt" {
            local ptau .3333333
            local pvr .25
            local pbase 2
            local rhodef .4
        }
        else {
            di as err "preset() for break must be cdrt, bcdt, bz or bcrt"
            exit 198
        }
        if "`base'" == "" local base `pbase'
        if `base' <= 0 {
            di as err "base() must be positive"
            exit 198
        }
        local P_base `base'
        tempname BS
        if "`bspec'" != "" {
            matrix `BS' = `bspec'
            if colsof(`BS') != 3 {
                di as err "bspec() must have 3 columns: series, tau, variance ratio"
                exit 503
            }
        }
        else {
            if "`sdratio'" != "" & "`varratio'" != "" {
                di as err "specify only one of sdratio() and varratio()"
                exit 198
            }
            if "`tau'" == "" local tau `ptau'
            local ratios ""
            if "`sdratio'" != "" {
                foreach r of local sdratio {
                    local ratios "`ratios' `=`r'*`r''"
                }
            }
            else if "`varratio'" != "" local ratios "`varratio'"
            else local ratios "`pvr'"
            local nt : word count `tau'
            local nr : word count `ratios'
            if `nr' != `nt' & `nr' != 1 {
                di as err "the number of ratios must equal the number of tau() values (or be one)"
                exit 198
            }
            if "`series'" == "" {
                numlist "1/`p'"
                local series "`r(numlist)'"
            }
            local nrow = `: word count `series'' * `nt'
            matrix `BS' = J(`nrow', 3, .)
            local row 0
            foreach s of local series {
                if `s' > `p' {
                    di as err "series(): index `s' exceeds nvars(`p')"
                    exit 198
                }
                forvalues j = 1/`nt' {
                    local row = `row' + 1
                    local tj : word `j' of `tau'
                    local rj : word `=cond(`nr' == 1, 1, `j')' of `ratios'
                    matrix `BS'[`row', 1] = `s'
                    matrix `BS'[`row', 2] = `tj'
                    matrix `BS'[`row', 3] = `rj'
                }
            }
        }
        matrix colnames `BS' = series tau varratio
        local P_bspec `BS'
        local plab "base variance = `base', breaks in r(bspec) (series, tau, variance ratio), vcase = `vcase'"
        local src "CRT (2010, JoE) s.5; CDRT (2018) case C; BCDT (2022); Cavaliere & Taylor (2006); Maki (2013)"
    }
    if "`it'" == "oupath" {
        if "`preset'" != "" & "`preset'" != "bz" {
            di as err "preset() for oupath must be bz"
            exit 198
        }
        local rhodef .4
        local plab "kappa = `kappa', zeta = `zeta', vcase = `vcase'"
        local src "Boswijk & Zu (2022) s.5, case 4 (Euler scheme, H_0 = 0)"
    }
    if "`it'" == "iid" {
        local plab "Gaussian (or distribution()) iid innovations with covariance Sigma"
        local src "benchmark (homoskedastic) design"
    }
    if "`dgp'" == "stochcoint" {
        local type = strlower(strtrim(`"`type'"'))
        if "`type'" == "" local type "hml"
        if !inlist("`type'", "hml", "mlh") {
            di as err "type() must be hml or mlh"
            exit 198
        }
        if abs(`rho34') >= 1 {
            di as err "rho34() must lie in (-1, 1)"
            exit 198
        }
        if "`type'" == "hml" {
            local plab "phi = `phi', pi_y = `piy', pi_x = `pix', rho34 = `rho34', sd(v) = `vsd'"
            local src "Harris, McCabe & Leybourne (2002) s.4"
        }
        else {
            local plab "d1 = `d1', d2 = `d2', d3 = `d3', phi(ey,ex,vy,vx) = (`phiey',`phiex',`phivy',`phivx')"
            local src "McCabe, Leybourne & Harris (2006) eq (10)"
        }
    }
    if "`dgp'" == "hci" {
        local plab "b0 = `b0', b1 = `b1', sigma_0 = `sigma0', sd(u2) = `s2', corr = (`r12',`r13',`r23')"
        local src "Hansen (1992) eqs (1)-(4)"
    }
    if inlist("`distribution'", "t", "skewt") & `df' <= 2 {
        di as err "df() must exceed 2"
        exit 198
    }
    if abs(`skew') >= 1 {
        di as err "skew() must lie in (-1, 1)"
        exit 198
    }

    // ---------------- burn-in defaults ---------------------------------------
    if `burnin' == -1 {
        local burnin 0
        if inlist("`it'", "garch", "ccc", "egarch", "agarch", "gjr", "sv", "bekk") local burnin 500
        if "`it'" == "figarch" local burnin = `trunc' + 500
        if "`dgp'" == "stochcoint" & "`type'" == "mlh" local burnin 100
        if inlist("`dgp'", "hci") local burnin 0
    }
    if `burnin' < 0 {
        di as err "burnin() must be non-negative"
        exit 198
    }

    // ---------------- Sigma / correlation ------------------------------------
    tempname Smat
    if "`sigma'" != "" {
        matrix `Smat' = `sigma'
        if rowsof(`Smat') != `p' | colsof(`Smat') != `p' {
            di as err "sigma() must be `p' x `p'"
            exit 503
        }
    }
    else {
        if "`rho'" == "" local rho `rhodef'
        if `rho' <= -1/(`p' - 1 + (`p' == 1)) | `rho' >= 1 {
            di as err "rho() gives a non-positive-definite equicorrelation matrix"
            exit 198
        }
        matrix `Smat' = J(`p', `p', `rho')
        forvalues i = 1/`p' {
            matrix `Smat'[`i', `i'] = 1
        }
    }
    mata: st_local("__pd", strofreal(hasmissing(cholesky(st_matrix("`Smat'")))))
    if `__pd' {
        di as err "sigma()/rho(): the matrix is not positive definite"
        exit 506
    }

    // ---------------- VECM matrices ------------------------------------------
    if "`dgp'" == "vecm" {
        tempname al be ga rc mm
        if "`alpha'" == "" & "`beta'" == "" {
            if `p' != 2 {
                di as err "dgp(vecm) needs alpha() and beta() unless nvars(2) (Lee & Tse 1996 default)"
                exit 198
            }
            matrix `al' = (-0.2 \ 0)
            matrix `be' = (1 \ -1)
        }
        else {
            if "`alpha'" == "" | "`beta'" == "" {
                di as err "specify both alpha() and beta()"
                exit 198
            }
            matrix `al' = `alpha'
            matrix `be' = `beta'
        }
        if rowsof(`al') != `p' | rowsof(`be') != `p' | colsof(`al') != colsof(`be') {
            di as err "alpha() and beta() must both be `p' x r"
            exit 503
        }
        local vr = colsof(`al')
        local P_al `al'
        local P_be `be'
        local P_ga ""
        local P_rc ""
        local P_mu ""
        if "`gamma'" != "" {
            matrix `ga' = `gamma'
            if rowsof(`ga') != `p' | mod(colsof(`ga'), `p') != 0 {
                di as err "gamma() must be `p' x `p'(k-1): [Gamma_1, ..., Gamma_{k-1}]"
                exit 503
            }
            local P_ga `ga'
        }
        if "`rconst'" != "" {
            matrix `rc' = `rconst'
            if rowsof(`rc') == `vr' & colsof(`rc') == 1 & `vr' > 1 matrix `rc' = `rc''
            if rowsof(`rc') != 1 | colsof(`rc') != `vr' {
                di as err "rconst() must be 1 x r (restricted constant rho')"
                exit 503
            }
            local P_rc `rc'
        }
        if "`mu'" != "" {
            matrix `mm' = `mu'
            if colsof(`mm') == 1 & rowsof(`mm') == `p' & `p' > 1 matrix `mm' = `mm''
            if rowsof(`mm') != 1 | colsof(`mm') != `p' {
                di as err "mu() must be 1 x `p' (or `p' x 1)"
                exit 503
            }
            local P_mu `mm'
        }
        if "`src'" != "" local src "`src'; VECM: CRT (2010ab), CDRT (2018), Lee & Tse (1996) s.2.3"
        else local src "CRT (2010ab), CDRT (2018), Lee & Tse (1996) s.2.3"
    }
    else if `presample' > 0 {
        di as err "presample() is only allowed with dgp(vecm)"
        exit 198
    }

    // ---------------- random numbers and data --------------------------------
    if `"`seed'"' != "" {
        set seed `seed'
    }
    capture mata: mata drop __cvd_oueta
    if "`it'" == "oupath" & `"`pathseed'"' != "" {
        local rngs "`c(rngstate)'"
        set seed `pathseed'
        mata: __cvd_oueta = rnormal(`nobs' + `presample', 1, 0, 1)
        set rngstate `rngs'
        local P_oufix 1
    }
    if "`clear'" != "" {
        qui clear
    }
    qui set obs `nobs'
    qui gen long `tvar' = _n
    qui tsset `tvar'
    capture scalar drop __cvd_nneg
    capture matrix drop __cvd_simroots
    mata: cvd_sim_main()
    capture mata: mata drop __cvd_oueta

    local nneg 0
    capture local nneg = scalar(__cvd_nneg)
    capture scalar drop __cvd_nneg
    tempname sroots
    local hasroots 0
    capture confirm matrix __cvd_simroots
    if !_rc {
        matrix `sroots' = __cvd_simroots
        matrix drop __cvd_simroots
        local hasroots 1
    }

    // ---------------- labels ---------------------------------------------------
    if "`dgp'" == "stochcoint" {
        label var `prefix'1 "y (stochastic cointegration DGP, `type')"
        label var `prefix'2 "x (stochastic cointegration DGP, `type')"
        label var `prefix'_w "common stochastic trend w1"
        local created "`prefix'1 `prefix'2 `prefix'_w"
    }
    else if "`dgp'" == "hci" {
        label var `prefix'1 "y = b0 + b1'x + sigma_t u1 (Hansen 1992)"
        forvalues i = 2/`p' {
            label var `prefix'`i' "I(1) regressor x`=`i'-1'"
        }
        label var `eprefix'1 "BI error w_t = sigma_t u1_t"
        label var `hprefix'1 "sigma_t^2 (random-walk scale squared)"
        local created "`prefix'1-`prefix'`p' `eprefix'1 `hprefix'1"
    }
    else {
        forvalues i = 1/`p' {
            if "`dgp'" == "vecm" label var `prefix'`i' "VECM level `i' (innov: `it')"
            else label var `prefix'`i' "random walk `i' with `it' increments"
            label var `eprefix'`i' "innovation `i' (`it')"
            label var `hprefix'`i' "conditional / unconditional variance `i' (`it')"
        }
        local created "`prefix'1-`prefix'`p' `eprefix'1-`eprefix'`p' `hprefix'1-`hprefix'`p'"
        if "`it'" == "bekk" & `p' == 2 {
            label var `hprefix'12 "conditional covariance h12 (bekk)"
            local created "`created' `hprefix'12"
        }
    }

    // ---------------- summary ------------------------------------------------
    local seeduse `"`seed'"'
    if `"`seeduse'"' == "" local seeduse "(current RNG state)"
    di
    di as txt "cointvol simulate: " as res "dgp(`dgp')" as txt cond("`dgp'" == "vecm", " with innov(`it')", "")
    di as txt "  N = " as res `nobs' as txt ", p = " as res `p' as txt ", burn-in = " as res `burnin' ///
        as txt ", presample = " as res `presample' as txt ", seed = " as res `"`seeduse'"'
    if "`plab'" != "" di as txt "  Parameters: " as res "`plab'"
    if "`omnote'" != "" di as txt "  `omnote'"
    if !inlist("`dgp'", "stochcoint", "hci") {
        di as txt "  Innovations: " as res "`distribution'" ///
            as txt cond("`distribution'" != "normal", " (df = `df', skew = `skew')", "")
    }
    di as txt "  Source: `src'"
    di as txt "  Variables created: " as res "`created'" as txt " (time variable `tvar', tsset)"
    if `nneg' > 0 {
        di as txt "  Note: " as res `nneg' as txt " non-positive FIGARCH variances were floored at 1e-8."
    }
    if `hasroots' {
        local nr = rowsof(`sroots')
        local nu 0
        local nx 0
        forvalues j = 1/`nr' {
            if abs(`sroots'[`j', 1] - 1) < 1e-6 local nu = `nu' + 1
            if `sroots'[`j', 1] > 1 + 1e-6 local nx = `nx' + 1
        }
        di as txt "  VECM companion: " as res `nu' as txt " unit root(s), " as res `nx' as txt " explosive root(s)"
        if `nx' > 0 di as err "  warning: the specified VECM is explosive"
    }

    // ---------------- stored results -------------------------------------------
    return scalar N         = `nobs'
    return scalar p         = `p'
    return scalar burnin    = `burnin'
    return scalar presample = `presample'
    foreach o in omega arch garch asym shift theta lambda sigxi fracd fconst fphi base {
        if "`P_`o''" != "." & "`P_`o''" != "" {
            return scalar `o' = `P_`o''
        }
    }
    if "`it'" == "oupath" {
        return scalar kappa = `kappa'
        return scalar zeta  = `zeta'
    }
    if "`it'" == "figarch" {
        return scalar trunc   = `trunc'
        return scalar n_negvar = `nneg'
    }
    if "`distribution'" != "normal" {
        return scalar df   = `df'
        return scalar skew = `skew'
    }
    if "`it'" == "gjr" {
        return scalar gjr_kappa = `gkap'
    }
    return local dgp          "`dgp'"
    return local innov        "`innov'"
    return local preset       "`preset'"
    return local distribution "`distribution'"
    return local seed         `"`seed'"'
    return local varlist      "`created'"
    return local source       "`src'"
    return local cmd          "cointvol simulate"
    if !inlist("`dgp'", "stochcoint", "hci") {
        return local vcase "`vcase'"
        return matrix Sigma = `Smat'
    }
    if "`it'" == "break" return matrix bspec = `BS'
    if "`it'" == "bekk" {
        return matrix C = `Cm'
        return matrix A = `Am'
        return matrix B = `Bm'
    }
    if "`dgp'" == "vecm" {
        return matrix alpha = `al'
        return matrix beta  = `be'
        if "`gamma'" != "" return matrix gamma = `ga'
        if "`rconst'" != "" return matrix rconst = `rc'
        if "`mu'" != "" return matrix mu = `mm'
        if `hasroots' return matrix roots = `sroots'
    }
end
