*! _tk_drop 1.0.0  05oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Drop the Stata matrices and scalars a THRESHKIT Mata engine uses to hand
*! its results back to the calling ado.
*!
*! WHY THIS EXISTS. Every command used to end with
*!
*!     capture matrix drop __tk_*
*!     capture scalar drop __tk_*
*!
*! which drops NOTHING: matrix drop and scalar drop take _all or a list of
*! exact names, never a wildcard, and the capture swallowed the error. Twelve
*! commands therefore left their whole engine namespace behind after every
*! estimation. Worse, a stale value survives into the next run, so an engine
*! that fails to set one of its outputs silently inherits the previous
*! command's number instead of erroring.
*!
*! Called with no arguments it drops every name any engine in the package can
*! create, so adding a core means editing this one file and nothing else.
*! Called with names it drops just those. Each name is dropped on its own,
*! because matrix drop aborts the whole command at the first missing name.

program define _tk_drop
    version 15
    if `"`0'"' != "" {
        foreach nm in `0' {
            capture matrix drop `nm'
            capture scalar drop `nm'
        }
        exit
    }
    local tknames __tk_G __tk_K __tk_V __tk_a1 __tk_a2 __tk_aic         ///
        __tk_arq __tk_arr __tk_arrm __tk_b __tk_b1 __tk_b2 __tk_bdist   ///
        __tk_bdist_f __tk_bdist_lm __tk_bestF __tk_bestd __tk_bestp     ///
        __tk_beta __tk_bic __tk_bicgp __tk_bmat __tk_c1 __tk_c2         ///
        __tk_cbest __tk_cbestd __tk_cbestp __tk_ci1 __tk_ci2 __tk_cib   ///
        __tk_cic __tk_cihi __tk_cilo __tk_ciset __tk_contig __tk_conv   ///
        __tk_crit __tk_cv __tk_darch __tk_delay __tk_delta __tk_dml     ///
        __tk_dn __tk_dnorm __tk_dserial __tk_e __tk_e0 __tk_edump       ///
        __tk_eta2 __tk_fcband __tk_fcfail __tk_fchist __tk_fcnhist      ///
        __tk_fcnpath __tk_fcnres __tk_fcshare __tk_fcskel __tk_fev1     ///
        __tk_fev2 __tk_fixg __tk_fsym __tk_gamma __tk_gammas __tk_ghat  ///
        __tk_girf __tk_gmax __tk_gmaxf __tk_gmaxl __tk_gmean __tk_gmin  ///
        __tk_gmx __tk_grad __tk_gradc __tk_graddump __tk_gradq __tk_h   ///
        __tk_hascons __tk_hetp0 __tk_hetp1 __tk_hqic __tk_irf1          ///
        __tk_irf2 __tk_irfb1 __tk_irfb2 __tk_irfmod1 __tk_irfmod2       ///
        __tk_irfn __tk_irfn1 __tk_irfn2 __tk_irfpsi1 __tk_irfpsi2       ///
        __tk_irfs1 __tk_irfs2 __tk_irfsp __tk_ivJ1 __tk_ivJ2            ///
        __tk_ivJdf __tk_ivV1 __tk_ivV2 __tk_ivb __tk_ivci1 __tk_ivci2   ///
        __tk_ivctg0 __tk_ivctg1 __tk_ivctg2 __tk_ivcv __tk_iveta1       ///
        __tk_iveta2 __tk_ivfail __tk_ivgamma __tk_ivk1 __tk_ivk2        ///
        __tk_ivkx __tk_ivkz __tk_ivn __tk_ivn1 __tk_ivn2 __tk_ivngci    ///
        __tk_ivngrid __tk_ivprof __tk_ivqci __tk_ivrfq __tk_ivrfsn      ///
        __tk_ivsig2 __tk_ivssr __tk_ivssr0 __tk_k __tk_keenan __tk_kg   ///
        __tk_kprof __tk_kres __tk_ksel __tk_kw __tk_kz __tk_lagp        ///
        __tk_lin __tk_ll __tk_ll0 __tk_lm __tk_lmave __tk_lmexp         ///
        __tk_lmsup __tk_lndet __tk_lndet0 __tk_lr __tk_lrave            ///
        __tk_lrexp __tk_lrsup __tk_m __tk_mbesti __tk_mbestp __tk_mcse  ///
        __tk_mk __tk_mkw __tk_mn __tk_moved __tk_ms __tk_msf1           ///
        __tk_msf2 __tk_msf3 __tk_mvarch __tk_mvk __tk_mvn __tk_mvnorm   ///
        __tk_mvser __tk_n __tk_n1 __tk_n2 __tk_nciset __tk_ngrid        ///
        __tk_nhigh __tk_nin __tk_nlow __tk_npar __tk_nreg __tk_nrsel    ///
        __tk_nsing __tk_ntp __tk_order __tk_p __tk_pb_cusum             ///
        __tk_pb_keenan __tk_pb_tsay86 __tk_pb_tsayF __tk_pboot __tk_pf  ///
        __tk_phi __tk_pl __tk_pphi __tk_prof __tk_profile __tk_qeq      ///
        __tk_qprof __tk_qres __tk_r2 __tk_r20 __tk_reps __tk_s2pool     ///
        __tk_scar __tk_sccand __tk_scfail __tk_scfam __tk_scfamp        ///
        __tk_sclin __tk_scminp __tk_scn __tk_scp __tk_segam __tk_sel    ///
        __tk_selg __tk_selp __tk_sigma __tk_sigma2 __tk_simY __tk_simn  ///
        __tk_simy __tk_skip __tk_srbd __tk_srbest __tk_srbestlm         ///
        __tk_srmax __tk_srn __tk_srp __tk_srpj __tk_srssr0 __tk_srtab   ///
        __tk_ssr __tk_ssr0 __tk_ssr1 __tk_ssr2 __tk_ssrreg __tk_states  ///
        __tk_statf __tk_statl __tk_supf __tk_suplm __tk_sz __tk_tau     ///
        __tk_tl __tk_tmax __tk_tri __tk_tsay86 __tk_tu __tk_tvsd        ///
        __tk_tvsfail __tk_tvsgam __tk_tvsgrid __tk_tvslin __tk_tvslp    ///
        __tk_tvslrow __tk_tvslval __tk_tvsn __tk_tvsp __tk_tvsrow       ///
        __tk_tvsval __tk_type __tk_urV __tk_uradf __tk_urb __tk_urbc    ///
        __tk_urbu __tk_urcv __tk_urd1 __tk_urfail __tk_urir1            ///
        __tk_urir2 __tk_urkz __tk_urlin __tk_urlse __tk_urmhat          ///
        __tk_urmused __tk_urn __tk_urnsw __tk_urp __tk_urptsc           ///
        __tk_urpwc __tk_urpwj __tk_urpwu __tk_urrho __tk_urse           ///
        __tk_ursig2 __tk_urssr __tk_urssr0 __tk_urtab __tk_urtsc        ///
        __tk_urwtest __tk_wald __tkm_E __tkm_X   ///
        __tk_t2fail __tk_t2A __tk_t2V __tk_t2Sig __tk_t2E __tk_t2grid     ///
        __tk_t2g1 __tk_t2g2 __tk_t2ld __tk_t2ld0 __tk_t2n1 __tk_t2n2      ///
        __tk_t2n3 __tk_t2kz __tk_t2ncell __tk_t2prof __tk_t2gam           ///
        __tk_t2bw __tk_t2n __tk_t2k __tk_t2kw __tk_t2beta __tk_t2b        ///
        __tk_seofail __tk_seosup __tk_seoave __tk_seoexp __tk_seogmax     ///
        __tk_seop __tk_seon __tk_seong __tk_seopath __tk_seobd   ///
        __tk_gbfail __tk_gbpath __tk_gbanch __tk_gbgamma __tk_gbxi           ///
        __tk_gblo __tk_gbhi __tk_gbcontig __tk_gbalo __tk_gbahi            ///
        __tk_gbacontig __tk_gbacv __tk_gbn __tk_gbng __tk_gbnanch          ///
        __tk_gbnfail   ///
        __tk_davf __tk_davl __tk_davvf __tk_davvl __tk_davq __tk_pathf __tk_pathl   ///
        __tk_lmrob   ///
        __tk_hetprof __tk_sigma2_1 __tk_sigma2_2 __tk_n1h __tk_n2h __tk_lr_var __tk_p_var   ///
        __tk_ugB __tk_uglags __tk_uggam __tk_uggirf __tk_ugfail __tk_ugn1 __tk_ugn2 __tk_ugnh __tk_ugsig   ///
        __tk_tsp __tk_tsd __tk_tsm __tk_tstab __tk_tsfail __tk_tsn __tk_tsoff __tk_tsncell __tk_tsbaic __tk_tsbbic __tk_tsbhq   ///
        __tk_skB __tk_sklags __tk_skgam __tk_skpath __tk_skroots __tk_skfix __tk_skcyc __tk_skdiv __tk_skmod1 __tk_skmod2 __tk_skhl1 __tk_skhl2 __tk_skfail   ///
        __tk_qtfail __tk_qtstat __tk_qtgam __tk_qttau __tk_qtp __tk_qtn __tk_qtng __tk_qtnt __tk_qtreps __tk_qtpath __tk_qttab __tk_qtbd   ///
        __tk_hacb __tk_hacV __tk_haclag __tk_hacrho __tk_hacn __tk_hack __tk_hacfail   ///
        __tk_tab __tk_taqt __tk_tagrid __tk_taboot __tk_tastat   ///
        __tk_tarhat __tk_tap __tk_tas2 __tk_tanpt __tk_tang   ///
        __tk_taconv __tk_taiter __tk_tamarad __tk_tanboot   ///
        __tk_tan __tk_tafail   ///
        __tk_bustat __tk_bup __tk_bucvs __tk_bucve __tk_bugrid   ///
        __tk_bur1 __tk_bur2 __tk_bunpt __tk_bung __tk_buplo   ///
        __tk_buphi __tk_bun __tk_bunb __tk_bufail   ///
        __tk_sbr __tk_sblo __tk_sbhi __tk_sbhw __tk_sbnblk   ///
        __tk_sbbeta __tk_sbubeta __tk_sbnrate __tk_sbb   ///
        __tk_sbn __tk_sbinfo __tk_sbfail   ///
        __tk_enb __tk_enV __tk_enprof __tk_enpiq __tk_engam   ///
        __tk_enssr __tk_ensig __tk_ensv __tk_enn1 __tk_enn2   ///
        __tk_ennpt __tk_enng __tk_enn __tk_enk __tk_enfail   ///
        __tk_ivtth __tk_ivtgrid __tk_ivtboot __tk_ivtw   ///
        __tk_ivtgam __tk_ivtp __tk_ivtwalt __tk_ivtgalt   ///
        __tk_ivtnpt __tk_ivtng __tk_ivtnb __tk_ivtn   ///
        __tk_ivtk __tk_ivtq __tk_ivtfail   ///
        __tk_su_b __tk_su_V __tk_su_trace __tk_su_dtrace   ///
        __tk_su_n __tk_su_off __tk_su_gamma __tk_su_d   ///
        __tk_su_k1 __tk_su_k2 __tk_su_aic __tk_su_aicn   ///
        __tk_su_n1 __tk_su_n2 __tk_su_ssr1 __tk_su_ssr2   ///
        __tk_su_s1 __tk_su_s2 __tk_su_ngrid
    foreach nm of local tknames {
        capture matrix drop `nm'
        capture scalar drop `nm'
    }
end
