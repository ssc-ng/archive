{smcl}
{* *! version 2.5 2026-11-11}{...}
{vieweralsosee "[U] Do-files" "mansection U 16Do-files"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] doedit" "help doedit"}{...}
{vieweralsosee "[R] do" "help do"}{...}
{vieweralsosee "[R] log" "help log"}{...}
{vieweralsosee "[P] capture" "help capture"}{...}
{vieweralsosee "[R] set" "help set"}{...}
{vieweralsosee "[P] version" "help version"}{...}
{vieweralsosee "[D] clear" "help clear"}{...}
{vieweralsosee "[P] macro drop" "help macro drop"}{...}
{vieweralsosee "[P] creturn" "help creturn"}{...}
{viewerjumpto "Syntax" "xmkdo##syntax"}{...}
{viewerjumpto "Description" "xmkdo##description"}{...}
{viewerjumpto "Options" "xmkdo##options"}{...}
{viewerjumpto "Examples" "xmkdo##examples"}{...}
{viewerjumpto "Stored results" "xmkdo##results"}{...}
{viewerjumpto "References" "xmkdo##references"}{...}
{viewerjumpto "Author" "xmkdo##author"}{...}
{p2colset 1 10 12 2}{...}
{p2col:{bf:xmkdo} {hline 2}}Make a do-file from template{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 4 28 2}{cmd:xmkdo} {cmd:using} {it:{help filename}}
 [{cmd:,} {opt m:ain} {opt sa} {opt v:ersion(#)} {opt l:size(#)} 
 {opt au:thor(name)} {opt log(logtype)} {opt ts(text)} {opt p:lain} 
 {opt replace} {opt ws:ok} {opt noed:it}]


{marker description}{...}
{title:Description}

{p 4 4 2}{cmd:xmkdo} makes a do-file from the templates recommended
by {help xmkdo##long:Long(2009)} and then open it in Stata's Do-file Editor for 
further modification. It could be a springboard for you to set up your 
own sensible do-files.

{p 4 4 2}{cmd:using} {it:{help filename}} specifies the {it:filename} for the 
do-file that you want to make. If {it:filename} is specified without an 
extension, {it:.do} is assumed. If {it:filename} contains embedded whitespaces, 
remember to enclose it in double quotes. But the embedded whitespaces in 
filename (and not in filepath) will be replaced with _ unless {cmd:wsok} is set.


{marker options}{...}
{title:Options}

{p 4 8 2}{opt m:ain} specifies that you want to make a {it:main} do-file 
{it:filename} which will run all manually-added task-specific do-files in 
sequence. When {opt m:ain} is set, {opt v:ersion(#)} will be ignored (because 
they are set in the task-specific do-files). {opt m:ain} and {cmd:sa} may 
not be set at the same time.

{p 4 8 2}{opt sa} specifies that you want to make a do-file {it:filename} for 
{bf:s}tatistical {bf:a}nalysis. {cmd:sa} and {opt m:ain} may not be set at the 
same time. When {opt m:ain} and {opt sa} are not specified, you means the 
default do-file for data management task, which will add some closing 
commands to the do-file, such as {cmd:label data}, {cmd:notes _dta}, 
{cmd:datasignature set}, and so on.

{p 4 8 2}{opt v:ersion(#)} specifies {bf:version #} in the do-file {it:filename}. 
{opt v:ersion()} defaults to the Stata's version you run currently. 

{p 4 8 2}{opt l:size(#)} specifies {bf:set linesize #} in the do-file {it:filename}. 
{opt l:size()} will set linewidth at 80 characters by default. 

{p 4 8 2} {opt au:thor(name)} specifies the author's {it:name} that will
appear in the do-file {it:filename}. Default author's name is set to c-class 
value {opt c(username)}, i.e., the user ID provided by the operating system. 

{p 4 8 2}{opt log(logtype)} specifies the {it:logtype} that the do-file 
{it:filename} will use. {it:logtype} must be either {opt t:ext} (plain text) 
or {opt s:mcl} (Stata Markup and Control Language) and defaults to {opt t:ext}, 
just for easy-sharing with somebody else without Stata intalled.

{p 4 8 2}{opt ts(text)} specifies the time stamp used in the do-file 
{it:filename}. {it:text} will appear as it is, so you must specify a valid date 
such as {it:2008 May 18}, {it:15/03/2021}, etc. {opt ts()} is set to c-class 
value {opt c(current_date)} by default.

{p 4 8 2}{opt p:lain} plainifies the baroque section headings in the do-file.

{p 4 8 2}{opt replace} permits {cmd:xmkdo} to overwrite an existing do-file 
{it:filename} - set it with care!

{p 4 8 2}{opt ws:ok} keeps whitespaces in do-file's {it:filename}.

{p 4 8 2}{opt noed:it} specifies not to open the do-file in the do-file editor.


{marker results}{...}
{title:Returned results}

{p 4 8 2}{cmd:xmkdo} returns nothing.


{marker examples}{...}
{title:Examples}

{p 4 7 2}1. Make a do-file for data management task ({it:w/wo} options set):{p_end}
{p 7 14 2}. {stata xmkdo using dm01_import.do}{p_end}
{p 7 14 2}. {stata xmkdo using dm01_import, v(14) l(90) log(s) au(zeng) ts(2021/03/15) replace}{p_end}

{p 4 7 2}2. Make a do-file for statistical analysis task ({it:w/wo} options set):{p_end}
{p 7 14 2}. {stata xmkdo using sa01_desc.do, sa}{p_end}
{p 7 14 2}. {stata xmkdo using sa01_desc, sa v(14) l(90) log(s) au(zeng) ts(2021/03/15) replace}{p_end}

{p 4 7 2}3. Make a do-file to run other do-files in sequence ({it:w/wo} options set): {p_end}
{p 7 14 2}. {stata xmkdo using _main_.do, main}{p_end}
{p 7 14 2}. {stata xmkdo using _main_, m v(14) log(s) au(zeng) ts(2021/03/15) replace}{p_end}

{p 4 7 2}4. Now delele the generated files if you will, but be careful: {p_end}
{p 7 14 2}. {stata erase dm01_import.do}{p_end}
{p 7 14 2}. {stata erase sa01_desc.do}{p_end}
{p 7 14 2}. {stata erase _main_.do}{p_end}


{marker references}{...}
{title:Reference}

{phang}
{marker long}{...}
Long, J. Scott. 2009. 
{browse "https://www.stata.com/bookstore/workflow-data-analysis-stata/":{it:The Workflow of Data Analysis Using Stata}}. 
"Chapter 3 Writing and debugging do-files". Stata Press. 


{marker author}{...}
{title:Author}

{pstd}Yongyi Zeng{p_end}
{pstd}zzyy@xmu.edu.cn{p_end}
{pstd}School of Management{p_end}
{pstd}Xiamen University{p_end}
{pstd}China, PR.{p_end}

{p2colset 5 40 42 2}{...}
{p2col:Yancheng Chen}Jinle Yan{p_end}
{p2col:25120242201569@stu.xmu.edu.cn}17420242200903@stu.xmu.edu.cn{p_end}
{p2col:School of Management}School of Management{p_end}
{p2col:Xiamen University}Xiamen University{p_end}
{p2col:China, PR.}China, PR.{p_end}
{p2colreset}{...}

{.-}
{phang}version 2.5 @ 2026-11-11 [for SSC archive submission]{p_end}
{pstd}version 2.4 @ 2022-11-03{p_end}
{pstd}version 2.3 @ 2022-05-18{p_end}
{pstd}version 2.2 @ 2021-05-19{p_end}
{pstd}version 2.1 @ 2021-04-11{p_end}
{pstd}version 2.0 @ 2021-03-15{p_end}
{pstd}version 1.0 @ 2008-05-18{p_end}
{center:{c 169} 2021 YongyiZeng}
