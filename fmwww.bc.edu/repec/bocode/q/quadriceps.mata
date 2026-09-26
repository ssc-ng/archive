*! version 0.1.2  24sep2026  Joris Pinkse
*! quadriceps.mata: the Mata code of the quadriceps package, compiled by quadriceps.ado on first use.
*! Functions defined inside an ado-file are private to it ([M-1] Ado), so the code lives here and is
*! loaded with -run-, which makes ghpos(), lepos(), quadriceps_rule() etc. usable from Mata directly.

version 16
mata:

// ------------------------------------------------------------------------------------------
// Data files.  The rules are in quadriceps_rules.bin (format QUADRICEPS1, see FORMAT.md in the
// repository): an ASCII header line, an index of little-endian 64-bit integers, then flat
// little-endian doubles.  quadriceps_index.tsv is the catalog with the metadata of each rule.
// Both are found along the ado-path, where net install puts them.
// ------------------------------------------------------------------------------------------

string scalar quadriceps_datafile(string scalar name)
{
    string scalar fn

    fn = findfile(name)
    if (fn == "") {
        errprintf("quadriceps: data file %s not found along the ado-path; reinstall the package\n", name)
        exit(601)
    }
    return(fn)
}

// s split on every occurrence of sep (empty pieces kept)
string rowvector quadriceps_split(string scalar s, string scalar sep)
{
    string rowvector r
    string scalar t
    real scalar i

    r = J(1, 0, "")
    t = s
    while ((i = strpos(t, sep)) > 0) {
        r = r, substr(t, 1, i - 1)
        t = substr(t, i + 1, .)
    }
    return((r, t))
}

real scalar quadriceps_col(string rowvector header, string scalar name)
{
    real scalar j

    for (j = 1; j <= cols(header); j++) {
        if (header[j] == name) return(j)
    }
    errprintf("quadriceps_index.tsv: column %s missing\n", name)
    exit(498)
}

colvector quadriceps_bufio()
{
    colvector C

    C = bufio()
    bufbyteorder(C, 2)                      // 2 = LOHI: little-endian, as the file declares
    return(C)
}

// The index of the binary file: one row per rule, columns
// family (0 GH, 1 Le), d, p, q, n, offset, nbytes, source_id.
real matrix quadriceps_binindex(string scalar fn)
{
    real scalar fh, H, cells, i, ok
    string scalar B
    string rowvector tok, kv
    colvector C
    real matrix V, I

    fh = fopen(fn, "r")
    B = fread(fh, 2048)
    H = strpos(B, char(10))                 // the header ends at the first newline; H bytes precede the index
    if (H == 0 | substr(B, 1, 11) != "QUADRICEPS1") {
        fclose(fh)
        errprintf("%s: not a QUADRICEPS1 file\n", fn)
        exit(498)
    }
    tok = tokens(substr(B, 1, H - 1))
    cells = .
    ok = 1
    for (i = 2; i <= cols(tok); i++) {
        kv = quadriceps_split(tok[i], "=")
        if (cols(kv) != 2) continue
        if (kv[1] == "cells") cells = strtoreal(kv[2])
        else if (kv[1] == "fmt") ok = ok & (kv[2] == "1")
        else if (kv[1] == "endian") ok = ok & (kv[2] == "little")
        else if (kv[1] == "float") ok = ok & (kv[2] == "binary64")
        else if (kv[1] == "index_fields") ok = ok & (kv[2] == "8")
    }
    if (!ok | missing(cells)) {
        fclose(fh)
        errprintf("%s: unsupported QUADRICEPS1 variant\n", fn)
        exit(498)
    }
    fseek(fh, H, -1)
    C = quadriceps_bufio()
    V = fbufget(C, fh, "%4bu", cells, 16)    // Mata has no 8-byte integers: read each as two 32-bit halves
    fclose(fh)
    I = V[., (1..8) * 2 :- 1] + 4294967296 * V[., (1..8) * 2]
    if (any(I[., 1] :> 1) | any(I[., 2] :> 64) | any(I[., 7] :!= I[., 5] :* (I[., 2] :+ 1) * 8)) {
        errprintf("%s: inconsistent index (byte order?)\n", fn)
        exit(498)
    }
    return(I)
}

