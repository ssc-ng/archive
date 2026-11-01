*! newcombe11 0.6.1 experimental 27oct2026 - Output 03 (group identification)
* Mata routines defined before the Stata program for autoloading.
capture mata: mata drop newcombe11_tailroot()
capture mata: mata drop newcombe11_tail()
capture mata: mata drop newcombe11_binprob()
capture mata: mata drop newcombe11_calc()
capture mata: mata drop newcombe11_wilson()
capture mata: mata drop newcombe11_root()
capture mata: mata drop newcombe11_stat()
capture mata: mata drop newcombe11_qhat()
capture mata: mata drop newcombe11_ll()
/* Mata routines embedded: no separate .mata file required. */
/* Experimental Mata engine for newcombe11. Methods 8/9 included, size limited. */
mata:
real scalar newcombe11_ll(real scalar p, real scalar q, real scalar a, real scalar m, real scalar b, real scalar n)
{
    real scalar s
    if (p<0 | p>1 | q<0 | q>1) return(-1e300)
    s=0
    if (a>0) {
        if (p<=0) return(-1e300)
        s=s+a*ln(p)
    }
    if (m>a) {
        if (p>=1) return(-1e300)
        s=s+(m-a)*ln(1-p)
    }
    if (b>0) {
        if (q<=0) return(-1e300)
        s=s+b*ln(q)
    }
    if (n>b) {
        if (q>=1) return(-1e300)
        s=s+(n-b)*ln(1-q)
    }
    return(s)
}
real scalar newcombe11_qhat(real scalar d, real scalar a, real scalar m, real scalar b, real scalar n)
{
    real scalar lo,hi,x1,x2,f1,f2,i,gr
    lo=max((0,-d)); hi=min((1,1-d))
    if (hi<=lo) return(lo)
    gr=(sqrt(5)-1)/2
    x1=hi-gr*(hi-lo); x2=lo+gr*(hi-lo)
    f1=newcombe11_ll(x1+d,x1,a,m,b,n); f2=newcombe11_ll(x2+d,x2,a,m,b,n)
    for(i=1;i<=115;i++) {
        if (f1<f2) {
            lo=x1
            x1=x2
            f1=f2
            x2=lo+gr*(hi-lo)
            f2=newcombe11_ll(x2+d,x2,a,m,b,n)
        }
        else {
            hi=x2
            x2=x1
            f2=f1
            x1=hi-gr*(hi-lo)
            f1=newcombe11_ll(x1+d,x1,a,m,b,n)
        }
    }
    return((lo+hi)/2)
}
real scalar newcombe11_stat(real scalar d, real scalar a, real scalar m, real scalar b, real scalar n, real scalar method)
{
    real scalar q,p,v,obs,full,part
    obs=a/m-b/n
    q=newcombe11_qhat(d,a,m,b,n); p=q+d
    if (method==7) {
        full=newcombe11_ll(a/m,b/n,a,m,b,n)
        part=newcombe11_ll(p,q,a,m,b,n)
        return(max((0,2*(full-part))))
    }
    v=p*(1-p)/m+q*(1-q)/n
    if (method==6) v=v*(m+n)/(m+n-1)
    if (v<=0) return((abs(obs-d)<1e-12 ? 0 : 1e300))
    return((obs-d)^2/v)
}
real scalar newcombe11_root(real scalar obs, real scalar edge, real scalar z2, real scalar a, real scalar m, real scalar b, real scalar n, real scalar method)
{
    real scalar lo,hi,mid,i
    if (edge<obs) {
        lo=edge
        hi=obs
    }
    else {
        lo=obs
        hi=edge
    }
    if (newcombe11_stat(edge,a,m,b,n,method)<=z2) return(edge)
    for(i=1;i<=100;i++) {
        mid=(lo+hi)/2
        if (edge<obs) {
            if (newcombe11_stat(mid,a,m,b,n,method)>z2) lo=mid
            else hi=mid
        }
        else {
            if (newcombe11_stat(mid,a,m,b,n,method)>z2) hi=mid
            else lo=mid
        }
    }
    return((lo+hi)/2)
}
real rowvector newcombe11_wilson(real scalar a, real scalar n, real scalar z, real scalar cc)
{
    real scalar p,lo,hi,den,term,left,right,mid,i,target
    p=a/n
    if (!cc) {
        den=1+z^2/n
        term=z*sqrt(p*(1-p)/n+z^2/(4*n^2))
        return(((p+z^2/(2*n)-term)/den,(p+z^2/(2*n)+term)/den))
    }
    /* Continuity-corrected score inversion, with boundary conventions.
       Solve |p-q|-1/(2n) = z*sqrt(q*(1-q)/n).
       The lower and upper roots are found separately by bisection. */
    if (a==0) lo=0
    else {
        left=0
        right=p
        for (i=1;i<=100;i++) {
            mid=(left+right)/2
            target=p-mid-1/(2*n)-z*sqrt(mid*(1-mid)/n)
            if (target>0) left=mid
            else right=mid
        }
        lo=(left+right)/2
    }
    if (a==n) hi=1
    else {
        left=p
        right=1
        for (i=1;i<=100;i++) {
            mid=(left+right)/2
            target=mid-p-1/(2*n)-z*sqrt(mid*(1-mid)/n)
            if (target>0) right=mid
            else left=mid
        }
        hi=(left+right)/2
    }
    return((lo,hi))
}

