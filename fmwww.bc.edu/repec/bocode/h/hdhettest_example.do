* hdhettest_example.do: heteroskedasticity tests with many regressors
* Uses Wooldridge's wage1 data through bcuse (ssc install bcuse)
version 14
clear all
set more off
bcuse wage1, clear

* 1. A standard wage equation (23 parameters, n = 526)
regress lwage educ exper expersq tenure tenursq nonwhite female married numdep smsa ///
    northcen south west construc ndurman trcommpu trade services profserv profocc clerocc servocc
hdhettest, seed(20261025)
estat hettest, rhs iid          // asymptotic Koenker test, for comparison

* 2. Many indicator regressors (133 parameters)
regress lwage i.educ i.exper i.tenure i.numdep ///
    i.female##(i.married i.nonwhite i.construc i.ndurman i.trcommpu i.trade i.services ///
    i.profserv i.profocc i.clerocc i.servocc) smsa northcen south west
hdhettest, seed(20261025)
hdhettest, seed(20261025) robust
return list

* 3. Koenker tests on chosen indicator variables (version 1.1.0)
regress lwage educ exper tenure female married nonwhite smsa
hdhettest, white seed(20261025)                      // White's indicators
estat imtest, white                                  // same statistic, asymptotic p-value
hdhettest, indicators(educ exper tenure) seed(20261025)
