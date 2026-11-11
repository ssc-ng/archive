*! version 1.2.2  09nov2026
*! _idxnl_cd: Pesaran (2015) CD test of cross-sectional dependence for (unbalanced) panel residuals
program define _idxnl_cd, rclass
    version 14
    syntax varname(numeric) [if] [in], Panel(varname) Time(varname) [MINT(integer 3)]
    marksample touse
    mata: _idxnl_cdtest("`varlist'", "`panel'", "`time'", "`touse'", `mint')
    return scalar cd = `cd'
    return scalar p = 2*(1 - normal(abs(`cd')))
    return scalar absrho = `absrho'
    return scalar N_g = `ng'
end

version 14
mata:
void _idxnl_cdtest(string scalar ev, string scalar pv, string scalar tv, string scalar tu,
    real scalar minT)
{
    real colvector e, p, t, up, ut, ii, tt, a, b, m
    real matrix M
    real scalar N, Tn, i, j, s, npair, sr, Tij, den, r, r2
    e = st_data(., ev, tu)
    p = st_data(., pv, tu)
    t = st_data(., tv, tu)
    up = uniqrows(p)
    ut = uniqrows(t)
    N = rows(up)
    Tn = rows(ut)
    M = J(N, Tn, .)
    for (i = 1; i <= rows(e); i++) {
        M[selectindex(up :== p[i]), selectindex(ut :== t[i])] = e[i]
    }
    s = 0
    npair = 0
    sr = 0
    for (i = 1; i < N; i++) {
        for (j = i + 1; j <= N; j++) {
            m = (M[i, .] :< .)' :& (M[j, .] :< .)'
            Tij = sum(m)
            if (Tij < minT) continue
            a = select(M[i, .]', m)
            b = select(M[j, .]', m)
            a = a :- mean(a)
            b = b :- mean(b)
            den = sqrt((a'a)*(b'b))
            if (den == 0) continue
            r = (a'b)/den
            s = s + sqrt(Tij)*r
            sr = sr + abs(r)
            npair++
        }
    }
    st_local("cd", strofreal(sqrt(2/(N*(N - 1)))*s, "%21.15g"))
    st_local("absrho", strofreal(sr/npair, "%21.15g"))
    st_local("ng", strofreal(N))
}
end
