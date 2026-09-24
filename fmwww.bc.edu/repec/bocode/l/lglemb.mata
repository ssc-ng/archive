version 17.0

capture mata: mata drop glemb_*()
capture mata: mata drop glemb_prelim_s
capture mata: mata drop glemb_suffstats
capture mata: mata drop glemb_params

mata:

struct glemb_prelim_s {
    real scalar n
    real scalar nwt
    real scalar det_n
    real scalar det_wt
    real scalar p
    real scalar q
    real scalar ncells
    real scalar npsi
    real scalar npattz
    real scalar npattw
    real scalar ngrp
    real matrix w
    real matrix z
    real colvector wt
    real matrix rw
    real matrix rz
    real matrix r
    real matrix psi
    real rowvector psij
    real rowvector psik
    real matrix allcodes
    real matrix compatible
    real rowvector d
    real rowvector jmp
    real rowvector xbar
    real rowvector sdv
    real rowvector nmis
    real rowvector mdpzst
    real rowvector mdpzfin
    real rowvector mdpzgrp
    real rowvector mdpwgrp
    real rowvector mobs
    real rowvector mobsst
    real rowvector nmobs
    real colvector knowncell
    real colvector cellst
    real colvector celln
    real rowvector cellidx
    real colvector estep_skip
    real rowvector det_t1
    real matrix det_t2
    real rowvector det_t3
    real colvector ro
}

struct glemb_suffstats {
    real rowvector t1
    real matrix t2
    real rowvector t3
}

struct glemb_params {
    real rowvector sigma
    real matrix mu
    real matrix beta
    real rowvector pi
    real scalar iterations
    real scalar converged
}

void glemb__not_implemented()
{
    errprintf("glemb Stata port scaffold is present, but the Mata ECM/imputation engine is not implemented yet.\n")
    exit(499)
}

real rowvector glemb_make_margins(real scalar p, real scalar catinteract)
{
    real scalar order, i, j, k
    real rowvector out

    if (p == 1) return(1)

    order = min((catinteract, p))
    out = J(1, 0, .)

    if (order == 2) {
        for (i = 1; i <= p - 1; i++) {
            for (j = i + 1; j <= p; j++) {
                if (cols(out) > 0) out = out, 0
                out = out, i, j
            }
        }
    }
    else {
        for (i = 1; i <= p - 2; i++) {
            for (j = i + 1; j <= p - 1; j++) {
                for (k = j + 1; k <= p; k++) {
                    if (cols(out) > 0) out = out, 0
                    out = out, i, j, k
                }
            }
        }
    }

    return(out)
}

real matrix glemb_make_design(real rowvector nlevels)
{
    real scalar cell, j, lev, col, ncols
    real matrix codes, design

    ncols = 1 + sum(nlevels :- 1)
    codes = glemb_all_cell_codes(nlevels)
    design = J(rows(codes), ncols, 0)
    design[, 1] = J(rows(codes), 1, 1)

    col = 1
    for (j = 1; j <= cols(nlevels); j++) {
        for (lev = 2; lev <= nlevels[j]; lev++) {
            col++
            for (cell = 1; cell <= rows(codes); cell++) {
                design[cell, col] = (codes[cell, j] == lev)
            }
        }
    }

    return(design)
}

real matrix glemb_make_saturated_design(real rowvector nlevels)
{
    return(I(glemb_row_product(nlevels)))
}

real matrix glemb_make_mean_design(real rowvector nlevels, real scalar meanmodel)
{
    if (meanmodel == 1) return(glemb_make_design(nlevels))
    if (meanmodel == 2) return(glemb_make_saturated_design(nlevels))
    _error(198, "mean model must be main or saturated")
}

real scalar glemb_row_product(real rowvector x)
{
    real scalar j, out

    out = 1
    for (j = 1; j <= cols(x); j++) {
        out = out * x[j]
    }

    return(out)
}

real matrix glemb_mkpsi(real scalar q)
{
    real scalar pos, j, k
    real matrix psi

    psi = J(q, q, .)
    pos = 0
    for (j = 1; j <= q; j++) {
        pos++
        psi[j, j] = pos
        for (k = j + 1; k <= q; k++) {
            pos++
            psi[j, k] = pos
            psi[k, j] = pos
        }
    }

    return(psi)
}

real scalar glemb_cell_count(real rowvector nlevels)
{
    return(glemb_row_product(nlevels))
}

real rowvector glemb_cell_jumps(real rowvector nlevels)
{
    real scalar p, j, running
    real rowvector jumps

    p = cols(nlevels)
    jumps = J(1, p, .)
    running = 1
    for (j = 1; j <= p; j++) {
        jumps[j] = running
        running = running * nlevels[j]
    }

    return(jumps)
}

real scalar glemb_cell_index(real rowvector codes, real rowvector jumps)
{
    return(1 + sum((codes :- 1) :* jumps))
}

real rowvector glemb_cell_codes(real scalar cell, real rowvector nlevels, real rowvector jumps)
{
    real scalar j, rem
    real rowvector codes

    codes = J(1, cols(nlevels), .)
    rem = cell - 1
    for (j = cols(nlevels); j >= 1; j--) {
        codes[j] = floor(rem / jumps[j]) + 1
        rem = rem - (codes[j] - 1) * jumps[j]
    }

    return(codes)
}

real matrix glemb_all_cell_codes(real rowvector nlevels)
{
    real scalar cell, ncells
    real rowvector jumps
    real matrix codes

    ncells = glemb_cell_count(nlevels)
    jumps = glemb_cell_jumps(nlevels)
    codes = J(ncells, cols(nlevels), .)
    for (cell = 1; cell <= ncells; cell++) {
        codes[cell,] = glemb_cell_codes(cell, nlevels, jumps)
    }

    return(codes)
}

