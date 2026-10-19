*! _tvt_drop 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Drop the Stata matrices and scalars a TVTHRESH Mata engine uses to hand
*! its results back to the calling ado.
*!
*! WHY THIS EXISTS FROM THE FIRST COMMAND RATHER THAN THE TWELFTH. The sister
*! library spent twelve commands writing
*!
*!     capture matrix drop __tvt_*
*!     capture scalar drop __tvt_*
*!
*! which drops NOTHING: matrix drop and scalar drop take _all or a list of
*! exact names, never a wildcard, and the capture swallowed the error. Every
*! command left its whole engine namespace behind, and -- the part that
*! actually bites -- a stale value survived into the next run, so an engine
*! that failed to set one of its outputs silently inherited the previous
*! command's number instead of erroring.
*!
*! Called with no arguments it drops every name any TVTHRESH engine can
*! create, so adding an engine means editing this one file. Called with names
*! it drops just those. Each name is dropped on its own, because matrix drop
*! aborts the whole command at the first missing name.

program define _tvt_drop
    version 15
    if `"`0'"' != "" {
        foreach nm in `0' {
            capture matrix drop `nm'
            capture scalar drop `nm'
        }
        exit
    }
    local names                                                          ///
        __tvt_ho_ct __tvt_ho_gam __tvt_ho_ssr __tvt_ho_r0 __tvt_ho_g0    ///
        __tvt_ho_h1 __tvt_ho_bw __tvt_ho_n __tvt_ho_k __tvt_ho_vpos      ///
        __tvt_ho_ng __tvt_ho_b __tvt_ho_isp __tvt_ho_sing __tvt_ho_v      ///
        __tvt_ho_rcond                                               ///
        __tvt_fo_ssr __tvt_fo_ssrd __tvt_fo_ssrc __tvt_fo_ssr0           ///
        __tvt_fo_g0 __tvt_fo_g1 __tvt_fo_g2 __tvt_fo_k __tvt_fo_gc       ///
        __tvt_fo_f1 __tvt_fo_f2 __tvt_fo_f2sup __tvt_fo_p1 __tvt_fo_p2   ///
        __tvt_fo_T __tvt_fo_m __tvt_fo_amp __tvt_fo_n1 __tvt_fo_nboot    ///
        __tvt_fo_b __tvt_fo_path __tvt_fo_ssrk __tvt_fo_ci              ///
        __tvt_lr_stat __tvt_lr_k __tvt_lr_r __tvt_lr_Z __tvt_lr_s2       ///
        __tvt_lr_rho __tvt_lr_ng __tvt_lr_n                              ///
        __tvt_ct_d __tvt_ct_c __tvt_ct_m __tvt_ct_nobs __tvt_ct_ssr       ///
        __tvt_ct_sig __tvt_ct_sh1 __tvt_ct_nfull __tvt_ct_nfeas           ///
        __tvt_ct_ngrid __tvt_ct_supW __tvt_ct_aveW __tvt_ct_expW          ///
        __tvt_ct_supL __tvt_ct_aveL __tvt_ct_expL __tvt_ct_b              ///
        __tvt_ct_V __tvt_ct_grid __tvt_ct_pv                             ///
        __tvt_mh_sel __tvt_mh_nobs __tvt_mh_ln __tvt_mh_ssr __tvt_mh_aic  ///
        __tvt_mh_bic __tvt_mh_wald __tvt_mh_npsi __tvt_mh_pw __tvt_mh_b   ///
        __tvt_mh_V __tvt_mh_out __tvt_mh_mask                            ///
        __tvt_rk_m __tvt_rk_c __tvt_rk_ssr __tvt_rk_ssr0 __tvt_rk_ssrc    ///
        __tvt_rk_muc __tvt_rk_nobs __tvt_rk_T __tvt_rk_sh                 ///
        __tvt_rk_ncand __tvt_rk_nfeas __tvt_rk_f1c __tvt_rk_f1t           ///
        __tvt_rk_f2 __tvt_rk_b __tvt_rk_V __tvt_rk_grid __tvt_rk_pv
    foreach nm of local names {
        capture matrix drop `nm'
        capture scalar drop `nm'
    }
end
