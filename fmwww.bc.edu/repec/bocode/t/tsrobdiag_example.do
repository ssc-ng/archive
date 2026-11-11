* tsrobdiag_example.do: examples for tsnormal and hansenstab
* Uses Wooldridge's data sets through bcuse (ssc install bcuse)
version 14
clear all
set more off

* 1. Normality of weekly returns on the value-weighted NYSE index (690 weeks)
bcuse nyse, clear
tsset t
tsnormal return, boot(999) seed(20261025)
regress return L.return
tsnormal, boot(999) seed(20261025)

* 2. Stability of an interest-rate equation, 1948-2003
bcuse intdef, clear
tsset year
regress i3 inf def
estat bgodfrey
hansenstab
hansenstab, kernel(qs)
hansenstab, kernel(bartlett)

* 3. Expectations-augmented Phillips curve, 1949-2003
bcuse phillips, clear
tsset year
regress cinf unem
hansenstab, boot(999) seed(20261025)
tsnormal, boot(999) seed(20261025)
