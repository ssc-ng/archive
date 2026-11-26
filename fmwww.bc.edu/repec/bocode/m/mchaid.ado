*!mchaid version 1.0.0 24nov2026 - based on chaid 2.2 (2/12/2015) by Joseph N. Luchman
program define mchaid, rclass	//command: runs the estimation (mchaid_est, eclass), shows the output and returns the cluster results in r()

version 12.1

mata: st_local("0", mchaid_qnorm(st_local("0")))													//quartiles and quartiles() (without argument) are quartiles(auto)

if (replay()) {																						//replay syntax: shows the results again and returns r() again

	if ("`e(cmd)'" != "mchaid") error 301

	if (_by()) error 190

	syntax [, noGRaph MCHAIDCLASSIF BRAnches DEFinitions IMPortance *]

	//importance in the replay: the matrix is stored only if it was asked for in the estimation; if not, the estimation is run again (same command line) with importance
	capture confirm matrix e(importance)

	if ("`importance'" != "") & (_rc) {

		local cl `"`e(cmdline)'"'

		gettoken first cl: cl

		if (strpos(`"`cl'"', ",") == 0) local cl `"`cl',"'

		display "{txt}(the estimation is run again to obtain the permutation importance)"

		foreach o in `graph' `branches' `definitions' {

			if (strpos(`"`cl'"', "`o'") == 0) local cl `"`cl' `o'"'							//options already in the command line are not repeated

		}

		local cl = strtrim(`"`cl'"')								//(the positions in the copy in lower case must be those of the line)

		foreach o in dir coll noop {									//directory(), collapse() and noopen typed now replace those of the original command line
			if (regexm(lower(`"`options'"'), "(^| )`o'[a-z]*")) {
				local lcl = lower(`"`cl'"')
				if (regexm(`"`lcl'"', "(^| )(`o'[a-z]*([(][^)]*[)])?)")) {
					local mt = regexs(2)
					local pos = strpos(`"`lcl'"', `"`mt'"')
					local cl = substr(`"`cl'"', 1, `pos' - 1) + substr(`"`cl'"', `pos' + length(`"`mt'"'), .)
				}
			}
		}

		mchaid `cl' importance `options'

		return add

		exit

	}

	if ("`mchaidclassif'" != "") {													//called by estat classification (mchaid_estat.ado): only the classification table

		mchaid_classif, `options'

		return add

		exit

	}

	local show 1

	local nog "`graph'"

	mata: st_local("gopts", mchaid_mergeopts(st_global("e(graphopts)"), st_local("options")))				//the options stored in the estimation and those typed now (the typed ones win)

}

else {

	mchaid_est `0'

	local show = ("`e(nodisplay)'" != "nodisplay")

	local nog "`e(nograph)'"

	local gopts `"`e(graphopts)'"'

	local branches "`e(showbranches)'"																//branches and definitions are shown only when the options were typed

	local definitions "`e(showdefinitions)'"

}

mchaid_results																						//cluster labels, frequencies and cross-tabulation of the response by cluster

return add

if (`show') mchaid_Display, nog(`nog') gopts(`"`gopts'"') `branches' `definitions'		//(compound quotes: the options of the graph may have text with spaces, as rootlabel("two words"))
else if (regexm(lower(`"`gopts'"'), "(^| )dir[a-z]*[(]")) mchaid_graph, `gopts' htmlonly						//nodisplay with directory(): the page is written anyway

end

program define mchaid_est, eclass	//version history at end of file									//program declarations

version 12.1																						//version declaration
syntax varlist(numeric min=1 max=1) [in] [if] [fw], ///											//only one dv and max 1 dv - allows if and in
[MINNode(integer 100) ///																		//minimum number of observations in a terminal node
MINSplit(integer 200) ///																		//minimum number of observations to allow splitting a node
MAXBranch(integer -1) ///																		//maximum number of splits/interactions stemming from the root node
UNOrdered(varlist numeric) ///																	//variable list for unordered splitting treatment in CHAID
ORDered(varlist numeric) ///																	//variable list for ordered splitting treatment in CHAID
MISsing ///																						//treat missing values as floating category
MERGAlpha(real .95) ///																			//alpha level for merging 2 allowable categories									
RESPAlpha(real -1) ///																			//alpha level for respliting 2 allowable, merged categories
SPLTAlpha(real .05) ///																			//alpha level for implementing a split in the data
NOIsily ///																						//shows a lot of output - if the user is interested
DVOrdered ///																					//declares that the outcome is ordered and uses ologit instead of mlogit
noadj ///																						//no Bonferroni adjustment - more permissive splitting
noDisplay	///																					//don't display the results
PREDicted ///																					//obtain predicted values - modal value for category
IMPortance ///																					//obtain permutation importance for input splitting variables
Permute ///																						//use permute to obtain p-values
svy ///																							//incorporate svy design to obtain p-values
///mi(string)	///																				//incorporate multiple imputation to obatain p-values (next relaease?)
XTile(string) ///																				//convenience command for obtaining ordered quantiles of predictors
EXhaust ///
NOFast ///
ORDTable ///
noRENumber ///
STEPs ///
noGRaph ///
noPVAL ///																						//no p-values of the splits on the graph
PCUT(string) ///																				//p-values below this cut are written as p<cut on the graph
LANGuage(string) ///												//language of the texts of the graph: en (default), es, fr, de, it, pt, ca, gl, nl, eu
QUARtiles(string) ///												//quartile lines of the graph with dvordered: auto (default) or all
TREEstyle(string) ///												//style of the graph of the tree: classic (default) or boxes
NODEPlot(string) ///								//with boxes: content of the box of each node: bar (default) or box (dvordered: box plot of the response)
WHISKer(string) ///								//with nodeplot(box): limits of the whiskers: p5 (default), minmax or tukey
noSHADE ///								//with nodeplot(box): colours of one single intensity
NODEHead(string) ///						//with boxes: heading of the boxes: category (default) or number
ROOTLabel(string asis) ///					//with nodehead(category): heading of the root node: total (default), depvar or a text
COLors(string asis) ///						//colours of the categories of the response on the graph: name=colour pairs or one colour for each category, in order
FORCEvars(string) ///						//splitting variables chosen by the user for the first levels of the tree: the first splits the first level, the second the second level, ...
DIRectory(string asis) ///						//folder where the interactive tree (html page) is written
COLLapse(integer -1) ///						//interactive tree: depth from which the branches start collapsed
NOOPen ///							//interactive tree: do not open the page in the browser
BRAnches ///														//shows the table of the branches of the tree
DEFinitions ///													//shows the definitions of the nodes
GRAPHopts(string asis)]																						//use exhaustive CHAID (binary split) instead of default multi-way splits

if ("`pval'" != "") local graphopts `"`graphopts' nopval"'										//nopval and pcut() are options of the graph: they are kept in e(graphopts)

if ("`pcut'" != "") {

	capture confirm number `pcut'

	if (_rc | (real("`pcut'") <= 0) | (real("`pcut'") >= 1)) {

		display "{err}pcut() must be a number between 0 and 1"

		exit 198

	}

	local graphopts `"`graphopts' pcut(`pcut')"'

}

if ("`quartiles'" != "") {																//quartiles() is an option of the graph: it is kept in e(graphopts)

	if (("`quartiles'" != "auto") & ("`quartiles'" != "all")) {

		display "{err}quartiles() must be auto or all"

		exit 198

	}

	local graphopts `"`graphopts' quartiles(`quartiles')"'

}

mchaid_gcheck, treestyle(`treestyle') nodeplot(`nodeplot') whisker(`whisker') nodehead(`nodehead')			//options of the style of boxes: checked now and kept in e(graphopts)
foreach o in treestyle nodeplot whisker nodehead {
	if ("``o''" != "") local graphopts `"`graphopts' `o'(``o'')"'
}
if ("`shade'" != "") local graphopts `"`graphopts' noshade"'
if (`"`rootlabel'"' != "") local graphopts `"`graphopts' rootlabel(`rootlabel')"'
if (`"`directory'"' != "") {								//directory(), collapse() and noopen belong to the interactive tree: they are kept in e(graphopts)
	local directory `directory'
	local graphopts `"`graphopts' directory("`directory'")"'
	if (`collapse' >= 0) local graphopts `"`graphopts' collapse(`collapse')"'
	if ("`noopen'" != "") local graphopts `"`graphopts' noopen"'
}
if (`"`colors'"' != "") {								//the colours are checked now and kept in e(graphopts)
	mchaid_cvalid, spec(`"`colors'"')
	local graphopts `"`graphopts' colors(`colors')"'
}
if (("`nodeplot'" == "box") & ("`dvordered'" == "")) {
	display "{err}nodeplot(box) needs the option dvordered"
	exit 198
}
if ("`language'" != "") {																//the language of the graph is checked now and kept, with the other options of the graph, in e(graphopts)

	mchaid_lang `language'

	local graphopts `"`graphopts' language(`t_lang')"'

}

/*exit and warning conditions*/
if ((`:list sizeof unordered' == 0) & (`:list sizeof ordered' == 0) & ///
(`:list sizeof xtile' == 0)) {																	//exit if no splitting vars entered

	display "{err}No independent variables entered."
	
	exit 111
	
}

if (`minsplit' < `minnode') {																	//exit if you tell chaid that the minnode/cluster size is larger than the min size to make a split

	display "{err}{opt minsplit()} cannot be smaller than " ///
	"{opt minnode()}."

	exit 198
	
}

if ((`mergalpha' <= 0) | (`mergalpha' >= 1) | (`spltalpha' <= 0) | ///
(`spltalpha' >= 1)) {																			//ensure that the alphas are possible

	display "{err}{opt mergalpha()} and {opt spltalpha()} must range " ///
	"betweeen (but not include) 0 and 1."
	
	exit 198

} 

if (`minnode' <= 0) {																			//ensure that min cluster size is a possible number

	display "{err}{opt minnode()} must be a positive integer value."
	
	exit 198

}

if ((`respalpha' >= 1) | (`respalpha' > 1 - `mergalpha') | (`respalpha' == 0)) {				//ensure that alphas are possible values that don't induce splitting forever

	display "{err}{opt resplapha()}, when invoked, must range between (but not include)" _newline ///
	"0 and 1 and must be less than 1 - {opt mergalpha()} to prevent infinite merging and resplitting."
	
	exit 198

}

if (("`weight'" != "") & (("`permute'" != "") | ("`svy'" != ""))) {

	display "{err}{cmd:fweight}s not allowed with {opt permute} or {opt svy}."

	exit 198

}

if (("`permute'" != "") & ("`svy'" != "")) {

	display "{err}{opt permute} and {opt svy} not allowed together."

	exit 198

}

//1) no fw and permute, 2) no fw and svy, 3) no permute and svy

if (strlen("`ordtable'") & (strlen("`dvordered'") | strlen("`svy'") | strlen("`permute'") | strlen("`nofast'"))) {

	display "{err}{opt ordtable} not allowed with {opt dvordered}, {opt svy}, {opt permute} or {opt nofast}."

	exit 198

}

capture which lmoremata.mlib																	//is moremata present?

if (_rc != 0) {																					//if moremata cannot be found, tell user to install it.

	display "{err}Module {cmd:moremata} not found.  Install {cmd:moremata} here {stata ssc install moremata}."
	
	exit 198

}

if (`"`forcevars'"' != "") {												//forcevars(): repeated variables and maxbranch() are checked now, the variables themselves when the splitting variables are known
	local nfv : word count `forcevars'
	local fvu : list uniq forcevars
	if (`:list sizeof forcevars' != `:list sizeof fvu') {
		display "{err}{opt forcevars()} has repeated variables."
		exit 198
	}
	if ((`maxbranch' >= 0) & (`maxbranch' < `nfv')) {
		display "{err}{opt maxbranch()} (`maxbranch') is smaller than the number of variables of {opt forcevars()} (`nfv')."
		exit 198
	}
}

if (strlen("`exhaust'") & (`respalpha' > 0)) display "{txt}note: {opt respalpha()} is ignored with {opt exhaust}."

if strlen("`permute'") local noadj "noadj"

/*begin data processing*/
//mark the estimation sample
tempvar keep touse stop cluster useob dv wt														//tempvar declarations - begin using "touse"; add "keep" markout variables in unordered() and ordered()

tempname cellcount fit																			//tempname declaration for matrix

quietly generate `keep' = 1 `if' `in'															//allows keeping of missings as valid category, but still adjusting for "if"s and "in"s

if strlen("`xtile'") {

	gettoken xtile xtile_opt: xtile, parse(",")

	foreach x of varlist `xtile' {																//convenience command for creating binned continuous predictors in CHAID

		capture inspect xt`x'
	
		if !_rc quietly drop xt`x'

		quietly xtile xt`x' = `x' if `keep' [`weight'`exp'] `xtile_opt'
	
		local ordered "`ordered' xt`x'"

	}
	
}

mark `touse'																					//mark estimation sample

if ("`missing'" == "") markout `touse' `varlist' `unordered' `ordered' `keep'					//markout all variables when missings as category is not desired

else if ("`missing'" != "") & ("`dvordered'" == "") markout `touse' `keep'						//markout only "if" and "in" when missings are a valid category

else if ("`missing'" != "") & ("`dvordered'" != "") markout `touse' `varlist' `keep'			//markout only "if" and "in" and on dv when missings are valid category and dv is declared ordered

drop `keep'																						//"keep" tempvar is dropped so that it does not find its way into mata

foreach x of varlist `varlist' `unordered' `ordered' {											//exit if too many categories (20 is max) or categories are negative integers

	quietly inspect `x' if `touse'
	
	if (r(N_unique) > 20) {
	
		display "{err}Number of distinct values in {cmd:`x'} is larger than allowed. " _newline ///
		"Consider collapsing across similar categories for unordered or using " _newline ///
		"{opt xtile()} option/command for ordered variables to reduce the number of levels."
		
		exit 198
	
	}
	
	else if (r(N) != r(N_0) + r(N_posint)) {
	
		display "{err}Levels of each variable must be non-negative integer values." _newline ///
		" Variable {cmd:`x'} contains negative or decimal values."
		
		exit 198
	
	}

}

//identify and process variables to use
quietly tab `varlist' [`weight'`exp'], matrow(`cellcount')										//identify levels of dependent/outcome variable to create inidicator varaibles

mata: st_local("dvlevs", invtokens(strofreal(st_matrix("`cellcount'")')))						//put levels into a macro for use
		
local dvlist "`varlist'"																		//produce local macro that's updated with tempvar names for use in mata

local dvdisp "`varlist'"																		//produce local macro that's updated with displayed names of outcome and levels
	
local type "`type' d"																			//note "type" of variable for dv

quietly generate `dv' = `varlist'																//local macro to denote variable type for splitting purposes - here "d" denotes dependent variable that will not be split

if ("`missing'" != "") quietly count if missing(`dv')											//discern whether outcome is missing values if missings are of interest

if (("`missing'" != "") & (r(N) > 0) & ("`dvordered'" == "")) {									//if "missing" invoked and dv is not ordered, turn missing into last category
	
	quietly summarize `dv' [`weight'`exp']														//find out what the larget category is
	
	quietly recode `dv' (missing = `=r(max)+1')													//make all missings one bigger than the biggest category													 
	
}

