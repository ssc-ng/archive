{smcl}
{* *! version 2.0.0  2 October, 2026 @ 12:00:00}{...}
{viewerjumpto "Syntax" "euromod setinfo##syntax"} {viewerjumpto "Description" "euromod setinfo####description"}{viewerjumpto "Examples" "euromod setinfo####examples"}
{viewerjumpto "Authors" "euromod setinfo####authors"}{cmd:help euromod setinfo} {it:(EUROMOD Connector v2.0.0)}

{hline}


{phang}
{bf:euromod setinfo} {hline 2} Changes the value of a parameter of a EUROMOD model for the runs of the Stata session {p_end}
{pstd} Note: euromod setinfo is a complementary command of {help euromod run}; see also {help euromod getinfo} and {help euromod reload}{p_end}

{marker syntax}{title:Syntax}

{p 4 4 2}
{cmd:euromod setinfo}, 
{bf:model}{it:(path to the EUROMOD project)}
{bf:country}{it:(EU country)} 
{bf:system}{it:(EUROMOD system name)}
{bf:parId}{it:(parameter identifier)}
{bf:newParValue}{it:(new value)}

{title:Description}{marker description}

{pstd}{cmd:euromod setinfo} allows the user to change parameters in the EUROMOD model. The change is kept in memory by the connector and applied to every run of that system in the Stata session; it is never written to the model files.{p_end}

{pstd}{help euromod getinfo} with {opt parId()} shows the changed value in r(par_value). The changes stay for the rest of the Stata session: {cmd:discard} and {cmd:clear all} do not drop them. {help euromod reload} is the way to drop them; it lists the changes it discards. When the files of the model change on disk, the connector reads the model again by itself and discards its changes with a message; a run that would have used them is not started, so that it never runs silently without them.{p_end}

{pstd}The command reports an error when the system or the parameter does not exist, when the parameter belongs to an add-on (the engine applies the parameters of an add-on before run-time changes, so the change would have no effect), and when the engine could not run the value as typed: an empty value (use {it:n/a} to take the parameter out of the system), or a value with inner spaces in a parameter that keeps them (the engine removes spaces from a run-time change; change such a value in the model itself).{p_end}

{pstd}{opt model(string)} This parameter is the root folder of the EUROMOD project, where the model is stored. This parameter is mandatory. The project must be a project of the EUROMOD platform (see {help euromod##projects:Supported projects}).{p_end}

{pstd}{opt country(string)} The country of the parameter.{p_end}

{pstd}{opt system(string)} Indicates the system you want to target.{p_end}

{pstd}{opt parId(string)} Id of the parameter that you want to target, as shown in the EUROMOD user interface. A parameter has the same identifier in every system; {opt system()} selects the system whose value changes. {p_end}

{pstd}{opt newParValue(string)} Indicates the new value of the parameter that you want to set. The value {it:n/a} takes the parameter out of the system; a value for a parameter that is {it:n/a} in the system adds it.{p_end}



{marker examples}
{title:Examples}

{p 4 4 2}

{p 8 4 2}euromod setinfo, model("$model_path") country("BG")	system("BG_2023") parId("5DF9FF12-F7D3-452F-BF2C-0320937B87C9") newParValue("12345") {p_end}
{p 8 4 2}euromod getinfo, model("$model_path") country("BG")	system("BG_2023") parId("5DF9FF12-F7D3-452F-BF2C-0320937B87C9") {p_end}
{p 8 4 2}display "`r(par_value)'" {p_end}
{p 8 4 2}euromod reload, model("$model_path") {p_end}


{marker authors}
{title:Authors}

{p 4 4 2}
Hannes Serruys, B2-JRC Seville (Hannes.SERRUYS@ec.europa.eu)

{hline}

{break}