cd "E:\参考文献获取"

adopath ++ "E:\参考文献获取"

getref "corporate social responsibility", saving("references.bib") ///
	replace n(20) yearfrom(2020) yearto(2026) email("agd2010@yeah.net")
	
getref, saving("reference.txt") doi("10.69979/3029-2700.24.7.020") ///
	format(txt) language(chinese) replace
	
getref, saving("references.bib") doi("10.1257/aer.109.4.1197") replace

getref, saving("references.bib") ///
	doi("10.1257/aer.109.4.1197; 10.1002/csr.2218") replace n(2)
	
* Create an empirical-paper framework and replace its example bibliography:
art2tex, filename("paper3") replace
getref "digital transformation and firm performance", ///
	saving("references2.bib") replace n(20) yearfrom(2018) yearto(2026)
return list

* Add another batch to the same bibliography:
getref "corporate governance", saving("references2.bib") ///
	append n(10) yearfrom(2020)






