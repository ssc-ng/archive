{smcl}
{* *! version 1.0.0  24sep2026}{...}
{vieweralsosee "cto_form_data" "help cto_form_data"}{...}
{vieweralsosee "cto_form_data_attachment" "help cto_form_data_attachment"}{...}
{title:Title}

{phang}
{bf:ctoclient} {hline 2} Stata client for the SurveyCTO API


{title:Description}

{pstd}
{cmd:ctoclient} downloads data from a SurveyCTO server into Stata through the
SurveyCTO REST API. It is the Stata companion of the R package {bf:ctoclient} by
the same author, and uses consistent command names.

{pstd}
The JSON parser is written in Mata, which makes {cmd:ctoclient} very fast,
memory-efficient and robust:

{phang2}o  It processes whole blocks of the file with vectorised Mata operations
instead of looping over keys and values in Stata.{p_end}
{phang2}o  It reads the file in pieces of 8 MB, so memory use stays low even for
very large downloads.{p_end}
{phang2}o  Text in any language, such as Amharic, is kept exactly as SurveyCTO sent it.{p_end}
{phang2}o  Problems such as a wrong login, server name or form ID are reported with a
clear message, and working files are always cleaned up.{p_end}

{title:Commands}

{synoptset 30}{...}
{synopt:{helpb cto_form_data}}download the submissions of a form and load them into Stata{p_end}
{synopt:{helpb cto_form_data_attachment}}download the submissions of a form and their media files{p_end}


{title:Requirements}

{pstd}
Stata 15 or newer, and the {cmd:curl} program, which is included in Windows 10
(version 1803) and later, macOS and most Linux distributions. Type
{cmd:shell curl --version} to check. The SurveyCTO user must be allowed to use
the server API and to download data.


{title:Installation and updates}

{pstd}
Install {cmd:ctoclient} from SSC:

{phang2}{cmd:. ssc install ctoclient}{p_end}

{pstd}
To update to the latest version:

{phang2}{cmd:. ssc install ctoclient, replace}{p_end}

{pstd}
To install from a local folder or another web address instead, use

{phang2}{cmd:. net install ctoclient, from("}{it:location}{cmd:") replace}{p_end}

{pstd}
where {it:location} is the folder or web address that contains {cmd:ctoclient.pkg}.


{title:Storing the password}

{pstd}
Store the password once in {cmd:profile.do}, the do-file that Stata runs
automatically every time it starts, by adding the line

{phang2}{cmd:global sctopassword "your-password"}{p_end}

{pstd}
The global macro {cmd:$sctopassword} is then defined in every Stata session, so
do-files never contain the password. Save {cmd:profile.do} in your home folder or
in your {cmd:PERSONAL} folder (type {cmd:sysdir} to see where it is), keep it
private, and restart Stata once for the macro to be defined.


{title:Example}

{phang2}{cmd:. cto_form_data hh_survey, server(myserver) username(me@org.org) pass("$sctopassword") clear}{p_end}


{title:Author}

{pstd}
Gutama Girja Urago{break}
Laterite{break}
{browse "mailto:gurago@laterite.com":gurago@laterite.com}
