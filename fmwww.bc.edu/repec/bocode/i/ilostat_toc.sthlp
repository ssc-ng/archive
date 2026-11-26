{smcl}
{* *! version 0.7.2-dev 17nov2026}{...}
{title:ilostat toc — ILOSTAT dataset catalogues}

{p 4 4 2}{cmd:ilostat toc} [{cmd:,} {opt by(indicator|ref_area)} {opt lang(en|fr|es)} {opt indicator(text)} {opt ref_area(text)} {opt label(text)} {opt freq(code)} {opt subject(text)} {opt classification(text)} {opt clear}]

{title:Description}
{p 4 4 2}Retrieves an ILOSTAT catalogue directly as a Stata DTA dataset, retaining API-provided field names. Indicator is the default segment; reference-area is an additional segment. Local filters are case-insensitive substrings except freq(), which is exact. Multiple filter options are combined with AND.

{title:Options}
{p 4 4 2}{opt by(indicator|ref_area)} selects the catalogue segment. Default: indicator.
{p 4 4 2}{opt lang(en|fr|es)} selects English, French, or Spanish. Default: en.
{p 4 4 2}{opt label(text)} searches indicator_label or ref_area_label depending on by().
{p 4 4 2}{opt indicator(text)}, {opt ref_area(text)}, {opt subject(text)}, and {opt classification(text)} search the corresponding code fields if present in the selected catalogue. Missing fields produce a clear error.
{p 4 4 2}{opt freq(code)} selects a frequency code when available.
{p 4 4 2}{opt clear} replaces the dataset in memory.

{title:Examples}
{phang}{cmd:ilostat toc, clear}
{phang}{cmd:ilostat toc, by(indicator) lang(es) clear}
{phang}{cmd:ilostat toc, indicator(EMP_TEMP) freq(Q) clear}
{phang}{cmd:ilostat toc, label("unemployment") clear}
{phang}{cmd:ilostat toc, by(ref_area) lang(fr) clear}
{phang}{cmd:ilostat toc, by(ref_area) ref_area(FRA) freq(A) lang(fr) clear}

{title:Notes}
{p 4 4 2}Requests include channel=ilostat-stata. The ref_area catalogue has been confirmed in Stata with fields including ref_area, ref_area_label, and freq. A failed download or invalid DTA stops with an error.

{title:Author}
{p 4 4 2}David Bescond, ILO Department of Statistics / ILOSTAT.
