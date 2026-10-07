*! jointdiag 1.0.0  06oct2026
*! Joint and simultaneous diagnostic tests for time-series regression models
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
*  Dispatcher + shared helpers + Mata engine.
*  Subcommands live in jointdiag_<sub>.ado and are loaded on demand.
*
*  STEP -> EQUATION MAP (abbreviated; full map in: help jointdiag methods)
*  ---------------------------------------------------------------------
*  lm       Bera & Jarque (1982, JoE 20) eq.(4) LM_NHIF = LM_N+LM_H+LM_I+LM_F
*           Jarque & Bera (1980, EL 6) eq.(4)   LM_NHI  (p=0 case)
*           additivity: Higgins & Bera (1988, EcRev 7) sec.2 (Bera-McKenzie cond.)
*           MCP: Bera & Jarque (1982) sec.5 steps (i)-(iv)
*  im       Hall (1987, REStud 54) T1n,T2n,T3n ; Bera & Lee (1993, REStud 60)
*           eq.(5) d=(d1..d6) with AR(p) errors; T2 = Engle ARCH LM eq.(7)
*  arch     Bera, Higgins & Lee (1992, JBES 10) sec.3 LM_{AARCH|AR}, LM_{AR|AARCH}
*           stationarity: Proposition 1 + w(phi)*sum(gamma) < 1
*  bilinear Higgins & Bera (1988) additive LM ; Bera & Higgins (1997, JBES 15)
*           sec.3 LEA eq.(3.4) and the 2*F_a + F_b statistic
*  bc       Savin & White (1978, JoE 8) Table 1 C/G/J tests
*           Lahiri & Egy (1981, JoE 15) eq.(6)(9) ; Ghali & Snow (1987, EcMod 4)
*           eq.(25)(32) ; Tse (1984, EL 14) eq.(10)(11)
*           Yang & Tse (2008, EctJ 11) Thm 3.1-3.3 + Cor 3.2 studentised
*  score    Tsai (1986, Biometrika 73) eq.(2-4) S = S1 + S2
*           Liu, Wei & Wang (2003, CSTM 32) eq.(3.2)-(3.5) DBL(p,0,1)
*  port     Wong & Ling (2005, JTSA 26) Thm 1, Cor 1, Q_M/Q_S/Q1M
*           Velasco & Wang (2015, JTSA 36) sec.2 distribution-free transform
*           Mahdi (2024, Stat&Comp 34:76) eq.(3.1)-(3.8) auto-and-cross
*  spec     Escanciano (2008, JoE 143) eq.(9) CvM + wild bootstrap sec.3
*  mpi      King & Evans (1984, EL 16) eq.(2)-(5) MPI one-sided
*  nonnest  Bera, McAleer & Pesaran (1989, BEBR 89-1616) eq.(6)(7)

program define jointdiag, rclass
    version 14.0

    gettoken sub 0 : 0, parse(" ,")

    if ("`sub'" == "") {
        di as err "jointdiag requires a subcommand"
        _jd_usage
        exit 198
    }
    if (substr("`sub'",1,1) == ",") {
        local 0 "`sub'`0'"
        local sub "all"
    }

    local lsub = lower("`sub'")

    if      ("`lsub'" == substr("lm",1,max(2,length("`lsub'"))))        local sub "lm"
    else if ("`lsub'" == substr("im",1,max(2,length("`lsub'"))))        local sub "im"
    else if ("`lsub'" == substr("arch",1,max(4,length("`lsub'"))))      local sub "arch"
    else if ("`lsub'" == substr("bilinear",1,max(3,length("`lsub'")))) local sub "bilinear"
    else if ("`lsub'" == substr("boxcox",1,max(2,length("`lsub'"))))    local sub "bc"
    else if ("`lsub'" == "bc")                                          local sub "bc"
    else if ("`lsub'" == substr("score",1,max(3,length("`lsub'"))))     local sub "score"
    else if ("`lsub'" == substr("port",1,max(3,length("`lsub'"))))      local sub "port"
    else if ("`lsub'" == substr("spec",1,max(3,length("`lsub'"))))      local sub "spec"
    else if ("`lsub'" == substr("mpi",1,max(3,length("`lsub'"))))       local sub "mpi"
    else if ("`lsub'" == substr("nonnest",1,max(3,length("`lsub'"))))   local sub "nonnest"
    else if ("`lsub'" == substr("all",1,max(3,length("`lsub'"))))       local sub "all"
    else {
        di as err `"unknown subcommand "`sub'""'
        _jd_usage
        exit 198
    }

    jointdiag_`sub' `0'
    return add
end


*-----------------------------------------------------------------------
* usage banner
*-----------------------------------------------------------------------
program define _jd_usage
    di as txt ""
    di as txt "{hline 74}"
    di as txt "  {bf:jointdiag} {it:subcommand} ... {hline 2} joint / simultaneous diagnostic tests"
    di as txt "{hline 74}"
    di as txt "  {bf:lm}        " _col(14) "4-directional LM: normality, heteroskedasticity,"
    di as txt            _col(14) "serial independence, functional form (+ MCP)"
    di as txt "  {bf:im}        " _col(14) "information-matrix decomposition (Hall; Bera-Lee)"
    di as txt "  {bf:arch}      " _col(14) "ARCH/AARCH and autocorrelation jointly"
    di as txt "  {bf:bilinear}  " _col(14) "ARCH vs bilinearity (joint + non-nested)"
    di as txt "  {bf:bc}        " _col(14) "Box-Cox functional form with AR / heteroskedastic errors"
    di as txt "  {bf:score}     " _col(14) "score tests for AR(p)-heteroskedastic-bilinear errors"
    di as txt "  {bf:port}      " _col(14) "mixed portmanteau for conditional mean AND variance"
    di as txt "  {bf:spec}      " _col(14) "generalised-spectral joint and marginal tests"
    di as txt "  {bf:mpi}       " _col(14) "one-sided MPI joint test (serial corr. + heterosk.)"
    di as txt "  {bf:nonnest}   " _col(14) "non-nested models + general error specification"
    di as txt "  {bf:all}       " _col(14) "full dashboard"
    di as txt "{hline 74}"
    di as txt "  see {helpb jointdiag} and {help jointdiag##methods:help jointdiag methods}"
    di as txt ""
end


*-----------------------------------------------------------------------
* _jd_gstyle : the house graph look (returns r(gopt))
*-----------------------------------------------------------------------
