{smcl}
{* *! version 0.9.2-rc 19nov2026}{...}
{vieweralsosee "ILOSTAT API" "https://rplumber.ilo.org/__docs__/"}{...}

{title:Title}

{pstd}
{bf:ilostat} - Access ILOSTAT statistics and metadata from Stata.{p_end}

{title:Syntax}

{p 4 8 2}
{cmd:ilostat get} {it:dataset_id}{cmd:,} [{cmd:by(indicator|ref_area)} {cmd:indicator(}{it:codes}{cmd:)} {cmd:ref_area(}{it:codes}{cmd:)} {cmd:sex(}{it:codes}{cmd:)} {cmd:classif1(}{it:codes}{cmd:)} {cmd:classif2(}{it:codes}{cmd:)} {cmd:timefrom(}{it:year}{cmd:)} {cmd:timeto(}{it:year}{cmd:)} {cmd:type(code|both|label)} {cmd:format(dta|csv)} {cmd:clear}]{p_end}

{p 4 8 2}
{cmd:ilostat get} {it:dataset_id}{cmd:,} [{cmd:ref_area_label(}{it:quoted labels}{cmd:)} {cmd:sex_label(}{it:quoted labels}{cmd:)} {cmd:classif1_label(}{it:quoted labels}{cmd:)} {cmd:classif2_label(}{it:quoted labels}{cmd:)} {cmd:indicator_label(}{it:quoted labels}{cmd:)} {cmd:clear}]{p_end}

{p 4 8 2}
{cmd:ilostat toc}{cmd:,} [{cmd:by(indicator|ref_area)} {cmd:lang(en|fr|es)} {cmd:indicator(}{it:text}{cmd:)} {cmd:ref_area(}{it:text}{cmd:)} {cmd:label(}{it:text}{cmd:)} {cmd:freq(}{it:code}{cmd:)} {cmd:subject(}{it:text}{cmd:)} {cmd:classification(}{it:text}{cmd:)} {cmd:clear}]{p_end}

{p 4 8 2}
{cmd:ilostat metadata} {it:dataset_id}{cmd:,} [{cmd:by(indicator|ref_area)} {cmd:lang(en|fr|es)} {cmd:clear}]{p_end}

{p 4 8 2}
{cmd:ilostat dic} {it:dictionary}{cmd:,} [{cmd:lang(en|fr|es)} {cmd:clear}]{p_end}

{p 4 8 2}
{cmd:ilostat datasetdic} {it:dataset_id}{cmd:,} {cmd:var(}{it:dimension}{cmd:)} [{cmd:by(indicator|ref_area)} {cmd:lang(en|fr|es)} {cmd:code(}{it:search}{cmd:)} {cmd:match(contains|exact)} {cmd:clear}]{p_end}

{p 4 8 2}{cmd:ilostat dimensions}{p_end}
{p 4 8 2}{cmd:ilostat info}{p_end}

{title:Description}

{pstd}
{cmd:ilostat} retrieves ILOSTAT data and metadata from the ILOSTAT Plumber API. Data are returned as native Stata DTA by default. There is no persistent local cache, and no Python, R, curl or PowerShell dependency. Requests include {cmd:channel=ilostat-stata}.{p_end}

{pstd}
Dataset identifiers such as {cmd:FRA_A} are automatically routed to the reference-area segment. Use {cmd:by()} to select a segment explicitly. Other identifiers default to the indicator segment.{p_end}

{pstd}
Code filters accept space-separated values. The API applies its partial-matching semantics. Label filters accept comma-separated quoted values; commas inside quotes are preserved. Label filters are applied locally after labels have been retrieved.{p_end}

{pstd}
{cmd:metadata} returns a catalogue summary, not the full dataset-specific JSON metadata. {cmd:datasetdic} returns classification values available in the selected dataset.{p_end}

{title:Examples}

{phang2}{cmd:. ilostat get EMP_TEMP_SEX_AGE_NB_A, ref_area(FRA CHE) timefrom(2020) type(both) clear}{p_end}

{phang2}{cmd:. ilostat get FRA_A, indicator(EMP_TEMP_SEX_AGE_NB) timefrom(2020) clear}{p_end}

{phang2}{cmd:. ilostat get EMP_TEMP_SEX_AGE_NB_A, ref_area_label("France", "Tanzania, United Republic of") type(both) clear}{p_end}

{phang2}{cmd:. ilostat toc, by(indicator) indicator(EMP_TEMP) freq(Q) clear}{p_end}

{phang2}{cmd:. ilostat toc, by(ref_area) ref_area(FRA) freq(A) lang(fr) clear}{p_end}

{phang2}{cmd:. ilostat dic sex, lang(en) clear}{p_end}

{phang2}{cmd:. ilostat datasetdic EMP_TEMP_SEX_AGE_NB_A, var(sex) clear}{p_end}

{phang2}{cmd:. ilostat metadata FRA_A, lang(fr) clear}{p_end}

{phang2}{cmd:. ilostat info}{p_end}

{title:Provenance}

{pstd}
{cmd:ilostat get} records dataset characteristics for the dataset identifier, segment, type, format, retrieval time, package version, language and request URL. Source {cmd:last_update} is available using {cmd:ilostat metadata}. Native Stata {cmd:copy} does not expose HTTP response headers.{p_end}

{title:Author and attribution}

{pstd}
David Bescond, International Labour Organization (ILO), Department of Statistics / ILOSTAT.{p_end}

{pstd}
Project: {browse "https://github.com/ilostat/stilostat"}{p_end}

{pstd}
Software: BSD 2-Clause License (BSD-2-Clause). Proposed copyright (c) 2026 International Labour Organization. See LICENSE and ATTRIBUTION.md in the project repository. ILOSTAT data have separate usage terms. Institutional authorization must be confirmed before SSC submission.{p_end}
