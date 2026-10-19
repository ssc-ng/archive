/*#####################################################
#  Version 2.0.0
#  Author: Hannes Serruys
#  Last updated: 2026-10-02
#####################################################*/
global EUROMOD_COMMAND_VERSION = "2.0.0"
// Minimum EUROMOD software version these commands require. Set here as well as in
// euromod.ado so the plugin's forward-compatibility check never fails open when this
// entry point is reached without euromod.ado having run first.
global EUROMOD_CONNECTOR_VERSION = "3.8.9"
// EUROMOD_PATH is the folder that holds StataPlugin.plugin and the EUROMOD engine library.
// The folder is looked for in this order: the Stata global EUROMOD_PATH, when the user set it;
// the environment variable EUROMOD_STATA_PLUGIN_PATH of the operating system, which an installer
// or the user sets once; the folder of an installed EUROMOD software. The folder found is kept
// in the global EUROMOD_PATH for the rest of the Stata session (the same lines in every .ado file).
if `"$EUROMOD_PATH"' == "" {
	local em_env_path : environment EUROMOD_STATA_PLUGIN_PATH
	if `"`em_env_path'"' != "" {
		global EUROMOD_PATH `"`em_env_path'"'
	}
	else {
		global EUROMOD_PATH "C:/Program Files/EUROMOD/Executable"
	}
}
quietly adopath + "$EUROMOD_PATH"
// The plugin is loaded in a way that works for both EUROMOD plugins. The plugin of the
// EUROMOD software 3.8.9 links to libraries that sit beside it, and Windows finds those only
// when that folder is the working directory at the moment the plugin is loaded; the plugin of
// the EUROMOD platform finds its own files, and for it the working directory does not matter.
// The working directory is restored at once. capture: a failed definition must not stop this
// file before that; its return code is checked below.
local em_wd `"`c(pwd)'"'
capture quietly cd "$EUROMOD_PATH"
capture program EM_StataPlugin, plugin using ("$EUROMOD_PATH/StataPlugin.plugin")
local em_plugin_rc = _rc
capture quietly cd `"`em_wd'"'
// A failed definition leaves no plugin program behind. Stata returns 9999 for a file it cannot
// load (not a plugin, or a library it needs is not found) and 601 for a missing file. A second
// definition of an existing program succeeds in Stata 19.5, where it loads the plugin again;
// 110 is let through in case another Stata version refuses the name instead.
if !inlist(`em_plugin_rc', 0, 110) {
	display as error "Stata could not load StataPlugin.plugin from the folder ${EUROMOD_PATH} (return code `em_plugin_rc'). That folder, named by the Stata global EUROMOD_PATH or the environment variable EUROMOD_STATA_PLUGIN_PATH, must be the folder of a complete EUROMOD installation, where StataPlugin.plugin has the files it needs beside it."
	exit `em_plugin_rc'
}

//once plugin is loaded, get software version of EUROMOD
if "$EUROMOD_SOFTWARE_VERSION" == "" {
		// noisily: when the call fails, the plugin shows why (for example the folders where it
		// looked for the engine library, or which version check failed).
		capture noisily plugin call EM_StataPlugin , "setVersion"
		if (_rc != 0) {
			// The plugin could not report its version. This is either a plugin that could not
			// be loaded, a EUROMOD software too old to support "setVersion", or one whose
			// compatibility check already rejected these commands. Refuse rather than assuming
			// a compatible version.
			display as error "The installed EUROMOD software version could not be determined, or is not compatible with these euromod commands. Please upgrade EUROMOD to at least version $EUROMOD_CONNECTOR_VERSION."
			display as error "The plugin is loaded from ${EUROMOD_PATH}/StataPlugin.plugin. The global EUROMOD_PATH names the folder that holds StataPlugin.plugin and the EUROMOD engine library."
			exit 198
		}
	}
program define euromod_run, rclass
	
	//syntax [anything(everything)], dataset(string) [REPository(string)] * 
	
    version 15.1
	syntax [if] [in], SYStem(string)  MODel(string) country(string) [bestmatch DATAset(string) REPository(string)  TU_output(string) VARs_output(string) il_output(string) constants(string) PREFix(string) SETtings(string) EXTRAinfo_output(string) SUPPress_output)  uselogger outputdataset(string) EXTensions(string) ADDons(string) replace euro sequentialrun PUBLICcomponentsonly outputpath(string) keep breakfun_id(string)]
	global vars_EM ""
	// if dataset not specified then go for bestmatch if it is uniquely identified
	if ("`dataset'" == "") {
		if ("`bestmatch'" != "bestmatch") {
			display as error "There is no dataset parameter specified. Consider using the bestmatch option to automatically select the bestmatch for the simulation."
			error -1
			exit
		}
		
		euromod getinfo, model(`model') country(`country') system(`system')
		local dataset = "`r(sys_bestMatchDatasets)'"
		local c = wordcount("`dataset'")
		if `c' == 0 {
			display as error "There is no dataset parameter specified, and the best match is not defined for system `system'."
			error -1
			exit
		}
		else if `c' > 1 {
			display as error "There is no dataset parameter specified, and the best match is not uniquely defined for system `system'. Best match datasets are `dataset'"
			error -1
			exit
		}
		noisily display "Running EUROMOD using the best match dataset (`dataset') for system `system' by default."
	} 
	else if ("`bestmatch'" == "bestmatch") {
		display as error "Both the dataset parameter and the bestmatch option cannot be used at the same time. "
		error -1
		exit
	}
	
	if ("`repository'" != "") {
		import delimited "`repository'\\`dataset'.txt",clear
	}
	capture confirm variable idhh idperson
	if _rc != 0 | _N == 0 {
		display as error "There is either no data present or the data does not contain idperson or idhh as a variable."
		error -1
		exit
	}
	
	
	
