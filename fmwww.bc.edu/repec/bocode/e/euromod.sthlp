{smcl}
{* *! version 2.0.0  2 October, 2026 @ 12:00:00}{...}
{viewerjumpto "Requirements" "euromod##requirements"}
{viewerjumpto "Supported projects" "euromod##projects"}
{viewerjumpto "Description" "euromod####description"}{viewerjumpto "Examples" "euromod####examples"}
{viewerjumpto "What's new" "euromod##whatsnew"}
{viewerjumpto "Authors" "euromod####authors"}{cmd:euromod} {it:(EUROMOD Connector v2.0.0)}

{hline}
{marker requirements}{title:Requirements}
In order to use the Stata Connector to EUROMOD, please install the latest software version of EUROMOD (version 3.8.9 or later).
This can be downloaded from {browse "https://euromod-web.jrc.ec.europa.eu/download-euromod":here}.

{pstd}The commands load the plugin {bf:StataPlugin.plugin} from one folder, which they look for in this order:{p_end}
{p 8 11 2}1. the Stata global {bf:EUROMOD_PATH}, when it is set before the first euromod command of the Stata session;{p_end}
{p 8 11 2}2. the environment variable {bf:EUROMOD_STATA_PLUGIN_PATH} of the operating system, which an installer or the
user sets once for all Stata sessions;{p_end}
{p 8 11 2}3. {it:C:/Program Files/EUROMOD/Executable}, the folder of an installed EUROMOD software.{p_end}
{pstd}The folder found is kept in the global EUROMOD_PATH for the rest of the session. It is the folder that holds
StataPlugin.plugin and the EUROMOD engine library ({it:executable_rust_shim}). The plugin looks for the engine library
in its own folder: first in the subfolder {it:bin/Executable/<platform>} (for example {it:bin/Executable/windows-x64}),
as a EUROMOD installation lays it out, then in the folder itself.{p_end}

{pstd}To name the folder in a do-file, set the global before the first euromod command, for example:{p_end}

{p 8 8 2}{cmd:. global EUROMOD_PATH "D:/EUROMOD/Executable"}{p_end}

{pstd}To name it once for the computer, set the environment variable, for example in a Windows command prompt, and
start Stata again (Stata reads the environment when it starts):{p_end}

{p 8 8 2}{cmd:setx EUROMOD_STATA_PLUGIN_PATH "D:\EUROMOD\Executable"}{p_end}

{pstd}To load the plugin, the commands change the working directory to the folder of EUROMOD_PATH for the moment of
loading and restore it at once.{p_end}

