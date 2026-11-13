// elecdisp: STATA program to calculate disproportionality indices for individual election results
// Oscar Martínez Coello
// Universität Mannheim, Germany
// e-mail: oscarmtc@outlook.de
// August 2026
// First Version: August 2026
// Copyright (C) 2026 Oscar Martínez Coello
// SPDX-License-Identifier: MIT
*! version 1.0.0 19aug2026


capture program drop elecdisp

program elecdisp, rclass
	version 19.5
	syntax varlist(min = 3 max = 3) [if] [in] [, INPUTscale(string) OUTPUTscale(string) noPRINT]
	tokenize `varlist'

	*************************************************************************************
	*********************** Verification of the Input-Scale Option ***********************
	*************************************************************************************

	local inputscale = lower(strtrim("`inputscale'"))

	if !inlist("`inputscale'", "percentage", "proportion") {
		display as error "The option inputscale() must be either percentage or proportion."
		exit 198
	}

	*************************************************************************************
	************************ Verification of Output-Scale Option ************************
	*************************************************************************************

	local outputscale = lower(strtrim("`outputscale'"))
	if !inlist("`outputscale'", "percentage", "proportion") {
		display as error "The option outputscale() must be either percentage or proportion."
		exit 198
	}

	*************************************************************************************
	******************************* Marking of the Sample *******************************
	*************************************************************************************

	marksample touse, novarlist 

	*************************************************************************************
	********************* Generation of Temporary Working Variables *********************
	*************************************************************************************

	tempvar vote_string_copy
	tempvar seat_string_copy
	tempvar vote_share_copy
	tempvar seat_share_copy

	*************************************************************************************
	************** Verification of the first variable (vote-share variable) *************
	*************************************************************************************

	capture confirm numeric variable `1'
	if _rc == 0 {
		quietly generate double `vote_share_copy' = `1' if `touse' == 1
	}
	else {
		quietly generate strL `vote_string_copy' = subinstr(strtrim(`1'), ",", ".", .) if `touse' == 1
		capture quietly destring `vote_string_copy', generate(`vote_share_copy')
		if _rc != 0 {
			display as error "The first variable, `1', contains elements that cannot be converted into numbers. Verify your input data."
			exit 109
		}
		quietly recast double `vote_share_copy'
	}

	*************************************************************************************
	************* Verification of the second variable (seat-share variable) *************
	*************************************************************************************

	capture confirm numeric variable `2'
	if _rc == 0 {
		quietly generate double `seat_share_copy' = `2' if `touse' == 1
	}
	else {
		quietly generate strL `seat_string_copy' = subinstr(strtrim(`2'), ",", ".", .) if `touse' == 1
		capture quietly destring `seat_string_copy', generate(`seat_share_copy')
		if _rc != 0 {
			display as error "The second variable, `2', contains elements that cannot be converted into numbers. Verify your input data."
			exit 109
		}
		quietly recast double `seat_share_copy'
	}

	*************************************************************************************
	********* Verification of the third variable (Election-Identifier variable) *********
	*************************************************************************************

	capture confirm string variable `3'
	local string_3 = (_rc == 0)
		
	*************************************************************************************
	******************** Marking of Observations with Missing Values ********************
	*************************************************************************************

	markout `touse' `vote_share_copy' `seat_share_copy' `3', strok

	quietly count if `touse' == 1
	if r(N) == 0 {
		display as error "No observations remain after removing missing values."
		exit 2000
	}

	*************************************************************************************
	**************** Verification of Negative Vote- and Seat-Share Values ***************
	*************************************************************************************

	capture assert `vote_share_copy' >= 0 & `seat_share_copy' >= 0 if `touse' == 1
	if _rc != 0 {
		display as error "Vote shares and seat shares cannot contain negative values. Verify your input data."
		exit 459
	}

	*************************************************************************************
	****************** Validation and Normalization of the Input Scale ******************
	*************************************************************************************

	if "`inputscale'" == "proportion" {
		capture assert inrange(`vote_share_copy', 0, 1) if `touse' == 1
		if _rc != 0 {
			display as error "The first variable, `1', must be between 0 and 1 because the option inputscale(proportion) was specified."
			exit 459
		}
		capture assert inrange(`seat_share_copy', 0, 1) if `touse' == 1
		if _rc != 0 {
			display as error "The second variable, `2', must be between 0 and 1 because inputscale(proportion) was specified."
			exit 459
		}
		quietly replace `vote_share_copy' = 100 * `vote_share_copy' if `touse' == 1
		quietly replace `seat_share_copy' = 100 * `seat_share_copy' if `touse' == 1
	}

	if "`inputscale'" == "percentage" {
		capture assert inrange(`vote_share_copy', 0, 100) if `touse' == 1
		if _rc != 0 {
			display as error "The first variable, `1', must be between 0 and 100 because the option inputscale(percentage) was specified."
			exit 459
			}
		capture assert inrange(`seat_share_copy', 0, 100) if `touse' == 1
		if _rc != 0 {
			display as error "The second variable, `2', must be between 0 and 100 because the option inputscale(percentage) was specified."
			exit 459
		}
	}

	*************************************************************************************
	************** Identification of unique elections and number of parties *************
	*************************************************************************************

	quietly levelsof `3' if `touse', local(elections)
	local number_of_elections : list sizeof elections

	* Create the matrix after determining its number of rows
	tempname results
	matrix `results' = J(`number_of_elections', 1, .)

	* Count the number of parties within each election
	local row = 1

	foreach election of local elections {
		if `string_3' {
			quietly count if `touse' == 1 & `3' == `"`election'"'
			matrix `results'[`row', 1] = r(N)
			local ++row
			}
			else {
				quietly count if `touse' == 1 & `3' == `election'
				matrix `results'[`row', 1] = r(N)
				local ++row
				}
			}

	*************************************************************************************
	********************* Calculation of Disproportionality Indices *********************
	*************************************************************************************

	************************ Part 1: Calculation of the Rae Index ***********************

	tempvar rae_mark 
	tempvar party_differences_rae
	tempname final_sum_differences_rae
	tempname number_parties_rae
	tempname results_rae sum_differences_rae

	matrix `results_rae' = J(`number_of_elections', 1, .)

	quietly generate byte `rae_mark' = 1 if `vote_share_copy' >= 0.5 & !missing(`vote_share_copy') & `touse' == 1
	quietly generate double `party_differences_rae' = abs(`vote_share_copy' - `seat_share_copy') if `touse' == 1 & `rae_mark' == 1

	local row_1 = 1

	foreach election of local elections {
		if `string_3' {
			quietly summarize `party_differences_rae' if `touse' == 1 & `3' == `"`election'"' & `rae_mark' == 1
			scalar `sum_differences_rae' = r(sum)
			quietly count if `rae_mark' == 1 & `touse' == 1 & `3' == `"`election'"' & !missing(`party_differences_rae')
			scalar `number_parties_rae' = r(N)
			scalar `final_sum_differences_rae' = scalar(`sum_differences_rae') / scalar(`number_parties_rae')
			matrix `results_rae'[`row_1', 1] = scalar(`final_sum_differences_rae')
			local ++row_1
			}
			else {
				quietly summarize `party_differences_rae' if `touse' == 1 & `3' == `election' & `rae_mark' == 1
				scalar `sum_differences_rae' = r(sum)
				quietly count if `rae_mark' == 1 & `touse' == 1 & `3' == `election' & !missing(`party_differences_rae')
				scalar `number_parties_rae' = r(N)
				scalar `final_sum_differences_rae' = scalar(`sum_differences_rae') / scalar(`number_parties_rae')
				matrix `results_rae'[`row_1', 1] = scalar(`final_sum_differences_rae')
				local ++row_1
				}
			}

	****************** Part 2: Calculation of the Loosemore-Hanby Index *****************
	
	tempvar party_differences_lh
	tempname results_lh sum_differences_lh
	
	matrix `results_lh' = J(`number_of_elections', 1, .)
	
	quietly generate double `party_differences_lh' = abs(`vote_share_copy' - `seat_share_copy') if `touse' == 1 
	
	local row_2 = 1
	
	foreach election of local elections {
		if `string_3' {
			quietly summarize `party_differences_lh' if `touse' == 1 & `3' == `"`election'"'
			scalar `sum_differences_lh' = r(sum) / 2
			matrix `results_lh'[`row_2', 1] = scalar(`sum_differences_lh')
			local ++row_2
			}
		else {
			quietly summarize `party_differences_lh' if `touse' == 1 & `3' == `election'
			scalar `sum_differences_lh' = r(sum) / 2
			matrix `results_lh'[`row_2', 1] = scalar(`sum_differences_lh')
			local ++row_2
			}
		}

	********************* Part 3: Calculation of the Gallagher-Index ********************
	
	tempvar party_differences_ls
	tempname results_ls sum_differences_ls final_value_ls
	
	matrix `results_ls' = J(`number_of_elections', 1, .)
	
	quietly generate double `party_differences_ls' = (`vote_share_copy' - `seat_share_copy')^2 if `touse' == 1 
	
	local row_3 = 1
	
	foreach election of local elections {
		if `string_3' {
			quietly summarize `party_differences_ls' if `touse' == 1 & `3' == `"`election'"'
			scalar `sum_differences_ls' = r(sum) 
			scalar `final_value_ls' = sqrt(scalar(`sum_differences_ls') / 2)
			matrix `results_ls'[`row_3', 1] = scalar(`final_value_ls')
			local ++row_3
			}
		else {
			quietly summarize `party_differences_ls' if `touse' == 1 & `3' == `election'
			scalar `sum_differences_ls' = r(sum) 
			scalar `final_value_ls' = sqrt(scalar(`sum_differences_ls') / 2)
			matrix `results_ls'[`row_3', 1] = scalar(`final_value_ls')
			local ++row_3
			}
		}

	******************* Part 4: Calculation of the Adjusted Rae Index *******************

	tempvar adjusted_rae_mark 
	tempvar party_differences_adj_rae
	tempname final_sum_differences_adj_rae
	tempname number_parties_adj_rae
	tempname results_adj_rae sum_differences_adj_rae

	matrix `results_adj_rae' = J(`number_of_elections', 1, .)

	quietly generate byte `adjusted_rae_mark' = 1 if `vote_share_copy' >= 5.00 & !missing(`vote_share_copy') & `touse' == 1
	quietly generate double `party_differences_adj_rae' = abs(`vote_share_copy' - `seat_share_copy') if `touse' == 1 & `adjusted_rae_mark' == 1

	local row_4 = 1

	foreach election of local elections {
		if `string_3' {
			quietly summarize `party_differences_adj_rae' if `touse' == 1 & `3' == `"`election'"' & `adjusted_rae_mark' == 1
			scalar `sum_differences_adj_rae' = r(sum)
			quietly count if `adjusted_rae_mark' == 1 & `touse' == 1 & `3' == `"`election'"' & !missing(`party_differences_adj_rae')
			scalar `number_parties_adj_rae' = r(N)
			scalar `final_sum_differences_adj_rae' = scalar(`sum_differences_adj_rae') / scalar(`number_parties_adj_rae')
			matrix `results_adj_rae'[`row_4', 1] = scalar(`final_sum_differences_adj_rae')
			local ++row_4
			}
		else {
			quietly summarize `party_differences_adj_rae' if `touse' == 1 & `3' == `election' & `adjusted_rae_mark' == 1
			scalar `sum_differences_adj_rae' = r(sum)
			quietly count if `adjusted_rae_mark' == 1 & `touse' == 1 & `3' == `election' & !missing(`party_differences_adj_rae')
			scalar `number_parties_adj_rae' = r(N)
			scalar `final_sum_differences_adj_rae' = scalar(`sum_differences_adj_rae') / scalar(`number_parties_adj_rae')
			matrix `results_adj_rae'[`row_4', 1] = scalar(`final_sum_differences_adj_rae')
			local ++row_4
			}
		}

	***************** Part 5: Calculation of the Two-Major Parties Index ****************

	tempvar party_differences_tmp
	tempvar rank_elections
	tempvar two_major_parties
	tempname results_tmp sum_differences_tmp final_value_tmp

	matrix `results_tmp' = J(`number_of_elections', 1, .)

	quietly generate double `party_differences_tmp' = abs(`vote_share_copy' - `seat_share_copy') if `touse' == 1 

	local row_5 = 1

	foreach election of local elections {
		if `string_3' {
			quietly egen `rank_elections' = rank(-`vote_share_copy') if `touse' == 1 & `3' == `"`election'"', unique
			quietly generate `two_major_parties' = 1 if `rank_elections' <= 2
			quietly summarize `party_differences_tmp' if `touse' == 1 & `3' == `"`election'"' & `two_major_parties' == 1
			scalar `sum_differences_tmp' = r(sum) 
			scalar `final_value_tmp' = scalar(`sum_differences_tmp') / 2
			matrix `results_tmp'[`row_5', 1] = scalar(`final_value_tmp')
			drop `rank_elections' `two_major_parties'
			local ++row_5
		}
		else {
			quietly egen `rank_elections' = rank(-`vote_share_copy') if `touse' == 1 & `3' == `election', unique
			quietly generate `two_major_parties' = 1 if `rank_elections' <= 2
			quietly summarize `party_differences_tmp' if `touse' == 1 & `3' == `election' & `two_major_parties' == 1
			scalar `sum_differences_tmp' = r(sum) 
			scalar `final_value_tmp' = scalar(`sum_differences_tmp') / 2
			matrix `results_tmp'[`row_5', 1] = scalar(`final_value_tmp')
			drop `rank_elections' `two_major_parties'
			local ++row_5
			}
		}	

	************* Part 6: Calculation of the Adjusted Loosemore-Hanby Index *************

	tempvar party_differences_adj_lh vote_share_squared_adj_lh
	tempname effective results_adj_lh sum_differences_adj_lh final_divided_value_adj_lh

	matrix `results_adj_lh' = J(`number_of_elections', 1, .)

	quietly generate double `party_differences_adj_lh' = abs(`vote_share_copy' - `seat_share_copy') if `touse' == 1 
	quietly generate double `vote_share_squared_adj_lh' = (`vote_share_copy')^2 if `touse' == 1 & !missing(`vote_share_copy')

	local row_6 = 1

	foreach election of local elections {
		if `string_3' {
			quietly summarize `vote_share_squared_adj_lh' if `touse' == 1 & `3' == `"`election'"'
			scalar `effective' = 10000 / r(sum)		
			quietly summarize `party_differences_adj_lh' if `touse' == 1 & `3' == `"`election'"'
			scalar `sum_differences_adj_lh' = r(sum)
			scalar `final_divided_value_adj_lh' = scalar(`sum_differences_adj_lh') / scalar(`effective')
			matrix `results_adj_lh'[`row_6', 1] = scalar(`final_divided_value_adj_lh')
			local ++row_6
			}
		else {
			quietly summarize `vote_share_squared_adj_lh' if `touse' == 1 & `3' == `election'
			scalar `effective' = 10000 / r(sum)		
			quietly summarize `party_differences_adj_lh' if `touse' == 1 & `3' == `election'
			scalar `sum_differences_adj_lh' = r(sum)
			scalar `final_divided_value_adj_lh' = scalar(`sum_differences_adj_lh') / scalar(`effective')
			matrix `results_adj_lh'[`row_6', 1] = scalar(`final_divided_value_adj_lh')
			local ++row_6
			}
		}

	*************************************************************************************
	*********************** Convert to the requested output scale ***********************
	*************************************************************************************

	local output_scale "percentage"
	if inlist("`outputscale'", "proportion") {
		matrix `results_rae' = 0.01 * `results_rae'
		matrix `results_lh'  = 0.01 * `results_lh'
		matrix `results_ls'  = 0.01 * `results_ls'
		matrix `results_adj_rae' = 0.01 * `results_adj_rae'
		matrix `results_tmp' = 0.01 * `results_tmp'
		matrix `results_adj_lh' = 0.01 * `results_adj_lh'
		local output_scale "proportion"
	}

	*************************************************************************************
	******************************** Display the results ********************************
	*************************************************************************************

	if "`print'" == "" {

		display	
		display as txt "All calculations have been completed successfully."	
		display
		display as txt "{dup 80:=}"
		display _col(22) as txt "{bf:Disproportionality Indices by Election}"
		display as txt "{dup 80:=}"
		display as txt "{c TLC}" _col(02) "{hline 55}" "{c TRC}"
		display as txt "{c |}	Variables:" _col(35) as result "`1' `2'" _col(57) as txt "{c |}"
		display as txt "{c |}	Group variable:" _col(35) as result "`3'" _col(57) as txt "{c |}"
		display as txt "{c |}	Input Scale:" _col(35) as result "`inputscale'" _col(57) as txt "{c |}"
		display as txt "{c |}	Internal Scale:" _col(35) as result "percentage" _col(57) as txt "{c |}"
		display as txt "{c |}	Output Scale:" _col(35) as result "`output_scale'" _col(57) as txt "{c |}"
		display as txt "{c |}	Number of Elections:" _col(40) as result "`number_of_elections'" _col(57) as txt "{c |}"
		display as txt "{c BLC}" _col(02) "{hline 55}" "{c BRC}"
		display as txt "{hline 80}"
		display as txt "	Election" _col(30) as txt "		Disproportionality Index"
		display as txt "{hline 80}"

		local row = 1

		foreach election of local elections {
			if `string_3' == 1 {
				local election_text `"`election'"'
				}
			else {
				local election_text : label (`3') `election'
				}
				
			display _col(02) as txt `"`election_text'"' _col(34) as txt "{it:Number of parties:}" _col(68) as result %-9.0f el(`results', `row', 1)
			display _col(34) as txt "Rae Index:" _col(68) as result %-9.4f el(`results_rae', `row', 1)
			display _col(34) as txt "Adjusted Rae Index:" _col(68) as result %-9.4f el(`results_adj_rae', `row', 1)	
			display _col(34) as txt "Loosemore-Hanby Index:" _col(68) as result %-9.4f el(`results_lh', `row', 1)
			display _col(34) as txt "Adjusted Loosemore-Hanby Index:" _col(68) as result %-9.4f el(`results_adj_lh', `row', 1)
			display _col(34) as txt "Two-Major Parties Index:" _col(68) as result %-9.4f el(`results_tmp', `row', 1)
			display _col(34) as txt "Gallagher-Index:" _col(68) as result %-9.4f el(`results_ls', `row', 1)
			display as txt "{hline 80}"
			local ++row
		}

		display as txt "{dup 80:=}"
	}	

	*************************************************************************************
	********************************* Return the results ********************************
	*************************************************************************************

	return matrix results = `results'
	return matrix results_rae = `results_rae'
	return matrix results_adj_rae = `results_adj_rae'
	return matrix results_lh = `results_lh'
	return matrix results_adj_lh = `results_adj_lh'
	return matrix results_tmp = `results_tmp'
	return matrix results_ls = `results_ls'

	return local elections `"`elections'"'
	return local input_scale "`inputscale'"
	return local internal_scale "percentage"
	return local output_scale "`output_scale'"

end

// End of the program
