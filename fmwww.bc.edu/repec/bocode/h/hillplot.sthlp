{smcl}
{* NJC 24 Feb 2021/25 Feb 2021/25 Oct 2026}{...} 
{hline}
help for {hi:hillplot}
{hline}

{title:Hill plot for distribution tails}

{p 8 17 2} 
{cmd:hillplot} 
{it:varname}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[, 
{cmdab:p:scale} 
{cmdab:l:og10} 
{cmdab:r:eport(#)} 
{cmdab:f:ormat(format)} 
{it:graph_options} 
]


{title:Description} 

{p 4 4 2}
Data are for a variable x with distribution function F(x). 

{p 4 4 2} 
Ordered values are labelled x_(1) >= ... >= x_(n).  Note that indexing here 
is the reverse of a more common convention.

{p 4 4 2} 
Given some slowly varying function L(x): 

{p 4 4 2} 
if pr(X > x) = 1 - F(x) = L(x) x^-alpha for large x and alpha > 0, 

{p 4 4 2} 
then for k < n, the tail index alpha can be estimated by the reciprocal of

{p 8 8 2}
    (1 / k) SUM [ log x_(i) / x_(k+1) ] 

{p 8 8 2} 
    =  (1 / k) SUM log x_(i)  -  log x_(k+1).  

{p 4 4 2}
{cmd:hillplot} plots for {it:varname}

{p 8 8 2} 
    estimates of alpha versus k 
   
{p 4 4 2}
and optionally

{p 8 8 2}
    estimates of alpha versus log(k / n) = log(1 - F(x)). 

{p 4 8 2}It reports a single estimate for alpha using {cmd:report()} order statistics. 


{title:Remarks}     

{p 4 4 2}
This is not the Hill plot as known in biochemistry and pharmacology. 

{p 4 4 2}
The command is an updated version of that discussed at the 6th London 
Stata meeting in 2000. 


{title:Options}

{p 4 8 2}{cmd:pscale} specifies plotting against log(k / n) = log(1 - F(x)), 
    that is, using a probability scale. 

{p 4 8 2}{cmd:log10} specifies the use of logarithms base 10 in {cmd:pscale} rather than 
    the default natural logarithms. 

{p 4 8 2}{cmd:report()} specifies the number of order statistics used for the reported estimate of alpha. The default is 25. 

{p 4 8 2}{cmd:format()} specifies a numeric display format for reporting alpha. 

{p 4 8 2}{it:graph_options} are any of the options allowed with {help twoway}. Defaults include {cmd:ms(Oh) yla(, ang(h))}.  {cmd:xsc(reverse)}  may be thought especially natural. 


{title:Saved results} 

{p 8 8 2}{cmd:r(alpha)}{space 4}estimate of alpha 


{title:Examples}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. hillplot price}{p_end}
{p 4 8 2}{cmd:. hillplot price, xsc(reverse)}{p_end}
{p 4 8 2}{cmd:. hillplot price, format(%4.3f)}


{title:Author}

{p 4 4 2}Nicholas J. Cox, University of Durham, U.K.{break}
         n.j.cox@durham.ac.uk