if (`:list sizeof unordered' > 0) {																//process unordered splitting variables when present

	foreach x of varlist `unordered' {

		quietly tabulate `x' if `touse' [`weight'`exp'], matrow(`cellcount') `missing'			//discern levels of each unordered variable for creating binary variables
	
		mata: st_local("`x'levs", invtokens(strofreal(st_matrix("`cellcount'")')))				//put levels of unordered variable into local macro
		
		foreach y of numlist ``x'levs' {
		
			if (`:list posof "`y'" in `x'levs' == 1) {
			
				local type "`type' ("
				
				local unorddisp "`unorddisp' ("
			
			}
		
			if ("`y'" != ".") {
			
				tempvar `x'`y'																	//create tempvars with name of level of unordered, binary variable
				
				quietly generate byte ``x'`y'' = `x' == `y'										//generate binaries for each level of unordered variable
	
				label variable ``x'`y'' "`x' @ `y'"												//label the tempvar for later processing
	
				local unorderedlist "`unorderedlist' ``x'`y''"									//include name of unordered binary variable in list of tempvar names
			
				local unorddisp "`unorddisp' `x'`y'"											//include displayed name of unordered binary variable in list of tempvar names
			
				local type "`type' u"															//include variable type in type macro
	
			} 

			else {																				//if missing option invoked count missings to see whether following syntax needs to be run
			
				tempvar `x'ms																	//assuming missings are present, create tempvar for unordered varible indicating missing
				
				quietly generate byte ``x'ms' = cond(missing(`x'), 1, 0)						//generate indicator for missing category
				
				label variable ``x'ms' "`x' @ missing"											//label the tempvar for later processing
				
				local unorderedlist "`unorderedlist' ``x'ms'"									//include missing tempvar name in unordered list
			
				local unorddisp "`unorddisp' `x'ms"												//include missing display name in unordered display list
				
				local type "`type' f"															//include type "floating"
					
			}
			
			if (`: list posof "`y'" in `x'levs' == `: list sizeof `x'levs') {
			
				local type "`type')"
				
				local unorddisp "`unorddisp')"
			
			}
				
		}
			
	}
			
}
	
if (`:list sizeof ordered' > 0) {

	foreach x of varlist `ordered' {

		quietly tab `x' if `touse' [`weight'`exp'], matrow(`cellcount') `missing'				//if ordered variables present, discern their levels/values
	
		mata: st_local("`x'levs", invtokens(strofreal(st_matrix("`cellcount'")')))				//put levels of ordered variable into local macro
	
		foreach y of numlist ``x'levs' {
		
			if (`: list posof "`y'" in `x'levs' == 1) {
			
				local type "`type' ("
				
				local orddisp "`orddisp' ("
			
			}
		
			if ("`y'" != ".") {
			
				tempvar `x'`y'																	//declare tempvar for each value of ordered variable
				
				quietly generate byte ``x'`y'' = `x' == `y'										//generate binary for each level of ordered variable
		
				label variable ``x'`y'' "`x' @ `y'"												//label the tempvar for later processing
		
				local orderedlist "`orderedlist' ``x'`y''"										//include ordered tempvar in orderedlist 
			
				local orddisp "`orddisp' `x'`y'"												//include display name of variable in ordered display macro
			
				local type "`type' o"															//include variable type in type macro
				
			}
	
			else {																				//if missing option invoked count missings to see whether following syntax needs to be run
			
				tempvar `x'ms																	//assuming missings are present, create tempvar for ordered varible indicating missing
				
				quietly generate byte ``x'ms' = cond(missing(`x'), 1, 0)						//generate indicator for missing category
					
				label variable ``x'ms' "`x' @ missing"											//label the tempvar for later processing					
					
				local orderedlist "`orderedlist' ``x'ms'"										//include missing tempvar name in ordered list
			
				local orddisp "`orddisp' `x'ms"													//include missing display name in unordered display list
						
				local type "`type' f"															//include type "floating"
			
			}
			
			if (`: list posof "`y'" in `x'levs' == `: list sizeof `x'levs') {
			
				local type "`type')"
				
				local orddisp "`orddisp')"
			
			}
					
		}
		
	}

}

/*process estimation options*/
if ("`permute'" != "") local permute "permute `dv' e(chi2) e(ll) e(df_m) e(N):"

local test "e(chi2)"

if ("`svy'" != "") local test "e(F)"

local quietly "quietly"																			//is the chaid process going to display everything?

if ("`noisily'" != "") local quietly ""															//make it non-quiet

quietly generate byte `stop' = 1 if `touse'														//indicator telling chaid to not look for splits on this observation

quietly generate byte `cluster' = 1 if `touse'													//cluster membership - everyone starts in same cluster #1

quietly generate byte `useob' = 0 if `touse'													//indicator for "use this ob" in current analysis

`quietly' summarize `stop' `cluster' [`weight'`exp']											//look at data if non-quiet

local reg "mlogit"																				//default analysis is mlogit

if ("`dvordered'" ! = "") local reg "ologit"													//if dvordered then ologit

/*begin chaid algorithm in Mata*/
/*fast path: with mlogit and no svy/permute the tests are cross-tabulation likelihood-ratio tests computed in Mata*/
local fast ""

local wtvar "`wt'"

if (("`reg'" == "mlogit") & ("`svy'" == "") & ("`permute'" == "") & ("`nofast'" == "")) local fast "fast"

if ("`weight'" != "") quietly generate double `wt' `exp'

else quietly generate double `wt' = 1

local fpos ""
if (`"`forcevars'"' != "") {												//position of each forced variable in `unordered' `ordered' (+ 1: the response is first); the variables of xtile() can be given with their original name or with that of the new variable xt...
	local allsplit "`unordered' `ordered'"
	foreach x of local forcevars {
		local xx "`x'"
		if (!`:list xx in allsplit') {
			if (`:list xx in xtile') local xx "xt`x'"
		}
		local pp : list posof "`xx'" in allsplit
		if (`pp' == 0) {
			display "{err}{opt forcevars()}: {cmd:`x'} is not one of the splitting variables ({opt unordered()}, {opt ordered()} or {opt xtile()})."
			exit 198
		}
		local fpos "`fpos' `=`pp' + 1'"
	}
	local fpu : list uniq fpos
	if (`:list sizeof fpos' != `:list sizeof fpu') {
		display "{err}{opt forcevars()} has repeated variables."
		exit 198
	}
}

local mchaid_estimating 1																//tells the Mata labelling functions that the levels of the ordered variables are in the local macros

`quietly' mata: CHAIDsplit = mchaid("`unorderedlist'", "`orderedlist'", "`type'", ///
"`dvdisp' `unorddisp' `orddisp'", "`dv' `unordered' `ordered'", `mergalpha', ///
`spltalpha', `minsplit', `minnode', `maxbranch', `respalpha', "`adj'", "`svy'", ///
"`exhaust'", "`fast'", "`ordtable'", "`renumber'", "`steps'", "`fpos'")																					//pass arguments to Mata

if (("`forcefb'" != "") & ("`forcefb'" != "0")) {						//the forced split was not possible in some node: it grew freely
	local fbm = cond(`forcefb' > 3, "the first three: ", "")
	display `"{txt}(note: forcevars(): the forced split was not possible in `forcefb' node(s) (`fbm'`forcefbtxt'), which grew freely)"'
}

/*process chaid results*/
capture xi: count																				//nix xi: used in chaid - cleans up dataset														

capture inspect _CHAID																			//is there already a _CHAID variable?

if (_rc == 0) drop _CHAID																		//if there is a _CHAID variable, drop it

rename `cluster' _CHAID																			//rename the current tempvar "cluster" _CHAID

label variable _CHAID "CHAID-defined node"													//label the clustering variable

mchaid_perm_import if `touse', dv("`varlist'") list(0) wexp("`exp'") `svy'

scalar `fit' = r(fit)

if ("`importance'" != "") mata: ifstmnts = J(rows(CHAIDsplit)-1, cols(CHAIDsplit), "")

mata: st_local("clusters", strofreal(rows(CHAIDsplit)-1))

if (`clusters' > 0) {

	forvalues x = 1/`clusters' {

		if ("`noisily'" == "noisily") mata: CHAIDsplit[`=`x'+1', .]
		
		local path`x' ""
	
		mata: st_local("search", strofreal(cols(CHAIDsplit)))
	
		forvalues z = 2/`search' {
	
			mata: st_local("currentname", CHAIDsplit[`=`x'+1', `z'])
	
			local vallist ""
		
			if ("`currentname'" != "") {
	
				foreach y of local currentname {
		
					local name "`:variable label ``y'''"
			
					gettoken varnam level: name, parse("@")
			
					gettoken atsign level: level, parse("@")
			
					if ("`level'" != "") local vallist "`vallist'`level'"
		
				}
			
				local varnam = trim("`varnam'")
			
				local vallist = trim("`vallist'")
		
				local path`x' "`path`x''`varnam'@`vallist';"
		
				if ("`importance'" != "") {
		
					if regexm("`vallist'", "missing") local vallist = subinword("`vallist'", "missing", ".", .)
		
					local ifcomma = subinstr("`vallist'", " ", ",", .)
				
					if (`z' == 2) mata: ifstmnts[`x', `=`z'-1'] = " inlist(" + st_local("varnam") + "," + st_local("ifcomma") + ")"
				
					else mata: ifstmnts[`x', `=`z'-1'] = " & inlist(" + st_local("varnam") + "," + st_local("ifcomma") + ")"
			
				}
			
			}
	
		}
	
	}
	
}


if ("`importance'" != "") & (`clusters' > 0) {
	
	tempname imp_v
	
	mata: imp_n = ""
	
	mata: imp_v = .
	
	foreach x of varlist `ordered' `unordered' {
	
		mchaid_perm_import if `touse', permvar("`x'") dv("`varlist'") list(`clusters') ///
		predlist(`ordered' `unordered') wexp("`exp'") `missing' `svy'
		
		mata: imp_n = (imp_n, "`x'")
		
		mata: imp_v = (imp_v, st_numscalar("r(fit)"))
	
	}
	
	mata: imp_v = st_numscalar("`fit'"):-imp_v
	
	mata: imp_v = imp_v:/rowsum(imp_v)
	
	mata: imp_v = (imp_v \ (., mm_ranks((imp_v[1, 2..cols(imp_v)]:*-1)',1,3)'))
	
	mata: st_local("imp_n", invtokens(imp_n))
	
	mata: st_matrix("`imp_v'", imp_v[., 2..cols(imp_v)])
	
	matrix colnames `imp_v' = `imp_n'
	
	matrix rownames `imp_v' = "raw" "rank"

}

ereturn post , depname(`varlist') esample(`touse')												//clear ereturned values, post dv and obs

mata: st_local("search", strofreal(cols(CHAIDsplit)))

local splitcount = 1

forvalues x = 2/`search' {
	
	mata: t = tokeninit("", pchars=(","))														//set up processing CHAIDsplit matrix

	mata: tokenset(t, CHAIDsplit[1, `x'])

	mata: nameslist = tokengetall(t)
	
	mata: st_local("search_name", strofreal(cols(nameslist)))
	
	forvalues y = 1/`search_name' {
	
		local levels ""
	
		mata: st_local("currentname", nameslist[`y'])
		
		if !regexm("`currentname'", ",") {
		
			foreach z of local currentname {
		
				local name "`:variable label ``z'''"
			
				gettoken name level : name, parse("@")
			
				local level = subinstr("`level'", "@", "", .)
			
				local levels = rtrim("`levels' `level'")
				
			}
			
			local alllevels "`alllevels' (`levels')"
			
			if ("`quietly'" == "") {
		
				display "`name'"	//
			
				display "`alllevels'"	//
			
			}
			
		}
		
	}
			
	ereturn local split`splitcount++' = itrim("`name' `alllevels'")
			
	local alllevels ""	
	
}

ereturn matrix branches = `branchmat'

ereturn matrix splitp = `splitpmat'																//adjusted p-value of each split: row = final node, column = level of the tree

ereturn matrix splitforced = `splitformat'								//1 where the variable of the split was chosen with forcevars(), same layout as e(splitp)

ereturn local forcevars `"`forcevars'"'										//variables of the forced first levels of the tree

ereturn matrix splitchi = `splitchimat'	//test statistic of each split (likelihood-ratio chi2; F with svy), same layout as e(splitp)

ereturn local splitstat = cond("`svy'" != "", "F", "chi2")

local mchaid_estimating 0																		//from here the levels of the ordered variables are read from e()

ereturn local ordered "`ordered'"																//ordered splitting variables and their levels, to abbreviate runs of adjacent categories in the labels

local ordcount = 0

foreach x of local ordered {

	local ++ordcount

	local ordlev ""

	foreach y of local `x'levs {

		if ("`y'" == ".") local y "missing"

		local ordlev "`ordlev' `y'"

	}

	ereturn local ordlev`ordcount' = trim("`ordlev'")

}

quietly summarize _CHAID if e(sample) [`weight'`exp'], meanonly

ereturn scalar N = r(N)

quietly summarize _CHAID, meanonly												//the nodes are numbered 1, 2, 3...: inspect gives a missing number of distinct values when there are more than 99

ereturn scalar N_clusters = r(max)

forvalues x = 1/`=e(N_clusters)' {

	ereturn local path`x' "`path`x''"

}

capture label drop mchaid_clu

forvalues x = 1/`=e(N_clusters)' {

	mchaid_pathtext `"`path`x''"'

	label define mchaid_clu `x' `"`x': `r(text)'"', add

}

label values _CHAID mchaid_clu

quietly tabulate _CHAID [`weight'`exp'], matcell(`cellcount')

matrix `cellcount' = `cellcount''

ereturn matrix sizes = `cellcount'

if ("`importance'" != "") & (`clusters' > 0) ereturn matrix importance = `imp_v'

if ("`predicted'" == "predicted") {

	tempvar order
	
	tempname maxcell maxval
	
	capture inspect CHAID_predict

	if (_rc == 0) drop CHAID_predict

	quietly generate long CHAID_predict = .
	
	forvalues x = 1/`=e(N_clusters)' {
	
		quietly tabulate `varlist' [`weight'`exp'] if _CHAID == `x', matcell(`maxcell') matrow(`maxval') `missing'
		
		mata: predicted = select(st_matrix("`maxval'"), st_matrix("`maxcell'"):==max(st_matrix("`maxcell'")))
		
		mata: st_numscalar("`maxcell'", rows(predicted))
		
		if (`maxcell' == 1) mata: st_numscalar("`maxval'", predicted)
		
		else mata: st_numscalar("`maxval'", min(predicted))
		
		quietly replace CHAID_predict = `maxval' if _CHAID == `x'
	
	}
	
	label variable CHAID_predict "predicted `varlist' values by CHAID"
	
}

ereturn scalar fit = `fit'

ereturn local title = "Chi-Square Automated Interaction Detection (CHAID)"

ereturn local cmd = "mchaid"

ereturn local estat_cmd "mchaid_estat"										//estat classification after mchaid

ereturn local cmdline `"mchaid `0'"'

ereturn local renumber "`renumber'"																//"norenumber" when the clusters keep the order in which they were created

ereturn local missing "`missing'"

ereturn local nograph "`graph'"

ereturn local showbranches "`branches'"										//branches and definitions are shown only when asked for

ereturn local showdefinitions "`definitions'"

ereturn local graphopts `"`graphopts'"'

ereturn local dvordered "`dvordered'"

if ("`weight'" != "") {

	ereturn local wtype "`weight'"

	ereturn local wexp "`exp'"

}


ereturn local nodisplay "`display'"

end

/*model fit program*/
program mchaid_perm_import, rclass

syntax if, dv(string) list(integer) [permvar(varlist) predlist(string) wexp(string) missing svy]

tempvar temp_chaid rand_perm

tempfile chaid_perm

preserve
		
if (!strlen("`svy'")) quietly keep `if'

if strlen("`wexp'") quietly expand `wexp'

quietly generate int `temp_chaid' = .

if (`list' == 0) {

	quietly replace `temp_chaid' = _CHAID

}

else {

	local notpermvar: list predlist-permvar
	
	if (!strlen("`svy'")) quietly keep `predlist' `dv' `temp_chaid'
		
	quietly save `chaid_perm'
		
	quietly keep `permvar'
		
	quietly generate `rand_perm' = runiform()
		
	quietly sort `rand_perm'
	
	if (strlen("`svy'")) quietly merge 1:1 _n using `chaid_perm', nogenerate
		
	else quietly merge 1:1 _n using `chaid_perm', nogenerate keepusing(`notpermvar' `dv' `temp_chaid')

	forvalues x = 1/`list' {

		mata: stata("quietly replace \`temp_chaid' = \`x' if" + invtokens(ifstmnts[`x', .]))

	}
	
}

if (strlen("`svy'")) {

	tempvar svy
	
	tempname best_F
	
	quietly clonevar `svy' = `dv'
	
	quietly svy: tabulate `dv' `svy', `missing'
	
	scalar `best_F' = e(F_Full)
	
	quietly svy: tabulate `dv' `temp_chaid', `missing'
	
	capture scalar `best_F' = e(F_Full)/`best_F'
	
	if (!_rc) return scalar fit = `best_F'
	
	else return scalar fit = 0

}

else {

	quietly tabulate `dv' `temp_chaid', V `missing'

	capture assert r(CramersV) != .
	
	if (!_rc) return scalar fit = abs(r(CramersV))

	else return scalar fit = 0
	
}

restore

end

/*replayable display*/
program mchaid_Display

syntax [, NOG(string) GOPTS(string asis) BRAnches DEFinitions]

local gopts `gopts'													//the options of the graph arrive in compound quotes (they may have text with spaces): the outer quotes are removed

if ("`branches'" != "") display _newline "{res}Chi-Square Automated Interaction Detection (CHAID)" ///
" Tree Branching Results" _newline "{txt}{hline 80}" _newline

if (e(N_clusters) == 1) display _newline "{res}No splits uncovered.  Node #1 is null."

else {

	preserve
	
	clear
	
	mata: st_addobs(st_numscalar("e(N_clusters)"))
	
	quietly mata: labels = st_tempname(max(st_matrix("e(branches)")) + 1)
	
	quietly mata: st_addvar("str100", labels)
	
	forvalues x = 1/`=e(N_clusters)' {
		
		local parse "`e(path`x')'"
		
		gettoken first second: parse, parse(";")
		
		local count = 0
		
		while ("`second'" != "") {
		
			mata: st_local("labvar", labels[1, `++count'])
		
			quietly replace `labvar' = "`first'" in `x'
			
			gettoken first second: second, parse(";")
			
			gettoken first second: second, parse(";")
		
		}
		
		mata: st_local("labvar", labels[1, cols(labels)])
		
		quietly replace `labvar' = "Node #`x'" in `x'
	
	}
	
	mata: st_local("all", invtokens(labels))
	
	if (`"`e(renumber)'"' == "norenumber") sort `all'
	
	quietly putmata namemat = (`all'), replace
	if ("`branches'" != "") mata: namemat'

	mata: namemat =  namemat[., 1..cols(namemat)-1]'

	mata: namemat = (J(1, cols(namemat), "root") \ namemat)
	
	clear
	
	mata: count = 0
	
	mata: column = 1

	local column = 1

	mata: st_local("totcol", strofreal(cols(namemat)))
	
	quietly {

		generate long x = .
	
		generate long y = .

		generate int col = .

		generate byte down = .
	
		generate str100 label = ""

	}
	
	local justup = 0
	
	forvalues y = 1/`totcol' {

		mata: currentvec = namemat[., column]
	
		if (`y' == 1) {
	
			mata: currentvec = select(currentvec, currentvec:!="")
		
			mata: st_local("row", strofreal(rows(currentvec)))
		
			mata: row = 1
		
			forvalues x = 1/`row' {
		
				mata: st_addobs(1)
			
				mata: st_store(++count, st_varindex("x"), column)
			
				mata: st_store(count, st_varindex("y"), row)
			
				mata: st_sstore(count, st_varindex("label"), namemat[row++, column])
		
			}
		
			quietly replace down = 1 if missing(down)
		
			mata: countback = st_data(2::count-1, (st_varindex("x"), st_varindex("y")))
		
			mata: countback = sort(((rows(countback)::1), countback), 1)
		
			mata: st_addobs(rows(countback))
		
			mata: st_store(count+1::count+rows(countback), (st_varindex("x"), st_varindex("y")), countback[., 2..cols(countback)])
		
			mata: count = count + rows(countback)
		
			quietly replace down = 0 if missing(down)
		
			quietly replace col = `y' if missing(col)
		
			mata: column++
	
		}
	
		else if (`y' == `totcol') {
	
			mata: prevvec = namemat[., column-1]
		
			mata: retrace1 = currentvec:==prevvec
		
			mata: retrace2 = currentvec:!=""
		
			mata: retrace = retrace1:*retrace2
		
			mata: obsvd = st_data(., (st_varindex("x"), st_varindex("y"), st_varindex("col"), st_varindex("down")))
		
			mata: obsvd = select(obsvd[., (1..2,4)], obsvd[.,3]:==column-1)
		
			mata: obsvd = select(obsvd[., 1..2], obsvd[.,3]:==1)
		
			mata: obsvd = select((obsvd \ J(rows(retrace)-rows(obsvd), 2, .)), retrace)
		
			mata: st_addobs(rows(obsvd))
		
			mata: st_store(count+1::count+rows(obsvd), (st_varindex("x"), st_varindex("y")), obsvd)
		
			mata: count = count + rows(obsvd)
		
			mata: currentvec = select(currentvec, abs(retrace:-1))
		
			mata: currentvec = select(currentvec, currentvec:!="")
		
			mata: st_local("row", strofreal(rows(currentvec)))
		
			mata: row = rows(obsvd)+1
		
			forvalues x = 1/`row' {
		
				mata: st_addobs(1)
			
				mata: st_store(++count, st_varindex("x"), column)
			
				mata: st_store(count, st_varindex("y"), row)
			
				mata: st_sstore(count, st_varindex("label"), namemat[row++, column])
		
			}	
		
			quietly replace col = `y' if missing(col)
		
			quietly replace down = 1 if missing(down)
	
		}
	
		else {
	
			mata: prevvec = namemat[., column-1]
		
			mata: retrace1 = currentvec:==prevvec
		
			mata: retrace2 = currentvec:!=""
		
			mata: retrace = retrace1:*retrace2
		
			mata: obsvd = st_data(., (st_varindex("x"), st_varindex("y"), st_varindex("col"), st_varindex("down")))
		
			mata: obsvd = select(obsvd[., (1..2,4)], obsvd[.,3]:==column-1)
		
			mata: obsvd = select(obsvd[., 1..2], obsvd[.,3]:==1)
		
			mata: obsvd = select((obsvd \ J(rows(retrace)-rows(obsvd), 2, .)), retrace)
		
			mata: st_addobs(rows(obsvd))
		
			mata: st_store(count+1::count+rows(obsvd), (st_varindex("x"), st_varindex("y")), obsvd)
		
			mata: count = count + rows(obsvd)
		
			mata: currentvec = select(currentvec, abs(retrace:-1))
		
			mata: currentvec = select(currentvec, currentvec:!="")
		
			mata: st_local("row", strofreal(rows(currentvec)))
		
			mata: row = rows(obsvd)+1
		
			forvalues x = 1/`row' {
		
				mata: st_addobs(1)
			
				mata: st_store(++count, st_varindex("x"), column)
			
				mata: st_store(count, st_varindex("y"), row)
			
				mata: st_sstore(count, st_varindex("label"), namemat[row++, column])
		
			}
		
			quietly replace col = `y' if missing(col)
		
			quietly replace down = 1 if missing(down)
		
			mata: countback = st_data(., (st_varindex("x"), st_varindex("y"), st_varindex("col"), st_varindex("down")))
		
			mata: countback = select(countback[., (1..2,4)], countback[.,3]:==column)
		
			mata: countback = select(countback[., 1..2], countback[.,3]:==1)
		
			mata: countback = sort(((rows(countback)::1), countback), 1)
		
			mata: st_addobs(rows(countback))
		
			mata: st_store(count+1::count+rows(countback), (st_varindex("x"), st_varindex("y")), countback[., 2..cols(countback)])
		
			mata: count = count + rows(countback)
		
			quietly replace down = 0 if missing(down)
		
			quietly replace col = `y' if missing(col)
		
			mata: column++
	
		}
	
	}

	quietly summarize y

	quietly replace y = (y - r(min))*-1 + r(max)

	tempname max

	scalar `max' = r(max)

	quietly summarize x

	quietly replace x = `=r(max)/2+r(min)' if y == `max'

	quietly generate int group = .

	forvalues x = `=`max'-1'(-1)1 {

		quietly replace group = y == `x' & label != ""
	
		quietly replace group = group + group[_n-1] in 2/`=_N'
	
		quietly summarize group
	
		forvalues y = `=r(min)'/`=r(max)' {
	
			quietly summarize x if group == `y' & y <= `x'
		
			quietly replace x = `=r(max)/2+r(min)' if group == `y' & y == `x'
	
		}
	
		quietly replace group = .

	}
	
	//the tree is drawn by mchaid_graph (below)

	capture matrix list e(importance)

	if !_rc {

		display _newline "{res}Splitting variable permutation importance"

		matrix list e(importance), noheader
	
	}
	
	restore
	
	if ("`nog'" != "nograph") mchaid_graph, `gopts'
	else if (regexm(lower(`"`gopts'"'), "(^| )dir[a-z]*[(]")) mchaid_graph, `gopts' htmlonly		//nograph with directory(): only the interactive tree

	if ("`definitions'" != "") mchaid_clusterlist

	mchaid_dvtable

}

end

/*text and tables for the output*/
//readable description of a path stored in e(path#): "var@levels;var@levels;" -> "var in {l1, l2} & var = l"
program mchaid_pathtext, rclass

args path

local text ""

gettoken first rest: path, parse(";")

while (`"`first'"' != "") {

	if (`"`first'"' != ";") {

		gettoken var levels: first, parse("@")

		gettoken at levels: levels, parse("@")

		local levels = trim(`"`levels'"')

		local nitems : word count `levels'

		mata: st_local("items", mchaid_levlab("`var'", "`levels'"))

		if (`nitems' == 1) local clause `"`var' = `items'"'

		else local clause `"`var' in {`items'}"'

		if (`"`text'"' != "") local text `"`text' & "'

		local text `"`text'`clause'"'

	}

	gettoken first rest: rest, parse(";")

}

if (`"`text'"' == "") local text "all observations"

return local text `"`text'"'

end

//checks the options of the style of boxes of the graph; the locals of the caller get them in lower case
program mchaid_gcheck
syntax [, TREEstyle(string) NODEPlot(string) WHISKer(string) NODEHead(string)]
foreach o in treestyle nodeplot whisker nodehead {
	local `o' = lower(trim("``o''"))
}
if (("`treestyle'" != "") & !inlist("`treestyle'", "classic", "boxes")) {
	display "{err}treestyle() must be classic or boxes"
	exit 198
}
if (("`nodeplot'" != "") & !inlist("`nodeplot'", "bar", "box")) {
	display "{err}nodeplot() must be bar or box"
	exit 198
}
if (("`whisker'" != "") & !inlist("`whisker'", "p5", "minmax", "tukey")) {
	display "{err}whisker() must be p5, minmax or tukey"
	exit 198
}
if (("`nodehead'" != "") & !inlist("`nodehead'", "category", "number")) {
	display "{err}nodehead() must be category or number"
	exit 198
}
foreach o in treestyle nodeplot whisker nodehead {
	c_local `o' "``o''"
}
end
//converts a colour (name of a Stata colour, "R G B" or #RRGGBB) into "R G B" (r(rgb)); exit 198 if it is not a colour
program mchaid_rgb, rclass
version 12.1
local c = trim(`"`0'"')
local rgb ""
local bad 0
if (substr(`"`c'"', 1, 1) == "#") {
	local h = upper(substr(`"`c'"', 2, .))
	if (length("`h'") != 6) local bad 1
	else {
		forvalues i = 0/2 {
			local v 0
			forvalues d = 1/2 {
				local ch = substr("`h'", 2*`i' + `d', 1)
				local p = strpos("0123456789ABCDEF", "`ch'")
				if (`p' == 0) local bad 1
				local v = 16*`v' + max(`p' - 1, 0)
			}
			local rgb "`rgb' `v'"
		}
	}
}
else if (real(word(`"`c'"', 1)) < .) {
	if (wordcount(`"`c'"') != 3) local bad 1
	forvalues i = 1/3 {
		local w = word(`"`c'"', `i')
		local pc = strpos("`w'", "%")
		if (`pc' > 0) local w = substr("`w'", 1, `pc' - 1)											//an opacity (R G B%50) is ignored
		local x = real("`w'")
		if (`x' >= . ) local bad 1
		else if ((`x' < 0) | (`x' > 255) | (`x' != int(`x'))) local bad 1
		local rgb "`rgb' `w'"
	}
}
else {																									//a name of a Stata colour: its RGB is read from the style file color-name.style
	local nm = lower(`"`c'"')
	if (!regexm("`nm'", "^[a-z0-9_]+$")) local bad 1
	else {
		capture findfile color-`nm'.style
		if (_rc) local bad 1
		else {
			local fn `"`r(fn)'"'
			tempname fh
			file open `fh' using `"`fn'"', read text
			file read `fh' line
			while ((r(eof) == 0) & ("`rgb'" == "")) {
				if (regexm(`"`line'"', `"^set rgb +"([0-9]+) ([0-9]+) ([0-9]+)""')) {
					local rgb "`=regexs(1)' `=regexs(2)' `=regexs(3)'"
				}
				file read `fh' line
			}
			file close `fh'
			if ("`rgb'" == "") local bad 1
		}
	}
}
if (`bad') exit 198
return local rgb = trim("`rgb'")
end
//colors() at estimation: the text is split and every colour is checked (the categories are not known yet)
program mchaid_cvalid
version 12.1
syntax, SPEC(string asis)
mata: mchaid_cparse(st_local("spec"), "", 0)
if (`"`cerr'"' != "") {
	display `"{err}`cerr'"'
	exit 198
}
forvalues k = 1/`ncs' {
	capture mchaid_rgb `cs`k''
	if (_rc) {
		display `"{err}colors(): "`cs`k''" is not a colour (the name of a Stata colour, "R G B" or #RRGGBB)"'
		exit 198
	}
}
end
//colors() at the graph: the colours of the categories of the response (locals col# of the caller), by name or in order
program mchaid_setcolors
version 12.1
syntax, SPEC(string asis) NLEV(integer) LABels(string asis)
mata: mchaid_cparse(st_local("spec"), st_local("labels"), `nlev')
if (`"`cerr'"' != "") {
	display `"{err}`cerr'"'
	exit 198
}
if ("`cramp'" != "") {												//colors(colour, ramp [reverse]): one shade of the colour for each category, from light to dark (reverse: from dark to light)
	capture mchaid_rgb `cs1'
	if (_rc) {
		display `"{err}colors(): "`cs1'" is not a colour (the name of a Stata colour, "R G B" or #RRGGBB)"'
		exit 198
	}
	local rgb "`r(rgb)'"
	gettoken rr rest : rgb
	gettoken gg bb : rest
	forvalues j = 1/`nlev' {
		local jj = cond("`cramp'" == "2", `nlev' + 1 - `j', `j')
		local a = cond(`nlev' == 1, 1, 0.2 + 0.8*(`jj' - 1)/(`nlev' - 1))
		c_local col`j' "`=round(255*(1 - `a') + `rr'*`a')' `=round(255*(1 - `a') + `gg'*`a')' `=round(255*(1 - `a') + `bb'*`a')'"
	}
	exit
}
if ("`cextra'" != "") display "{txt}(note: colors() has more colours than categories: the last ones are not used)"
if (`"`cunk'"' != "") display `"{txt}(note: colors(): these names are not categories of the response and are ignored: `cunk')"'
if (`"`cmis'"' != "") display `"{txt}(note: colors(): no colour for the categories `cmis': the default colours are used)"'
forvalues j = 1/`nlev' {
	if (`"`cj`j''"' != "") {
		capture mchaid_rgb `cj`j''
		if (_rc) {
			display `"{err}colors(): "`cj`j''" is not a colour (the name of a Stata colour, "R G B" or #RRGGBB)"'
			exit 198
		}
		c_local col`j' "`r(rgb)'"
	}
}
end
//graph of the tree: boxes for the splits, categories on the branches, nodes at the bottom with the distribution of the response variable
program mchaid_graph

version 12.1

syntax [, noPCT noPVAL PCUT(string) LANGuage(string) QUARtiles(string) TREEstyle(string) NODEPlot(string) WHISKer(string) noSHADE NODEHead(string) ROOTLabel(string asis) COLors(string asis) DIRectory(string asis) COLLapse(integer -1) NOOPen HTMLONLY TItle(string) NAME(passthru) SAVING(passthru) SCHeme(passthru) *]

if ("`e(cmd)'" != "mchaid") error 301

if ("`pcut'" != "") {																						//p-values below pcut() are written as p<pcut

	capture confirm number `pcut'

	if (_rc | (real("`pcut'") <= 0) | (real("`pcut'") >= 1)) {

		display "{err}pcut() must be a number between 0 and 1"

		exit 198

	}

}

if (("`quartiles'" != "") & ("`quartiles'" != "auto") & ("`quartiles'" != "all")) {

	display "{err}quartiles() must be auto or all"

	exit 198

}

mchaid_gcheck, treestyle(`treestyle') nodeplot(`nodeplot') whisker(`whisker') nodehead(`nodehead')

if (("`treestyle'" != "boxes") & (`"`directory'"' == "")) {													//options of the style of boxes in the classic graph (the interactive tree does use them)
	local ign ""
	foreach o in nodeplot whisker nodehead {
		if ("``o''" != "") local ign "`ign' `o'()"
	}
	if ("`shade'" != "") local ign "`ign' noshade"
	if ("`ign'" != "") display "{txt}(`=trim("`ign'")' ignored with the classic graph: use treestyle(boxes))"
}

if (("`nodeplot'" == "box") & ("`e(dvordered)'" != "dvordered")) {
	display "{err}nodeplot(box) needs a tree estimated with dvordered"
	exit 198
}

if (e(N_clusters) == 1) {

	display _newline "{txt}No splits uncovered: there is no tree to draw."

	exit 0

}

mchaid_results

local nlev = r(N_dv)

local cramv = r(CramersV)																			//shown, with the risk estimate, in the last line of the graph

mchaid_lang `language'																//texts of the graph in the chosen language (locals t_*)

local k = r(N_clusters)

local dvlabels `"`r(dvlabels)'"'

tempname rp E B L M W

matrix `rp' = r(rowpct)

tempname fq

matrix `fq' = r(freq)											//counts of the categories in each cluster (interactive tree)

local dvname : variable label `e(depvar)'														//the title uses the label of the response variable when it has one

if ("`dvname'" == "") local dvname "`e(depvar)'"

local usertitle `"`title'"'												//the style of boxes has no title unless the user gives one
if (`"`title'"' == "") local title `"`t_title'`dvname'"'

if (`"`e(dvordered)'"' == "dvordered") {																//ordered response: sequential colours from light to dark

	forvalues j = 1/`nlev' {

		local t = (`j' - 1)/max(`nlev' - 1, 1)

		local col`j' "`=round(222 + (8 - 222)*`t')' `=round(235 + (48 - 235)*`t')' `=round(247 + (107 - 247)*`t')'"

	}

}

else {																								//unordered response: colour-blind safe palette

	tokenize `""0 114 178" "230 159 0" "0 158 115" "204 121 167" "86 180 233" "213 94 0" "240 228 66" "100 100 100""'

	forvalues j = 1/`nlev' {

		local pos = mod(`j' - 1, 8) + 1

		local col`j' "``pos''"

	}

}

if (`"`colors'"' != "") mchaid_setcolors, spec(`"`colors'"') nlev(`nlev') labels(`"`dvlabels'"')				//colors(): they replace the default ones

	local np = cond("`nodeplot'" == "", "bar", "`nodeplot'")
	local wh = cond("`whisker'" == "", "p5", "`whisker'")
	local shd "`shade'"
	local nh = cond("`nodehead'" == "", "category", "`nodehead'")									//heading of the boxes: the category of the splitting variable that forms the node, or the number of the node
	local rl `rootlabel'
	if ((`"`rl'"' == "") | (lower(`"`rl'"') == "total")) local rl `"`t_total'"'
	else if (lower(`"`rl'"') == "depvar") local rl `"`dvname'"'

local pcls = ("`treestyle'" == "classic")								//with directory(): the page in the layout of the classic graph only if treestyle(classic) is typed

local hdir ""																		//interactive tree: the folder of the page (the json is written by mchaid_tree2)
if (`"`directory'"' != "") {
	local directory `directory'
	local hdir `"`directory'"'
	mata: mchaid_tree2("`rp'", `"`usertitle'"')
	mchaid_htmlpage, directory(`"`hdir'"') `noopen' title(`"`usertitle'"')
	local hdir ""
}
if ("`htmlonly'" != "") exit

if ("`treestyle'" == "boxes") {																			//style of boxes: every node is a box with its distribution of the response variable
	mata: mchaid_tree2("`rp'", `"`usertitle'"')											//calculated with the data in memory (labels of variables and values)
	preserve
	quietly clear
	mata: mchaid_tree2put()
	local plots `"(pcspike e1 e2 e3 e4 if ed == 0, lcolor(gs6) lwidth(thin))"'
	local plots `"`plots' (pcspike e1 e2 e3 e4 if ed == 1, lcolor(gs6) lwidth(thin) lpattern(dash))"'
	local plots `"`plots' (rbar r1 r2 r3 if rk == 2, horizontal barwidth(`h_back') fcolor(white) lcolor(white) lwidth(vthin))"'
	forvalues i = 1/3 {																				//backgrounds of the labels of the branches (1, 2 or 3 lines)
		local plots `"`plots' (rbar r1 r2 r3 if rk == `=2 + `i'', horizontal barwidth(`h_lab`i'') fcolor("245 242 235") lcolor("245 242 235") lwidth(vthin))"'
	}
	local plots `"`plots' (rbar r1 r2 r3 if rk == 1, horizontal barwidth(`h_box') fcolor(white) lcolor(gs4) lwidth(medium))"'
		local plots `"`plots' (rbar r1 r2 r3 if rk == 6, horizontal barwidth(`h_badge') fcolor(white) lcolor(gs4) lwidth(thin))"'				//square with the number of the node (nodehead(category))
		local plots `"`plots' (rbar r1 r2 r3 if rk == 7, horizontal barwidth(`h_badge') fcolor("64 64 64") fintensity(100) lcolor("64 64 64") lwidth(thin))"'		//the same, dark, for a terminal node
		local plots `"`plots' (rbar r1 r2 r3 if rk == 8, horizontal barwidth(0.27) fcolor("64 64 64") fintensity(100) lcolor("64 64 64") lwidth(vthin))"'			//dark heading of a terminal node (nodehead(number))
	forvalues j = 1/`nlev' {
		local plots `"`plots' (rbar r1 r2 r3 if rk == `=100 + `j'', horizontal barwidth(`h_bar') fcolor("`col`j''") lcolor(white) lwidth(vthin))"'
		local plots `"`plots' (rbar r1 r2 r3 if rk == `=10 + `j'', horizontal barwidth(.16) fcolor("`col`j''") lcolor(white) lwidth(vthin))"'
	}
	forvalues s = 1/5 {																				//five levels of intensity of the blue (above the reference) and of the orange (below it)
		local a = 0.2 + 0.8*(`s' - 1)/4
		local cb`s' "`=round(255*(1 - `a'))' `=round(255*(1 - `a') + 114*`a')' `=round(255*(1 - `a') + 178*`a')'"
		local co`s' "`=round(255*(1 - `a') + 213*`a')' `=round(255*(1 - `a') + 94*`a')' `=round(255*(1 - `a'))'"
	}
	local plots `"`plots' (rbar r1 r2 r3 if rk == 900, horizontal barwidth(`h_q') fcolor(gs13) lcolor(gs5) lwidth(thin))"'
	forvalues s = 1/5 {
		local plots `"`plots' (rbar r1 r2 r3 if rk == `=200 + `s'', horizontal barwidth(`h_q') fcolor("`cb`s''") lcolor(gs5) lwidth(thin))"'
		local plots `"`plots' (rbar r1 r2 r3 if rk == `=210 + `s'', horizontal barwidth(`h_q') fcolor("`co`s''") lcolor(gs5) lwidth(thin))"'
	}
	local plots `"`plots' (rbar r1 r2 r3 if rk == 240, horizontal barwidth(.16) fcolor("`cb5'") lcolor(white) lwidth(vthin))"'
	local plots `"`plots' (rbar r1 r2 r3 if rk == 241, horizontal barwidth(.16) fcolor("`co5'") lcolor(white) lwidth(vthin))"'
	local plots `"`plots' (pcspike e1 e2 e3 e4 if ed == 2, lcolor(gs5) lwidth(thin))"'
	local plots `"`plots' (pcspike e1 e2 e3 e4 if ed == 3, lcolor(black) lwidth(medthick))"'
	local plots `"`plots' (pcspike e1 e2 e3 e4 if ed == 4, lcolor("0 158 115") lwidth(medthin))"'
	foreach spec in "1 nm" "2 n" "6 n" "3 sv" "4 ch" "30 ch" "5 bl" "7 lg" "8 lt" "9 tt" "41 h2" "42 h3" "43 h4" "44 h5" "50 pc" {											//texts: points without symbol with the text as label
		gettoken kind sz : spec
		local sz = trim("`sz'")
		local plots `"`plots' (scatter ty tx if tk == `kind', msymbol(none) mlabel(ts) mlabposition(0) mlabsize(`s_`sz'') mlabcolor(black))"'
	}
	local plots `"`plots' (scatter ty tx if tk == 51, msymbol(none) mlabel(ts) mlabposition(0) mlabsize(`s_pc') mlabcolor(white))"'				//number of a terminal node (white on the dark square)
	local plots `"`plots' (scatter ty tx if tk == 52, msymbol(none) mlabel(ts) mlabposition(0) mlabsize(`s_nm') mlabcolor(white))"'				//heading "Node N" of a terminal node (nodehead(number))
	forvalues j = 1/`nlev' {
		gettoken red rest : col`j'																			//white labels on dark colours, black labels on light ones
		gettoken green blue : rest
		local lum = 0.299*`red' + 0.587*`green' + 0.114*`blue'
		local labcol = cond(`lum' < 140, "white", "black")
		local predcol = cond(`lum' < 170, `"`col`j''"', "gs6")													//the prediction is written in the colour of its category, unless it is too light to be read
		local plots `"`plots' (scatter ty tx if tk == `=100 + `j'', msymbol(none) mlabel(ts) mlabposition(0) mlabsize(`s_pc') mlabcolor(`labcol'))"'
		local plots `"`plots' (scatter ty tx if tk == `=10 + `j'', msymbol(none) mlabel(ts) mlabposition(0) mlabsize(`s_pr') mlabcolor("`predcol'"))"'
	}
	capture twoway `plots', legend(off) xscale(off range(0 `xs')) yscale(off range(0 `ys')) xlabel(none) ylabel(none) ///
	plotregion(margin(zero) style(none)) graphregion(color(white) margin(zero)) aspectratio(`=`ys'/`xs'') xsize(`xs') ysize(`ys') ///
	`name' `saving' `scheme' `options'
	if (_rc) {
		display "{err}The graph could not be drawn (error r(" string(_rc) "))."
		exit _rc
	}
	restore
	exit
}

mata: mchaid_tree("`E'", "`B'", "`L'", "`M'", "`rp'", `"`title'"', "`W'")

capture confirm matrix `M'

local hasm = !_rc

local nrm = 0

if (`hasm') local nrm = rowsof(`M')

preserve

quietly {

	clear

	set obs `=max(rowsof(`E'), rowsof(`B'), rowsof(`L'), rowsof(`W'), `nrm')'

	svmat `E', names(e)

	svmat `B', names(b)

	svmat `L', names(l)

	svmat `W', names(w)

	if (`hasm') svmat `M', names(m)

	generate str6 plab = string(round(b5), "%3.0f") + cond(b7 == 1, "*", "")

}

local plots ""

local pctplots ""

forvalues j = 1/`nlev' {

	local col "`col`j''"

	local plots `"`plots' (rbar b3 b2 b1 if b4 == `j', barwidth(.92) fcolor("`col'") lcolor(white) lwidth(vthin))"'

	local plots `"`plots' (rbar l3 l2 l1 if l4 == `j', barwidth(.16) fcolor("`col'") lcolor(white) lwidth(vthin))"'

	gettoken red rest : col																				//white labels on dark colours, black labels on light ones

	gettoken green blue : rest

	local labcol "black"

	if (0.299*`red' + 0.587*`green' + 0.114*`blue' < 140) local labcol "white"

	local pctplots `"`pctplots' (scatter b6 b1 if b4 == `j' & (b5 >= 12 | b7 == 1) & b5 < ., msymbol(none) mlabel(plab) mlabposition(0) mlabsize(`psz') mlabcolor(`labcol'))"'

}

local plots `"`plots' (pcspike e1 e2 e3 e4, lcolor(gs7) lwidth(thin))"'

	local plots `"`plots' (rbar w1 w2 w3, horizontal barwidth(`bhw') fcolor(white) lcolor(white) lwidth(vthin))"'				//white block of the splitting variable and its test over each branch (the texts are drawn over it)

if (`hasm') {																				//ordered response: median (solid) and quartiles (dotted) of each node in red

	foreach p in shortdash solid {

		local pat = cond("`p'" == "solid", 0, 1)

		local wr = cond("`p'" == "solid", "medium", cond("`quartiles'" == "all", "thin", "medthick"))									//the quartiles: short wide dashes, which look like dots (the dot pattern of Stata gives very thin vertical ticks); thinner with quartiles(all), when they can be close to each other

		local plots `"`plots' (pcspike m1 m2 m3 m4 if m5 == `pat', lcolor("0 158 115") lwidth(`wr') lpattern(`p'))"'

	}

}

if ("`pct'" == "") local plots `"`plots' `pctplots'"'

