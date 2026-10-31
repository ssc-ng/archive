* polyreg_examples.do -- example in the polyreg article (simulated household survey)
version 14
clear all
set more off
set seed 20261025
set obs 300
gen int ea = _n
gen double u_ea = rnormal(0, .6)
expand 20
bysort ea: gen int hh = _n
gen double wealth = u_ea + rnormal()
gen byte electricity = wealth + rnormal(0, .7) > 0.3
gen byte radio       = wealth + rnormal(0, 1.2) > -0.6
gen byte tv          = wealth + rnormal(0, .8) > 0.6
gen byte fridge      = wealth + rnormal(0, .8) > 1.2
gen byte floor  = 1 + (wealth + rnormal(0, .9) > -.2) + (wealth + rnormal(0, .9) > 1.0)
gen byte water  = 1 + (wealth + rnormal(0, 1) > -1) + (wealth + rnormal(0, 1) > 0)
gen byte female = runiform() < .5
gen int age = 6 + floor(runiform()*10)
gen byte enrolled = (0.4*wealth + 0.2*female - 0.1*(age - 10) + rnormal()) > -0.5
local assets electricity radio tv fridge floor water

* linear index, linear probability model, cluster bootstrap
polyreg enrolled i.female age, index(`assets') reps(199) cluster(ea) seed(1)
* wealth quintiles in a logit model
polyreg enrolled i.female age, index(`assets') quantiles(5) model(logit) reps(199) cluster(ea) seed(2)
