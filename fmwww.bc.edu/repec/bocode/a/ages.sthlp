{smcl}
{* First Version August 15 2026}{...}
{* This Version August 15 2026}{...}
{viewerdialog ages "dialog ages"}{...}
{viewerjumpto "Syntax" "ages##syntax"}{...}
{viewerjumpto "Stored results" "ages##results"}{...}
{viewerjumpto "Examples" "ages##Examples"}{...}
{hline}
Help for {hi:ages}
{hline}

{title:Description}

{p}{cmd:ages} estimates the relationship between population age-cohorts shares and a dependent variable of choice, 
based on the polynomial transformation suggested by {helpb ages##references:Fair and Dominguez (1991)} and applied later by Higgins (1998), Arnott 
and Chaves (2012) and {helpb ages##references:Juselius and Takats (2018,2021)}. {p_end}

{p}Capturing the effects of changes in the population's age structure in a regression involves different methodological issues, 
such as weak precision if the number of population cohorts is large compared with the number of time periods, large correlation 
between consecutive cohorts' shares and perfect collinearity with respect to the constant. The solution consists of restricting 
the age groups coefficients to lie on a Pth degree polynomial and restricting its sum to be equal to zero to remove 
the perfect multicolinearity. {p_end}

{p}{cmd:ages} performs all the necessary transformations and mathematical calculations to estimate and report the final 
effect by age-cohort, together with its standard error and confidence interval, as an output matrix and through an 
automated graph that displays the effect of all the age-cohorts on the dependent variable. It allows testing for 
different age structure effects based on different groups captured by an interaction with a dummy variable. {p_end}

{p}It also allows estimating a fully dynamic model with lags of the age-cohorts, or their polynomial transformation terms, 
included in the specification. {cmd:ages} allows the user to define the desired number of lags of the age-cohorts and then 
reports the age structure effect as a sum of the contemporaneus and lagged coefficients. Alternatively, it can also report 
each age-cohort effect lag by lag.{p_end}

{p}The user can easily choose different options for the graph with the impact by age group, as well as several other options to 
save and use the results.{p_end}

{p}{cmd:ages} allows the user to choose different estimation methods for both time series and panel data.{p_end}


{synoptline}
{marker index}{...}
{title:Index}

{synopt :{helpb ages##syntax:Syntax}} Syntax{p_end}

{synopt :{helpb ages##options:Options}}{p_end}
{synopt :{helpb ages##required:Required Options}} Defining the age-cohorts variables and its transformation {p_end}
{synopt :{helpb ages##specification:Specification Options}} Options defining the specification of the age-cohorts.{p_end}
{synopt :{helpb ages##estimation:Estimation Method}} Estimation Method options {p_end}
{synopt :{helpb ages##output:Displaying and Saving Results}} Options for displaying and saving the estimation outputs.{p_end}
{synopt :{helpb ages##graph_options:Graph Options}} Options for modifying the IRF graph{p_end}

{synopt :{helpb ages##results:Stored results}}{p_end}

{synopt :{helpb ages##Examples:Examples}}{p_end}

{synopt :{helpb ages##example1:Example 1}} Defining the basic specification options{p_end}
{synopt :{helpb ages##example2:Example 2}} Changing the estimation method and adding methodological options {p_end}
{synopt :{helpb ages##example3:Example 3}} Adding lags to the age-structure (steps) {p_end}
{synopt :{helpb ages##example4:Example 4}} Displaying the full regression output{p_end}
{synopt :{helpb ages##example5:Example 5}} Changing the confidence level or using more than one level{p_end}
{synopt :{helpb ages##example6:Example 6}} Saving the results into new variables{p_end}
{synopt :{helpb ages##example7:Example 7}} Options for plotting the coefficients {p_end}
{synopt :{helpb ages##example8:Example 8}} Interaction of the age-structure with a dummy variable{p_end}

{synoptline}
{marker syntax}{...}
{title:Syntax}


{p 8 13 2}
{cmd:ages}
{depvar}
[{it:controls}]
{ifin}
{cmd:,}
{opt *v:arname(string)} {opt *g:roups(string)} {opt *np(integer)}
[{opt lagpol(integer)} {opt inter(string)} {opt bylag} {opt f:act(real)} {opt conf(numlist integer)} {opt noi:sily} {it:model_options} 
{opt save:ages(string)} {opt nograph} {opt z:ero} {opt ti:tle(string)} 
{opt lab:el(string)} {opt lcol:or(string)} {opt tti:tle(string)} {opt grn:ame(string)} {opt grs:ave(string)} 
{opt as(string)} {opt gro:pt(string)} ]{p_end}
	
{synoptline}

{synoptset 33 tabbed}{...}
{marker options}{...}
{synopthdr:Options}
{synoptline}

{marker required}{...}
{syntab:{bf:Required Options:}}

{synopt:{opt v:arname(string)}}Specifies the common string part of the name of the variables that represent the age-cohorts. 
Different age-cohorts  variables have to be specified with a variable name that consists of two parts, one string that is 
common to all of the groups and one part specific to each group. In this option you need to specify the part that is common to 
all the groups. For instance, if you have three groups and your variables are named {it: coh_young}, {it: coh_middle} 
and {it: coh_old}, then in this option you would need to introduce the common part "coh_" as {opt varname(coh_)}. 
If the variables are named {it: gr1_share}, {it: gr2_share} and {it: g3_share} you would need to introduce two 
strings "gr" and "_share" as {opt varname(gr _share)}.{p_end}

{synopt:{opt g:roups(string)}}Specifies the specific parts of the variables' names that represent each one of the
{bf:K} age-cohorts, which could be strings, numbers, or any combination of them. 
Different age-cohorts variables have to be specified with a variable name that consists of two parts, one common 
to all the groups and one specific to each group. In this option you need to specify the part that is specific 
to each group. For instance, if you have three groups and your variables are named {it: coh_young}, {it: coh_middle} 
and {it: coh_old}, then in this option you would need to introduce the strings "young middle old" as 
{opt groups(young middle old)}. If the variables are named {it: gr1_share, gr2_share and g3_share} you would need to 
introduce the numbers  "1 2 3" as {opt groups(1 2 3)}.{p_end}

{synopt:{opt np(integer)}}Specifies the degree {bf: P} of the polynomial transformation, with {bf: P<K}.{p_end}


{marker specification}{...}
{syntab:{bf:Specification Options:}}

{synopt:{opt lagpol(integer)}}Specifies the number of lags of the age-cohorts variables that are introduced in the 
specification. More specifically, this option defines the number of lags of the polynomial transformation terms. 
If this option is not specified, only the contemporaneus terms are included in the specification.{p_end} 

{synopt:{opt bylag}}It has to be used together with the option {opt lagpol(integer)}. It specifies that the 
estimated coefficients of each age-cohort should be reported separately by each one of the lags included in the specification. 
If this option is not specified, the default is to report the coefficients of each age-cohort as the sum of the coefficients of 
the contemporaneus plus all the lags.{p_end}

{synopt:{opt inter(varlist)}}Specifies a dummy variable that determines an interaction with the polynomial terms in 
the specification. If this option is specified, the command returns two groups of coefficients for each cohort, 
one coefficient for the sample in which the dummy variable is equal to one and another coefficient for the sample 
in which the dummy variable is equal to zero.{p_end} 


{marker estimation}{...}
{syntab:{bf:Estimation Method:}}

{synopt:{opt m:et(string)}}Specifies the estimation method. The default is {cmd:xtreg} when using panel data and {cmd:reg} 
when using time-series data. Any estimation method with a standard syntax is allowed.{p_end}

{synopt:{it:model_options}}Specifies any other estimation options specific to the method used and not defined elsewhere. 
If the user wants to specify any methodological option corresponding to the estimation method being used, she only has to 
enter them alongside the rest of {cmd:ages} options.{p_end}


{marker output}{...}
{syntab:{bf:Displaying and Saving Output Results:}}

{synopt:{opt noi:sily}}If this option is specified, the command displays the full regression output with the polynomial terms. 
If this option is not specified the command only returns a matrix with the age-cohorts coefficients, their standard errors,  
t-statistics, p-values and the confidence bands.{p_end}

{synopt:{opt conf(numlist)}}Specifies one or (max) two confidence levels for calculating the confidence bands. 
The default is 95%. {p_end}

{synopt:{opt f:act(real)}}Specifies a factor for scaling the estimated coefficients. For instance, if the dependent variable
is in logarithms and the coefficients can be interpreted as pseudo elasticities, and therefore, they could be 
expressed in percentage terms, this option should be specified as {opt fact(100)}.{p_end}

{synopt:{opt save(string)}}If this option is specified, the estimated coefficients of each age-cohort, their standard errors 
and the confidence bands are saved as new variables, otherwise no new variables are created. 
The user needs to specify a name/prefix for the new variable containing the coefficients, which is also used for all 
the other new generated variables (standard error and confidence bands).{p_end}


{marker graph_options}{...}
{syntab:{bf:Graph Options:}}

{synopt:{opt nograph}}If this option is specified a graph is not displayed.{p_end}

{synopt:{opt z:ero}}If this option is specified the graph includes a dashed line for the value 0.{p_end}

{synopt:{opt ti:tle(string)}}Specifies a title for the age-cohorts effects graph.{p_end}

{synopt:{opt lcol:or(string)}}Specifies a color for the age-cohorts effects line and its confidence bands.{p_end}

{synopt:{opt lab:el(string)}}Specifies a label for the age-cohorts effects line.{p_end}

{synopt:{opt legend(string)}}Specifies the desired legend options in a similar way as in any other Stata graph.{p_end}

{synopt:{opt grn:ame(string)}}Specifies a graph name that could be used, for instance, when combining various graphs.{p_end}

{synopt:{opt grs:ave(string)}}Specifies a file name and path that should be used to save the age-cohorts effects graph on the disk.{p_end}

{synopt:{opt as(string)}}Specifies the desired file format of the saved graph.{p_end}

{synopt:{opt gro:pt(string)}}Specifies any other graph options not defined elsewhere.{p_end}

{synopt :{helpb ages##index:Return to Index}}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:ages} stores the following in {cmd:e()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{bf:e(ages)}}A matrix including each age-cohort estimated coefficient, its standard error, t-statistic, 
p-value and confidence interval.{p_end}
{synopt:{bf:e(ages0)}}A matrix including each age-cohort estimated coefficient for the sample in which 
the dummy variable is equal to one, its standard error, t-statistic, p-value and confidence interval.{p_end}
{synopt:{bf:e(ages1)}}A matrix including each age-cohort estimated coefficient for the sample in which 
the dummy variable is equal to zero, its standard error, t-statistic, p-value and confidence interval.{p_end}


{p2col 5 18 22 2: Name of Generated Variables if the name given to the estimate coefficients is {it: "age_coefs"}:}{p_end}

{synopt:{bf:age_coefs}} estimated age-cohorts coefficients.{p_end}
{synopt:{bf:age_coefs_se}} coefficent's standar error {p_end}
{synopt:{bf:age_coefs_lo}} coefficent's lower confidence interval {p_end}
{synopt:{bf:age_coefs_up}} coefficent's upper confidence interval {p_end}
{synopt:{bf:age_coefs_up2}} coefficent's second upper confidence interval {p_end}
{synopt:{bf:age_coefs_lo2}} coefficent's second lower confidence interval {p_end}

{synoptline}

{synopt :{helpb ages##index:Return to Index}}{p_end}

{marker Examples}{...}
{title:Examples}

{p 4 4 0}Throughout examples 1 to 10 we are interested in estimating the effects of 17 age-cohorts shares on the variable 
{bf:dlcpi} (log-difference of the consumer price index). The population age-cohorts are the shares over the total population 
of each 5-year cohorts from 0 to 4, 5 to 9, ... 70 to 74, 75 to 80 and more than 80 years old. 
The sample corresponds to a panel dataset of 34 advanced economies from 1961 to 2022.{p_end} 

{title:Example 1. Defining the basic options}
{marker example1}{...}

{p 4 8 2}. {stata use inflation_example_advanced.dta}{p_end}

{p 4 4 0}We need to specify our dependent variable and how the variables containing the shares are named. In our first example,
these variables are named as pp0_4_t, pp5_9_t, pp10_14_t,..., pp70_74_t, pp75_79_t and pp80_over_t. Therefore they all start
with the string "pp", then they have some numbers specific to each cohort and they end with the string "_t". Thus, we need to
specify in the option {opt v:arname(string)} the two common strings that are shared by all the cohort variables, i.e. we need to
introduce both strings in the option as the following: {opt varname(pp _t)}.{p_end}

{p 4 4 0}We also need to specify all the specific parts corresponding to each cohort variable in the option {opt g:roups(string)} as 
the following: {opt groups(0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over)}.{p_end}

{p 4 4 0}Finally, we need to specify the degree of the P:th polynomial transformation. Following Juselius and Takas (2021) we are going
to start with a 4th degree polynomial, thus we need to introduce the option {opt np(4)}.{p_end}

{p 4 8 2}. {stata ages dlcpi, v(pp _t) g(0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over) np(4)}
{p_end}

{p 4 4 0}Then we can add other control variables, like the lag of our dependent variable {bf:l.dlcpi}, the output gap {bf: outpgap}, 
the population growth rate {bf: pop_gr} and the population life expectancey {bf: life_exp}:{p_end}

{p 4 8 2}. {stata ages dlcpi l.dlcpi outpgap pop_gr life_exp, v(pp _t) g(0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over) np(4)}{p_end}

{p 4 4 0}We can also add other control variables including factor variables such as time-fixed effects or country-fixed-effects using dummy 
variables. {p_end}

{p 4 8 2}. {stata ages dlcpi l.dlcpi outpgap pop_gr life_exp i.year i.ccode, v(pp _t) g(0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over) np(4)}{p_end}


{synopt :{helpb ages##index:Return to Index}}{p_end}

{marker example2}{...}
{title:Example 2. Changing the estimation method and adding methodological options}

{p 4 4 0}By default, {cmd: ages} uses the Stata commands {cmd: reg} and {cmd: xtreg} as the estimation methods for 
time-series and panel-data respectively. You can easily change the estimation method through the option {opt method(string)}. 
For instance, if we would like to use the Stata command {cmd: xtregar} we just need to introduce it as the following:

{p 4 8 2}. {stata ages dlcpi l.dlcpi outpgap pop_gr life_exp, v(pp _t) g(0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over) np(4) method(xtregar)}{p_end}
 
{p 4 4 0}We might not want to change the estimation method, but we would like to introduce some methodological options 
like using fixed-effects or robust standard errors. In this case we just need to add theses options as we would do with 
any other Stata command:{p_end}

{p 4 8 2}. {stata ages dlcpi l.dlcpi outpgap pop_gr life_exp, v(pp _t) g(0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over) np(4) fe robust}{p_end}


{synopt :{helpb ages##index:Return to Index}}{p_end}

{marker example3}{...}
{title:Example 3. Adding lags to the population age-structure}

{p 4 4 0}Since many economic process follow complex dynamic processes, we would like to be able to add lags to any of our 
explanatory variables to guarantee that we have a correctly specified model, including the age-cohorts or their corresponding 
polynomial transformations. For instance, in an alternative specification, we might not include the lag of the dependent variable, 
but we include a number of lags of all our explanatory variables instead. In such case, we should specify 
the number of lags of the age-cohorts using the option {opt lagpol(integer)}, for instance 3 lags, and also add the same 
number of lags to the other control variables in the following way:{p_end}

{p 4 8 2}. {stata ages dlcpi l(0/3)(outpgap pop_gr life_exp), v(pp _t) g(0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over) np(4) fe lagpol(3)}{p_end}

{p 4 4 0}When adding lags to the age-structure, the command {cmd: ages} only reports one set of estimated coefficients per each 
age-cohort. Such reported coefficient corresponds to the addition of all the estimated coefficients per age-cohort, i.e.{cmd: ages} 
adds the coefficients from {it:lag=0,...,L} and estimates the standard error, t-statistic, p-value and confidence interval of 
the sum of all the coefficients for each cohort. {p_end}

{p 4 4 0}However, if we are interested in looking at the estimated coefficients at each lag, we can do so just by adding the option
{opt bylag}. {cmd: ages} would still report a table with the sum of all coefficients and also one table per each lag.{p_end}

{p 4 8 2}. {stata ages dlcpi l(0/3)(outpgap pop_gr life_exp), v(pp _t) g(0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over) np(4) fe lagpol(3) bylag}{p_end}


{synopt :{helpb ages##index:Return to Index}}{p_end}

{marker example4}{...}
{title:Example 4. Displaying the full regression output}

{p 4 4 0}If we want to take a look at the full regression output and not only to the age-cohorts coefficients we should use the option 
{opt noisily}.{p_end} 

{p 4 8 2}. {stata ages dlcpi l(0/3)(outpgap pop_gr life_exp), v(pp _t) g(0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over) np(4) fe lagpol(3) noisily}{p_end}

{synopt :{helpb ages##index:Return to Index}}{p_end}

{marker example5}{...}
{title:Example 5. Changing the confidence level or using more than one level}

{p 4 4 0}By default the confidence level for the confidence bands is 95%. If we want to change it, we can use the {opt conf()} option
which admits a maximum of two levels and only admits integer values:{p_end}

{p 4 8 2}. {stata ages dlcpi l.dlcpi outpgap pop_gr life_exp, v(pp _t) g(0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over) np(4) fe conf(90)}{p_end}

{p 4 8 2}. {stata ages dlcpi l.dlcpi outpgap pop_gr life_exp, v(pp _t) g(0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over) np(4) fe conf(66 90)}{p_end}

{synopt :{helpb ages##index:Return to Index}}{p_end}

{marker example6}{...}
{title:Example 6. Saving the results into new variables}

{p 4 4 0}If we want to save the estimated coefficients into a new variable that can be used later, we can use it through the option 
{opt save(string)}. If we introduce the name type {bf:agescoeffs}, {cmd: ages} generates four (or six) new variables with the 
estimated coefficients per age-cohort, its standard error and the confidence bands, and their corresponding neames would be 
{it: agescoeffs, agescoeffs_se, agescoeffs_lo and agescoeffs_up).{p_end}

{p 4 8 2}. {stata ages dlcpi l.dlcpi outpgap pop_gr life_exp, v(pp _t) g(0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over) np(4) fe save(agescoeffs)}{p_end}

{synopt :{helpb ages##index:Return to Index}}{p_end}


{marker example7}{...}
{title:Example 7. Options for plotting the coefficients}

{p 4 4 0}If we do not want {cmd:ages} to produce a graph, we just have to type {bf:nograph}:{p_end}

{p 4 8 2}. {stata ages dlcpi l.dlcpi outpgap pop_gr life_exp, v(pp _t) g(0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over) np(4) fe nograph}{p_end}

{p 4 4 0}In order to reduce the typing we are going to first define a global macro containing the list of the age-cohorts:{p_end}

{p 4 8 2}. {stata global cohorts 0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 55_59 60_64 65_69 70_74 75_79 80_over}{p_end}

{p 4 4 0}In the following example we are going to produce a graph in which a dashed-line with the value of zero is included, we are 
goint to give the graph the tittle "Example on Inflation", include a label "Age-Cohorts Effect" and change the color of the coefficients line and 
the confidence interval to green:{p_end}

{p 4 8 2}. {stata ages dlcpi l.dlcpi outpgap pop_gr life_exp, v(pp _t) g($cohorts) np(4) fe zero title(Example on Inflation) lab(Age-Cohorts Effect) lc(green)}{p_end}

{p 4 4 0}We can also add other graph options inside the {opt gropt()} option, for instance, we can define the labels of the y-axis 
and introduce a title for the x-axis:{p_end}

{p 4 8 2}. {stata ages dlcpi l.dlcpi outpgap pop_gr life_exp, v(pp _t) g($cohorts) np(4) fe zero title(Example on Inflation) lab(Estimated Impact) lc(green) gropt(ylabel(-0.4(0.1)0.4) xtitle(Age-Cohorts))}{p_end}

{p 4 4 0}Finally, we are going to give the graph a name and we are going to save it in a folder in our disk as a png file named "example1".{p_end}

{p 4 8 2}. {cmd: ages dlcpi l.dlcpi outpgap pop_gr life_exp, v(pp _t) g($cohorts) np(4) fe zero grname(Example1) grsave(C:\example1.png) as(png)}{p_end}

{marker example8}{...}
{title:Example 8. Interaction of the age-structure with a dummy variable}

{p 4 4 0}If we are interested in estimating whether the effects of the age-structure differ between two different samples, 
we can do so by interacting the age-cohorts coefficients with a dummy variable that separates our sample into two subsamples.
For instance, we want to test whether the effects are diffeent between the group of 15 countries known as EU15 (the group 
of 15 member countries that made up the European Union between January 1, 1995, and May 1, 2004) and the rest of advanced
economies included in our sample.{p_end}

{p 4 4 0}We can estimate separate coefficients for each sample of countries by using a dummy variable that takes the value of 1
for countries belonging to the EU15, i.e. the variable {bf: eu15}, and introducing such variable into the option {opt inter(string)}:{p_end}

{p 4 8 2}. {stata ages dlcpi l.dlcpi outpgap pop_gr life_exp, v(pp _t) g($cohorts) np(4) fe z inter(eu15)}{p_end}

{p 4 4 0}If we think that all the demographic variables should be different between the two groups we can also add an 
interaction with the population growth and the life expectancy variables: {p_end}

{p 4 8 2}. {stata ages dlcpi l.dlcpi outpgap eu15#c.(pop_gr life_exp), v(pp _t) g($cohorts) np(4) fe z inter(eu15)}{p_end}

{p 4 4 0}When we have specified an interaction with a dummy variable, we can assign labels to the groups defined by 
such binary variable using the options {opt lab0()} and {opt lab1()}. We can also change the color of the lines corresponding
to each sample group by using the otpions {opt lc0()} and {opt lc1()}.{p_end}

{p 4 8 2}. {stata ages dlcpi l.dlcpi eu15#c.(outpgap pop_gr life_exp), v(pp _t) g($cohorts) np(4) fe z inter(eu15) title(Impact on EU15) lc0(green) lc1(red) conf(66 90) lab0(non-EU15) lab1(EU15)}{p_end}

{p 4 4 0}Finally, we can again add other graph options inside the {opt gropt()} option, for instance, we can give a title to the x-axis. 
We can also use the option {opt legend()} to change the legend style:{p_end}

{p 4 8 2}. {stata ages dlcpi l.dlcpi eu15#c.(outpgap pop_gr life_exp), v(pp _t) g($cohorts) np(4) fe z inter(eu15) title(Impact on EU15) lc0(green) lc1(red) conf(66 90) lab0(non-EU15) lab1(EU15) legend(rows(1)) gropt(xtitle(Age-Cohorts))}{p_end}


{synopt :{helpb ages##index:Return to Index}}{p_end}



{synoptline}

{marker references}{...}
{title:References}

{marker fair}{...}
{p}Fair, R.C. and Dominguez, K.M., 1991. "Effects of the changing US age distribution on macroeconomic equations". 
The American Economic Review, Vol. 81, No. 5, Dec. 1991, 1276-1294. {p_end}

{marker juselius}{...}
{p}Juselius, M. and Takáts. E., 2021, "Inflation and demography through time." Journal of Economic Dynamics and Control 128, p.104136."{p_end}

{p}Juselius, M. and Takáts, E., 2018, "The Enduring Link Between Demography And Inflation BIS Working Papers No 722". 
Bank for International Settlements.{p_end}

{synoptline}


{p}If you use this package, please cite both the package and the paper introducing it:{p_end}

{p}Ugarte-Ruiz, A. 2026. "AGES: Stata module to estimate demographic effects," Statistical Software Components, Boston College Department of Economics{p_end}

{synoptline}

{title:Author}

Alfonso Ugarte-Ruiz
alfonso.ugarte@bbva.com
