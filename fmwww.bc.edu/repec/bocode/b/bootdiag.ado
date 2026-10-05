*! bootdiag — bootstrap and Monte Carlo post-estimation diagnostics
*! Version 1.0.0 — 2026-10-01
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Independent Researcher
*!
*! Bootstrap / Monte Carlo versions of the standard regression diagnostics,
*! valid after OLS and after the ARDL family of time-series commands.
*!
*! Subcommands
*!   bootdiag serial  — serial correlation      (Breusch-Godfrey family, DW)
*!   bootdiag het     — heteroskedasticity      (BP, Koenker, White, ARCH, ...)
*!   bootdiag norm    — normality               (JB, Lobato-Velasco, AD)
*!   bootdiag stab    — parameter stability     (CUSUM, CUSUMSQ, supF/ave/exp)
*!   bootdiag spec    — functional form         (RESET, CvM / KS)
*!   bootdiag all     — the full battery + joint NHI test
*!
*! References
*!   Davidson, R. & E. Flachaire (2008), J. Econometrics 146, 162-169
*!   MacKinnon, J.G. (2007), QED WP 1127, Bootstrap Hypothesis Testing
*!   MacKinnon, J.G. (2006), QED WP 1028, Bootstrap Methods in Econometrics
*!   Davidson, R. & J.G. MacKinnon (2000), Econometric Reviews 19, 55-68
*!   Racine, J. & J.G. MacKinnon (2007), Comput. Statist. Data Anal.
*!   Dufour, J.-M., L. Khalaf, J.-T. Bernard & I. Genest (2004),
*!       J. Econometrics 122, 317-347
*!   Godfrey, L.G. & A.R. Tremayne (2005), Comput. Statist. Data Anal. 49, 377-395
*!   Flachaire, E. (2005), Comput. Statist. Data Anal. 49, 361-376
*!   Mammen, E. (1993), Ann. Statist. 21, 255-285
*!   Psaradakis, Z. & M. Vavra (2020), Comm. Statist. Simul. Comput. 49, 283-304
*!   Kilian, L. & U. Demiroglu (2000), J. Bus. Econ. Statist. 18, 40-50
*!   O'Reilly, G. & K. Whelan (2005), CBFSAI Research Technical Paper 8/RT/05
*!   Lee, T. & C. Baek (2020), Comput. Statist. Data Anal. 150, 106996
*!   Politis, D.N. & J.P. Romano (1994), JASA 89, 1303-1313
*!   Buehlmann, P. (1997), Bernoulli 3, 123-148
*!   Jarque, C.M. & A.K. Bera (1980), Economics Letters 6, 255-259
*!   White, H. (1980), Econometrica 48, 817-838
*!   Breusch, T.S. & A.R. Pagan (1979), Econometrica 47, 1287-1294

program define bootdiag, rclass
    version 16.0

    gettoken sub 0 : 0, parse(" ,")
    if "`sub'" == "" local sub "all"

    if !inlist("`sub'", "serial", "het", "norm", "stab", "spec", "all", ///
                        "nhi", "fdb") {
        di as err "{bf:bootdiag}: unknown subcommand {bf:`sub'}"
        di as err "Valid: serial, het, norm, stab, spec, all, nhi, fdb"
        exit 198
    }

    _bd_driver `sub' `0'
    return add
end


