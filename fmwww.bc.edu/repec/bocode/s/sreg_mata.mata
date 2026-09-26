version 14.2
mata:
/* Native Stata/Mata estimator implementation.
   Rows entering the numerical routines are assignment units. T is the
   expanded cluster outcome and N the represented size (both individual
   quantities when N=1). */
struct sreg_result {
    real rowvector b
    real matrix V, beta, betalarge, bsmall, Vsmall, bbig, Vbig
    real scalar adjusted, design, k, nsmall, nbig, psmall
}

real scalar sreg_api_version()
{
    return(1)
}

void sreg_fail(string scalar msg)
{
    errprintf("sreg: %s\n", msg)
    _error(498)
}

void sreg_warn(string scalar msg)
{
    printf("{txt}Warning: %s\n", msg)
    st_local("sreg_warnings", st_local("sreg_warnings")+msg+" | ")
}

real colvector sreg_ids(real colvector s)
{
    real colvector z, ordering
    real matrix info
    real scalar j
    if(!rows(s)) return(J(0,1,.))
    ordering=order((s,(1::rows(s))),(1,2))
    info=panelsetup(s[ordering],1); z=J(rows(s),1,.)
    for(j=1;j<=rows(info);j++)
        z[ordering[|info[j,1]\info[j,2]|]]=J(info[j,2]-info[j,1]+1,1,j)
    return(z)
}

real scalar sreg_modal(real colvector sizes, real scalar k)
{
    real colvector u
    real scalar modal, best, j, freq
    u=uniqrows(sort(sizes,1)); modal=.; best=0
    if(rows(u)==1) {
        if(k!=. & k!=u[1]) sreg_fail("The supplied small-stratum size k does not match the observed stratum size.")
        return(u[1])
    }
    for(j=1;j<=rows(u);j++) if(k==. ? u[j]<=3 : u[j]==k) {
        freq=mean(sizes:==u[j])
        if(freq>=.25 & freq>best) {
            modal=u[j]
            best=freq
        }
    }
    if(modal==.) sreg_fail("Invalid input: Either all strata are large or too few strata qualify as small. Omit smallstrata or specify the appropriate k().")
    return(modal)
}

// Classify strata by size for estimator selection.
real colvector sreg_classify(real colvector sizes, real scalar k)
{
    real scalar modal
    modal=sreg_modal(sizes,k)
    if(rows(uniqrows(sort(sizes,1)))>1)
        sreg_warn(sprintf("Mixed design detected: at least 25%% of all strata have the same size (k = %g). Weighted estimators will be used.",modal))
    return(sizes:==modal)
}

real colvector sreg_slope(real colvector y, real matrix X)
{
    real matrix Z
    Z=J(rows(X),1,1),X
    if (rank(Z)<cols(Z)) sreg_fail("There are too many covariates relative to the number of observations, or adjustment regressions are unidentified. Reduce covariates or omit adjustment.")
    return(qrsolve(Z,y)[|2\cols(Z)|])
}

real matrix sreg_large_variance(real colvector T, real colvector S,
    real colvector D, real colvector N, real matrix mu, real matrix pi,
    real rowvector b, real scalar hc)
{
    real scalar n,a,h,d,s,fac
    real colvector ix,ir,z,c,t1,t0
    real matrix W,B
    n=rows(T); a=max(D)+1; h=max(S)
    W=B=J(n,cols(b),0)
    for(d=1;d<=cols(b);d++) {
        z=mu[,d+1]-mu[,1]
        t1=z+(T-mu[,d+1]):/pi[,d+1]
        t0=z-(T-mu[,1]):/pi[,1]
        for(s=1;s<=h;s++) {
            ix=selectindex(S:==s)
            c=b[d]*(N[ix]:-mean(N[ix]))
            W[ix,d]=(z[ix]:-mean(z[ix]))-c
            ir=selectindex((S:==s):&(D:==d))
            W[ir,d]=(t1[ir]:-mean(t1[ir]))-b[d]*(N[ir]:-mean(N[ix]))
            ir=selectindex((S:==s):&(D:==0))
            W[ir,d]=(t0[ir]:-mean(t0[ir]))-b[d]*(N[ir]:-mean(N[ix]))
            B[ix,d]=J(rows(ix),1,mean(select(T,(S:==s):&(D:==d)))-mean(select(T,(S:==s):&(D:==0)))-b[d]*mean(N[ix]))
        }
    }
    fac=1
    if(hc) {
        if(n-h*a<=0) sreg_warn("HC1 adjustment unstable or undefined due to degenerate strata-treatment structure; reverting to unadjusted estimator.")
        else fac=n/(n-h*a)
    }
    return((fac*cross(W,W)+cross(B,B))/(n^2*mean(N)^2))
}

