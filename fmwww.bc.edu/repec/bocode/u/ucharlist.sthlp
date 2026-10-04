{smcl}
{* 02May2025}{...}
{hline}
help for {hi:ucharlist}
{hline}

{title:List Unicode Characters Present in String Variable}

{cmd:ucharlist} listing Unicode characters present in the string Variable.


{marker syntax}{...}
{title:Syntax}

{p 4 10 2}
{cmd:ucharlist } {it:strvarname} {ifin} [, {opt a:rabnum(string)} {opt p:arse(parse_string)} {opt m:ore} {opt s:ort} ]

{phang}
Where the type of {it:strvarname} must be string, and number of {it:strvarname} must be 1.


{title:Options}

{phang}
{opt a:rabnum(string)} is optional, specifies the Arabic numerals (separated by space). The default is "{res:0 1 2 3 4 5 6 7 8 9 0 . -}".

{phang}
{opt p:arse(parse_string)} is optional, concatenates Unicode characters in {it:strvarname} with parse string. The default is nothing.

{phang} 
{opt s:ort} is optional, sorts Unicode characters in {it:strvarname} by alphabetical (ascending ASCII or code-point) order.
The default order is based on the present of characters in variable {it:strvarname}.

{phang} 
{opt m:ore} is optional, diaplays the Arabic numerals and non Arabic numeral characters in variable {it:strvarname}.


{title:Examples}

{phang}
{cmd:. }{stata sysuse auto, clear}

{phang}
{cmd:. }{stata ucharlist make}

{phang}
{cmd:. }{stata return list}

{phang}
{cmd:. }{stata ucharlist make, arabnum("0 1 2 3 4 5 6 7 8 9 .")}

{phang}
{cmd:. }{stata ucharlist make, parse(" ")}

{phang}
{cmd:. }{stata ucharlist make, sort}

{phang}
{cmd:. }{stata ucharlist make, more}

{phang}
{cmd:. }{stata ucharlist make, arabnum("0 1 2 3 4 5 6 7 8 9 .") parse("")}


{title:Saved Results}

{phang}
{cmd:ucharlist} saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(Ucharlen)}}The number of Unicode Characters Present in variable {it:strvarname}.{p_end}
{synopt:{cmd:r(Arablen)}}The number of Arabic numerals  Present in variable {it:strvarname}.{p_end}
{synopt:{cmd:r(NoArablen)}}The number of non Arabic numeral characters Present in variable {it:strvarname}.{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(Ucharlist)}}The list of Unicode Characters Present in variable {it:strvarname}.{p_end}
{synopt:{cmd:r(Arablist)}}The list of Arabic numerals  Present in variable {it:strvarname}.{p_end}
{synopt:{cmd:r(NoArablist)}}The list of non Arabic numeral characters Present in variable {it:strvarname}.{p_end}


{title:Authors}

{phang}
{cmd:Dejin Xie}, School of Economics and Management, Nanchang University, China.{break}
 E-mail: {browse "mailto:xiedejin@ncu.edu.cn":xiedejin@ncu.edu.cn}. {break}


{title:Also see}

{p 4 14 2}Help: {helpb uchar()}, {helpb usubinstr()}, {helpb levelsof} ; {helpb charlist},
 {helpb valuesof}, {helpb inbase} (if they are installed).{p_end}
