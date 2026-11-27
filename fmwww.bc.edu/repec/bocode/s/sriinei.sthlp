{smcl}
{* *! version 1.0.1  27nov2026}{...}
{vieweralsosee "sriinei (en espanol)" "help sriinei_es"}{...}
{viewerjumpto "Syntax" "sriinei##syntax"}{...}
{viewerjumpto "Description" "sriinei##description"}{...}
{viewerjumpto "Options" "sriinei##options"}{...}
{viewerjumpto "Remarks" "sriinei##remarks"}{...}
{viewerjumpto "Examples" "sriinei##examples"}{...}
{viewerjumpto "Author" "sriinei##author"}{...}
{hline}
{title:Title}

{phang}
{bf:sriinei} {hline 2} Download a microdata module from Peru's INEI
SRIENAHO portal

{phang}
{it:Version {bf:1.0.1} (27nov2026)}{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:sriinei}{cmd:,}
{opt cod:igo(#)}
{opt mod:ulo(#)}
{opt tipo(format)}
{opt des:tino(folder)}
[{opt replace} {opt nounz:ip}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt codigo(#)}}survey/round code on the portal; required{p_end}
{synopt:{opt modulo(#)}}module number; required{p_end}
{synopt:{opt tipo(format)}}{cmd:stata}, {cmd:spss}, {cmd:csv} or {cmd:dbf}; required{p_end}
{synopt:{opt destino(folder)}}folder where the module is saved; created if it does not exist; required{p_end}
{synopt:{opt replace}}download again even if the module was already downloaded{p_end}
{synopt:{opt nounzip}}keep the .zip file without extracting it{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:sriinei} downloads one microdata module from the INEI (Peru)
SRIENAHO portal, building the download address from the portal's
pattern:

{p 8 8 2}
{it:https://proyectos.inei.gob.pe/iinei/srienaho/descarga/FORMAT/COD-ModuloN.zip}

{pstd}
It works with any survey published on the portal (ENAHO, ENA, ENAPRES
and others): it has no built-in catalog of surveys, years or modules,
so it does not go out of date when new surveys are published.

{pstd}
{bf:How to find codigo() and modulo():} go to the microdata portal
({browse "https://proyectos.inei.gob.pe/microdatos/"}), choose the survey
and year, and look at the download link of a module. The file name has
the form {it:COD}{cmd:-Modulo}{it:N}{cmd:.zip}: pass {it:COD} to
{opt codigo()} and {it:N} to {opt modulo()}.


{marker options}{...}
{title:Options}

{phang}
{opt codigo(#)} is the survey/round code shown in the download link.

{phang}
{opt modulo(#)} is the module number shown in the download link.

{phang}
{opt tipo(format)} is the file format: {cmd:stata}, {cmd:spss},
{cmd:csv} or {cmd:dbf}. Not every format is available for every survey
and year.

{phang}
{opt destino(folder)} is the folder where the module is saved. It is
created if it does not exist.

{phang}
{opt replace} downloads the module again even if it was already
downloaded to {opt destino()}.

{phang}
{opt nounzip} keeps the downloaded {cmd:.zip} file without extracting
it.


{marker remarks}{...}
{title:Remarks}

{pstd}
After extracting, {cmd:sriinei} lists the files and folders the module
created in {opt destino()}. The names come from INEI's .zip file and
usually differ from {it:COD}{cmd:-Modulo}{it:N}.

{pstd}
To know whether a module was already downloaded, {cmd:sriinei} keeps a
small record file in {opt destino()},
{cmd:.sriinei_}{it:COD}{cmd:-Modulo}{it:N}{cmd:_}{it:FORMAT}{cmd:.txt},
with the address used and the files extracted. If that file exists, the
module is skipped unless {opt replace} is given. With {opt nounzip}, the
check is on the {cmd:.zip} file itself. Deleting the record file forces a
new download.


{marker examples}{...}
{title:Examples}

{pstd}One module in Stata format (replace the codes with the ones shown on the portal){p_end}
{phang2}{cmd:. sriinei, codigo(906) modulo(1234) tipo(stata) destino("C:/ENA/raw")}{p_end}

{pstd}Keep the .zip file without extracting it{p_end}
{phang2}{cmd:. sriinei, codigo(1036) modulo(1895) tipo(csv) destino("C:/ENA/raw") nounzip}{p_end}

{pstd}Download again even if it was already downloaded{p_end}
{phang2}{cmd:. sriinei, codigo(1036) modulo(1895) tipo(stata) destino("C:/ENA/raw") replace}{p_end}

{pstd}Several modules of the same survey{p_end}
{phang2}{cmd:foreach m in 1895 1896 1897 {c 123}}{p_end}
{phang2}{cmd:    sriinei, codigo(1036) modulo(`m') tipo(stata) destino("C:/ENA/raw")}{p_end}
{phang2}{cmd:{c 125}}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Andres Talavera Cuya. Affiliation stated for identification purposes
only -- this software is not an official product of INEI and INEI bears
no responsibility for it. Distributed under the GNU General Public
License v3 (https://www.gnu.org/licenses/gpl-3.0.txt).

{pstd}
Microdata portal: {browse "https://proyectos.inei.gob.pe/microdatos/"}

{psee}
En espanol: {helpb sriinei_es}
{p_end}