//DO NOT touch name of varlist_input_EM, plugin is hardcoded on the name #####
	// euro, sequentialrun and publiccomponentsonly append their settings to the settings string,
	// each entry followed by a comma. A non-empty user string that does not end with a comma
	// gets one first, so that its last entry and the appended ones stay separate entries; a
	// string that already ends with a comma is kept as it is.
	if ("`euro'`sequentialrun'`publiccomponentsonly'" != "") {
		// The settings syntax uses single quotes ('KEY':'value'), so the last character is
		// usually a quote. It is tested through functions of the whole string: a lone quote
		// expanded into an if-expression is not parsed as a string (type mismatch, r(109)).
		local settings_length = ustrlen(ustrtrim(`"`settings'"'))
		local settings_ends_with_comma = (substr(ustrtrim(`"`settings'"'), -1, 1) == ",")
		if `settings_length' > 0 & !`settings_ends_with_comma' {
			local settings `"`settings',"'
		}
	}
	if ("`euro'" == "euro") {
	    local settings = "`settings''FORCE_OUTPUT_EURO': 'yes',"
	}
	
	if ("`sequentialrun'" == "sequentialrun") {
	    local settings = "`settings''FORCE_SEQUENTIAL_RUN':'yes',"
	}
	if ("`publiccomponentsonly'" == "publiccomponentsonly") {
	    local settings = "`settings''IGNORE_PRIVATE':'yes',"
	}
	if ("`uselogger'" != "uselogger"  ) {
		local disableLogger "disableLogger"
	}
	quietly ds, has(type numeric)
	local numeric_list = "`r(varlist)'"
	quietly ds, has(char inputvar)
	local previous_input = "`r(varlist)'"
	
	quietly ds, not(char simulated) 
	local not_simulated_list = "`r(varlist)'"
	local varlist_input_EM9870 = ""
	marksample touse
	// Next foreach loop makes sure that variables which were previous output are not entering as input again 
	//(unless they were assigned to be an input variable before and overwritten by the output of a simulation)
	
	if ("`vars_output'" != "") | ("`il_output'" != "") {
		local outputdataset = "custom_output.txt"
	}
	
	foreach var in `numeric_list' {
		if  `: list var in not_simulated_list' {
			local varlist_input_EM9870 = "`varlist_input_EM9870' `var'"
			char `var'[inputvar] "yes"
		}
		else if `: list var in previous_input' {
		    
		    local varlist_input_EM9870 = "`varlist_input_EM9870' `var'"
		}	
	}
    capture noisily plugin call EM_StataPlugin `varlist_input_EM9870' if `touse', "simulate" "`system'" "`model'" "`dataset'" "`repository'" "`outputdataset'" "`country'" "`vars_output'" "`il_output'" "`extrainfo_output'" "`suppress_output'" "`constants'" "`settings'" "`disableLogger'" "`extensions'" "`addons'" "`outputpath'" "`keep'" "`breakfun_id'"
	if (_rc != 0) {
		quietly plugin call EM_StataPlugin, "setReturnList"
		foreach local_connector in `return_list_locals_connector' {
			return local `local_connector' = "`rlm`local_connector''"
		}
		error 1
		exit
	}
	capture gen __simulated__ = 0
	replace __simulated__ = `touse'
	if ($EM_n_outputs == 1) {
		quietly euromod_getdata, outputdataset($EM_outputs) prefix(`prefix') `replace'
		return add
	}
	else if "`outputdataset'" != "" {
		euromod_getdata, outputdataset("`outputdataset'") prefix(`prefix') `replace'
		return add
	}
	else if (strpos("$EM_outputs","custom_output") > 0) {
		quietly euromod_getdata, outputdataset("custom_output.txt") prefix(`prefix') `replace'
		display "Loaded custom_output.txt by default."
		return add
	}
	else {
		quietly plugin call EM_StataPlugin, "setReturnList"
		foreach local_connector in `return_list_locals_connector' {
			return local `local_connector' = "`rlm`local_connector''"
		}
	}
	exit
end
