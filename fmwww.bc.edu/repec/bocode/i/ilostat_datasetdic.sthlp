{smcl}
{* *! version 0.9.0-dev 19nov2026}{...}
{title:ilostat datasetdic — dataset-specific ILOSTAT classifications}

{p 4 4 2}{cmd:ilostat datasetdic} {it:dataset_id}{cmd:, var(}{it:dimension}{cmd:)} [{cmd:by(indicator|ref_area)} {cmd:lang(en|fr|es)} {cmd:code(}{it:pattern}{cmd:)} {cmd:match(contains|exact)} {cmd:clear}]

{title:Description}
{p 4 4 2}Downloads the classifications present in one ILOSTAT dataset from /metadata/dataset. Uses the API's native .dta output and sends channel=ilostat-stata. No cache or external runtime is required.

{title:Options}
{p 4 4 2}{cmd:var()} is required. {cmd:by()} overrides automatic dataset-segment detection. {cmd:lang()} defaults to en. {cmd:code()} filters code values; {cmd:match()} defaults to contains. {cmd:clear} permits replacing data in memory.

{title:Examples}
{p 4 4 2}{cmd:ilostat datasetdic EMP_TEMP_SEX_AGE_NB_A, var(sex) clear}
{p 4 4 2}{cmd:ilostat datasetdic FRA_A, var(indicator) lang(fr) clear}
{p 4 4 2}{cmd:ilostat datasetdic CLD_XCHL_SEX_AGE_ECO_NB_A, var(classif2) code(AGR) clear}

{title:Returned variables}
{p 4 4 2}{cmd:code}, {cmd:label}, and {cmd:label_short} where provided by the API. Code and label are checked; label_short is optional.

{title:See also}
{p 4 4 2}{help ilostat:ilostat}, {help ilostat_toc:ilostat toc}