// The catalog: M has one row per stored rule, columns
//   1 family (0 GH, 1 Le)   2 d   3 p   4 q   5 n   6 offset   7 nbytes   8 source_id
//   9 moller   10 relerr   11 minweight   12 interior (0/1)
// and origin[i] is the text of the origin column.  The catalog (index.tsv) supplies the metadata,
// the binary file's own index the offsets; the two must agree.
void quadriceps_catalog(real matrix M, string matrix origin)
{
    real scalar fh, i, j, fam, p, cf, cd, cp, cn, cm, cr, cw, ci, co, cs
    string scalar line
    string rowvector header, f
    real matrix B
    real colvector jj

    fh = fopen(quadriceps_datafile("quadriceps_index.tsv"), "r")
    header = J(1, 0, "")
    M = J(0, 12, .)
    origin = J(0, 1, "")
    while ((line = fget(fh)) != J(0, 0, "")) {
        if (substr(line, 1, 1) == "#" | strtrim(line) == "") continue
        f = quadriceps_split(line, char(9))
        if (cols(header) == 0) {
            header = f
            cf = quadriceps_col(header, "family")
            cd = quadriceps_col(header, "d")
            cp = quadriceps_col(header, "p")
            cn = quadriceps_col(header, "n")
            cm = quadriceps_col(header, "moller")
            cr = quadriceps_col(header, "relerr")
            cw = quadriceps_col(header, "minweight")
            ci = quadriceps_col(header, "interior")
            co = quadriceps_col(header, "origin")
            cs = quadriceps_col(header, "source_id")
            continue
        }
        if (cols(f) != cols(header)) {
            fclose(fh)
            errprintf("quadriceps_index.tsv: a line has %g fields, the header %g\n", cols(f), cols(header))
            exit(498)
        }
        fam = (f[cf] == "gh" ? 0 : (f[cf] == "le" ? 1 : .))
        p = strtoreal(f[cp])
        M = M \ (fam, strtoreal(f[cd]), p, (p + 1) / 2, strtoreal(f[cn]), ., ., strtoreal(f[cs]),
                 strtoreal(f[cm]), strtoreal(f[cr]), strtoreal(f[cw]), (f[ci] == "yes"))
        origin = origin \ f[co]
    }
    fclose(fh)
    if (rows(M) == 0 | any(M[., 1] :== .)) {
        errprintf("quadriceps_index.tsv: no rules, or an unknown family\n")
        exit(498)
    }
    B = quadriceps_binindex(quadriceps_datafile("quadriceps_rules.bin"))
    if (rows(B) != rows(M)) {
        errprintf("quadriceps: index.tsv and rules.bin disagree (%g and %g rules)\n", rows(M), rows(B))
        exit(498)
    }
    for (i = 1; i <= rows(M); i++) {
        jj = selectindex(B[., 1] :== M[i, 1] :& B[., 2] :== M[i, 2] :& B[., 3] :== M[i, 3])
        if (length(jj) != 1) {
            errprintf("quadriceps: index.tsv and rules.bin disagree (d = %g, p = %g)\n", M[i, 2], M[i, 3])
            exit(498)
        }
        j = jj[1]
        if (B[j, 5] != M[i, 5]) {
            errprintf("quadriceps: index.tsv and rules.bin disagree on n for d = %g, p = %g\n", M[i, 2], M[i, 3])
            exit(498)
        }
        M[i, 6] = B[j, 6]
        M[i, 7] = B[j, 7]
    }
}

