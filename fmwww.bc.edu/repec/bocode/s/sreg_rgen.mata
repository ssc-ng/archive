version 14.2
mata:
void sreg_rgen_version() {}
void sreg_rg_check(real scalar ok, string scalar message)
{
    if (!ok) {
        errprintf("%s\n", message)
        _error(198)
    }
}
real colvector sreg_rg_strata(real colvector w, real scalar h, real scalar cluster)
{
    real scalar lo, hi
    real colvector s
    lo = cluster ? min(w) : -2.25
    hi = cluster ? max(w) : 2.25
    if (hi == lo) return(J(rows(w),1,1))
    s = ceil((w:-lo):/(hi-lo)*h)
    // Include the minimum matching value in the first stratum.
    s = rowmax((s,J(rows(w),1,1)))
    return(rowmin((s,J(rows(w),1,h))))
}
real colvector sreg_rg_assign(real colvector s, real matrix probs, real rowvector sizes, real scalar small)
{
    real colvector d, ix, labels, a
    real rowvector counts
    real scalar j, t, n, pos
    d = J(rows(s),1,0)
    labels = uniqrows(sort(s,1))
    for (j=1;j<=rows(labels);j++) {
        ix = selectindex(s:==labels[j])
        n = rows(ix)
        if (small) counts = sizes
        else {
            counts = floor(n*probs[labels[j],.])
            counts[1] = n-sum(counts[|2\cols(counts)|])
        }
        a = J(n,1,0)
        pos = counts[1]+1
        for (t=2;t<=cols(counts);t++) {
            if (counts[t]) a[|pos\pos+counts[t]-1|] = J(counts[t],1,t-1)
            pos = pos+counts[t]
        }
        d[ix] = a[order(runiform(n,1),(1))]
    }
    return(d)
}
real matrix sreg_rg_component(real scalar n, real scalar nmax, real scalar h,
    real rowvector tau, real rowvector gamma, real scalar cluster, real scalar cov,
    real scalar small, real scalar k, real rowvector sizes, real matrix probs,
    real colvector effects, real matrix te)
{
    real colvector ng, w, x1, x2, m, s, d, id, ix, y, ord
    real matrix eps, out
    real scalar g, pos, total, a
    ng = cluster ? 10*(floor(runiform(n,1)*(nmax/10)):+1) : J(n,1,1)
    total = sum(ng)
    w = sqrt(20)*(rbeta(n,1,2,2):-.5)
    x1 = rnormal(n,1,cluster ? 0 : 5,cluster ? 1 : 2)
    x2 = rnormal(n,1,cluster ? 0 : 2,1)
    m = gamma[1]*w
    if (cluster | cov) m = m+gamma[2]*x1+gamma[3]*x2
    eps = rnormal(total,cols(tau)+1,0,1)
    if (cluster) eps[.,2..cols(eps)] = sqrt(2)*eps[.,2..cols(eps)]
    if (small) {
        ord = order(w,1)
        s = J(n,1,.)
        s[ord] = ceil((1::n)/k)
    }
    else s = sreg_rg_strata(w,h,cluster)
    d = sreg_rg_assign(s,probs,sizes,small)
    id = J(total,1,.)
    pos = 1
    for (g=1;g<=n;g++) {
        id[|pos\pos+ng[g]-1|] = J(ng[g],1,g)
        pos = pos+ng[g]
    }
    y = m[id,1]
    for (a=0;a<=cols(tau);a++) {
        ix = selectindex(d[id,1]:==a)
        if (rows(ix)) {
            y[ix] = (y[ix]+eps[ix,a+1]):+(a ? tau[a] : 0)
            if (rows(effects)) y[ix] = y[ix]+effects[s[id[ix],1],1]
            if (a & rows(te)) y[ix] = y[ix]+te[s[id[ix],1],a]:-tau[a]
        }
    }
    out = (y,s[id,1],d[id,1],id,ng[id,1],x1[id,1],x2[id,1])
    if (small & !cluster) out = out[ord,.]
    return(out)
}
void sreg_rgen_run(real scalar n, real scalar nmax, real scalar h, real scalar cluster,
    real scalar cov, real scalar small, real scalar mixed, real scalar k, real scalar ns)
{
    real rowvector tau, gamma, sizes, keep
    real matrix probs, te, out, big
    real colvector effects
    real scalar arms, j
    string rowvector names
    tau = strtoreal(tokens(st_local("tau")))
    gamma = strtoreal(tokens(st_local("gamma")))
    arms = cols(tau)+1
    sreg_rg_check(n>0 & n<. & h>0 & h<. & k>0 & k<.,"n(), strata(), and k() must be positive integers.")
    sreg_rg_check(!hasmissing(tau) & !hasmissing(gamma),"tau() and gamma() must be finite.")
    if (cluster) sreg_rg_check(nmax>=10 & nmax<. & mod(nmax,10)==0,"nmax() must be a positive multiple of 10.")
    sreg_rg_check(ns==-1 | mixed,"nsmall() requires mixedstrata.")
    sizes = strtoreal(tokens(st_local("treatsizes")))
    if (!cols(sizes)) {
        if (mixed) {
            sizes = J(1,arms,floor(k/arms))
            for (j=1;j<=mod(k,arms);j++) sizes[j] = sizes[j]+1
        }
        else sizes = (1,1,1)
    }
    if (small | mixed) sreg_rg_check(cols(sizes)==arms & !hasmissing(sizes) & all(sizes:>=0) & all(sizes:==floor(sizes)) & sum(sizes)==k,"treatsizes() must contain one nonnegative integer per arm, including control, summing to k().")
    if (small) sreg_rg_check(mod(n,k)==0,"n() must be divisible by k().")
    if (mixed) {
        if (ns==-1) ns = floor(n/(2*k))*k
        sreg_rg_check(ns>0 & ns<n & mod(ns,k)==0,"nsmall() must be positive, smaller than n(), and divisible by k().")
        sreg_rg_check(n-ns>h*k,"The large component must contain more than strata()*k() units.")
        sreg_rg_check(ns/k>h,"The mixed design must contain more small strata than large strata.")
    }
    else ns = small ? n : 0
    sreg_rg_check(!(cluster | small | mixed) | st_local("allocation")+st_local("stratumeffects")+st_local("treatmenteffects")=="","Custom allocations and effects require individual large strata.")
    probs = J(h,arms,1/arms)
    if (st_local("allocation")!="") probs = st_matrix(st_local("allocation"))
    sreg_rg_check(rows(probs)==h & cols(probs)==arms,"allocation() must have strata() rows and one column per arm including control.")
    sreg_rg_check(!hasmissing(probs) & all(probs:>0) & all(abs(rowsum(probs):-1):<1e-10),"Allocation probabilities must be positive and each row must sum to one.")
    effects = vec(strtoreal(tokens(st_local("stratumeffects"))))
    if (rows(effects)) sreg_rg_check(rows(effects)==h & !hasmissing(effects),"stratumeffects() must contain one finite value per stratum.")
    te = J(0,0,.)
    if (st_local("treatmenteffects")!="") {
        te = st_matrix(st_local("treatmenteffects"))
        sreg_rg_check(rows(te)==h & cols(te)==arms-1 & !hasmissing(te),"treatmenteffects() must have strata() rows and one finite column per active arm.")
    }
    out = sreg_rg_component(mixed ? ns : n,nmax,h,tau,gamma,cluster,cov,small|mixed,k,sizes,probs,effects,te)
    if (mixed) {
        big = sreg_rg_component(n-ns,nmax,h,tau,gamma,cluster,cov,0,k,sizes,probs,effects,te)
        big[.,2] = big[.,2]:+ns/k
        big[.,4] = big[.,4]:+ns
        out = out\big
    }
    names = ("Y","S","D","G_id","Ng","x_1","x_2")
    keep = cluster ? (1,2,3,4,5) : (1,2,3)
    if (cov) keep = (keep,6,7)
    stata("clear")
    st_addobs(rows(out))
    (void) st_addvar("double",names[keep])
    st_store(.,names[keep],out[.,keep])
    st_local("actualsmall",strofreal(ns))
    st_local("gendesign",mixed ? "mixed" : (small ? "small" : "large"))
}
end