struct sreg_result scalar sreg_large(real colvector T, real colvector S,
    real colvector D, real colvector N, real matrix X, real scalar hc,
    real scalar fallback)
{
    struct sreg_result scalar out
    real scalar n, a, h, p, s, r, d, j, ns
    real colvector ix, ir, z
    real matrix mu, pi, slopes
    n=rows(T); a=max(D)+1; h=max(S); p=cols(X)
    if (p & fallback) {
        for(s=1;s<=h;s++) for(r=0;r<a;r++) {
            ir=selectindex((S:==s):&(D:==r))
            if (!rows(ir)) sreg_fail("Every treatment arm, including control, must occur in every stratum.")
            for(j=1;j<=p;j++) if (min(X[ir,j])==max(X[ir,j])) {
                sreg_warn("One or more covariates do not vary within one or more stratum-treatment combinations. Proceeding with the unadjusted estimator.")
                X=J(n,0,.); p=0; break
            }
        }
    }
    mu=J(n,a,0); pi=J(n,a,.); slopes=J(h*a,p,.)
    for(s=1;s<=h;s++) {
        ix=selectindex(S:==s); ns=rows(ix)
        for(r=0;r<a;r++) {
            ir=selectindex((S:==s):&(D:==r))
            if (!rows(ir)) sreg_fail("Every treatment arm, including control, must occur in every stratum.")
            pi[ix,r+1]=J(ns,1,rows(ir)/ns)
            if(p) {
                slopes[(s-1)*a+r+1,.]=sreg_slope(T[ir],X[ir,.])'
                mu[ix,r+1]=X[ix,.]*slopes[(s-1)*a+r+1,.]'
            }
        }
    }
    out.b=J(1,a-1,.)
    for(d=1;d<a;d++) {
        z=mu[,d+1]-mu[,1]
        out.b[d]=mean(z+(D:==d):*(T-mu[,d+1]):/pi[,d+1]-(D:==0):*(T-mu[,1]):/pi[,1])/mean(N)
    }
    out.V=sreg_large_variance(T,S,D,N,mu,pi,out.b,hc)
    out.beta=slopes; out.adjusted=p>0; out.design=0; out.k=.
    return(out)
}

/* Bilinear paired-strata variance and cross-treatment covariances. */
real scalar sreg_small_cross(real colvector U, real colvector V,
    real colvector S, real colvector D, real scalar fac)
{
    real scalar h, n, a, r, s, j, rho, cv, ans
    real matrix su, sv, grouped, info, sums
    real colvector ur, vr, ix, ids
    real rowvector gu, gv, counts
    h=max(S); n=rows(S); a=max(D)+1
    su=sv=J(h,a,0); gu=gv=counts=J(1,a,0); ans=0
    for(r=0;r<a;r++) {
        ur=select(U,D:==r); vr=select(V,D:==r)
        counts[r+1]=rows(ur)/h; gu[r+1]=mean(ur); gv[r+1]=mean(vr)
        // Aggregate each treatment's strata once, preserving within-cell order.
        ix=selectindex(D:==r)
        grouped=sort((S[ix],U[ix],V[ix],ix),(1,4))
        info=panelsetup(grouped,1)
        sums=panelsum(grouped[,2..3],info)
        ids=grouped[info[,1],1]
        su[ids,r+1]=sums[,1]; sv[ids,r+1]=sums[,2]
        rho=0
        for(j=1;j<h;j=j+2) rho=rho+(su[j,r+1]*sv[j+1,r+1]+sv[j,r+1]*su[j+1,r+1])/h/counts[r+1]^2
        cv=mean((ur:-gu[r+1]):*(vr:-gv[r+1]))
        ans=ans+fac*(cv-rho+gu[r+1]*gv[r+1])/(rows(ur)/n)+rho-gu[r+1]*gv[r+1]
    }
    for(r=1;r<=a;r++) for(j=1;j<=a;j++) if(r!=j) {
        ans=ans+mean(su[,r]:*sv[,j])/(counts[r]*counts[j])-gu[r]*gv[j]
    }
    return(ans/n)
}

