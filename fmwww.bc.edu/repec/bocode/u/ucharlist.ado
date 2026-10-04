*! Version 1.0.0 2025-05-02
*! Author: Dejin Xie (Nanchang University, China)

****** List Unicode Characters Present in String Variable ******

program define ucharlist, rclass sortpreserve
version 14

syntax varname (string) [if] [in], [ Arabnum(string) Parse(string) Sort More ]

if `c(N)'==0 {
  dis as error "There is no observations in the current dataset."
  exit
}

marksample touse, novarlist

tempvar ComP_`varlist' UcharId

if "`arabnum'"=="" {
  local arabnum "0 1 2 3 4 5 6 7 8 9 . -"
}

if "`sort'"!="" {
  local punct "#$^@%"
}
else {
  local punct "`parse'"
}

local Ucharlist ""
local Arablist ""
local Arablen = 0

preserve

quietly keep if `touse'
quietly keep `varlist'
quietly gen `UcharId'=_n
quietly bysort `varlist' (`UcharId') : keep if _n==1
quietly gen `ComP_`varlist''=`varlist'

foreach ii of local arabnum {
  quietly replace `ComP_`varlist''=subinstr(`ComP_`varlist'',"`ii'","",.)
  quietly bysort `ComP_`varlist'' (`UcharId') : keep if _n==1
  capture assert `varlist'==`ComP_`varlist''
  if !_rc==0 {
    local Arablist "`Arablist'`punct'`ii'"
    local Arablen = `Arablen' + 1
  }
  quietly drop if `ComP_`varlist''==""
  if `c(N)'>0 {
    quietly replace `varlist'=`ComP_`varlist''
  }
  else {
    break
  }
}

sort `UcharId'
local NoArablen = 0
if `c(N)'>0 {
  local Fchar = usubstr("`=`ComP_`varlist''[1]'",1,1)
  while `"`Fchar'"'!="" {
    quietly replace `ComP_`varlist''=usubinstr(`ComP_`varlist'',`"`Fchar'"',"",.)
    quietly drop if `ComP_`varlist''==""
    quietly bysort `ComP_`varlist'' (`UcharId') : keep if _n==1
    local NoArablist "`NoArablist'`punct'`Fchar'"
    local NoArablen = `NoArablen' + 1
    sort `UcharId'
    local Fchar = usubstr("`=`ComP_`varlist''[1]'",1,1)
  }
}

restore

local Ucharlist "`Arablist'`punct'`NoArablist'"
local Ucharlen = `Arablen' + `NoArablen'

if "`sort'"!="" {
  local Space = strpos("`NoArablist'"," ")
  local Ucharlist=subinstr("`Ucharlist'","#$^@%"," ",.)
  local Ucharlist : list sort Ucharlist
  local Ucharlist=subinstr("`Ucharlist'"," ","`parse'",.)
  local Arablist=subinstr("`Arablist'","#$^@%"," ",.)
  local Arablist : list sort Arablist
  local Arablist=subinstr("`Arablist'"," ","`parse'",.)
  local NoArablist=subinstr("`NoArablist'","#$^@%"," ",.)
  local NoArablist : list sort NoArablist
  local NoArablist=subinstr("`NoArablist'"," ","`parse'",.)
  if `Space'>0 {
    local Ucharlist " `Ucharlist'"
    local NoArablist " `NoArablist'"
  }
}

return scalar Ucharlen = `Ucharlen'
return scalar NoArablen = `NoArablen'
return scalar Arablen = `Arablen'

return local Ucharlist `Ucharlist'
return local NoArablist `NoArablist'
return local Arablist `Arablist'

dis as txt "There are " as res "`Ucharlen'" as txt " unicode characters in the variable " as res "`varlist'" as txt " as follows :"
dis as res "`Ucharlist'"

if "`more'"!="" {
  if `Arablen'>0 {
    dis as txt "There are " as res "`Arablen'" as txt " Arabic numerals in the variable " as res "`varlist'" as txt " as follows :"
    dis as res "`Arablist'"
  }
  else {
    dis as txt "There is " as res "0" as txt " Arabic numerals in the variable " as res "`varlist'" as txt " ."
  }
  if `NoArablen'>0 {
    dis as txt "There are " as res "`NoArablen'" as txt " Non Arabic numeral characters in the variable " as res "`varlist'" as txt " as follows :"
    dis as res "`NoArablist'"
  }
  else {
    dis as txt "There is " as res "0" as txt "  Non Arabic numeral characters in the variable " as res "`varlist'" as txt " ."
  }
}

end
