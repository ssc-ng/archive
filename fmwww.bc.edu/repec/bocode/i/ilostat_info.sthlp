{smcl}
{title:ilostat info — Show ILOSTAT dataset provenance}

{p 4 4 2}{cmd:ilostat info}{p_end}

{p 4 4 2}Displays the dataset ID, segment, type, language, transfer format,
retrieval timestamp, package version and request URL recorded by
{cmd:ilostat get}. This information is stored in Stata dataset characteristics
and survives {cmd:save} / {cmd:use}.{p_end}

{p 4 4 2}No local cache is created and no additional API call is made.
Source {cmd:last_update} is deliberately not populated unless a verified
source timestamp is available. The retrieval timestamp is not the source
update timestamp.{p_end}

{p 4 4 2}For raw characteristics, use {cmd:char list _dta[]}.{p_end}
