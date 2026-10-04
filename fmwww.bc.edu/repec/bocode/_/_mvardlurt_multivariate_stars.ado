*! _mvardlurt_multivariate_stars  version 1.1.2  03oct2026
*! Significance stars from bootstrap critical values
*!   ***  1%    **  2.5%    *  5%    +  10%

capture program drop _mvardlurt_multivariate_stars
program define _mvardlurt_multivariate_stars, rclass
    version 14
    syntax , STAT(real) TAIL(string) CV10(real) CV05(real) CV025(real) CV01(real)

    local stars ""
    local level ""

    if "`tail'" == "lower" {
        if `stat' < `cv01' {
            local stars "***"
            local level "1%"
        }
        else if `stat' < `cv025' {
            local stars "**"
            local level "2.5%"
        }
        else if `stat' < `cv05' {
            local stars "*"
            local level "5%"
        }
        else if `stat' < `cv10' {
            local stars "+"
            local level "10%"
        }
    }
    else if "`tail'" == "upper" {
        if `stat' > `cv01' {
            local stars "***"
            local level "1%"
        }
        else if `stat' > `cv025' {
            local stars "**"
            local level "2.5%"
        }
        else if `stat' > `cv05' {
            local stars "*"
            local level "5%"
        }
        else if `stat' > `cv10' {
            local stars "+"
            local level "10%"
        }
    }
    else {
        di as err "tail() must be lower or upper"
        exit 198
    }

    return local stars "`stars'"
    return local level "`level'"
end