capture twoway `plots', `textopts' legend(off) xscale(off range(0 `xs')) yscale(off range(0 `ys')) xlabel(none) ylabel(none) ///
plotregion(margin(zero) style(none)) graphregion(color(white) margin(zero)) aspectratio(`=`ys'/`xs'') xsize(`xs') ysize(`ys') ///
`name' `saving' `scheme' `options'

if (_rc == 1003) {														//too many options: the tree has too many nodes for the number of options that a Stata graph accepts

	restore

	display _newline "{err}The tree has `=e(N_clusters)' nodes: too many to be drawn (a Stata graph accepts a limited number of options)."

	display "{txt}Use {opt nograph} to show the results without the graph, or build a smaller tree: a lower {opt maxbranch()} (maximum number of splits from the root node),"

	display "{txt}or a higher {opt minnode()} and {opt minsplit()}."

	exit 0

}

else if (_rc) {

	display "{err}The graph could not be drawn (error r(" string(_rc) "))."

	exit _rc

}

restore

end
//interactive tree: creates the folder of the page (index.html, styles/ and scripts/) with the json that mchaid_tree2 has built, and shows the link
program mchaid_htmlpage

version 12.1

syntax, DIRectory(string asis) [NOOPen TItle(string asis)]

local dir `directory'

local dir = subinstr(`"`dir'"', "\", "/", .)

while (substr(`"`dir'"', -1, 1) == "/") & (length(`"`dir'"') > 1) {
	local dir = substr(`"`dir'"', 1, length(`"`dir'"') - 1)
}

local ttl `title'

if (`"`ttl'"' == "") local ttl "mchaid tree"

local index `"`dir'/index.html"'

mata: st_local("direx", strofreal(direxists(st_local("dir"))))

if (`direx') {

	local nfiles : dir `"`dir'"' files "*"
	local ndirs : dir `"`dir'"' dirs "*"
	local ok = (`"`nfiles'`ndirs'"' == "")						//an empty folder is accepted

	capture confirm file `"`index'"'

	if (!_rc) {

		tempname fh
		file open `fh' using `"`index'"', read text
		file read `fh' line
		while (r(eof) == 0) {
			if (strpos(`"`macval(line)'"', "<!--mchaid Project-->") | strpos(`"`macval(line)'"', "<!--rD3tree Project-->")) local ok = 1
			file read `fh' line
		}
		file close `fh'

	}

	if (!`ok') {

		display "{err}directory {bf:`dir'} already exists and is not a page of mchaid: use another folder or empty it"

		exit 693

	}

	foreach sub in styles scripts {							//the files of the previous page
		mata: st_local("subx", strofreal(direxists(st_local("dir") + "/`sub'")))
		if (`subx') {
			local fl : dir `"`dir'/`sub'"' files "*"
			foreach f of local fl {
				quietly erase `"`dir'/`sub'/`f'"'
			}
			capture rmdir `"`dir'/`sub'"'
		}
	}

	capture erase `"`index'"'

}

else mata: mchaid_mkdirs(st_local("dir"))

quietly mkdir `"`dir'/styles"'

quietly mkdir `"`dir'/scripts"'

foreach pair in "mchaid_tree_css.ado styles/tree.css" "mchaid_d3_js.ado scripts/d3.min.js" "mchaid_tree_js.ado scripts/tree.js" {			//(the files of the page travel as .ado: net install puts only those in the ado path)

	gettoken src dst : pair

	local dst = trim("`dst'")

	capture findfile `src'

	if (_rc) {

		display "{err}the file {bf:`src'} of the package was not found: install mchaid again (net install mchaid, replace)"

		exit 601

	}

	quietly copy `"`r(fn)'"' `"`dir'/`dst'"', replace

}

mata: mchaid_hwrite(st_local("index"), st_local("ttl"))

local full `"`dir'"'

if (!regexm(`"`full'"', "^([a-zA-Z]:)?/") & (substr(`"`full'"', 1, 1) != "~")) local full = subinstr(`"`c(pwd)'"', "\", "/", .) + "/" + `"`full'"'

local url = "file://" + cond(substr(`"`full'"', 1, 1) == "/", "", "/") + subinstr(`"`full'"', " ", "%20", .) + "/index.html"

display _newline `"{txt}Interactive tree: {browse "`url'":`dir'/index.html}"'

if ("`noopen'" == "" & "`c(mode)'" != "batch") view browse "`url'"

end
//texts of the graph in the language chosen with language(); they are returned in the locals t_* of the caller (accents need Stata 14 or later)
program mchaid_lang

version 12.1

args code

local code = lower(trim("`code'"))

if ("`code'" == "") local code "en"

if ("`code'" == "po") local code "pt"

if (strpos(" en es fr de it pt ca gl nl eu ", " `code' ") == 0) {

	display "{err}language() must be one of: en es fr de it pt (or po) ca gl nl eu"

	exit 198

}

if ((c(stata_version) < 14) & ("`code'" != "en")) {

	display "{txt}language(): the accents of the graph need Stata 14 or later; the graph is written in English"

	local code "en"

}

//title (before the name of the response variable), node (@ = number), risk, root node, Cramer's V, note, missing category, median (legend of the ordered response)
if ("`code'" == "en") {

	local title "CHAID tree: "
	local node "Node @"
	local risk "Risk estimate"
	local root "root node"
	local cramer "Cram\u00e9r's V"
	local note "Bars: distribution (%) of the response variable within each node; * = modal category"
	local missing "missing"
	local median "Median"
	local legend "(% within each node)"
	local pred "Pred.:"
	local overallmed "Overall median"
	local above "Above"
	local below "Below"
	local minmax "Min-Max"
	local leaf "Terminal node"
	local iqr "1.5 IQR"
	local total "Total"
	local forced "variable chosen by the user (forcevars)"

}

else if ("`code'" == "es") {

	local title "\u00c1rbol CHAID: "
	local node "Nodo @"
	local risk "Estimaci\u00f3n del riesgo"
	local root "nodo ra\u00edz"
	local cramer "V de Cram\u00e9r"
	local note "Barras: distribuci\u00f3n (%) de la variable respuesta en cada nodo; * = categor\u00eda modal"
	local missing "perdido"
	local median "Mediana"
	local legend "(% dentro de cada nodo)"
	local pred "Pred.:"
	local overallmed "Mediana global"
	local above "Por encima"
	local below "Por debajo"
	local minmax "M\u00edn-M\u00e1x"
	local leaf "Nodo terminal"
	local iqr "1,5 RIC"
	local total "Total"
	local forced "variable elegida por el usuario (forcevars)"

}

else if ("`code'" == "fr") {

	local title "Arbre CHAID : "
	local node "N\u0153ud @"
	local risk "Estimation du risque"
	local root "n\u0153ud racine"
	local cramer "V de Cram\u00e9r"
	local note "Barres : distribution (%) de la variable r\u00e9ponse dans chaque n\u0153ud ; * = cat\u00e9gorie modale"
	local missing "manquant"
	local median "M\u00e9diane"
	local legend "(% dans chaque n\u0153ud)"
	local pred "Pr\u00e9d. :"
	local overallmed "M\u00e9diane globale"
	local above "Au-dessus"
	local below "En dessous"
	local minmax "Min-Max"
	local leaf "N\u0153ud terminal"
	local iqr "1,5 EIQ"
	local total "Total"
	local forced "variable choisie par l'utilisateur (forcevars)"

}

else if ("`code'" == "de") {

	local title "CHAID-Baum: "
	local node "Knoten @"
	local risk "Risikosch\u00e4tzung"
	local root "Wurzelknoten"
	local cramer "Cram\u00e9rs V"
	local note "Balken: Verteilung (%) der Zielvariable in jedem Knoten; * = h\u00e4ufigste Kategorie"
	local missing "fehlend"
	local median "Median"
	local legend "(% innerhalb jedes Knotens)"
	local pred "Vorh.:"
	local overallmed "Gesamtmedian"
	local above "\u00dcber"
	local below "Unter"
	local minmax "Min-Max"
	local leaf "Endknoten"
	local iqr "1,5 IQR"
	local total "Gesamt"
	local forced "vom Benutzer gew\u00e4hlte Variable (forcevars)"

}

else if ("`code'" == "it") {

	local title "Albero CHAID: "
	local node "Nodo @"
	local risk "Stima del rischio"
	local root "nodo radice"
	local cramer "V di Cram\u00e9r"
	local note "Barre: distribuzione (%) della variabile risposta in ogni nodo; * = categoria modale"
	local missing "mancante"
	local median "Mediana"
	local legend "(% all'interno di ogni nodo)"
	local pred "Prev.:"
	local overallmed "Mediana complessiva"
	local above "Sopra"
	local below "Sotto"
	local minmax "Min-Max"
	local leaf "Nodo terminale"
	local iqr "1,5 SIQ"
	local total "Totale"
	local forced "variabile scelta dall'utente (forcevars)"

}

else if ("`code'" == "pt") {

	local title "\u00c1rvore CHAID: "
	local node "N\u00f3 @"
	local risk "Estimativa de risco"
	local root "n\u00f3 raiz"
	local cramer "V de Cram\u00e9r"
	local note "Barras: distribui\u00e7\u00e3o (%) da vari\u00e1vel resposta em cada n\u00f3; * = categoria modal"
	local missing "ausente"
	local median "Mediana"
	local legend "(% dentro de cada n\u00f3)"
	local pred "Prev.:"
	local overallmed "Mediana global"
	local above "Acima"
	local below "Abaixo"
	local minmax "M\u00edn-M\u00e1x"
	local leaf "N\u00f3 terminal"
	local iqr "1,5 AIQ"
	local total "Total"
	local forced "vari\u00e1vel escolhida pelo utilizador (forcevars)"

}

else if ("`code'" == "ca") {

	local title "Arbre CHAID: "
	local node "Node @"
	local risk "Estimaci\u00f3 del risc"
	local root "node arrel"
	local cramer "V de Cram\u00e9r"
	local note "Barres: distribuci\u00f3 (%) de la variable resposta a cada node; * = categoria modal"
	local missing "perdut"
	local median "Mediana"
	local legend "(% dins de cada node)"
	local pred "Pred.:"
	local overallmed "Mediana global"
	local above "Per sobre"
	local below "Per sota"
	local minmax "M\u00edn-M\u00e0x"
	local leaf "Node terminal"
	local iqr "1,5 RIQ"
	local total "Total"
	local forced "variable triada per l'usuari (forcevars)"

}

else if ("`code'" == "gl") {

	local title "\u00c1rbore CHAID: "
	local node "Nodo @"
	local risk "Estimaci\u00f3n do risco"
	local root "nodo ra\u00edz"
	local cramer "V de Cram\u00e9r"
	local note "Barras: distribuci\u00f3n (%) da variable resposta en cada nodo; * = categor\u00eda modal"
	local missing "perdido"
	local median "Mediana"
	local legend "(% dentro de cada nodo)"
	local pred "Pred.:"
	local overallmed "Mediana global"
	local above "Por riba"
	local below "Por baixo"
	local minmax "M\u00edn-M\u00e1x"
	local leaf "Nodo terminal"
	local iqr "1,5 RIC"
	local total "Total"
	local forced "variable escollida polo usuario (forcevars)"

}

else if ("`code'" == "nl") {

	local title "CHAID-boom: "
	local node "Knoop @"
	local risk "Risicoschatting"
	local root "wortelknoop"
	local cramer "Cram\u00e9rs V"
	local note "Balken: verdeling (%) van de responsvariabele in elke knoop; * = modale categorie"
	local missing "ontbrekend"
	local median "Mediaan"
	local legend "(% binnen elke knoop)"
	local pred "Voorsp.:"
	local overallmed "Totale mediaan"
	local above "Boven"
	local below "Onder"
	local minmax "Min-Max"
	local leaf "Eindknoop"
	local iqr "1.5 IQR"
	local total "Totaal"
	local forced "door de gebruiker gekozen variabele (forcevars)"

}

else {																									//eu

	local title "CHAID zuhaitza: "
	local node "@. nodoa"
	local risk "Arriskuaren estimazioa"
	local root "erro-nodoa"
	local cramer "Cram\u00e9r-en V"
	local note "Barrak: erantzun-aldagaiaren banaketa (%) nodo bakoitzean; * = kategoria modala"
	local missing "galdua"
	local median "Mediana"
	local legend "(% nodo bakoitzaren barruan)"
	local pred "Aurrez.:"
	local overallmed "Mediana orokorra"
	local above "Gainetik"
	local below "Azpitik"
	local minmax "Min-Max"
	local leaf "Amaierako nodoa"
	local iqr "1.5 IQR"
	local total "Guztira"
	local forced "erabiltzaileak aukeratutako aldagaia (forcevars)"

}

foreach t in title node risk root cramer note missing median legend pred overallmed above below minmax iqr total forced leaf {

	if (c(stata_version) >= 14) local `t' = ustrunescape(`"``t''"')

	else if ("`t'" == "cramer") local cramer "Cramer's V"															//Stata 12 and 13: English without the accent

	c_local t_`t' `"``t''"'

}

c_local t_lang "`code'"
c_local t_dagger = cond(c(stata_version) >= 14, ustrunescape("\u2020"), "+")						//mark of the forced variables in the classic graph (the asterisk is the modal category there)
c_local t_chi = cond(c(stata_version) >= 14, ustrunescape("\u03c7\u00b2"), "Chi2")							//chi2 of the tests of the splits (graph of the boxes)

end

//classification table: each case is classified in the modal category of its node and compared with its real category
program mchaid_classif, rclass

version 12.1

syntax [, POSitive(string)]

if ("`e(cmd)'" != "mchaid") error 301

mchaid_results

local L = r(N_dv)

local labels `"`r(dvlabels)'"'

local depvar "`r(depvar)'"

tempname F C R P T N K S

matrix `F' = r(freq)

mata: mchaid_class("`F'", "`C'", "`R'", "`T'", "`P'", "`N'", "`K'", "`S'")

local lw = 22																							//width of the labels of the rows and of the columns

local cw = 9

local wide = `cw'*`L'

local rest `"`labels'"'

forvalues j = 1/`L' {

	gettoken lab rest : rest

	local fl`j' `"`lab'"'														//full label of the category

	if (c(stata_version) >= 14) {

		local lr`j' = usubstr(`"`lab'"', 1, `lw' - 2)

		local lc`j' = usubstr(`"`lab'"', 1, `cw' - 1)

	}

	else {

		local lr`j' = substr(`"`lab'"', 1, `lw' - 2)

		local lc`j' = substr(`"`lab'"', 1, `cw' - 1)

	}

}

local pos 0																							//category taken as positive (D) for the detailed statistics: its label or its position in the table

if (`"`positive'"' != "") {

	forvalues j = 1/`L' {

		if (lower(`"`fl`j''"') == lower(`"`positive'"')) local pos `j'

	}

	if (`pos' == 0) {

		capture confirm integer number `positive'

		if (!_rc) {

			if ((`positive' >= 1) & (`positive' <= `L')) local pos = `positive'

		}

	}

	if (`pos' == 0) {

		display `"{err}positive(): `positive' is neither a category of the response variable nor a number between 1 and `L'"'

		exit 198

	}

}

local vl : variable label `depvar'

if (`"`vl'"' == "") local vl "`depvar'"

display

display `"{txt}Classification table: {res}`vl'"'

display "{txt}Each case is classified in the modal category of its node (`e(N_clusters)' nodes)"

display

display "{txt}{lalign `lw':}{c |}{center `wide':Classified as}{c |}{ralign 9:}{ralign 11:}"

local line "{txt}{lalign `lw':Observed}{c |}"

forvalues j = 1/`L' {

	local line `"`line'{ralign `cw':`lc`j''}"'

}

display `"`line'{c |}{ralign 9:Total}{ralign 11:% correct}"'

display "{txt}{hline `lw'}{c +}{hline `wide'}{c +}{hline 20}"

forvalues i = 1/`L' {

	local line `"{txt}{lalign `lw':`lr`i''}{c |}{res}"'

	forvalues j = 1/`L' {

		local line `"`line'{ralign `cw':`=string(el(`C', `i', `j'), "%9.0fc")'}"'

	}

	local pc = cond(el(`R', `i', 1) > 0, string(el(`P', `i', 1), "%5.1f"), ".")

	display `"`line'{txt}{c |}{res}{ralign 9:`=string(el(`R', `i', 1), "%9.0fc")'}{ralign 11:`pc'}"'

}

display "{txt}{hline `lw'}{c +}{hline `wide'}{c +}{hline 20}"

local line "{txt}{lalign `lw':Total}{c |}{res}"

forvalues j = 1/`L' {

	local line `"`line'{ralign `cw':`=string(el(`T', 1, `j'), "%9.0fc")'}"'

}

display `"`line'{txt}{c |}{res}{ralign 9:`=string(`N', "%9.0fc")'}{ralign 11:`=string(100*`K'/`N', "%5.1f")'}"'

display "{txt}{hline `lw'}{c BT}{hline `wide'}{c BT}{hline 20}"

local nn = trim(string(`N', "%12.0fc"))

local kk = trim(string(`K', "%12.0fc"))

display "{txt}Correctly classified: {res}" trim(string(100*`K'/`N', "%5.1f")) "%{txt} (`kk' of `nn')"

display "{txt}Risk estimate (proportion misclassified): {res}" trim(string(1 - `K'/`N', "%5.3f"))

display

display "{txt}Statistics of each category versus the rest of them (%)"

display

display "{txt}{lalign `lw':Category}{c |}{ralign 12:Sensitivity}{ralign 12:Precision}{ralign 12:F1}{ralign 12:Specificity}{ralign 12:NPV}"

display "{txt}{hline `lw'}{c +}{hline 60}"

forvalues i = 1/`L' {

	local line `"{txt}{lalign `lw':`lr`i''}{c |}{res}"'

	foreach s in 1 3 9 2 4 {														//columns of S: sensitivity (recall), precision (PPV), F1, specificity, NPV

		local v = el(`S', `i', `s')

		local line `"`line'{ralign 12:`=cond(missing(`v'), ".", string(`v', "%5.1f"))'}"'

	}

	display `"`line'"'

}

display "{txt}{hline `lw'}{c BT}{hline 60}"

display "{txt}Sensitivity = recall, Precision = positive predictive value (PPV), NPV = negative predictive value"

display "{txt}F1 = 2*Precision*Sensitivity/(Precision + Sensitivity)"

local f1m = 0																							//F1 averaged over the categories: macro (all the same weight) and weighted by the number of real cases

local f1w = 0

forvalues i = 1/`L' {

	local f1m = `f1m' + el(`S', `i', 9)/`L'

	local f1w = `f1w' + el(`S', `i', 9)*el(`R', `i', 1)/`N'

}

display "{txt}F1 averaged over the categories: macro {res}" trim(string(`f1m', "%5.1f")) "%{txt}, weighted by the real cases {res}" trim(string(`f1w', "%5.1f")) "%"

if (`pos' > 0) {																						//detailed list for the category chosen with positive()

	local tp = el(`C', `pos', `pos')

	local acc = 100*(`N' - (el(`R', `pos', 1) - `tp') - (el(`T', 1, `pos') - `tp'))/`N'

	display

	display `"{txt}Classified + if classified in the category {res}`fl`pos''"'

	display `"{txt}True D defined as {res}`vl' = `fl`pos''"'

	display "{txt}{hline 50}"

	local st1 "Sensitivity"
	local st2 "Specificity"
	local st3 "Positive predictive value"
	local st4 "Negative predictive value"
	local st5 "False + rate for true ~D"
	local st6 "False - rate for true D"
	local st7 "False + rate for classified +"
	local st8 "False - rate for classified -"

	local pr1 "Pr( +| D)"
	local pr2 "Pr( -|~D)"
	local pr3 "Pr( D| +)"
	local pr4 "Pr(~D| -)"
	local pr5 "Pr( +|~D)"
	local pr6 "Pr( -| D)"
	local pr7 "Pr(~D| +)"
	local pr8 "Pr( D| -)"

	forvalues s = 1/8 {

		local v = el(`S', `pos', `s')

		display "{txt}`st`s''{col 33}`pr`s''{col 43}{res}{ralign 8:`=cond(missing(`v'), ".", string(`v', "%6.2f") + "%")'}"

		if ((`s' == 4) | (`s' == 8)) display "{txt}{hline 50}"

	}

	local f1 = el(`S', `pos', 9)

	display "{txt}F1 score{col 43}{res}{ralign 8:`=cond(missing(`f1'), ".", string(`f1', "%6.2f") + "%")'}"

	display "{txt}Correctly classified{col 43}{res}{ralign 8:`=string(`acc', "%6.2f")'%}"

	display "{txt}{hline 50}"

}


return scalar N = `N'

return scalar N_correct = `K'

return scalar pct_correct = 100*`K'/`N'

return scalar risk = 1 - `K'/`N'

return matrix class = `C'

matrix colnames `S' = sensitivity specificity ppv npv fpos_true fneg_true fpos_class fneg_class f1

return scalar f1_macro = `f1m'

return scalar f1_weighted = `f1w'

return matrix stats = `S'												//rows: categories of the table; percentages

return local depvar "`depvar'"

end

//one line per cluster: number, size and the categories that define it
program mchaid_clusterlist

tempname sizes

matrix `sizes' = e(sizes)

display _newline "{res}Node definitions" _newline "{txt}{hline 80}"

forvalues x = 1/`=e(N_clusters)' {

	mchaid_pathtext `"`e(path`x')'"'

	local size = `sizes'[1, `x']

	display `"{p 2 8 2}{txt}Node {res}`x'{txt} (n = {res}`size'{txt}): {res}`r(text)'{p_end}"'

}

end

//results of the cluster analysis returned in r(): labels and frequencies of the clusters, cross-tabulation of the response by cluster and tests of association
program mchaid_results, rclass

capture confirm variable _CHAID

if (_rc) {

	display "{err}Variable {cmd:_CHAID} is not in the data: the node results cannot be computed."

	exit 111

}

local k = e(N_clusters)

local wt ""

if ("`e(wtype)'" != "") local wt "[`e(wtype)' `e(wexp)']"

tempname F R C freq rowpct colpct clusfreq dvfreq

quietly tabulate `e(depvar)' _CHAID if e(sample) `wt', matcell(`F') matrow(`R') matcol(`C') `e(missing)'

local nlev = rowsof(`R')

local rnames ""

forvalues x = 1/`k' {

	local rnames "`rnames' `=`C'[1, `x']'"

}

local cnames ""

local dvlevels ""

local dvlabels ""

local vallab : value label `e(depvar)'

forvalues j = 1/`nlev' {

	local lev = `R'[`j', 1]

	if (missing(`lev')) {

		local cnames "`cnames' missing"

		local dvlevels "`dvlevels' ."

		local dvlabels `"`dvlabels' "missing""'

	}

	else {

		local cnames "`cnames' `lev'"

		local dvlevels "`dvlevels' `lev'"

		if ("`vallab'" != "") local text : label `vallab' `lev'

		else local text "`lev'"

		local dvlabels `"`dvlabels' "`text'""'

	}

}

matrix `freq' = `F''

matrix rownames `freq' = `rnames'

matrix colnames `freq' = `cnames'

mata: F = st_matrix("`freq'"); st_matrix("`rowpct'", 100*F:/rowsum(F)); st_matrix("`colpct'", 100*F:/colsum(F)); st_matrix("`clusfreq'", rowsum(F)); st_matrix("`dvfreq'", colsum(F))

matrix rownames `rowpct' = `rnames'

matrix colnames `rowpct' = `cnames'

matrix rownames `colpct' = `rnames'

matrix colnames `colpct' = `cnames'

matrix rownames `clusfreq' = `rnames'

matrix colnames `clusfreq' = frequency

matrix rownames `dvfreq' = frequency

matrix colnames `dvfreq' = `cnames'

local labels ""

forvalues x = 1/`k' {

	mchaid_pathtext `"`e(path`x')'"'

	return local label`x' `"`x': `r(text)'"'

	local labels `"`labels' "`x': `r(text)'""'

}

capture quietly tabulate `e(depvar)' _CHAID if e(sample) `wt', chi2 lrchi2 V `e(missing)'

if (!_rc) {

	return scalar chi2 = r(chi2)

	return scalar p = r(p)

	return scalar chi2_lr = r(chi2_lr)

	return scalar p_lr = r(p_lr)

	return scalar CramersV = r(CramersV)

}

return scalar df = (`k' - 1)*(`nlev' - 1)

return scalar N = e(N)

return scalar N_clusters = `k'

return scalar N_dv = `nlev'

return local depvar "`e(depvar)'"

return local dvlevels = trim("`dvlevels'")

return local dvlabels `"`dvlabels'"'

return local labels `"`labels'"'

return matrix freq = `freq'

return matrix rowpct = `rowpct'

return matrix colpct = `colpct'

return matrix clusfreq = `clusfreq'

return matrix dvfreq = `dvfreq'

end
//table of the response variable by cluster: clusters in rows, categories of the response in columns, frequencies and row percentages; tests of association
program mchaid_dvtable

capture confirm variable _CHAID

if (_rc) {

	display _newline "{txt}Variable {cmd:_CHAID} is not in the data: the table of {cmd:`e(depvar)'} by node cannot be shown."

	exit 0

}

tempvar clus dvc

quietly clonevar `clus' = _CHAID

label variable `clus' "Node"

quietly clonevar `dvc' = `e(depvar)'

label variable `dvc' "`e(depvar)'"

local wt ""

if ("`e(wtype)'" != "") local wt "[`e(wtype)' `e(wexp)']"

mchaid_results

local N = r(N)

local df = r(df)

local chi2 = r(chi2)

local p = r(p)

local chi2lr = r(chi2_lr)

local plr = r(p_lr)

local V = r(CramersV)

mata: st_local("rk", strofreal(1 - (st_matrix("e(sizes)")*rowmax(st_matrix("r(rowpct)"))/100)/sum(st_matrix("e(sizes)"))))	//risk estimate, as in the graph

mata: st_local("rk0", strofreal(1 - max(st_matrix("e(sizes)")*st_matrix("r(rowpct)")/100)/sum(st_matrix("e(sizes)"))))		//risk of the root node

display _newline "{res}`e(depvar)' by CHAID node" _newline "{txt}{hline 80}"

if (0`c(stata_version)' >= 17) {

	version 17

	preserve

	quietly keep if e(sample)

	if ("`e(wtype)'" != "") quietly expand `=trim(subinstr(`"`e(wexp)'"', "=", "", 1))'

	quietly table (`clus') (`dvc'), statistic(frequency) statistic(percent, across(`dvc')) totals(`clus' `dvc') `e(missing)' name(mchaid_tab) replace

	quietly levelsof `dvc', local(dvlevels) `e(missing)'

	collect style header result, level(hide)

	collect style header `clus', title(hide)

	collect style cell result[percent], nformat(%9.1f)

	collect style cell result[frequency], nformat(%9.0fc) sformat("(%s)")

	collect label levels `clus' .m "Total (N = `=string(`N', "%12.0fc")')", modify

	display "{txt}Row percentages; frequencies in parentheses in the column Total"

	quietly collect layout (`clus') (`dvc'[`dvlevels']#result[percent] `dvc'[.m]#result[frequency])

	collect preview

	restore

}

else tabulate `dvc' `clus' if e(sample) `wt', row `e(missing)'

display _newline "{txt}Risk estimate = {res}" %5.3f `rk' "{txt} (root node: {res}" %5.3f `rk0' "{txt})"

display _newline "{txt}Tests of association between {cmd:`e(depvar)'} and node (N = {res}`N'{txt})"

display "{txt}  Pearson chi2({res}`df'{txt}) = {res}" %9.2f `chi2' "{txt}   Pr = {res}" cond(`p' < .0001, "<0.0001", string(`p', "%6.4f"))

display "{txt}  Likelihood-ratio chi2({res}`df'{txt}) = {res}" %9.2f `chi2lr' "{txt}   Pr = {res}" cond(`plr' < .0001, "<0.0001", string(`plr', "%6.4f"))

display "{txt}  Cram{c e'}r's V = {res}" %6.3f `V'

display "{txt}  Empty cells of the table are zero."

display "{txt}  Note: the nodes were chosen to be associated with {cmd:`e(depvar)'}, so these tests describe the strength of the association but are not valid for inference."

end
/*Mata functions to lay out the tree graph*/
version 12.1

mata:

mata set matastrict on

//number of characters of a text (UTF-8 continuation bytes are not counted, so accents and other non-ASCII characters count once)
real scalar mchaid_len(string scalar txt)
{
	real rowvector b
	
	if (strlen(txt) == 0) return(0)
	
	b = ascii(txt)
	
	return(strlen(txt) - sum((b :>= 128) :& (b :< 192)))
}

//split a text into lines of at most "width" characters
string rowvector mchaid_wrap(string scalar txt, real scalar width)
{
	string rowvector words, out
	
	string scalar cur
	
	real scalar i
	
	words = tokens(subinstr(txt, char(34), "'"))
	
	out = J(1, 0, "")
	
	cur = ""
	
	for (i = 1; i <= cols(words); i++) {
	
		if (strlen(cur) == 0) cur = words[i]
		
		else if (mchaid_len(cur) + 1 + mchaid_len(words[i]) > width) {
		
			out = (out, cur)
			
			cur = words[i]
		
		}
		
		else cur = cur + " " + words[i]
	
	}
	
	if (strlen(cur) > 0) out = (out, cur)
	
	if (cols(out) == 0) out = ("")
	
	return(out)
}

//text() option of twoway with a box (or without it) at (y, x)
string scalar mchaid_text(real scalar y, real scalar x, string rowvector lines, string scalar opts)
{
	string scalar res
	
	real scalar i
	
	res = "text(" + strofreal(y, "%12.6f") + " " + strofreal(x, "%12.6f")
	
	for (i = 1; i <= cols(lines); i++) res = res + " " + char(34) + lines[i] + char(34)
	
	return(res + ", " + opts + ")")
}

//levels (in order, "missing" for the missing category) of an ordered splitting variable, or "" when the variable is not ordered
//while the algorithm runs they are in the locals of the estimation; afterwards in e(ordered) and e(ordlev#)
string scalar mchaid_ordlev(string scalar var)
{
	string rowvector ov, lg

	string scalar out

	real scalar i, j

	if (st_local("mchaid_estimating") == "1") {

		if (!any(tokens(st_local("ordered")) :== var)) return("")

		lg = tokens(st_local(var + "levs"))

		out = ""

		for (j = 1; j <= cols(lg); j++) out = out + " " + (lg[j] == "." ? "missing" : lg[j])

		return(strtrim(out))

	}

	ov = tokens(st_global("e(ordered)"))

	for (i = 1; i <= cols(ov); i++) if (ov[i] == var) return(st_global("e(ordlev" + strofreal(i) + ")"))

	return("")
}

