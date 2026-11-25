* cgemod_sj_examples.do
* Reproduces the examples in the Stata Journal article on cgemod.
* Section 5.1-5.4 (Nigeria): requires 002_IFPRI_SAM_NGA_2018_SAM.tab in the working directory
* (https://doi.org/10.7910/DVN/WWZDTD).
* Sections 5.5-5.7: illustrative datasets supplied with the package.

version 15
clear all
set more off
capture log close sjex
log using cgemod_sj_examples.log, replace text name(sjex)

* Sections 5.1 to 5.4: import, audit, calibration, diagnostics, tariff simulation and
* sensitivity analysis with the 2018 Nigeria SAM
do cgemod_nigeria.do

* Sections 5.5 to 5.7: SAM balancing, scenarios and poverty, validation and performance
do cgemod_example.do

log close sjex
