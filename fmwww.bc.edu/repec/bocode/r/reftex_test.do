cd "E:\参考文献获取\"
* Create a direct LaTeX bibliography:

reftex using "cnki.txt", outfile("cnki_refs.tex") lang(mix) replace

* Create a BibTeX library for natbib:

reftex using "cnki.txt", saving("cnki.bib") format(bib) lang(mix) replace

* Inspect citation keys and conversion counts:

return list

* Keep all records, including apparent duplicates:

reftex using "cnki.txt", outfile("all.tex") nodedupe replace

* Use an input whose LaTeX characters have already been escaped:

reftex using "escaped.txt", outfile("escaped.tex") noescape replace


