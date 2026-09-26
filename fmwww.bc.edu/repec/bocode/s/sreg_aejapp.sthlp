{smcl}
{* *! version 1.0.0 24sep2026}{...}
{title:sreg_aejapp — Peru iron supplementation example data}

{p 4 4 2}
The AEJapp dataset contains 215 observations and 62 variables from the
study of iron deficiency and schooling attainment in Peru by Chong et al.
(2016). It is included with the package in Stata format.

{title:Download and load the included data}
{p 4 4 2}Download the example files from SSC:{p_end}
{phang2}{cmd:. ssc install sreg, all replace}{p_end}
{phang2}{cmd:. use sreg_aejapp.dta, clear}{p_end}

{p 4 4 2}The command above places the
example dataset and {cmd:try_sreg.do} in the current working directory.

{title:Empirical illustration}
{phang2}{cmd:. generate byte D = cond(treatment == 3, 0, treatment)}{p_end}
{phang2}{cmd:. sreg gradesq34, treatment(D) strata(class_level)}{p_end}
{phang2}{cmd:. sreg gradesq34 pills_taken age_months, treatment(D) strata(class_level)}{p_end}

{p 4 4 2}
The outcome is gradesq34, strata are class_level, and treatment code 3
is recoded to control (0). The second specification uses pills_taken and
age_months. The original variables remain unchanged.

{title:Source and citation}
{p 4 4 2}
Chong, A., Cohen, I., Field, E., Nakasone, E., and Torero, M. (2016).
Iron Deficiency and Schooling Attainment in Peru.
American Economic Journal: Applied Economics 8(4): 222–255.
{browse "https://doi.org/10.1257/app.20140494":doi:10.1257/app.20140494}.

{p 4 4 2}
Replication data distributed by the American Economic Association and ICPSR:
{browse "https://doi.org/10.3886/E113624V1":doi:10.3886/E113624V1}.


{p 4 4 2}
Run {cmd:do try_sreg.do} from the download folder for the complete walkthrough.

{title:Project and software}

{p 4 4 2}
This is the Stata version of the R package sreg, implemented natively in
Stata and Mata. R is not required to use this package.

{p 4 4 2}
{browse "https://sreg-project.github.io":Project website}
{break}
{browse "https://github.com/jutrifonov/sreg-stata":Stata GitHub repository}
{break}
{browse "https://github.com/jutrifonov/sreg":R package}