// The stored rule of catalog row i, in the normalized frame: X is n x d, w has n positive weights.
void quadriceps_stored(real matrix M, real scalar i, real matrix X, real matrix w)
{
    real scalar fh, n, d
    colvector C
    real matrix A

    n = M[i, 5]
    d = M[i, 2]
    fh = fopen(quadriceps_datafile("quadriceps_rules.bin"), "r")
    fseek(fh, M[i, 6], -1)
    C = quadriceps_bufio()
    A = fbufget(C, fh, "%8z", n, d + 1)     // row-major on disk: one node per row, x1..xd then w
    fclose(fh)
    X = A[., 1..d]
    w = A[., d + 1]
    if (any(w :<= 0) | any(w :> 1)) {
        errprintf("quadriceps_rules.bin: unreadable rule (byte order?) for d = %g, p = %g\n", d, M[i, 3])
        exit(498)
    }
}

// ------------------------------------------------------------------------------------------
// Which rule answers a request (d, p): a stored one, or the cheapest tensor product.
// ------------------------------------------------------------------------------------------

real scalar quadriceps_family(string scalar family)
{
    if (family == "gh") return(0)
    if (family == "le") return(1)
    errprintf("unknown family %s; use gh or le\n", family)
    exit(198)
}

void quadriceps_checkargs(real scalar d, real scalar p, real scalar pragmatic)
{
    if (missing(d) | d != floor(d) | d < 1) {
        errprintf("the dimension d must be a whole number at least 1\n")
        exit(198)
    }
    if (missing(p) | p != floor(p) | p < 0) {
        errprintf("the degree p must be a whole number at least 0\n")
        exit(198)
    }
    if (missing(pragmatic)) {
        errprintf("pragmatic must be 0 or 1\n")
        exit(198)
    }
}

// Catalog row of the smallest stored rule of family fam, dimension d and degree >= p
// (ties: the lowest degree), or 0 if there is none.  A rule exact to degree p' >= p is a rule of degree p.
real scalar quadriceps_best(real matrix M, real scalar fam, real scalar d, real scalar p)
{
    real colvector idx
    real scalar best, i, c

    idx = selectindex(M[., 1] :== fam :& M[., 2] :== d :& M[., 3] :>= p)
    best = 0
    for (i = 1; i <= length(idx); i++) {
        c = idx[i]
        if (best == 0) best = c
        else if (M[c, 5] < M[best, 5] | (M[c, 5] == M[best, 5] & M[c, 3] < M[best, 3])) best = c
    }
    return(best)
}

// Node count of the single-rule answer for (k, p): the Gauss rule in one dimension, a stored
// rule otherwise; missing if there is none.
real scalar quadriceps_atom(real matrix M, real scalar fam, real scalar k, real scalar p)
{
    real scalar i

    if (k == 1) return(floor(p / 2) + 1)
    i = quadriceps_best(M, fam, k, p)
    return(i ? M[i, 5] : .)
}

// The cheapest product of single rules covering d dimensions at degree p, by dynamic programming
// over the dimension (a product of products is a product, so splitting in two is enough).  A
// single stored rule wins ties.  Returns the node count and fills dims with the dimensions of
// the factors, in the order of the columns of the result.
real scalar quadriceps_cheapest(real matrix M, real scalar fam, real scalar d, real scalar p, real matrix dims)
{
    real colvector cost, split
    real scalar k, j, c

    cost = J(d, 1, .)
    split = J(d, 1, 0)
    for (k = 1; k <= d; k++) {
        cost[k] = quadriceps_atom(M, fam, k, p)
        for (j = 1; j <= floor(k / 2); j++) {
            c = cost[j] * cost[k - j]
            if (c < cost[k]) {              // also true when cost[k] is missing
                cost[k] = c
                split[k] = j
            }
        }
    }
    dims = quadriceps_unroll(split, d)
    return(cost[d])
}

real rowvector quadriceps_unroll(real colvector split, real scalar k)
{
    if (split[k] == 0) return(k)
    return((quadriceps_unroll(split, split[k]), quadriceps_unroll(split, k - split[k])))
}

