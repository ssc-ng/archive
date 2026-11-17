{smcl}
{* *! version 0.4 2026-11-11}{...}
{vieweralsosee "[U] Naming Conventions" "mansection U 11.3Namingconventions"}{...}
{vieweralsosee "[U] Project Manager" "mansection P ProjectManager"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[D] mkdir" "help mkdir"}{...}
{vieweralsosee "[D] cd" "help cd"}{...}
{vieweralsosee "[D] dir" "help dir"}{...}
{vieweralsosee "SSC" "--"}{...}
{vieweralsosee "xdtree" "help xdtree"}{...}
{vieweralsosee "mkproject" "stata ssc desc mkproject"}{...}
{vieweralsosee "fastcd" "stata ssc desc fastcd"}{...}
{vieweralsosee "dirtools" "stata ssc desc dirtools"}{...}
{vieweralsosee "fileutils" "stata ssc desc fileutils"}{...}
{vieweralsosee "workingdir" "net describe workingdir, from(https://jslsoc.sitehost.iu.edu/stata)"}{...}
{viewerjumpto "Syntax" "xproj##syntax"}{...}
{viewerjumpto "Description" "xproj##description"}{...}
{viewerjumpto "Options" "xproj##options"}{...}
{viewerjumpto "Examples" "xproj##examples"}{...}
{viewerjumpto "Stored results" "xproj##results"}{...}
{viewerjumpto "References" "xproj##references"}{...}
{viewerjumpto "Author" "xproj##author"}{...}
{p2colset 1 10 12 2}{...}
{p2col:{bf:xproj} {hline 2}}Tools to make, manage and build project in Stata{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 4 24 2}
{cmd:xproj make} {it:pname}
 [{cmd:,} {opt in:dir(dirname)} {opt d:irs(subdirectories)} 
 {opt n:ote(short_description)} {opt not:ree} {opt nor:eadme} 
 {opt nocd} {opt noadd}]
{p_end}

{p 4 24 2}
{cmd:xproj add} {it:pname} [{help using} {it:directory}]
 [{cmd:,} {opt n:ote(short_description)} {opt nol:ist}]
{p_end}

{p 4 24 2}
{cmd:xproj goto} {it:pname}
{p_end}

{p 4 24 2}
{cmd:xproj list} [{it:pname_spec}]
{p_end}

{p 4 24 2}
{cmd:xproj drop} {it:pname}
{p_end}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:xproj make}
{synopt:{cmdab:in:dir:(}{it:dirname}{cmd:)}}
where to put your project {it:pname} in
{p_end}
{synopt:{cmdab:d:irs:(}{it:subdirectories}{cmd:)}}
subdirectories in the project {it:pname}'s root
{p_end}
{synopt:{cmdab:n:ote:(}{it:short_description}{cmd:)}}
a short description of the project {it:pname}
{p_end}
{synopt:{opt not:ree}}
do not display the project {it:pname}'s directories
{p_end}
{synopt:{opt nor:eadme}}
do not create the README.md file
{p_end}
{synopt:{opt nocd}}
do not change working directory to the project {it:pname}'s root
{p_end}
{synopt:{opt noadd}}
do not add {it:pname} to the projects lookup table
{p_end}

