{smcl}
{* *! version 1.2 2026-11-11}{...}
{vieweralsosee "[D] dir" "mansection D dir"}{...}
{vieweralsosee "[D] dir" "help dir"}{...}
{vieweralsosee "[D] ls" "help ls"}{...}
{vieweralsosee "[D] cd" "help cd"}{...}
{vieweralsosee "SSC" "--"}{...}
{vieweralsosee "opendir" "stata ssc desc fileutils"}{...}
{vieweralsosee "filelist" "stata ssc desc filelist"}{...}
{viewerjumpto "Syntax" "xdtree##syntax"}{...}
{viewerjumpto "Description" "xdtree##description"}{...}
{viewerjumpto "Options" "xdtree##options"}{...}
{viewerjumpto "Examples" "xdtree##examples"}{...}
{viewerjumpto "Stored results" "xdtree##results"}{...}
{viewerjumpto "References" "xdtree##references"}{...}
{viewerjumpto "Author" "xdtree##author"}{...}
{p2colset 1 12 14 2}{...}
{p2col:{bf:xdtree} {hline 2}}Display a directory's structure in a tree-like 
format{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 4 30 2}{opt xdtree} [{it:directoryname}]
 [{cmd:,} {opt norec:urse} {opt l:evels(#)} 
 {cmdab:g:lob(}[{it:pattern}][{cmd:, }{opt rev:ert }{opt noc:ase}]{cmd:)} 
 {cmdab:r:egex(}[{it:pattern}][{cmd:, }{opt rev:ert }{opt noc:ase}]{cmd:)}
 {opt o:pen} {opt nocl:ick}]


{marker description}{...}
{title:Description}

{p 4 4 2}{cmd:xdtree} displays a directory's contents recursively in a 
tree-like format in Stata's results window (shown below, something like 
the enhanced output of DOS command {cmd:tree /f /a}), which facilates 
you getting a really nice and effective overview of the directory's 
structure.

{phang2}{cmd:. xdtree eoe_hw01, glob(*.do) noclick}{p_end}
{p 8 8 2}{hline 50}{p_end}
            📂 eoe_hw01/
            +--📂 data/
            |   +--📂 source/
            |   |   \--📄 [2_files_not_match_<*.do>]
            |   \--📄 [1_file_not_match_<*.do>]
            +--📂 docs/
            +--📂 logs/
            |   \--📄 [2_files_not_match_<*.do>]
            +--📂 results/
            |   \--📄 [1_file_not_match_<*.do>]
            +--📄 _main_.do
            +--📄 dm01_import_tbl2-9.do
            +--📄 sa01_ex2-12.do
            \--📄 [2_files_not_match_<*.do>]
{p 8 8 2}{hline 50}

{p 4 4 2}{cmd:xdtree} is called by user-contributed command {cmd: xproj}, 
but it can be called independently just as you like.

{p 4 4 2}{it:directoryname} is optional. If no {it:directoryname} is 
specified, it will use the current working directory. You don't need to use 
double quotes to enclose {it:directoryname} even if it contains embedded 
spaces.


{marker options}{...}
{title:Options}

{p 4 8 2}{opt norec:urse} specifies that you don't want to recurse into the 
{it:directoryname}'s subdirectories. When not set, {cmd:xdtree} will recurse 
to utmost {it:#} levels (specified by {opt l:evels()}).

{p 4 8 2}{opt l:evels(#)} specifies the levels to recurse into, which is set 
to 3 by default.

{p 4 8 2}{cmdab:g:lob(}[{it:pattern}][{cmd:, }{opt rev:ert }
{opt noc:ase}]{cmd:)} and {cmdab:r:egex(}[{it:pattern}][{cmd:, }
{opt rev:ert }{opt noc:ase}]{cmd:)} may not be set at the same time. 
	
{p 8 12 2}{it:pattern} is wildcards pattern (such as {it:x?z_*.do}) for 
{opt g:lob()} and regular expression for {opt r:egex()} 
(such as {it:^x.z_.*\.do$}). {ul:Better not to double-quote {it:pattern}}. 
{it:pattern} is optional and defaults to match everything.{p_end}
{p 8 12 2}{opt rev:ert} reverts the files showed (i.e., showing 
the no-matches and hiding the matches).{p_end}
{p 8 12 2}{opt noc:ase} means case-insensitive matching.{p_end}

{p 4 8 2}{opt o:pen} will open the {it:directoryname} in the Finder (macOS), 
Explorer (MS Windows), or whatever windows manager you use in unix for 
further investigation. Sometimes it is nicer to see what is in a 
folder/directory through the typical window in the operating system GUI than 
just a file listing (even in the tree-like format, :)).

{p 4 8 2}{opt nocl:ick} will hide the verbose link 
"Click >>> HERE << to browse the directory".


{marker results}{...}
{title:Returned results}

{p 4 8 2}{cmd:xdtree} returns nothing.


{marker examples}{...}
{title:Examples}

{p 4 7 2}1. Display current working directory:{p_end}
{p 7 17 2}{cmd:. }{stata xdtree}{p_end}

{p 4 7 2}2. Display current working directory and open it in OS window:{p_end}
{p 7 17 2}{cmd:. }{stata xdtree, o}{p_end}

{p 4 7 2}3. Display directory {it:foo} norecursively:{p_end}
{p 7 17 2}{cmd:. }{stata xdtree foo, norec}{p_end}

{p 4 7 2}4. Display directory {it:foo/bar} down to 2 levels and show 
no-matched files (case-insensitive matching to wildcarded pattern "*.do"):{p_end}
{p 7 17 2}{cmd:. }{stata xdtree foo/bar, l(2) glob(*.do, rev noc)}{p_end}


{marker references}{...}
{title:References}

{phang}
Jim Hester and Hadley Wickham. 2020. 
{it:{cmd:fs}: Cross-Platform File System Operations Based on 'libuv'}. 
R package version 1.5.0, {browse "https://CRAN.R-project.org/package=fs"}. 
(especially {it:dir_tree()}).

{phang}
Bill Rising. 2017. 
{it:{cmd:opendir}: Open folder/directory window in the operating system}. 
version 1.0.1, {browse "http://fmwww.bc.edu/RePEc/bocode/o/opendir.ado"}. 
(click {stata "net install fileutils.pkg, from(http://fmwww.bc.edu/RePEc/bocode/f)":here} to install it).


{marker author}{...}
{title:Author}

{pstd}Yongyi Zeng{p_end}
{pstd}zzyy@xmu.edu.cn{p_end}
{pstd}School of Management{p_end}
{pstd}Xiamen University{p_end}
{pstd}China, PR.{p_end}

{p2colset 5 40 42 2}{...}
{p2col:Yancheng Chen}Bowen Wang{p_end}
{p2col:25120242201569@stu.xmu.edu.cn}34520232201140@stu.xmu.edu.cn{p_end}
{p2col:School of Management}School of Management{p_end}
{p2col:Xiamen University}Xiamen University{p_end}
{p2col:China, PR.}China, PR.{p_end}
{p2colreset}{...}

{.-}
{phang}version 1.2 @ 2026-11-11 [for SSC archive submission]{p_end}
{pstd}version 1.1 @ 2022-05-18{p_end}
{pstd}version 1.0 @ 2021-04-01{p_end}
{center:{c 169} 2021 YongyiZeng}

