## indsat_validate.R -- reference results from R gets::isat for indsat_validate.do
## Dr Merwan Roudane (merwanroudane920@gmail.com)
library(gets)
d <- read.csv("indsat_validate.csv")
X <- cbind(x = d$x)
show <- function(i, lab, m) {
  cat("\nCase", i, ":", lab, "  retained:", length(m$ISnames), " estimations:", m$no.of.estimations, "\n")
  print(round(coef(m), 7))
  if (!is.null(m$outlier.proportion.test))
    cat("outlier proportion z =", round(m$outlier.proportion.test$proportion$statistic, 6),
        " count p =", round(m$outlier.proportion.test$count$p.value, 4),
        " distortion =", round(m$outlier.distortion.test$statistic, 6), "\n")
}
q <- function(...) isat(d$y, mxreg = X, print.searchinfo = FALSE, additional.block.search = TRUE, ...)
show(1, "iis",                 q(iis = TRUE, sis = FALSE))
show(2, "sis",                 q(sis = TRUE))
show(3, "iis sis",             q(iis = TRUE, sis = TRUE))
show(4, "iis sis tis",         q(iis = TRUE, sis = TRUE, tis = TRUE))
show(5, "iis sis white",       q(iis = TRUE, sis = TRUE, t.pval = 0.01, vcov.type = "white"))
show(6, "sis newey-west",      q(sis = TRUE, t.pval = 0.01, vcov.type = "newey-west"))
show(7, "ar(1,2) iis tis aic", isat(d$y, ar = 1:2, mxreg = X, iis = TRUE, sis = FALSE, tis = TRUE, t.pval = 0.01,
                                    info.method = "aic", print.searchinfo = FALSE, additional.block.search = TRUE))
