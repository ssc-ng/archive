*! xturcoint 1.0.0  11nov2026
*! Panel unit-root and panel cointegration tests ported from GAUSS
*!   (tspdlib, carrionlib, westerlundlib), numerically identical to GAUSS
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*!
*! Subcommands
*!   Panel unit-root / stationarity
*!     lm      Im-Lee-Tieslau (2005) / Lee-Tieslau (2019) panel LM, 0-2 breaks
*!     fixedt  Hadri-Larsson (2005) / Carrion-i-Silvestre-Hadri (2010), fixed T
*!     mp      Moon-Perron (2004) t*_a, t*_b with common factors
*!     panic   Bai-Ng (2010), Westerlund-Larsson (2009), PANICCA (2016)
*!   Cross-sectional dependence
*!     cd      BP (1980), PUY (2008), Pesaran (2004, 2021), BFK (2012)
*!   Panel cointegration
*!     cusum   Westerlund (2005) panel CUSUM (H0: cointegration)
*!     adfmin  Westerlund (2006) panel ADF/Z tests with a level break

program xturcoint, rclass
    version 14.0
    gettoken sub 0 : 0, parse(" ,")
    local sub = strlower(`"`sub'"')

    if inlist(`"`sub'"', "", "list", "describe", ",") {
        _xturcoint_list
        exit
    }
    if inlist(`"`sub'"', "lm", "ilt", "lt", "pdlm") {
        _xturcoint_lm `0'
    }
    else if inlist(`"`sub'"', "fixedt", "fixed", "hl", "ch") {
        _xturcoint_fixedt `0'
    }
    else if inlist(`"`sub'"', "mp", "moonperron", "moon") {
        _xturcoint_mp `0'
    }
    else if inlist(`"`sub'"', "panic", "panicca", "bn2010", "wl2009") {
        if inlist(`"`sub'"', "panicca", "bn2010", "wl2009") & strpos(`"`0'"', "meth") == 0 {
            if strpos(`"`0'"', ",") == 0 local 0 `"`0', method(`sub')"'
            else local 0 `"`0' method(`sub')"'
        }
        _xturcoint_panic `0'
    }
    else if inlist(`"`sub'"', "cd", "csd") {
        _xturcoint_cd `0'
    }
    else if inlist(`"`sub'"', "cusum") {
        _xturcoint_cusum `0'
    }
    else if inlist(`"`sub'"', "adfmin", "levelbreak") {
        _xturcoint_adfmin `0'
    }
    else {
        di as err `"unknown subcommand {bf:`sub'}"'
        di as err "valid subcommands: lm, fixedt, mp, panic, cd, cusum, adfmin  (type {bf:xturcoint} to list them)"
        exit 198
    }
    return add
    return local subcmd "`sub'"
    return local cmd "xturcoint"
end

program _xturcoint_list
    di
    di as txt "{bf:xturcoint} -- panel unit-root and cointegration tests (ports of GAUSS tspdlib,"
    di as txt "             carrionlib and westerlundlib; results identical to GAUSS)"
    di as txt "{hline 78}"
    di as txt "{bf:Panel unit-root / stationarity tests}"
    di as txt "  {stata help xturcoint_lm:xturcoint lm}      " _col(30) "Im-Lee-Tieslau (2005) level shifts / Lee-Tieslau (2019)"
    di as txt _col(30) "level & trend shifts; 0, 1 or 2 breaks"
    di as txt "  {stata help xturcoint_fixedt:xturcoint fixedt}  " _col(30) "Hadri-Larsson (2005) stationarity and"
    di as txt _col(30) "Carrion-i-Silvestre-Hadri (2010) unit root, fixed T"
    di as txt "  {stata help xturcoint_mp:xturcoint mp}      " _col(30) "Moon-Perron (2004) t*_a, t*_b, dynamic factors"
    di as txt "  {stata help xturcoint_panic:xturcoint panic}   " _col(30) "Bai-Ng (2010) Pa/Pb/PMSB, Westerlund-Larsson (2009)"
    di as txt _col(30) "Ze/Ze+, Reese-Westerlund (2016) PANICCA"
    di as txt "{bf:Cross-sectional dependence (pre-test)}"
    di as txt "  {stata help xturcoint_cd:xturcoint cd}      " _col(30) "BP (1980) LM, PUY (2008) LMadj, Pesaran (2004, 2021)"
    di as txt _col(30) "CDlm and CD, Baltagi-Feng-Kao (2012) CDlm+"
    di as txt "{bf:Panel cointegration tests}"
    di as txt "  {stata help xturcoint_cusum:xturcoint cusum}   " _col(30) "Westerlund (2005) panel CUSUM, H0: cointegration"
    di as txt "  {stata help xturcoint_adfmin:xturcoint adfmin}  " _col(30) "Westerlund (2006) panel ADF/Phillips Z tests with"
    di as txt _col(30) "a level break, H0: no cointegration"
    di as txt "{hline 78}"
    di as txt "Data must be {bf:xtset}; panels must be balanced.  See {help xturcoint}."
end