/* Binomial point probability, including degenerate boundary distributions. */
real scalar newcombe11_binprob(real scalar x, real scalar n, real scalar p)
{
    if (p<=0) return(x==0)
    if (p>=1) return(x==n)
    return(exp(lngamma(n+1)-lngamma(x+1)-lngamma(n-x+1)+x*ln(p)+(n-x)*ln(1-p)))
}
/* Return (lower tail, upper tail) for D=A/m-B/n, with weight k on ties.
   Integer comparison i*n-j*m vs a*n-b*m avoids floating point tie errors.
   Nuisance parameter is constrained profile-likelihood maximizer. */
real rowvector newcombe11_tail(real scalar delta, real scalar a, real scalar m, real scalar b, real scalar n, real scalar k)
{
    real scalar q,p,i,j,pi,pj,obs,v,lower,upper
    q=newcombe11_qhat(delta,a,m,b,n)
    p=q+delta
    lower=0
    upper=0
    obs=a*n-b*m
    for (i=0;i<=m;i++) {
        pi=newcombe11_binprob(i,m,p)
        if (pi==0) continue
        for (j=0;j<=n;j++) {
            pj=newcombe11_binprob(j,n,q)
            if (pj==0) continue
            v=pi*pj
            if (i*n-j*m<obs) lower=lower+v
            else if (i*n-j*m>obs) upper=upper+v
            else {
                lower=lower+k*v
                upper=upper+k*v
            }
        }
    }
    return((lower,upper))
}
/* Invert the appropriate one-sided tail area at alpha/2. */
real scalar newcombe11_tailroot(real scalar a, real scalar m, real scalar b, real scalar n, real scalar k, real scalar alpha, real scalar side)
{
    real scalar obs,lo,hi,mid,v,i
    real rowvector tail
    obs=a/m-b/n
    if (side==1) {
        lo=-1
        hi=obs
        tail=newcombe11_tail(lo,a,m,b,n,k)
        if (tail[2]>=alpha/2) return(lo)
        for (i=1;i<=46;i++) {
            mid=(lo+hi)/2
            tail=newcombe11_tail(mid,a,m,b,n,k)
            v=tail[2]
            if (v<alpha/2) lo=mid
            else hi=mid
        }
    }
    else {
        lo=obs
        hi=1
        tail=newcombe11_tail(hi,a,m,b,n,k)
        if (tail[1]>=alpha/2) return(hi)
        for (i=1;i<=46;i++) {
            mid=(lo+hi)/2
            tail=newcombe11_tail(mid,a,m,b,n,k)
            v=tail[1]
            if (v<alpha/2) hi=mid
            else lo=mid
        }
    }
    return((lo+hi)/2)
}