real colvector glemb_cell_indices(real matrix w, real rowvector jumps)
{
    real scalar i
    real colvector out

    out = J(rows(w), 1, .)
    for (i = 1; i <= rows(w); i++) {
        out[i] = glemb_cell_index(w[i,], jumps)
    }

    return(out)
}

real matrix glemb_parse_margins(real rowvector margins, real scalar p)
{
    real scalar j, row, width
    real matrix out

    width = p
    out = J(0, width, .)
    row = 1
    out = out \ J(1, width, 0)
    for (j = 1; j <= cols(margins); j++) {
        if (margins[j] == 0) {
            row++
            out = out \ J(1, width, 0)
        }
        else {
            out[row, sum(out[row,] :> 0) + 1] = margins[j]
        }
    }

    return(out)
}

real matrix glemb_center_scale(real matrix z, real rowvector xbar, real rowvector sdv)
{
    real scalar j
    real colvector observed
    real matrix out

    out = z
    for (j = 1; j <= cols(z); j++) {
        observed = select(z[, j], z[, j] :< .)

        if (rows(observed) > 0) {
            xbar[j] = mean(observed)
            sdv[j] = sqrt(mean((observed :- xbar[j]) :^ 2))
            out[, j] = z[, j] :- xbar[j]
            if (sdv[j] > 0) {
                out[, j] = out[, j] :/ sdv[j]
            }
            else {
                sdv[j] = 1
            }
        }
        else {
            xbar[j] = .
            sdv[j] = 1
        }
    }

    return(out)
}

real matrix glemb_center_scale_weighted(
    real matrix z,
    real colvector wt,
    real rowvector xbar,
    real rowvector sdv)
{
    real scalar j, denom
    real colvector ok
    real matrix out

    out = z
    for (j = 1; j <= cols(z); j++) {
        ok = (z[, j] :< .)
        denom = sum(select(wt, ok))

        if (denom > 0) {
            xbar[j] = sum(select(wt :* z[, j], ok)) / denom
            sdv[j] = sqrt(sum(select(wt :* ((z[, j] :- xbar[j]) :^ 2), ok)) / denom)
            out[, j] = z[, j] :- xbar[j]
            if (sdv[j] > 0) {
                out[, j] = out[, j] :/ sdv[j]
            }
            else {
                sdv[j] = 1
            }
        }
        else {
            xbar[j] = .
            sdv[j] = 1
        }
    }

    return(out)
}

