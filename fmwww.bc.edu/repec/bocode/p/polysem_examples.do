* polysem_examples.do -- examples from the article
version 14
clear all
set more off
webuse gsem_cfa, clear
* two-factor model: 8 binary test items, 5 ordinal attitude items
polysem (MathAb: q1-q8) (MathAtt: att1-att5)
estimates store dwls
matrix list e(resid), format(%6.3f)
* robust to school clustering
polysem (MathAb: q1-q8) (MathAtt: att1-att5), vce(cluster school)
* full-information benchmark (ordinal probit CFA, slower)
gsem (MathAb -> q1-q8, probit) (MathAtt -> att1-att5, oprobit), var(MathAb@1 MathAtt@1)
* standardized loading for a probit item = b/sqrt(1+b^2)
display _b[q1:MathAb]/sqrt(1 + _b[q1:MathAb]^2)
