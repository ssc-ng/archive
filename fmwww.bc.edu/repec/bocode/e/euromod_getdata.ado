/*#####################################################
#  Version 2.0.0
#  Author: Hannes Serruys
#  Last updated: 2026-10-02
#####################################################*/
global EUROMOD_COMMAND_VERSION = "2.0.0"
// Minimum EUROMOD software version these commands require (keep in sync with euromod.ado).
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
adopath + "$EUROMOD_PATH"
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
program define euromod_getdata, rclass
	set type double
	syntax , OUTputdataset(string) [replace PREfix(string)]
	capture confirm variable idperson
	if (_rc == 0) {
		capture noisily plugin call EM_StataPlugin idperson if __simulated__, "checkConcatenation" "`outputdataset'"
	} 
	//Check if data needs to be replaced before throwing an error
	if (_rc != 0) {
	    if ("`replace'" != "replace") {
		display in r "Output dataset cannot be concatenated."
		display in r "Consider replacing existing dataset with current one using replace option."
		quietly plugin call EM_StataPlugin, "setReturnList"
		error -1
		exit
		}
	}
	if ("`replace'" == "replace") {
		quietly ds, has(char inputvar)
		local previous_input = "`r(varlist)'"
		capture noi plugin call EM_StataPlugin, "setNobs" "`outputdataset'"
		if (_rc != 0) {
			error -1
			exit
		}
		clear
		insobs `nObs'
		gen __simulated__ = 1
	}
	
	capture noi plugin call EM_StataPlugin if __simulated__ , "setOutputVarsMacro" "`outputdataset'"
		if (_rc != 0) {
			error -1
			exit
		}

	local output_vars_stata ""
	foreach var of global vars_EM {
		//ensure unique varname of maximum length of 32
		local candidate = strtoname("`prefix'`var'")
		capture confirm variable `candidate'
		if _rc == 0 {
			// if exists already check first length, if necessary use substring
			local len_candidate = ustrlen("`candidate'")
			if `len_candidate' >= 30 {
				local candidate = substr("`candidate'",1,29)
			}
			//add a counter which you increase until variable name is for sure unique
			local counter = 0
			while _rc == 0 {
				local counter = `counter' + 1
				capture confirm variable `candidate'`counter'
			}
			local varname = "`candidate'`counter'"
		}
		else
		{
			local varname = "`candidate'"
		}
		capture gen `varname' = .
		quietly format `varname' %12.0g
		char `varname'[simulated] "yes"
		//set variable name of euromod as label. Add optional prefix between parenthesises
		if "`prefix'" == "" {
			label variable `varname' "`var'"
		}
		else {
			label variable `varname' "`var' (`prefix')"
		}
		
		
		local output_vars_stata "`output_vars_stata' `varname'"
	}
	// This loads the output 
	capture noi plugin call EM_StataPlugin `output_vars_stata' if __simulated__, "storeData" "`outputdataset'"
	if (_rc != 0) {
		error -1
		exit
	}
	// Setting return List Macros
	capture noi plugin call EM_StataPlugin, "setReturnList"
	if (_rc != 0) {
		error -1
		exit
	}
	foreach local_connector in `return_list_locals_connector' {
		return local `local_connector' = "`rlm`local_connector''"
	}
	
end