real matrix newcombe11_calc(real scalar a,real scalar m,real scalar b,real scalar n,real scalar level)
{
    real matrix out
    real scalar z,z2,d,v,u,l,t,h,w,rad,j,low,up
    real rowvector w1,w2
    out=J(11,2,.)
    z=invnormal(1-(100-level)/200); z2=z*z
    d=a/m-b/n; v=(a/m)*(1-a/m)/m+(b/n)*(1-b/n)/n
    out[1,.]=(max((-1,d-z*sqrt(v))),min((1,d+z*sqrt(v))))
    out[2,.]=(max((-1,d-z*sqrt(v)-(1/m+1/n)/2)),min((1,d+z*sqrt(v)+(1/m+1/n)/2)))
    u=(1/m+1/n)/4; l=(1/m-1/n)/4
    for(j=3;j<=4;j++) {
        if (j==3) t=(a/m+b/n)/2
        else t=((a+0.5)/(m+1)+(b+0.5)/(n+1))/2
        h=(d+z2*l*(1-2*t))/(1+z2*u)
        rad=u*(4*t*(1-t)-d*d)+2*l*(1-2*t)*d+4*z2*u*u*(1-t)*t+z2*l*l*(1-2*t)^2
        w=z*sqrt(max((0,rad)))/(1+z2*u)
        out[j,.]=(max((-1,h-w)),min((1,h+w)))
    }
    for(j=5;j<=7;j++) {
        low=newcombe11_root(d,-1,z2,a,m,b,n,j)
        up=newcombe11_root(d,1,z2,a,m,b,n,j)
        out[j,.]=(low,up)
    }
    /* Avoid prohibitive O(m*n*iterations) work for large sample sizes.
       Missing endpoints explicitly signal a computational limitation. */
    if ((m+1)*(n+1)<=10000) {
        out[8,.]=(newcombe11_tailroot(a,m,b,n,1,(100-level)/100,1),newcombe11_tailroot(a,m,b,n,1,(100-level)/100,2))
        out[9,.]=(newcombe11_tailroot(a,m,b,n,0.5,(100-level)/100,1),newcombe11_tailroot(a,m,b,n,0.5,(100-level)/100,2))
    }
    w1=newcombe11_wilson(a,m,z,0); w2=newcombe11_wilson(b,n,z,0)
    out[10,.]=(d-sqrt((a/m-w1[1])^2+(w2[2]-b/n)^2),d+sqrt((w1[2]-a/m)^2+(b/n-w2[1])^2))
    /* Newcombe (1999) correction: method 11 MUST use the first,
       geometric expressions for d and e; the alternative score-variance
       expressions printed for method 10 are NOT equivalent here. */
    w1=newcombe11_wilson(a,m,z,1); w2=newcombe11_wilson(b,n,z,1)
    out[11,.]=(d-sqrt((a/m-w1[1])^2+(w2[2]-b/n)^2),d+sqrt((w1[2]-a/m)^2+(b/n-w2[1])^2))
    return(out)
}
end