//labels of the levels of a splitting variable (value labels when the variable has them)
//in an ordered variable, three or more adjacent categories are written as first-last (first~last when they have value labels)
string scalar mchaid_levlab(string scalar var, string scalar levels)
{
	string rowvector lv, lg, txt, items

	string scalar vl, out, lab

	real rowvector pos, isnum, idx, rest, hit

	real scalar j, n, k, m, en, r

	lv = tokens(levels)

	n = cols(lv)

	vl = ""

	if (_st_varindex(var) != .) vl = st_varvaluelabel(var)

	txt = lv
	
	if (st_local("t_missing") != "") for (j = 1; j <= n; j++) if (lv[j] == "missing") txt[j] = st_local("t_missing")				//the floating missing category, in the language of the graph

	isnum = J(1, n, 1)

	for (j = 1; j <= n; j++) {

		if ((vl != "") & (lv[j] != "missing")) {

			lab = st_vlmap(vl, strtoreal(lv[j]))

			if (lab != "") {

				txt[j] = lab

				isnum[j] = 0

			}

		}

	}

	lg = J(1, 0, "")

	if (n >= 3) lg = tokens(mchaid_ordlev(var))

	items = J(1, 0, "")

	if (cols(lg) == 0) items = txt

	else {

		pos = J(1, n, 0)

		for (j = 1; j <= n; j++) {

			if (lv[j] == "missing") continue																//the floating missing category is never part of a run: it goes last, on its own

			hit = select(1..cols(lg), lg :== lv[j])

			if (cols(hit) > 0) pos[j] = hit[1]

		}

		idx = order(pos', 1)'

		idx = select(idx, pos[idx] :> 0)

		rest = select(1..n, pos :== 0)

		m = cols(idx)

		k = 1

		while (k <= m) {

			en = k

			while (en < m) {																				//Mata does not short-circuit "&": idx[en + 1] must not be read when en == m

				if (pos[idx[en + 1]] != pos[idx[en]] + 1) break

				en++

			}

			if (en - k + 1 >= 3) items = items, (txt[idx[k]] + (isnum[idx[k]] & isnum[idx[en]] ? "-" : "~") + txt[idx[en]])

			else for (r = k; r <= en; r++) items = items, txt[idx[r]]

			k = en + 1

		}

		for (r = 1; r <= cols(rest); r++) items = items, txt[rest[r]]

	}

	out = ""

	for (j = 1; j <= cols(items); j++) out = out + (j > 1 ? ", " : "") + items[j]

	return(out)
}

//output of the option steps: a line of text shown even when the algorithm runs quietly
void mchaid_say(string scalar msg)
{
	st_local("mchaid_msg", subinstr(msg, char(34), char(39)))

	stata("noisily display as text " + char(34) + char(96) + "mchaid_msg" + char(39) + char(34))
}

//p-value for the steps
string scalar mchaid_pfmt(real scalar p)
{
	if (p >= .) return(".")

	if (p < .0001) return("<0.0001")

	return(strofreal(p, "%6.4f"))
}

//splits a text of options into its tokens (name or name(arguments)), keeping together what is between parentheses and quotes
string rowvector mchaid_splitopts(string scalar s)
{
	string rowvector out
	string scalar cur, c
	real scalar i, depth, inq
	out = J(1, 0, "")
	cur = ""
	depth = 0
	inq = 0
	for (i = 1; i <= strlen(s); i++) {
		c = substr(s, i, 1)
		if (c == char(34)) inq = !inq
		if (!inq) {
			if (c == "(") depth++
			else if (c == ")") depth--
		}
		if ((c == " ") & (depth == 0) & !inq) {
			if (strlen(cur)) out = (out, cur)
			cur = ""
		}
		else cur = cur + c
	}
	if (strlen(cur)) out = (out, cur)
	return(out)
}
//name of an option of the graph (the abbreviation typed is completed)
string scalar mchaid_optname(string scalar tok)
{
	string rowvector canon
	real rowvector mn
	string scalar n
	real scalar j
	canon = ("treestyle", "nodeplot", "center", "whisker", "noshade", "nodehead", "rootlabel", "colors", "digits", "language", "directory", "collapse", "noopen", "maxdots", "pcut", "nopval", "nopct", "quartiles", "title", "name", "saving", "scheme", "htmlonly")
	mn = (4, 5, 4, 5, 4, 5, 5, 3, 3, 4, 3, 4, 4, 4, 4, 4, 4, 4, 2, 4, 3, 3, 8)
	n = strlower(strtrim(strpos(tok, "(") ? substr(tok, 1, strpos(tok, "(") - 1) : tok))
	for (j = 1; j <= cols(canon); j++) if ((strlen(n) >= mn[j]) & (substr(canon[j], 1, strlen(n)) == n)) return(canon[j])
	return(n)
}
//options of the graph in the replay: those stored in e(graphopts) that are not typed again, then the typed ones; directory(), collapse() and noopen are not reused (the page is written only when it is asked for)
string scalar mchaid_mergeopts(string scalar stored, string scalar typed)
{
	string rowvector ts, tt, tn
	string scalar out, n
	real scalar i
	ts = mchaid_splitopts(stored)
	tt = mchaid_splitopts(typed)
	tn = J(1, 0, "")
	for (i = 1; i <= cols(tt); i++) tn = (tn, mchaid_optname(tt[i]))
	out = ""
	for (i = 1; i <= cols(ts); i++) {
		n = mchaid_optname(ts[i])
		if ((n == "directory") | (n == "collapse") | (n == "noopen") | (n == "htmlonly")) continue
		if (sum(tn :== n)) continue
		out = out + " " + ts[i]
	}
	return(strtrim(out + " " + strtrim(typed)))
}
//flows the widths w of the items of the legend into rows no wider than maxw (gap gp between items): the row of each item
real colvector mchaid_legflow(real colvector w, real scalar gp, real scalar maxw)
{
	real colvector r
	real scalar i, cw, row
	r = J(rows(w), 1, 1)
	cw = 0
	row = 1
	for (i = 1; i <= rows(w); i++) {
		if ((cw > 0) & (cw + gp + w[i] > maxw)) {
			row++
			cw = 0
		}
		cw = cw + (cw > 0 ? gp : 0) + w[i]
		r[i] = row
	}
	return(r)
}
//rows of the legend, as in the R package: no wider than maxw, 3 at most (the width grows if need be) and balanced (the narrowest width that keeps the number of rows)
real colvector mchaid_legrows(real colvector w, real scalar gp, real scalar maxw)
{
	real colvector r, r2
	real scalar widest, nr
	widest = max(w)
	maxw = max((maxw, widest))
	r = mchaid_legflow(w, gp, maxw)
	while ((max(r) > 3) & (maxw < 100)) {
		maxw = maxw*1.1
		r = mchaid_legflow(w, gp, maxw)
	}
	nr = max(r)
	while (maxw - 0.05 > widest) {
		r2 = mchaid_legflow(w, gp, maxw - 0.05)
		if (max(r2) != nr) break
		maxw = maxw - 0.05
		r = r2
	}
	return(r)
}
//p-value of a split for the graph: three decimals, or p<0.001 (as in the style of boxes)
string scalar mchaid_ptxt(real scalar p, real scalar cut, string scalar cuttxt)
{
	real scalar e, m

	if (p >= .) return("")

	if ((cut < .) & (p < cut)) return("p<" + cuttxt)												//p-values below the cut given by the user (pcut) are written as p<cut

	if (p >= .001) return("p=" + strofreal(p, "%5.3f"))

	return("p<0.001")
}

//classification table of estat classification: each case is classified in the modal category of its node
//F = cases of each node (rows) by category of the response variable (columns); C = real category (rows) by assigned category (columns)
//S = statistics of each category versus the rest (rows): sensitivity, specificity, positive and negative predictive values, their complements and F1 (%)
void mchaid_class(string scalar Fn, string scalar Cn, string scalar Rn, string scalar Tn, string scalar Pn, string scalar Nn, string scalar Kn, string scalar Sn)
{
	real matrix F, C, S
	
	real rowvector p
	
	real scalar i, L, n, tp, fn, fp, tn
	
	F = st_matrix(Fn)
	
	L = cols(F)
	
	C = J(L, L, 0)
	
	for (i = 1; i <= rows(F); i++) {
	
		p = select(1..L, F[i, .]:== max(F[i, .]))																//categories with the highest count: the first one is used when there is a tie
		
		C[., p[1]] = C[., p[1]] + F[i, .]'
	
	}
	
	n = sum(C)
	
	S = J(L, 9, .)
	
	for (i = 1; i <= L; i++) {
	
		tp = C[i, i]
		
		fn = sum(C[i, .]) - tp
		
		fp = sum(C[., i]) - tp
		
		tn = n - tp - fn - fp
		
		S[i, .] = 100*(tp/(tp + fn), tn/(tn + fp), tp/(tp + fp), tn/(tn + fn), fp/(fp + tn), fn/(tp + fn), fp/(tp + fp), fn/(tn + fn), 2*tp/(2*tp + fp + fn))
	
	}
	
	st_matrix(Cn, C)
	
	st_matrix(Rn, rowsum(C))
	
	st_matrix(Tn, colsum(C))
	
	st_matrix(Pn, 100*diagonal(C):/rowsum(C))
	
	st_matrix(Sn, S)
	
	st_numscalar(Nn, n)
	
	st_numscalar(Kn, trace(C))
}

//name of the splitting variable of a group of binary variables (their labels are "variable @ level")
string scalar mchaid_varof(string scalar grp)
{
	string rowvector tk

	string scalar lab

	tk = tokens(grp)

	if (cols(tk) == 0) return("")

	lab = st_varlabel(st_local(tk[1]))

	if (strpos(lab, "@") == 0) return("")

	return(strtrim(substr(lab, 1, strpos(lab, "@") - 1)))
}

//text of a group of categories of a splitting variable: "{uno, dos}" or "uno", with the name of the variable ("a in {uno, dos}", "a = uno") when withvar = 1
string scalar mchaid_grptext(string scalar grp, real scalar withvar)
{
	string rowvector tk

	string scalar lab, var, levs, txt

	real scalar j, p, n

	tk = tokens(grp)

	var = ""

	levs = ""

	for (j = 1; j <= cols(tk); j++) {

		lab = st_varlabel(st_local(tk[j]))

		p = strpos(lab, "@")

		if (p == 0) continue

		var = strtrim(substr(lab, 1, p - 1))

		levs = levs + " " + strtrim(substr(lab, p + 1, .))

	}

	levs = strtrim(levs)

	if (levs == "") return("")

	txt = mchaid_levlab(var, levs)

	n = cols(tokens(levs))

	if (n > 1) txt = "{" + txt + "}"

	if (withvar) txt = var + (n > 1 ? " in " : " = ") + txt

	return(txt)
}

//list of the groups of categories of a splitting variable
string scalar mchaid_catlist(string rowvector sn, string scalar sep)
{
	string scalar out

	real scalar j

	out = ""

	for (j = 1; j <= cols(sn); j++) out = out + (j > 1 ? sep : "") + mchaid_grptext(sn[j], 0)

	return(out)
}

//definition of a node from its splits
string scalar mchaid_path(string rowvector sp, real scalar nb)
{
	string scalar out

	real scalar d

	out = ""

	for (d = 1; d <= nb; d++) out = out + (d > 1 ? " & " : "") + mchaid_grptext(sp[d], 1)

	if (out == "") out = "all observations"

	return(out)
}

//test statistic of a split in the classic graph, written before its p-value: "chi2=2131; " (F with svy)
string scalar mchaid_cstat(real matrix sk, real scalar m1, real scalar du)
{
	real scalar x
	if ((rows(sk) < m1) | (cols(sk) < du)) return("")
	x = sk[m1, du]
	if (x >= .) return("")
	return((st_global("e(splitstat)") == "F" ? "F" : st_local("t_chi")) + "=" + strofreal(x, (x >= 100 ? "%12.0f" : (x >= 10 ? "%9.1f" : "%9.2f"))) + "; ")
}
//size in the units of the graph (inches) of a text of a given height and number of characters
real scalar mchaid_tw(real scalar h, real scalar nchar)
{
	return(0.52*h*nchar)
}
//removes the compound quotes that wrap a string passed with the option asis
string scalar mchaid_unwrap(string scalar s)
{
	s = strtrim(s)
	if (strlen(s) >= 4) {
		if (substr(s, 1, 2) == char(96) + char(34) & substr(s, strlen(s) - 1, 2) == char(34) + char(39)) s = strtrim(substr(s, 3, strlen(s) - 4))
	}
	return(s)
}
//colors(): splits the text into colours, each one either alone or as name=colour (names and colours with spaces go in double quotes), and
//leaves in locals of the calling program: ncs and cs1... (the colours, as typed), cerr (an error message, if any) and, if nlev > 0, cj1...
//(the colour of each category: by name, or in order if there are no names), cextra, cunk (names that are not categories) and cmis (categories
//without colour). labs are the labels of the categories, in quotes
void mchaid_cparse(string scalar spec, string scalar labs, real scalar nlev)
{
	string rowvector t, lab, nm, cl, sq, cs, out, ro
	real rowvector iseq
	real scalar i, j, k, n, p, inq
	string scalar dq, unk, mis, msg, cramp, ch
	dq = char(34)
	msg = "colors() must be a list of colours, or of name=colour (names and colours with spaces in double quotes)"
	spec = mchaid_unwrap(spec)
	labs = mchaid_unwrap(labs)
	cramp = ""
	p = 0
	inq = 0
	for (i = 1; i <= strlen(spec); i++) {									//a comma outside quotes: colors(colour, ramp [reverse])
		ch = substr(spec, i, 1)
		if (ch == dq) inq = !inq
		else if (ch == "," & !inq) {
			p = i
			break
		}
	}
	if (p > 0) {
		ro = tokens(strlower(substr(spec, p + 1, .)))
		spec = strtrim(substr(spec, 1, p - 1))
		if (length(ro) == 0 | length(ro) > 2) {
			st_local("cerr", "colors(): after the comma only ramp or ramp reverse is allowed")
			return
		}
		if (ro[1] != "ramp" | (length(ro) == 2 ? ro[2] != "reverse" : 0)) {
			st_local("cerr", "colors(): after the comma only ramp or ramp reverse is allowed")
			return
		}
		cramp = (length(ro) == 2 ? "2" : "1")
	}
	t = tokens(spec, " =")
	n = length(t)
	iseq = (t :== "=")
	for (i = 1; i <= n; i++) {
		if (!iseq[i] & strlen(t[i]) >= 2) {
			if (substr(t[i], 1, 1) == dq & substr(t[i], strlen(t[i]), 1) == dq) t[i] = substr(t[i], 2, strlen(t[i]) - 2)
		}
	}
	nm = J(1, 0, ""); cl = J(1, 0, ""); sq = J(1, 0, "")
	i = 1
	while (i <= n) {
		if (iseq[i]) {
			st_local("cerr", msg)
			return
		}
		if (i < n) {
			if (iseq[i + 1]) {
				if ((i + 2 > n) ? 1 : iseq[i + 2]) {
					st_local("cerr", msg)
					return
				}
				nm = nm, t[i]
				cl = cl, t[i + 2]
				i = i + 3
				continue
			}
		}
		sq = sq, t[i]
		i++
	}
	if (length(nm) + length(sq) == 0) {
		st_local("cerr", msg)
		return
	}
	if (length(nm) > 0 & length(sq) > 0) {
		st_local("cerr", "colors() cannot mix name=colour with colours without name")
		return
	}
	cs = (length(nm) > 0 ? cl : sq)
	if (cramp != "") {														//ramp: one single colour
		if (length(nm) > 0 | length(sq) != 1) {
			st_local("cerr", "colors(): ramp needs one single colour, as in colors(green, ramp)")
			return
		}
		st_local("cramp", cramp)
	}
	st_local("ncs", strofreal(length(cs)))
	for (k = 1; k <= length(cs); k++) st_local("cs" + strofreal(k), cs[k])
	if (cramp != "") return
	if (nlev <= 0) return
	lab = tokens(labs)
	for (i = 1; i <= length(lab); i++) {
		if (strlen(lab[i]) >= 2) {
			if (substr(lab[i], 1, 1) == dq & substr(lab[i], strlen(lab[i]), 1) == dq) lab[i] = substr(lab[i], 2, strlen(lab[i]) - 2)
		}
	}
	if (length(sq) > 0) {																					//one colour for each category, in order
		if (length(sq) < nlev) {
			st_local("cerr", "colors() has " + strofreal(length(sq)) + " colour(s) for " + strofreal(nlev) + " categories: give one for each, or name them with name=colour")
			return
		}
		if (length(sq) > nlev) st_local("cextra", "1")
		for (j = 1; j <= nlev; j++) st_local("cj" + strofreal(j), sq[j])
		return
	}
	out = J(1, nlev, "")
	unk = ""
	for (k = 1; k <= length(nm); k++) {
		j = 0
		for (i = 1; i <= min((nlev, length(lab))); i++) {
			if (strlower(strtrim(lab[i])) == strlower(strtrim(nm[k]))) {
				j = i
				break
			}
		}
		if (j == 0) {
			unk = unk + (unk == "" ? "" : ", ") + nm[k]
			continue
		}
		if (out[j] != "") {
			st_local("cerr", "colors(): the category " + lab[j] + " has two colours")
			return
		}
		out[j] = cl[k]
	}
	mis = ""
	for (j = 1; j <= nlev; j++) {
		st_local("cj" + strofreal(j), out[j])
		if (out[j] == "") mis = mis + (mis == "" ? "" : ", ") + (j <= length(lab) ? lab[j] : strofreal(j))
	}
	st_local("cunk", unk)
	st_local("cmis", mis)
}
//1 if the split of level j of the path of cluster i was made by a variable chosen with forcevars() (matrix e(splitforced))
real scalar mchaid_isf(real matrix sf, real scalar i, real scalar j)
{
	if ((i > rows(sf)) | (j > cols(sf))) return(0)
	return(sf[i, j] == 1)
}
//a text cut (with ...) so that, written with height h, it takes at most mw inches; whole UTF-8 characters are removed
string scalar mchaid_cut(string scalar t, real scalar h, real scalar mw)
{
	real rowvector b
	while ((mchaid_len(t) > 1) & (mchaid_tw(h, mchaid_len(t) + 3) > mw)) {
		t = substr(t, 1, strlen(t) - 1)
		while (strlen(t) > 0) {
			b = ascii(substr(t, strlen(t), 1))
			if (b[1] >= 128) t = substr(t, 1, strlen(t) - 1)
			else break
		}
	}
	return(t + "...")
}
//heading of a box that has to fit in mw inches (bold): (kind of text, line) with a smaller letter, or (kind, line 1, line 2) in two lines, or cut; the kinds 1, 41, 42, 43, 44 are the sizes 0.165, 0.15, 0.138, 0.126, 0.12
string rowvector mchaid_fithead(string scalar s, real scalar mw)
{
	real rowvector hs, kd
	real scalar i, j, bi, bm, m
	string rowvector words
	string scalar a, b2
	hs = (0.165, 0.15, 0.138, 0.126, 0.12)
	kd = (1, 41, 42, 43, 44)
	for (i = 1; i <= 4; i++) if (mchaid_tw(hs[i], 1.08*mchaid_len(s)) <= mw) return((strofreal(kd[i]), s))
	words = tokens(subinstr(s, char(34), "'"))
	if (cols(words) > 1) {
		bi = 1
		bm = 1e100
		for (j = 1; j < cols(words); j++) {
			m = max((mchaid_len(invtokens(words[1..j])), mchaid_len(invtokens(words[(j + 1)..cols(words)]))))
			if (m < bm) {
				bm = m
				bi = j
			}
		}
		a = invtokens(words[1..bi])
		b2 = invtokens(words[(bi + 1)..cols(words)])
		for (i = 4; i <= 5; i++) if (mchaid_tw(hs[i], 1.08*max((mchaid_len(a), mchaid_len(b2)))) <= mw) return((strofreal(kd[i]), a, b2))
		if (mchaid_tw(hs[5], 1.08*mchaid_len(a)) > mw) a = mchaid_cut(a, 1.08*hs[5], mw)
		if (mchaid_tw(hs[5], 1.08*mchaid_len(b2)) > mw) b2 = mchaid_cut(b2, 1.08*hs[5], mw)
		return((strofreal(kd[5]), a, b2))
	}
	return((strofreal(kd[5]), mchaid_cut(s, 1.08*hs[5], mw)))
}

//heading of a box of the classic graph (letter not bold) that has to fit in mw inches: (size, line) with a smaller letter, (size, line 1, line 2) in two lines, or cut
string rowvector mchaid_fitcl(string scalar s, real scalar mw)
{
	real scalar z, j, bi, bm, m
	string rowvector words
	string scalar a, b2
	for (z = 0.17; z >= 0.1249; z = z - 0.005) if (mchaid_tw(z, mchaid_len(s)) <= mw) return((strtrim(strofreal(z, "%9.3f")), s))
	words = tokens(subinstr(s, char(34), "'"))
	if (cols(words) > 1) {
		bi = 1
		bm = 1e100
		for (j = 1; j < cols(words); j++) {
			m = max((mchaid_len(invtokens(words[1..j])), mchaid_len(invtokens(words[(j + 1)..cols(words)]))))
			if (m < bm) {
				bm = m
				bi = j
			}
		}
		a = invtokens(words[1..bi])
		b2 = invtokens(words[(bi + 1)..cols(words)])
		for (z = 0.14; z >= 0.1199; z = z - 0.01) if (mchaid_tw(z, max((mchaid_len(a), mchaid_len(b2)))) <= mw) return((strtrim(strofreal(z, "%9.3f")), a, b2))
		if (mchaid_tw(0.12, mchaid_len(a)) > mw) a = mchaid_cut(a, 0.12, mw)
		if (mchaid_tw(0.12, mchaid_len(b2)) > mw) b2 = mchaid_cut(b2, 0.12, mw)
		return(("0.120", a, b2))
	}
	return(("0.120", mchaid_cut(s, 0.12, mw)))
}
//width in inches of the widest line of a heading given by mchaid_fitcl()
real scalar mchaid_headw(string rowvector fh)
{
	real scalar j, m
	m = 0
	for (j = 2; j <= cols(fh); j++) m = max((m, mchaid_len(fh[j])))
	return(mchaid_tw(strtoreal(fh[1]), m))
}
//texts of a box of the classic graph: the heading (one or two lines) and, under it, "n = N"; top is the top of the box
string scalar mchaid_nodetext(real scalar top, real scalar x, string rowvector fh, string scalar nline, real scalar fnn, real scalar msz)
{
	string scalar o, on
	o = "placement(c) size(" + strofreal(100*strtoreal(fh[1])/msz, "%9.3f") + ")"
	on = "placement(c) size(" + strofreal(100*fnn/msz, "%9.3f") + ")"
	if (cols(fh) == 2) return(mchaid_text(top - 0.175, x, (fh[2]), o) + " " + mchaid_text(top - 0.355, x, (nline), on))
	return(mchaid_text(top - 0.16, x, (fh[2], fh[3]), o) + " " + mchaid_text(top - 0.385, x, (nline), on))
}
//texts of the block over a branch of the classic graph: the splitting variable and, under it, its test (only the variable with nopval); btop is the top of the block
string scalar mchaid_blocktext(real scalar btop, real scalar x, string scalar sv, string scalar stxt, real scalar showp, real scalar bh, real scalar fn, real scalar fz, real scalar msz)
{
	string scalar s
	if (!showp) return(mchaid_text(btop - bh/2, x, (sv), "placement(c) size(" + strofreal(100*fn/msz, "%9.3f") + ")"))
	s = mchaid_text(btop - 0.095, x, (sv), "placement(c) size(" + strofreal(100*fn/msz, "%9.3f") + ")")
	if (stxt != "") s = s + " " + mchaid_text(btop - 0.265, x, (stxt), "placement(c) size(" + strofreal(100*fz/msz, "%9.3f") + ")")
	return(s)
}

//coordinates of the tree in inches: edges and boxes (E), stacked bars of the response in the nodes (B), squares of the legend (L) and the texts (local textopts)
void mchaid_tree(string scalar Ename, string scalar Bname, string scalar Lname, string scalar Mname, string scalar rpname, string scalar ttl, string scalar Wname)
{
	real scalar showp, gapu, rk, rk0, cv, wl, wn, k, i, d, j, D, du, nn, u, xs, ys, msz, dx, dy, hbox, barh, gapbar, topm, botm, x0, py, px, nx, ny, ymid, cum, pc, m1, isleaf, cl, nlev, ybt, ybb, wbox, ytot, xleg, yleg, wj, total, fn, fnn, fe, fp, fl, ft, fz, mx, ordr, quar, legw, wmed, wq, ym, gp, lt, r, jq, nq, bh, btop, bwid, mwh
	
	real matrix sizes, rp, E, B, L, M, W, sp, skc, labs

	real colvector b, xl, ord, members, cx, cy, nlu, lv, yd, yq
	
	string matrix P, Pk
	
	string colvector nodes, allkeys, fullkeys, pdone, paru

	string rowvector tk, lines, dvl, fh
	
	string scalar lefttxt, key, parkey, svar, elab, opts, textopts, path, nm, nline, note, medtxt, svp, stxt
	real matrix sf
	
	transmorphic t
	
	k = st_numscalar("e(N_clusters)")
	
	sizes = st_matrix("e(sizes)")

	sp = st_matrix("e(splitp)")																				//adjusted p-values of the splits
	sf = st_matrix("e(splitforced)")											//1 where the variable of the split was chosen with forcevars()
	skc = st_matrix("e(splitchi)")												//test statistics of the splits

	pdone = J(0, 1, "")																						//parents whose p-value is already in the graph

	rp = st_matrix(rpname)
	
	nlev = cols(rp)
	
	dvl = tokens(st_local("dvlabels"))
	
	if ((subinstr(dvl[nlev], char(34), "") == "missing") & (st_global("e(missing)") == "missing") & (st_local("t_missing") != "")) dvl[nlev] = st_local("t_missing")		//the missing category of the response variable, in the language of the graph
	
	P = J(k, 0, "")
	
	b = J(k, 1, 0)
	
	t = tokeninit(";", "", "")
	
	for (i = 1; i <= k; i++) {
	
		tokenset(t, st_global("e(path" + strofreal(i) + ")"))
		
		tk = tokengetall(t)
		
		b[i] = cols(tk)
		
		if (cols(tk) > cols(P)) P = (P, J(k, cols(tk) - cols(P), ""))
		
		P[i, 1..cols(tk)] = tk
	
	}
	
	D = max(b)
	
	showp = (st_local("pval") != "nopval")																	//p-value of each split on the graph (more vertical space to fit it above the labels of the branches)

	dx = 1.15																							//horizontal space of a final node (inches)
	
	dy = showp ? 1.6 : 1.45																								//vertical space of a level
	
	hbox = 0.50																								//height of the boxes
	
	barh = 1.1																								//height of the bars
	
	gapbar = 0.12

	bh = showp ? 0.3556 : 0.22																				//height of the white block over each branch (the splitting variable and its test; only the variable with nopval)

	mwh = 1.05 - 0.14																						//widest text of the heading of a box (inches)
	
	topm = 0.65																								//space for the title
	
	botm = 0.85																								//space for the legend and the note
	
	xs = max((6, k*dx + 0.8))

	rk = 1 - (sizes*rowmax(rp)/100)/sum(sizes)																//risk estimate: proportion of misclassified cases when each node is assigned its modal category

	cv = abs(strtoreal(st_local("cramv")))

	rk0 = 1 - max(sizes*rp/100)/sum(sizes)																	//risk of the root node: its modal category is the most frequent one in the whole sample

	lefttxt = st_local("t_risk") + " = " + strofreal(rk, "%5.3f") + " (" + st_local("t_root") + ": " + strofreal(rk0, "%5.3f") + ")"

	if (cv < .) lefttxt = lefttxt + "    " + st_local("t_cramer") + " = " + strofreal(cv, "%5.3f")

	note = st_local("t_note")
	if (sum(sf) > 0) note = note + "; " + st_local("t_dagger") + " " + st_local("t_forced")			//the mark of the forced variables is explained in the note

	wl = mchaid_tw(0.12, mchaid_len(lefttxt))

	wn = mchaid_tw(0.12, mchaid_len(note))

	xs = max((xs, wl + wn + 0.9))																				//the last line has room for the two texts

	fl = 0.15																								//height of the text of the legend

	ordr = (st_global("e(dvordered)") == "dvordered") & (st_local("quartiles") != "")														//ordered response and option quartiles(): median (the second quartile) and, with 5 categories or more, the quartiles on the bars; without the option no line is drawn

	quar = ordr & (nlev >= 5)

	medtxt = st_local("t_median")

	if (medtxt == "") medtxt = "Median"

	wmed = mchaid_tw(fl, mchaid_len(medtxt))

	wq = mchaid_tw(fl, 6)																					//"Q1, Q3"

	legw = 0.3*(nlev - 1)																					//width of the legend: squares and labels of the categories, then the lines of the median and of the quartiles

	for (j = 1; j <= nlev; j++) legw = legw + 0.16 + 0.07 + mchaid_tw(fl, strlen(subinstr(dvl[j], char(34), "")))

	if (ordr) legw = legw + 0.3 + 0.3 + 0.07 + wmed

	if (quar) legw = legw + 0.3 + 0.3 + 0.07 + wq

	xs = max((xs, legw + 0.6))
	
	ys = topm + hbox + D*dy + gapbar + barh + botm
	
	msz = min((xs, ys))																						//text sizes in Stata are percentages of the smaller side of the graph
	
	fn = 0.17																								//text heights in inches: variable and node names, n lines, branch labels, percentages, legend, title and note
	
	fnn = 0.125
	
	fe = 0.14
	
	fp = 0.125
	
	ft = 0.28
	
	fz = 0.12
	
	Pk = J(k, D, "")
	
	fullkeys = J(k, 1, "")
	
	for (i = 1; i <= k; i++) {
	
		key = ""
		
		for (d = 1; d <= b[i]; d++) {
		
			key = key + "|" + P[i, d]
			
			Pk[i, d] = key
		
		}
		
		fullkeys[i] = key
	
	}
	
	xl = (1::k)																								//horizontal position of the nodes: the order of the tree (the numbering of the nodes unless norenumber is used)
	
	if (st_global("e(renumber)") == "norenumber") {
	
		ord = order(fullkeys, 1)
		
		xl[ord] = (1::k)
	
	}
	
	x0 = (xs - k*dx)/2
	
	xl = x0 :+ (xl :- 0.5)*dx
	
	allkeys = J(0, 1, "")
	
	for (i = 1; i <= k; i++) {
	
		for (d = 1; d <= b[i]; d++) allkeys = allkeys \ Pk[i, d]
	
	}
	
	nodes = uniqrows(allkeys)
	
	nn = rows(nodes)
	
	E = J(0, 4, .)
	
	B = J(0, 7, .)
	
	L = J(0, 4, .)
	
	M = J(0, 5, .)

	W = J(0, 3, .)
	
	textopts = ""
	
	opts = "placement(c)"
	
	//root: the heading is "Total" (or rootlabel()); the splitting variable and its test go in the block over its branches
	svar = substr(P[1, 1], 1, strpos(P[1, 1], "@") - 1)
	if (mchaid_isf(sf, 1, 1)) svar = svar + st_local("t_dagger")

	nline = "n = " + strofreal(sum(sizes), "%12.0fc")

	px = (min(xl) + max(xl))/2

	py = ys - topm - hbox/2

	fh = mchaid_fitcl(subinstr(st_local("rl"), char(34), "'"), mwh)

	wbox = max((0.7, mchaid_tw(fn, strlen(svar)), mchaid_tw(fnn, strlen(nline)), mchaid_headw(fh) - 0.06)) + 0.2

	E = E \ (py + hbox/2, px - wbox/2, py + hbox/2, px + wbox/2) \ (py - hbox/2, px - wbox/2, py - hbox/2, px + wbox/2) \ (py + hbox/2, px - wbox/2, py - hbox/2, px - wbox/2) \ (py + hbox/2, px + wbox/2, py - hbox/2, px + wbox/2)

	textopts = mchaid_nodetext(py + hbox/2, px, fh, nline, fnn, msz)
	
	//parent of each node and number of lines of its branch label (3 at most, longer lists are cut)
	nlu = J(nn, 1, 1)

	paru = J(nn, 1, "")

	for (u = 1; u <= nn; u++) {

		key = nodes[u]

		du = strlen(key) - strlen(subinstr(key, "|", "", .))

		m1 = select((1::k), rowsum(Pk:== key):> 0)[1]

		if (du > 1) paru[u] = Pk[m1, du - 1]

		elab = mchaid_levlab(substr(P[m1, du], 1, strpos(P[m1, du], "@") - 1), substr(P[m1, du], strpos(P[m1, du], "@") + 1, .))

		nlu[u] = min((cols(mchaid_wrap(elab, 20)), 3))

	}

	for (u = 1; u <= nn; u++) {
	
		key = nodes[u]
		
		du = strlen(key) - strlen(subinstr(key, "|", "", .))
		
		members = select((1::k), rowsum(Pk:== key):> 0)
		
		m1 = members[1]
		
		isleaf = max(b[members]:== du)
		
		nx = (min(xl[members]) + max(xl[members]))/2
		
		if (isleaf) {
		
			cl = select(members, b[members]:== du)[1]
			
			nx = xl[cl]
			
			ny = ys - topm - hbox/2 - D*dy
		
		}
		
		else ny = ys - topm - hbox/2 - du*dy
		
		//parent coordinates
		if (du == 1) {
		
			px = (min(xl) + max(xl))/2
			
			py = ys - topm - hbox/2
		
		}
		
		else {
		
			parkey = Pk[m1, du - 1]
			
			members = select((1::k), rowsum(Pk:== parkey):> 0)
			
			px = (min(xl[members]) + max(xl[members]))/2
			
			py = ys - topm - hbox/2 - (du - 1)*dy
		
		}
		
		gapu = 0.0417 + bh + 0.0426																			//distance from the box of the parent to the horizontal line of the branches: the block of the splitting variable and its test sits in it

		ymid = py - hbox/2 - gapu

		if (du == 1) parkey = ""																				//the parent of the first level is the root

		E = E \ (py - hbox/2, px, ymid, px) \ (ymid, px, ymid, nx) \ (ymid, nx, ny + hbox/2, nx)

		//block of the parent, once per parent: its splitting variable (with the mark of forcevars()) and, under it, its test, on a white rectangle over the branch
		if (!any(pdone :== parkey)) {

			pdone = pdone \ parkey

			svp = substr(P[m1, du], 1, strpos(P[m1, du], "@") - 1)

			if (mchaid_isf(sf, m1, du)) svp = svp + st_local("t_dagger")

			stxt = ""

			if (showp & (rows(sp) >= m1) & (cols(sp) >= du)) stxt = mchaid_cstat(skc, m1, du) + mchaid_ptxt(sp[m1, du], strtoreal(st_local("pcut")), st_local("pcut"))

			btop = py - hbox/2 - 0.0417

			bwid = max((0.9722, mchaid_tw(fn, strlen(svp)) + 0.1, mchaid_tw(fz, strlen(stxt)) + 0.1))

			W = W \ (px - bwid/2, px + bwid/2, btop - bh/2)

			textopts = textopts + " " + mchaid_blocktext(btop, px, svp, stxt, showp, bh, fn, fz, msz)

		}

		//heading of the box: the categories of the splitting variable that lead to the node, and its size
		elab = mchaid_levlab(substr(P[m1, du], 1, strpos(P[m1, du], "@") - 1), substr(P[m1, du], strpos(P[m1, du], "@") + 1, .))

		members = select((1::k), rowsum(Pk:== key):> 0)

		if (isleaf) {

			nline = "n = " + strofreal(sizes[1, cl], "%12.0fc")

			svar = ""

		}

		else {

			svar = substr(P[m1, du + 1], 1, strpos(P[m1, du + 1], "@") - 1)
			if (mchaid_isf(sf, m1, du + 1)) svar = svar + st_local("t_dagger")

			nline = "n = " + strofreal(sum(sizes[1, members']), "%12.0fc")

		}

		fh = mchaid_fitcl(elab, mwh)

		wbox = max((0.7, mchaid_tw(fn, strlen(svar)), mchaid_tw(fnn, strlen(nline)), mchaid_headw(fh) - 0.06)) + 0.2

		E = E \ (ny + hbox/2, nx - wbox/2, ny + hbox/2, nx + wbox/2) \ (ny - hbox/2, nx - wbox/2, ny - hbox/2, nx + wbox/2) \ (ny + hbox/2, nx - wbox/2, ny - hbox/2, nx - wbox/2) \ (ny + hbox/2, nx + wbox/2, ny - hbox/2, nx + wbox/2)

		textopts = textopts + " " + mchaid_nodetext(ny + hbox/2, nx, fh, nline, fnn, msz)
		
		if (isleaf) {
		
			ybt = ny - hbox/2 - gapbar
			
			ybb = ybt - barh
			
			cum = 0
			
			mx = max(rp[cl, .])
			
			for (j = 1; j <= nlev; j++) {
			
				pc = rp[cl, j]
				
				B = B \ (nx, ybb + barh*cum/100, ybb + barh*(cum + pc)/100, j, pc, ybb + barh*(cum + pc/2)/100, (pc == mx) & (pc > 0))
				
				cum = cum + pc
			
			}
			
			if (ordr) {																							//the height of the stack is the cumulative percentage: the median is at 50%, the quartiles at 25% and 75%
			
				labs = J(0, 2, .)																				//centre and half width of the percentages written inside the bars: the lines are interrupted there so that they can be read
				
				if (st_local("pct") != "nopct") {
				
					cum = 0
					
					for (j = 1; j <= nlev; j++) {
					
						pc = rp[cl, j]
						
						if (((pc >= 12) | ((pc == mx) & (pc > 0))) & (pc > 0) & (pc < .)) labs = labs \ (ybb + barh*(cum + pc/2)/100, mchaid_tw(fp, strlen(strofreal(round(pc))) + ((pc == mx) & (pc > 0)))/2 + 0.05)
						
						cum = cum + pc
					
					}
				
				}
				
				lv = (50 \ (quar ? (25 \ 75) : J(0, 1, .)))																	//percentiles to mark: median and, with 5 categories or more, the quartiles
				
				yq = J(rows(lv), 1, .)																			//height of each percentile: the bar is divided in nlev equal bands, one for each category in order, and the percentile is interpolated inside the category where the cumulative percentage reaches it
				
				for (j = 1; j <= rows(lv); j++) {
				
					cum = 0
					
					for (jq = 1; jq <= nlev; jq++) {
					
						pc = rp[cl, jq]
						
						if ((pc > 0) & (pc < .) & (cum + pc >= lv[j] - 0.000001)) {
						
							yq[j] = ybb + barh*((jq - 1) + min((1, max((0, (lv[j] - cum)/pc)))))/nlev
							
							break
						
						}
						
						if (pc < .) cum = cum + pc
					
					}
				
				}
				
				nq = rows(lv)
				
				if ((nq > 1) & (yq[1] < .) & (st_local("quartiles") != "all")) if (any(abs(yq[2..nq] :- yq[1]) :< 0.07)) nq = 1						//quartiles(auto): a quartile too close to the median to be told apart from it: only the median of that node is drawn; quartiles(all): all of them are always drawn
				
				yd = J(0, 1, .)																					//heights already drawn: lines that coincide are drawn once
				
				for (j = 1; j <= nq; j++) {
				
					ym = yq[j]
					
					if ((ym == .) | any(abs(yd :- ym) :< 0.000001)) continue
					
					yd = yd \ ym
					
					lt = (j > 1)																				//0 solid (median), 1 dotted (quartiles)
					
					gp = 0
					
					for (r = 1; r <= rows(labs); r++) if (abs(labs[r, 1] - ym) < 0.09) gp = max((gp, labs[r, 2]))		//a percentage at the height of the line: the line stops before and starts after it
					
					if (gp > 0) M = M \ (ym, nx - 0.5, ym, nx - gp, lt) \ (ym, nx + gp, ym, nx + 0.5, lt)
					
					else M = M \ (ym, nx - 0.5, ym, nx + 0.5, lt)
				
				}
			}
		
		}
	
	}
	
	//legend: one square and one label for each category of the response variable
	xleg = (xs - legw)/2
	
	yleg = 0.55
	
	for (j = 1; j <= nlev; j++) {
	
		L = L \ (xleg + 0.08, yleg - 0.08, yleg + 0.08, j)
		
		wj = mchaid_tw(fl, strlen(subinstr(dvl[j], char(34), "")))
		
		textopts = textopts + " " + mchaid_text(yleg, xleg + 0.16 + 0.07 + wj/2, (subinstr(dvl[j], char(34), "")), "placement(c) size(" + strofreal(100*fl/msz, "%9.3f") + ")")
		
		xleg = xleg + 0.16 + 0.07 + wj + 0.3
	
	}
	
	if (ordr) {																								//legend of the lines: median (solid) and, with 5 categories or more, quartiles (dotted)
	
		M = M \ (yleg, xleg, yleg, xleg + 0.3, 0)
		
		textopts = textopts + " " + mchaid_text(yleg, xleg + 0.3 + 0.07 + wmed/2, (medtxt), "placement(c) size(" + strofreal(100*fl/msz, "%9.3f") + ")")
		
		xleg = xleg + 0.3 + 0.07 + wmed + 0.3
	
	}
	
	if (quar) {
	
		M = M \ (yleg, xleg, yleg, xleg + 0.3, 1)
		
		textopts = textopts + " " + mchaid_text(yleg, xleg + 0.3 + 0.07 + wq/2, ("Q1, Q3"), "placement(c) size(" + strofreal(100*fl/msz, "%9.3f") + ")")
	
	}
	
	//title and note
	textopts = textopts + " " + mchaid_text(ys - 0.33, xs/2, (subinstr(ttl, char(34), "")), "placement(c) size(" + strofreal(100*ft/msz, "%9.3f") + ")")
	
	textopts = textopts + " " + mchaid_text(0.17, 0.15, (lefttxt), "placement(e) size(" + strofreal(100*fz/msz, "%9.3f") + ")")					//risk estimate and V on the left, the note in the rest of the line

	textopts = textopts + " " + mchaid_text(0.17, (wl + 0.3 + xs)/2, (note), "placement(c) size(" + strofreal(100*fz/msz, "%9.3f") + ")")
	
	st_matrix(Ename, E)
	
	st_matrix(Bname, B)
	
	st_matrix(Lname, L)
	
	if (rows(M) > 0) st_matrix(Mname, M)												//a matrix cannot have 0 rows: with an unordered response there is none

	st_matrix(Wname, W)

	st_local("bhw", strofreal(bh, "%9.4f"))
	
	st_local("textopts", textopts)
	
	st_local("xs", strofreal(xs, "%9.3f"))
	
	st_local("ys", strofreal(ys, "%9.3f"))
	
	st_local("psz", strofreal(100*fp/msz, "%9.3f"))
}

//number written in the decimal and thousands separators of the language of the graph (en: 1,234.5; fr: 1 234,5; the others: 1.234,5)
string scalar mchaid_loc(string scalar s)
{
	string scalar lang, th
	lang = st_local("t_lang")
	if ((lang == "") | (lang == "en")) return(s)
	th = (lang == "fr" ? " " : ".")
	s = subinstr(s, ",", char(1), .)
	s = subinstr(s, ".", ",", .)
	return(subinstr(s, char(1), th, .))
}
//statistic of a split for the graph of the boxes: "chi2 = 13.764; p < 0.001" (the p-value is left out with nopval)
string scalar mchaid_stattxt(real scalar chi, real scalar p, string scalar sname, real scalar showp, real scalar cut, string scalar cuttxt)
{
	string scalar out, ptx
	out = ""
	if (chi < .) out = sname + " = " + mchaid_loc(strofreal(chi, (chi >= 100 ? "%12.0fc" : (chi >= 10 ? "%9.1f" : "%9.2f"))))
	if (showp & (p < .)) {
		if ((cut < .) & (p < cut)) ptx = "p < " + mchaid_loc(cuttxt)
		else if (p < .001) ptx = "p < " + mchaid_loc("0.001")
		else ptx = "p = " + mchaid_loc(strofreal(p, "%5.3f"))
		out = out + (strlen(out) ? "; " : "") + ptx
	}
	return(out)
}
//statistics of the distribution of an ordered response in a node on the scale 0-K (category j occupies the band j-1 to j; the percentiles are interpolated inside the category where the cumulative
//percentage reaches them, as the lines of quartiles() do): lower edge of the first occupied category, p5, q1, median, q3, p95 and upper edge of the last occupied category
real rowvector mchaid_pcat(real rowvector pc)
{
	real scalar j, K, cum, tot, p, i, first, last
	real rowvector pp, out
	K = cols(pc)
	tot = sum(pc)
	first = 0
	last = 0
	for (j = 1; j <= K; j++) if (pc[j] > 0) {
		if (first == 0) first = j
		last = j
	}
	pp = (5, 25, 50, 75, 95)
	out = J(1, 5, .)
	for (i = 1; i <= 5; i++) {
		p = tot*pp[i]/100
		cum = 0
		for (j = 1; j <= K; j++) {
			if ((pc[j] > 0) & (cum + pc[j] >= p - 1e-9)) {
				out[i] = (j - 1) + min((1, max((0, (p - cum)/pc[j]))))
				break
			}
			cum = cum + pc[j]
		}
	}
	return((first - 1, out, last))
}
//lines of a box plot (y1 x1 y2 x2 kind) centred in px at height yr, on the scale vmin-vmax that takes the width bw: whiskers (kind 2) with caps, median (kind 3)
real matrix mchaid_boxlines(real scalar lo, real scalar q1, real scalar med, real scalar q3, real scalar hi, real scalar px, real scalar yr, real scalar vmin, real scalar vmax, real scalar bw)
{
	real scalar s, a, b, c, d, e
	s = (vmax > vmin ? bw/(vmax - vmin) : 0)
	a = px - bw/2 + (lo - vmin)*s
	b = px - bw/2 + (q1 - vmin)*s
	c = px - bw/2 + (med - vmin)*s
	d = px - bw/2 + (q3 - vmin)*s
	e = px - bw/2 + (hi - vmin)*s
	return((yr, a, yr, b, 2) \ (yr, d, yr, e, 2) \ (yr - 0.06, a, yr + 0.06, a, 2) \ (yr - 0.06, e, yr + 0.06, e, 2) \ (yr - 0.12, c, yr + 0.12, c, 3))
}
//level (1-5) of the shade of the colour of a node: the more standard deviations from the reference the stronger (one or more: the strongest)
real scalar mchaid_shade(real scalar z, real scalar noshade)
{
	if (noshade | (z >= .)) return(5)
	return(1 + round(4*min((abs(z), 1))))
}
//JSON of the interactive tree: text with its quotes and escapes (also "</", which would close the script of the page)
string scalar mchaid_js(string scalar t0)
{
	real scalar c
	string scalar bs, t
	t = t0																				//(Mata passes the arguments by reference: the caller's text must not change)
	bs = char(92)
	t = subinstr(t, bs, bs + bs, .)
	t = subinstr(t, char(34), bs + char(34), .)
	t = subinstr(t, char(10), bs + "n", .)
	t = subinstr(t, char(13), bs + "r", .)
	t = subinstr(t, char(9), bs + "t", .)
	t = subinstr(t, "</", "<" + bs + "/", .)
	for (c = 1; c <= 31; c++) t = subinstr(t, char(c), " ", .)
	return(char(34) + t + char(34))
}
//number (null when it is missing)
string scalar mchaid_jn(real scalar x)
{
	string scalar r
	if (x >= .) return("null")
	r = strtrim(strofreal(x, "%21.10g"))
	if (substr(r, 1, 1) == ".") r = "0" + r											//JSON needs the zero before the point
	else if (substr(r, 1, 2) == "-.") r = "-0" + substr(r, 2, .)
	return(r)
}
//true or false
string scalar mchaid_jb(real scalar x)
{
	return(x ? "true" : "false")
}
//object from its keys and its values (already in JSON)
string scalar mchaid_jo(string rowvector k, string rowvector v)
{
	real scalar i
	string scalar out
	out = "{"
	for (i = 1; i <= cols(k); i++) out = out + (i > 1 ? "," : "") + char(34) + k[i] + char(34) + ":" + v[i]
	return(out + "}")
}
//array from its values (already in JSON)
string scalar mchaid_ja(string rowvector v)
{
	real scalar i
	string scalar out
	out = "["
	for (i = 1; i <= cols(v); i++) out = out + (i > 1 ? "," : "") + v[i]
	return(out + "]")
}
//text inside html (tooltips of the page)
string scalar mchaid_hesc(string scalar t0)
{
	string scalar t
	t = subinstr(t0, "&", "&amp;", .)
	t = subinstr(t, "<", "&lt;", .)
	return(subinstr(t, ">", "&gt;", .))
}
//colour "R G B" to its three numbers
real rowvector mchaid_rgb3(string scalar t)
{
	real rowvector m
	m = strtoreal(tokens(t))
	if (cols(m) < 3) return((100, 100, 100))
	return(m[1..3])
}
//colour mixed with white: intensity a (0 to 1)
real rowvector mchaid_mix(real rowvector m, real scalar a)
{
	return(round(255*(1 - a) :+ m*a))
}
//#RRGGBB
string scalar mchaid_hexc(real rowvector m)
{
	real scalar i, v
	string scalar dg, out
	dg = "0123456789ABCDEF"
	out = "#"
	for (i = 1; i <= 3; i++) {
		v = min((255, max((0, round(m[i])))))
		out = out + substr(dg, floor(v/16) + 1, 1) + substr(dg, mod(v, 16) + 1, 1)
	}
	return(out)
}
//relative luminance and contrast ratio of two colours (WCAG)
real scalar mchaid_rellum(real rowvector m)
{
	real rowvector c
	c = m/255
	c = (c :<= 0.03928) :* (c/12.92) :+ (c :> 0.03928) :* (((c :+ 0.055)/1.055):^2.4)
	return(0.2126*c[1] + 0.7152*c[2] + 0.0722*c[3])
}
real scalar mchaid_contrast(real rowvector a, real rowvector b)
{
	real scalar la, lb
	la = mchaid_rellum(a)
	lb = mchaid_rellum(b)
	return((max((la, lb)) + 0.05)/(min((la, lb)) + 0.05))
}
//colour (black or white) of the text written on a colour: the one that contrasts more
string scalar mchaid_texton(real rowvector m)
{
	return(mchaid_contrast(m, (0, 0, 0)) >= mchaid_contrast(m, (255, 255, 255)) ? "black" : "white")
}
//the colour darkened (same hue) until its contrast with white is at least 3, to write a text with it on a white background
string scalar mchaid_darken(real rowvector m)
{
	real scalar f
	f = 1
	while ((f > 0.2) & (mchaid_contrast(round(m*f), (255, 255, 255)) < 3)) f = f*0.95
	return(mchaid_hexc(round(m*f)))
}
//writes the page index.html of the interactive tree (the json is in mchaid_hjson, which mchaid_tree2 has built)
void mchaid_hwrite(string scalar file, string scalar ttl)
{
	external string scalar mchaid_hjson
	real scalar fh
	string scalar q
	q = char(34)
	fh = fopen(file, "w")
	fput(fh, "<!DOCTYPE html>")
	fput(fh, "<html>")
	fput(fh, "<head>")
	fput(fh, "<meta charset=" + q + "UTF-8" + q + ">")
	fput(fh, "<meta name=" + q + "viewport" + q + " content=" + q + "width=device-width, initial-scale=1" + q + ">")
	fput(fh, "<!--mchaid Project-->")
	fput(fh, "<title>" + mchaid_hesc(ttl) + "</title>")
	fput(fh, "<link rel=" + q + "stylesheet" + q + " type=" + q + "text/css" + q + " href=" + q + "styles/tree.css" + q + ">")
	fput(fh, "</head>")
	fput(fh, "<body>")
	fput(fh, "<script type=" + q + "application/json" + q + " id=" + q + "data" + q + ">" + mchaid_hjson + "</script>")
	fput(fh, "<script src=" + q + "scripts/d3.min.js" + q + "></script>")
	fput(fh, "<script src=" + q + "scripts/tree.js" + q + "></script>")
	fput(fh, "</body>")
	fput(fh, "</html>")
	fclose(fh)
}
//creates a folder and the ones above it that do not exist
void mchaid_mkdirs(string scalar path)
{
	string scalar cur, rest, part
	real scalar i
	cur = ""
	rest = path
	if (substr(path, 1, 1) == "/") {
		cur = "/"
		rest = substr(path, 2, .)
	}
	while (strlen(rest) > 0) {
		i = strpos(rest, "/")
		if (i == 0) {
			part = rest
			rest = ""
		}
		else {
			part = substr(rest, 1, i - 1)
			rest = substr(rest, i + 1, .)
		}
		if (part == "") continue
		cur = cur + part
		if ((substr(part, strlen(part), 1) != ":") & !direxists(cur)) mkdir(cur)				//(a drive, C:, is not created)
		cur = cur + "/"
	}
}
//coordinates of the tree in the style of boxes, in inches: every node is a box with its number, its size and a horizontal bar with the distribution of the response variable;
//the final nodes also show the predicted (modal) category. The graph is built from the variables that this function creates in the (empty) dataset of the caller:
//e1-e4, ed (lines: y1 x1 y2 x2, 1 = dashed), r1-r3, rk (rectangles: x1 x2 y, kind), ty tx tk ts (texts: y, x, kind, text)
void mchaid_tree2(string scalar rpname, string scalar ttl)
{
	real scalar k, nlev, i, j, d, u, v, D, nn, nt, N, dx, hb, barh, wb, bw, topm, botm, xs, ys, msz, x0, c0, cum, pc, mx, jm
	real scalar cw7, nlr, rh, lr, lx, ly, lty
	real colvector LW, LT, LR
	real scalar legw, wj, xleg, yleg, ttlw, ltw, wlab, p, chi, showp, cut, nl, labh, labc, ytopc, yb, yline, px, cxmin, cxmax, ww, ybar, xa, m1, du, nw
	real scalar fnm, fnn, fsv, fch, fbl, fpc, fpr, flg, flt, ft, zt
	real scalar isbox, noshade, ref, vmin, vmax, lvl, yr, yd, a0, a1, xr, zsd, mm, lo, hi, yax, xg, cw1, cw2, cw3, cw4, ytop
	real matrix S2
	real colvector stc, dev, z, wlo, whi
	string colvector l3
	string scalar wh, whtxt, reftxt, boxtxt
	real matrix sizes, rp, sp, sc, Mem, PC, E, Rc, Tt
	real colvector b, xl, dep, par, isl, cl, xu, x, num, nsz, nlc, idx, yc, gap
	real rowvector cnt
	string matrix P, Pk, Lab
	string colvector nodes, allkeys, fullkeys, key, svn, sct, nline, nname, Ts
	string rowvector tk, lines, dvl
	string rowvector hf
	string colvector hl
	string scalar prd, nbtxt
	real scalar cls, mq, rkc, rk0c, cvc, gm0, maxd
	string scalar mk, footl
	real scalar headcat, bwid
	string scalar var, elab, parkey, sname, lab, pcuttxt, legt, pre, fnote
	real matrix sf
	real scalar hasforced, ynote
	real scalar oi, s5, a5, nct, spv
	real rowvector ct
	real matrix hrgb, cbm, com, FQ
	real colvector zz, ord
	string scalar hs, defin, tipstr, predc
	string rowvector hcol, cbv, cov, hk, hv, bl, pcs, cts, cats, lvs
	external string scalar mchaid_hjson
	external real matrix mchaid_tE, mchaid_tR, mchaid_tT
	external string colvector mchaid_tS
	transmorphic t
	k = st_numscalar("e(N_clusters)")
	cls = (st_local("pcls") == "1")								//the page in the layout of the classic graph (treestyle(classic) with directory())
	mk = (cls ? st_local("t_dagger") : "*")
	sizes = st_matrix("e(sizes)")
	sp = st_matrix("e(splitp)")
	sc = st_matrix("e(splitchi)")
	sf = st_matrix("e(splitforced)")
	hasforced = (sum(sf) > 0)
	fnote = (hasforced ? mk + " " + st_local("t_forced") : "")
	ynote = (hasforced ? 0.2 : 0)									//room for the line with the note of the forced variables
	rp = st_matrix(rpname)
	nlev = cols(rp)
	N = sum(sizes)
	showp = (st_local("pval") != "nopval")
	pcuttxt = st_local("pcut")
	cut = strtoreal(pcuttxt)
	sname = (st_global("e(splitstat)") == "F" ? "F" : st_local("t_chi"))
	dvl = tokens(st_local("dvlabels"))
	if ((subinstr(dvl[nlev], char(34), "") == "missing") & (st_global("e(missing)") == "missing") & (st_local("t_missing") != "")) dvl[nlev] = st_local("t_missing")
	for (j = 1; j <= nlev; j++) dvl[j] = subinstr(dvl[j], char(34), "")
	//paths of the final nodes
	P = J(k, 0, "")
	b = J(k, 1, 0)
	t = tokeninit(";", "", "")
	for (i = 1; i <= k; i++) {
		tokenset(t, st_global("e(path" + strofreal(i) + ")"))
		tk = tokengetall(t)
		b[i] = cols(tk)
		if (cols(tk) > cols(P)) P = (P, J(k, cols(tk) - cols(P), ""))
		P[i, 1..cols(tk)] = tk
	}
	D = max(b)
	Pk = J(k, D, "")
	fullkeys = J(k, 1, "")
	for (i = 1; i <= k; i++) {
		pre = ""
		for (d = 1; d <= b[i]; d++) {
			pre = pre + "|" + P[i, d]
			Pk[i, d] = pre
		}
		fullkeys[i] = pre
	}
	xl = (1::k)																								//order of the final nodes along the horizontal axis: that of the tree
	if (st_global("e(renumber)") == "norenumber") {
		idx = order(fullkeys, 1)
		xl[idx] = (1::k)
	}
	allkeys = J(0, 1, "")
	for (i = 1; i <= k; i++) {
		for (d = 1; d <= b[i]; d++) allkeys = allkeys \ Pk[i, d]
	}
	nodes = uniqrows(allkeys)
	nn = rows(nodes)
	nt = nn + 1																								//all the nodes; the first one is the root
	key = "" \ nodes
	dep = J(nt, 1, 0)
	par = J(nt, 1, 0)
	isl = J(nt, 1, 0)
	cl = J(nt, 1, .)
	Mem = J(k, nt, 0)
	Mem[., 1] = J(k, 1, 1)
	for (u = 2; u <= nt; u++) {
		dep[u] = strlen(key[u]) - strlen(subinstr(key[u], "|", "", .))
		for (i = 1; i <= k; i++) {
			for (d = 1; d <= b[i]; d++) if (Pk[i, d] == key[u]) Mem[i, u] = 1
			if (Mem[i, u] & (b[i] == dep[u])) {
				isl[u] = 1
				cl[u] = i
			}
		}
		if (dep[u] == 1) par[u] = 1
		else {
			for (i = 1; i <= k; i++) if (Mem[i, u]) break
			parkey = Pk[i, dep[u] - 1]
			for (v = 2; v <= nt; v++) if (key[v] == parkey) par[u] = v
		}
	}
	//position of the nodes in units of final node (leaves in order; the others in the middle of their first and last children); numbering: all the nodes level by level, left to right, the root is 0
	xu = J(nt, 1, .)
	for (d = D; d >= 0; d--) {
		for (u = 1; u <= nt; u++) {
			if (dep[u] != d) continue
			if (isl[u]) xu[u] = xl[cl[u]]
			else {
				cxmin = 1e100
				cxmax = -1e100
				for (v = 2; v <= nt; v++) if (par[v] == u) {
					cxmin = min((cxmin, xu[v]))
					cxmax = max((cxmax, xu[v]))
				}
				xu[u] = (cxmin + cxmax)/2
			}
		}
	}
	num = J(nt, 1, .)
	c0 = 0
	for (d = 0; d <= D; d++) {
		idx = J(0, 1, .)
		for (u = 1; u <= nt; u++) if (dep[u] == d) idx = idx \ u
		idx = idx[order(xu[idx], 1)]
		for (i = 1; i <= rows(idx); i++) num[idx[i]] = c0++
	}
	//size and distribution of the response in each node
	PC = J(nt, nlev, 0)
	nsz = J(nt, 1, 0)
	for (u = 1; u <= nt; u++) {
		cnt = J(1, nlev, 0)
		for (i = 1; i <= k; i++) if (Mem[i, u]) {
			cnt = cnt + sizes[1, i]*rp[i, .]/100
			nsz[u] = nsz[u] + sizes[1, i]
		}
		if (isl[u]) PC[u, .] = rp[cl[u], .]
		else if (sum(cnt) > 0) PC[u, .] = 100*cnt/sum(cnt)
	}
	nline = J(nt, 1, "")
	nname = J(nt, 1, "")
	for (u = 1; u <= nt; u++) {
		nline[u] = mchaid_loc(strofreal(nsz[u], "%12.0fc") + " (" + strofreal(100*nsz[u]/N, "%5.1f") + "%)")
		nname[u] = subinstr(st_local("t_node"), "@", strofreal(num[u]))
	}
	//labels of the branches (the categories of the splitting variable) and, for the nodes that are split, the splitting variable with its test
	Lab = J(nt, 3, "")
	nlc = J(nt, 1, 0)
	svn = J(nt, 1, "")
	sct = J(nt, 1, "")
	hl = J(nt, 1, "")													//heading of the box (nodehead(category)): the category of the splitting variable that forms the node; the root, its own label
	headcat = (st_local("nh") == "category")
	hl[1] = subinstr(st_local("rl"), char(34), "'")
	for (u = 1; u <= nt; u++) {
		for (m1 = 1; m1 <= k; m1++) if (Mem[m1, u]) break
		if (u > 1) {
			du = dep[u]
			var = substr(P[m1, du], 1, strpos(P[m1, du], "@") - 1)
			elab = mchaid_levlab(var, substr(P[m1, du], strpos(P[m1, du], "@") + 1, .))
			hl[u] = subinstr(elab, char(34), "'")
			lines = mchaid_wrap(elab, 18)
			if (cols(lines) > 3) lines = (lines[1..2], lines[3] + " ...")
			nlc[u] = cols(lines)
			Lab[u, 1..cols(lines)] = lines
		}
		if (!isl[u]) {
			du = dep[u] + 1
			var = substr(P[m1, du], 1, strpos(P[m1, du], "@") - 1)
			lab = ""
			if (_st_varindex(var) != .) lab = st_varlabel(var)
			if (lab == "") lab = var
			if (mchaid_len(lab) > 26) lab = substr(lab, 1, 24) + "..."
			svn[u] = subinstr(lab, char(34), "'")
			if (mchaid_isf(sf, m1, du)) svn[u] = svn[u] + "*"
			p = .
			chi = .
			if ((rows(sp) >= m1) & (cols(sp) >= du)) p = sp[m1, du]
			if ((rows(sc) >= m1) & (cols(sc) >= du)) chi = sc[m1, du]
			sct[u] = mchaid_stattxt(chi, p, sname, showp, cut, pcuttxt)
				if (cls) {
					svn[u] = var + (mchaid_isf(sf, m1, du) ? mk : "")
					sct[u] = (showp ? mchaid_cstat(sc, m1, du) + mchaid_ptxt(p, cut, pcuttxt) : "")
				}
		}
	}
	isbox = (st_local("np") == "box") & !cls
	noshade = (st_local("shd") == "noshade")
	wh = st_local("wh")
	l3 = J(nt, 1, "")
	vmin = 0
	vmax = nlev
	if (isbox) {																						//box plots of the ordered response on the scale of its categories
		S2 = J(nt, 7, .)
		for (u = 1; u <= nt; u++) S2[u, .] = mchaid_pcat(PC[u, .])
		stc = S2[., 4]
		ref = stc[1]
		cnt = PC[1, .]
		mm = sum(cnt:*((1..nlev) :- 0.5))/sum(cnt)
		zsd = max((0.1, sqrt(sum(cnt:*(((1..nlev) :- 0.5) :- mm):^2)/sum(cnt))))
		dev = stc :- ref
		z = dev/zsd
		wlo = (wh == "minmax" ? S2[., 1] : (wh == "tukey" ? rowmax((S2[., 1], S2[., 3] :- 1.5*(S2[., 5] :- S2[., 3]))) : S2[., 2]))
		whi = (wh == "minmax" ? S2[., 7] : (wh == "tukey" ? rowmin((S2[., 7], S2[., 5] :+ 1.5*(S2[., 5] :- S2[., 3]))) : S2[., 6]))
		for (u = 1; u <= nt; u++) l3[u] = st_local("t_median") + ": " + dvl[min((max((ceil(stc[u]), 1)), nlev))]
	}
	if (st_local("hdir") != "") {													//interactive tree: the json of the page (same fields as tree_html() of the R package)
		hcol = J(1, nlev, "")
		hrgb = J(nlev, 3, .)
		for (j = 1; j <= nlev; j++) {
			hrgb[j, .] = mchaid_rgb3(st_local("col" + strofreal(j)))
			hcol[j] = mchaid_hexc(hrgb[j, .])
		}
		cbm = J(5, 3, .)
		com = J(5, 3, .)
		cbv = J(1, 5, "")
		cov = J(1, 5, "")
		for (s5 = 1; s5 <= 5; s5++) {
			a5 = 0.2 + 0.8*(s5 - 1)/4
			cbm[s5, .] = mchaid_mix((0, 114, 178), a5)
			com[s5, .] = mchaid_mix((213, 94, 0), a5)
			cbv[s5] = mchaid_hexc(cbm[s5, .])
			cov[s5] = mchaid_hexc(com[s5, .])
		}
		FQ = st_matrix(st_local("fq"))
		zz = (isbox ? z : J(nt, 1, 0))
		whtxt = (wh == "minmax" ? st_local("t_minmax") : (wh == "tukey" ? st_local("t_iqr") : "P5-P95"))
		ord = order(num, 1)
		hs = ""
		for (oi = 1; oi <= nt; oi++) {
			u = ord[oi]
			for (m1 = 1; m1 <= k; m1++) if (Mem[m1, u]) break
			defin = "all observations"
			if (u > 1) {
				defin = ""
				for (d = 1; d <= dep[u]; d++) {
					var = substr(P[m1, d], 1, strpos(P[m1, d], "@") - 1)
					elab = substr(P[m1, d], strpos(P[m1, d], "@") + 1, .)
					nct = cols(tokens(elab))
					defin = defin + (d > 1 ? " & " : "") + var + (nct > 1 ? " in {" : " = ") + mchaid_levlab(var, elab) + (nct > 1 ? "}" : "")
				}
			}
			ct = J(1, nlev, 0)
			for (i = 1; i <= k; i++) if (Mem[i, u]) ct = ct + FQ[i, .]
			lvl = mchaid_shade(zz[u], noshade)
			mx = max(PC[u, .])
			jm = 0
			for (j = 1; j <= nlev; j++) if ((PC[u, j] == mx) & (jm == 0)) jm = j
			spv = .
			if (!isl[u]) {
				du = dep[u] + 1
				if ((rows(sp) >= m1) & (cols(sp) >= du)) spv = sp[m1, du]
			}
			if (isbox) predc = (u == 1 ? "#595959" : mchaid_darken(zz[u] >= 0 ? cbm[lvl, .] : com[lvl, .]))
			else predc = mchaid_darken(hrgb[jm, .])
			tipstr = "<b>" + nname[u] + "</b>" + (isl[u] ? " &middot; " + subinstr((st_local("t_lang") == "es" ? "nodo final @" : "terminal node @"), "@", strofreal(cl[u])) : "")
			tipstr = tipstr + "<br><span class='def'>" + mchaid_hesc(defin) + "</span><br>n = " + nline[u] + "<table class='dist'>"
			for (j = 1; j <= nlev; j++) tipstr = tipstr + "<tr><td><i style='background:" + hcol[j] + "'></i>" + mchaid_hesc(dvl[j]) + "</td><td>" + mchaid_loc(strofreal(PC[u, j], "%9.1f")) + "%</td><td>" + strtrim(strofreal(ct[j], "%12.0fc")) + "</td></tr>"
			tipstr = tipstr + "</table>"
			if (!isl[u] & strlen(sct[u])) tipstr = tipstr + "<br><span class='sp'>" + mchaid_hesc(svn[u]) + ": " + sct[u] + "</span>"
			if (isl[u]) tipstr = tipstr + "<br><b>" + st_local("t_pred") + " " + mchaid_hesc(dvl[jm]) + "</b>"
			bl = J(1, 0, "")
			if (u > 1) for (i = 1; i <= nlc[u]; i++) bl = (bl, mchaid_js(Lab[u, i]))
			hk = ("id", "parent", "depth", "leaf", "term", "x", "name", "n", "nline", "pctn", "l3", "l4", "branch", "svar", "stat", "p", "def", "tip", "fill", "lvl", "sign", "headlab", "nleaves", "pc", "ct", "jm", "pred", "predcol")
			hv = (mchaid_jn(num[u]), (u == 1 ? "null" : mchaid_jn(num[par[u]])), mchaid_jn(dep[u]), mchaid_jb(isl[u]), (isl[u] ? mchaid_jn(cl[u]) : "null"), mchaid_jn(xu[u]), mchaid_js(nname[u]), mchaid_jn(nsz[u]), mchaid_js(nline[u]), mchaid_jn(100*nsz[u]/N), mchaid_js(l3[u]), mchaid_js(""), mchaid_ja(bl), (isl[u] ? "null" : mchaid_js(svn[u])), (isl[u] ? "null" : mchaid_js(sct[u])), (isl[u] ? "null" : mchaid_jn(spv)), mchaid_js(defin), mchaid_js(tipstr), mchaid_js(u == 1 ? "#D9D9D9" : (zz[u] >= 0 ? cbv[lvl] : cov[lvl])), mchaid_jn(lvl), mchaid_jn(u == 1 ? 0 : (zz[u] >= 0 ? 1 : -1)), mchaid_js(hl[u]), mchaid_jn(sum(Mem[., u])))
			pcs = J(1, 0, "")
			cts = J(1, 0, "")
			for (j = 1; j <= nlev; j++) {
				pcs = (pcs, mchaid_jn(PC[u, j]))
				cts = (cts, mchaid_jn(ct[j]))
			}
			hv = (hv, mchaid_ja(pcs), mchaid_ja(cts), mchaid_jn(jm), mchaid_js(st_local("t_pred") + " " + dvl[jm]), mchaid_js(predc))
				if (cls) {
					hk = (hk, "ncl")
					hv = (hv, mchaid_js("n = " + strtrim(strofreal(nsz[u], "%12.0fc"))))
				}
			if (isbox) {
				hk = (hk, "q1", "q3", "med", "lo", "hi")
				hv = (hv, mchaid_jn(S2[u, 3]), mchaid_jn(S2[u, 5]), mchaid_jn(S2[u, 4]), mchaid_jn(wlo[u]), mchaid_jn(whi[u]))
			}
			hs = hs + (oi > 1 ? "," : "") + mchaid_jo(hk, hv)
		}
		hk = ("kind", "nodeplot", "depvar", "language", "D", "k", "pct", "center", "whisker", "whiskertxt", "dvordered", "collapse", "nodehead")
		hv = (mchaid_js("mchaid"), mchaid_js(isbox ? "box" : "bar"), mchaid_js(st_local("dvname")), mchaid_js(st_local("t_lang")), mchaid_jn(D), mchaid_jn(k), mchaid_jb(st_local("pct") != "nopct"), mchaid_js("mean"), mchaid_js(wh), mchaid_js(whtxt), mchaid_jb(st_global("e(dvordered)") == "dvordered"), (strtoreal(st_local("collapse")) >= 0 ? st_local("collapse") : "null"), mchaid_js(st_local("nh")))
		if (cls) {
			rkc = 1 - (sizes*rowmax(rp)/100)/sum(sizes)
			rk0c = 1 - max(sizes*rp/100)/sum(sizes)
			cvc = abs(strtoreal(st_local("cramv")))
			footl = st_local("t_risk") + " = " + strofreal(rkc, "%5.3f") + " (" + st_local("t_root") + ": " + strofreal(rk0c, "%5.3f") + ")"
			if (cvc < .) footl = footl + "  " + char(194) + char(183) + "  " + st_local("t_cramer") + " = " + strofreal(cvc, "%5.3f")
			mq = ((st_global("e(dvordered)") == "dvordered") & (st_local("quartiles") != "") & (nlev >= 5) ? 3 : 1)
			hk = (hk, "treestyle", "showp", "quartiles", "foot", "nquart")
			hv = (hv, mchaid_js("classic"), mchaid_jb(showp), (st_local("quartiles") != "" ? mchaid_js(st_local("quartiles")) : "null"), mchaid_jo(("left", "note"), (mchaid_js(footl), mchaid_js(st_local("t_note")))), mchaid_jn(mq))
		}
		if (isbox) {
			cats = J(1, 0, "")
			for (j = 1; j <= nlev; j++) cats = (cats, mchaid_js(dvl[j]))
			hk = (hk, "scale")
			hv = (hv, mchaid_jo(("vmin", "vmax", "ref", "ref2", "cats", "reftxt"), (mchaid_jn(0), mchaid_jn(nlev), mchaid_jn(ref), "null", mchaid_ja(cats), mchaid_js(st_local("t_overallmed") + " = " + dvl[min((max((ceil(ref), 1)), nlev))]))))
		}
		lvs = J(1, 0, "")
		for (j = 1; j <= nlev; j++) lvs = (lvs, mchaid_jo(("name", "color", "text"), (mchaid_js(dvl[j]), mchaid_js(hcol[j]), mchaid_js(mchaid_texton(hrgb[j, .])))))
		hk = (hk, "colors", "levels", "legend", "main", "note")
		hv = (hv, mchaid_jo(("above", "below", "above5", "below5"), (mchaid_js(cbv[5]), mchaid_js(cov[5]), mchaid_js(cbv[5]), mchaid_js(cov[5]))), mchaid_ja(lvs), mchaid_js(st_local("dvname") + " " + st_local("t_legend")), mchaid_js(ttl), mchaid_js(fnote))
		mchaid_hjson = mchaid_jo(("options", "text", "nodes"), (mchaid_jo(hk, hv), mchaid_jo(("above", "below", "median", "node", "pred", "leaf"), (mchaid_js(st_local("t_above")), mchaid_js(st_local("t_below")), mchaid_js(st_local("t_median")), mchaid_js(st_local("t_node")), mchaid_js(st_local("t_pred")), mchaid_js(st_local("t_leaf")))), "[" + hs + "]"))
	}
	//sizes (inches)
	fnm = 0.165																								//text heights: name of the node, n, splitting variable, its test, branch labels, percentages, prediction, legend, title of the legend, title
	fnn = 0.125
	fsv = 0.15
	fch = 0.115
	fbl = 0.12
	fpc = 0.105
	fpr = 0.14
	flg = 0.15
	flt = 0.17
	ft = 0.26
	hb = (isbox ? 1.08 : 0.92)																								//height of the boxes
	barh = 0.28
	zt = 0.46																								//from the box of a node to the horizontal line of its branches
	wb = (isbox ? 1.6 : 1.2)
	for (u = 1; u <= nt; u++) wb = max((wb, mchaid_tw(fnn, mchaid_len(nline[u])) + 0.2, mchaid_tw(fnn, mchaid_len(l3[u])) + 0.2, (headcat ? min((1.7, mchaid_tw(0.14, 1.08*mchaid_len(hl[u])) + 0.2)) : mchaid_tw(fnm, mchaid_len(nname[u])) + 0.25)))
	bw = wb - 0.18
	dx = wb + 0.18
	legt = (isbox ? st_local("dvname") : st_local("dvname") + " " + st_local("t_legend"))
	whtxt = (wh == "minmax" ? st_local("t_minmax") : (wh == "tukey" ? st_local("t_iqr") : "P5-P95"))
	if (isbox) {
		reftxt = st_local("t_overallmed") + " = " + dvl[min((max((ceil(ref), 1)), nlev))]
		boxtxt = "Q1-Q3, " + st_local("t_median") + ", " + whtxt
		cw1 = 0.5 + 0.07 + mchaid_tw(flg, mchaid_len(boxtxt))
		cw2 = 0.3 + 0.07 + mchaid_tw(flg, mchaid_len(reftxt))
		cw3 = 0.16 + 0.07 + mchaid_tw(flg, mchaid_len(st_local("t_above")))
		cw4 = 0.16 + 0.07 + mchaid_tw(flg, mchaid_len(st_local("t_below")))
	}
	ltw = mchaid_tw(flt, mchaid_len(legt))
	cw7 = 0.16 + 0.07 + mchaid_tw(flg, mchaid_len(st_local("t_leaf")))
	LW = J(0, 1, .)																				//items of the legend (width, type) in rows no wider than the tree, 3 at most
	LT = J(0, 1, .)
	if (isbox) {
		LW = cw1 \ cw2 \ cw3 \ cw4
		LT = 1 \ 3 \ 5 \ 6
	}
	else {
		for (j = 1; j <= nlev; j++) {
			LW = LW \ (0.16 + 0.07 + mchaid_tw(flg, mchaid_len(dvl[j])))
			LT = LT \ (10 + j)
		}
	}
	LW = LW \ cw7
	LT = LT \ 7
	LR = mchaid_legrows(LW, 0.3, max((k*dx, 8)))
	nlr = max(LR)
	rh = 0.26																					//pitch of the rows
	legw = 0
	for (lr = 1; lr <= nlr; lr++) legw = max((legw, sum(select(LW, LR :== lr)) + 0.3*(sum(LR :== lr) - 1)))
	ttlw = 0
	if (strlen(ttl) > 0) ttlw = mchaid_tw(ft, mchaid_len(ttl))
	xs = max((k*dx + 0.6, legw + 0.6, ltw + 0.6, ttlw + 0.6, (hasforced ? mchaid_tw(flg, mchaid_len(fnote)) + 0.6 : 0)))
	x0 = (xs - k*dx)/2
	x = x0 :+ (xu :- 0.5)*dx
	topm = (strlen(ttl) > 0 ? 0.6 : 0.15)
	if (headcat) topm = topm + 0.12												//the square with the number sticks out of the root box
	botm = (isbox ? 1.4 : 1.05) + ynote + (nlr - 1)*rh																			//below the last level: prediction and legend
	gap = J(D + 1, 1, 0)																					//space between the boxes of a level and the next one: tests, branch lines and labels (as high as the highest one)
	for (d = 0; d < D; d++) {
		nl = 1
		for (u = 2; u <= nt; u++) if (dep[u] == d + 1) nl = max((nl, nlc[u]))
		gap[d + 1] = (headcat ? zt + 0.30 : zt + 0.12 + (0.10 + 0.14*nl) + 0.20)			//without labels on the branches the drop is short
	}
	ys = topm + (D + 1)*hb + sum(gap) + botm
	msz = min((xs, ys))
	yc = J(D + 1, 1, .)
	yc[1] = ys - topm - hb/2
	for (d = 1; d <= D; d++) yc[d + 1] = yc[d] - hb - gap[d]
	E = J(0, 5, .)
	Rc = J(0, 4, .)
	Tt = J(0, 3, .)
	Ts = J(0, 1, "")
	for (u = 1; u <= nt; u++) {
		d = dep[u]
		px = x[u]
		//box, name, size and bar
		Rc = Rc \ (px - wb/2, px + wb/2, yc[d + 1], 1)
		if (headcat) {																					//heading: category of the splitting variable that forms the node; the number goes in a small square on the top left corner
			hf = mchaid_fithead(hl[u], wb - 0.16)
			if (cols(hf) == 2) {
				Tt = Tt \ (yc[d + 1] + hb/2 - 0.17, px, strtoreal(hf[1]))
				Ts = Ts \ ("{bf:" + hf[2] + "}")
			}
			else {
				Tt = Tt \ (yc[d + 1] + hb/2 - 0.105, px, strtoreal(hf[1])) \ (yc[d + 1] + hb/2 - 0.25, px, strtoreal(hf[1]))
				Ts = Ts \ ("{bf:" + hf[2] + "}") \ ("{bf:" + hf[3] + "}")
			}
			nbtxt = strofreal(num[u])
			bwid = max((0.16, 0.064*strlen(nbtxt) + 0.08))
			Rc = Rc \ (px - wb/2, px - wb/2 + bwid, yc[d + 1] + hb/2 + 0.075, (isl[u] ? 7 : 6))						//a terminal node: dark square with the number in white
			Tt = Tt \ (yc[d + 1] + hb/2 + 0.075, px - wb/2 + bwid/2, (isl[u] ? 51 : 50))
			Ts = Ts \ ("{bf:" + nbtxt + "}")
		}
		else {
			if (isl[u]) Rc = Rc \ (px - wb/2, px + wb/2, yc[d + 1] + hb/2 - 0.165, 8)								//(nodehead(number)) a terminal node: dark heading with the text in white
			Tt = Tt \ (yc[d + 1] + hb/2 - 0.17, px, (isl[u] ? 52 : 1))
			Ts = Ts \ ("{bf:" + nname[u] + "}")
		}
		Tt = Tt \ (yc[d + 1] + hb/2 - 0.39, px, 2)
		Ts = Ts \ nline[u]
		if (isbox) {
			Tt = Tt \ (yc[d + 1] + hb/2 - 0.57, px, 6)
			Ts = Ts \ l3[u]
		}
		ybar = yc[d + 1] + hb/2 - 0.70
		cum = 0
		mx = max(PC[u, .])
		xa = px - bw/2
		jm = 0
		for (j = 1; j <= nlev; j++) {
			pc = PC[u, j]
			if ((pc == mx) & (jm == 0)) jm = j
			if ((pc > 0) & !isbox) {
				Rc = Rc \ (xa + bw*cum/100, xa + bw*(cum + pc)/100, ybar, 100 + j)
				if (((pc >= 12) | (pc == mx)) & (st_local("pct") != "nopct") & (pc >= 1)) {
					Tt = Tt \ (ybar, xa + bw*(cum + pc/2)/100, 100 + j)
					Ts = Ts \ strofreal(round(pc))
				}
			}
			cum = cum + pc
		}
		if (isbox) {
			lvl = mchaid_shade(z[u], noshade)
			yr = yc[d + 1] + hb/2 - 0.86
			xr = px - bw/2 + (ref - vmin)*bw/(vmax - vmin)
			Rc = Rc \ (px - bw/2 + S2[u, 3]*bw/nlev, px - bw/2 + S2[u, 5]*bw/nlev, yr, (u == 1 ? 900 : (z[u] >= 0 ? 200 : 210) + lvl))
			E = E \ mchaid_boxlines(wlo[u], S2[u, 3], S2[u, 4], S2[u, 5], whi[u], px, yr, vmin, vmax, bw) \ (yr - 0.19, xr, yr + 0.19, xr, 4)
		}
		if (isl[u] & (jm > 0)) {
			Tt = Tt \ (yc[d + 1] - hb/2 - 0.17, px, 10 + jm)
			prd = st_local("t_pred") + " " + dvl[jm]
			if (mchaid_tw(0.85*fpr, mchaid_len(prd)) > dx - 0.06) prd = mchaid_cut(prd, 0.85*fpr, dx - 0.06)		//it may not touch the prediction of the next leaf
			Ts = Ts \ ("{bf:" + prd + "}")
		}
		if (isl[u]) continue
		//splitting variable and test, line of the branches, labels of the branches
		yb = yc[d + 1] - hb/2
		yline = yb - zt
		ww = max((mchaid_tw(fsv, mchaid_len(svn[u])), mchaid_tw(fch, mchaid_len(sct[u])))) + 0.1
		Rc = Rc \ (px - ww/2, px + ww/2, yb - 0.23, 2)
		Tt = Tt \ (yb - 0.15, px, 3)
		Ts = Ts \ ("{bf:" + svn[u] + "}")
		if (strlen(sct[u])) {
			Tt = Tt \ (yb - 0.32, px, 4)
			Ts = Ts \ sct[u]
		}
		E = E \ (yb, px, yline, px, 0)
		cxmin = 1e100
		cxmax = -1e100
		for (v = 2; v <= nt; v++) if (par[v] == u) {
			cxmin = min((cxmin, x[v]))
			cxmax = max((cxmax, x[v]))
		}
		if (cxmax > cxmin) E = E \ (yline, cxmin, yline, cxmax, 0)
		for (v = 2; v <= nt; v++) {
			if (par[v] != u) continue
			ytopc = yc[d + 2] + hb/2
			labh = 0.10 + 0.14*nlc[v]
			labc = ytopc + 0.20 + labh/2
			if (headcat) {															//the category is in the heading of the box: the line goes straight to it
				E = E \ (yline, x[v], ytopc, x[v], 0)
				continue
			}
			E = E \ (yline, x[v], labc, x[v], 0) \ (labc, x[v], ytopc, x[v], 1)
			wlab = 0
			for (i = 1; i <= nlc[v]; i++) wlab = max((wlab, mchaid_tw(fbl, mchaid_len(Lab[v, i]))))
			Rc = Rc \ (x[v] - wlab/2 - 0.08, x[v] + wlab/2 + 0.08, labc, 2 + nlc[v])
			for (i = 1; i <= nlc[v]; i++) {
				Tt = Tt \ (labc + ((nlc[v] + 1)/2 - i)*0.14, x[v], 5)
				Ts = Ts \ Lab[v, i]
			}
		}
	}
	//legend: title and, below, the items in rows (as in the R package): a square and a label for each category, or for the box plots what the plot shows, the reference and the colours
	yleg = (isbox ? 0.62 : 0.28) + ynote
	for (lr = 1; lr <= nlr; lr++) {
		lx = (xs - (sum(select(LW, LR :== lr)) + 0.3*(sum(LR :== lr) - 1)))/2
		ly = yleg + (nlr - lr)*rh
		for (i = 1; i <= rows(LW); i++) {
			if (LR[i] != lr) continue
			lty = LT[i]
			if (lty == 1) {
				E = E \ (ly, lx, ly, lx + 0.5, 2) \ (ly - 0.06, lx, ly + 0.06, lx, 2) \ (ly - 0.06, lx + 0.5, ly + 0.06, lx + 0.5, 2) \ (ly - 0.12, lx + 0.25, ly + 0.12, lx + 0.25, 3)
				Rc = Rc \ (lx + 0.15, lx + 0.35, ly, 900)
				Tt = Tt \ (ly, lx + 0.5 + 0.07 + mchaid_tw(flg, mchaid_len(boxtxt))/2, 7)
				Ts = Ts \ boxtxt
			}
			else if (lty == 3) {
				E = E \ (ly - 0.19, lx + 0.15, ly + 0.19, lx + 0.15, 4)
				Tt = Tt \ (ly, lx + 0.3 + 0.07 + mchaid_tw(flg, mchaid_len(reftxt))/2, 7)
				Ts = Ts \ reftxt
			}
			else if (lty == 5) {
				Rc = Rc \ (lx, lx + 0.16, ly, 240)
				Tt = Tt \ (ly, lx + 0.16 + 0.07 + mchaid_tw(flg, mchaid_len(st_local("t_above")))/2, 7)
				Ts = Ts \ st_local("t_above")
			}
			else if (lty == 6) {
				Rc = Rc \ (lx, lx + 0.16, ly, 241)
				Tt = Tt \ (ly, lx + 0.16 + 0.07 + mchaid_tw(flg, mchaid_len(st_local("t_below")))/2, 7)
				Ts = Ts \ st_local("t_below")
			}
			else if (lty == 7) {																//terminal node: the dark square of its number
				Rc = Rc \ (lx, lx + 0.16, ly, 7)
				Tt = Tt \ (ly, lx + 0.16 + 0.07 + mchaid_tw(flg, mchaid_len(st_local("t_leaf")))/2, 7)
				Ts = Ts \ st_local("t_leaf")
			}
			else {																				//a category of the response variable
				j = lty - 10
				Rc = Rc \ (lx, lx + 0.16, ly, 10 + j)
				Tt = Tt \ (ly, lx + 0.16 + 0.07 + mchaid_tw(flg, mchaid_len(dvl[j]))/2, 7)
				Ts = Ts \ dvl[j]
			}
			lx = lx + LW[i] + 0.3
		}
	}
	if (isbox) {																						//box plots: below the legend, the scale (the categories)
		yax = 0.30 + ynote
		xg = xs/2 - bw/2
		E = E \ (yax, xg, yax, xg + bw, 2)
		for (j = 0; j <= nlev; j++) E = E \ (yax - 0.05, xg + j*bw/nlev, yax + 0.05, xg + j*bw/nlev, 2)
		Tt = Tt \ (yax - 0.17, xg + 0.5*bw/nlev, 30) \ (yax - 0.17, xg + (nlev - 0.5)*bw/nlev, 30)
		Ts = Ts \ dvl[1] \ dvl[nlev]
	}
	Tt = Tt \ (yleg + (nlr - 1)*rh + 0.33, xs/2, 8)
	Ts = Ts \ legt
	if (hasforced) {															//note of the mark of the forced variables, at the bottom
		Tt = Tt \ (0.12, xs/2, 7)
		Ts = Ts \ fnote
	}
	if (strlen(ttl) > 0) {
		Tt = Tt \ (ys - 0.3, xs/2, 9)
		Ts = Ts \ subinstr(ttl, char(34), "'")
	}
	//the data of the graph are kept until the dataset is replaced (mchaid_tree2put): the labels of the variables and of their values must be read before
	mchaid_tE = E
	mchaid_tR = Rc
	mchaid_tT = Tt
	mchaid_tS = Ts
	st_local("xs", strofreal(xs, "%9.3f"))
	st_local("ys", strofreal(ys, "%9.3f"))
	st_local("h_box", strofreal(hb, "%9.3f"))
	st_local("h_bar", strofreal(barh, "%9.3f"))
	st_local("h_back", "0.36")
	st_local("h_q", "0.24")
	st_local("h_badge", "0.15")
	for (i = 1; i <= 3; i++) st_local("h_lab" + strofreal(i), strofreal(0.10 + 0.14*i, "%9.3f"))
	st_local("s_nm", strofreal(100*fnm/msz, "%9.3f"))
	st_local("s_n", strofreal(100*fnn/msz, "%9.3f"))
	st_local("s_sv", strofreal(100*fsv/msz, "%9.3f"))
	st_local("s_ch", strofreal(100*fch/msz, "%9.3f"))
	st_local("s_bl", strofreal(100*fbl/msz, "%9.3f"))
	st_local("s_pc", strofreal(100*fpc/msz, "%9.3f"))
	st_local("s_pr", strofreal(100*fpr/msz, "%9.3f"))
	st_local("s_lg", strofreal(100*flg/msz, "%9.3f"))
	st_local("s_lt", strofreal(100*flt/msz, "%9.3f"))
	st_local("s_tt", strofreal(100*ft/msz, "%9.3f"))
	st_local("s_h2", strofreal(100*0.15/msz, "%9.3f"))
	st_local("s_h3", strofreal(100*0.138/msz, "%9.3f"))
	st_local("s_h4", strofreal(100*0.126/msz, "%9.3f"))
	st_local("s_h5", strofreal(100*0.12/msz, "%9.3f"))
}
//writes in the (empty) dataset the lines, rectangles and texts calculated by mchaid_tree2
void mchaid_tree2put()
{
	external real matrix mchaid_tE, mchaid_tR, mchaid_tT
	external string colvector mchaid_tS
	real scalar nw
	nw = max((rows(mchaid_tE), rows(mchaid_tR), rows(mchaid_tT)))
	st_addobs(nw)
	(void) st_addvar("double", ("e1", "e2", "e3", "e4", "ed", "r1", "r2", "r3", "rk", "ty", "tx", "tk"))				//(void): st_addvar() returns the indices of the new variables and Mata would write them in the output
	(void) st_addvar("str244", "ts")
	if (rows(mchaid_tE) > 0) st_store((1::rows(mchaid_tE)), ("e1", "e2", "e3", "e4", "ed"), mchaid_tE)
	st_store((1::rows(mchaid_tR)), ("r1", "r2", "r3", "rk"), mchaid_tR)
	st_store((1::rows(mchaid_tT)), ("ty", "tx", "tk"), mchaid_tT)
	st_sstore((1::rows(mchaid_tT)), "ts", mchaid_tS)
}

end
/*mata function to recursively partition data based on CHAID algorithm*/
version 12.1

mata:

mata set matastrict on

string matrix mchaid(string rowvector unordvar, string rowvector ordvar, string scalar type, ///
string scalar names, string scalar vars, real scalar alpha1, real scalar alpha3, ///
real scalar minsplit, real scalar minnode, real scalar maxbranch, real scalar alpha2, ///
string scalar bfadj, string scalar svy, string scalar exhaust, string scalar fast, string scalar ordtable, string scalar norenum, string scalar steps, string scalar forcepos)
{
	real matrix selectvar, select2var, countcheck, comparecount, splitp, splitchi, splitfor
	
	real rowvector var1, var2, merger_ps, merger_aic, withinselect, randresolve, ///
	branches
	
	real colvector unordpcomp
	
	real scalar mchsep, mchlo1, mchhi1, mchll, mchdf
	
	real matrix mchn
	
	real scalar position, moresplit, compare_p, current_p, compare_chi, current_chi, compare_aic, current_aic, ///
	moremerge, clustercount, currentcluster, adj_p, countmerge, temploc1, temploc2, ///
	mergeruns, floating, match_p
	
	string matrix splits, CHAIDsplit
	
	string rowvector varsvec, namesvec, typevec, selecttype, collapsevec, selectnames, ///
	clusnames, comparenames, select2names, select2vec
	
	string scalar temploc1s, temploc2s, splitformat

	string rowvector trpairs
	real rowvector trp
	string colvector trrows
	real scalar tri, trbest, trraw
	
	transmorphic basis																				
	
	real matrix fastbin, fastD, fastmask
	
	real colvector fastrows, fastdv, fastwt, fastgrp
	
	real rowvector fres
	
	string rowvector fastnames
	
	real scalar xx
	
	real rowvector fpos
	
	real scalar nforce, isforced, forcemerge, fbflag, fbc, fbb, endpos, startpos, nfb, fbskip
	
	string scalar fbtxt
	
	real matrix rn_R, rn_key
	
	string matrix rn_P
	
	real colvector rn_p, rn_newid, rn_cl, rn_idx, rn_sib
	
	real scalar rn_n, rn_b, rn_i, rn_d, rn_j
	
	string scalar rn_pre, rn_par
	
	string rowvector rn_all, rn_tok
	
	real rowvector rn_pos
	
	
	position = 2																						//updatable position of data to find in varsvec
	
	varsvec = tokens(vars)																				//vectorize the tempvars																		
	
	splitfor = (0)													//1 where the variable of the split was chosen with forcevars(), same layout as splitp
	fpos = strtoreal(tokens(forcepos))								//positions in varsvec of the variables that split the first levels of the tree (forcevars)
	nforce = cols(fpos)
	isforced = 0
	forcemerge = 0
	fbflag = 0
	fbc = 0
	fbb = 0
	startpos = 2
	endpos = cols(varsvec)
	nfb = 0
	fbtxt = ""
	
	
	moresplit = 1																						//scalar to indicate continue splitting process between-variable process
	
	compare_p = 1																						//currently lowest p-value for deciding which variable will be splitting variable
	
	compare_aic = .																						//currently lowesr AIC value for deciding which variable will be splitting variable
	compare_chi = .
	
	clustercount = 1
	
	currentcluster = 1
	
	comparenames = ("")
	
	branches = (0)
	
	splits = ("")

	splitp = (.)																							//adjusted p-value of the split that created each branch of each cluster (same layout as splits)
	splitchi = (.)																							//test statistic of that split (likelihood-ratio chi2, F with svy), same layout
	
	q = tokeninit(wchars = (" "), pchars = (" "), qchars = ("()"))										//vectorize the display names
		
	tokenset(q, names)
	
	namesvec = tokengetall(q)
	
	
	q = tokeninit(wchars = (" "), pchars = (" "), qchars = ("()"))										//vectorize the type inputs
		
	tokenset(q, type)
	
	typevec = tokengetall(q)
	
	
	CHAIDsplit = ("Splits")

	trrows = J(0, 1, "")

	trpairs = J(1, 0, "")
	
	while (moresplit == 1) {																			//do following process at least once - continue if between-variable splitting process is to continue (i.e., moresplit == 1)
	
		stata("replace \`useob' = \`stop' & \`cluster' == " + strofreal(currentcluster) + " if \`touse'")	

		fbskip = (currentcluster > cols(branches))								//Mata evaluates both sides of &: branches[] cannot be read beyond the last cluster
		if (!fbskip & fbflag) fbskip = ((fbc == currentcluster) & (fbb == branches[currentcluster]))
		if ((nforce > 0) & (position == 2) & !fbskip) {		//start of a node (a node whose forced split was not possible is processed again with all the variables)
			isforced = (branches[currentcluster] < nforce)
			if (isforced) {														//the variable of this level is chosen by the user: it is the only candidate
				position = fpos[branches[currentcluster] + 1]
				endpos = position
				compare_p = .												//a forced variable is taken whatever its adjusted p-value
			}
			else endpos = cols(varsvec)
			startpos = position
		}
		
		selectnames = tokens(subinstr(subinstr(namesvec[position], ")", ""), "(", ""))					//pull out names for first independent variable (i.e., in position = 2] binaries using same procedure as with dependent variable - select() to pull out data - strpos() to create	vector of 1's, substr() to truncate names, strlen() to truncate substr() statement at length of focal independent variable to match												
		
		
		selecttype = tokens(subinstr(subinstr(typevec[position], ")", ""), "(", ""))					//pull out types for first independent variable using same procedure as with dependent variable - select() to pull out data - strpos() to create	vector of 1's, substr() to truncate names, strlen() to truncate substr() statement at length of focal independent variable to match												
		
		
		moremerge = 1																					//updatable scalar to indicate continute merging within-variable process
		
		stata("tabulate \`dv' \`useob' if \`touse' [\`weight'\`exp'], matcell(\`cellcount')") 			//tabulate dv with the current cluster set, keep the resulting matrix
		
		stata("ereturn matrix cellcount = \`cellcount'")												//ereturn the matrix to pull it into Mata - probably unnecessary, but it works
		
		countcheck = st_matrix("e(cellcount)")'															//pull matrix of counts into Mata, transposed
		
		
		if (rows(countcheck) > 1) countcheck = countcheck[2,]											//keep only the rows corresponding to the "useob" values if there are some that got a 0 on useob
		
		countcheck = select(countcheck, sign(countcheck))												//keep only the rows with some value (omit thosw with 0's)
		
		
		stata("summarize \`stop' [\`weight'\`exp']")													//quick summarize on stopping indicator
		
		if (st_numscalar("r(mean)") == 0) {																//if no-one has a 1 on stop, then end chaid as the process is now over
		
			moresplit = 0																				//don't split anymore - chaid is done
			
			moremerge = 0																				//don't merge anymore on this variable
			
		}
		
		else if ((rowsum(sign(countcheck)) == 1) | (rowsum(countcheck) <= minsplit)) {					//if there is only one value left in a cluster (i.e., it's pure) or it's size is below the minimum splitting size
			if ((nforce > 0) & (currentcluster == 1) & (branches[1] == 0)) _error(198, "forcevars(): the sample cannot be split: it is pure or has no more than minsplit(" + strofreal(minsplit) + ") observations")
			
			if (strlen(steps)) {
				mchaid_say("")
				mchaid_say("{res}Node: " + mchaid_path(splits[currentcluster, .], branches[currentcluster]) + " (n = " + strofreal(rowsum(countcheck), "%12.0fc") + ")")
				mchaid_say("{txt}  Not split: the node is pure or has no more than minsplit(" + strofreal(minsplit) + ") observations")
			}

			moremerge = 0																				//stop merging on this variable
			
			stata("replace \`stop' = 0 if \`useob' & \`touse'")											//update cluster to stop using this variable
			
			currentcluster++																			//increment current cluster - start using the next cluster up, look for splits there
			
			position = 2																				//restart "position" used in merging
			
		}
																										
		/*begin splitting variable category merging*/
		else {

			if (strlen(steps) & (position == startpos) & !forcemerge) {
				mchaid_say("")
				mchaid_say("{res}Node: " + mchaid_path(splits[currentcluster, .], branches[currentcluster]) + " (n = " + strofreal(rowsum(countcheck), "%12.0fc") + ")")
				mchaid_say("{txt}{hline 78}")
			}

		
			stata("tabulate " + varsvec[position] + ///
			" \`useob' if \`touse' [\`weight'\`exp'], \`missing' matcell(\`cellcount')") 
		
			stata("ereturn matrix cellcount = \`cellcount'")
		
			countcheck = st_matrix("e(cellcount)")'
		
		
			if (rows(countcheck) > 1) countcheck = countcheck[2,]
		
			selectnames = select(selectnames, sign(countcheck))

			if (strlen(steps)) mchaid_say("{txt}Variable {res}" + varsvec[position] + "{txt}: " + strofreal(cols(selectnames)) + " categories: " + mchaid_catlist(selectnames, ", "))

		
		
			if (strlen(fast)) {																				//pull the data for the current cluster into Mata once per splitting variable - the merging tests are then computed from cross-tabulations in Mata instead of by estimating a model in Stata
			
				fastmask = st_data(., (st_local("touse"), st_local("useob")))
				
				fastrows = select(1::rows(fastmask), (fastmask[., 1]:== 1):*(fastmask[., 2]:== 1))
				
				fastdv = st_data(fastrows, st_local("dv"))
				
				fastwt = st_data(fastrows, st_local("wtvar"))
				
				fastnames = tokens(invtokens(selectnames))
				
				fastbin = J(rows(fastrows), cols(fastnames), 0)
				
				for (xx = 1; xx <= cols(fastnames); xx++) fastbin[., xx] = st_data(fastrows, st_local(fastnames[xx]))
				
				fastD = (J(1, rows(uniqrows(fastdv)), fastdv):== uniqrows(fastdv)')
			
			}
			
			while (moremerge == 1) {
		
				collapsevec = ("")																			//replace/generate collapsevec including names of variables to be collapsed into single variable
			
				merger_ps = (.)
				
				merger_aic = (.)
				
				floating = 0
			
				if (cols(selectnames) > 2)  {																//if there are more than 2 categories and the type of variabel is "unordered" then proceed
		
					/*Unordered merging*/
					if (selecttype[1] == "u") {
										
						base = (J(2, 1, 1) \ J(cols(selectnames) - 2, 1, 0))								//setup vector for use in cvpermute() to select all sets of 2 variables
			
						
						basis = cvpermutesetup(base)														//register "base" vector with cvpermute()
				
						mergeruns = comb(cols(selectnames), 2)
				
					}
					
					else if (
					(selecttype[cols(selecttype)] == "f") & ///
					(colsum(regexm(selectnames[cols(selectnames)], "ms$")) == 1) & ///
					(colsum(cols(tokens(selectnames[cols(selectnames)]))) == 1)) {
					
						mergeruns = (cols(selectnames) - 1)*2 - 1
						
						floating = 1
						
						base = (J(1, 1, 1) \ J(cols(selectnames) - 2, 1, 0))								//setup vector for use in cvpermute() to select all sets of 2 variables
			
						
						basis = cvpermutesetup(base)
					
					}
					
					else {
					
						mergeruns = cols(selectnames) - 1
					
					}
				
					countmerge = 1
					trpairs = J(1, 0, "")
				
					while (countmerge <= mergeruns) {														//go through all different combinations of predictor levels to find best levels to collapse
			
						if (selecttype[1] == "u") select2var = cvpermute(basis)'							//invoke cvpermute for selector vector
				
						else if (((selecttype[1] == "o") & (floating == 0)) | ///
						((floating == 1) & (sign(countmerge*2 - mergeruns) != 1))) {
						
							select2var = (J(countmerge - 1, 1, 0) \ J(2, 1, 1) \ ///
							J(cols(selectnames) - countmerge - 1, 1, 0))'
						
						}
						
						else if ((floating == 1) & (sign(countmerge*2 - mergeruns) == 1)) {
						
							select2var = (cvpermute(basis)', 1)
									
						}
				
				
						collapsevec = (collapsevec, invtokens(strofreal(select2var)))						//create string vector indicating position of variabels to test
				
				
						select2names = select(selectnames, select2var)										//proceed to select 2 columns of predictor to evaluate for potentially collapsing

						if (strlen(steps)) trpairs = (trpairs, mchaid_grptext(select2names[1], 0) + " + " + mchaid_grptext(select2names[2], 0))

				
					
						if (strlen(fast)) {
						
							fres = mchaid_lr2(fastD, fastwt, mchaid_grp(fastbin, fastnames, tokens(select2names[1])), ///
							mchaid_grp(fastbin, fastnames, tokens(select2names[2])))
							
							merger_ps = (merger_ps, fres[1])
							
							merger_aic = (merger_aic, fres[2])
						
						}
						
						else {
						
					
						select2vec = tokens(select2names[1])
					
						temploc1 = st_addvar("byte", st_tempname())
					
						temploc1s = st_varname(temploc1)
						
						stata("replace " + temploc1s + "=0")
					
						for (y = 1; y <= cols(tokens(select2names[1])); y++) {
						
							stata("replace " + temploc1s + "=`" ///
							+ select2vec[y] + "' + " + temploc1s)
								
						}
					
					
						select2vec = tokens(select2names[2])
					
						temploc2 = st_addvar("byte", st_tempname())
					
						temploc2s = st_varname(temploc2)
						
						stata("replace " + temploc2s + "=0")
					
						for (y = 1; y <= cols(tokens(select2names[2])); y++) {
						
							stata("replace " + temploc2s + "=`" ///
							+ select2vec[y] + "' + " + temploc2s)
								
						}
					
						 
						
						mchsep = 0																							//with dvordered, two groups of categories that do not overlap on the response (perfect separation): ologit does not converge (and takes seconds to give up), the likelihood-ratio test is infinite

						if (st_local("reg") == "ologit") {

							stata("quietly summarize \`dv' if \`touse' & \`useob' & " + temploc1s + ", meanonly")

							mchlo1 = st_numscalar("r(min)")

							mchhi1 = st_numscalar("r(max)")

							stata("quietly summarize \`dv' if \`touse' & \`useob' & " + temploc2s + ", meanonly")

							mchsep = (mchhi1 < st_numscalar("r(min)")) | (st_numscalar("r(max)") < mchlo1)

						}

						if (mchsep) stata("capture error 430")

						else if (strlen(svy)) stata("capture svy, subpop(if \`touse' & \`useob' & (" + temploc1s + ///
						" | " + temploc2s + ")): \`reg' \`dv' " + temploc1s)

						else stata("capture \`permute'\`reg' \`dv' " + temploc1s + ///
							" if \`touse' & \`useob' & (" + temploc1s + " | " + temploc2s + ") [\`weight'\`exp']")

						if ((st_numscalar("c(rc)") == 0)) {
						
							if ((strlen(svy)) & !((mchaid_sc(st_local("test")) == .) | (mchaid_sc("df_m") == 0))) {
						
																
								merger_ps = (merger_ps, Ftail(mchaid_sc("e(df_m)"), ///
								mchaid_sc("e(df_r)"), mchaid_sc(st_local("test"))))
								
								stata("mchaid_getic, type(aicw) ll(1) parm(1) obs(1)")
								
								merger_aic = (merger_aic, st_numscalar("r(ic)"))

						
							}
							
							else if (!(strlen(svy)) & !((mchaid_sc(st_local("test")) == .) | (mchaid_sc("df_m") == 0)) & ///
							!(rows(mchaid_rp()))) {
					
								
								merger_ps = (merger_ps, chi2tail(mchaid_sc("e(df_m)"), ///
								mchaid_sc(st_local("test"))))
								
								stata("mchaid_getic, type(aicc) ll(\`=e(ll)') parm(\`=e(df_m)') obs(\`=e(N)')")
								
								merger_aic = (merger_aic, st_numscalar("r(ic)"))
						
							}
							
														
							else if (!(strlen(svy)) & (rows(mchaid_rp()))) {
							
								merger_ps = (merger_ps, mchaid_rp()[1,1])
								
								stata("mchaid_getic, type(aicc) ll(" + strofreal(st_matrix("r(b)")[1, 2]) + ///
								") parm(" + strofreal(st_matrix("r(b)")[1, 3]) + ") obs(" ///
								+ strofreal(st_matrix("r(b)")[1, 4]) + ")")
								
								merger_aic = (merger_aic, st_numscalar("r(ic)"))
								
							}
					
							else { 
								
								merger_ps = (merger_ps, 1)
								
								merger_aic = (merger_aic, .)
								
							}
							
						}
						
						else if ((st_numscalar("c(rc)") == 430) & (st_local("reg") == "ologit") & !strlen(svy)) {			//no convergence of ologit: perfect separation (before, p = 1 and the groups were merged first). The likelihood has no maximum but its supremum is finite: the test is that of the limit

							if (mchsep) {														//the supremum of the likelihood is that of the response within each group

								stata("quietly tabulate \`dv' " + temploc1s + " if \`touse' & \`useob' & (" + temploc1s + " | " + temploc2s + ") [\`weight'\`exp'], matcell(\`cellcount')")

								mchn = st_matrix(st_local("cellcount"))

								mchll = mchaid_nlogn(mchn[., 1]', colsum(mchn)[1]) + mchaid_nlogn(mchn[., 2]', colsum(mchn)[2])

								merger_ps = (merger_ps, chi2tail(1, max((2*(mchll - mchaid_nlogn(rowsum(mchn)', sum(mchn))), 0))))

								merger_aic = (merger_aic, mchaid_aicc(mchll, 1, sum(mchn)))

							}

							else if (mchaid_sc("e(chi2)") < .) {									//ologit leaves its last iteration in e()

								merger_ps = (merger_ps, chi2tail(1, mchaid_sc("e(chi2)")))

								merger_aic = (merger_aic, mchaid_aicc(mchaid_sc("e(ll)"), 1, mchaid_sc("e(N)")))

							}

							else {

								merger_ps = (merger_ps, 1)

								merger_aic = (merger_aic, .)

							}

						}

						else {

							merger_ps = (merger_ps, 1)

							merger_aic = (merger_aic, .)

						}
						}

						countmerge++
					
						
						if (!strlen(fast)) st_dropvar((temploc1s, temploc2s))
				
					}
			
					if (strlen(steps)) {
						trp = merger_ps[2..cols(merger_ps)]
						mchaid_say("{txt}  Merging step: candidate pairs and p-value of their difference (the highest is merged if p > " + strofreal(1 - alpha1) + ")")
						for (tri = 1; tri <= cols(trp); tri++) mchaid_say("      " + sprintf("%-46s", trpairs[tri]) + sprintf("%9s", mchaid_pfmt(trp[tri])))
					}

					if ((max(merger_ps) > 1 - alpha1) | (strlen(exhaust)) | forcemerge) {								//if at least one p-value doesn't the "respalpha" limit offered by the user, collapse the levels as they appear sufficiently homogeneous - also ensures that, when the DV is a constant, the algorithm stops
					
												merger_ps = strmatch(strofreal(merger_ps), strofreal(max(merger_ps)))					//find the position of the largest p-value that passed the spltalpha criterion
				
					
						if (rowsum(merger_ps) > 1) {
						
							merger_ps = (0, merger_ps[2..cols(merger_ps)]:* ///
							(merger_aic[2..cols(merger_aic)]:== ///
							max(select(merger_aic[2..cols(merger_aic)], merger_ps[2..cols(merger_ps)]))))	//among the tied p-values, find the position of the largest aic value
				
											
							if (rowsum(merger_ps) > 1) {
							
								randresolve = runiform(1, cols(merger_ps))
					
								merger_ps = strmatch(strofreal(merger_ps), strofreal(max(merger_ps)))
						
								merger_ps = randresolve:*merger_ps
						
								merger_ps = strmatch(strofreal(merger_ps), strofreal(max(merger_ps)))
								
								
							}
					
						}
				
						withinselect = strtoreal(tokens(select(collapsevec, merger_ps)))					//pull out variables associated with largest p-value

						if (strlen(steps)) {
							trbest = select(1..cols(merger_ps), merger_ps)[1] - 1
							mchaid_say("{txt}  -> merged: {res}" + trpairs[trbest] + "{txt} (p = " + mchaid_pfmt(trp[trbest]) + ")")
						}

						
						
						if (selecttype[1] == "u") selectnames = (invtokens(select(selectnames, withinselect)), ///
						select(selectnames, abs(withinselect:-1)))
						
						else if (selecttype[1] == "o") {
						
							countmerge = (strpos(invtokens(strofreal(withinselect)), "1") + 1)/2
							
							
							if (withinselect[countmerge] == withinselect[countmerge + 1]) { 
						
								if (countmerge == 1) selectnames = (invtokens(select(selectnames, withinselect)), ///
								select(selectnames[countmerge + 2..cols(withinselect)], ///
								abs(withinselect[countmerge + 2..cols(withinselect)]:-1)))
							
								else if (countmerge == cols(withinselect) - 1) selectnames = ///
								(select(selectnames[1..countmerge - 1], abs(withinselect[1..countmerge - 1]:-1)), ///
								invtokens(select(selectnames, withinselect)))
							
								else selectnames = (select(selectnames[1..countmerge - 1], abs(withinselect[1..countmerge - 1]:-1)), ///
								invtokens(select(selectnames, withinselect)), ///
								select(selectnames[countmerge + 2..cols(withinselect)], ///
								abs(withinselect[countmerge + 2..cols(withinselect)]:-1)))
							
							}
							
							else {
							
								if (countmerge == 1) selectnames = (invtokens(select(selectnames, withinselect)), ///
								select(selectnames[countmerge + 1..cols(withinselect) - 1], ///
								abs(withinselect[countmerge + 1..cols(withinselect) - 1]:-1)))
							
								else if (countmerge == cols(withinselect) - 1) selectnames = ///
								(select(selectnames[1..countmerge - 1], abs(withinselect[1..countmerge - 1]:-1)), ///
								invtokens(select(selectnames, withinselect)))
							
								else selectnames = (select(selectnames[1..countmerge - 1], abs(withinselect[1..countmerge - 1]:-1)), ///
								invtokens(select(selectnames, withinselect)), ///
								select(selectnames[countmerge + 1..cols(withinselect) - 1], ///
								abs(withinselect[countmerge + 1..cols(withinselect) - 1]:-1)))
							
							}
						
						}
					
						
						if ((alpha2 > 0) & !strlen(exhaust) & !forcemerge) {																	//re-splitting is not used with exhaustive CHAID: merging does not stop at mergalpha(), so merged categories would be split and merged again indefinitely
						
							match_p = -1
						
							selectnames = mchaidsplit(selectnames, withinselect, selecttype[1], alpha2, svy, match_p)
							
							
						}
				
					}
			
					else {
						moremerge = 0
						if (strlen(steps)) mchaid_say("{txt}  -> no pair exceeds p > " + strofreal(1 - alpha1) + ": merging stops")
					}
				
				}
			
				else {
					moremerge = 0
					if (strlen(steps)) mchaid_say("{txt}  Merging step: not needed, " + strofreal(cols(selectnames)) + " categories remain")
				}
				
				adj_p = 0
						
				if (!strlen(bfadj)) {
					
					if (selecttype[1] == "u") {
						
						if (strlen(exhaust)) adj_p = cols(selectnames)*(cols(selectnames) - 1)/2
								
						else {
						
							unordpcomp = (0::cols(selectnames))
					
							for (y = 1; y <= cols(selectnames); y++) {
					
								adj_p = adj_p + (-1)^unordpcomp[y]*((cols(selectnames) - ///
								unordpcomp[y])^cols(selecttype)/(factorial(unordpcomp[y])* ///
								factorial(cols(selectnames) - unordpcomp[y])))
										
							}
								
						}
																						
					}
						
					else if (selecttype[1] == "o") {
						
						if (strlen(exhaust)) adj_p = cols(selectnames)*(cols(selectnames)^2 - 1)/2
						
						else adj_p = comb(cols(selecttype) - 1, cols(selectnames) - 1)
						
					}
					
					else if (selecttype[cols(selecttype)] == "f") {
						
						if (strlen(exhaust)) adj_p = cols(selectnames)*(cols(selectnames) - 1)/2
							
						else {
						
							adj_p = comb(cols(selecttype) - 1, cols(selectnames) - 1)* ///
							((cols(selectnames) - 1) + cols(selectnames)*(cols(selecttype) - ///
							cols(selectnames)))/(cols(selecttype) - 1)
									
						}
							
					}
							
				}
						
				else adj_p = 1
						
			
			
			}
		
			/*Compute chi-square used for splitting*/
		
			countmerge = 1
		
			temploc1 = st_addvar("byte", st_tempname())
		
			temploc1s = st_varname(temploc1)
						
			stata("replace " + temploc1s + "=0 if \`touse' & \`useob'")
			
			for (x = 1; x <= cols(selectnames); x++) {
			
				select2vec = tokens(selectnames[x])					
					
				for (y = 1; y <= cols(select2vec); y++) {
					
						
					stata("replace " + temploc1s + "=`" ///
					+ select2vec[y] + "'*" + strofreal(countmerge) + " if `" ///
					+ select2vec[y] + "' & \`touse' & \`useob'")
						
				}
				
				countmerge++
				
				
			} 
				
			stata("tabulate " + temploc1s + ///
			" \`useob' if \`touse' [\`weight'\`exp'], \`missing' matcell(\`cellcount')") 
		
			stata("ereturn matrix cellcount = \`cellcount'")
		
				countcheck = st_matrix("e(cellcount)")'
			
				if (rows(countcheck) > 1) countcheck = countcheck[2,]										//with the missing option the cases outside the current node form an extra group of the table: only the "useob" row is kept, as when the node is tabulated above
			
				countcheck = select(countcheck, sign(countcheck))										//and the groups without cases in the node (that extra group) are dropped
		
			
			if (selecttype[1] == "u") {
			
				st_local("xi", "xi:")
				
				st_local("i", "i.")
			
			}
			
			if (selecttype[1] == "o") {
			
				st_local("xi", "")
				
				st_local("i", "")
			
			}
			
			if (strlen(fast) & ((selecttype[1] == "u") | (selecttype[1] == "o"))) {
			
				if (cols(countcheck) > 1) {
				
					fastgrp = J(rows(fastrows), 1, 0)
					
					for (xx = 1; xx <= cols(selectnames); xx++) {
					
						fastgrp = fastgrp + xx*mchaid_grp(fastbin, fastnames, tokens(selectnames[xx]))
						
					}
					
					if ((selecttype[1] == "u") | strlen(ordtable)) fres = mchaid_lrk(fastD, fastwt, fastgrp)				//test of the cross-tabulation (df = (groups - 1)*(outcome levels - 1))
						
						else fres = mchaid_lrt(fastD, fastwt, fastgrp)																		//ordered splitting variable: groups coded 1, 2, 3... enter as one linear term, as in mlogit with the numeric code
					
					current_p = fres[1]
					
					current_aic = fres[2]
					current_chi = fres[3]
				
				}
				
				else {
				
					current_p = 1
					
					current_aic = .
					current_chi = .
				
				}
			
			}
			
			else {
			
			if (strlen(svy)) stata("capture svy, subpop(if \`touse' & \`useob'): \`reg' \`dv' \`i'" + temploc1s)				//factor variables (i.) instead of xi:, which cannot be used inside permute
			
			else stata("capture \`permute' \`reg' \`dv' \`i'" + temploc1s + " if \`touse' & \`useob' [\`weight'\`exp']")
			
			if ((st_numscalar("c(rc)") == 0) & (cols(countcheck) > 1)) {
			
				if ((strlen(svy)) & !((mchaid_sc(st_local("test")) == .) | (mchaid_sc("df_m") == 0))) {
			
				
					current_p = Ftail(mchaid_sc("e(df_m)"), mchaid_sc("e(df_r)"), mchaid_sc(st_local("test")))
					
					stata("mchaid_getic, type(aicw) ll(1) parm(1) obs(1)")
								
					current_aic = st_numscalar("r(ic)")
					current_chi = mchaid_sc(st_local("test"))
			
				}
			
				else if (!(strlen(svy)) & !((mchaid_sc(st_local("test")) == .) | (mchaid_sc("df_m") == 0)) ///
				& !(rows(mchaid_rp()))) {
			
			
					current_p = chi2tail(mchaid_sc("e(df_m)"), mchaid_sc(st_local("test")))
					
					stata("mchaid_getic, type(aicc) ll(\`=e(ll)') parm(\`=e(df_m)') obs(\`=e(N)')")
								
					current_aic = st_numscalar("r(ic)")
					current_chi = mchaid_sc(st_local("test"))
				
				}
			
				else if (!(strlen(svy)) & (rows(mchaid_rp()))) {
				
					current_p = mchaid_rp()[1,1]
					current_chi = st_matrix("r(b)")[1, 1]								//before mchaid_getic, which replaces r()
					
					stata("mchaid_getic, type(aicc) ll(" + strofreal(st_matrix("r(b)")[1, 2]) + ///
					") parm(" + strofreal(st_matrix("r(b)")[1, 3]) + ") obs(" ///
					+ strofreal(st_matrix("r(b)")[1, 4]) + ")")
								
					current_aic = st_numscalar("r(ic)")
					
				}
			
				else {
				
					current_p = 1
					
					current_aic = .
					current_chi = .
					
				}
				
			}
			
			else {
			
				if ((st_numscalar("c(rc)") == 430) & (cols(countcheck) > 1) & (st_local("reg") == "ologit") & !strlen(svy) & (mchaid_sc("e(chi2)") < .)) {		//no convergence of ologit (perfect separation; before, p = 1): the test of the limit, from the last iteration

					mchdf = (selecttype[1] == "u" ? cols(countcheck) - 1 : 1)

					current_p = chi2tail(mchdf, mchaid_sc("e(chi2)"))

					current_aic = mchaid_aicc(mchaid_sc("e(ll)"), mchdf, mchaid_sc("e(N)"))
					current_chi = mchaid_sc("e(chi2)")

				}

				else {

					current_p = 1

					current_aic = .
					current_chi = .

				}
				
			}
			}
				
			st_dropvar(temploc1s)
			
			trraw = current_p

			if (cols(selectnames) < 2) adj_p = 1								//a variable with a single category in the node (an unordered variable already used above) cannot split it: its multiplier was 0, so its adjusted p-value was 0 and it won over all the others

			current_p = current_p*adj_p

			if (isforced & !forcemerge & (cols(selectnames) > 2) & (min((current_p, 1)) >= alpha3)) {			//forced and not significant: binary split
				forcemerge = 1
				if (strlen(steps)) mchaid_say("{txt}  The forced split is not significant (adjusted p = " + mchaid_pfmt(min((current_p, 1))) + " is not below spltalpha(" + strofreal(alpha3) + ")): merging continues until two groups remain")
				continue
			}

			if (strlen(steps)) {
				mchaid_say("{txt}  Splitting test: categories " + mchaid_catlist(selectnames, " | ") + ": p = " + mchaid_pfmt(trraw) + ", Bonferroni multiplier = " + strofreal(adj_p, "%9.4g") + ", adjusted p = {res}" + mchaid_pfmt(min((current_p, 1))))
				trrows = trrows \ (sprintf("%-14s", varsvec[position]) + sprintf("%-44s", mchaid_catlist(selectnames, " | ")) + sprintf("%9s", mchaid_pfmt(min((current_p, 1)))))
			}
				
			
		
			
		
			if (current_p < compare_p) {
		
		
				compare_p = current_p
		
				
				compare_aic = current_aic
				compare_chi = current_chi
				
			
				comparenames = selectnames 
			
				
				comparecount = countcheck
				
			
			}
		
			else if (current_p == compare_p) {	
		
				if (current_aic < compare_aic) {
				
		
					compare_p = current_p
		
					
					compare_aic = current_aic
					compare_chi = current_chi
				
			
					comparenames = selectnames 
			
				
					comparecount = countcheck
				
					
				}
					
				else if (current_aic == compare_aic) {							//equal p-values and equal AIC: the choice is random (before, it was random whenever the AIC of the new candidate was not lower)
				
					randresolve = runiform(1, 2)
			
					if (randresolve[1] < randresolve[2]) {
		
		
						compare_p = current_p
		
						
						compare_aic = current_aic
						compare_chi = current_chi
				
			
						comparenames = selectnames 
			
						
						comparecount = countcheck
						
						
					}
						
				}
		
			}
		
			position =  position + 1
		
		forcemerge = 0
		
		
		
	
			if (position == endpos + 1) {

				if (strlen(steps)) {
					mchaid_say("{txt}  Candidate variables for the split (adjusted p-values):")
					for (tri = 1; tri <= rows(trrows); tri++) mchaid_say("      " + trrows[tri])
					if (isforced & (cols(tokens(invtokens(comparenames))) <= 1)) mchaid_say("{txt}  -> the forced variable has fewer than two categories in the node, or they are all merged")
					else if (cols(tokens(invtokens(comparenames))) <= 1) mchaid_say("{txt}  -> no variable shows any association (adjusted p of 1 or more): the node is not split")
					else if (!isforced & !(compare_p < alpha3)) mchaid_say("{txt}  -> best adjusted p = " + mchaid_pfmt(min((compare_p, 1))) + " is not below spltalpha(" + strofreal(alpha3) + "): the node is not split")
					else if (min(comparecount) < minnode) mchaid_say("{txt}  -> the best split would create a node with n = " + strofreal(min(comparecount), "%12.0fc") + ", below minnode(" + strofreal(minnode) + "): the node is not split")
					else if ((maxbranch >= 0) & (branches[currentcluster] >= maxbranch)) mchaid_say("{txt}  -> maxbranch(" + strofreal(maxbranch) + ") reached: the node is not split")
					else {
						mchaid_say("{txt}  -> split on {res}" + mchaid_varof(comparenames[1]) + "{txt}" + (isforced ? " (forced)" : "") + " (adjusted p = " + mchaid_pfmt(min((compare_p, 1))) + "):")
						for (tri = 1; tri <= cols(comparenames); tri++) mchaid_say("        " + mchaid_grptext(comparenames[tri], 1) + "  (n = " + strofreal(comparecount[1, tri], "%12.0fc") + ")")
					}
					trrows = J(0, 1, "")
				}

		
				if ((cols(tokens(invtokens(comparenames))) > 1) & ((compare_p < alpha3) | isforced) & ///
				(min(comparecount) >= minnode) & ///
				((branches[currentcluster] < maxbranch) | (maxbranch < 0))){
		
					
					branches[currentcluster] = branches[currentcluster] + 1
					
					
					selectnames = (" ")
					
					for (x = 1; x <= cols(comparenames); x++) {
					
					
						selectnames = (selectnames, comparenames[x], ",")
					
					}
					
					
					if (branches[currentcluster] > cols(splits)) {

						splits = (splits, J(rows(splits), 1, ""))

						splitp = (splitp, J(rows(splitp), 1, .))
						splitchi = (splitchi, J(rows(splitchi), 1, .))
						splitfor = (splitfor, J(rows(splitfor), 1, 0))

					}

					splits[currentcluster, branches[currentcluster]] = comparenames[1]

					splitp[currentcluster, branches[currentcluster]] = min((compare_p, 1))
					splitchi[currentcluster, branches[currentcluster]] = compare_chi
					splitfor[currentcluster, branches[currentcluster]] = isforced
					
					
					CHAIDsplit = (CHAIDsplit, invtokens(selectnames))
					
					for (x = 2; x <= cols(comparenames); x++) {
					
						clustercount++
						
						
						branches = (branches, branches[currentcluster])
						
						
						splits = (splits \ splits[currentcluster, .])

						splitp = (splitp \ splitp[currentcluster, .])
						splitchi = (splitchi \ splitchi[currentcluster, .])
						splitfor = (splitfor \ splitfor[currentcluster, .])

						splits[clustercount, branches[clustercount]] = comparenames[x]
						
																		
						selectnames = tokens(comparenames[x])
					
						for (y = 1; y <= cols(selectnames); y++) {
							
				
							stata("replace \`cluster' = " + strofreal(clustercount)+ " if `" + ///
							selectnames[y] + "' & \`touse' & \`useob'")	//	
					
						}
					
					}
					
					position = 2
					
					comparenames = ("")
					
					compare_p = 1
					
					compare_aic = .
					compare_chi = .
				
				}
				
			else if (isforced) {														//the split forced at this level is not possible: the node grows freely, with all the variables
				if ((currentcluster == 1) & (branches[1] == 0)) _error(198, "forcevars(): the sample cannot be split by " + varsvec[endpos] + ": it has fewer than two categories, or they are all merged, or a node would have fewer than minnode(" + strofreal(minnode) + ") observations")
				nfb++
				if (nfb <= 3) fbtxt = fbtxt + (nfb > 1 ? "; " : "") + mchaid_path(splits[currentcluster, .], branches[currentcluster])
				if (strlen(steps)) mchaid_say("{txt}  -> the split forced by " + varsvec[endpos] + " is not possible: the node grows freely")
				fbflag = 1
				fbc = currentcluster
				fbb = branches[currentcluster]
				isforced = 0
				position = 2
				startpos = 0
				endpos = cols(varsvec)
				compare_p = 1
				compare_aic = .
				compare_chi = .
				comparenames = ("")
			}
				else {
				
					position = 2
				
					stata("replace \`stop'=0 if \`cluster' == " + strofreal(currentcluster))
					
					currentcluster++
				
					stata("summarize \`cluster'")
				
					if (st_numscalar("r(max)") < currentcluster) moresplit = 0
				
				
					compare_p = 1
					
					compare_aic = .
					compare_chi = .
					
					comparenames = ("")
						
				}
		
			}	
		
		}
	
	}
	
	/*number the final clusters in tree order: depth first, following the order of the categories of each split*/
	if (!strlen(norenum) & (rows(splits) > 1)) {
	
		rn_n = rows(splits)
		
		rn_b = cols(splits)
		
		rn_P = J(rn_n, rn_b, "")
		
		for (rn_i = 1; rn_i <= rn_n; rn_i++) {
		
			rn_pre = ""
			
			for (rn_d = 1; rn_d <= rn_b; rn_d++) {
			
				if (splits[rn_i, rn_d] == "") break
				
				rn_pre = rn_pre + "|" + splits[rn_i, rn_d]
				
				rn_P[rn_i, rn_d] = rn_pre
			
			}
		
		}
		
		rn_key = J(rn_n, rn_b, .)																			//position of the lowest category of each branch in the original list of categories: branches are ordered by their lowest category
		
		rn_all = tokens(subinstr(subinstr(names, "(", ""), ")", ""))
		
		for (rn_i = 1; rn_i <= rn_n; rn_i++) {
		
			for (rn_d = 1; rn_d <= rn_b; rn_d++) {
			
				if (splits[rn_i, rn_d] == "") break
				
				rn_tok = tokens(splits[rn_i, rn_d])
				
				for (rn_j = 1; rn_j <= cols(rn_tok); rn_j++) {
				
					rn_pos = select(1..cols(rn_all), rn_all:== rn_tok[rn_j])
					
					if (cols(rn_pos) > 0) rn_key[rn_i, rn_d] = min((rn_key[rn_i, rn_d], rn_pos[1]))
				
				}
			
			}
		
		}
		
		rn_R = J(rn_n, rn_b, 0)
		
		for (rn_i = 1; rn_i <= rn_n; rn_i++) {
		
			for (rn_d = 1; rn_d <= rn_b; rn_d++) {
			
				if (rn_P[rn_i, rn_d] == "") break
				
				if (rn_d == 1) rn_par = ""
				
				else rn_par = rn_P[rn_i, rn_d - 1]
				
				rn_sib = J(0, 1, .)
				
				for (rn_j = 1; rn_j <= rn_n; rn_j++) {
				
					if (rn_P[rn_j, rn_d] != "") {
					
						if (rn_d == 1) rn_sib = rn_sib \ rn_key[rn_j, rn_d]
						
							else if (rn_P[rn_j, rn_d - 1] == rn_par) rn_sib = rn_sib \ rn_key[rn_j, rn_d]
					
					}
				
				}
				
				rn_sib = uniqrows(rn_sib)
				
				rn_R[rn_i, rn_d] = sum(rn_sib:< rn_key[rn_i, rn_d]) + 1
			
			}
		
		}
		
		rn_p = order(rn_R, 1..rn_b)																			//rn_p[k] is the creation number of the cluster that will be numbered k
		
		rn_newid = J(rn_n, 1, .)
		
		rn_newid[rn_p] = 1::rn_n
		
		rn_cl = st_data(., st_local("cluster"))
		
		rn_idx = select(1::rows(rn_cl), rn_cl:< .)
		
		if (rn_n > 100) stata("quietly recast int " + st_local("cluster"))
		
		st_store(rn_idx, st_local("cluster"), rn_newid[rn_cl[rn_idx]])
		
		splits = splits[rn_p, .]

		splitp = splitp[rn_p, .]
		splitchi = splitchi[rn_p, .]
		splitfor = splitfor[rn_p, .]
		
		branches = branches[1, rn_p']
	
	}
	
	currentcluster = 0
	
	for (x = 1; x <= rows(splits); x++) {
	
		currentcluster++
		
		if (cols(CHAIDsplit) > 1) CHAIDsplit = (CHAIDsplit \ ("path" + strofreal(currentcluster), splits[x, .], J(1, cols(CHAIDsplit)-cols(splits)-1, "")))
	
	}
	
	branchmat = st_tempname()
	
	st_matrix(branchmat, branches)
	
	st_local("branchmat", branchmat)

	splitpmat = st_tempname()

	st_matrix(splitpmat, splitp)

	st_local("splitpmat", splitpmat)
	splitchimat = st_tempname()
	st_matrix(splitchimat, splitchi)
	st_local("splitchimat", splitchimat)
	splitformat = st_tempname()
	st_matrix(splitformat, splitfor)
	st_local("splitformat", splitformat)
	st_local("forcefb", strofreal(nfb))
	st_local("forcefbtxt", fbtxt)
	
	
	return(CHAIDsplit)

}  

end

version 12.1

mata:

mata set matastrict on

string rowvector mchaidsplit(string rowvector selectnames, real rowvector withinselect, string scalar type, ///
real scalar cutalpha, string scalar svy, real scalar match_p)
{
	string scalar trysplit, tploc1s, tploc2s
	
	real scalar count, float_miss
	
	real rowvector selectsplit, tploc1, tploc2, mg_ps, mg_aic, repeats
	
	real colvector  base, combin
	
	string rowvector splitvec, namesplit, comparevec
	
	real matrix unordmat
	
	transmorphic basis
	

	if (type == "o") {
	
		trysplit = select(selectnames, withinselect[1..cols(withinselect) - 1])
		
		trysplit = trysplit[1]
		
		float_miss = rowsum(strmatch(substr(tokens(trysplit), -2), "ms"))
		
	}
	
	else if (type == "u") trysplit = selectnames[1]
		
	
	
	splitvec = ("")
	
	mg_ps = (.)
	
	mg_aic = (.)
		
	if (cols(tokens(trysplit)) > 2) {
	
		namesplit = tokens(invtokens(trysplit))
		
		
		if (float_miss == 1) {
		
			namesplit = (select(namesplit, abs(strmatch(substr(namesplit, -2), "ms")):-1), ///
			select(namesplit, strmatch(substr(namesplit, -2), "ms")))
			
		
		}
		
		if (type == "u") {
		
			repeats = 2^(cols(tokens(trysplit))) - 2
			
			unordmat = J(1, cols(tokens(trysplit)), .)
			
			for (x = 1; x <= cols(tokens(trysplit)); x++) {

				base = J(x, 1, 1)
	
				base = (base \ J(cols(tokens(trysplit)) - x, 1, 0))
	
				basis = cvpermutesetup(base)
	
				for (y = 1; y <= comb(cols(tokens(trysplit)), x); y++) {
	
					combin = cvpermute(basis)
		
					unordmat = (unordmat \ combin')
		
				}
	
			}
			
			unordmat = unordmat[2..rows(unordmat)-1, .]
			
			
		}
		
		else if (type == "o") {
		
			repeats = cols(tokens(trysplit)) - 1
			
			if (float_miss == 1) repeats = repeats*2 - 1
			
		}
		
		
		count = 1
		
		while (count <= repeats) {
			
			if (type == "u") {
				
				selectsplit = unordmat[count, .]
				
			}
			
			else if (type == "o") {
			
				if (count <= cols(namesplit) - 1) selectsplit = (J(1, count, 1), J(1, cols(namesplit) - count, 0))
				
				else if (count > cols(namesplit) - 1) {
				
					selectsplit = (J(1, count - (cols(namesplit) - 1), 1), ///
					J(1, cols(namesplit) - 1 - (count - (cols(namesplit) - 1)), 0), 1)
				
				}
			
			}
	
				
			splitvec = (splitvec, invtokens(strofreal(selectsplit)))						//create string vector indicating position of variables to test
				
				
			comparevec = select(namesplit, selectsplit)										//proceed to select 2 columns of predictor to evaluate for potentially collapsing
				
				
			tploc1 = st_addvar("byte", st_tempname())
					
			tploc1s = st_varname(tploc1)
						
			stata("replace " + tploc1s + "=0")
					
			for (y = 1; y <= cols(comparevec); y++) {
						
				stata("replace " + tploc1s + "=`" ///
				+ comparevec[y] + "' + " + tploc1s)
								
			}
					
			comparevec = select(namesplit, abs(selectsplit:-1))
			
					
			tploc2 = st_addvar("byte", st_tempname())
					
			tploc2s = st_varname(tploc2)
						
			stata("replace " + tploc2s + "=0")
					
			for (y = 1; y <= cols(comparevec); y++) {
						
				stata("replace " + tploc2s + "=`" ///
				+ comparevec[y] + "' + " + tploc2s)
								
			}
					
						 
			
			if (strlen(svy)) stata("capture svy, subpop(if \`touse' & \`useob' & (" + tploc1s + " | " + ///
			tploc2s + ")): \`reg' \`dv' " + tploc1s)
			
			else stata("capture \`permute'\`reg' \`dv' " + tploc1s + ///
			" if \`touse' & \`useob' & (" + tploc1s + " | " + tploc2s + ") [\`weight'\`exp']")
						
			if ((st_numscalar("c(rc)") == 0)) {
						
				if ((strlen(svy)) & !((mchaid_sc(st_local("test")) == .) | (mchaid_sc("df_m") == 0))) {
						
							
					mg_ps = (mg_ps, Ftail(mchaid_sc("e(df_m)"), ///
					mchaid_sc("e(df_r)"), mchaid_sc(st_local("test"))))
					
					stata("mchaid_getic, type(aicw) ll(1) parm(1) obs(1)")
								
					mg_aic = (mg_aic, st_numscalar("r(ic)"))
						
				}
							
				else if (!(strlen(svy)) & !((mchaid_sc(st_local("test")) == .) | (mchaid_sc("df_m") == 0)) & ///
				!(rows(mchaid_rp()))) {
					
						
					mg_ps = (mg_ps, chi2tail(mchaid_sc("e(df_m)"), ///
					mchaid_sc(st_local("test"))))
					
					stata("mchaid_getic, type(aicc) ll(\`=e(ll)') parm(\`=e(df_m)') obs(\`=e(N)')")
								
					mg_aic = (mg_aic, st_numscalar("r(ic)"))
						
				}
							
											
				else if (!(strlen(svy)) & (rows(mchaid_rp()))) {
				
					mg_ps = (mg_ps, mchaid_rp()[1,1])
					
					stata("mchaid_getic, type(aicc) ll(" + strofreal(st_matrix("r(b)")[1, 2]) + ///
					") parm(" + strofreal(st_matrix("r(b)")[1, 3]) + ") obs(" ///
					+ strofreal(st_matrix("r(b)")[1, 4]) + ")")
								
					mg_aic = (mg_aic, st_numscalar("r(ic)"))
					
				}
					
				else {
				
					mg_ps = (mg_ps, 1)
					
					mg_aic = (mg_aic, .)
					
				}
							
			}
						
			else {
			
				mg_ps = (mg_ps, 1)
				
				mg_aic = (mg_aic, .)
				
			}
						
			st_dropvar((tploc1s, tploc2s))
			
			count++
				
		}
		
		if ((min(mg_ps) < cutalpha) & (min(mg_ps) < match_p)) {
			
			mg_aic = mg_aic[2..cols(mg_aic)]

			mg_ps = mg_ps[2..cols(mg_ps)]

			mg_ps = (mg_ps:== min(mg_ps))
			
				
			if (rowsum(mg_ps) > 1) {
			
				mg_ps = mg_ps:*(mg_aic:== min(select(mg_aic, mg_ps)))
			
				
				if (rowsum(mg_ps) > 1) {
			
					randresolve = runiform(1, cols(mg_ps)):*mg_ps
				
					mg_ps = (randresolve:== max(randresolve))
								
					
				}
	
			}
				
			trysplit = (invtokens(select(namesplit, strtoreal(tokens(select(splitvec[2..cols(splitvec)], mg_ps))))), ///
			invtokens(select(namesplit, abs(strtoreal(tokens(select(splitvec[2..cols(splitvec)], mg_ps))):-1))))
			
		
			if (type == "u") selectnames = (trysplit, selectnames[2..cols(selectnames)])
		
			else if (type == "o") {
		
				if (withinselect[1] == 1) selectnames = (trysplit, selectnames[2..cols(selectnames)])
			
				else if (withinselect[cols(withinselect)-1] == 1) selectnames = (selectnames[1..cols(selectnames)-1], trysplit)
			
				else {
			
					count = (strpos(invtokens(strofreal(withinselect)), "1") + 1)/2
					
				
					selectnames = (selectnames[1..count-1], trysplit, selectnames[count..cols(selectnames)])
			
				}
				
				if (rowsum(strmatch(substr(selectnames, -2), "ms")) == 1) {
				
					if (cols(tokens((select(selectnames, strmatch(substr(selectnames, -2), "ms")))))) {
					
						selectnames = (select(selectnames, abs(strmatch(substr(selectnames, -2), "ms")):-1), ///
						select(selectnames, strmatch(substr(selectnames, -2), "ms")))
					
					}
					
				}				
				
			}
			
		}
		
	}
	
	
	return(selectnames)

}

end

/*Mata functions for the fast path: likelihood-ratio tests from cross-tabulations*/
version 12.1

mata:

mata set matastrict on

//option quartiles typed without argument (quartiles or quartiles()) means quartiles(auto); only the options of the command (after the first comma outside of parentheses) are looked at, and only at the first level, so names of variables are not touched
string scalar mchaid_qnorm(string scalar s)
{
	real scalar i, n, depth, inq, p, j, k, m
	
	string scalar c, w, out, pre, post, q
	
	q = "quartiles"
	
	n = strlen(s)
	
	depth = 0
	
	inq = 0
	
	p = 0
	
	for (i = 1; i <= n; i++) {													//first comma outside of quotes and parentheses
	
		c = substr(s, i, 1)
		
		if (c == char(34)) inq = !inq
		
		else if (!inq) {
		
			if (c == "(") depth++
			
			else if (c == ")") depth--
			
			else if ((c == ",") & (depth == 0)) {
			
				p = i
				
				break
			
			}
		
		}
	
	}
	
	if (p == 0) return(s)
	
	pre = substr(s, 1, p)
	
	post = substr(s, p + 1, .)
	
	n = strlen(post)
	
	out = ""
	
	depth = 0
	
	inq = 0
	
	i = 1
	
	while (i <= n) {
	
		c = substr(post, i, 1)
		
		if (c == char(34)) {
		
			inq = !inq
			
			out = out + c
			
			i++
			
			continue
		
		}
		
		if (inq) {
		
			out = out + c
			
			i++
			
			continue
		
		}
		
		if (c == "(") depth++
		
		if (c == ")") depth--
		
		if ((depth == 0) & (regexm(c, "[A-Za-z_]")) & ((i == 1) | (!regexm(substr(post, i - 1, 1), "[A-Za-z0-9_]")))) {		//a word of the first level
		
			j = i
			
			while ((j <= n) & regexm(substr(post, j, 1), "[A-Za-z0-9_]")) j++
			
			w = substr(post, i, j - i)
			
			if ((strlen(w) >= 4) & (strlen(w) <= 9) & (strlower(w) == substr(q, 1, strlen(w)))) {
			
				k = j
				
				while ((k <= n) & (substr(post, k, 1) == " ")) k++
				
				if (substr(post, k, 1) == "(") {
				
					m = k + 1
					
					while ((m <= n) & (substr(post, m, 1) == " ")) m++
					
					if (substr(post, m, 1) == ")") {									//quartiles()
					
						out = out + w + "(auto)"
						
						i = m + 1
						
						continue
					
					}
				
				}
				
				else {																	//quartiles without parentheses
				
					out = out + w + "(auto)"
					
					i = j
					
					continue
				
				}
			
			}
			
			out = out + w
			
			i = j
			
			continue
		
		}
		
		out = out + c
		
		i++
	
	}
	
	return(pre + out)
}
//numeric scalar from Stata, or missing when it does not exist (st_numscalar() then returns an empty matrix)
real scalar mchaid_sc(string scalar name)
{
	real matrix val
	
	val = st_numscalar(name)
	
	if ((rows(val) != 1) | (cols(val) != 1)) return(.)
	
	return(val)
}
//p-values of permute: Stata 16 and later store them in r(p_upper) (upper tail: the larger the statistic, the stronger the association), older versions in r(p)
real matrix mchaid_rp()
{
	real matrix p
	
	p = st_matrix("r(p_upper)")
	
	if (rows(p) == 0) p = st_matrix("r(p)")
	
	return(p)
}
//indicator (0/1) of membership in a set of merged categories
real colvector mchaid_grp(real matrix bin, string rowvector allnames, string rowvector toks)
{
	real colvector g
	
	real scalar i
	
	g = J(rows(bin), 1, 0)
	
	for (i = 1; i <= cols(toks); i++) g = g + bin[., select(1..cols(allnames), allnames:== toks[i])]
	
	return(g)
}

//sum of n*ln(n/N) skipping empty cells
real scalar mchaid_nlogn(real rowvector n, real scalar N)
{
	real rowvector pos
	
	pos = select(n, n:> 0)
	
	return(sum(pos:*ln(pos:/N)))
}

//small-sample corrected AIC (AICc) as in mchaid_getic
real scalar mchaid_aicc(real scalar ll, real scalar parm, real scalar obs)
{
	return(-2*ll + 2*parm + 2*parm*(parm + 1)/(obs - parm - 1))
}

//p-value and AIC for the comparison of two groups of categories (dummy g1 versus g2) on the response; same as mlogit
real rowvector mchaid_lr2(real matrix D, real colvector w, real colvector g1, real colvector g2)
{
	real rowvector n1, n2, keep
	
	real scalar N1, N2, J, ll, ll0, chi2, df
	
	n1 = (w:*g1)'*D
	
	n2 = (w:*g2)'*D
	
	keep = (n1:+ n2):> 0
	
	n1 = select(n1, keep)
	
	n2 = select(n2, keep)
	
	J = cols(n1)
	
	N1 = sum(n1)
	
	N2 = sum(n2)
	
	if ((J < 2) | (N1 == 0) | (N2 == 0)) return((1, .))
	
	ll = mchaid_nlogn(n1, N1) + mchaid_nlogn(n2, N2)
	
	ll0 = mchaid_nlogn(n1:+ n2, N1 + N2)
	
	chi2 = max((2*(ll - ll0), 0))
	
	df = J - 1
	
	return((chi2tail(df, chi2), mchaid_aicc(ll, df, N1 + N2)))
}

//p-value and AIC for a response by a multi-group splitting variable (dummy-coded in mlogit)
real rowvector mchaid_lrk(real matrix D, real colvector w, real colvector grp)
{
	real matrix n
	
	real rowvector keep
	
	real colvector lev, ng
	
	real scalar i, m, J, N, ll, ll0, chi2, df
	
	lev = uniqrows(grp)
	
	n = J(rows(lev), cols(D), 0)
	
	for (i = 1; i <= rows(lev); i++) n[i, .] = (w:*(grp:== lev[i]))'*D
	
	n = select(n, rowsum(n):> 0)
	
	keep = colsum(n):> 0
	
	n = select(n, keep)
	
	m = rows(n)
	
	J = cols(n)
	
	if ((m < 2) | (J < 2)) return((1, ., .))
	
	N = sum(n)
	
	ll = 0
	
	for (i = 1; i <= m; i++) ll = ll + mchaid_nlogn(n[i, .], sum(n[i, .]))
	
	ll0 = mchaid_nlogn(colsum(n), N)
	
	chi2 = max((2*(ll - ll0), 0))
	
	df = (m - 1)*(J - 1)
	
	return((chi2tail(df, chi2), mchaid_aicc(ll, df, N), chi2))
}

//p-value and AIC for the response by a numeric score (the group code) entered as one linear term; same as mlogit dv score
real rowvector mchaid_lrt(real matrix D, real colvector w, real colvector grp)
{
	real matrix n, X, full, logp, p, H, Hjk
	
	real colvector lev, Ng, g, step, theta, theta2, s
	
	real rowvector lse
	
	real scalar i, j, k, m, J, K, N, ll, ll0, ll2, chi2, iter, halve
	
	lev = uniqrows(grp)
	
	n = J(rows(lev), cols(D), 0)
	
	for (i = 1; i <= rows(lev); i++) n[i, .] = (w:*(grp:== lev[i]))'*D
	
	s = select(lev, rowsum(n):> 0)
	
	n = select(n, rowsum(n):> 0)
	
	n = select(n, colsum(n):> 0)
	
	m = rows(n)
	
	J = cols(n)
	
	if ((m < 2) | (J < 2)) return((1, ., .))
	
	N = sum(n)
	
	Ng = rowsum(n)
	
	K = J - 1
	
	ll0 = mchaid_nlogn(colsum(n), N)
	
	X = (J(m, 1, 1), s)
	
	theta = J(2*K, 1, 0)
	
	for (j = 1; j <= K; j++) theta[2*j - 1] = ln(sum(n[., j + 1])/sum(n[., 1]))
	
	ll = .
	
	for (iter = 1; iter <= 100; iter++) {
	
		full = (J(m, 1, 0), X*colshape(theta, 2)')
		
		logp = full :- ln(rowsum(exp(full)))
		
		if (ll == .) ll = sum(n:*logp)
		
		p = exp(logp)
		
		g = J(2*K, 1, 0)
		
		H = J(2*K, 2*K, 0)
		
		for (j = 1; j <= K; j++) {
		
			g[(2*j - 1)::(2*j)] = X'*(n[., j + 1] - Ng:*p[., j + 1])
			
			for (k = 1; k <= K; k++) {
			
				Hjk = -X'*((Ng:*((j == k)*p[., j + 1] - p[., j + 1]:*p[., k + 1])):*X)
				
				H[(2*j - 1)::(2*j), (2*k - 1)::(2*k)] = Hjk
			
			}
		
		}
		
		step = invsym(-H)*g
		
		halve = 0
		
		while (1) {
		
			theta2 = theta + step
			
			full = (J(m, 1, 0), X*colshape(theta2, 2)')
			
			ll2 = sum(n:*(full :- ln(rowsum(exp(full)))))
			
			if ((ll2 >= ll - 1e-12) | (++halve > 30)) break
			
			step = step/2
		
		}
		
		if (ll2 < ll) break
		
		theta = theta2
		
		if (abs(ll2 - ll) < 1e-10*(1 + abs(ll))) {
		
			ll = ll2
			
			break
		
		}
		
		ll = ll2
	
	}
	
	chi2 = max((2*(ll - ll0), 0))
	
	return((chi2tail(K, chi2), mchaid_aicc(ll, K, N), chi2))
}
end
//program to obtain information criteria
program define mchaid_getic, rclass

syntax, type(string) ll(real) parm(integer) obs(integer)

if ("`type'" == "aicc") return scalar ic = -2*`ll'+2*`parm'+2*`parm'*(`parm' + 1)/(`obs' - `parm' - 1)

else if ("`type'" == "aicw") {

	tempname ilog gdeff
	
	matrix `ilog' = e(ilog)
	
	mata: ilog = select(st_matrix("`ilog'"), abs(sign(st_matrix("`ilog'"))))
	
	mata: st_matrix("`ilog'", ilog[1, cols(ilog)])
	
	matrix `gdeff' = trace(invsym(e(V_srs))*e(V))
	
	return scalar ic = -2*`ilog'[1,1]*(e(N)/e(N_pop))+2*`gdeff'[1,1]

}

else exit 198

end

/* programming notes and history

- chaid version 1.0 - date - November 18, 2013

Basic version

-----

- chaid version 1.1 - date - March 20, 2014

//notable changes\\
a] added frequency weights
b] updated display to highlight hierarchical tree-structure using Mata matrix and fix errors with original display
c] implemented the remerge process as an option
d] allowed a no Bonferroni adjustment option
e] fixed merging inaccuracy that excluded categories arbitrarily
f] error returning an extra "root" fixed
g] predicted value offered based on mode of node
h] additional returned values
i] updated helpfile - going over collapse option to expedite chaid fitting

-----

- chaid version 2.0 - date - August 22, 2014

//notable changes\\
a] added permutation-based p-values
b] added svy prefix compatability
c] added graphical depiction to display output
d] added accessible mata matrices
e] now can "replay" chaid results again as with other Stata programs
f] added permutation importance metric
g] fixed N-obs issue w/ fweights
h] added fit metric based on cramer's V (and svy compatible version with similar properties)
i] fixed Q1 Q11 nested variable selection issue - also allows to predict itself (dv and iv, though non-sensical, no more error)
j] added exhaustive CHAID algorithm
k] convenience command allows user to "xtile" for continuous predictors

-----

- chaid version 2.1 - date - December 16, 2014

//notable changes\\
a] fixed missing colon for svy with respalpha
b] moved location of bonferroni adjustment (doesn't require "exhaust" or there to have been a merge implemented to compute it) 
	to ensure no missing adjusted p-value
c] use aic for between model comparisons to decide on splitting (p-value has numerical precision issues... just use it to meet 
	the p<.05 threshold and that's it)
d] fix importance w/ missing (extra space added to "ifstmnts" for missings erroneously that was turned into comma
e] fix DV levels check that occurs before markout

-----

- chaid version 2.2 - date - February 12, 2015

//notable changes\\
a] fixed Bonferroni adjustment (was not invoked unless noadj option was used) - had opposite behavior as intended
b] fixed but which prevented splits on splitting variables with a single level

-----

- mchaid version 1.0.0 - 24/11/2026, first release at SSC (numbered 2.3 in the development, after chaid 2.2) - changes since chaid 2.2, from 19/10/2026

//notable changes\\
a] the graph writes the (Bonferroni-adjusted) p-value of each split in the middle of the line from the box of the splitting variable to the line of its categories;
	options nopval (no p-values) and pcut(#) (p<# below the cut), both accepted by mchaid, by graphopts() and in the replay; the p-values are stored in e(splitp)
b] last line of the graph: risk estimate (misclassified proportion with the modal category of each node; in parentheses, that of the root node) and Cramer's V
c] fixed: with the missing option only the first split of the tree was made (in the nodes below the root the table of counts of the groups of a split included the cases outside
	the node as an extra group with 0 cases, so min(comparecount) was 0 and the split was rejected by minnode); comparecount now keeps only the row of the cases of the node.
	The same code is in chaid 2.2

d] new option language(): texts of the graph in en (default), es, fr, de, it, pt (po), ca, gl, nl or eu (program mchaid_lang; only the graph is translated)

e] new postestimation command: estat classification (classification table of the cases in the modal category of their node; r(class), r(risk), ...).
	It needs the file mchaid_estat.ado (the programs of an ado-file are not visible from the others): it calls mchaid with the hidden option mchaidclassif

f] estat classification also gives, for each category versus the rest, sensitivity, specificity, PPV and NPV, and with positive(category) the full list of statistics of estat classification after logit; r(stats)

g] F1 score of each category in estat classification (2*PPV*sensitivity/(PPV+sensitivity)), its macro and weighted averages (r(f1_macro), r(f1_weighted)) and column f1 of r(stats)

h] fixed: option permute found no splits at all (it did not work in chaid 2.2 either, which stops with an error): since Stata 16 permute stores its p-values in r(p_upper), r(p_lower) and r(p_twosided) and no longer in r(p).
	The upper tail is now used (large chi2 = association), like the tail of the parametric tests; program mchaid_rp() falls back to r(p) in older Stata versions

i] with dvordered and the new option quartiles(auto|all) the graph draws, over the bar of each final node, a red line at the median (the second quartile) of that node and, when the response variable has 5 categories or more,
	dotted red lines at the quartiles Q1 and Q3. Without the option quartiles() no line is drawn. The height of a line is the VALUE of the percentile on the scale of the categories, not the position of the segment where it falls:
	the bar is divided in as many equal bands as categories (the first category at the bottom) and the percentile is interpolated inside the category where the cumulative percentage reaches 25, 50 or 75%
	((category - 1 + (p - cumulative percentage before it)/its percentage)/number of categories), so a node with more cases in the high categories has its lines higher, whatever the size of its segments.
	quartiles and quartiles() (without argument) mean quartiles(auto) (mchaid_qnorm, which rewrites the line typed by the user; names of variables are not touched).
	Option quartiles(auto|all), accepted by mchaid, by graphopts() and in the replay: with auto (default), in a node where a quartile is less than 0.07 inches (of the graph) from the median, so that they could not be told apart
	(nearly all the cases in one category), only the median is drawn; with all the median and both quartiles are always drawn and the quartile lines are thinner.
	Lines that coincide are drawn once (the median goes first). Legend entries "Median" (translated in all the languages) and "Q1, Q3".
	The lines are interrupted around the percentages written inside the bars (not when nopct is used) so that the numbers can be read.
	The width of the graph now also takes into account the width of the legend. mchaid_tree() has a new matrix for the lines (4th argument)

j] boxes of the splits (the root included): n on the first line and the splitting variable on the second; the final nodes keep the number of the node on the first line and n below

k] output: the tree branches and the definitions of the nodes are no longer shown by default: options branches and definitions (accepted in the estimation and in the replay; e(showbranches), e(showdefinitions));
	the table of the response by node is always shown, and below it the risk estimate (in parentheses, that of the root node), as in the graph, before the tests of association

l] fixed: after splitting a node with an unordered variable, that variable remained in the children with a single category; its Bonferroni multiplier was 0, so its adjusted p-value was 0 and it won over all
	the other variables: the children were never split (trees with an unordered variable at the first level stopped there). A variable with fewer than 2 categories in the node is no longer a candidate

m] fixed: with svy or permute the unordered splitting variables could not be tested (xi: cannot be used inside permute, and version 10: does not allow factor variables): they are tested with factor variables (i.)

n] fixed: with equal p-values the split was chosen at random whenever the AIC of the new candidate was not lower; now only when the AIC is also equal (the same command gave different trees)

o] a tree with too many nodes for a Stata graph (error 1003, too many options) gives a clear message recommending nograph, a lower maxbranch() or a higher minnode()/minsplit(), and the output continues

p] fixed: the Bonferroni multiplier of the unordered splitting variables (the number of ways of merging the categories into g groups, a Stirling number of the second kind) left out the last term of its sum (the loop stopped at g - 1 instead of g):
	it was S(C, g) - (-1)^(g-1)/(g-1)! (2^(C-1) instead of 2^(C-1) - 1 for 2 groups; 0.5 instead of 1 for C = g = 3). Trees can change near the limit of spltalpha(); chaid 2.2 has the same error
q] fixed: with dvordered the merging tests were run with version 10: ologit, which stops with r(430) when two groups of categories are completely separated on the response; the pair then got p = 1 and was merged first.
	"version 10:" was removed from the estimation commands of the merging and re-splitting tests (ologit converges, with the note that some observations are completely determined, and the pair is correctly kept apart)
	When two groups of categories are completely separated on the response, ologit does not converge even without it (r(430), after seconds of iterations): the tests then use the limit of the likelihood-ratio statistic (the one that ologit leaves in e(chi2), or, when the ranges of the response of the two groups do not overlap, the one computed without the iterations from the response within each group) instead of p = 1 (not with svy)

r] new option treestyle(classic|boxes) of the graph (accepted by mchaid, by graphopts() and in the replay). boxes: every node of the tree (the root and the intermediate ones too) is a box with its name, n (and % of the cases) and a horizontal bar
	with the distribution of the response variable; under the nodes that are split the splitting variable (its variable label) and "chi2 = x; p < y"; on the branches, in boxes, the categories; under the final nodes the predicted category in its colour;
	legend with the label of the response variable and "(% within each node)". The nodes are numbered as in SPSS (root 0, level by level, from left to right), not as in e(sizes). Numbers with the separators of language(). mchaid_tree2() calculates it
	and mchaid_tree2put() writes the dataset of the graph: the texts are points with a label (scatter, mlabel), not text() options, so the graph does not hit the limit of options (error 1003) of the classic one. Texts in mchaid_lang: legend, pred
	(ca, gl, nl and eu translations to be reviewed by native speakers, as the rest of them)
s] the test statistic of every split is kept in the new matrix e(splitchi) (same layout as e(splitp); likelihood-ratio chi2 from mchaid_lrk()/mchaid_lrt(), which now return it as third element, or from mlogit/ologit; F with svy; with permute the statistic of
	the data) and e(splitstat) is chi2 or F

t] new options nodeplot(bar|box), whisker(p5|minmax|tukey) and noshade of the style of boxes (also in graphopts() and the replay). nodeplot(box), only with dvordered: in the box of each node a box plot of the response on the scale of its categories
	(category j is the band j-1 to j; percentiles interpolated as in quartiles(): mchaid_pcat()), with the median category under the size, a dashed line at the overall median, colour above (blue) / below (orange) it, stronger the more standard deviations
	(of the scale of the categories) away, and a scale under the tree with the first and the last category. The final nodes keep Pred.: (modal category). Texts in mchaid_lang: overallmed, above, below, minmax, iqr (ca, gl, nl and eu to be reviewed by native speakers)

u] nodeplot(box): the line of the overall median is red, thin and sticks out of the boxes (as in maid)
v] fixed: the graph of the style of boxes wrote in the output a table with the numbers of the variables created (st_addvar() returns their indices); now (void) st_addvar()
w] classic graph: before the p-value of each split the test statistic is written (chi2=2131; p<0.001; F with svy), kept since item s] in e(splitchi); nopval removes both
x] 2026-11-06: the median is GREEN (0 158 115, Okabe-Ito) instead of red in the graphs, as in the interactive tree: the line of the overall median of the box plots (treestyle(boxes)) and the median and quartiles over the bars of the classic graph (quartiles()). The red was confused with the orange of "below"
y] 2026-11-06: new options nodehead(category|number) and rootlabel(total|depvar|text) of the style of boxes (also in graphopts() and the replay). nodehead(category), the default, writes in the heading of each box the category (or interval) of the splitting variable that forms the node, which the branches carried before; the branches have no labels (the line goes straight to the box), the number of the node goes in a small square on the top left corner of the box and the root says Total (translated; rootlabel(depvar) writes the label of the response variable, any other text is used as it is). A long heading is written with a smaller letter, in two lines or cut with ...; the long Pred.: under the leaves is cut so that it does not touch the next one (also with nodehead(number), the previous design). New language key total (mchaid_lang), kinds 41-44 and 50 of text and 6 of rectangle in the dataset of the graph, mchaid_cut() and mchaid_fithead()
z] 2026-11-08: new option colors() of the graph (also in graphopts() and the replay): the colours of the categories of the response variable, by name, colors(White=navy Black="230 159 0" Other=#009E73), or one for each category in the order of the legend; a colour is a Stata colour name, "R G B" or #RRGGBB. Names are the labels of the categories (case-insensitive); the categories without colour keep the default one and the unknown names are ignored, with a note. New programs mchaid_rgb (colour to RGB: the names are read from the style files color-name.style of Stata), mchaid_cvalid (check at estimation), mchaid_setcolors (assignment at the graph) and the Mata functions mchaid_cparse() and mchaid_unwrap(). The labels over the bars choose white or black from the luminance of each colour, as before
aa] 2026-11-08: colors(colour, ramp [reverse]): one shade of a single colour for each category, mixed with white from 20% to 100% of the colour, from light (first category) to dark (last one); reverse inverts the order. Handled in mchaid_cparse() (the part after the comma, outside quotes) and mchaid_setcolors(). maid has the same parser but refuses ramp
ab] 2026-11-08: new option forcevars(varlist): the first levels of the tree are chosen by the user: forcevars(v1 v2 ...) splits the sample by v1 and every node of the next level by v2, and so on, and below them the tree grows as usual. In the Mata loop the forced variable is the only candidate (position = fpos[branches + 1], endpos = position; compare_p starts as missing so that its adjusted p-value is taken even above 1) and the node is split whatever the adjusted p-value; if it is not below spltalpha() and more than two groups remain, the variable is processed again with forcemerge = 1 (the merging goes on as in exhaustive CHAID, with no re-splitting) so that the split is binary. If the forced split is not possible (fewer than two categories, all merged, a node below minnode()) the root gives an error (also when it is pure or has no more than minsplit() cases) and a deeper node grows freely (fbflag, fbc, fbb: it is processed again with all the variables) with a note with the number of nodes. maxbranch() cannot be smaller than the number of variables; xtile() variables can be named by their original name or xt... New e(forcevars) and e(splitforced) (1 where the variable of the split was forced, same layout as e(splitp)). Mata evaluates both sides of & : branches[] must not be read beyond the last cluster (fbskip). Validated against the R package (mchaid 0.6.0) node by node in 14 configurations of mchaid and 8 of maid (nofast, dvordered, ordered variables, anova, non significant forced variable, fallback). svy and permute run but were not compared. The graphs mark the forced variables: an asterisk after the splitting variable in the style of boxes (a dagger in the classic graph, where the asterisk is the modal category) and a note at the bottom, new language key forced (10 languages; ca, gl, nl and eu to be reviewed) and t_dagger; mchaid_isf(), mchaid_tree() and mchaid_tree2() read e(splitforced)
ac] 2026-11-08: bug fix: mchaid, importance (replay) gave 'The graph could not be drawn (error r(198))' because importance was passed to the graph as an unknown option, and the error message itself was badly written (string() inside display with +). importance is now accepted in the replay: if e(importance) does not exist the estimation is run again with the stored command line plus importance (the permutations are random, so the values may change slightly), and if it exists it is shown as always
ad] 2026-11-08: new, interactive tree: the tree can be written as an interactive HTML page: options directory(folder), collapse(#) and noopen (also in graphopts() and the replay; e(graphopts)). The page is the one of the R package (tree_html()): the same inst/www files (tree.js, tree.css, d3.min.js; the sync script is arbol_html/sync_stata_assets.py) with the data as JSON inside index.html. The JSON is built at the end of the node computations of tree2 (the boxes graph) from the same arrays (tree, numbering, texts, percentages, box plot statistics, shades) plus the definition and tooltip of each node, so it is written whatever treestyle() is (and with nograph or nodisplay: Display/main call the graph program with htmlonly). The programs are _htmlpage (folder, copy of the files, index.html, link, view browse unless noopen or batch mode) and Mata _js/_jn/_jb/_jo/_ja/_hesc (JSON), _hexc/_mix/_darken/_texton (colours as in the R package), _hwrite, _mkdirs. The files of the page travel as mchaid_tree_js.ado, mchaid_d3_js.ado and mchaid_tree_css.ado (the fonts as data: URIs inside the css): net install copies only .ado, .sthlp... into the ado path, the other extensions are ancillary files for net get. An existing folder is replaced only if it is empty or has an index.html with the mark <!--mchaid Project-->. Mata passes the arguments by reference: the JSON helpers copy their text. Checked against tree_html() of the R package 0.6.0: the JSON of mchaid (bar, box plot, es, nodehead(number), collapse, minmax) and of maid (box, bar, both, median, digits, fr, tukey) is identical except the second colour of the default palette of the response (Stata keeps its own) and the escaping of & in the tooltips. The replay with importance (history item ac]) removes directory(), collapse() and noopen of the original command line when they are typed again
ae] 2026-11-08: the terminal nodes (final nodes) are marked in the style of boxes: the little square with the number (nodehead(category)) is dark, with the number in white (fcolor 64 64 64, fintensity(100) so that Stata does not lighten it; rect kind 7, text kind 51), and with nodehead(number) the heading Node N of a final node is a dark band with white text (rect kind 8, text kind 52). Same in tree_html()/R 0.7.1 (kinds 7 and 8, #404040).
af] 2026-11-08: (1) the legend of the style of boxes has an item for the terminal nodes (t_leaf, 10 languages; rect kind 7) and its items go in rows no wider than the tree, 3 at most, balanced (legflow/legrows, as in the R package; the row count lowers botm and the title goes over the top row); (2) the replay uses the options of the estimation (e(graphopts)) and the typed ones replace them (Mata mergeopts/splitopts/optname, abbreviations completed; directory, collapse and noopen are not reused); (3) the classic graph says that the options of the style of boxes typed with it are ignored (not with directory()); (4) classic graph: p<0.001 instead of the scientific notation (p=5.6e-9). SVG export (graph export x.svg) works with the boxes graph in Stata 17-19. Checked with svy and permute (maid and mchaid) with the new graph code.
ag] 2026-11-10: new layout of the classic graph (mchaid_tree), from the model of the user: every node is a small box whose heading is the category (or group of categories, with the value labels) of the splitting variable that leads to it, with "n = N" under it (the root: Total, or rootlabel(), which now also works with the classic graph; the node-number heading "Node N" of the final nodes and the labels of the branches are gone); the splitting variable (with the dagger of forcevars()) and, under it, "chi2=29.0; p<0.001" go in a white block (rbar of the new matrix W, drawn before the texts) over the branches that leave the node, 0.0417 inches under its box, 0.3556 inches high (0.22 with nopval, which keeps the variable); the horizontal line of the branches is 0.44 inches under the box (0.30 with nopval). Headings that do not fit in 1.05 inches are written with a smaller letter, in two lines or cut (mchaid_fitcl(), mchaid_headw()); the texts are made by mchaid_nodetext() and mchaid_blocktext(). The width of the box is that of the formula of before, with the name of the splitting variable under it. Bars, legend and last line are as before. Same change in maid (history item aa]) and in the R package mchaid 0.8.0. Backup _copias\mchaid_antes_formato_clasico2.ado
ah] 2026-11-10: directory() with treestyle(classic): the interactive page in the layout of the classic graph (local pcls, set in the graph program only when treestyle(classic) is typed; without it the page is the one of the style of boxes, as before). mchaid_tree2 writes the extra fields of tree.js: per node ncl (n = N), svar and stat in the classic text (variable name with the dagger of forcevars(), chi2/F=...; p...); in the options treestyle, showp, quartiles, foot (risk estimate and Cramer's V and the note), nquart. The files of the page (mchaid_tree_js.ado) were regenerated with arbol_html/sync_stata_assets.py from tree.js of the R package 0.9.0 (backward compatible with the boxes page). Backup _copias\mchaid_tree_js_antes_classic.ado
//checked 20/10/2026 (Stata 18, 3411r2.dta)\\
the fix in c] (missing) works with nofast, svy, permute and dvordered: splits below the root and the missing category as an extra node; the ways of computing the p-value other than the default one were all tested

v 3?
- allow custom xtile() for each variable
- save info for all splits (as obj) 
- postestimation for predict & importance
- make interactive fitting - graphing?
- add mi?
