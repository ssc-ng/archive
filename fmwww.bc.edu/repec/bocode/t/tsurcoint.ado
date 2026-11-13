*! tsurcoint 1.0.0  12nov2026
*! Time-series unit-root and cointegration tests ported from GAUSS
*!   (tspdlib, carrionlib), numerically identical to GAUSS
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*!
*! Subcommands
*!   Nonlinear / smooth-break unit root
*!     fkss      Christopoulos-Leon-Ledesma (2010) Fourier KSS (and Fourier ADF)
*!     wkss      Aydin (2020) wavelet KSS
*!     fwkss     Aydin (2020) Fourier wavelet KSS
*!     fwadf     Aydin-Pata (2020) Fourier wavelet ADF
*!   Quantile unit root
*!     qkss      Li-Park (2018) quantile KSS
*!     qfkss     Bahmani-Oskooee et al. (2020) quantile Fourier KSS
*!     qks       quantile Kolmogorov-Smirnov tests (KX 2004, LZ 2018, LP 2018, BCNR 2020)
*!   Structural-break unit root
*!     glsbreak  Perron-Rodriguez (2003) / Carrion-i-Silvestre-Kim-Perron (2009), 1-2 breaks
*!   Cointegration (H0: cointegration)
*!     shin      Shin (1994)
*!     cissanso  Carrion-i-Silvestre-Sanso (2006), one structural break

program tsurcoint, rclass
    version 14.0
    gettoken sub 0 : 0, parse(" ,")
    local sub = strlower(`"`sub'"')

    if inlist(`"`sub'"', "", "list", "describe", ",") {
        _tsurcoint_list
        exit
    }
    if inlist(`"`sub'"', "fkss", "fadf", "wkss", "fwkss", "fwadf") {
        if `"`sub'"' == "fadf" {
            if strpos(`"`0'"', ",") == 0 local 0 `"`0', adf"'
            else local 0 `"`0' adf"'
            local sub "fkss"
        }
        _tsurcoint_kss `sub' `0'
    }
    else if inlist(`"`sub'"', "qkss", "qfkss", "qks") {
        _tsurcoint_qkss `sub' `0'
    }
    else if inlist(`"`sub'"', "glsbreak", "gls") {
        _tsurcoint_glsbreak `0'
    }
    else if inlist(`"`sub'"', "shin") {
        _tsurcoint_kpssc shin `0'
    }
    else if inlist(`"`sub'"', "cissanso", "cs") {
        _tsurcoint_kpssc cissanso `0'
    }
    else {
        di as err `"unknown subcommand {bf:`sub'}"'
        di as err "valid subcommands: fkss, wkss, fwkss, fwadf, qkss, qfkss, qks, glsbreak, shin, cissanso  (type {bf:tsurcoint} to list them)"
        exit 198
    }
    return add
    return local subcmd "`sub'"
    return local cmd "tsurcoint"
end

program _tsurcoint_list
    di
    di as txt "{bf:tsurcoint} -- time-series unit-root and cointegration tests (ports of GAUSS tspdlib"
    di as txt "             and carrionlib; results identical to GAUSS)"
    di as txt "{hline 78}"
    di as txt "{bf:Nonlinear / smooth-break unit root}"
    di as txt "  {stata help tsurcoint_fkss:tsurcoint fkss}     " _col(30) "Fourier KSS / Fourier ADF (Christopoulos-Leon-Ledesma 2010)"
    di as txt "  {stata help tsurcoint_wkss:tsurcoint wkss}     " _col(30) "wavelet KSS (Aydin 2020)"
    di as txt "  {stata help tsurcoint_fwkss:tsurcoint fwkss}    " _col(30) "Fourier wavelet KSS (Aydin 2020)"
    di as txt "  {stata help tsurcoint_fwadf:tsurcoint fwadf}    " _col(30) "Fourier wavelet ADF (Aydin-Pata 2020)"
    di as txt "{bf:Quantile unit root}"
    di as txt "  {stata help tsurcoint_qkss:tsurcoint qkss}     " _col(30) "quantile KSS (Li-Park 2018)"
    di as txt "  {stata help tsurcoint_qfkss:tsurcoint qfkss}    " _col(30) "quantile Fourier KSS (Bahmani-Oskooee et al. 2020)"
    di as txt "  {stata help tsurcoint_qks:tsurcoint qks}      " _col(30) "quantile Kolmogorov-Smirnov tests (4 variants)"
    di as txt "{bf:Structural-break unit root}"
    di as txt "  {stata help tsurcoint_glsbreak:tsurcoint glsbreak} " _col(30) "GLS tests with 1-2 breaks (Perron-Rodriguez 2003; CKP 2009)"
    di as txt "{bf:Cointegration (H0: cointegration)}"
    di as txt "  {stata help tsurcoint_shin:tsurcoint shin}     " _col(30) "Shin (1994) LM test, OLS and DOLS"
    di as txt "  {stata help tsurcoint_cissanso:tsurcoint cissanso} " _col(30) "Carrion-i-Silvestre-Sanso (2006), one break"
    di as txt "{hline 78}"
    di as txt "Data must be {bf:tsset} (one series, no gaps).  See {help tsurcoint}."
end
