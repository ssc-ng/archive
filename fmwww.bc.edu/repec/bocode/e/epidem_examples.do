version 17
clear all 
macro drop _all 
set more off
capture log close

log using epidem_examples.log, replace text 

use dengue_rd8, clear

keep if region == 8
label var week "Epidemiologic week"

set scheme sj 
	
epidem channel cases year week, yeval(2012) yspan(5) wspan(0) ///
    met(regmean) grtitle("A. regmean, wspan(0)") grsave(channel_regmean0)
epidem channel cases year week, yeval(2012) yspan(5) wspan(2) ///
    met(regmean) grtitle("B. regmean, wspan(2)") grsave(channel_regmean2)
epidem channel cases year week, yeval(2012) yspan(5) wspan(2) ///
    met(robmean) grtitle("C. robmean, wspan(2)") grsave(channel_robmean)
epidem channel cases year week, yeval(2012) yspan(5) wspan(2) ///
    met(bsmedian) jitter grtitle("D. bsmedian, wspan(2)") ///
    grsave(channel_bsmedian)

graph combine channel_regmean0.gph channel_regmean2.gph ///
	channel_robmean.gph channel_bsmedian.gph, cols(2)
graph save Figure1_endemic_channels.gph, replace

/* Examples for rregmm*/
epidem rregmm cases year week, yeval(2012) ryspan (5) ///
	seed(1234) jitter ysrange(0 25) yvalues(0 5 10 15 20 25) ///
	grtitle("5-year reference period") grsave(rregmm_2012_ryspan5.gph)
epidem rregmm cases year week, yeval(2012) ryspan(10) ///
	seed(1234) jitter ysrange(0 25) yvalues(0 5 10 15 20 25) ///
	grtitle("10-year reference period") grsave(rregmm_2012_ryspan10.gph)

graph combine rregmm_2012_ryspan5.gph rregmm_2012_ryspan10.gph, cols(1) 
	graph save Figure2_rregmm.gph, replace

/*Examples for ppvalue*/
epidem ppvalue cases year week, yeval(2007) yspan(5) ///
	wspan(2) met(regmean) iweek(40)

log close

