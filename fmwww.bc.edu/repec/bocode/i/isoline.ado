*! isoline v1.1 (06 Nov 2026)
*! Asjad Naqvi (asjadnaqvi@gmail.com)

* v1.1 (06 Nov 2026): Standardized the minimum requirement to Stata 15 for the graphfunctions v1.8 release.
* v1.0 (06 Nov 2026): First release

version 15
capture program drop isoline
program define isoline, rclass
    version 15
    syntax varlist(numeric min=3 max=3) [if] [in], ///
        [Levels(numlist sort) n(integer 50) SMOoth(real 0) fill replace ///
        METHOD(string) POWer(string) ///
        GENX(name) GENY(name) GENZ(name) GENID(name) GENORDER(name)]

    if `n' < 2 {
        display as error "n() must be at least 2."
        exit 198
    }
    if missing(`smooth') | `smooth' < 0 | `smooth' > 1 {
        display as error "smooth() must be between 0 and 1."
        exit 198
    }
    local method = lower(trim("`method'"))
    if "`method'" == "" local method idw
    if !inlist("`method'", "idw", "nearest") {
        display as error "method() must be idw or nearest."
        exit 198
    }
    if "`power'" != "" {
        if "`method'" != "idw" {
            display as error "power() is only allowed with method(idw)."
            exit 198
        }
        capture confirm number `power'
        if _rc {
            display as error "power() must be a positive, nonmissing number."
            exit 198
        }
        if missing(real("`power'")) | real("`power'") <= 0 {
            display as error "power() must be a positive, nonmissing number."
            exit 198
        }
        local power = real("`power'")
    }
    else local power 2

    foreach v in x y z id order {
        if "`gen`v''" == "" local gen`v' _`v'
        local outputs `outputs' `gen`v''
    }
    local unique : list uniq outputs
    if wordcount("`unique'") != 5 {
        display as error "Output variable names must be distinct."
        exit 198
    }
    local overlap : list outputs & varlist
    if "`overlap'" != "" {
        display as error "Output variables must not overwrite x, y, or z."
        exit 198
    }
    if "`replace'" == "" {
        foreach v of local outputs {
            confirm new variable `v'
        }
    }

    marksample touse
    quietly count if `touse'
    if r(N) < 3 {
        display as error "At least three complete observations are required."
        exit 2001
    }
    local sample = r(N)
    gettoken x rest : varlist
    gettoken y z : rest
    quietly summarize `z' if `touse', meanonly
    if r(min) == r(max) {
        display as error "z must vary within the selected sample."
        exit 498
    }
    if "`levels'" == "" {
        forvalues k = 1/5 {
            local level = r(min) + (r(max) - r(min)) * `k' / 6
            local levels `levels' `level'
        }
    }
    local levels : list uniq levels

    tempname result
    mata: `result' = _isoline_build(st_data(., tokens("`varlist'"), ///
        "`touse'"), strtoreal(tokens("`levels'")), `n', "`fill'" != "", ///
        `smooth', "`method'", `power')
    mata: st_local("pieces", strofreal(sum(`result'[.,5] :== 1)))
    if `pieces' == 0 {
        mata: mata drop `result'
        display as error "No contour geometry found; check levels(), n(), and smooth()."
        exit 498
    }

    // Generate only after all calculation and validation have succeeded.
    if "`replace'" != "" {
        foreach v of local outputs {
            capture confirm variable `v'
            if !_rc drop `v'
        }
    }
    mata: _isoline_store(`result', tokens("`outputs'"))
    mata: mata drop `result'
    label variable `genx' "Contour x"
    label variable `geny' "Contour y"
    label variable `genz' "Contour level"
    label variable `genid' "Contour segment ID"
    label variable `genorder' "Point order within segment"
    if "`fill'" != "" {
        label variable `genz' "Depth band (ascending)"
        label variable `genid' "Contour polygon ID"
        label variable `genorder' "Point order within polygon"
    }

    return scalar N = `sample'
    if "`fill'" == "" {
        return scalar N_segments = `pieces'
        return local geometry "line"
    }
    else {
        return scalar N_polygons = `pieces'
        return scalar N_bands = wordcount("`levels'") + 1
        return local geometry "fill"
    }
    return scalar n = `n'
    return scalar smooth = `smooth'
    if `smooth' == 0 return local smoothing "none"
    else return local smoothing "gaussian"
    return local levels "`levels'"
    return local method "`method'"
    if "`method'" == "idw" return scalar power = `power'
end

capture mata: mata drop _isoline_build()
capture mata: mata drop _isoline_triangle()
capture mata: mata drop _isoline_store()
capture mata: mata drop _isoline_clip()
capture mata: mata drop _isoline_band()
capture mata: mata drop _isoline_smooth()
capture mata: mata drop _isoline_predict()

mata:
real matrix _isoline_triangle(real matrix p, real scalar level)
{
    real scalar a, b, t, k
    real matrix hits

    hits = J(2, 2, .)
    k = 0
    for (a = 1; a <= 3; a++) {
        b = mod(a, 3) + 1
        // Half-open crossings give shared vertices a consistent side.
        if ((p[a,3] < level) != (p[b,3] < level)) {
            t = (level - p[a,3]) / (p[b,3] - p[a,3])
            hits[++k,.] = (1-t) * p[a,1..2] + t * p[b,1..2]
        }
    }
    if (k != 2) return(J(0, 2, .))
    if (all(hits[1,.] :== hits[2,.])) return(J(0, 2, .))
    return(hits)
}

real matrix _isoline_clip(real matrix p, real scalar level, real scalar above)
{
    real scalar a, b, ina, inb, t
    real matrix out

    out = J(0, 3, .)
    for (a = 1; a <= rows(p); a++) {
        b = mod(a, rows(p)) + 1
        if (above) {
            ina = p[a,3] >= level
            inb = p[b,3] >= level
        }
        else {
            ina = p[a,3] <= level
            inb = p[b,3] <= level
        }
        if (ina != inb) {
            t = (level - p[a,3]) / (p[b,3] - p[a,3])
            out = out \ ((1-t)*p[a,1..2] + t*p[b,1..2], level)
        }
        if (inb) out = out \ p[b,.]
    }
    return(out)
}

real matrix _isoline_band(real matrix p, real rowvector levels, real scalar k)
{
    real scalar i, area
    real matrix xy

    // Assign constant triangles on a cut exactly once, to the upper band.
    if (min(p[.,3]) == max(p[.,3])) {
        if (k != 1 + sum(levels :<= p[1,3])) return(J(0,2,.))
    }
    if (k > 1) p = _isoline_clip(p, levels[k-1], 1)
    if (rows(p) == 0) return(J(0,2,.))
    if (k <= cols(levels)) p = _isoline_clip(p, levels[k], 0)
    if (rows(p) < 3) return(J(0,2,.))
    xy = p[.,1..2] \ p[1,1..2]
    area = 0
    for (i = 2; i < rows(xy)-1; i++) {
        area = area + (xy[i,1]-xy[1,1])*(xy[i+1,2]-xy[1,2]) -
            (xy[i+1,1]-xy[1,1])*(xy[i,2]-xy[1,2])
    }
    if (area == 0) return(J(0,2,.))
    return(xy)
}

real matrix _isoline_smooth(real matrix grid, real scalar n, real scalar bandwidth)
{
    real scalar i, j, axis, span, delta
    real matrix weights, wx, wy, values, out
    real colvector coordinate

    if (bandwidth == 0) return(grid)
    span = max(colmax(grid[.,1..2]) - colmin(grid[.,1..2]))
    for (axis = 1; axis <= 2; axis++) {
        if (axis == 1) coordinate = grid[1..n,1]
        else coordinate = grid[(1::n):*n,2]
        coordinate = (coordinate :- coordinate[1]) / span
        weights = J(n,n,0)
        for (i = 1; i <= n; i++) {
            for (j = 1; j <= n; j++) {
                delta = abs(coordinate[i] - coordinate[j])
                // Beyond 38 standard deviations, weights are numerically zero.
                if (delta <= 38*bandwidth) {
                    weights[i,j] = exp(-0.5*(delta/bandwidth)^2)
                }
            }
        }
        weights = weights :/ rowsum(weights)
        if (axis == 1) wx = weights
        else wy = weights
    }
    values = wy * rowshape(grid[.,3],n) * wx'
    out = grid
    out[.,3] = vec(values')
    return(out)
}

real scalar _isoline_predict(real matrix data, real rowvector xy,
    real scalar scale, string scalar method, real scalar power)
{
    real scalar dmin, i
    real colvector distance, weight

    distance = rowsum(((data[.,1..2] :- xy) / scale):^2)
    dmin = min(distance)
    if (method == "nearest" | dmin == 0) {
        for (i = 1; i <= rows(data); i++) {
            if (distance[i] == dmin) return(data[i,3])
        }
    }
    weight = (dmin :/ distance):^(power/2)
    return(sum(weight :* data[.,3]) / sum(weight))
}

real matrix _isoline_build(real matrix data, real rowvector levels,
    real scalar n, real scalar fill, real scalar smooth,
    string scalar method, real scalar power)
{
    real scalar i, j, k, h, m, scale, used, id, a, b, c, d, count, value
    real rowvector lo, hi, xy
    real matrix grid, out, hits, triangle

    data = sort(data, (1, 2))
    m = rows(data)
    for (i = 2; i <= m; i++) {
        if (all(data[i,1..2] :== data[i-1,1..2])) {
            errprintf("Sampled x/y locations must be unique.\n")
            _error(459)
        }
    }
    lo = colmin(data[.,1..2])
    hi = colmax(data[.,1..2])
    if (any(lo :== hi)) {
        errprintf("Both x and y must vary within the selected sample.\n")
        _error(498)
    }
    scale = max(hi - lo)
    grid = J(n*n, 3, .)
    for (j = 1; j <= n; j++) {
        for (i = 1; i <= n; i++) {
            xy = lo + (hi-lo) :* ((i-1, j-1) / (n-1))
            grid[(j-1)*n+i,.] = (xy,
                _isoline_predict(data, xy, scale, method, power))
        }
    }

    grid = _isoline_smooth(grid, n, smooth)
    out = J(1024, 5, .)
    used = id = 0
    for (k = 1; k <= cols(levels)+fill; k++) {
        for (j = 1; j < n; j++) {
            for (i = 1; i < n; i++) {
                a = (j-1)*n+i
                b = a+1
                c = a+n+1
                d = a+n
                for (h = 1; h <= 2; h++) {
                    if (h == 1) triangle = grid[(a\b\c),.]
                    else triangle = grid[(a\c\d),.]
                    if (fill) {
                        hits = _isoline_band(triangle, levels, k)
                        value = k
                    }
                    else {
                        hits = _isoline_triangle(triangle, levels[k])
                        value = levels[k]
                    }
                    if (rows(hits) == 0) continue
                    count = rows(hits)
                    if (used+count+1 > rows(out)) out = out \ J(rows(out),5,.)
                    id++
                    out[used+1..used+count,.] = (hits,
                        J(count,1,value), J(count,1,id), (1::count))
                    used = used+count+1
                }
            }
        }
    }
    if (used == 0) return(J(0, 5, .))
    return(out[1..used,.])
}

void _isoline_store(real matrix out, string rowvector names)
{
    real rowvector vars

    if (rows(out) > st_nobs()) st_addobs(rows(out)-st_nobs())
    vars = st_addvar("double", names)
    st_store((1::rows(out)), vars, out)
}
end