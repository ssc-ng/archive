/*#####################################################
#  Version 2.0.0
#  Author: Hannes Serruys
#  Last updated: 2026-10-02
#####################################################*/
global EUROMOD_COMMAND_VERSION = "2.0.0"
// Minimum EUROMOD software version these commands require (the version of the engine library).
global EUROMOD_CONNECTOR_VERSION = "3.8.9"


// EUROMOD_PATH is the folder that holds StataPlugin.plugin. The commands work with both plugins
// of that name. The plugin of the EUROMOD platform looks for the engine library in its own
// folder (first in bin/Executable/<platform>) and then in the folder named by EUROMOD_PATH.
// The plugin of the EUROMOD software 3.8.9 has its libraries beside it in that folder.
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
capture confirm file "${EUROMOD_PATH}/StataPlugin.plugin"

// Check the return code to determine if the file exists
if _rc != 0 {
	display as error "Expected to find StataPlugin.plugin in the folder ${EUROMOD_PATH}. Make sure to have installed the latest version of EUROMOD (minimum version $EUROMOD_CONNECTOR_VERSION), or name the folder that holds StataPlugin.plugin and the EUROMOD engine library in the Stata global EUROMOD_PATH or in the environment variable EUROMOD_STATA_PLUGIN_PATH."
	exit _rc
}
program define euromod
	
	
    gettoken first rest : 0, parse(", ")
       if "`first'" == "run" {
			local subcommand = "euromod_run"
	   } 
	   else if "`first'" == "getdata" {
			local subcommand = "euromod_getdata"
	   }
	   else if "`first'" == "getinfo" {
			local subcommand = "euromod_getinfo"
	   }
	   else if "`first'" == "setinfo" {
			local subcommand = "euromod_setinfo"
	   }
	   else if "`first'" == "getmodel" {
			local subcommand = "euromod_getmodel"
	   }
	   else if "`first'" == "reload" {
			local subcommand = "euromod_reload"
	   }
	   else {
			di as err "No valid subcommand specified."
			error -1
	   }
       `subcommand'`rest'
	   exit 0
end