struct sreg_result scalar sreg_small(real colvector T, real colvector S,
    real colvector D, real colvector N, real matrix X, real scalar hc,
    real scalar cluster)
{
    struct sreg_result scalar out
    real scalar n, a, h, p, d, s, j, fac
    real matrix dx, W, meansT, meansX, grouped, info, sums
    real colvector dy, ix, iz, res, beta, counts
    n=rows(T); h=max(S); a=max(D)+1; p=cols(X)
    if(mod(h,2)) sreg_fail("The paired-strata variance estimator requires an even number of strata.")
    if(h<2) sreg_fail("At least two small strata are required.")
    out.b=J(1,a-1,.); out.beta=J(a-1,p,.); W=J(n,a-1,0)
    // Compute stratum-arm means once rather than repeatedly scanning S and D.
    meansT=J(h,a,.); meansX=J(h*a,p,.)
    for(j=0;j<a;j++) {
        ix=selectindex(D:==j)
        if(!rows(ix)) sreg_fail("Every treatment arm, including control, must occur in every small stratum.")
        grouped=sort((S[ix],ix,T[ix],X[ix,.]),(1,2))
        info=panelsetup(grouped,1)
        if(rows(info)!=h) sreg_fail("Every treatment arm, including control, must occur in every small stratum.")
        counts=info[,2]-info[,1]:+1
        sums=panelsum(grouped[,3..(3+p)],info):/counts
        meansT[,j+1]=sums[,1]
        if(p) meansX[|(j*h+1),1\((j+1)*h),p|]=sums[,2..(p+1)]
    }
    for(d=1;d<a;d++) {
        dy=meansT[,d+1]-meansT[,1]
        dx=J(h,p,.)
        if(p) dx=meansX[|(d*h+1),1\((d+1)*h),p|]-meansX[|1,1\h,p|]
        res=T
        if(p) {
            beta=sreg_slope(dy,dx); out.beta[d,.]=beta'
            res=T-(X:-mean(X))*beta
        }
        out.b[d]=(mean(select(res,D:==d))-mean(select(res,D:==0)))/mean(N)
        W[,d]=((D:==d)-(D:==0)):*res/mean(N)
        if(cluster) for(j=0;j<a;j++) {
            ix=selectindex(D:==j)
            W[ix,d]=W[ix,d]-out.b[d]*(rows(ix)/n)*N[ix]/mean(N)
        }
    }
    fac=1
    if(hc & (cluster | p)) {
        if(h<=p+1) sreg_fail("Variance estimate is not finite. Reduce covariates or use nohc1.")
        fac=h/(h-p-1)
    }
    out.V=J(a-1,a-1,.)
    for(d=1;d<a;d++) for(j=d;j<a;j++) {
        out.V[d,j]=out.V[j,d]=sreg_small_cross(W[,d],W[,j],S,D,fac)
    }
    if(any(diagonal(out.V):<0)) sreg_fail("The paired-strata variance estimate is negative; inference is undefined for this sample.")
    out.adjusted=p>0; out.design=1; out.k=n/h
    return(out)
}

struct sreg_result scalar sreg_fit(real colvector T, real colvector S,
    real colvector D, real colvector N, real matrix X, real scalar hc,
    real scalar small, real scalar k, real scalar cluster)
{
    struct sreg_result scalar out, lo, hi
    real colvector sizes, us, flag, il, ih
    real matrix info
    real scalar s,h, modal, j, weight, sharevar, nn
    real rowvector delta
    h=max(S); info=panelsetup(sort(S,1),1)
    sizes=info[,2]-info[,1]:+1
    us=uniqrows(sort(sizes,1))
    if(!small) {
        if(rows(us)==1 & us[1]<=5) sreg_warn("All strata have the same small number of assignment units, but smallstrata was not specified.")
        for(j=1;j<=rows(us);j++) if((k==. ? us[j]<=3 : us[j]==k) & mean(sizes:==us[j])>=.25) {
            sreg_warn("At least 25% of strata are small, but smallstrata was not specified; consider the small/mixed procedure."); break
        }
        return(sreg_large(T,S,D,N,X,hc,1))
    }
    if(rows(us)==1) {
        if(k!=. & k!=us[1]) sreg_fail("The supplied small-stratum size k does not match the observed stratum size.")
        return(sreg_small(T,S,D,N,X,hc,cluster))
    }
    flag=sreg_classify(sizes,k)
    modal=min(select(sizes,flag))
    flag=flag[S]; il=selectindex(flag); ih=selectindex(!flag)
    lo=sreg_small(T[il],sreg_ids(S[il]),D[il],N[il],X[il,.],hc,cluster)
    if(cols(X)) {
        for(s=1;s<=h;s++) if(sizes[s]!=modal) for(j=0;j<=max(D);j++) {
            nn=sum((S:==s):&(D:==j))
            if(nn<cols(X)+1) sreg_fail("The large-strata component of the mixed design cannot support the requested covariate adjustment. Reduce covariates or omit adjustment.")
        }
    }
    hi=sreg_large(T[ih],sreg_ids(S[ih]),D[ih],N[ih],X[ih,.],hc,0)
    weight=sum(N[il])/sum(N); delta=lo.b-hi.b
    sharevar=mean(N:^2:*(flag:-weight):^2)/mean(N)^2/rows(N)
    out.b=weight*lo.b+(1-weight)*hi.b
    out.V=weight^2*lo.V+(1-weight)^2*hi.V+sharevar*cross(delta,delta)
    out.bsmall=lo.b; out.Vsmall=lo.V; out.bbig=hi.b; out.Vbig=hi.V
    out.beta=lo.beta; out.betalarge=hi.beta
    out.adjusted=cols(X)>0; out.design=2; out.k=modal
    out.nsmall=rows(il); out.nbig=rows(ih); out.psmall=weight
    return(out)
}