void quadriceps_norule(real matrix M, real scalar fam, real scalar d, real scalar p)
{
    real colvector ps
    string scalar have, at

    ps = select(M[., 3], M[., 1] :== fam :& M[., 2] :== d)
    if (length(ps) == 0) have = sprintf("no rules are stored for d = %g", d)
    else have = sprintf("stored rules for d = %g reach q = %g, p = %g", d, (max(ps) + 1) / 2, max(ps))
    if (mod(p, 2) == 1) at = sprintf("q = %g (p = %g)", (p + 1) / 2, p)
    else at = sprintf("p = %g", p)
    errprintf("no stored positive-weight %s rule for d = %g, %s: %s; the option pragmatic returns the cheapest tensor product of lower-dimensional rules instead\n",
              (fam ? "Le" : "GH"), d, at, have)
    exit(499)
}

real scalar quadriceps_plan(real matrix M, real scalar fam, real scalar d, real scalar p, real scalar pragmatic, real matrix dims)
{
    real scalar n

    if (pragmatic) return(quadriceps_cheapest(M, fam, d, p, dims))
    n = quadriceps_atom(M, fam, d, p)
    if (missing(n)) quadriceps_norule(M, fam, d, p)
    dims = d
    return(n)
}

// The one-dimensional Gauss rule with q nodes in the normalized frame (N(0,1) for GH, uniform on
// [0,1] for Le), by the Golub-Welsch eigenvalue method: the nodes are the eigenvalues of the
// Jacobi matrix of the orthonormal polynomials, the weights the squared first components of its
// eigenvectors.
void quadriceps_gauss1d(real scalar fam, real scalar q, real matrix X, real matrix w)
{
    real colvector k, off, x, o
    real matrix Jm, V
    real rowvector L
    real scalar i

    if (q == 1) {
        X = J(1, 1, (fam == 0 ? 0 : 0.5))
        w = J(1, 1, 1)
        return
    }
    k = 1::(q - 1)
    if (fam == 0) off = sqrt(k)
    else off = k :/ sqrt(4 * k:^2 :- 1)
    Jm = J(q, q, 0)
    for (i = 1; i < q; i++) {
        Jm[i, i + 1] = off[i]
        Jm[i + 1, i] = off[i]
    }
    V = .
    L = .
    symeigensystem(Jm, V, L)
    o = order(L', 1)
    x = L'
    x = x[o]
    w = (V[1, o] :^ 2)'
    x = (x - x[q::1]) / 2                   // the rule is symmetric; remove rounding asymmetry
    w = (w + w[q::1]) / 2
    w = w / sum(w)
    if (fam == 1) x = (x :+ 1) / 2
    X = x
}

// The rule of one factor: Gauss in one dimension, the stored rule otherwise.
void quadriceps_atomrule(real matrix M, real scalar fam, real scalar k, real scalar p, real matrix X, real matrix w)
{
    real scalar i

    if (k == 1) {
        quadriceps_gauss1d(fam, floor(p / 2) + 1, X, w)
        return
    }
    i = quadriceps_best(M, fam, k, p)
    if (i == 0) {
        errprintf("quadriceps: internal error, no stored rule for a planned factor\n")
        exit(498)
    }
    quadriceps_stored(M, i, X, w)
}

// ------------------------------------------------------------------------------------------
// The Mata API.
//   quadriceps_rule(family, d, p, pragmatic, normalize, X, w)   fills X (n x d) and w (n x 1)
//   ghpos(d, q, X, w [, normalize, pragmatic]),  lepos(...)      the same, with q instead of p
//   quadriceps_nnodes(family, d, p, pragmatic)                   the node count, without building
//   quadriceps_ruleinfo(family, d, p, pragmatic, origins)        the factors: rows (d, p, n, source_id)
//   quadriceps_exactness(X, w, p, family)                        largest relative monomial error
// ------------------------------------------------------------------------------------------

void quadriceps_rule(string scalar family, real scalar d, real scalar p, real scalar pragmatic, real scalar normalize,
                     real matrix X, real matrix w)
{
    real matrix M, Xk
    string colvector origin
    real rowvector dims
    real colvector wk, idx, j
    real scalar fam, n, i, nk, rep, col

    fam = quadriceps_family(family)
    quadriceps_checkargs(d, p, pragmatic)
    quadriceps_catalog(M, origin)
    n = quadriceps_plan(M, fam, d, p, pragmatic, dims)
    if (n * (d + 1) > 2147483647) {
        errprintf("the cheapest rule for this request has %s nodes, which is more than this command will build\n",
                  strofreal(n, "%21.0g"))
        exit(498)
    }
    if (cols(dims) == 1) {
        quadriceps_atomrule(M, fam, d, p, X, w)
    }
    else {                                  // tensor product; the first factor varies slowest
        X = J(n, d, .)
        w = J(n, 1, 1)
        idx = 0::(n - 1)
        rep = n
        col = 0
        for (i = 1; i <= cols(dims); i++) {
            quadriceps_atomrule(M, fam, dims[i], p, Xk, wk)
            nk = rows(wk)
            rep = rep / nk
            j = mod(floor(idx :/ rep), nk) :+ 1
            w = w :* wk[j]
            X[., (col + 1)..(col + dims[i])] = Xk[j, .]
            col = col + dims[i]
        }
    }
    if (!normalize) {
        if (fam == 0) {                     // int f(x) exp(-|x|^2) dx = pi^(d/2) E f(Z/sqrt(2))
            X = X / sqrt(2)
            w = w * pi()^(d / 2)
        }
        else {                              // [0,1]^d -> [-1,1]^d
            X = 2 * X :- 1
            w = w * 2^d
        }
    }
}

void ghpos(real scalar d, real scalar q, real matrix X, real matrix w, | real scalar normalize, real scalar pragmatic)
{
    if (args() < 5) normalize = 1
    if (args() < 6) pragmatic = 0
    if (missing(q) | q != floor(q) | q < 1) {
        errprintf("q must be a whole number at least 1\n")
        exit(198)
    }
    quadriceps_rule("gh", d, 2 * q - 1, pragmatic, normalize, X, w)
}

void lepos(real scalar d, real scalar q, real matrix X, real matrix w, | real scalar normalize, real scalar pragmatic)
{
    if (args() < 5) normalize = 1
    if (args() < 6) pragmatic = 0
    if (missing(q) | q != floor(q) | q < 1) {
        errprintf("q must be a whole number at least 1\n")
        exit(198)
    }
    quadriceps_rule("le", d, 2 * q - 1, pragmatic, normalize, X, w)
}

real scalar quadriceps_nnodes(string scalar family, real scalar d, real scalar p, real scalar pragmatic)
{
    real matrix M
    string colvector origin
    real rowvector dims
    real scalar fam

    fam = quadriceps_family(family)
    quadriceps_checkargs(d, p, pragmatic)
    quadriceps_catalog(M, origin)
    return(quadriceps_plan(M, fam, d, p, pragmatic, dims))
}

// One row per factor, in the order of the columns of X: d, p, n, source_id (-1 for a Gauss
// rule); origins gets the origin text of each factor ("Gauss" for a Gauss rule).
real matrix quadriceps_ruleinfo(string scalar family, real scalar d, real scalar p, real scalar pragmatic, string matrix origins)
{
    real matrix M, F
    string colvector origin
    real rowvector dims
    real scalar fam, i, k, nq, r

    fam = quadriceps_family(family)
    quadriceps_checkargs(d, p, pragmatic)
    quadriceps_catalog(M, origin)
    (void) quadriceps_plan(M, fam, d, p, pragmatic, dims)
    F = J(cols(dims), 4, .)
    origins = J(cols(dims), 1, "")
    for (i = 1; i <= cols(dims); i++) {
        k = dims[i]
        if (k == 1) {
            nq = floor(p / 2) + 1
            F[i, .] = (1, 2 * nq - 1, nq, -1)
            origins[i] = "Gauss"
        }
        else {
            r = quadriceps_best(M, fam, k, p)
            F[i, .] = (k, M[r, 3], M[r, 5], M[r, 8])
            origins[i] = origin[r]
        }
    }
    return(F)
}

// One-dimensional moments of the normalized weights: E Z^e for N(0,1), E U^e for U[0,1], e = 0..p.
real colvector quadriceps_moments1d(real scalar fam, real scalar p)
{
    real colvector m
    real scalar e

    if (fam == 1) return(1 :/ (1::(p + 1)))
    m = J(p + 1, 1, 0)
    m[1] = 1
    for (e = 2; e <= p; e = e + 2) m[e + 1] = m[e - 1] * (e - 1)     // (e-1)!!
    return(m)
}

real matrix quadriceps_den(real matrix SA)
{
    return(SA :* (SA :> 1) :+ (SA :<= 1))   // max(SA, 1) elementwise
}

// The largest relative monomial error over all monomials of total degree <= p:
// max |sum_i w_i x_i^a - E x^a| / max(sum_i |w_i| |x_i^a|, 1), for the normalized weight of the
// family (N(0, I_d) for gh, uniform on [0,1]^d for le).  A rule built with normalize = 0 must be
// checked in the normalized frame.
real scalar quadriceps_exactness(real matrix X, real colvector w, real scalar p, string scalar family)
{
    real scalar fam, n, d, k, a, c0
    real colvector m, s, sa
    real matrix P, A

    fam = quadriceps_family(family)
    n = rows(X)
    d = cols(X)
    if (rows(w) != n) {
        errprintf("X has %g rows, w has %g\n", n, rows(w))
        exit(503)
    }
    if (missing(p) | p != floor(p) | p < 0) {
        errprintf("the degree p must be a whole number at least 0\n")
        exit(198)
    }
    m = quadriceps_moments1d(fam, p)
    P = J(n, d * (p + 1), .)                // P[i, (k-1)(p+1) + e + 1] = x_ik^e
    for (k = 1; k <= d; k++) {              // (a column and a row vector are not c-conformable, hence the loop)
        c0 = (k - 1) * (p + 1) + 1
        P[., c0] = J(n, 1, 1)
        for (a = 1; a <= p; a++) P[., c0 + a] = X[., k] :^ a
    }
    A = abs(P)
    if (d == 1) {
        s = P' * w
        sa = A' * abs(w)
        return(max(abs(s - m) :/ quadriceps_den(sa)))
    }
    return(quadriceps_descend(P, A, m, d, p, 1, w, 1, p))
}

// prev: w * x_1^a_1 ... x_(k-1)^a_(k-1); mom: its exact moment; r: degree left for x_k, ..., x_d.
// The last two coordinates are done in one matrix product over all their exponent pairs.
real scalar quadriceps_descend(real matrix P, real matrix A, real colvector m, real scalar d, real scalar p,
                               real scalar k, real colvector prev, real scalar mom, real scalar r)
{
    real rowvector ck, cd
    real matrix B, S, SA, E, L
    real colvector mi
    real scalar a, best, v

    ck = ((k - 1) * (p + 1) + 1)..((k - 1) * (p + 1) + r + 1)
    if (k == d - 1) {
        cd = ((d - 1) * (p + 1) + 1)..((d - 1) * (p + 1) + r + 1)
        mi = m[1::(r + 1)]
        B = prev :* P[., ck]
        S = B' * P[., cd]
        SA = abs(B)' * A[., cd]
        E = abs(S - mom * (mi * mi')) :/ quadriceps_den(SA)
        L = (0::r) * J(1, r + 1, 1) + J(r + 1, 1, 1) * (0..r)     // exponent sums of the last two coordinates
        return(max(E :* (L :<= r)))
    }
    best = 0
    for (a = 0; a <= r; a++) {
        v = quadriceps_descend(P, A, m, d, p, k + 1, prev :* P[., ck[a + 1]], mom * m[a + 1], r - a)
        if (v > best) best = v
    }
    return(best)
}

// ------------------------------------------------------------------------------------------
// Behind the Stata commands.
// ------------------------------------------------------------------------------------------

// braces are SMCL directives in printf(); show them literally
string scalar quadriceps_smcl(string scalar s)
{
    string scalar t

    t = subinstr(s, "{", char(1), .)
    t = subinstr(t, "}", "{c )-}", .)
    return(subinstr(t, char(1), "{c -(}", .))
}

string rowvector quadriceps_varnames(real scalar d)
{
    string rowvector names
    real scalar k

    names = J(1, d + 1, "")
    for (k = 1; k <= d; k++) names[k] = "x" + strofreal(k)
    names[d + 1] = "w"
    return(names)
}

// into the current (empty) frame: variables x1..xd, w
void quadriceps_todata(real matrix X, real colvector w)
{
    string rowvector names

    names = quadriceps_varnames(cols(X))
    (void) st_addvar("double", names)
    st_addobs(rows(X))
    st_store(., names, (X, w))
}

void quadriceps_tomatrix(string scalar name, real matrix X, real colvector w)
{
    string rowvector names
    real scalar maxsize

    maxsize = strtoreal(st_global("c(max_matsize)"))
    if (rows(X) > maxsize) {
        errprintf("the rule has %g nodes, more than the %g rows a Stata matrix can hold here; use the frame instead\n",
                  rows(X), maxsize)
        exit(908)
    }
    names = quadriceps_varnames(cols(X))
    st_matrix(name, (X, w))
    st_matrixcolstripe(name, (J(cols(X) + 1, 1, ""), names'))
}

void quadriceps_ruleinfo_st(string scalar family, real scalar d, real scalar p, real scalar pragmatic, string scalar matname)
{
    real matrix F
    string colvector origins
    real scalar i, n

    F = quadriceps_ruleinfo(family, d, p, pragmatic, origins)
    n = 1
    for (i = 1; i <= rows(F); i++) n = n * F[i, 3]
    printf("{txt}%s rule for d = %g, degree %g: %s nodes, %g factor%s\n", (family == "gh" ? "GH" : "Le"), d, p,
           strofreal(n, "%21.0g"), rows(F), (rows(F) == 1 ? "" : "s"))
    printf("{txt}  factor    d      p           n  origin\n")
    for (i = 1; i <= rows(F); i++) {
        printf("{txt}  %6.0f %4.0f %6.0f %11.0g  {res}%s\n", i, F[i, 1], F[i, 2], F[i, 3], quadriceps_smcl(origins[i]))
    }
    st_matrix(matname, F)
    st_matrixcolstripe(matname, (J(4, 1, ""), ("d" \ "p" \ "n" \ "source_id")))
    st_local("n", strofreal(n, "%21.0g"))
    st_local("nfactors", strofreal(rows(F)))
    for (i = 1; i <= rows(F); i++) st_local("origin" + strofreal(i), origins[i])
}

void quadriceps_rules_st(string scalar family)
{
    real matrix M
    string colvector origin
    real colvector idx
    real scalar fam, i, r

    fam = quadriceps_family(family)
    quadriceps_catalog(M, origin)
    idx = selectindex(M[., 1] :== fam)
    printf("{txt}%s rules (family %s): %g stored\n", (fam ? "Le" : "GH"), family, length(idx))
    printf("{txt}   d    q    p       n  moller       relerr    minweight  interior  origin\n")
    for (i = 1; i <= length(idx); i++) {
        r = idx[i]
        printf("{txt}%4.0f %4.0f %4.0f %7.0f %7.0f %12.2e %12.3e  %-8s  {res}%s\n", M[r, 2], M[r, 4], M[r, 3], M[r, 5],
               M[r, 9], M[r, 10], M[r, 11], (M[r, 12] ? "yes" : "no"), quadriceps_smcl(origin[r]))
    }
}

void quadriceps_check_st(string scalar family, real scalar d, real scalar p, real scalar pragmatic,
                         string scalar errname, string scalar nname)
{
    real matrix X
    real colvector w

    quadriceps_rule(family, d, p, pragmatic, 1, X, w)
    st_numscalar(errname, quadriceps_exactness(X, w, p, family))
    st_numscalar(nname, rows(w))
}

void quadriceps_version_st(string scalar cellsname)
{
    real matrix M
    string colvector origin

    quadriceps_catalog(M, origin)
    st_numscalar(cellsname, rows(M))
}


// the loader in quadriceps.ado compares this with its own version and recompiles when they differ
string scalar quadriceps_mata_version()
{
    return("0.1.2")
}

end
