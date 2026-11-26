{smcl}
{title:ilostat metadata — catalogue-level dataset metadata}

{p 4 4 2}{cmd:ilostat metadata} {it:dataset_id}{cmd:,} [{cmd:by(indicator|ref_area)} {cmd:lang(en|fr|es)} {cmd:clear}]{p_end}

{p 4 4 2}Loads the matching row from the verified ILOSTAT DTA table-of-contents endpoint and displays its metadata. This is a catalogue summary, NOT the complete dataset-specific JSON metadata used by pyilostat.{p_end}

{p 4 4 2}Example:{p_end}
{cmd:ilostat metadata EMP_TEMP_SEX_AGE_NB_A, clear}
{cmd:ilostat metadata FRA_A, lang(fr) clear}

{p 4 4 2}The command replaces data in memory; specify {cmd:clear} when data are already loaded. The full JSON metadata endpoint and dictionary conversion are future work.{p_end}