{syntab:xproj add}
{synopt:{cmdab:n:ote:(}{it:short_description}{cmd:)}}
a short description of the project {it:pname}
{p_end}
{synopt:{opt nol:ist}}
do not list the added {it:pname} in Stata's results window
{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{p 4 4 2}{cmd:xproj make} makes directory structure for a research project 
conveniently using flexible specifications. {cmd:xproj make} uses {cmd:xdtree} 
internally to display the created directories in a tree-like format.

{p 4 4 2}{it:pname} is the project's mnemonics, which follows Stata's 
{mansection U 11.3Namingconventions:naming convention}. {it:pname} shall be a 
sequence of 1 to 32 letters (A–Z, a–z, and any Unicode letter), digits (0–9), 
and underscores (_) and start with a letter or an underscore. Embedded 
quotes and whitespaces are not allowed in the {it:pname}. This is intentional, 
as the {it:pname} should a be nice short name. {it:pname} shouldn't be 
duplicated. If you like, you could attach a {opt n:ote(short_description)} 
to the {it:pname}.

{p 4 4 2}Beside {cmd:xproj make} to make a bland-new project and give its 
directory/folder a {it:pname}, {cmd:xproj} also provide {cmd:xproj add} for 
giving an existing (project) directory/folder a {it:pname}. After adding, 
jumping to them is much simpler with {cmd:xproj goto}. This is particularly 
useful and handy if you have projects in different locations and possibly 
deeply buried. 

{p 4 4 2}When you don't need a {it:pname} anymore, you can use {cmd:xproj drop} 
to drop {it:pname} from the lookup table file. 

{p 4 4 2}All changes that you make to your list of {it:pname}s are written to 
a lookup table file right away, so that you will not lose the entries if you 
set up {it:pname}s and then quit Stata. For your curiosity, the file is named 
"XPROJ_LOOKUP_TABLE.txt" and saved in {stata di c(sysdir_personal):sysdir_personal}. 
This file can be edited by hand, if you like.

{p 4 4 2}You can include wildcards "*" and "?" in {cmd:xproj list}'s 
{it:pname_spec} to display several {it:pname}s at the same time. When the 
optional {it:pname_spec} isn't specified, it will list all existing 
projects. {cmd:xproj list} provides a table-like list in Stata's results 
windows with clickable links [goto] and [drop] to invoke the specific 
{cmd:xproj goto} and {cmd:xproj drop}. There is also an [open] link - 
you can click it to open the {it:pname}'s directory. 

{p 4 4 2}The subcommands {cmd:make}, {cmd:goto} and {cmd:list} can be abbreviated 
to subcommands {cmd:mk}, {cmd:go} and {cmd:ls} respectively.


{marker options}{...}
{title:Options}

{dlgtab:xproj make}

{p 4 8 2}{opt in:dir(dirname)} specifies where you want to put your project 
{it:pname} in (i.e., {it:dirname}). If you don't specify {opt in:dir(dirname)}, 
it defaults to the current working directory.

{p 4 8 2}{opt d:irs(subdirectories)} sets subdirectories in the project 
{it:pname}'s root. It sets to a reasonable default with four subdirectories 
for a data analysis project: {it:docs}, {it:data/source}, {it:results} and 
{it:logs}. {it:subdirectories} is a string seperated by whitespace (or ;) and 
don't need double quotes. You can specify {it:subdirectories} with a totally 
new directory list (such as {opt d:irs(docs data outs/logs outs/figs outs/tbls)}) 
or by adding / dropping directories to the default four subdirectories (such as 
{opt d:irs(+docs/readings -results +figs +tbls)}).

{p 4 8 2} {opt n:ote(short_description)} attaches a short decription to the 
{it:pname}. When {cmd:xproj list}ing {it:pname}, the {it:short_description} will 
be displayed instead of the default {it:pname}'s path.

{p 4 8 2}{opt nor:eadme} requests not to create the README.md file in the 
project {it:pname}'s root. Otherwise a README.md will be created and you 
can further {cmd:doedit} it to meet your needs.

{p 4 8 2} {opt nocd} requests not to change the current working directory to 
the project {it:pname}'s root.

{p 4 8 2} {opt noadd} specifies that not to add {it:pname} to the projects 
lookup table. 

{dlgtab:xproj add}

{p 4 8 2} {opt n:ote(short_description)} attaches a short decription to the 
{it:pname}. When {cmd:xproj list}ing {it:pname}, the {it:short_description} will 
be displayed instead of the default {it:pname}'s path.

{p 4 8 2} {opt nol:ist} requests not to display the {it:pname}'s information in
Stata's results windows after adding it to the projects lookup table.


{marker results}{...}
{title:Returned results}

{p 4 8 2}{cmd:xproj {it:subcmd}} returns nothing.


{marker examples}{...}
{title:Examples}

{p 4 7 2}1. {stata xproj make foo1} will make a directory structure for project 
{it:foo1}:{p_end}
{p 8 10 2}- in the current working directory{p_end}
{p 8 10 2}- with subdirtories {it:docs data/source results logs}{p_end}
{p 8 10 2}- display directory structure in tree-like format{p_end}
{p 8 10 2}- create README.md in the project's root{p_end}
{p 8 10 2}- change the working directory to the project's root{p_end}
{p 8 10 2}- add {it:foo1} to the projects lookup table{p_end}

{p 4 7 2}2. {stata "xproj make foo2, in(d:/yzworks) note(the examplar foo2)"} 
will make a directory structure for project {it:foo2}:{p_end}
{p 8 10 2}{bf:- in directory "d:/yzworks"} (d:/yzworks must exists beforehand){p_end}
{p 8 10 2}- with subdirtories {it:docs data/source results logs}{p_end}
{p 8 10 2}- display directory structure in tree-like format{p_end}
{p 8 10 2}- create README.md in the project's root{p_end}
{p 8 10 2}- change the working directory to the project's root{p_end}
{p 8 10 2}- add {it:foo2} to the projects lookup table{p_end}
{p 8 10 2}{bf:- attach a short note "{it:the examplar foo2}" to {it:foo2}}{p_end}

{p 4 7 2}3. {stata "xproj make foo3, dir(data dos outs docs) notree noreadme nocd noadd"} 
will make a directory structure for project {it:foo3}:{p_end}
{p 8 10 2}- in the current working directory{p_end}
{p 8 10 2}{bf:- with subdirtories {it:data dos outs docs}}{p_end}
{p 8 10 2}{bf:- don't display directory structure}{p_end}
{p 8 10 2}{bf:- don't create README.md}{p_end}
{p 8 10 2}{bf:- don't change the working directory to the project's root}{p_end}
{p 8 10 2}{bf:- don't add {it:foo3} to the projects lookup table}{p_end}

{p 4 7 2}4. {stata "xproj make foo4, dir(+docs/readings -results +tbls +figs)"} 
will make a directory structure for project {it:foo4}:{p_end}
{p 8 10 2}- in the current working directory{p_end}
{p 8 10 2}{bf:- with subdirtories {it:docs docs/readings data/source tbls figs logs}}{p_end}
{p 8 10 2}- display directory structure in tree-like format{p_end}
{p 8 10 2}- create README.md in the project's root{p_end}
{p 8 10 2}- change the working directory to the project's root{p_end}
{p 8 10 2}- add {it:foo4} to the projects lookup table{p_end}

{p 4 7 2}5. {stata "xproj add foo5"} will add {it:foo5} to the projects 
lookup table:{p_end}
{p 8 10 2}- {it:foo5}'s path is set to the current working directory{p_end}
{p 8 10 2}- list {it:foo5}'s information in Stata results window{p_end}

{p 4 7 2}6. {stata "xproj add foo6 using d:/yzworks, note(the examplar foo6)"} 
will add {it:foo6} to the projects lookup table:{p_end}
{p 8 10 2}{bf:- {it:foo6}'s path is set to d:/yzworks}{p_end}
{p 8 10 2}- list {it:foo6}'s information in Stata results window{p_end}
{p 8 10 2}{bf:- attach a short note "{it:the examplar foo6}" to {it:foo6}}{p_end}

{p 4 7 2}7. {stata "xproj goto foo1"} will change working directory to 
{it:foo1}'s path.{p_end}

{p 4 7 2}8. {stata "xproj list f*"} will display all {it:pname}s matching glob 
{it:f*} (i.e., {it:pname} starts with letter "f") in the Stata results 
window.{p_end}

{p 4 7 2}9. {stata "xproj drop foo1"} will drop the unwanted pname {it:foo1} from 
the projects lookup table.{p_end}


{marker references}{...}
{title:Reference}

{phang}
{marker long}{...}
Long, J. Scott. 2009. 
{browse "https://www.stata.com/bookstore/workflow-data-analysis-stata/":{it:The Workflow of Data Analysis Using Stata}}. 
"Chapter 2 Planning, organizing, and documenting". Stata Press. 

{phang}
Maarten Buis. 2021. 
{it:{cmd:mkproject}: module to create a project folder with some boilerplate code and research log}. 
version 1.1.0, {browse "http://fmwww.bc.edu/RePEc/bocode/m/mkproject.ado"}. 
(click {stata "net install mkproject.pkg, from(http://fmwww.bc.edu/RePEc/bocode/m)":here} to install it).


{marker author}{...}
{title:Author}

{pstd}Yongyi Zeng{p_end}
{pstd}zzyy@xmu.edu.cn{p_end}
{pstd}School of Management{p_end}
{pstd}Xiamen University{p_end}
{pstd}China, PR.{p_end}

{p2colset 5 40 42 2}{...}
{p2col:Yancheng Chen}Shangqi Jin{p_end}
{p2col:25120242201569@stu.xmu.edu.cn}37620242205372@stu.xmu.edu.cn{p_end}
{p2col:School of Management}School of Management{p_end}
{p2col:Xiamen University}Xiamen University{p_end}
{p2col:China, PR.}China, PR.{p_end}
{p2colreset}{...}

{.-}
{phang}version 0.4 @ 2026-11-11 [for SSC archive submission]{p_end}
{pstd}version 0.3 @ 2022-11-05{p_end}
{pstd}version 0.2 @ 2022-05-18{p_end}
{pstd}version 0.1 @ 2021-05-01{p_end}
{center:{c 169} 2021 YongyiZeng}
