{smcl}
{* 25nov2003/25oct2026}{...}
{hline}
help for {hi:mexplot}
{hline}

{title:Mean and median excess plots} 

{p 8 17 2}
{cmd:mexplot} 
{it:varname}
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}]
[ {cmd:,}
{cmd:mean(}{it:newvar}{cmd:)} 
{cmdab:med:ian} 
{cmdab:med:ian(}{it:newvar}{cmd:)} 
{it:connect_options} ]


{title:Description}

{p 4 4 2}
{cmd:mexplot} plots for {it:varname} 

{p 8 8 2}mean of ({it:varname - u} | {it:varname} > {it:u})

{p 4 4 2}and optionally

{p 8 8 2}median of ({it:varname - u} | {it:varname} > {it:u})

{p 4 4 2}against a varying threshold {it:u}. 

{p 4 4 2}The first plot is variously known
as a mean excess plot or a mean residual life plot.
A linear pattern in (the tail of) a distribution is expected if and
only if the data resemble a generalised Pareto distribution.

{p 4 4 2}The command is an updated version of that discussed at the 6th London 
Stata meeting in 2000. 


{title:Options} 

{p 4 8 2}{cmd:mean()} specifies that a new variable should be generated
containing the means of values over the threshold.

{p 4 8 2}{cmd:median} specifies that the median excess is to be plotted as well
as the mean excess.

{p 4 8 2}{cmd:median(}{it:newvar}{cmd:)} specifies that a new variable should
be generated containing the medians of values over the threshold. This option
automatically implies the previous option. 

{p 4 8 2}{it:connect_options} are any of the options allowed with 
{cmd:twoway connected}; see help for 
{help twoway_connected:graph twoway connected}.


{title:Examples}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. mexplot price}{p_end}
{p 4 8 2}{cmd:. mexplot price, median}


{title:Author}

{p 4 4 2}Nicholas J. Cox, University of Durham{break} 
n.j.cox@durham.ac.uk


