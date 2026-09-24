{smcl}
{* *! version 0.1.3 23sep2026}{...}
{vieweralsosee "[MI] mi impute glemb" "help mi_impute_glemb"}{...}
{vieweralsosee "[MI] mi impute" "help mi_impute"}{...}
{title:Title}

{p2colset 5 14 16 2}{...}
{p2col:{cmd:glemb}}General location EMB imputation engine{p_end}
{p2colreset}{...}

{title:Description}

{pstd}
The recommended user interface is {helpb mi impute glemb}.  It uses Stata's
official {cmd:mi impute} machinery to manage imputation storage, styles,
{cmd:add()}, {cmd:replace}, and {cmd:rseed()}.

{pstd}
The standalone {cmd:glemb} command remains available as a development and
diagnostic interface.  It saves completed datasets to disk and is retained
mainly for testing and comparison with earlier development runs.

{title:Recommended syntax}

{p 8 19 2}
{cmd:mi} {cmd:impute} {cmd:glemb} {it:ivars}
[{cmd:=} {it:xvars}] {ifin}{cmd:,}
{cmd:noms(}{it:varlist}{cmd:)}
[{cmd:add(}{it:#}{cmd:)}
 {cmd:replace}
 {cmd:rseed(}{it:#}{cmd:)}
 {cmd:catinteract(}{it:#}{cmd:)}
 {cmd:catprior(}{it:#}{cmd:)}
 {cmd:maxits(}{it:#}{cmd:)}
 {cmd:meanmodel(}{it:main|saturated}{cmd:)}
 {cmd:profile}]

{pstd}
See {helpb mi impute glemb} for full documentation.

{pstd}
Author: Paul D. Allison, Statistical Horizons,
{browse "mailto:allison@statisticalhorizons.com":allison@statisticalhorizons.com}.
Distributed under the GNU General Public License version 3.

{title:Standalone syntax}

{p 8 15 2}
{cmd:glemb} {it:varlist} {ifin}{cmd:,}
{cmd:noms(}{it:varlist}{cmd:)}
[{cmd:add(}{it:#}{cmd:)}
 {cmd:id(}{it:varlist}{cmd:)}
 {cmd:idvars(}{it:varlist}{cmd:)}
 {cmd:catinteract(}{it:#}{cmd:)}
 {cmd:catprior(}{it:#}{cmd:)}
 {cmd:maxits(}{it:#}{cmd:)}
 {cmd:meanmodel(}{it:main|saturated}{cmd:)}
 {cmd:seed(}{it:#}{cmd:)}
 {cmd:saving(}{it:stub}{cmd:)}
 {cmd:profile}
 {cmd:replace}]

{title:Example}

{phang2}
{cmd:. mi set wide}

{phang2}
{cmd:. mi register imputed self pov race momwork}

{phang2}
{cmd:. mi register regular anti childage divorce gender momage}

{phang2}
{cmd:. mi impute glemb self pov race momwork = anti childage divorce gender momage, noms(pov race momwork divorce) add(25) rseed(123)}

{phang2}
{cmd:. mi estimate: regress anti self pov i.race childage divorce gender momage momwork}

{title:Also see}

{psee}
{helpb mi impute glemb}; {helpb mi impute}
