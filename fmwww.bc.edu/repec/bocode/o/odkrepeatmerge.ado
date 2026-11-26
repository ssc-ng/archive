*! version 1.5.0 24nov2026 Arman Mahmud

program define odkrepeatmerge, rclass
	version 14
	syntax using/ [, XLSform(string) FORMTitle(string) ///
		SAVing(string asis) REPLACE SEParator ALLstring]

	* --- XLSForm: xlsform() is the preferred name; formtitle() a synonym ---
	if `"`xlsform'"' == "" {
		local xlsform `"`formtitle'"'
	}
	else if `"`formtitle'"' != "" & `"`formtitle'"' != `"`xlsform'"' {
		display as error "specify xlsform() or formtitle(), not both"
		exit 198
	}
	if `"`xlsform'"' == "" {
		display as error "option xlsform() required"
		exit 198
	}

	* separator: put "_" between a question name and its instance number
	local sep = cond("`separator'" != "", "_", "")
	* allstring: import every CSV column as string (keeps leading zeros);
	* otherwise store decimals as double so GPS coordinates keep full precision
	local strimport = cond("`allstring'" != "", "stringcols(_all)", "asdouble")
	local overwrite `replace'

	* --- Locate the data -------------------------------------------------
	* form_id  = folder/stem of the CSV files: main is form_id.csv,
	*            repeat group g is form_id-g.csv
	local __p : subinstr local using "\" "/", all
	if regexm(lower(`"`__p'"'), "\.csv$") {
		local mainfile `"`__p'"'
		local form_id = substr(`"`__p'"', 1, length(`"`__p'"') - 4)
	}
	else {
		local mainfile `"`__p'.csv"'
		local form_id `"`__p'"'
	}
	* stem = file name part of form_id (used for the default output)
	if regexm(`"`form_id'"', "([^/]*)$") {
		local stem = regexs(1)
	}
	local form_name `"`xlsform'"'

	foreach __f in form_name mainfile {
		capture confirm file `"``__f''"'
		if _rc {
			display as error `"file ``__f'' not found (or it cannot be read; is it open in another program?)"'
			exit 601
		}
	}

	* --- Output file: saving(filename [, replace]) or stem.dta in the cwd ---
	if `"`saving'"' != "" {
		local 0 `"using `saving'"'
		capture syntax using/ [, replace]
		if _rc {
			display as error "saving() must be {it:filename} [, replace]"
			exit 198
		}
		local savefile `"`using'"'
		if "`replace'" != "" local overwrite replace
	}
	else {
		local savefile `"`stem'.dta"'
	}
	mata: st_local("__ext", pathsuffix(st_local("savefile")))
	if `"`__ext'"' == "" local savefile `"`savefile'.dta"'
	else if lower(`"`__ext'"') != ".dta" {
		display as error `"saving(): the output must be a .dta file, not `__ext'"'
		exit 198
	}
	* checked now, so a missing folder is not found only after all the work
	capture confirm new file `"`savefile'"'
	local rc = _rc
	if `rc' == 602 {
		if "`overwrite'" == "" {
			display as error `"file `savefile' already exists; specify replace"'
			exit 602
		}
	}
	else if `rc' {
		display as error `"cannot write `savefile' (does the folder exist?)"'
		exit `rc'
	}

	preserve

qui {

	* ==================================================================
	* 1. Read the XLSForm: repeat structure + question order
	* ==================================================================
	noisily display as input _n "Reading the XLSForm..."

	import excel using `"`form_name'"', describe
	local __nsheet = r(N_worksheet)
	local __sheet
	forvalues s = 1/`__nsheet' {
		if lower(`"`r(worksheet_`s')'"') == "survey" local __sheet `"`r(worksheet_`s')'"'
	}
	if `"`__sheet'"' == "" {
		local __sheet `"`r(worksheet_1)'"'
		noisily display as text `"  note: no sheet named survey; reading the first sheet (`__sheet')"'
	}
	import excel using `"`form_name'"', sheet(`"`__sheet'"') firstrow case(lower) allstring clear
	capture confirm variable type name
	if _rc {
		noisily display as error "The XLSForm survey sheet must have columns named type and name"
		exit 111
	}
	* question label: first column whose name starts with "label"
	local __labvar
	foreach v of varlist _all {
		if "`__labvar'" == "" & substr("`v'", 1, 5) == "label" local __labvar `v'
	}
	if "`__labvar'" != "" {
		keep type name `__labvar'
		rename `__labvar' _orm_label
	}
	else {
		keep type name
		generate _orm_label = ""
	}
	replace _orm_label = trim(ustrregexra(_orm_label, "[\r\n\t]+", " "))
	replace type = lower(trim(itrim(type)))
	replace name = trim(itrim(name))
	drop if type == ""
	* keep end_repeat / end_group rows even when their name cell is blank
	drop if name == "" & !inlist(type, "end_repeat", "end repeat", "end_group", "end group")

	tempfile question_meta variable_order main expect
	tempname qh
	* qname: variable name import delimited makes from the question name
	* qraw/qpath: CSV header without/with group prefix (relative to the
	*            enclosing repeat), as ODK Central writes it
	postfile `qh' str128 qname str320 qlabel str244 qtemplate int qdepth ///
		long qseq byte qgeo int qgroup str128 qraw str244 qpath ///
		using "`question_meta'", replace

	* stack of open groups (G:name) and repeats (R:name); gpref = names of
	* the groups opened since the innermost repeat, joined by "-"
	local gstack
	local gpref
	local depth = 0
	local pos0 = 0
	local templ0 ""
	local gcur0 = 0
	local qseq = 0
	local G = 0
	local maxgdepth = 0
	local qnamelist
	local grpnames meta
	* ODK Central system columns: expected to be absent from the XLSForm
	local __sys submissiondate submitterid submittername attachmentspresent ///
		attachmentsexpected status reviewstate deviceid edits formversion ///
		instanceid instancename metainstanceid meta_instanceid ///
		metainstancename meta_instancename

	forvalues x = 1/`=_N' {
		local __type = type[`x']
		local __oname = name[`x']

		if inlist("`__type'", "begin_group", "begin group", "begin_repeat", "begin repeat") {
			local grpnames `grpnames' `=ustrlower(name[`x'])'
			local __k = cond(inlist("`__type'", "begin_repeat", "begin repeat"), "R", "G")
			local gstack `gstack' `__k':`__oname'
		}
		else if inlist("`__type'", "end_group", "end group", "end_repeat", "end repeat") {
			local __n : word count `gstack'
			local __s
			forvalues i = 1/`=`__n' - 1' {
				local __s `__s' `: word `i' of `gstack''
			}
			local gstack `__s'
		}
		if strpos("`__type'", "begin") | strpos("`__type'", "end") {
			local gpref
			foreach __e of local gstack {
				if substr("`__e'", 1, 2) == "R:" local gpref
				else if "`gpref'" == "" local gpref = substr("`__e'", 3, .)
				else local gpref `gpref'-`=substr("`__e'", 3, .)'
			}
		}

		if inlist("`__type'", "begin_repeat", "begin repeat") {
			local pos`depth' = `pos`depth'' + 1
			local __templ = trim("`templ`depth'' `pos`depth''")
			local ++G
			local gname`G' "`__oname'"
			local gpidx`G' = `gcur`depth''
			local gactive`G' 0
			local gdone`G' 0
			local depth = `depth' + 1
			local gdepth`G' = `depth'
			if `depth' > `maxgdepth' local maxgdepth = `depth'
			local templ`depth' "`__templ'"
			local gcur`depth' = `G'
			local pos`depth' = 0
		}
		else if inlist("`__type'", "end_repeat", "end repeat") {
			if `depth' > 0 local depth = `depth' - 1
		}
		else if !inlist("`__type'", "begin_group", "begin group", "end_group", "end group") {
			* notes are kept: ODK Central exports them as (empty) columns
			local pos`depth' = `pos`depth'' + 1
			local ++qseq
			local __templ = trim("`templ`depth'' `pos`depth''")
			* geopoint columns are split into -Latitude/-Longitude/...
			local __geo = inlist("`__type'", "geopoint", "start-geopoint", "start_geopoint")
			* the variable name import delimited makes from this column:
			* "-" and "." dropped, at most 32 characters
			local __vname = ustrlower(usubstr(ustrregexra(name[`x'], "[^\p{L}\p{N}_]", ""), 1, 32))
			local __qpath = cond(`"`gpref'"' == "", "`__oname'", `"`gpref'-`__oname'"')
			post `qh' ("`__vname'") (usubstr(_orm_label[`x'], 1, 80)) ("`__templ'") ///
				(`depth') (`qseq') (`__geo') (`gcur`depth'') ("`__oname'") (`"`__qpath'"')
			local qnamelist `qnamelist' `__vname'
		}
	}
	postclose `qh'

	* the same question name twice makes the output ambiguous
	use "`question_meta'", clear
	bysort qname (qseq): generate byte _dup = _N > 1 & _n == 1
	levelsof qname if _dup, local(__dups) clean
	if `"`__dups'"' != "" {
		noisily display as text "  note: these names appear more than once in the XLSForm: `__dups'"
	}

	noisily display as result "Found `G' repeat group(s)"

	* ==================================================================
	* 2. Load the main CSV and every repeat-group CSV
	* ==================================================================
	noisily display as input _n "Loading CSV files..."

	import delimited using `"`mainfile'"', clear varnames(1) case(lower) bindquote(strict) encoding("utf-8") `strimport'
	if _N == 0 {
		noisily display as error `"`mainfile' has no data rows"'
		exit 2000
	}
	_orm_ungroup using `"`mainfile'"', meta("`question_meta'") group(0) ///
		names(`qnamelist' `__sys') groups(`grpnames')
	local qmap0 `r(qmap)'
	unab own0 : _all
	capture confirm variable key
	if _rc {
		noisily display as error `"`mainfile' has no KEY column"'
		exit 111
	}
	capture isid key
	if _rc {
		noisily display as error `"`mainfile': KEY is missing or duplicated in some rows"'
		exit 459
	}
	save "`main'"

	forvalues g = 1/`G' {
		local fn "`form_id'-`gname`g''.csv"
		capture confirm file "`fn'"
		if _rc {
			noisily display as error `"Repeat-group file not found: `fn'"'
			exit 601
		}
		import delimited using "`fn'", clear varnames(1) case(lower) bindquote(strict) encoding("utf-8") `strimport'
		if _N == 0 {
			noisily display as text "  note: `gname`g'' has no rows - skipped"
			continue
		}
		capture confirm variable key parent_key
		if _rc {
			noisily display as error `"`fn' must have KEY and PARENT_KEY columns"'
			exit 111
		}
		_orm_ungroup using `"`fn'"', meta("`question_meta'") group(`g') ///
			names(`qnamelist' `__sys') groups(`grpnames')
		local qmap`g' `r(qmap)'
		capture isid key
		if _rc {
			noisily display as error `"`fn': KEY is missing or duplicated in some rows"'
			exit 459
		}
		count if missing(parent_key)
		if r(N) > 0 {
			noisily display as error `"`fn': PARENT_KEY is empty in `r(N)' row(s)"'
			exit 459
		}
		local gactive`g' 1
		local nrows`g' = _N
		ds key parent_key, not
		local own`g' `r(varlist)'
		tempfile tf`g'
		save "`tf`g''"
	}

	noisily display as result "CSV files loaded"

	* ==================================================================
	* 3. Reshape + merge, deepest groups first
	* ==================================================================
	noisily display as input _n "Merging repeat groups (deepest first)..."

	if `maxgdepth' > 0 {
	forvalues dd = `maxgdepth'(-1)1 {
		forvalues g = 1/`G' {
			if `gdepth`g'' != `dd' continue
			if !`gactive`g'' continue

			use "`tf`g''", clear

			* instance number = the [n] at the end of KEY (not row order)
			generate long _orm_j = real(regexs(1)) if regexm(key, "\[([0-9]+)\]$")
			count if missing(_orm_j)
			if r(N) > 0 {
				noisily display as error "`gname`g'': could not read the instance number [n] from KEY"
				exit 459
			}
			drop key
			rename parent_key key
			capture isid key _orm_j
			if _rc {
				noisily display as error "`gname`g'': two rows have the same PARENT_KEY and instance number [n]"
				exit 459
			}

			if "`sep'" != "" & "`own`g''" != "" {
				local __new
				foreach v of local own`g' {
					if ustrlen("`v'`sep'") > 32 {
						noisily display as error "`v'`sep' would exceed 32 characters; shorten question `v'"
						exit 198
					}
					local __new `__new' `v'`sep'
				}
				* new names must not be taken by (nested) variables that keep their name
				ds key _orm_j `own`g'', not
				local __keep `r(varlist)'
				local __clash : list __new & __keep
				if "`__clash'" != "" {
					local __c : word 1 of `__clash'
					noisily display as error "`__c' (repeat group `gname`g'') is already used by a nested repeat question; rename one of them"
					exit 110
				}
				* one group rename, so a and a_ become a_ and a__ in any order
				rename (`own`g'') (`__new')
			}

			ds key _orm_j, not
			local stubs `r(varlist)'
			if "`stubs'" == "" continue

			levelsof _orm_j, local(jvals)
			* variable-limit check: reshape wide multiplies variables (and
			* needs one variable more while it works)
			local __ns : word count `stubs'
			local __nj : word count `jvals'
			local __newk = c(k) - `__ns' - 1 + `__ns' * `__nj' + 1
			if `__newk' + 1 > c(maxvar) {
				noisily display as error "Repeat group `gname`g'' needs `=`__newk' + 1' variables in wide form; the limit is `c(maxvar)'."
				noisily display as error "Raise it with {cmd:set maxvar} (Stata SE/MP) or drop unneeded questions."
				exit 900
			}

			* every name reshape will create (stub + instance number) must be
			* unique and short enough; nested names get one more "_" later
			local maxlen = cond(`gpidx`g'' > 0, 31, 32)
			mata: _orm_widecheck(st_local("stubs"), st_local("jvals"), `maxlen')
			if "`__long'" != "" {
				noisily display as error "`__long' (repeat group `gname`g'') would exceed Stata's 32-character name limit; shorten the question name"
				exit 198
			}
			if "`__dup'" != "" {
				noisily display as error "Repeat group `gname`g'': `__dupwhat' would both be named `__dup'."
				if "`sep'" == "" {
					noisily display as error "Re-run with the separator option (names like q_1, q1_1)."
				}
				exit 110
			}

			* rows per parent, to count orphan rows after the merge
			bysort key: generate long _orm_rows = _N
			capture reshape wide `stubs', i(key) j(_orm_j)
			local rc = _rc
			* reshape leaves globals and characteristics behind
			capture macro drop ReS_*
			local __chars : char _dta[]
			foreach c of local __chars {
				if substr("`c'", 1, 4) == "ReS_" char _dta[`c']
			}
			if `rc' {
				noisily display as error "reshape wide failed for repeat group `gname`g'' (r(`rc'))."
				exit `rc'
			}

			ds key _orm_rows, not
			local childvars `r(varlist)'
			if `gpidx`g'' > 0 {
				rename (`childvars') (=_)
				ds key _orm_rows, not
				local childvars `r(varlist)'
			}
			tempfile child
			save "`child'"

			local p = `gpidx`g''
			if `p' > 0 {
				if !`gactive`p'' {
					noisily display as text "  note: `nrows`g'' `gname`g'' row(s) dropped: parent repeat group `gname`p'' has no rows"
					continue
				}
				use "`tf`p''", clear
			}
			else {
				use "`main'", clear
			}

			foreach v of local childvars {
				capture confirm variable `v', exact
				if !_rc {
					noisily display as error "Variable `v' (from repeat group `gname`g'') already exists in the parent data."
					noisily display as error "Check that no two questions in the XLSForm share the same name."
					if "`sep'" == "" {
						noisily display as error "If names differ only by trailing digits (e.g. q1 and q11), re-run with the separator option."
					}
					exit 110
				}
			}
			local __nc : word count `childvars'
			if c(k) + `__nc' + 2 > c(maxvar) {
				noisily display as error "Merging repeat group `gname`g'' needs more than `c(maxvar)' variables."
				noisily display as error "Raise the limit with {cmd:set maxvar} (Stata SE/MP) or drop unneeded questions."
				exit 900
			}

			merge 1:1 key using "`child'", generate(_orm_m)
			summarize _orm_rows if _orm_m == 2, meanonly
			if r(N) > 0 {
				noisily display as text "  note: `r(sum)' `gname`g'' row(s) had no matching parent and were dropped"
			}
			drop if _orm_m == 2
			drop _orm_m _orm_rows

			if `p' > 0 save "`tf`p''", replace
			else save "`main'", replace

			* instance numbers of this group, used to name its variables
			local jv`g' `jvals'
			local gdone`g' 1
		}
	}
	}   // maxgdepth > 0

	noisily display as result "Merge done"

	* ==================================================================
	* 4. Order variables to follow the questionnaire
	* ==================================================================
	* Every variable the merge created is known exactly: question q of
	* repeat group g gets q[sep]<inner>_..._<outer> for every combination
	* of instance numbers of g and its ancestors. Build that list and look
	* each variable up by name (no guessing from name prefixes).
	noisily display as input _n "Ordering variables..."

	use "`main'", clear
	unab allvars : _all
	* Central system columns renamed on import because their name clashes
	* with a form field (e.g. DeviceID vs deviceid becomes v30)
	local __syslab
	foreach x of local allvars {
		local __l : variable label `x'
		local __l = lower(subinstr(`"`__l'"', "-", "", .))
		local __in : list posof `"`__l'"' in __sys
		if `__in' local __syslab `__syslab' `x'
	}

	* instance tuples of each merged group: j1 (outermost) .. jd
	forvalues g = 1/`G' {
		if !`gdone`g'' continue
		* the group and its ancestors, outermost first (all were merged,
		* otherwise this group could not have been merged into its parent)
		local chain `g'
		local h = `gpidx`g''
		while `h' > 0 {
			local chain `h' `chain'
			local h = `gpidx`h''
		}
		tempfile tup`g'
		local lvl 0
		foreach h of local chain {
			local ++lvl
			clear
			local __jl `jv`h''
			set obs `: word count `__jl''
			generate long j`lvl' = .
			mata: st_store(., "j`lvl'", strtoreal(tokens(st_local("__jl")))')
			if `lvl' > 1 cross using "`tup`g''"
			save "`tup`g''", replace
		}
	}

	* expected variable names, with their sort keys and labels
	local maxkey = 2 * `maxgdepth' + 1
	local nexp 0
	forvalues g = 0/`G' {
		if `g' > 0 {
			if !`gdone`g'' continue
		}
		use "`question_meta'", clear
		keep if qgroup == `g'
		if _N == 0 continue
		local d 0
		if `g' > 0 local d = `gdepth`g''
		generate str244 _sfx = ""
		if `g' > 0 {
			cross using "`tup`g''"
			forvalues m = `d'(-1)1 {
				replace _sfx = _sfx + cond(_sfx == "", "", "_") + string(j`m')
			}
		}
		* geopoint: one variable per part
		expand cond(qgeo, 5, 1)
		bysort qseq _sfx: generate byte _part = _n - 1
		generate str10 _pn = ""
		replace _pn = word("latitude longitude altitude accuracy", _part) if _part > 0
		* only questions whose column is in this group's CSV: otherwise a
		* name made by another question (main q1 vs repeat q, instance 1)
		* would get this question's label and position
		generate str244 _stub = usubstr(qname + _pn, 1, 32)
		mata: st_store(., st_addvar("byte", "_own"), ///
			_orm_inlist(st_sdata(., "_stub"), tokens(st_local("own`g'"))))
		keep if _own
		* a name used by two questions: keep the one its column was matched to
		mata: st_store(., st_addvar("byte", "_qok"), ///
			_orm_qok(st_sdata(., "_stub"), st_data(., "qseq"), st_local("qmap`g'")))
		keep if _qok
		if _N == 0 continue
		generate str244 actual = _stub + cond(`g' > 0, "`sep'" + _sfx, "")
		generate str400 vlab = cond(qlabel != "", qlabel, qname)
		replace vlab = vlab + " (" + _pn + ")" if _part > 0
		if `g' > 0 replace vlab = "[" + _sfx + "] " + vlab
		replace vlab = usubstr(vlab, 1, 80)
		forvalues m = 1/`=`d' + 1' {
			generate long k`=2 * `m' - 1' = real(word(qtemplate, `m'))
		}
		forvalues m = 1/`d' {
			generate long k`=2 * `m'' = j`m'
		}
		keep actual vlab qseq k*
		if `nexp' append using "`expect'"
		save "`expect'", replace
		local ++nexp
	}
	if `nexp' {
		* the last group may have been skipped, leaving other data in memory
		use "`expect'", clear
		* a name can only be created once (a clash stops the merge above)
		bysort actual (qseq): keep if _n == 1
		save "`expect'", replace
	}

	* the variables in the data, in their current order
	clear
	local nv : word count `allvars'
	set obs `nv'
	generate str128 actual = ""
	mata: st_sstore(., "actual", tokens(st_local("allvars"))')
	generate long origseq = _n
	if `nexp' {
		merge 1:1 actual using "`expect'", keep(master match) generate(_orm_m)
	}
	else {
		generate byte _orm_m = 1
		generate long qseq = .
		generate str1 vlab = ""
	}
	local klist
	forvalues i = 1/`maxkey' {
		capture generate long k`i' = .
		local klist `klist' k`i'
	}
	generate byte grp = cond(actual == "key", 0, cond(_orm_m == 3, 1, 2))
	sort grp `klist' qseq origseq

	* not in the XLSForm (and not an ODK Central system column)
	local unmatched
	forvalues i = 1/`=_N' {
		if grp[`i'] != 2 continue
		local x = actual[`i']
		local __issys : list posof "`x'" in __sys
		local __issys2 : list posof "`x'" in __syslab
		if !`__issys' & !`__issys2' local unmatched `unmatched' `x'
	}

	mata: st_local("ordered_varlist", invtokens(st_sdata(., "actual")'))
	* labels for the variables found in the XLSForm (grp 1)
	mata: __orm_s = st_data(., "grp") :== 1
	mata: __orm_n = select(st_sdata(., "actual"), __orm_s); __orm_l = select(st_sdata(., "vlab"), __orm_s)

	use "`main'", clear
	order `ordered_varlist'
	mata: for (__i = 1; __i <= rows(__orm_n); __i++) st_varlabel(__orm_n[__i], __orm_l[__i])
	mata: mata drop __orm_n __orm_l __orm_s __i
	save `"`savefile'"', replace
	local N = _N
	local K = c(k)

	noisily display as result "Ordering done"

	local n_unmatched : word count `unmatched'
	if `n_unmatched' > 0 {
		local __show
		forvalues i = 1/`=min(`n_unmatched', 20)' {
			local __w : word `i' of `unmatched'
			local __show `__show' `__w'
		}
		if `n_unmatched' > 20 local __show `__show' ...
		noisily display as text _n "Note: `n_unmatched' variable(s) not found in the XLSForm were placed at the end:"
		noisily display as text "  `__show'"
		noisily display as text "  If unexpected, check that the XLSForm version matches the data."
	}

	noisily display as result _n `"Saved `savefile' (`N' obs, `K' vars)"'

}   // qui closing

	return local fn `"`savefile'"'
	return local unmatched `"`unmatched'"'
	return scalar N = `N'
	return scalar k = `K'
	return scalar n_repeat = `G'
	return scalar n_unmatched = `n_unmatched'