program define _bd_driver, rclass
    version 16.0
    gettoken sub 0 : 0

    syntax [,                                   ///
        Reps(integer 999)                       ///
        DGP(string)                             ///
        Weight(string)                          ///
        FTrans(string)                          ///
        BLock(real -1)                          ///
        CONTinuous                              ///
        SEED(string)                            ///
        LAGs(numlist integer >0)                ///
        ARCHlags(integer 2)                     ///
        TRIM(real 0.15)                         ///
        RESETpow(integer 4)                     ///
        YLev(string)                            ///
        XLev(string)                            ///
        P(integer -1)                           ///
        Q(numlist integer >=0)                  ///
        CASE(integer -1)                        ///
        TOLerance(real 0.0001)                    ///
        noVERify                                ///
        Level(cilevel)                          ///
        noTABle                                 ///
        noASYmptotic                            ///
        GRaph                                   ///
        GNAme(string)                       ///
        SAVing(string)                          ///
        NHILags(integer 1)                      ///
        FDB                                     ///
        FDBTest(string)                         ///
        PRETest                                 ///
        PREAlpha(real 0.05)                     ///
        PREBeta(real 0.01)                      ///
        PREMin(integer 99)                      ///
        PREMax(integer 12799)                   ///
    ]

    * ---------- defaults ---------------------------------------------
    if "`dgp'"    == "" local dgp    "wild"
    if "`weight'" == "" local weight "rademacher"
    if "`ftrans'" == "" local ftrans "hc3"
    if "`lags'"   == "" local lags   "1 2 4"
    if "`seed'"   != "" set seed `seed'

    local dgpn = .
    if "`dgp'" == "wild"        local dgpn 2
    if "`dgp'" == "residual"    local dgpn 1
    if "`dgp'" == "fixed"       local dgpn 3
    if "`dgp'" == "sieve"       local dgpn 4
    if "`dgp'" == "block"       local dgpn 5
    if "`dgp'" == "stationary"  local dgpn 6
    if "`dgp'" == "blockwild"   local dgpn 7
    if "`dgp'" == "normal"      local dgpn 8
    if `dgpn' >= . {
        di as err "{bf:dgp()} must be one of: wild residual fixed sieve"
        di as err "block stationary blockwild normal"
        exit 198
    }

    local wn = .
    if "`weight'" == "rademacher" local wn 1
    if "`weight'" == "mammen"     local wn 2
    if "`weight'" == "normal"     local wn 3
    if `wn' >= . {
        di as err "{bf:weight()} must be rademacher, mammen or normal"
        exit 198
    }

    local fn = .
    if "`ftrans'" == "none" local fn 0
    if "`ftrans'" == "hc2"  local fn 1
    if "`ftrans'" == "hc3"  local fn 2
    if "`ftrans'" == "hc1"  local fn 3
    if `fn' >= . {
        di as err "{bf:ftrans()} must be none, hc1, hc2 or hc3"
        exit 198
    }

    local contn = ("`continuous'" != "")

    * ---------- build and verify the model ---------------------------
    * q() is a numlist option: passing it empty is a syntax error, so
    * only hand it over when the user actually supplied lag orders.
    local qopt ""
    if trim("`q'") != "" local qopt "q(`q')"

    * The sample marker must outlive _bd_model: a tempvar created inside
    * that program is dropped when it returns, and _bd_graph would then
    * have nothing to write the residuals back onto.  Create it here.
    tempvar bdtouse
    qui gen byte `bdtouse' = 1

    _bd_model, ylev(`ylev') xlev(`xlev') p(`p') `qopt' case(`case') ///
               tolerance(`tolerance') `verify' touse(`bdtouse')

    local mcmd   "`r(cmd)'"
    local msrc   "`r(source)'"
    local mylev  "`r(ylev)'"
    local mxlev  "`r(xlev)'"
    local mq     "`r(qlist)'"
    local mp     = r(p)
    local mcase  = r(case)
    local mok    "`r(okmsg)'"
    local mnote  "`r(note)'"
    local mtouse "`bdtouse'"

    mata: bd_fitstats()
    local N  = r(bd_n)
    local K  = r(bd_k)

    * ---------- block length for the dependent schemes ---------------
    if `block' < 0 {
        if inlist(`dgpn', 5, 6, 7) {
            tempname bl
            mata: st_numscalar("`bl'", ///
                bd_blocklen(bd_GLOBAL_M.ylev, `N', 100))
            local block = `bl'
            if `dgpn' == 6 local block = 1 / max(`block', 1)
        }
        else local block 1
    }

    * ---------- joint NHI test (Jarque & Bera 1980) -------------------
    if "`sub'" == "nhi" {
        tempname RN
        mata: bd_run_nhi(`nhilags', `reps', `dgpn', `wn', `fn', `block', ///
                         `contn', "`RN'")
        local nhinames `""LM_NHI  joint N+H+I" "LM_N    normality" "LM_H    homoskedasticity" "LM_I    independence" "LM_NH   normal + homoskedastic" "LM_NI   normal + independent" "LM_HI   homoskedastic + independent""'
        * asymptotic chi2 reference: 2 for N, k-1 for H, nhilags for I
        local dfN 2
        local dfH = `K' - 1
        local dfI = `nhilags'
        local dfs "`=`dfN'+`dfH'+`dfI'' `dfN' `dfH' `dfI' `=`dfN'+`dfH'' `=`dfN'+`dfI'' `=`dfH'+`dfI''"
        forvalues j = 1/7 {
            local d : word `j' of `dfs'
            local sj = `RN'[`j', 1]
            local pj = .
            if `sj' < . & `d' > 0 local pj = chi2tail(`d', `sj')
            matrix `RN'[`j', 6] = `pj'
        }
        if "`table'" == "" {
            _bd_report, mat(`RN') names(`"`nhinames'"') sub(nhi)          ///
                cmd("`mcmd'") src("`msrc'") ok("`mok'") note("`mnote'")   ///
                dgp("`dgp'") weight("`weight'") ftrans("`ftrans'")        ///
                reps(`reps') n(`N') k(`K') p(`mp') case(`mcase')          ///
                ylev("`mylev'") xlev("`mxlev'") q("`mq'") block(`block')  ///
                `asymptotic' level(`level')
        }
        matrix colnames `RN' = statistic p_boot cv5 cv10 cv1 p_asym
        matrix rownames `RN' = LM_NHI LM_N LM_H LM_I LM_NH LM_NI LM_HI
        return matrix results = `RN'
        return scalar reps = `reps'
        return scalar N = `N'
        return scalar k = `K'
        return local dgp "`dgp'"
        return local cmd "`mcmd'"
        exit
    }

    * ---------- fast double bootstrap ---------------------------------
    if "`sub'" == "fdb" {
        if "`fdbtest'" == "" local fdbtest "koenker"
        local fid = .
        if "`fdbtest'" == "bg"        local fid 10
        if "`fdbtest'" == "koenker"   local fid 21
        if "`fdbtest'" == "bp"        local fid 20
        if "`fdbtest'" == "white"     local fid 22
        if "`fdbtest'" == "arch"      local fid 24
        if "`fdbtest'" == "jb"        local fid 30
        if "`fdbtest'" == "reset"     local fid 50
        if "`fdbtest'" == "supf"      local fid 42
        if `fid' >= . {
            di as err "{bf:fdbtest()} must be one of: bg bp koenker white arch jb reset supf"
            exit 198
        }
        local fprm 0
        if `fid' == 10 local fprm : word 1 of `lags'
        if `fid' == 24 local fprm `archlags'
        if `fid' == 50 local fprm `resetpow'
        if `fid' == 42 local fprm `trim'

        if "`pretest'" != "" {
            * Davidson & MacKinnon (2000) s.3: choose B by pretesting.
            * Start at premin, and while the p-value is not decisively on
            * one side of prealpha set B <- 2B+1 and draw B+1 more.  That
            * rule keeps alpha*(B+1) an integer throughout.
            tempname RP
            mata: bd_pretest(`fid', `fprm', `prealpha', `prebeta',      ///
                             `premin', `premax', `dgpn', `wn', `fn',    ///
                             `block', "`RP'")
            _bd_prereport, mat(`RP') test("`fdbtest'") alpha(`prealpha') ///
                beta(`prebeta') bmin(`premin') bmax(`premax')            ///
                dgp("`dgp'") cmd("`mcmd'")
            matrix colnames `RP' = statistic p_boot B_used
            * read the value first: return matrix MOVES the matrix
            local busedp = `RP'[1, 3]
            return matrix results = `RP'
            return scalar reps = `busedp'
            exit
        }

        tempname RF
        mata: bd_fdb(`fid', `fprm', `reps', `dgpn', `wn', `fn', `block', "`RF'")
        _bd_fdbreport, mat(`RF') test("`fdbtest'") reps(`reps') ///
            dgp("`dgp'") cmd("`mcmd'")
        matrix colnames `RF' = statistic p_single q_second p_fdb
        return matrix results = `RF'
        return scalar reps = `reps'
        exit
    }

    * ---------- assemble the test battery ----------------------------
    * NOTE: one statement per line.  Stata does not treat ";" as a
    * command separator outside #delimit mode.
    local ids ""
    local prm ""
    local tai ""
    local nms ""
    local asy ""
    local adf ""

    if inlist("`sub'", "serial", "all") {
        foreach L of local lags {
            local ids "`ids' 10"
            local prm "`prm' `L'"
            local tai "`tai' 1"
            local asy "`asy' chi2"
            local adf "`adf' `L'"
            local nms `"`nms' "Breusch-Godfrey LM (`L')""'
            local ids "`ids' 12"
            local prm "`prm' `L'"
            local tai "`tai' 1"
            local asy "`asy' chi2"
            local adf "`adf' `L'"
            local nms `"`nms' "BG robust LM_HR (`L')""'
            local ids "`ids' 13"
            local prm "`prm' `L'"
            local tai "`tai' 1"
            local asy "`asy' chi2"
            local adf "`adf' `L'"
            local nms `"`nms' "BG modified MLM_HR (`L')""'
        }
        local ids "`ids' 14"
        local prm "`prm' 0"
        local tai "`tai' 4"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "Durbin-Watson d""'
        local ids "`ids' 15"
        local prm "`prm' 0"
        local tai "`tai' 3"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "First-order rho-hat""'
    }

    if inlist("`sub'", "het", "all") {
        local dfz = `K' - 1
        local ids "`ids' 20"
        local prm "`prm' 0"
        local tai "`tai' 1"
        local asy "`asy' chi2"
        local adf "`adf' `dfz'"
        local nms `"`nms' "Breusch-Pagan LM""'
        local ids "`ids' 21"
        local prm "`prm' 0"
        local tai "`tai' 1"
        local asy "`asy' chi2"
        local adf "`adf' `dfz'"
        local nms `"`nms' "Koenker studentised""'
        local ids "`ids' 22"
        local prm "`prm' 0"
        local tai "`tai' 1"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "White general""'
        local ids "`ids' 24"
        local prm "`prm' `archlags'"
        local tai "`tai' 1"
        local asy "`asy' chi2"
        local adf "`adf' `archlags'"
        local nms `"`nms' "Engle ARCH LM (`archlags')""'
        local ids "`ids' 25"
        local prm "`prm' 0"
        local tai "`tai' 1"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "Szroeter SKH""'
        local ids "`ids' 27"
        local prm "`prm' 0"
        local tai "`tai' 2"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "Harrison-McCabe""'
    }

    if inlist("`sub'", "norm", "all") {
        local ids "`ids' 30"
        local prm "`prm' 0"
        local tai "`tai' 1"
        local asy "`asy' chi2"
        local adf "`adf' 2"
        local nms `"`nms' "Jarque-Bera""'
        local ids "`ids' 31"
        local prm "`prm' 0"
        local tai "`tai' 1"
        local asy "`asy' chi2"
        local adf "`adf' 2"
        local nms `"`nms' "Lobato-Velasco""'
        local ids "`ids' 32"
        local prm "`prm' 0"
        local tai "`tai' 1"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "Anderson-Darling""'
    }

    if inlist("`sub'", "stab", "all") {
        local ids "`ids' 40"
        local prm "`prm' 0"
        local tai "`tai' 1"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "CUSUM""'
        local ids "`ids' 41"
        local prm "`prm' 0"
        local tai "`tai' 1"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "CUSUM of squares""'
        local ids "`ids' 42"
        local prm "`prm' `trim'"
        local tai "`tai' 1"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "supF""'
        local ids "`ids' 43"
        local prm "`prm' `trim'"
        local tai "`tai' 1"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "aveF""'
        local ids "`ids' 44"
        local prm "`prm' `trim'"
        local tai "`tai' 1"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "expF""'
    }

    if inlist("`sub'", "spec", "all") {
        local ids "`ids' 50"
        local prm "`prm' `resetpow'"
        local tai "`tai' 1"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "Ramsey RESET""'
        local ids "`ids' 51"
        local prm "`prm' 0"
        local tai "`tai' 1"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "Cramer-von Mises""'
        local ids "`ids' 52"
        local prm "`prm' 0"
        local tai "`tai' 1"
        local asy "`asy' none"
        local adf "`adf' 0"
        local nms `"`nms' "Kolmogorov-Smirnov""'
    }

    local nst : word count `ids'
    if `nst' == 0 {
        di as err "no tests selected"
        exit 198
    }

    * ---------- run ---------------------------------------------------
    local idsm = subinstr(trim("`ids'"), " ", ",", .)
    local prmm = subinstr(trim("`prm'"), " ", ",", .)
    local taim = subinstr(trim("`tai'"), " ", ",", .)

    tempname R
    mata: bd_run((`idsm'), (`prmm'), (`taim'), `reps', `dgpn', `wn', ///
                 `fn', `block', `contn', "`R'")

    * ---------- asymptotic p-values for comparison --------------------
    forvalues j = 1/`nst' {
        local a : word `j' of `asy'
        local d : word `j' of `adf'
        local s = `R'[`j', 1]
        local pv = .
        if "`a'" == "chi2" & `s' < . & `d' > 0 local pv = chi2tail(`d', `s')
        matrix `R'[`j', 6] = `pv'
    }

    * ---------- report -------------------------------------------------
    if "`table'" == "" {
        _bd_report, mat(`R') names(`"`nms'"') sub(`sub')               ///
            cmd("`mcmd'") src("`msrc'") ok("`mok'") note("`mnote'")    ///
            dgp("`dgp'") weight("`weight'") ftrans("`ftrans'")         ///
            reps(`reps') n(`N') k(`K') p(`mp') case(`mcase')           ///
            ylev("`mylev'") xlev("`mxlev'") q("`mq'") block(`block')   ///
            `asymptotic' level(`level')
    }

    * ---------- graphs -------------------------------------------------
    if "`graph'" != "" {
        _bd_graph, sub(`sub') reps(`reps') dgp(`dgpn') weight(`wn')    ///
            ftrans(`fn') block(`block') trim(`trim')                   ///
            touse("`mtouse'") name("`gname'") saving(`"`saving'"')
    }

    * ---------- returns -------------------------------------------------
    matrix colnames `R' = statistic p_boot cv5 cv10 cv1 p_asym
    local rn ""
    forvalues j = 1/`nst' {
        local nj : word `j' of `nms'
        local nj = subinstr("`nj'", " ", "_", .)
        local rn "`rn' `nj'"
    }
    matrix rownames `R' = `rn'

    return matrix results = `R'
    return scalar  reps   = `reps'
    return scalar  N      = `N'
    return scalar  k      = `K'
    return local   dgp    "`dgp'"
    return local   weight "`weight'"
    return local   ftrans "`ftrans'"
    return local   cmd    "`mcmd'"
    return local   source "`msrc'"
end
