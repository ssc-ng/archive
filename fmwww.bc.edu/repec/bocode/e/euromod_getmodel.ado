global EUROMOD_COMMAND_VERSION = "2.0.0"
// Minimum EUROMOD software version these commands require (keep in sync with euromod.ado).
global EUROMOD_CONNECTOR_VERSION = "3.8.9"
/*#####################################################
#  Version 2.0.0
#  Author: Hannes Serruys
#  Last updated: 2026-10-02
#####################################################*/
program define euromod_getmodel 
	syntax , [folder(string)]
	**# Download latest model
	// Without folder(), the model goes to the working directory; the default is set before the
	// check so that the check looks at the folder actually used.
	if "`folder'" == "" {
		local folder = "`c(pwd)'"
	}
	mata : st_numscalar("folder_exists", direxists("`folder'"))
	if folder_exists == 0 {
		noi display as error "The folder `folder' does not exists."
		error 601
	}
	di "Downloading the file from https://euromod-web.jrc.ec.europa.eu"
	capture copy "https://euromod-web.jrc.ec.europa.eu/sites/default/files/latest_public_model_release.zip" "`folder'/latest_public_model_release.zip", replace
	if _rc != 0 {
		display as error "Latest model cannot be downloaded. Please try again later."
		error 601
	}
	local pwd = "`c(pwd)'"
	qui cd "`folder'"
	qui unzipfile "`folder'/latest_public_model_release.zip", replace
	qui cd "`pwd'"
	di "unzipped model in `folder'"
	
end