end


* Give CSV columns the variable name of their XLSForm question.
* ODK Central writes a field inside groups as group-subgroup-field (a
* geopoint as field-Latitude, ...), or only field with "Remove group
* names"; import delimited turns that header into groupsubgroupfield, or
* v# if that name is taken. The original headers are read from the CSV's
* first row (variable labels are cut at 80 characters).
*   1. A header equal to a question's path (group-...-field, relative to
*      its repeat) or to its bare name gets that question's name.
*   2. Otherwise, if every "-" segment but the last is a group or repeat
*      name and the last is a question (or Central system column), the
*      column gets that name if it is free (e.g. meta-instanceID).
* Two columns that would get the same name stop with an error.
* r(qmap) lists "name qseq" for the columns matched in step 1, so a name
* used by two questions is labelled and placed as the one it came from.
program define _orm_ungroup, rclass
	version 14
	syntax using/ , meta(string) group(integer) [names(string) groups(string)]
	unab __vars : _all
	local K : word count `__vars'
	local j 0
	foreach v of local __vars {
		local ++j
		local v`j' `v'
		local h`j' : variable label `v'
		if `"`h`j''"' == "" local h`j' `v'
	}
	preserve
	quietly import delimited using `"`using'"', clear varnames(nonames) ///
		rowrange(1:1) stringcols(_all) bindquote(strict) encoding("utf-8")
	if c(k) == `K' & _N >= 1 {
		forvalues j = 1/`K' {
			local h`j' = trim(v`j'[1])
		}
	}
	* header -> question name, for the questions of this group
	quietly use "`meta'", clear
	quietly keep if qgroup == `group'
	quietly expand cond(qgeo, 5, 1)
	sort qseq
	generate byte _part = 0
	quietly by qseq: replace _part = _n - 1
	generate str10 _pn = ""
	quietly replace _pn = word("Latitude Longitude Altitude Accuracy", _part) if _part > 0
	generate str244 _k1 = qpath + cond(_part > 0, "-" + _pn, "")
	generate str244 _k2 = qraw + cond(_part > 0, "-" + _pn, "")
	generate str128 _t = usubstr(qname + ustrlower(_pn), 1, 32)
	mata: _orm_match(`K')
	restore

	* 1a. matched columns not yet under their name: move out of the way
	forvalues j = 1/`K' {
		if "`t`j''" != "" & "`t`j''" != "`v`j''" {
			rename `v`j'' __orm_t`j'
			local v`j' __orm_t`j'
		}
	}
	* 1b. give them their name
	forvalues j = 1/`K' {
		if "`t`j''" == "" | "`t`j''" == "`v`j''" continue
		local occ 0
		capture confirm new variable `t`j''
		if _rc {
			forvalues i = 1/`K' {
				if "`v`i''" == "`t`j''" local occ `i'
			}
		}
		if `occ' {
			if "`t`occ''" != "" {
				display as error `"CSV columns "`h`occ''" and "`h`j''" would both become variable `t`j''."'
				display as error "If two questions in the XLSForm share this name, rename one of them."
				exit 110
			}
			* taken by a column that is not in the form: give that one v#
			capture confirm new variable v`occ'
			if _rc {
				display as error `"CSV column "`h`j''" (question `t`j'') clashes with column "`h`occ''"; rename one of them"'
				exit 110
			}
			rename `v`occ'' v`occ'
			local v`occ' v`occ'
		}
		rename `v`j'' `t`j''
		local v`j' `t`j''
	}
	* which question each matched column belongs to
	local qmap
	forvalues j = 1/`K' {
		if "`t`j''" != "" local qmap `qmap' `t`j'' `q`j''
	}
	return local qmap `qmap'
	* 2. other group-prefixed columns
	forvalues j = 1/`K' {
		if "`t`j''" != "" continue
		local lab `"`h`j''"'
		local geo
		if regexm(`"`lab'"', "^(.+-.+)-(Latitude|Longitude|Altitude|Accuracy)$") {
			local geo = lower(regexs(2))
			local lab = regexs(1)
		}
		if !regexm(`"`lab'"', "^(.+)-([^-]+)$") continue
		local prefix = ustrlower(regexs(1))
		local field = regexs(2)
		local field = ustrlower(usubstr(ustrregexra(`"`field'"', "[^\p{L}\p{N}_]", ""), 1, 32))
		if "`geo'" != "" {
			* grp-gps-Latitude: gps must be a question, the part kept
			local inform : list posof "`field'" in names
			if !`inform' continue
			local field = usubstr("`field'`geo'", 1, 32)
		}
		if "`field'" == "`v`j''" continue
		local prefix : subinstr local prefix "-" " ", all
		local okprefix 1
		foreach p of local prefix {
			local isgrp : list posof "`p'" in groups
			if !`isgrp' local okprefix 0
		}
		if !`okprefix' continue
		if "`geo'" == "" {
			local inform : list posof "`field'" in names
			if !`inform' continue
		}
		capture confirm new variable `field'
		if _rc continue
		rename `v`j'' `field'
		local v`j' `field'
	}
end


version 14
mata:

// _orm_ungroup: look up the target name of each header h1..hK (locals);
// set local t<j> for the matched ones. Full paths win over bare names.
void _orm_match(real scalar K)
{
	string colvector k1, k2, t
	real colvector q
	transmorphic scalar A
	real scalar i, r
	string scalar h

	k1 = st_sdata(., "_k1")
	k2 = st_sdata(., "_k2")
	t  = st_sdata(., "_t")
	q  = st_data(., "qseq")
	A = asarray_create()
	for (i = 1; i <= rows(t); i++) {
		if (k1[i] != "" & !asarray_contains(A, k1[i])) asarray(A, k1[i], i)
	}
	for (i = 1; i <= rows(t); i++) {
		if (k2[i] != "" & !asarray_contains(A, k2[i])) asarray(A, k2[i], i)
	}
	for (i = 1; i <= K; i++) {
		h = st_local("h" + strofreal(i))
		if (h != "") {
			if (asarray_contains(A, h)) {
				r = asarray(A, h)
				st_local("t" + strofreal(i), t[r])
				st_local("q" + strofreal(i), strofreal(q[r], "%12.0f"))
			}
		}
	}
}

// reshape wide: check the names stub+j for every stub and instance j.
// Sets locals __long (first name longer than maxlen), __dup (first name
// made twice) and __dupwhat (the two stub/instance pairs that make it).
void _orm_widecheck(string scalar stubs, string scalar jvals, real scalar maxlen)
{
	string rowvector s, j
	string colvector a, w
	real colvector o
	real scalar x, y, k

	s = tokens(stubs)
	j = tokens(jvals)
	a = J(cols(s) * cols(j), 1, "")
	w = a
	k = 0
	for (x = 1; x <= cols(s); x++) {
		for (y = 1; y <= cols(j); y++) {
			k++
			a[k] = s[x] + j[y]
			w[k] = s[x] + " instance " + j[y]
		}
	}
	st_local("__long", "")
	st_local("__dup", "")
	st_local("__dupwhat", "")
	for (k = 1; k <= rows(a); k++) {
		if (ustrlen(a[k]) > maxlen) {
			st_local("__long", a[k])
			break
		}
	}
	if (rows(a) < 2) return
	o = order(a, 1)
	for (k = 2; k <= rows(a); k++) {
		if (a[o[k]] == a[o[k - 1]]) {
			st_local("__dup", a[o[k]])
			st_local("__dupwhat", w[o[k - 1]] + " and " + w[o[k]])
			break
		}
	}
}

// 0 where name a[i] was matched (by its CSV header) to another question
// than qs[i]; map = "name qseq name qseq ..." from _orm_ungroup
real colvector _orm_qok(string colvector a, real colvector qs, string scalar map)
{
	transmorphic scalar A
	string rowvector m
	real colvector r
	real scalar i

	m = tokens(map)
	A = asarray_create()
	for (i = 1; i + 1 <= cols(m); i = i + 2) asarray(A, m[i], strtoreal(m[i + 1]))
	r = J(rows(a), 1, 1)
	for (i = 1; i <= rows(a); i++) {
		if (asarray_contains(A, a[i])) r[i] = (asarray(A, a[i]) == qs[i])
	}
	return(r)
}

// 1 where a[i] is one of the words in b
real colvector _orm_inlist(string colvector a, string rowvector b)
{
	transmorphic scalar A
	real colvector r
	real scalar i

	A = asarray_create()
	for (i = 1; i <= cols(b); i++) asarray(A, b[i], 1)
	r = J(rows(a), 1, 0)
	for (i = 1; i <= rows(a); i++) r[i] = asarray_contains(A, a[i])
	return(r)
}

end
