{smcl}
{* *! version 1.1.0  22sep2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{viewerjumpto "Syntax" "twopartlog##syntax"}{...}
{viewerjumpto "Description" "twopartlog##description"}{...}
{viewerjumpto "Options" "twopartlog##options"}{...}
{viewerjumpto "Examples" "twopartlog##examples"}{...}
{viewerjumpto "Stored results" "twopartlog##results"}{...}
{viewerjumpto "Author" "twopartlog##author"}{...}

{title:Title}

{phang}
{bf:twopartlog} {hline 2} Two-part log regression model with an optimal zero-handling constant for independent variables containing zeros (Lien, Hu, & Liu, 2025).


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:twopartlog}
{depvar}
{indepvar}
{ifin}
{cmd:,}
{opt gen:erate(newvar)}
[{opt method(string)} {opt c_fixed(#)} {opt grid(#)}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:twopartlog} implements the two-part regression framework proposed by Donald Lien, Yue Hu, and Long Liu (2025) to handle regression analysis where the independent variable contains zeros. It generalizes the Started Logarithm (GSLT) and Inverse Hyperbolic Sine (GIHST) transformations by estimating the optimal constant {it:c} via concentrated non-linear least squares, treats zero values as a separate group via indicator variables, computes average elasticities, and conducts continuity tests at {it:x} = 0.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt generate(newvar)} specifies the name of the new variable to store the transformed independent variable based on the optimal or fixed constant {it:c}. This option is required.

{dlgtab:Optional}

{phang}
{opt method(string)} specifies the transformation type: {cmd:gslt} (Generalized Started Logarithm, {it:ln(x + c)}) or {cmd:gihst} (Generalized Inverse Hyperbolic Sine, {it:ln(x + sqrt(x^2 + c))}). The default is {cmd:method(gslt)}.

{phang}
{opt c_fixed(#)} allows the user to specify a pre-determined, fixed constant {it:c} instead of estimating it via concentrated least squares.

{phang}
{opt grid(#)} specifies the resolution of the concentrated grid search when estimating {it:c}. The default is {cmd:grid(100)}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen y = ln(price)}{p_end}
{phang2}{cmd:. gen x = weight * 0.5}{p_end}
{phang2}{cmd:. replace x = 0 if foreign == 0}{p_end}

{pstd}Run two-part log regression with estimated optimal constant{p_end}
{phang2}{cmd:. twopartlog y x, generate(trans_x) method(gslt) grid(30)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:twopartlog} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(c_opt)}}estimated or fixed optimal constant ({it:c}){p_end}
{synopt:{cmd:e(rss)}}minimized residual sum of squares{p_end}
{synopt:{cmd:e(elasticity)}}average elasticity for positive observations ({it:x} > 0){p_end}
{synopt:{cmd:e(test_continuity)}}continuity test statistic difference at {it:x} = 0{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(method)}}{cmd:gslt} or {cmd:gihst}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:twopartlog}{p_end}


{marker author}{...}
{title:Author}

{pstd}
{bf:Dereje Fedasa Hordofa}{break}
Department of Economics{break}
Dire Dawa University, Ethiopia{break}
Email: {browse "mailto:derejefedasaa@gmail.com":derejefedasaa@gmail.com}{break}
{p_end}


{marker references}{...}
{title:References}

{phang}
Lien, D., Hu, Y., and Liu, L. 2025. Taking logarithm when the independent variable contains zeros in regression analysis: a new approach. {it:Applied Economics Letters} 32(5): 630–636.
{p_end}