real rowvector glemb_pattern_codes(real matrix miss)
{
    real scalar j
    real rowvector weights

    weights = J(1, cols(miss), .)
    for (j = 1; j <= cols(miss); j++) {
        weights[j] = 2 ^ (j - 1)
    }

    return((miss * weights')' :+ 1)
}

real colvector glemb_group_starts(real colvector x)
{
    real scalar i
    real colvector starts

    if (rows(x) == 0) return(J(0, 1, .))

    starts = 1
    for (i = 2; i <= rows(x); i++) {
        if (x[i] != x[i - 1]) starts = starts \ i
    }

    return(starts)
}

real rowvector glemb_group_values(real colvector x, real colvector starts)
{
    real scalar i
    real rowvector out

    out = J(1, rows(starts), .)
    for (i = 1; i <= rows(starts); i++) {
        out[i] = x[starts[i]]
    }

    return(out)
}

struct glemb_prelim_s scalar glemb_prelim(real matrix w, real matrix z)
{
    return(glemb_prelim_weighted(w, z, J(rows(w), 1, 1)))
}

struct glemb_prelim_s scalar glemb_prelim_weighted(real matrix w, real matrix z, real colvector wt)
{
    real scalar i, j, a, b, st, fin, ncompat
    real matrix rwmiss, rzmiss, keys
    real colvector ord, invord, mdpz, mdpw, mobs_all, mdpzst, mdpwst, mobsst
    real rowvector mdpzgrp, mdpwgrp, nlevels
    struct glemb_prelim_s scalar s

    s.n = rows(w)
    s.nwt = sum(wt)
    s.p = cols(w)
    s.q = cols(z)
    s.w = w
    s.z = z
    s.wt = wt

    nlevels = J(1, s.p, .)
    for (j = 1; j <= s.p; j++) {
        nlevels[j] = max(select(w[, j], w[, j] :< .))
    }
    s.d = nlevels
    s.jmp = glemb_cell_jumps(s.d)
    s.ncells = glemb_cell_count(s.d)
    s.allcodes = glemb_all_cell_codes(s.d)

    rwmiss = (w :>= .)
    rzmiss = (z :>= .)
    s.nmis = (wt' * rwmiss), (wt' * rzmiss)

    mdpw = glemb_pattern_codes(rwmiss)'
    mdpz = glemb_pattern_codes(rzmiss)'
    s.rw = 1 :- rwmiss
    s.rz = 1 :- rzmiss

    mobs_all = J(s.n, 1, .)
    for (i = 1; i <= s.n; i++) {
        mobs_all[i] = 1 + sum(((editmissing(w[i,], 1) :- 1) :* s.rw[i,] :* s.jmp))
    }

    keys = mdpz, mdpw, mobs_all, (1::s.n)
    keys = sort(keys, (1, 2, 3, 4))
    ord = keys[, 4]
    invord = J(s.n, 1, .)
    for (i = 1; i <= s.n; i++) invord[ord[i]] = i
    s.ro = invord

    s.w = w[ord,]
    s.z = z[ord,]
    s.wt = wt[ord]
    mdpz = mdpz[ord]
    mdpw = mdpw[ord]
    mobs_all = mobs_all[ord]
    s.rw = s.rw[ord,]
    s.rz = s.rz[ord,]

    mdpzst = glemb_group_starts(mdpz)
    s.npattz = rows(mdpzst)
    s.mdpzst = mdpzst'
    s.mdpzfin = J(1, s.npattz, .)
    for (i = 1; i <= s.npattz; i++) {
        s.mdpzfin[i] = (i < s.npattz ? mdpzst[i + 1] - 1 : s.n)
    }
    mdpzgrp = J(1, s.npattz, .)
    mdpwst = J(0, 1, .)
    for (i = 1; i <= s.npattz; i++) {
        st = mdpzst[i]
        fin = (i < s.npattz ? mdpzst[i + 1] - 1 : s.n)
        a = rows(mdpwst)
        mdpwst = mdpwst \ (glemb_group_starts(mdpw[|st \ fin|]) :+ st :- 1)
        mdpzgrp[i] = rows(mdpwst) - a
    }
    s.mdpzgrp = mdpzgrp
    s.npattw = rows(mdpwst)

    mdpwgrp = J(1, s.npattw, .)
    mobsst = J(0, 1, .)
    for (i = 1; i <= s.npattw; i++) {
        st = mdpwst[i]
        fin = (i < s.npattw ? mdpwst[i + 1] - 1 : s.n)
        b = rows(mobsst)
        mobsst = mobsst \ (glemb_group_starts(mobs_all[|st \ fin|]) :+ st :- 1)
        mdpwgrp[i] = rows(mobsst) - b
    }
    s.mdpwgrp = mdpwgrp
    s.ngrp = rows(mobsst)
    s.mobsst = mobsst'
    s.mobs = glemb_group_values(mobs_all, mobsst)

    s.nmobs = J(1, s.ngrp, .)
    for (i = 1; i <= s.ngrp; i++) {
        s.nmobs[i] = (i < s.ngrp ? mobsst[i + 1] : s.n + 1) - mobsst[i]
    }

    s.r = (s.rw, s.rz)[mdpwst,]
    s.rz = s.rz[mdpzst,]
    s.rw = s.rw[mdpwst,]

    s.npsi = s.q * (s.q + 1) / 2
    s.psi = glemb_mkpsi(s.q)
    s.psij = J(1, s.npsi, .)
    s.psik = J(1, s.npsi, .)
    for (j = 1; j <= s.q; j++) {
        for (k = j; k <= s.q; k++) {
            s.psij[s.psi[j, k]] = j
            s.psik[s.psi[j, k]] = k
        }
    }
    s.xbar = J(1, s.q, .)
    s.sdv = J(1, s.q, .)
    s.z = glemb_center_scale_weighted(s.z, s.wt, s.xbar, s.sdv)
    s.knowncell = J(s.n, 1, .)
    for (i = 1; i <= s.n; i++) {
        if (all(s.w[i,] :< .)) {
            s.knowncell[i] = glemb_cell_index(s.w[i,], s.jmp)
        }
    }
    s.compatible = J(s.n, s.ncells, 0)
    s.cellst = J(s.n, 1, .)
    s.celln = J(s.n, 1, 0)
    s.cellidx = J(1, 0, .)
    for (i = 1; i <= s.n; i++) {
        s.compatible[i,] = glemb_compatible_mask(s.w[i,], s.allcodes)
        s.cellst[i] = cols(s.cellidx) + 1
        ncompat = sum(s.compatible[i,])
        s.celln[i] = ncompat
        if (ncompat > 0) {
            s.cellidx = s.cellidx, selectindex(s.compatible[i,])
        }
    }
    s.estep_skip = J(s.n, 1, 0)
    s.det_t1 = J(1, s.npsi, 0)
    s.det_t2 = J(s.q, s.ncells, 0)
    s.det_t3 = J(1, s.ncells, 0)
    s.det_n = 0
    s.det_wt = 0
    for (i = 1; i <= s.n; i++) {
        if (s.knowncell[i] < . & all(s.z[i,] :< .)) {
            s.estep_skip[i] = 1
            s.det_n = s.det_n + 1
            s.det_wt = s.det_wt + s.wt[i]
            s.det_t3[s.knowncell[i]] = s.det_t3[s.knowncell[i]] + s.wt[i]
            s.det_t2[, s.knowncell[i]] = s.det_t2[, s.knowncell[i]] + s.wt[i] * s.z[i,]'
            s.det_t1 = s.det_t1 + s.wt[i] * (s.z[i, s.psij] :* s.z[i, s.psik])
        }
    }

    return(s)
}

struct glemb_suffstats scalar glemb_tobsm(struct glemb_prelim_s scalar s)
{
    real scalar i, j, k, cell, wi
    real rowvector codes
    struct glemb_suffstats scalar out

    out.t1 = J(1, s.npsi, 0)
    out.t2 = J(s.q, s.ncells, 0)
    out.t3 = J(1, s.ncells, 0)

    for (i = 1; i <= s.n; i++) {
        wi = s.wt[i]
        if (all(s.w[i,] :< .)) {
            codes = s.w[i,]
            cell = glemb_cell_index(codes, s.jmp)
            out.t3[cell] = out.t3[cell] + wi
        }
        else {
            cell = .
        }

        for (j = 1; j <= s.q; j++) {
            if (s.z[i, j] < .) {
                if (cell < .) {
                    out.t2[j, cell] = out.t2[j, cell] + wi * s.z[i, j]
                }
                for (k = j; k <= s.q; k++) {
                    if (s.z[i, k] < .) {
                        out.t1[s.psi[j, k]] = out.t1[s.psi[j, k]] + wi * s.z[i, j] * s.z[i, k]
                    }
                }
            }
        }
    }

    return(out)
}

real matrix glemb_unpack_sigma(real rowvector sigma, real matrix psi)
{
    real scalar q, j, k
    real matrix out

    q = rows(psi)
    out = J(q, q, .)
    for (j = 1; j <= q; j++) {
        for (k = j; k <= q; k++) {
            out[j, k] = sigma[psi[j, k]]
            out[k, j] = out[j, k]
        }
    }

    return(out)
}

real rowvector glemb_pack_sigma(real matrix sigma, real matrix psi)
{
    real scalar q, j, k
    real rowvector out

    q = rows(psi)
    out = J(1, q * (q + 1) / 2, .)
    for (j = 1; j <= q; j++) {
        for (k = j; k <= q; k++) {
            out[psi[j, k]] = sigma[j, k]
        }
    }

    return(out)
}

real matrix glemb_cov_ridge(real matrix sigma)
{
    real scalar q, scale

    q = rows(sigma)
    if (q == 0) return(sigma)

    scale = trace(sigma) / q
    if (scale <= 0 | scale >= .) scale = 1

    return((sigma + sigma') / 2 + I(q) * (1e-10 * scale))
}

real scalar glemb_log_mvn(real rowvector y, real rowvector mu, real matrix sigma)
{
    real scalar d, sign, logdet
    real rowvector diff

    d = cols(y)
    if (d == 0) return(0)

    diff = y - mu
    sigma = glemb_cov_ridge(sigma)
    logdet = ln(det(sigma))
    if (logdet >= .) return(-.)

    return(-0.5 * (d * ln(2 * pi()) + logdet + diff * invsym(sigma) * diff'))
}

real scalar glemb_log_mvn_cached(
    real rowvector y,
    real rowvector mu,
    real matrix sigma_inv,
    real scalar logdet)
{
    real scalar d
    real rowvector diff

    d = cols(y)
    if (d == 0) return(0)

    diff = y - mu
    return(-0.5 * (d * ln(2 * pi()) + logdet + diff * sigma_inv * diff'))
}

real rowvector glemb_compatible_cells(
    real rowvector wrow,
    real matrix allcodes)
{
    real scalar cell, j, ok, nout
    real rowvector out

    out = J(1, rows(allcodes), .)
    nout = 0
    for (cell = 1; cell <= rows(allcodes); cell++) {
        ok = 1
        for (j = 1; j <= cols(allcodes); j++) {
            if (wrow[j] < . & wrow[j] != allcodes[cell, j]) {
                ok = 0
                break
            }
        }
        if (ok) {
            nout++
            out[nout] = cell
        }
    }

    return(out[|1 \ nout|])
}

real rowvector glemb_compatible_mask(
    real rowvector wrow,
    real matrix allcodes)
{
    real scalar cell, j, ok
    real rowvector out

    out = J(1, rows(allcodes), 0)
    for (cell = 1; cell <= rows(allcodes); cell++) {
        ok = 1
        for (j = 1; j <= cols(allcodes); j++) {
            if (wrow[j] < . & wrow[j] != allcodes[cell, j]) {
                ok = 0
                break
            }
        }
        out[cell] = ok
    }

    return(out)
}

struct glemb_params scalar glemb_start_params(struct glemb_prelim_s scalar s)
{
    struct glemb_params scalar theta

    theta.sigma = glemb_pack_sigma(I(s.q), s.psi)
    theta.mu = J(s.q, s.ncells, 0)
    theta.beta = J(s.ncells, s.q, 0)
    theta.pi = J(1, s.ncells, 1 / s.ncells)
    theta.iterations = 0
    theta.converged = 0

    return(theta)
}

struct glemb_suffstats scalar glemb_estep(
    struct glemb_prelim_s scalar s,
    struct glemb_params scalar theta)
{
    real scalar pattz, i, a, cell, j, k, q, weight_sum, st, fin, wi
    real rowvector cells, logw, weights, zrow, obs, mis, yhat, posidx
    real matrix sigma, sigma_obs_inv, condvar, diff
    real scalar logdet_obs
    real colvector obsidx, misidx
    struct glemb_suffstats scalar out

    q = s.q
    sigma = glemb_unpack_sigma(theta.sigma, s.psi)

    out.t1 = s.det_t1
    out.t2 = s.det_t2
    out.t3 = s.det_t3

    for (pattz = 1; pattz <= s.npattz; pattz++) {
        obsidx = selectindex(s.rz[pattz,] :== 1)
        misidx = selectindex(s.rz[pattz,] :== 0)
        if (length(obsidx) > 0) {
            sigma_obs_inv = invsym(sigma[obsidx, obsidx])
            logdet_obs = ln(det(sigma[obsidx, obsidx]))
        }

        st = s.mdpzst[pattz]
        fin = s.mdpzfin[pattz]
        for (i = st; i <= fin; i++) {
            if (s.estep_skip[i]) continue
            zrow = s.z[i,]
            wi = s.wt[i]
            if (length(misidx) == 0 & s.knowncell[i] < .) {
                cell = s.knowncell[i]
                out.t3[cell] = out.t3[cell] + wi
                out.t2[, cell] = out.t2[, cell] + wi * zrow'
                out.t1 = out.t1 + wi * (zrow[s.psij] :* zrow[s.psik])
                continue
            }

            obs = (length(obsidx) > 0 ? zrow[obsidx] : J(1, 0, .))
            cells = s.cellidx[|s.cellst[i] \ s.cellst[i] + s.celln[i] - 1|]

            if (length(misidx) == 0 & cols(cells) == 1) {
                cell = cells[1]
                out.t3[cell] = out.t3[cell] + wi
                out.t2[, cell] = out.t2[, cell] + wi * zrow'
                out.t1 = out.t1 + wi * (zrow[s.psij] :* zrow[s.psik])
                continue
            }

            if (cols(cells) == 1) {
                cell = cells[1]
                yhat = J(1, q, .)

                if (length(obsidx) > 0) {
                    yhat[obsidx] = zrow[obsidx]
                    yhat[misidx] = theta.mu[misidx, cell]' +
                        (sigma[misidx, obsidx] *
                        sigma_obs_inv *
                        (obs' - theta.mu[obsidx, cell]))'
                    condvar = sigma[misidx, misidx] -
                        sigma[misidx, obsidx] *
                        sigma_obs_inv *
                        sigma[obsidx, misidx]
                }
                else {
                    yhat[misidx] = theta.mu[misidx, cell]'
                    condvar = sigma[misidx, misidx]
                }

                out.t3[cell] = out.t3[cell] + wi
                out.t2[, cell] = out.t2[, cell] + wi * yhat'
                out.t1 = out.t1 + wi * (yhat[s.psij] :* yhat[s.psik])
                for (j = 1; j <= length(misidx); j++) {
                    for (k = j; k <= length(misidx); k++) {
                        out.t1[s.psi[misidx[j], misidx[k]]] =
                            out.t1[s.psi[misidx[j], misidx[k]]] + wi * condvar[j, k]
                    }
                }
                continue
            }

            logw = J(1, cols(cells), -.)
            posidx = selectindex(theta.pi[cells] :> 0)
            if (cols(posidx) > 0) {
                if (length(obsidx) == 0) {
                    logw[posidx] = ln(theta.pi[cells[posidx]])
                }
                else {
                    diff = theta.mu[obsidx, cells[posidx]]' :- obs
                    logw[posidx] = ln(theta.pi[cells[posidx]]) :-
                        0.5 :* (length(obsidx) * ln(2 * pi()) + logdet_obs :+
                        rowsum((diff * sigma_obs_inv) :* diff)')
                }
            }

            logw = logw :- max(logw)
            weights = exp(logw)
            weight_sum = sum(weights)
            if (weight_sum <= 0 | weight_sum >= .) {
                _error(498, "unable to compute E-step cell probabilities")
            }
            weights = weights / weight_sum

            if (length(misidx) == 0) {
                for (a = 1; a <= cols(cells); a++) {
                    cell = cells[a]
                    out.t3[cell] = out.t3[cell] + wi * weights[a]
                    out.t2[, cell] = out.t2[, cell] + wi * weights[a] * zrow'
                }
                out.t1 = out.t1 + wi * (zrow[s.psij] :* zrow[s.psik])
                continue
            }

            for (a = 1; a <= cols(cells); a++) {
                cell = cells[a]
                yhat = J(1, q, .)

                if (length(obsidx) > 0) {
                    yhat[obsidx] = zrow[obsidx]
                }
                if (length(misidx) > 0) {
                    if (length(obsidx) > 0) {
                        yhat[misidx] = theta.mu[misidx, cell]' +
                            (sigma[misidx, obsidx] *
                            sigma_obs_inv *
                            (obs' - theta.mu[obsidx, cell]))'
                        condvar = sigma[misidx, misidx] -
                            sigma[misidx, obsidx] *
                            sigma_obs_inv *
                            sigma[obsidx, misidx]
                    }
                    else {
                        yhat[misidx] = theta.mu[misidx, cell]'
                        condvar = sigma[misidx, misidx]
                    }
                }

                out.t3[cell] = out.t3[cell] + wi * weights[a]
                out.t2[, cell] = out.t2[, cell] + wi * weights[a] * yhat'
                out.t1 = out.t1 + wi * weights[a] * (yhat[s.psij] :* yhat[s.psik])
                for (j = 1; j <= length(misidx); j++) {
                    for (k = j; k <= length(misidx); k++) {
                        out.t1[s.psi[misidx[j], misidx[k]]] =
                            out.t1[s.psi[misidx[j], misidx[k]]] +
                            wi * weights[a] * condvar[j, k]
                    }
                }
            }
        }
    }

    return(out)
}

real scalar glemb_draw_discrete(real rowvector probs)
{
    real scalar u, s, j

    u = runiform(1, 1)
    s = 0
    for (j = 1; j <= cols(probs); j++) {
        s = s + probs[j]
        if (u <= s | j == cols(probs)) return(j)
    }

    return(cols(probs))
}

real matrix glemb_impute(struct glemb_prelim_s scalar s, struct glemb_params scalar theta)
{
    real scalar pattz, i, a, cell, draw, weight_sum, st, fin
    real rowvector cells, logw, weights, zrow, obs, yhat, noise
    real matrix sigma, sigma_obs_inv, wout, zout, condvar, chol
    real scalar logdet_obs
    real colvector obsidx, misidx

    sigma = glemb_unpack_sigma(theta.sigma, s.psi)
    wout = s.w
    zout = s.z

    for (pattz = 1; pattz <= s.npattz; pattz++) {
        obsidx = selectindex(s.rz[pattz,] :== 1)
        misidx = selectindex(s.rz[pattz,] :== 0)
        if (length(obsidx) > 0) {
            sigma_obs_inv = invsym(sigma[obsidx, obsidx])
            logdet_obs = ln(det(sigma[obsidx, obsidx]))
        }

        st = s.mdpzst[pattz]
        fin = s.mdpzfin[pattz]
        for (i = st; i <= fin; i++) {
            zrow = zout[i,]
            obs = (length(obsidx) > 0 ? zrow[obsidx] : J(1, 0, .))
            cells = s.cellidx[|s.cellst[i] \ s.cellst[i] + s.celln[i] - 1|]
            logw = J(1, cols(cells), .)

            for (a = 1; a <= cols(cells); a++) {
                cell = cells[a]
                if (theta.pi[cell] <= 0) {
                    logw[a] = -.
                }
                else if (length(obsidx) == 0) {
                    logw[a] = ln(theta.pi[cell])
                }
                else {
                    logw[a] = ln(theta.pi[cell]) +
                        glemb_log_mvn_cached(obs, theta.mu[obsidx, cell]', sigma_obs_inv, logdet_obs)
                }
            }

            logw = logw :- max(logw)
            weights = exp(logw)
            weight_sum = sum(weights)
            if (weight_sum <= 0 | weight_sum >= .) {
                _error(498, "unable to compute imputation cell probabilities")
            }
            weights = weights / weight_sum
            draw = glemb_draw_discrete(weights)
            cell = cells[draw]

            wout[i,] = s.allcodes[cell,]

            if (length(misidx) > 0) {
                if (length(obsidx) > 0) {
                    yhat = theta.mu[misidx, cell]' +
                        (sigma[misidx, obsidx] *
                        sigma_obs_inv *
                        (obs' - theta.mu[obsidx, cell]))'
                    condvar = sigma[misidx, misidx] -
                        sigma[misidx, obsidx] *
                        sigma_obs_inv *
                        sigma[obsidx, misidx]
                }
                else {
                    yhat = theta.mu[misidx, cell]'
                    condvar = sigma[misidx, misidx]
                }

                condvar = glemb_cov_ridge(condvar)
                if (length(misidx) == 1) {
                    noise = rnormal(1, 1, 0, sqrt(max((condvar[1,1], 0))))
                }
                else {
                    chol = cholesky(condvar)
                    noise = rnormal(1, length(misidx), 0, 1) * chol
                }
                zout[i, misidx] = yhat + noise
            }
        }
    }

    for (i = 1; i <= s.q; i++) {
        zout[, i] = zout[, i] :* s.sdv[i] :+ s.xbar[i]
    }

    return((wout, zout)[s.ro,])
}

struct glemb_params scalar glemb_mstepcm(
    struct glemb_prelim_s scalar s,
    struct glemb_suffstats scalar ss,
    real matrix design)
{
    real scalar q, ncells, n, j, k
    real matrix w, wdesign, xty, beta, mu, sigma_mat, sigma_full
    struct glemb_params scalar out

    q = s.q
    ncells = s.ncells
    n = s.nwt

    wdesign = design
    for (j = 1; j <= ncells; j++) {
        wdesign[j,] = wdesign[j,] :* ss.t3[j]
    }
    w = design' * wdesign
    xty = design' * ss.t2'
    beta = invsym(w) * xty
    mu = (design * beta)'

    sigma_mat = J(q, q, 0)
    for (j = 1; j <= q; j++) {
        for (k = j; k <= q; k++) {
            sigma_mat[j, k] = ss.t1[s.psi[j, k]]
            sigma_mat[k, j] = sigma_mat[j, k]
        }
    }

    sigma_full = glemb_cov_ridge((sigma_mat - beta' * w * beta) / n)
    out.sigma = J(1, s.npsi, .)
    for (j = 1; j <= q; j++) {
        for (k = j; k <= q; k++) {
            out.sigma[s.psi[j, k]] = sigma_full[j, k]
        }
    }

    out.mu = mu
    out.beta = beta
    out.pi = ss.t3 / sum(ss.t3)

    return(out)
}

real rowvector glemb_ipf(
    real rowvector table,
    real rowvector fit,
    real rowvector margins,
    real rowvector nlevels,
    real scalar eps)
{
    return(glemb_ipf_with_codes(table, fit, margins, nlevels, glemb_all_cell_codes(nlevels), eps))
}

real rowvector glemb_ipf_with_codes(
    real rowvector table,
    real rowvector fit,
    real rowvector margins,
    real rowvector nlevels,
    real matrix codes,
    real scalar eps)
{
    real scalar tab, g, h, j, pos, sum_table, sum_fit, ratio
    real rowvector vars, vlevels, vjumps, ukeys
    real matrix margin_specs
    real colvector keys, idx
    real rowvector out

    out = fit
    margin_specs = glemb_parse_margins(margins, cols(nlevels))

    for (tab = 1; tab <= rows(margin_specs); tab++) {
        vars = select(margin_specs[tab,], margin_specs[tab,] :> 0)
        if (cols(vars) == 0) continue

        vlevels = nlevels[vars]
        vjumps = glemb_cell_jumps(vlevels)
        keys = J(rows(codes), 1, 1)
        for (j = 1; j <= cols(vars); j++) {
            keys = keys + (codes[, vars[j]] :- 1) :* vjumps[j]
        }
        ukeys = uniqrows(sort(keys, 1))'

        for (g = 1; g <= cols(ukeys); g++) {
            idx = selectindex(keys :== ukeys[g])
            sum_table = sum(table[idx'])
            sum_fit = sum(out[idx'])
            if (sum_fit != 0) {
                ratio = sum_table / sum_fit
                for (h = 1; h <= rows(idx); h++) {
                    pos = idx[h]
                    out[pos] = (out[pos] >= eps ? out[pos] * ratio : 0)
                }
            }
        }
    }

    return(out)
}

real scalar glemb_maxreldif(real matrix a, real matrix b)
{
    real matrix denom

    denom = abs(b)
    denom = denom :+ (denom :< 1e-12) :* 1e-12
    return(max(abs(a - b) :/ denom))
}

struct glemb_params scalar glemb_ecm(
    struct glemb_prelim_s scalar s,
    real rowvector margins,
    real matrix design,
    real rowvector prior,
    real scalar maxits,
    real scalar eps)
{
    real scalar it, eps1, converged
    real rowvector counts
    struct glemb_params scalar theta, next
    struct glemb_suffstats scalar ss

    if (cols(prior) == 1) prior = J(1, s.ncells, prior[1])
    theta = glemb_start_params(s)
    eps1 = .0000001 * s.nwt / s.ncells
    converged = 0

    for (it = 1; it <= maxits; it++) {
        ss = glemb_estep(s, theta)
        next = glemb_mstepcm(s, ss, design)

        counts = ss.t3 + prior :- 1
        if (min(counts) < 0) {
            _error(498, "estimate outside parameter space; check prior")
        }
        next.pi = glemb_ipf_with_codes(counts, theta.pi, margins, s.d, s.allcodes, eps1)
        next.pi = next.pi / sum(next.pi)

        converged =
            glemb_maxreldif(next.sigma, theta.sigma) <= eps &
            glemb_maxreldif(next.mu, theta.mu) <= eps &
            glemb_maxreldif(next.pi, theta.pi) <= eps

        theta = next
        if (converged) break
    }

    theta.iterations = it
    theta.converged = converged

    return(theta)
}

struct glemb_params scalar glemb_ecm_profile(
    struct glemb_prelim_s scalar s,
    real rowvector margins,
    real matrix design,
    real rowvector prior,
    real scalar maxits,
    real scalar eps)
{
    real scalar it, eps1, converged
    real rowvector counts
    struct glemb_params scalar theta, next
    struct glemb_suffstats scalar ss

    if (cols(prior) == 1) prior = J(1, s.ncells, prior[1])
    theta = glemb_start_params(s)
    eps1 = .0000001 * s.nwt / s.ncells
    converged = 0

    for (it = 1; it <= maxits; it++) {
        timer_on(81)
        ss = glemb_estep(s, theta)
        timer_off(81)

        timer_on(82)
        next = glemb_mstepcm(s, ss, design)
        timer_off(82)

        timer_on(83)
        counts = ss.t3 + prior :- 1
        if (min(counts) < 0) {
            _error(498, "estimate outside parameter space; check prior")
        }
        next.pi = glemb_ipf_with_codes(counts, theta.pi, margins, s.d, s.allcodes, eps1)
        next.pi = next.pi / sum(next.pi)
        timer_off(83)

        converged =
            glemb_maxreldif(next.sigma, theta.sigma) <= eps &
            glemb_maxreldif(next.mu, theta.mu) <= eps &
            glemb_maxreldif(next.pi, theta.pi) <= eps

        theta = next
        if (converged) break
    }

    theta.iterations = it
    theta.converged = converged

    return(theta)
}

struct glemb_params scalar glemb_fit(
    real matrix w,
    real matrix z,
    real scalar catinteract,
    real scalar meanmodel,
    real scalar prior,
    real scalar maxits,
    real scalar eps)
{
    struct glemb_prelim_s scalar s

    s = glemb_prelim(w, z)
    return(glemb_ecm(
        s,
        glemb_make_margins(s.p, catinteract),
        glemb_make_mean_design(s.d, meanmodel),
        prior,
        maxits,
        eps))
}

real matrix glemb_fit_impute(
    real matrix w,
    real matrix z,
    real scalar catinteract,
    real scalar meanmodel,
    real scalar prior,
    real scalar maxits,
    real scalar eps)
{
    struct glemb_prelim_s scalar s
    struct glemb_params scalar theta

    s = glemb_prelim(w, z)
    theta = glemb_ecm(
        s,
        glemb_make_margins(s.p, catinteract),
        glemb_make_mean_design(s.d, meanmodel),
        prior,
        maxits,
        eps)

    return(glemb_impute(s, theta))
}

real matrix glemb_pseudo_obs(real matrix w, real matrix z, real scalar catprior)
{
    real scalar i, n_pseudo
    real rowvector nlevels, means
    real matrix codes, zout

    if (catprior <= 0) return(J(0, cols(w) + cols(z), .))

    nlevels = J(1, cols(w), .)
    for (i = 1; i <= cols(w); i++) {
        nlevels[i] = max(select(w[, i], w[, i] :< .))
    }

    codes = glemb_all_cell_codes(nlevels)
    means = J(1, cols(z), .)
    for (i = 1; i <= cols(z); i++) {
        means[i] = mean(select(z[, i], z[, i] :< .))
    }

    n_pseudo = max((1, round(catprior)))
    codes = codes[ceil((1::(rows(codes) * n_pseudo)) / n_pseudo),]
    zout = J(rows(codes), cols(z), .)
    for (i = 1; i <= rows(codes); i++) {
        zout[i,] = means
    }

    return(codes, zout)
}

real colvector glemb_bootstrap_counts(real scalar n)
{
    real scalar i
    real colvector idx, counts

    idx = ceil(runiform(n, 1) :* n)
    counts = J(n, 1, 0)
    for (i = 1; i <= n; i++) {
        counts[idx[i]] = counts[idx[i]] + 1
    }

    return(counts)
}

real matrix glemb_emb_once(
    real matrix w,
    real matrix z,
    real scalar catinteract,
    real scalar meanmodel,
    real scalar catprior,
    real scalar maxits,
    real scalar eps)
{
    real scalar n
    real colvector idx, bootwt
    real matrix bootw, bootz, pseudo
    struct glemb_prelim_s scalar boot_s, orig_s
    struct glemb_params scalar theta

    n = rows(w)
    bootwt = glemb_bootstrap_counts(n)
    idx = selectindex(bootwt :> 0)
    bootw = w[idx,]
    bootz = z[idx,]
    bootwt = bootwt[idx]

    pseudo = glemb_pseudo_obs(w, z, catprior)
    if (rows(pseudo) > 0) {
        bootw = bootw \ pseudo[, 1::cols(w)]
        bootz = bootz \ pseudo[, (cols(w) + 1)::cols(pseudo)]
        bootwt = bootwt \ J(rows(pseudo), 1, 1)
    }

    boot_s = glemb_prelim_weighted(bootw, bootz, bootwt)
    theta = glemb_ecm(
        boot_s,
        glemb_make_margins(boot_s.p, catinteract),
        glemb_make_mean_design(boot_s.d, meanmodel),
        1,
        maxits,
        eps)

    orig_s = glemb_prelim(w, z)
    return(glemb_impute(orig_s, theta))
}

void glemb_stata_emb_once(
    string scalar wvars,
    string scalar zvars,
    string scalar touse,
    string scalar outvars,
    string scalar iterscalar,
    string scalar convscalar,
    real scalar catinteract,
    real scalar meanmodel,
    real scalar catprior,
    real scalar maxits,
    real scalar eps)
{
    real scalar p, q
    real matrix w, z, ximp
    struct glemb_prelim_s scalar boot_s, orig_s
    struct glemb_params scalar theta
    real scalar n
    real colvector idx, bootwt
    real matrix bootw, bootz, pseudo
    string rowvector wv, zv, ov

    wv = tokens(wvars)
    zv = tokens(zvars)
    ov = tokens(outvars)
    p = cols(wv)
    q = cols(zv)

    if (cols(ov) != p + q) {
        _error(198, "internal error: output variable count does not match model variable count")
    }

    w = st_data(., wv, touse)
    z = st_data(., zv, touse)

    n = rows(w)
    bootwt = glemb_bootstrap_counts(n)
    idx = selectindex(bootwt :> 0)
    bootw = w[idx,]
    bootz = z[idx,]
    bootwt = bootwt[idx]

    pseudo = glemb_pseudo_obs(w, z, catprior)
    if (rows(pseudo) > 0) {
        bootw = bootw \ pseudo[, 1::cols(w)]
        bootz = bootz \ pseudo[, (cols(w) + 1)::cols(pseudo)]
        bootwt = bootwt \ J(rows(pseudo), 1, 1)
    }

    boot_s = glemb_prelim_weighted(bootw, bootz, bootwt)
    theta = glemb_ecm(
        boot_s,
        glemb_make_margins(boot_s.p, catinteract),
        glemb_make_mean_design(boot_s.d, meanmodel),
        1,
        maxits,
        eps)

    orig_s = glemb_prelim(w, z)
    ximp = glemb_impute(orig_s, theta)
    st_store(., ov, touse, ximp)
    st_numscalar(iterscalar, theta.iterations)
    st_numscalar(convscalar, theta.converged)
}

void glemb_stata_emb_once_profile(
    string scalar wvars,
    string scalar zvars,
    string scalar touse,
    string scalar outvars,
    string scalar iterscalar,
    string scalar convscalar,
    string scalar readscalar,
    string scalar bootscalar,
    string scalar pseudoscalar,
    string scalar bootprelimscalar,
    string scalar ecmscalar,
    string scalar origprelimscalar,
    string scalar imputescalar,
    string scalar storescalar,
    string scalar estepscalar,
    string scalar mstepscalar,
    string scalar ipfscalar,
    string scalar detrowscalar,
    string scalar detwtscalar,
    string scalar activerowscalar,
    string scalar activewtscalar,
    real scalar catinteract,
    real scalar meanmodel,
    real scalar catprior,
    real scalar maxits,
    real scalar eps)
{
    real scalar p, q, t
    real matrix w, z, ximp
    struct glemb_prelim_s scalar boot_s, orig_s
    struct glemb_params scalar theta
    real scalar n
    real colvector idx, bootwt
    real matrix bootw, bootz, pseudo
    string rowvector wv, zv, ov
    real rowvector tv

    for (t = 71; t <= 83; t++) timer_clear(t)

    wv = tokens(wvars)
    zv = tokens(zvars)
    ov = tokens(outvars)
    p = cols(wv)
    q = cols(zv)

    if (cols(ov) != p + q) {
        _error(198, "internal error: output variable count does not match model variable count")
    }

    timer_on(71)
    w = st_data(., wv, touse)
    z = st_data(., zv, touse)
    timer_off(71)

    timer_on(72)
    n = rows(w)
    bootwt = glemb_bootstrap_counts(n)
    idx = selectindex(bootwt :> 0)
    bootw = w[idx,]
    bootz = z[idx,]
    bootwt = bootwt[idx]
    timer_off(72)

    timer_on(73)
    pseudo = glemb_pseudo_obs(w, z, catprior)
    if (rows(pseudo) > 0) {
        bootw = bootw \ pseudo[, 1::cols(w)]
        bootz = bootz \ pseudo[, (cols(w) + 1)::cols(pseudo)]
        bootwt = bootwt \ J(rows(pseudo), 1, 1)
    }
    timer_off(73)

    timer_on(74)
    boot_s = glemb_prelim_weighted(bootw, bootz, bootwt)
    timer_off(74)

    timer_on(75)
    theta = glemb_ecm_profile(
        boot_s,
        glemb_make_margins(boot_s.p, catinteract),
        glemb_make_mean_design(boot_s.d, meanmodel),
        1,
        maxits,
        eps)
    timer_off(75)

    timer_on(76)
    orig_s = glemb_prelim(w, z)
    timer_off(76)

    timer_on(77)
    ximp = glemb_impute(orig_s, theta)
    timer_off(77)

    timer_on(78)
    st_store(., ov, touse, ximp)
    timer_off(78)

    st_numscalar(iterscalar, theta.iterations)
    st_numscalar(convscalar, theta.converged)

    tv = timer_value(71)
    st_numscalar(readscalar, tv[1])
    tv = timer_value(72)
    st_numscalar(bootscalar, tv[1])
    tv = timer_value(73)
    st_numscalar(pseudoscalar, tv[1])
    tv = timer_value(74)
    st_numscalar(bootprelimscalar, tv[1])
    tv = timer_value(75)
    st_numscalar(ecmscalar, tv[1])
    tv = timer_value(76)
    st_numscalar(origprelimscalar, tv[1])
    tv = timer_value(77)
    st_numscalar(imputescalar, tv[1])
    tv = timer_value(78)
    st_numscalar(storescalar, tv[1])
    tv = timer_value(81)
    st_numscalar(estepscalar, tv[1])
    tv = timer_value(82)
    st_numscalar(mstepscalar, tv[1])
    tv = timer_value(83)
    st_numscalar(ipfscalar, tv[1])
    st_numscalar(detrowscalar, boot_s.det_n)
    st_numscalar(detwtscalar, boot_s.det_wt)
    st_numscalar(activerowscalar, boot_s.n - boot_s.det_n)
    st_numscalar(activewtscalar, boot_s.nwt - boot_s.det_wt)
}

real scalar glemb_resolve_catprior(real scalar catprior, real scalar n_cells)
{
    if (catprior < 0) return(1 / n_cells)
    return(catprior)
}

real scalar glemb_resolve_empri(real scalar empri, real scalar n, real scalar q)
{
    if (empri < 0) return(q / n)
    return(empri)
}

end
