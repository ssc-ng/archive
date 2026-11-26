
***************************************************
*EXAMPLE 1
***************************************************

    sysuse tsline2, clear
    tsset day
    
    bj calories

***************************************************
*EXAMPLE 2
***************************************************

    sysuse gnp96, clear
    tsset date

    bj gnp96, id

    bj d.gnp96,

**************************************************
*EXAMPLE 3
**************************************************

    use https://rodrigotaborda.com/ad/data/trafico_carreteras/trafico_carreteras_2003-2024_nacional.dta, clear
    tsset fecha
    
    bj trafico_peaje, id noinfo

    generate covid_curfew = tin(2020m3,2020m8) | tin(2021m4,2021m5)

    bj trafico_peaje covid_curfew

    bj trafico_peaje covid_curfew, arima(arima(1,0,0) sarima(1,1,0,12)) subtitle("Identification" "Tráfico ARIMA(1,0,0) SARIMA(1,1,0,12) + Covid curfew") /// 
        estsubtitle("Estimation" "Tráfico ARIMA(1,0,0) SARIMA(1,1,0,12) + Covid curfew")
