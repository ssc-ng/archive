* PIRNEX v2.1.4 - example; run from the PIRNEX repository folder.
* Before running this file, use Stata's cd command to enter the extracted folder.
* For example: cd "C:\PIRNEX" (change to your own installation folder).
version 16.0
clear all
set more off
which pirnex
webuse nlswork, clear
pirnex ln_wage tenure hours union, id(idcode) time(year) folder("pirnex_run_v21") boots(0) epochs(150) seed(20261108)
