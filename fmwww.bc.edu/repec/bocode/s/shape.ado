*! shape v1.5 (06 Nov 2026)
*! Asjad Naqvi (asjadnaqvi@gmail.com)

* v1.5 (06 Nov 2026): Stata 15 minimum. Alias uses the updated shapes command and its geometry, allocation, and validation fixes.

**** duplicate of shapes

cap program drop shape

program shape
version 15
shapes `0'
end


*** END OF PROGRAM ***
