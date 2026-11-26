*!mchaid_estat version 1.0.0 24nov2026 - postestimation (estat) after mchaid
program define mchaid_estat, rclass	//estat classification: table of the cases classified in the modal category of their node against their real category

version 12.1

if ("`e(cmd)'" != "mchaid") error 301

gettoken sub 0 : 0, parse(" ,")

local len = length("`sub'")

if ((`len' >= 5) & ("`sub'" == substr("classification", 1, `len'))) {

	syntax [, POSitive(string)]

	if (`"`positive'"' == "") mchaid, mchaidclassif														//the calculation is in mchaid.ado (its programs are not visible from here)

	else mchaid, mchaidclassif positive(`positive')

	return add

}

else {

	display "{err}estat `sub' is not available after mchaid; use {bf:estat classification}"

	exit 198

}

end
