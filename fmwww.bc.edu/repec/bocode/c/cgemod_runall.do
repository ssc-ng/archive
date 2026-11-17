* cgemod_runall.do: runs the unit tests, the certification script, the Nigeria application and the
* examples in one session and writes everything to cgemod_runall.log.
* Run from the folder that contains the package files:   do cgemod_runall.do
* Each script continues after an error (option nostop), so the log lists every problem at once.
clear all
discard
set more off
mata: mata set matalnum on
capture log close _all
log using cgemod_runall.log, replace text name(runall)
display as text "cgemod run-all: " c(current_date) " " c(current_time) ", Stata " c(stata_version)
which cgemod
do cgemod_unittest.do, nostop
do cgemod_cert.do, nostop
do cgemod_nigeria.do, nostop
do cgemod_example.do, nostop
log close runall
display as text "finished; the full record is in cgemod_runall.log"