program define newcombe11, rclass
    version 19.0
    syntax anything(name=inputs) [, BY(varname) METHOD(integer 10) ALL Level(real 95)]
    if (`method'<1 | `method'>11) {
        di as error "method() must be between 1 and 11"
        exit 198
    }
    if (`level'<=0 | `level'>=100) {
        di as error "level() must be strictly between 0 and 100"
        exit 198
    }
    tokenize `"`inputs'"'
    local a "`1'"
    local m "`2'"
    local b "`3'"
    local n "`4'"
    if "`by'" != "" {
        if "`m'" != "" {
            di as error "With by(), supply exactly one binary outcome variable"
            exit 198
        }
        confirm numeric variable `a'
        confirm numeric variable `by'
        quietly count if !missing(`a',`by')
        local N = r(N)
        quietly levelsof `by' if !missing(`a',`by'), local(groups)
        if `: word count `groups'' != 2 {
            di as error "by() must have exactly two observed numeric groups"
            exit 459
        }
        local g1 : word 1 of `groups'
        local g2 : word 2 of `groups'
        * Output 03: descriptive group identities; calculations unchanged.
        local g1desc "`g1'"
        local g2desc "`g2'"
        local vallab : value label `by'
        if `"`vallab'"' != "" {
            local label1 : label `vallab' `g1'
            local label2 : label `vallab' `g2'
            if `"`label1'"' != "" local g1desc `"`g1' (`label1')"'
            if `"`label2'"' != "" local g2desc `"`g2' (`label2')"'
        }
        quietly count if `by'==`g1' & !missing(`a')
        local m=r(N)
        quietly count if `by'==`g2' & !missing(`a')
        local n=r(N)
        quietly count if `by'==`g1' & `a'==1
        local aa=r(N)
        quietly count if `by'==`g2' & `a'==1
        local bb=r(N)
        quietly count if !inlist(`a',0,1) & !missing(`a',`by')
        if r(N)>0 {
            di as error "Outcome must be coded 0/1"
            exit 459
        }
        local a `aa'
        local b `bb'
    }
    else {
        if "`n'"=="" | "`5'"!="" {
            di as error "Immediate syntax: newcombe11 successes1 total1 successes2 total2"
            exit 198
        }
        foreach x in a m b n {
            capture confirm integer number ``x''
            if _rc {
                di as error "All four arguments must be integers"
                exit 198
            }
        }
    }
    if (`m'<=0 | `n'<=0 | `a'<0 | `b'<0 | `a'>`m' | `b'>`n') {
        di as error "Invalid successes or denominators"
        exit 198
    }
    tempname result
    mata: st_matrix("`result'",newcombe11_calc(`a',`m',`b',`n',`level'))
    matrix colnames `result' = lb ub
    matrix rownames `result' = Wald Wald_CC Haldane JeffreysPerks Mee MiettinenNurminen Profile TailExact TailMidP Wilson Wilson_CC
    local diff=`a'/`m'-`b'/`n'
    local methodname1  "Wald"
    local methodname2  "Wald CC"
    local methodname3  "Haldane"
    local methodname4  "Jeffreys-Perks"
    local methodname5  "Mee"
    local methodname6  "Miettinen-Nurminen"
    local methodname7  "Profile likelihood"
    local methodname8  "Tail exact"
    local methodname9  "Tail mid-p"
    local methodname10 "Wilson"
    local methodname11 "Wilson CC"
    local selectedname "`methodname`method''"
    local p1=`a'/`m'
    local p2=`b'/`n'
    local lower=el(`result',`method',1)
    local upper=el(`result',`method',2)
    di as text _newline "Difference of independent proportions (group 1 - group 2)"
    di as text "-------------------------------------------------------"
    if "`by'" != "" {
        di as text "    Group 1 code: `g1desc'"
        di as text "    Group 2 code: `g2desc'"
        di as text "    Difference: Group 1 minus Group 2 (ascending numeric codes)"
        di as text "-------------------------------------------------------"
    }
    if "`all'"!="" {
        di as text "    Group 1:      `a'/`m'  (p1 = " ///
            as result %8.6f `p1' as text ")"
        di as text "    Group 2:      `b'/`n'  (p2 = " ///
            as result %8.6f `p2' as text ")"
        di as text "    Difference: " as result %10.6f `diff'
        di as text "-------------------------------------------------------"
        di as text "                Confidence level: " ///
            as result %6.2f `level' as text "%"
        matlist `result', format(%10.6f) rowtitle(Method)
        if missing(`result'[8,1]) {
            di as text "Methods 8/9 not calculated: (n1+1)*(n2+1) exceeds 10000."
        }
    }
    else {
        di as text "    Method:       " as result %2.0f `method' ///
            as text "    `selectedname'"
        di as text "    Group 1:      `a'/`m'  (p1 = " ///
            as result %8.6f `p1' as text ")"
        di as text "    Group 2:      `b'/`n'  (p2 = " ///
            as result %8.6f `p2' as text ")"
        di as text "    Difference: " as result %10.6f `diff'
        if missing(`lower') | missing(`upper') {
            di as text "    `level'% CI:      not calculated"
            di as error "Method `method' not calculated: sample-size computational limit"
        }
        else {
            di as text "    `level'% CI:      " ///
                as result %10.6f `lower' "  " %10.6f `upper'
        }
    }
    di as text "-------------------------------------------------------"
    return scalar diff = `diff'
    return scalar p1 = `a'/`m'
    return scalar p2 = `b'/`n'
    return scalar lb = el(`result',`method',1)
    return scalar ub = el(`result',`method',2)
    return scalar method = `method'
    return scalar level = `level'
    return scalar n1 = `m'
    return scalar n2 = `n'
    return scalar x1 = `a'
    return scalar x2 = `b'
    return matrix ci = `result', copy
end