{pstd}{bf:Two plugins.} EUROMOD has shipped two plugins under the name StataPlugin.plugin, and the commands work with
both. The plugin in the folder found as described above is the one used:{p_end}
{p 8 10 2}- the plugin of the EUROMOD platform, which reads projects of the platform (see
{help euromod##projects:Supported projects}) and runs them with the engine library;{p_end}
{p 8 10 2}- the plugin of the EUROMOD software 3.8.9, which the installer of that software puts in
{it:C:/Program Files/EUROMOD/Executable} and which reads projects in the earlier layout, with an {it:XMLParam} folder.{p_end}
{pstd}A Stata session uses one plugin: set EUROMOD_PATH before the first euromod command, and restart Stata to change
plugin. The help files describe the commands with the plugin of the EUROMOD platform. With the plugin of the EUROMOD
software 3.8.9 the commands, their options and the names of the results are the same, and the behaviour is the one of
that plugin: the changes listed under {help euromod##whatsnew:What's new} describe the plugin of the EUROMOD platform,
apart from the corrections made in the commands themselves (for example {opt settings()} without a final comma).{p_end}

{marker projects}{title:Supported projects}
{pstd}This section describes the plugin of the EUROMOD platform. The plugin of the EUROMOD software 3.8.9 reads projects
in the earlier layout only: there {opt model()} names the folder that holds the {it:XMLParam} folder.{p_end}

{pstd}The {opt model()} option of every command names the folder of a project of the EUROMOD platform: a folder with a
{it:Model} subfolder. Each country in {it:Model/Countries} (and each add-on in {it:Model/AddOns}) may be stored in either format:{p_end}
{p 8 10 2}- an EM4 bundle (a {it:manifest.json} file with the other JSON files of the country), as the current EUROMOD user interface saves it;{p_end}
{p 8 10 2}- an EM3 XML file ({it:Model/Countries/XX/XX.xml}).{p_end}
{pstd}Projects in the old layout, with an {it:XMLParam} folder, are refused with a message. Open such a project with the
EUROMOD user interface and use its import of EM2 projects: it converts the project into a new folder, and the converted
project works with these commands as is.{p_end}

{pstd}A run prepares the input files of the engine in the {it:EM3Translation} folder of the project, as the EUROMOD user
interface does, so the project folder must be writable. The model files in {it:Model} are never changed, and changes made
with {help euromod setinfo} are never saved.{p_end}

{marker description}{title:Description} The euromod command allows the user to interact with the EUROMOD microsimulation software from Stata. 
The user is able to 
{p 10} - Run the model, see {help euromod run} {p_end}
{p 10} - Download the latest public model, see {help euromod getmodel} {p_end}
{p 10} - Retrieve information about the model, see {help euromod getinfo} {p_end}
{p 10} - Change parameter values of the model for the runs of the Stata session, see {help euromod setinfo} {p_end}
{p 10} - Read a model again and discard those changes, see {help euromod reload} {p_end}
{p 10} - Load the data into memory, see {help euromod getdata}{p_end}
Note that euromod getdata command is only needed when multiple datasets are returned by the model.
 
{marker examples}
{title:Examples}

{p 4 8 2}{cmd:. euromod getdata, outputdataset(sk_2022_xbase_std.txt) prefix(sim1_)} {p_end}
{p 4 8 2}{cmd:. euromod run, model({it:Path to model}) system(BE_2020) dataset(BE_2020_c2) country(BE)} {p_end}
{p 4 8 2}{cmd:. euromod getinfo, model({it:Path to model}) system(BE_2020) dataset(BE_2020_c2) country(BE)} {p_end}
{p 4 8 2}{cmd:. euromod setinfo, model("{it:Path to model}") country("BG")	system("BG_2023") parId("5DF9FF12-F7D3-452F-BF2C-0320937B87C9") newParValue("12345")} {p_end}
{p 4 8 2}{cmd:. euromod reload, model("{it:Path to model}")} {p_end}

{marker whatsnew}
{title:What's new in 2.0.0}

{pstd}Version 2.0.0 of the commands works with the plugin of the EUROMOD platform, and still works with the plugin of the
EUROMOD software 3.8.9 (see {help euromod##requirements:Requirements}). The commands, their options, the globals and the
returned results keep their names. What users can notice with the plugin of the EUROMOD platform:{p_end}

{p 4 4 2}{bf:Installation and projects}{p_end}
{p 6 8 2}- The global EUROMOD_PATH names the folder that holds StataPlugin.plugin and the EUROMOD engine library (see {help euromod##requirements:Requirements}).{p_end}
{p 6 8 2}- When the global EUROMOD_PATH is not set, the commands take the folder from the environment variable EUROMOD_STATA_PLUGIN_PATH of the operating system, and only then from {it:C:/Program Files/EUROMOD/Executable}. This holds with either plugin.{p_end}
{p 6 8 2}- The commands read projects of the EUROMOD platform, with countries stored as EM4 bundles or as EM3 XML files; projects in the old XMLParam layout are refused with guidance (see {help euromod##projects:Supported projects}).{p_end}
{p 6 8 2}- The commands require EUROMOD 3.8.9 or later, with either plugin; the plugin of the EUROMOD platform requires commands of version 2.0.0 or later.{p_end}

{p 4 4 2}{bf:Fixed}{p_end}
{p 6 8 2}- {cmd:euromod run, breakfun_id()} stops the run after the given function; the option had no effect before.{p_end}
{p 6 8 2}- {cmd:euromod getinfo, all parId()} returns the parameter results r(par_*); it returned the system results before.{p_end}
{p 6 8 2}- r(ctry_publicdatasets) lists only the public datasets; it listed every dataset before.{p_end}
{p 6 8 2}- {cmd:euromod setinfo} reports an error for an unknown system or parameter identifier; it reported success before.{p_end}
{p 6 8 2}- {cmd:euromod reload} reports an error when the path is no longer a valid model, and {cmd:euromod reload} is accepted as well as {cmd:euromod_reload}.{p_end}
{p 6 8 2}- {cmd:euromod run} accepts {opt settings()} together with {opt euro}, {opt sequentialrun} or {opt publiccomponentsonly} also when the settings string does not end with a comma.{p_end}
{p 6 8 2}- {cmd:euromod run, bestmatch} shows its message when the best match of the system is missing or not unique; a quoting error kept it from showing before.{p_end}

{p 4 4 2}{bf:Retired}{p_end}
{p 6 8 2}- The {opt uselogger} option of {cmd:euromod run} is still accepted but ignored; the run prints a note.{p_end}

{p 4 4 2}{bf:Small differences in results and messages}{p_end}
{p 6 8 2}- {cmd:euromod getinfo} with an unknown {opt dataset()} name or {opt parId()} identifier reports an error; it returned no results without an error before.{p_end}
{p 6 8 2}- Every documented r() result is always returned: an empty string when the model has no value, {it:no} for a yes/no result that is not set. Stata keeps no empty result, so one without a value is not listed by {cmd:return list}; reading it gives an empty string. The results r(data_order) and r(par_comment) are new.{p_end}
{p 6 8 2}- An empty parameter value is returned as the model stores it: empty for an EM3 XML country, {it:n/a} for an EM4 bundle.{p_end}
{p 6 8 2}- r(ctry_datasets) no longer starts with a space, and r(mod_countries) lists only the country folders that hold a model.{p_end}
{p 6 8 2}- Dataset names may be given with the {it:.txt} extension and with surrounding spaces.{p_end}
{p 6 8 2}- Add-ons can be queried with {cmd:euromod getinfo}, but their parameters cannot be changed with {cmd:euromod setinfo}: the engine applies the parameters of an add-on before run-time changes, so the change would have no effect.{p_end}
{p 6 8 2}- {cmd:euromod setinfo} refuses an empty {opt newParValue()}; use {it:n/a} to take a parameter out of a system.{p_end}
{p 6 8 2}- {cmd:euromod getinfo, switchvalue} names only the first of system, dataset and extension that it cannot find.{p_end}
{p 6 8 2}- {cmd:euromod getinfo, all country()} for a country folder that does not exist reports "Could not read country Xml and get systemdata combinations. Aborting." instead of "<path>does not exist!".{p_end}
{p 6 8 2}- {cmd:euromod run}: a model or country that cannot be found is reported and counted in $EM_n_errors like an engine error; an unknown extension name is an error (the engine only warned, out of sight of Stata); extension values are {it:on} or {it:off} in any letter case and anything else is refused, as is an extension or add-on given twice; a mismatch between the input variables and the data passed to the plugin is reported; reading past the end of an output is refused; every message ends with a line break.{p_end}
{p 6 8 2}- The connector keeps its session (the models it has read, the changes made with {cmd:euromod setinfo}, the outputs of the last run and the outputs kept with {opt keep}) until Stata exits; {cmd:discard} and {cmd:clear all} no longer clear it. {cmd:euromod reload} is the way to drop the changes made with {cmd:euromod setinfo}, and it lists the changes it discards. A model whose files change on disk is read again by itself and its changes are discarded with a message (a run that would have used them is not started).{p_end}
{p 6 8 2}- The error messages of the information commands keep their wording.{p_end}

{marker authors}
{title:Authors}

{p 4 4 2}
Hannes Serruys, B2-JRC Seville (Hannes.SERRUYS@ec.europa.eu)

{hline}

{break}