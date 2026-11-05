program define ppvalue, rclass    
    version 17   
    *! Version 2.2.4 24Dec2025
    *! Single-week posterior probability of a 2-week progressive increase ("gold") given the current zone at iweek()
    *! Uses method-specific Se/Sp and week-specific Prev (Bayesian with Beta priors)
    *! Prints only iweek() results, but fsave() writes week-by-week assessments for all weeks in yeval()
    *! NOTE: met() supports ONLY regmean, bsmedian, robmean 
    *! Graph behavior:
    *!   - default: NO graphs, NO channel messages (quietly + channel,nograph)
    *!   - dograph: show graphs + messages
    *!   - nograph: retained for backward compatibility; equivalent to default
    *! seed() optional; RNG restored; verbose Stata notes suppressed

    syntax varlist(min=3 max=3 numeric) [if] [in] , ///
        YEVAL(integer) ///
        [ YSPAN(integer 5) WSPAN(integer 2) ///
          MET(string) ///
          IWeek(string) ///
          DRAWS(integer 50000) ///
          SEPRIOR(numlist min=2 max=2) ///
          SPPRIOR(numlist min=2 max=2) ///
          PREVPRIOR(numlist min=2 max=2) ///
          SEED(string) ///
          FSAVE(string) ///
          NOGraph ///
          DOGRaph ]

    marksample touse

    tokenize `varlist'
    local cases `1'
    local year  `2'
    local week  `3'

    if "`met'" == "" {
        di as err "met() is required: regmean, bsmedian, or robmean"
        exit 198
    }

    local method = lower("`met'")
    if !inlist("`method'", "regmean", "bsmedian", "robmean") {
        di as err "met() must be regmean, bsmedian, or robmean"
        exit 198
    }

    local yeval  = `yeval'
    local yspan  = `yspan'
    local wspan  = `wspan'

    local firstref = `yeval' - `yspan'
    local lastref  = `yeval' - 1

    if "`seprior'"   == "" local seprior   "0.5 0.5"
    if "`spprior'"   == "" local spprior   "0.5 0.5"
    if "`prevprior'" == "" local prevprior "0.5 0.5"

    local a_se : word 1 of `seprior'
    local b_se : word 2 of `seprior'
    local a_sp : word 1 of `spprior'
    local b_sp : word 2 of `spprior'
    local a_pr : word 1 of `prevprior'
    local b_pr : word 2 of `prevprior'

    /*Channel call policy (default suppresses graphs + messages)*/
    local _chquiet   "quietly"
    local _chnograph "nograph"

    /*dograph overrides everything (show graphs + messages)*/
    if "`dograph'" != "" {
        local _chquiet   ""
        local _chnograph ""
    }
    else {
        if "`nograph'" != "" di as txt "(note: nograph is now the default; use dograph to display graphs)"
    }

    tempfile orig
    quietly save "`orig'", replace

   
    /*Gold standard on reference years: 2-week increasing pattern*/
    quietly use "`orig'", clear
    quietly keep if `touse'

    quietly gen double __date = yw(`year', `week')
    format __date %tw
    sort __date

    quietly gen double C  = `cases'
    quietly gen double C1 = C[_n+1]
    quietly gen double C2 = C[_n+2]

    gen byte gold = (C1 > C & C2 > C1) if !missing(C1, C2)

    quietly keep if inrange(`year', `firstref', `lastref')

    quietly keep `year' `week' gold
    rename `year' ytested

    tempfile gold_index
    quietly save "`gold_index'", replace

    /*Prev by week-window (reference years): counts for Beta posterior*/
    tempfile prev_counts
		capture erase "`prev_counts'"
		postfile ph int week double Prev int A int B using "`prev_counts'"


    forvalues w0 = 1/52 {
        local lo = max(1, `w0' - `wspan')
        local hi = min(52, `w0' + `wspan')

        quietly count if inrange(`week', `lo', `hi') & gold==1
        local A = r(N)
        quietly count if inrange(`week', `lo', `hi') & gold==0
        local B = r(N)

        local Prev = .
        if (`A' + `B') > 0 local Prev = `A' / (`A' + `B')

        post ph (`w0') (`Prev') (`A') (`B')
    }
    postclose ph

    quietly use "`prev_counts'", clear
    tempfile prev
    quietly save "`prev'", replace

    /*Parse/validate iweek()*/
    local iw = .
    if "`iweek'" == "" {
        local iw = 52
    }
    else {
        local iw = real(trim("`iweek'"))
        if missing(`iw') {
            di as err "iweek() must be numeric (1–52); received: `iweek'"
            exit 198
        }
        if (`iw' < 1 | `iw' > 52) {
            di as err "iweek() out of range (1–52): `iw'"
            exit 198
        }
    }

    /*Get Prev window counts at iweek*/
    quietly use "`prev'", clear
    quietly count if week==`iw'
    if r(N)==0 {
        di as err "Week `iw' not found in prevalence table."
        exit 498
    }
    quietly summarize A if week==`iw', meanonly
    local Aiw = r(mean)
    quietly summarize B if week==`iw', meanonly
    local Biw = r(mean)

    /*Build pooled reference-year predictions for candidate tests*/
    tempfile refperf
    local firstdone 0

    forvalues yy = `firstref'/`lastref' {
        quietly use "`orig'", clear
        quietly keep if `touse'

        tempfile outyy

        /*channel call (policy-controlled)*/
        `_chquiet' channel `cases' `year' `week', ///
            yeval(`yy') yspan(`yspan') wspan(`wspan') ///
            met(`method') fsave("`outyy'") `_chnograph'
				
				capture confirm file "`outyy'"
					if (_rc) {
    				di as err "Internal error: channel did not create expected output file:"
    					di as err "  `outyy'"
    			exit 601
				}
			
        quietly use "`outyy'", clear
        quietly keep if ytested == `yy'
        quietly gen byte T_lb   = (obscases >= lbsmooth)   if obscases < . & lbsmooth   < .
        quietly gen byte T_mean = (obscases >= meansmooth) if obscases < . & meansmooth < .
        quietly gen byte T_ub   = (obscases >= ubsmooth)   if obscases < . & ubsmooth   < .
        quietly keep ytested `week' T_lb T_mean T_ub

        if `firstdone' == 0 {
            quietly save "`refperf'", replace
            local firstdone 1
        }
        else {
            quietly append using "`refperf'"
            quietly save "`refperf'", replace
        }
    }

    /*Merge with gold standard*/
    quietly use "`refperf'", clear
    quietly merge 1:1 ytested `week' using "`gold_index'"
    quietly keep if _merge == 3
    quietly drop _merge

    /*2x2 counts for Se/Sp (pooled reference years)*/
    quietly count if gold==1 & T_lb==1
    local TP_lb = r(N)
    quietly count if gold==1 & T_lb==0
    local FN_lb = r(N)
    quietly count if gold==0 & T_lb==0
    local TN_lb = r(N)
    quietly count if gold==0 & T_lb==1
    local FP_lb = r(N)

    quietly count if gold==1 & T_mean==1
    local TP_mean = r(N)
    quietly count if gold==1 & T_mean==0
    local FN_mean = r(N)
    quietly count if gold==0 & T_mean==0
    local TN_mean = r(N)
    quietly count if gold==0 & T_mean==1
    local FP_mean = r(N)

    quietly count if gold==1 & T_ub==1
    local TP_ub = r(N)
    quietly count if gold==1 & T_ub==0
    local FN_ub = r(N)
    quietly count if gold==0 & T_ub==0
    local TN_ub = r(N)
    quietly count if gold==0 & T_ub==1
    local FP_ub = r(N)

    /*Determine zone/test for iweek() in yeval()*/
    local zone "UNKNOWN"
    local testname "UNKNOWN"
    local condpos 1
    local TP = .
    local FN = .
    local TN = .
    local FP = .

    quietly use "`orig'", clear
    quietly keep if `touse'

    tempfile ztmp

    `_chquiet' channel `cases' `year' `week', ///
        yeval(`yeval') yspan(`yspan') wspan(`wspan') ///
        met(`method') fsave("`ztmp'") `_chnograph'
		
    quietly use "`ztmp'", clear
    quietly keep if ytested == `yeval'
    quietly count if `week' == `iw'
    if r(N)==0 {
        di as err "Week `iw' not found in evaluation-year channel output."
        exit 498
    }

    quietly summarize obscases if `week'==`iw', meanonly
    local zC = r(mean)
    quietly summarize lbsmooth if `week'==`iw', meanonly
    local zL = r(mean)
    quietly summarize meansmooth if `week'==`iw', meanonly
    local zM = r(mean)
    quietly summarize ubsmooth if `week'==`iw', meanonly
    local zU = r(mean)

    if missing(`zC') | missing(`zL') | missing(`zM') | missing(`zU') {
        di as err "Missing obscases/lbsmooth/meansmooth/ubsmooth at week `iw' in evaluation-year channel output."
        exit 498
    }

    if (`zC' >= `zU') {
        local zone "EPIDEMIC"
        local testname ">= upper bound"
        local condpos 1
        local TP = `TP_ub'
        local FN = `FN_ub'
        local TN = `TN_ub'
        local FP = `FP_ub'
    }
    else if (`zC' >= `zM') {
        local zone "ALERT"
        local testname ">= mean"
        local condpos 1
        local TP = `TP_mean'
        local FN = `FN_mean'
        local TN = `TN_mean'
        local FP = `FP_mean'
    }
    else if (`zC' >= `zL') {
        local zone "ALARM"
        local testname ">= lower bound"
        local condpos 1
        local TP = `TP_lb'
        local FN = `FN_lb'
        local TN = `TN_lb'
        local FP = `FP_lb'
    }
    else {
        local zone "BASELINE"
        local testname "< lower bound"
        local condpos 0
        local TP = `TP_lb'
        local FN = `FN_lb'
        local TN = `TN_lb'
        local FP = `FP_lb'
    }

    if missing(`TP') | missing(`FN') | missing(`TN') | missing(`FP') {
        di as err "Could not determine zone/test for week `iw'—cannot compute PPV."
        exit 498
    }

    /*Optional RNG control*/
    local _rng ""
    local _rngstate ""
    local _seed .

    if "`seed'" != "" {
        local _seed = real(trim("`seed'"))
        if missing(`_seed') | (`_seed' != floor(`_seed')) | (`_seed' < 0) {
            di as err "seed() must be a nonnegative integer; received: `seed'"
            exit 198
        }
        local _rng      = c(rng)
        local _rngstate = c(rngstate)
        set seed `_seed'
    }

    /*Bayesian posterior simulation for iweek()*/
    tempname Se_med Se_lo Se_hi Sp_med Sp_lo Sp_hi Prev_med Prev_lo Prev_hi PPV_med PPV_lo PPV_hi

    quietly {
        preserve
        clear
        set obs `draws'

        gen double Prev = rbeta(`Aiw' + `a_pr', `Biw' + `b_pr')
        gen double Se   = rbeta(`TP'  + `a_se', `FN'  + `b_se')
        gen double Sp   = rbeta(`TN'  + `a_sp', `FP'  + `b_sp')

        gen double odds_prev = Prev/(1-Prev) if Prev>0 & Prev<1
        gen double LRp = Se/(1-Sp) if Sp < 1
        gen double LRn = (1-Se)/Sp if Sp > 0

        gen double odds_post = .
        if `condpos'==1 replace odds_post = odds_prev * LRp
        else           replace odds_post = odds_prev * LRn

        gen double PPV = odds_post/(1+odds_post) if odds_post < .

        _pctile Se, p(2.5 50 97.5)
        scalar `Se_lo'  = r(r1)
        scalar `Se_med' = r(r2)
        scalar `Se_hi'  = r(r3)

        _pctile Sp, p(2.5 50 97.5)
        scalar `Sp_lo'  = r(r1)
        scalar `Sp_med' = r(r2)
        scalar `Sp_hi'  = r(r3)

        _pctile Prev, p(2.5 50 97.5)
        scalar `Prev_lo'  = r(r1)
        scalar `Prev_med' = r(r2)
        scalar `Prev_hi'  = r(r3)

        _pctile PPV, p(2.5 50 97.5)
        scalar `PPV_lo'  = r(r1)
        scalar `PPV_med' = r(r2)
        scalar `PPV_hi'  = r(r3)

        restore
    }

    if "`seed'" != "" {
        set rng `_rng'
        set rngstate `_rngstate'
    }

    /*Display (single result for iweek)*/
    di _n
    di as txt "====================================================================================="  
    di as txt "RESULTS FROM WEEK `iw' OF `yeval'."
    di as txt "====================================================================================="  
    di as text "Endemic zone: " as res "Week `iw' is currently in the `zone' zone"
    di as txt "Method: " as res "`method'" ",  "   "year: (`yeval')" ",  "   "week span(`wspan')" ",  Bayesian draws=`draws' "
    di as txt "Method Sensitivity = " as res %4.2f scalar(`Se_med')*100 "%"" [" %4.2f scalar(`Se_lo')*100 ", " %4.2f scalar(`Se_hi')*100 "] " 
    di as txt "Method Specificity = " as res %4.2f scalar(`Sp_med')*100 "%"" [" %4.2f scalar(`Sp_lo')*100 ", " %4.2f scalar(`Sp_hi')*100 "]"
    di as txt "Prevalence of an increase in cases during reference period: " ///
                     as res  %4.2f scalar(`Prev_med')*100 "%  " "[" %4.2f scalar(`Prev_lo')*100 ", " %4.2f scalar(`Prev_hi')*100 "]"
    di as txt "Posterior probability of an increase in cases after week `iw': " ///
               as res  %4.2f scalar(`PPV_med')*100 "%  "  "[" %4.2f scalar(`PPV_lo')*100 ", " %4.2f scalar(`PPV_hi')*100 "]"
    di as txt "====================================================================================="               
    di as txt in red "WARNING:" as text "An increase in cases does not necessarily indicate they will reach the next" 
    di as txt "zone in the endemic curve."

    /*Return scalars*/
    return scalar Se      = scalar(`Se_med')
    return scalar Sp      = scalar(`Sp_med')
    return scalar Prev_i  = scalar(`Prev_med')
    return scalar PPV     = scalar(`PPV_med')
    return scalar iweek   = `iw'

    return scalar Se_lo   = scalar(`Se_lo')
    return scalar Se_hi   = scalar(`Se_hi')
    return scalar Sp_lo   = scalar(`Sp_lo')
    return scalar Sp_hi   = scalar(`Sp_hi')
    return scalar Prev_lo = scalar(`Prev_lo')
    return scalar Prev_hi = scalar(`Prev_hi')
    return scalar PPV_lo  = scalar(`PPV_lo')
    return scalar PPV_hi  = scalar(`PPV_hi')

    return scalar TP = `TP'
    return scalar FN = `FN'
    return scalar TN = `TN'
    return scalar FP = `FP'

    return local  zone = "`zone'"
    return local  test = "`testname'"
    return scalar condpos = `condpos'

    /*Save week-by-week assessment dataset (ALL weeks in yeval)*/
    if "`fsave'" != "" {
        /*Parse fsave(): allow fsave(filename) or fsave(filename, replace)*/
        local __fsave_raw `"`fsave'"'
        local __fsave_replace 0

        /*Split on first comma (if any)*/
        gettoken __fsave_file __fsave_rest : __fsave_raw, parse(",")

        local __fsave_file = trim(`"`__fsave_file'"')
        local __fsave_rest = lower(trim(subinstr(`"`__fsave_rest'"', ",", "", 1)))

        if strpos(" `__fsave_rest' ", " replace ") local __fsave_replace 1

        /*Clean surrounding quotes, if user provided them*/
        if (substr(`"`__fsave_file'"',1,1) == `"""' & substr(`"`__fsave_file'"',-1,1) == `"""') {
            local __fsave_file = substr(`"`__fsave_file'"',2,length(`"`__fsave_file'"')-2)
            local __fsave_file = trim(`"`__fsave_file'"')
        }

        /*If no replace requested, refuse to overwrite*/
        if (`__fsave_replace'==0) {
            capture confirm file "`__fsave_file'"
            if (_rc==0) {
                di as err "File already exists: `__fsave_file'"
                di as err "Use fsave(`__fsave_file', replace) to overwrite."
                exit 602
            }
        }

        preserve

        quietly use "`orig'", clear
        quietly keep if `touse'

        tempfile evalall

        `_chquiet' channel `cases' `year' `week', ///
            yeval(`yeval') yspan(`yspan') wspan(`wspan') ///
            met(`method') fsave("`evalall'") `_chnograph'
           
        quietly use "`evalall'", clear
        quietly keep if ytested == `yeval'
        
        quietly gen str20 testname = ""
        quietly gen byte  condpos  = .

        quietly gen long TP = .
        quietly gen long FN = .
        quietly gen long TN = .
        quietly gen long FP = .

        quietly replace testname = ">= upper bound" if wtype==3
        quietly replace condpos  = 1               if wtype==3
        quietly replace TP = `TP_ub' if wtype==3
        quietly replace FN = `FN_ub' if wtype==3
        quietly replace TN = `TN_ub' if wtype==3
        quietly replace FP = `FP_ub' if wtype==3

        quietly replace testname = ">= mean" if wtype==2
        quietly replace condpos  = 1         if wtype==2
        quietly replace TP = `TP_mean' if wtype==2
        quietly replace FN = `FN_mean' if wtype==2
        quietly replace TN = `TN_mean' if wtype==2
        quietly replace FP = `FP_mean' if wtype==2

        quietly replace testname = ">= lower bound" if wtype==1
        quietly replace condpos  = 1                if wtype==1
        quietly replace TP = `TP_lb' if wtype==1
        quietly replace FN = `FN_lb' if wtype==1
        quietly replace TN = `TN_lb' if wtype==1
        quietly replace FP = `FP_lb' if wtype==1

        quietly replace testname = "< lower bound" if wtype==0
        quietly replace condpos  = 0               if wtype==0
        quietly replace TP = `TP_lb' if wtype==0
        quietly replace FN = `FN_lb' if wtype==0
        quietly replace TN = `TN_lb' if wtype==0
        quietly replace FP = `FP_lb' if wtype==0

        quietly keep ytested `week' obscases lbsmooth meansmooth ubsmooth ///
             		wtype testname condpos TP FN TN FP

        
        /*Attach prevalence counts for each week.*/
        /*prev.dta has canonical variable name "week"*/
        tempvar __wkmerge
        quietly gen int `__wkmerge' = `week'

        /*Create canonical "week" for merge, then rename back later*/
        if "`week'" != "week" {
            quietly drop `week'
            quietly rename `__wkmerge' week
        }
        else {
            quietly drop `__wkmerge'
        }

        quietly merge 1:1 week using "`prev'"
        quietly keep if _merge==3
        quietly drop _merge

        /*Rename canonical week back to the user-supplied weekvar name*/
        if "`week'" != "week" {
            quietly rename week `week'
        }

        /*Output variables for week-by-week posterior summaries*/
        quietly gen double Se_med   = .
        quietly gen double Se_lo    = .
        quietly gen double Se_hi    = .
        quietly gen double Sp_med   = .
        quietly gen double Sp_lo    = .
        quietly gen double Sp_hi    = .
        quietly gen double Prev_med = .
        quietly gen double Prev_lo  = .
        quietly gen double Prev_hi  = .
        quietly gen double PPV_med  = .
        quietly gen double PPV_lo   = .
        quietly gen double PPV_hi   = .

        /*Loop over all weeks; simulate and write summaries per week*/
        forvalues w0 = 1/52 {
            quietly count if `week'==`w0'
            if r(N)==0 continue

            quietly summarize A if `week'==`w0', meanonly
            local Aw = r(mean)
            quietly summarize B if `week'==`w0', meanonly
            local Bw = r(mean)

            quietly summarize TP if `week'==`w0', meanonly
            local TPw = r(mean)
            quietly summarize FN if `week'==`w0', meanonly
            local FNw = r(mean)
            quietly summarize TN if `week'==`w0', meanonly
            local TNw = r(mean)
            quietly summarize FP if `week'==`w0', meanonly
            local FPw = r(mean)

            quietly summarize condpos if `week'==`w0', meanonly
            local cpw = r(mean)

            tempfile snap
            quietly save "`snap'", replace

            quietly clear
            quietly set obs `draws'

            quietly gen double Prev = rbeta(`Aw' + `a_pr', `Bw' + `b_pr')
            quietly gen double Se   = rbeta(`TPw' + `a_se', `FNw' + `b_se')
            quietly gen double Sp   = rbeta(`TNw' + `a_sp', `FPw' + `b_sp')

            quietly gen double odds_prev = Prev/(1-Prev) if Prev>0 & Prev<1
            quietly gen double LRp = Se/(1-Sp) if Sp < 1
            quietly gen double LRn = (1-Se)/Sp if Sp > 0

            quietly gen double odds_post = .
            if `cpw'==1 quietly replace odds_post = odds_prev * LRp
            else        quietly replace odds_post = odds_prev * LRn

            quietly gen double PPV = odds_post/(1+odds_post) if odds_post < .

            quietly _pctile Se, p(2.5 50 97.5)
            local Se_lo_w  = r(r1)
            local Se_med_w = r(r2)
            local Se_hi_w  = r(r3)

            quietly _pctile Sp, p(2.5 50 97.5)
            local Sp_lo_w  = r(r1)
            local Sp_med_w = r(r2)
            local Sp_hi_w  = r(r3)

            quietly _pctile Prev, p(2.5 50 97.5)
            local Pr_lo_w  = r(r1)
            local Pr_med_w = r(r2)
            local Pr_hi_w  = r(r3)

            quietly _pctile PPV, p(2.5 50 97.5)
            local PPV_lo_w  = r(r1)
            local PPV_med_w = r(r2)
            local PPV_hi_w  = r(r3)

            quietly use "`snap'", clear

            quietly replace Se_lo   = `Se_lo_w'   if `week'==`w0'
            quietly replace Se_med  = `Se_med_w'  if `week'==`w0'
            quietly replace Se_hi   = `Se_hi_w'   if `week'==`w0'

            quietly replace Sp_lo   = `Sp_lo_w'   if `week'==`w0'
            quietly replace Sp_med  = `Sp_med_w'  if `week'==`w0'
            quietly replace Sp_hi   = `Sp_hi_w'   if `week'==`w0'

            quietly replace Prev_lo  = `Pr_lo_w'  if `week'==`w0'
            quietly replace Prev_med = `Pr_med_w' if `week'==`w0'
            quietly replace Prev_hi  = `Pr_hi_w'  if `week'==`w0'

            quietly replace PPV_lo   = `PPV_lo_w'  if `week'==`w0'
            quietly replace PPV_med  = `PPV_med_w' if `week'==`w0'
            quietly replace PPV_hi   = `PPV_hi_w'  if `week'==`w0'
        }
				
				/*Variable labels for ppvalue fsave() output*/
				label var ytested   "Year evaluated"
				label var `week'      "Epidemiologic week"
				label var obscases  "Observed number of cases"
				label var meansmooth "Smoothed expected mean of cases"
				label var lbsmooth  "Lower 95% bound of smoothed expected mean"
				label var ubsmooth  "Upper 95% bound of smoothed expected mean"
				
				label var wtype  "Endemic zone: 0 baseline, 1 alarm, 2 alert, 3 epidemic)"
				//label var zone      "Endemic zone classification"
				label var testname  "Decision rule defining a positive test"
				label var condpos   "Test result treated as positive (1=yes, 0=no)"
				
				label var TP "True positives (gold=1 & test=1, reference years)"
				label var FN "False negatives (gold=1 & test=0, reference years)"
				label var TN "True negatives (gold=0 & test=0, reference years)"
				label var FP "False positives (gold=0 & test=1, reference years)"
				
				label var Prev "Observed prevalence of gold outcome in reference years"
				label var A    "Number of gold=1 weeks in reference window"
				label var B    "Number of gold=0 weeks in reference window"
				
				label var Se_med "Posterior median sensitivity"
				label var Se_lo  "Posterior 2.5th percentile sensitivity"
				label var Se_hi  "Posterior 97.5th percentile sensitivity"
				
				label var Sp_med "Posterior median specificity"
				label var Sp_lo  "Posterior 2.5th percentile specificity"
				label var Sp_hi  "Posterior 97.5th percentile specificity"
				
				label var Prev_med "Posterior median prevalence"
				label var Prev_lo  "Posterior 2.5th percentile prevalence"
				label var Prev_hi  "Posterior 97.5th percentile prevalence"
				
				label var PPV_med "Posterior median probability of a 2-week increase"
				label var PPV_lo  "Posterior 2.5th percentile probability"
				label var PPV_hi  "Posterior 97.5th percentile probability"
				
				capture label define wtypelb 0 "Baseline" 1 "Alarm" 2 "Alert" 3 "Epidemic"
				label values wtype wtypelb

				capture label define pp_cond 0 "Negative test" 1 "Positive test"
				label values condpos pp_cond

        quietly capture drop __000000
        
        if (`__fsave_replace') quietly save "`__fsave_file'", replace
           else                quietly save "`__fsave_file'"
        /*Renaming variables for clarity*/ 
        quietly use "`__fsave_file'", clear   
        qui gen str2 threshold=""
				qui replace threshold="0" if testname=="< lower bound"
				qui replace threshold="1" if testname==">= lower bound"
				qui replace threshold="2" if testname==">= mean"
				qui replace threshold="3" if testname==">= upper bound"
				qui destring threshold, replace
				qui drop testname
				label define threslb 0 "< lower bound" 1 ">= lower bound" 2 ">= mean" 3 ">= upper bound"
				label values threshold threslb
				capture label var threshold "Threshold rule applied"
      	rename condpos thresmet
				label define ynlb 0 "No" 1 "Yes"
				label values thresmet ynlb
				capture label var thresmet "Week met endemic-channel threshold (0 No, 1 Yes)"
  			rename TP truepos 
				capture label var truepos "True positive: PGW+ & threshmet+ (ref yrs)"
				rename FN falseneg
				capture label var falseneg "False negative: PGW+ and threshmet- (ref yrs)"
				rename TN trueneg
				capture label var trueneg "True negative: PGW- and threshmet- (ref yrs)"
				rename FP falsepos
				capture label var falsepos "False positive: PGW- and threshmet+ (ref yrs)"
				rename A pgwpos
				capture label var pgwpos "PGW positive weeks (ref window)"
				rename B pgwneg
				capture label var pgwneg "PGW negative weeks (ref window)"
				capture notes drop threshold
				capture notes drop condpos
				capture notes threshold: "Threshold rule from channel at each week (>=lb, >=mean, >=ub, or <lb)."
				capture notes thresmet: "1 if threshold condition met/exceeded (uses LR+); 0 if <lb (uses LR-)."
				rename Prev       prev     
				label var prev    "Observed prevalence of PGW (ref yrs)"
				rename Se_med     se_med      
				rename Se_lo      se_lo       
				rename Se_hi      se_hi       
				rename Sp_med     sp_med      
				rename Sp_lo      sp_lo       
				rename Sp_hi      sp_hi       
				rename Prev_med   prev_med    
				rename Prev_lo    prev_lo     
				rename Prev_hi    prev_hi     
				rename PPV_med    ppv_med     
				rename PPV_lo     ppv_lo      
				rename PPV_hi     ppv_hi      
				order ytested week obscases meansmooth lbsmooth ubsmooth wtype thresmet threshold truepos falseneg ///
				trueneg falsepos prev pgwpos pgwneg se_med se_lo se_hi sp_med sp_lo sp_hi prev_med prev_lo prev_hi /// 
				ppv_med ppv_lo ppv_lo ppv_hi
quietly save "`__fsave_file'", replace 
        di as txt "Results saved in: `__fsave_file'"
        restore
    }
    quietly use "`orig'", clear
end