void sreg_run(string scalar yv, string scalar dv, string scalar sv,
    string scalar gv, string scalar nv, string scalar xv, string scalar sample,
    real scalar hc, real scalar small, real scalar k)
{
    real matrix X, agg, xx, info
    real colvector Y,D,S,G,N,u,ix, ordering
    real scalar n,j,p,cl,changed
    struct sreg_result scalar out
    Y=st_data(.,yv,sample); D=st_data(.,dv,sample); n=rows(Y)
    S=(sv=="" ? J(n,1,1) : st_data(.,sv,sample))
    X=(xv=="" ? J(n,0,.) : st_data(.,tokens(xv),sample))
    cl=(gv!=""); p=cols(X)
    if(small & sv=="") sreg_fail("Strata indicator variable has not been provided; smallstrata requires strata().")
    if(any(D:!=floor(D)) | any(S:!=floor(S))) sreg_fail("Strata and treatment must contain only integer values.")
    if(min(S)!=1) sreg_fail("The strata should be indexed by {1, 2, 3, ...}.")
    if(min(D)!=0) sreg_fail("The treatments should be indexed by {0, 1, 2, ...}, with control coded 0.")
    if(rows(uniqrows(sort(S,1)))!=max(S) | rows(uniqrows(sort(D,1)))!=max(D)+1) sreg_fail("Variables S and D must not contain skipped values within the range.")
    if(max(D)<1) sreg_fail("At least one active treatment and a control arm are required.")
    N=J(n,1,1)
    if(cl) {
        G=st_data(.,gv,sample)
        if(any(G:!=floor(G))) sreg_fail("Cluster identifiers must contain only integer values.")
        if(nv!="") {
            N=st_data(.,nv,sample)
            if(any(N:!=floor(N))) sreg_fail("Cluster sizes must contain only integer values.")
            if(min(N)<=0) sreg_fail("Cluster sizes must be positive.")
        }
        else sreg_warn("Cluster sizes have not been provided; using the number of available observations in every cluster.")
        // Stable grouping avoids scanning every observation for each cluster.
        ordering=order((G,(1::n)),(1,2))
        Y=Y[ordering]; S=S[ordering]; D=D[ordering]; G=G[ordering]
        N=N[ordering]; X=X[ordering,.]
        info=panelsetup(G,1); u=G[info[,1]]
        agg=J(rows(u),4+p,.); changed=0
        for(j=1;j<=rows(u);j++) {
            ix=(info[j,1]::info[j,2])
            if(min(S[ix])!=max(S[ix]) | min(D[ix])!=max(D[ix]) | min(N[ix])!=max(N[ix])) sreg_fail("The values for S, D, and Ng must be consistent within each cluster.")
            agg[j,1..4]=(mean(Y[ix]),S[ix[1]],D[ix[1]],(nv=="" ? rows(ix) : N[ix[1]]))
            if(p) {
                xx=X[ix,.]; agg[j,5..(4+p)]=mean(xx)
                if(any(colmin(xx):!=colmax(xx))) changed=1
            }
        }
        if(changed) sreg_warn("sreg cannot use individual-level covariates for cluster adjustment; covariates have been aggregated to their cluster-level averages.")
        Y=agg[,1]; S=agg[,2]; D=agg[,3]; N=agg[,4]
        X=(p ? agg[,5..(4+p)] : J(rows(Y),0,.))
    }
    out=sreg_fit(Y:*N,S,D,N,X,hc,small,k,cl)
    if(any(out.b:>=.) | any(out.V:>=.)) sreg_fail("Nonfinite estimates or variance; check treatment cells and adjustment identification.")
    st_matrix(st_local("b"),out.b); st_matrix(st_local("V"),out.V)
    if(cols(out.beta)) st_matrix(st_local("beta"),out.beta)
    st_numscalar(st_local("nunits"),rows(Y)); st_numscalar(st_local("nstrata"),max(S))
    st_numscalar(st_local("adjusted"),out.adjusted); st_numscalar(st_local("design"),out.design)
    st_numscalar(st_local("ksmall"),out.k)
    if(out.design==2) {
        if(cols(out.betalarge)) st_matrix(st_local("betabig"),out.betalarge)
        st_matrix(st_local("bs"),out.bsmall); st_matrix(st_local("Vs"),out.Vsmall)
        st_matrix(st_local("bb"),out.bbig); st_matrix(st_local("Vb"),out.Vbig)
        st_numscalar(st_local("ps"),out.psmall)
        st_numscalar(st_local("ns"),out.nsmall); st_numscalar(st_local("nb"),out.nbig)
    }
}
end
