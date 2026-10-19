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
program define euromod_setinfo, rclass
	syntax , model(string) country(string) system(string) parId(string) newParValue(string)
	// Stata keeps the case of these option names: the values of parId() and newParValue() are in the
	// locals parId and newParValue, and the lower-case locals stay empty (checked in Stata 19.5).
	if "`system'" != "" & "`country'" == "" {
			di in r "Need country argument in order to identify system."
			error -1
	}
	if "`parId'" != "" & "`system'" == "" {
		di in r "Need system argument in order to identify parameter."
		error -1
	}
	if "`parId'" != "" & `"`newParValue'"' == "" {
		di in r "Need newParValue argument in order to set the parameter (use n/a to take it out of the system)."
		error -1
	}
	di `"`newParValue'"'
	if "`parId'" != "" { 
		// noisily: when the edit is refused, the plugin says why (unknown system or parameter id,
		// a value the engine cannot take, an add-on parameter).
		capture noisily plugin call EM_StataPlugin, "setXmlInfoPar" "`model'" "`country'" "`system'" "`parId'" "`newParValue'"
		if _rc != 0 {
			error 1
		}
		
	}
	else{
		exit
	}

	// Setting return List Macros
	plugin call EM_StataPlugin, "setReturnList"
	foreach local_connector in `return_list_locals_connector' {
		return local `local_connector' "`rlm`local_connector''"
	}
end
