{smcl}
{* *! version 0.2.1  27nov2026}{...}
{vieweralsosee "bcrpdata (en espanol)" "help bcrpdata_es"}{...}
{viewerjumpto "Syntax" "bcrpdata##syntax"}{...}
{viewerjumpto "Description" "bcrpdata##description"}{...}
{viewerjumpto "Options" "bcrpdata##options"}{...}
{viewerjumpto "Remarks" "bcrpdata##remarks"}{...}
{viewerjumpto "Examples" "bcrpdata##examples"}{...}
{viewerjumpto "Author" "bcrpdata##author"}{...}
{hline}
{title:Title}

{phang}
{bf:bcrpdata} {hline 2} Download statistical series from the Central
Reserve Bank of Peru (BCRPData) into Stata

{phang}
{it:Version {bf:0.2.1} (27nov2026)}{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:bcrpdata} {it:code} [{it:code} ...]
[{cmd:,} {opt from(period)} {opt to(period)} {opt clear}]

{synoptset 18 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt from(period)}}first period (see formats below){p_end}
{synopt:{opt to(period)}}last period; requires {opt from()}{p_end}
{synopt:{opt clear}}replace the data in memory even if they have unsaved changes{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:bcrpdata} queries the BCRPData API of the Central Reserve Bank of
Peru ({browse "https://estadisticas.bcrp.gob.pe/estadisticas/series/"})
and leaves in memory a dataset with a {cmd:fecha} (date) variable and one
variable per series, named after the series code and labeled with the
series description. The dataset is {helpb tsset}.

{pstd}
{bf:How to find a code:} search for the series in BCRPData by category or
by name. The code appears in the {it:Codigo} column and in the address of
the series page, for example {cmd:PN02508AQ}.

{pstd}
Series descriptions (variable labels) are in Spanish, as published by
BCRPData. Messages from the command are also in Spanish.


{marker options}{...}
{title:Options}

{phang}
{opt from(period)} and {opt to(period)} restrict the range, using the
API format for the frequency of the series:

{p2colset 9 24 26 2}{...}
{p2col:{it:Frequency}}{it:Format} (example){p_end}
{p2col:monthly}{cmd:2021-1} (January 2021){p_end}
{p2col:quarterly}{cmd:2022-1} (first quarter of 2022){p_end}
{p2col:annual}{cmd:2015}{p_end}
{p2col:daily}{cmd:2024-11-01}{p_end}
{p2colreset}{...}

{pmore}
Without these options, the API returns only the most recent data.

{phang}
{opt clear} allows replacing data in memory that have unsaved changes.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Dates.} The {cmd:fecha} variable gets the Stata date format that
matches the frequency: {cmd:%tm} (monthly), {cmd:%tq} (quarterly),
{cmd:%ty} (annual) or {cmd:%td} (daily).

{pstd}
{bf:Daily series.} The API returns business days only, and holidays
without data are missing. With a daily {cmd:tsset}, weekends count as
gaps; for lags or differences between consecutive business days, use an
index: {cmd:gen t = _n} and {cmd:tsset t}.

{pstd}
{bf:Several series.} All series in one call must have the same
frequency; if frequencies are mixed, the API uses the frequency of the
first series and drops the others. The API accepts up to 10 series per
query; with more, {cmd:bcrpdata} makes several queries and merges them
by period.

{pstd}
{bf:Labels.} Stata limits variable labels to 80 characters. If the
series description is longer, the label shows the last part of the
description and its unit, for example "Agropecuario (millones S/ de
2007)". The full description is stored in the {cmd:nombre}
characteristic of the variable: {cmd:char list PM04986AA[nombre]}.

{pstd}
{bf:Missing data and discontinued series.} Values not available are
stored as missing ({cmd:.}). If a series has no data in the requested
period (for example, a discontinued series called without {opt from()}),
the command says so and leaves the data in memory unchanged.


{marker examples}{...}
{title:Examples}

{pstd}Monthly{p_end}
{phang2}{cmd:. bcrpdata PN38071GM, from(2021-1) to(2022-6) clear}{p_end}

{pstd}Quarterly{p_end}
{phang2}{cmd:. bcrpdata PN02508AQ, from(2022-1) to(2024-4) clear}{p_end}

{pstd}Annual{p_end}
{phang2}{cmd:. bcrpdata PM04986AA, from(2015) to(2024) clear}{p_end}

{pstd}Daily (interbank exchange rate, buying){p_end}
{phang2}{cmd:. bcrpdata PD04637PD, from(2024-11-01) to(2024-11-30) clear}{p_end}

{pstd}Two series with the same frequency, and a graph{p_end}
{phang2}{cmd:. bcrpdata PN01288PM PN01289PM, from(2010-1) to(2012-12) clear}{p_end}
{phang2}{cmd:. tsline PN01288PM PN01289PM}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Andres Talavera Cuya. This command is not an official product of the
Central Reserve Bank of Peru (BCRP) or of INEI. The data belong to the
BCRP; see its
{browse "https://estadisticas.bcrp.gob.pe/estadisticas/series/ayuda/condiciones-de-uso":terms of use}.
Distributed under the GNU General Public License v3
(https://www.gnu.org/licenses/gpl-3.0.txt).

{psee}
En espanol: {helpb bcrpdata_es}
{p_end}
