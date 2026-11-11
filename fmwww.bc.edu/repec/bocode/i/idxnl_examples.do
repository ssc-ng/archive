* idxnl_examples.do -- worked examples on the simulated panel shipped with idxnl
version 14
clear all
set more off
use idxnl_example, clear
xtset id year

* 1. Characterize the indices
idxdescribe gov gov1 gov2, bounds(-2.5 2.5)
idxdescribe ict, bounds(0 100)

* 2. Specification comparison and turning-point evaluation
idxspec y gov w1 w2 i.year, vce(cluster id)
idxspec y gov w1 w2 i.year, fe vce(cluster id) graph
matrix list r(compare)

* 3. Turning-point inference after a user-specified model
regress y c.gov##c.gov w1 w2 i.year, vce(cluster id)
idxtp gov
idxtp gov, trim(0)

* 4. Interaction between correlated sub-indices
idxint y gov2 gov1 w1 w2 i.year, vce(cluster id) graph
