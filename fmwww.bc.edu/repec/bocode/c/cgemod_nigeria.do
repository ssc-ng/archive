* cgemod with the 2018 Social Accounting Matrix for Nigeria (IFPRI Nexus SAM)
*
* Data (download from Harvard Dataverse and place 002_IFPRI_SAM_NGA_2018_SAM.tab in the working folder):
*   International Food Policy Research Institute (IFPRI). 2021. 2018 Social Accounting Matrix for Nigeria.
*   Washington, DC: IFPRI [dataset]. https://doi.org/10.7910/DVN/WWZDTD. Harvard Dataverse. Version 1.
*   Randriamamonjy, J., and J. Thurlow. 2021. 2018 Social Accounting Matrix for Nigeria: A Nexus Project SAM.
*   Data Paper. Washington, DC: IFPRI. https://doi.org/10.2499/p15738coll2.134812.
* Units: billions of naira. 42 activities and commodities, 5 factors, 10 households, 1 enterprise.

clear all
set more off
capture confirm file "002_IFPRI_SAM_NGA_2018_SAM.tab"
if _rc {
    di as err "002_IFPRI_SAM_NGA_2018_SAM.tab is not in the working folder (" c(pwd) ")."
    di as err "Copy it from the Harvard Dataverse download (doi:10.7910/DVN/WWZDTD) into this folder and run again."
    exit 601
}

* 1. Import: codes are in column 2; roles (including stock changes, dstk) are detected from the codes
cgemod samimport using "002_IFPRI_SAM_NGA_2018_SAM.tab", labelcol(2) name(NGA) nolist
foreach r in activities commodities factors households enterprises government row savinv taxes margins stocks {
    local `r' "`r(`r')'"
}

* 2. Audit the SAM: accounting identities and GDP from both sides
cgemod samcheck, sam(NGA) activities(`activities') commodities(`commodities') factors(`factors') ///
    households(`households') enterprises(`enterprises') government(`government') row(`row') savinv(`savinv') ///
    taxes(`taxes') margins(`margins') stocks(`stocks')

* 3. Calibrate (roles detected by samimport) and run the model diagnostics
cgemod calibrate, sam(NGA)
cgemod check

* 4. Remove all import tariffs (default closures) and compare with the reference implementation
cgemod sim, tm(*0) title(Nigeria: removal of all import tariffs)
cgemod compare using cgemod_nigeria_reference.csv, value(default) tolerance(1e-4)

* 5. Fixed exchange rate
cgemod calibrate, sam(NGA) exchange(fixed) notable
cgemod sim, tm(*0) title(Tariff removal, fixed exchange rate) notable
cgemod compare using cgemod_nigeria_reference.csv, value(fixer) tolerance(1e-4)

* 6. Unemployment of workers without and with primary education (fixed wages)
cgemod calibrate, sam(NGA) unemployed(flab_n flab_p) notable
cgemod sim, tm(*0) title(Tariff removal with unemployed low-skill labour)
cgemod compare using cgemod_nigeria_reference.csv, value(unemp) tolerance(1e-4)

* 7. Robustness of the tariff results to the trade and production elasticities
cgemod calibrate, sam(NGA) notable
cgemod ssa, tm(*0) elasticities(sigmava sigmaq omega sigmax) range(0.5)

* 8. Export the balanced SAM for GAMS and Excel users
cgemod samexport, sam(NGA) excel(nga_sam_2018.xlsx) gams(nga_sam_2018.inc) replace
