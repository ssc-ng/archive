*! xtxai 0.44.1-pmg-ect-guard 04nov2026 - strict ECT and panel-row validation; NOT SSC
* Single-file Stata source. No external xtxai_*.ado dependency.
program define xtxai, rclass
    version 16.0
    syntax [anything(name=rawvars)] [if] [in] [, MODEL(string) MODELS(string) EXPLAIN(string) GRAPH(string) HOLDOUT(real -999999) COMPARE REPLACE PREFIX(name) ID(string) METHOD(string) BACKGROUND(string) POSitive(name) NEGative(name) HORIZON(integer 20) REGIME(name) EFFECT(name) COEFMATRIX(name) VARS(varlist numeric) ECTVAR(varname numeric) ECTLAG(integer 1) DEPVAR(varname numeric) LRVARS(varlist numeric) FACTOR(varname numeric)]

    local model = lower(strtrim(`"`model'"'))
    local models = lower(strtrim(itrim(`"`models'"')))
    local explain = lower(strtrim(`"`explain'"'))
    local method = lower(strtrim(`"`method'"'))
    local graph = lower(strtrim(`"`graph'"'))

    if `"`models'"' != "" & `"`model'"' != "" {
        di as err "model() and models() cannot be combined"
        exit 198
    }
    if `"`method'"' != "" & `"`explain'"' != "" {
        di as err "choose explain() or legacy method(), not both"
        exit 198
    }
    if `"`explain'"' == "" local explain `"`method'"'
    if `"`explain'"' == "" local explain "auto"

    * PSSA reference-game linear adapter for estimated regress/xtreg FE/RE.
    * Explicit model(pssa) is intentionally routed before estimator autodetection.
    if "`model'" == "pssa" {
        if "`rawvars'`graph'`models'`compare'`coefmatrix'`ectvar'`depvar'`lrvars'" != "" {
            di as err "PSSA accepts vars(), id(), background(), factor(), prefix(), replace only"
            exit 198
        }
        if !inlist("`explain'", "auto", "linear", "shap") {
            di as err "PSSA linear reference game: use explain(linear) or explain(shap)"
            exit 198
        }
        local popts "vars(`vars') id(`id')"
        if "`background'" != "" local popts "`popts' background(`background')"
        if "`factor'" != "" local popts "`popts' factor(`factor')"
        if "`prefix'" != "" local popts "`popts' prefix(`prefix')"
        if "`replace'" != "" local popts "`popts' replace"
        xtxai_pssa_linear, `popts'
        return add
        exit
    }

    local isml = (`"`models'"' != "" | inlist(`"`model'"', "xgboost", "ebm", "randomforest"))

    if `isml' {
        if "`explain'" == "pssa" {
            if "`models'`compare'`graph'`factor'" != "" {
                di as err "ML PSSA: one model only, no models()/compare()/graph()/factor()"
                exit 198
            }
            if !inlist("`model'", "xgboost", "ebm") {
                di as err "ML PSSA currently supports xgboost and ebm"
                exit 198
            }
            if `holdout' == -999999 {
                di as err "ML PSSA requires holdout()"
                exit 198
            }
            if "`id'" == "" {
                di as err "ML PSSA requires id(panelvar)"
                exit 198
            }
            local mlpopt "model(`model') id(`id') holdout(`holdout')"
            if "`background'" != "" local mlpopt "`mlpopt' background(`background')"
            if "`prefix'" != "" local mlpopt "`mlpopt' prefix(`prefix')"
            if "`replace'" != "" local mlpopt "`mlpopt' replace"
            xtxai_mlpssa `rawvars' `if' `in', `mlpopt'
            return add
            exit
        }
        if `"`rawvars'"' == "" {
            di as err "ML models require depvar and indepvars"
            exit 102
        }
        if `holdout' == -999999 {
            di as err "holdout() is required for ML models in this preview"
            exit 198
        }
        if `"`graph'`prefix'`id'`background'"' != "" {
            di as err "graph(), prefix(), id(), background() are not implemented for ML in v0.7.0"
            exit 198
        }
        if `"`explain'"' != "auto" {
            if `"`models'"' != "" {
                di as err "models() comparison requires explain(auto): tree models use Tree SHAP; EBM uses additive terms"
                exit 198
            }
            if `"`model'"' == "xgboost" & !inlist(`"`explain'"', "shap", "tree_shap") {
                di as err "XGBoost currently supports explain(auto), explain(shap), explain(tree_shap)"
                exit 198
            }
            if `"`model'"' == "randomforest" & !inlist(`"`explain'"', "shap", "tree_shap") {
                di as err "Random Forest supports explain(auto), explain(shap), explain(tree_shap)"
                exit 198
            }
            if `"`model'"' == "ebm" & !inlist(`"`explain'"', "additive", "terms") {
                di as err "EBM currently supports explain(auto), explain(additive), explain(terms)"
                exit 198
            }
        }
        local mlopts ""
        if `"`models'"' != "" local mlopts `"models(`models')"'
        else local mlopts `"model(`model')"'
        if `"`compare'"' != "" local mlopts `"`mlopts' compare"'
        if `"`replace'"' != "" local mlopts `"`mlopts' replace"'
        xtxaiml `rawvars' `if' `in', holdout(`holdout') `mlopts'
        return add
        return local backend "ml"
        return local explanation `"`explain'"'
        exit
    }

    if `"`models'`compare'"' != "" {
        di as err "models()/compare currently supported for XGBoost, EBM and Random Forest only"
        exit 198
    }
    if `holdout' != -999999 {
        di as err "holdout() currently supported for ML only"
        exit 198
    }
    if `"`model'"' == "" | `"`model'"' == "auto" {
        if `"`e(cmd)'"' != "xtreg" | !inlist(`"`e(model)'"', "fe", "re") {
            di as err "automatic model detection currently supports preceding xtreg, fe/re only; specify model()"
            exit 301
        }
        local model `"`e(model)'"'
    }
    * Verified PMG ARDL(1,1,1) ECM observation-level linear index route.
    if "`model'" == "pmg" & "`explain'" == "dynamic" {
        if "`rawvars'`graph'`background'`id'`vars'`coefmatrix'`ectvar'`depvar'`lrvars'" != "" {
            di as err "PMG dynamic uses stored xtpmg estimation only; no varlist/graph()/manual coefficients"
            exit 198
        }
        local pmgopts ""
        if "`prefix'" != "" local pmgopts "`pmgopts' prefix(`prefix')"
        if "`replace'" != "" local pmgopts "`pmgopts' replace"
        if "`pmgopts'" == "" xtxai_pmg_dynamic
        else xtxai_pmg_dynamic, `pmgopts'
        return add
        exit
    }
    * PMG dedicated read-only contract: keep it before generic pending/longrun routes.
    if "`model'" == "pmg" & "`explain'" == "audit" {
        if "`rawvars'`graph'`background'`id'`vars'`coefmatrix'" != "" {
            di as err "PMG audit takes no varlist or other data transformation options"
            exit 198
        }
        xtxai_pmg_contract
        return add
        exit
    }
    * CS-ARDL partialling-out projection identity: xb2 = xb + projection component.
    if "`model'" == "csardl" & "`explain'" == "projection" {
        if "`rawvars'`graph'`background'`vars'`coefmatrix'`ectvar'`depvar'`lrvars'" != "" {
            di as err "CS-ARDL projection accepts id(), prefix(), replace only"
            exit 198
        }
        if "`id'" == "" {
            di as err "CS-ARDL projection requires id()"
            exit 198
        }
        local csopts "id(`id')"
        if "`prefix'" != "" local csopts "`csopts' prefix(`prefix')"
        if "`replace'" != "" local csopts "`csopts' replace"
        xtxai_csardl_projection, `csopts'
        return add
        exit
    }
    * CS-ARDL prediction API audit: inspect xb vs xb2 without attributing unobserved factors.
    if "`model'" == "csardl" & "`explain'" == "predaudit" {
        if "`rawvars'`graph'`background'`vars'`coefmatrix'`ectvar'`depvar'`lrvars'" != "" {
            di as err "CS-ARDL predaudit accepts only id(), prefix(), and replace"
            exit 198
        }
        if "`id'" == "" {
            di as err "CS-ARDL predaudit requires id()"
            exit 198
        }
        local csopts "id(`id')"
        if "`prefix'" != "" local csopts "`csopts' prefix(`prefix')"
        if "`replace'" != "" local csopts "`csopts' replace"
        xtxai_csardl_predaudit, `csopts'
        return add
        exit
    }
    * CS-ARDL explicit unit suffix-to-id mapping: partial observed-dynamic index only.
    if "`model'" == "csardl" & "`explain'" == "partial" {
        if "`rawvars'`graph'`background'`vars'`coefmatrix'`ectvar'`depvar'`lrvars'" != "" {
            di as err "CS-ARDL partial requires only id(), optional prefix(), and replace"
            exit 198
        }
        if "`id'" == "" {
            di as err "CS-ARDL partial requires id() explicitly to audit suffix-to-panel mapping"
            exit 198
        }
        local csopts "id(`id')"
        if "`prefix'" != "" local csopts "`csopts' prefix(`prefix')"
        if "`replace'" != "" local csopts "`csopts' replace"
        xtxai_csardl_partial, `csopts'
        return add
        exit
    }
    * Read-only CS-ARDL: verified e(bi) stripes and per-unit ARDL identities.
    if "`model'" == "csardl" & "`explain'" == "units" {
        if "`rawvars'`graph'`background'`id'`vars'`coefmatrix'`ectvar'`depvar'`lrvars'`prefix'" != "" {
            di as err "CS-ARDL units audit takes no data/graph/prefix options"
            exit 198
        }
        xtxai_csardl_units
        return add
        exit
    }
    * Audit actual stored postestimation results without presuming a matrix layout.
    if inlist("`model'", "rcsardl", "scc", "amg", "csardl", "csdl", "pmg") & "`explain'" == "audit" {
        if "`rawvars'" != "" {
            di as err "model audit takes no varlist; estimate the underlying model first"
            exit 198
        }
        xtxai_contract_audit, model(`model')
        return add
        exit
    }
    if `"`model'"' == "hscc" {
        if `"`e(cmd)'"' != "hscc" {
            di as err "first estimate hscc, then run xtxai, model(hscc)"
            exit 301
        }
        if `"`rawvars'"' != "" {
            di as err "pre-estimated HSCC uses xtxai without a varlist"
            exit 198
        }
        if !inlist(`"`explain'"', "auto", "heterogeneous") {
            di as err "HSCC preview supports explain(heterogeneous)"
            exit 198
        }
        if `"`background'"' != "" {
            di as err "background() is not supported by HSCC adapter"
            exit 198
        }
        local hsopts ""
        if `"`prefix'"' != "" local hsopts `"`hsopts' prefix(`prefix')"'
        if `"`replace'"' != "" local hsopts `"`hsopts' replace"'
        if `"`graph'"' != "" local hsopts `"`hsopts' graph(`graph')"'
        if `"`id'"' != "" local hsopts `"`hsopts' id(`id')"'
        xtxai_hscc, `hsopts'
        return add
        return local backend "hscc"
        return local explanation "heterogeneous"
        exit
    }
    if "`model'" == "xtscc" {
        if "`e(cmd)'" != "xtscc" {
            di as err "first estimate xtscc, then run xtxai, model(xtscc)"
            exit 301
        }
        if "`rawvars'`graph'`id'`background'`coefmatrix'`vars'" != "" {
            di as err "xtscc v0.35 requires no varlist, graph(), id(), background(), coefmatrix(), or vars()"
            exit 198
        }
        if !inlist("`explain'", "auto", "linear", "within") {
            di as err "xtscc supports explain(linear) or explain(within); not SHAP"
            exit 198
        }
        local xsopts ""
        if "`prefix'" != "" local xsopts "`xsopts' prefix(`prefix')"
        if "`replace'" != "" local xsopts "`xsopts' replace"
        if "`explain'" == "within" local xsopts "`xsopts' within"
        if "`xsopts'" == "" xtxai_xtscc
        else xtxai_xtscc, `xsopts'
        return add
        return local backend "xtscc"
        exit
    }
    if "`model'" == "quantile" local model "qreg"
    if inlist("`model'", "ols", "fgls", "pcse", "gee", "qreg", "rreg") {
        if "`rawvars'" != "" {
            di as err "pre-estimated standard models use xtxai without a varlist"
            exit 198
        }
        if !inlist("`explain'", "auto", "linear", "shap") {
            di as err "standard adapter supports explain(linear) or explain(shap)"
            exit 198
        }
        if "`explain'" == "auto" local explain "linear"
        local opts "model(`model') explain(`explain')"
        if "`prefix'" != "" local opts "`opts' prefix(`prefix')"
        if "`replace'" != "" local opts "`opts' replace"
        if "`graph'" != "" local opts "`opts' graph(`graph')"
        if "`id'" != "" local opts "`opts' id(`id')"
        if "`background'" != "" local opts "`opts' background(`background')"
        xtxai_standard, `opts'
        return add
        exit
    }
    if inlist("`model'", "cce", "ccemg", "xtdcce2", "dcce") {
        if `"`e(cmd)'"' != "xtdcce2" {
            di as err "first estimate xtdcce2, then run xtxai"
            exit 301
        }
        if `"`rawvars'"' != "" {
            di as err "pre-estimated CCE/MG uses xtxai without a varlist"
            exit 198
        }
        if `"`background'`id'"' != "" {
            di as err "background() and id() unsupported in CCE preview"
            exit 198
        }
        if !inlist("`explain'", "auto", "heterogeneous", "partial") {
            di as err "CCE/MG preview supports explain(heterogeneous) or explain(partial)"
            exit 198
        }
        if "`explain'" == "auto" local explain "heterogeneous"
        local opts "explain(`explain')"
        if "`prefix'" != "" local opts "`opts' prefix(`prefix')"
        if "`graph'" != "" local opts "`opts' graph(`graph')"
        if "`replace'" != "" local opts "`opts' replace"
        xtxai_cce, `opts'
        return add
        return local backend "xtdcce2"
        exit
    }
    if "`model'" == "xtie2" {
        if "`rawvars'" != "" {
            di as err "xtie2 requires a prior estimate and no variable list"
            exit 198
        }
        if !inlist("`explain'", "auto", "interaction", "marginal") {
            di as err "xtie2 supports explain(interaction) or explain(marginal)"
            exit 198
        }
        local xtopts ""
        if "`graph'" != "" local xtopts "`xtopts' graph(`graph')"
        if "`xtopts'" == "" xtxai_xtie2
        else xtxai_xtie2, `xtopts'
        return add
        exit
    }
    if inlist("`model'", "csardl", "csdl", "pmg") {
        if "`rawvars'" != "" {
            di as err "prior estimation needed; no varlist in longrun inspection"
            exit 198
        }
        if !inlist("`explain'", "auto", "longrun", "parameters") {
            di as err "longrun parameters only; dynamic attribution not implemented"
            exit 498
        }
        if "`graph'" != "" {
            di as err "longrun graph not validated"
            exit 498
        }
        xtxai_longrun, model(`model')
        return add
        exit
    }
    if inlist("`model'", "nardl", "nrardl", "ardl") & "`explain'" == "multipliers" {
        if "`rawvars'" != "" | "`graph'" != "" {
            di as error "Dynamic multiplier calculation takes no varlist/graph option."
            exit 198
        }
        if `horizon' < 1 | `horizon' > 300 {
            di as error "horizon() must be between 1 and 300"
            exit 198
        }
        if inlist("`model'", "nardl", "nrardl") {
            if "`positive'" == "" | "`negative'" == "" {
                di as error "Specify positive() and negative() partial-sum variables"
                exit 198
            }
            xtxai_multiplier_path, positive(`positive') negative(`negative') horizon(`horizon')
        }
        else {
            if "`positive'" == "" {
                di as error "For ARDL paths specify positive(name) as the input variable"
                exit 198
            }
            xtxai_multiplier_path, positive(`positive') horizon(`horizon')
        }
        return add
        return local model "`model'"
        exit
    }
    if inlist("`model'", "nardl", "nrardl") & "`explain'" == "longrun" {
        if "`rawvars'" != "" | "`graph'" != "" {
            di as error "Asymmetric long-run analysis requires previous regress and no graph or varlist"
            exit 198
        }
        if "`positive'" == "" | "`negative'" == "" {
            di as error "Specify positive() and negative() names of precomputed partial-sum variables"
            exit 198
        }
        xtxai_asym_lr, positive(`positive') negative(`negative')
        return add
        return local model "`model'"
        exit
    }
    if "`model'" == "ardl" & "`e(cmd)'" == "regress" {
        if "`rawvars'" != "" | !inlist("`explain'", "auto", "dynamic", "longrun") {
            di as err "for regress-based ARDL use xtxai, model(ardl) explain(longrun)"
            exit 198
        }
        if "`graph'" != "" {
            di as err "ARDL multiplier graph is not implemented"
            exit 498
        }
        xtxai_ardl_lr
        return add
        exit
    }
    if inlist("`model'", "dynlinear", "ardl", "nardl", "nrardl") {
        if "`rawvars'" != "" {
            di as err "first estimate model; no varlist in postestimation"
            exit 198
        }
        if "`model'" == "ardl" & "`e(cmd)'" != "ardl" {
            di as err "model(ardl) requires preceding ardl estimation"
            exit 301
        }
        if inlist("`model'", "nardl", "nrardl") & !inlist("`e(cmd)'", "regress", "ardl") {
            di as err "NARDL preview accepts an explicitly estimated linear lag specification only; no automatic nonlinear long-run inference"
            exit 301
        }
        if "`model'" == "dynlinear" & !inlist("`e(cmd)'", "regress", "ardl") {
            di as err "model(dynlinear) requires regress or ardl estimation"
            exit 301
        }
        if !inlist("`explain'", "auto", "dynamic", "linear") {
            di as err "dynamic linear adapter supports explain(dynamic)"
            exit 198
        }
        local dopts ""
        if "`prefix'" != "" local dopts "`dopts' prefix(`prefix')"
        if "`replace'" != "" local dopts "`dopts' replace"
        if "`graph'" != "" local dopts "`dopts' graph(`graph')"
        if "`dopts'" == "" xtxai_lagindex
        else xtxai_lagindex, `dopts'
        return add
        return local model "`model'"
        exit
    }
    if "`model'" == "threshold" {
        if "`rawvars'" != "" | !inlist("`explain'", "auto", "regime", "heterogeneous") {
            di as error "threshold adapter requires prior regress; use explain(regime)"
            exit 198
        }
        if "`regime'" == "" | "`effect'" == "" {
            di as error "specify regime(binary_variable) effect(continuous_variable)"
            exit 198
        }
        local ropts "regime(`regime') effect(`effect')"
        if "`replace'" != "" local ropts "`ropts' replace"
        xtxai_threshold, `ropts'
        return add
        exit
    }
    if "`model'" == "mg" {
        if "`rawvars'`graph'`id'`coefmatrix'" != "" {
            di as err "xtmg Mean Group uses stored coefficients; do not supply varlist, graph(), id(), or coefmatrix()"
            exit 198
        }
        if !inlist("`explain'", "auto", "heterogeneous", "full", "within") {
            di as err "MG supports explain(full), explain(heterogeneous), explain(within)"
            exit 198
        }
        local mgopts ""
        if "`vars'" != "" local mgopts "`mgopts' vars(`vars')"
        if "`prefix'" != "" local mgopts "`mgopts' prefix(`prefix')"
        if "`replace'" != "" local mgopts "`mgopts' replace"
        if "`explain'" == "within" local mgopts "`mgopts' within"
        xtxai_xtmg_mg, `mgopts'
        return add
        exit
    }
    if "`model'" == "amg" & "`coefmatrix'" == "" {
        if "`rawvars'`graph'`id'" != "" {
            di as error "AMG auto adapter: do not supply varlist(), graph() or id(); use xtmg estimation metadata"
            exit 198
        }
        if !inlist("`explain'", "auto", "heterogeneous", "within", "partial", "full") {
            di as error "AMG auto adapter supports explain(heterogeneous), explain(partial), explain(within), explain(full)"
            exit 198
        }
        local aopts ""
        if "`vars'" != "" local aopts "`aopts' vars(`vars')"
        if "`prefix'" != "" local aopts "`aopts' prefix(`prefix')"
        if "`replace'" != "" local aopts "`aopts' replace"
        if "`explain'" == "within" local aopts "`aopts' within"
        if "`explain'" == "full" local aopts "`aopts' full"
        xtxai_amg_partial, `aopts'
        return add
        exit
    }
    if inlist("`model'", "scc", "amg", "panelhetero") {
        if "`rawvars'" != "" | "`coefmatrix'" == "" | "`vars'" == "" | "`id'" == "" {
            di as err "heterogeneous adapter: provide id(), vars() and coefmatrix() after estimation"
            exit 198
        }
        if !inlist("`explain'", "auto", "heterogeneous", "linear", "within") {
            di as err "heterogeneous adapter supports explain(heterogeneous)"
            exit 198
        }
        if "`graph'" != "" {
            di as err "heterogeneous adapter: graph() not yet implemented"
            exit 198
        }
        if "`model'" == "scc" & "`e(cmd)'" != "scc" {
            di as err "model(scc) requires preceding scc estimation; otherwise use model(panelhetero) for a coefficient matrix audit"
            exit 301
        }
        if "`model'" == "amg" & !inlist("`e(cmd)'", "xtmg", "amg") {
            di as err "model(amg) requires preceding xtmg/amg estimation; otherwise use model(panelhetero)"
            exit 301
        }
        local hopts "id(`id') vars(`vars') coefmatrix(`coefmatrix')"
        if "`explain'" == "within" local hopts "`hopts' within"
        if "`prefix'" != "" local hopts "`hopts' prefix(`prefix')"
        if "`replace'" != "" local hopts "`hopts' replace"
        xtxai_panelhetero, `hopts'
        return add
        return local model "`model'"
        exit
    }
    if inlist("`model'", "scc", "amg", "nardl", "nrardl", "threshold", "randomforest", "prophet") {
        xtxai_pending, model(`model')
        exit 498
    }
    if "`model'" == "rcsardl" {
        if "`explain'" == "aggregation" {
            if "`rawvars'`graph'`id'`ectvar'`depvar'`lrvars'" != "" {
                di as err "explain(aggregation) accepts no variables, ECT or graph options"
                exit 198
            }
            xtxai_rcsardl_aggregation
            return add
            exit
        }
        if "`rawvars'" != "" {
            di as err "rcsardl: use no varlist; specify explain(adjustment) or explain(ect)"
            exit 198
        }
        * Real RCSARDL e() metadata: zero-option ECT route.
        if "`ectvar'" == "" & "`depvar'" == "" & "`lrvars'" == "" & "`id'" == "" & inlist("`explain'", "ect") {
            if "`graph'" != "" {
                di as error "graph() is not supported for RCSARDL explain(ect)"
                exit 198
            }
            local rcsopts "ectlag(`ectlag')"
            if "`prefix'" != "" local rcsopts "`rcsopts' prefix(`prefix')"
            if "`replace'" != "" local rcsopts "`rcsopts' replace"
            xtxai_rcsardl_realect, `rcsopts'
            return add
            exit
        }
        if "`ectvar'" == "" & "`depvar'" == "" & "`lrvars'" == "" & !inlist("`explain'", "auto", "dynamic", "adjustment") {
            di as err "rcsardl: explain(ect) requires ectvar() or depvar() with lrvars()"
            exit 198
        }
        if "`depvar'" != "" | "`lrvars'" != "" {
            if "`ectvar'" != "" | "`depvar'" == "" | "`lrvars'" == "" {
                di as error "provide depvar() and lrvars() together, without ectvar()"
                exit 198
            }
            if "`id'" == "" {
                di as error "automatic RCSARDL ECT requires id()"
                exit 198
            }
            if !inlist("`explain'", "auto", "dynamic", "ect") | "`graph'" != "" {
                di as error "automatic RCSARDL ECT supports explain(ect), without graph()"
                exit 198
            }
            local autoopts "id(`id') depvar(`depvar') lrvars(`lrvars') ectlag(`ectlag')"
            if "`prefix'" != "" local autoopts "`autoopts' prefix(`prefix')"
            if "`replace'" != "" local autoopts "`autoopts' replace"
            xtxai_rcsardl_autoect, `autoopts'
        }
        else if "`ectvar'" != "" {
            if !inlist("`explain'", "auto", "dynamic", "adjustment", "ect") {
                di as error "rcsardl with ectvar() supports explain(ect)"
                exit 198
            }
            if "`id'" == "" {
                di as error "supply id() identifying numeric panel units"
                exit 198
            }
            if "`graph'" != "" {
                di as error "graph() not supported with ectvar()"
                exit 198
            }
            local ectopts "id(`id') ectvar(`ectvar') ectlag(`ectlag')"
            if "`prefix'" != "" local ectopts "`ectopts' prefix(`prefix')"
            if "`replace'" != "" local ectopts "`ectopts' replace"
            xtxai_rcsardl_ect, `ectopts'
        }
        else {
            if "`id'" != "" | "`replace'" != "" | `ectlag' != 1 {
                di as error "id(), replace, ectlag() require ectvar() or depvar()/lrvars()"
                exit 198
            }
            if "`graph'" == "" xtxai_rcsardl
            else xtxai_rcsardl, graph(`graph')
        }
        return add
        exit
    }
    if inlist("`model'", "xtabond", "xtdpdsys") {
        if `"`rawvars'"' != "" {
            di as err "pre-estimated dynamic models require xtxai without a varlist"
            exit 198
        }
        if `"`background'`id'"' != "" {
            di as err "background() and id() are unavailable in the dynamic preview"
            exit 198
        }
        local opts "model(`model') explain(`explain')"
        if "`prefix'" != "" local opts "`opts' prefix(`prefix')"
        if "`graph'" != "" local opts "`opts' graph(`graph')"
        if "`replace'" != "" local opts "`opts' replace"
        xtxai_dynamic, `opts'
        return add
        exit
    }
    if !inlist(`"`model'"', "fe", "re") {
        di as err "model(`model') is on the roadmap but has no validated adapter in v0.7.0"
        di as err "currently available: fe, re, hscc (central only), xgboost, ebm"
        exit 198
    }
    if `"`e(cmd)'"' != "xtreg" | `"`e(model)'"' != `"`model'"' {
        di as err "first estimate xtreg, `model', then run xtxai"
        exit 301
    }
    if !inlist(`"`explain'"', "auto", "linear", "shap") {
        di as err "FE/RE supports explain(auto), explain(linear), explain(shap)"
        exit 198
    }
    if `"`explain'"' == "auto" local explain "linear"
    local opts `"method(`explain')"'
    if `"`prefix'"' != "" local opts `"`opts' prefix(`prefix')"'
    if `"`replace'"' != "" local opts `"`opts' replace"'
    if `"`graph'"' != "" local opts `"`opts' graph(`graph')"'
    if `"`id'"' != "" local opts `"`opts' id(`id')"'
    if `"`background'"' != "" local opts `"`opts' background(`background')"'
    xtxai_linear, `opts'
    return add
    return local backend "linear"
    return local explanation `"`explain'"'
end


* ===== BEGIN xtxai_standard.ado =====
*! xtxai_standard 0.18.0-preview - explicit linear predictor adapter
program define xtxai_standard, rclass
    version 16.0
    syntax [, MODEL(string) EXPLAIN(string) GRAPH(string) PREFIX(name) REPLACE ID(string) BACKGROUND(string)]
    local model = lower(strtrim("`model'"))
    local explain = lower(strtrim("`explain'"))
    local graph = lower(strtrim("`graph'"))
    if "`prefix'" == "" local prefix "xai_"
    if "`explain'" == "" local explain "linear"
    if !inlist("`explain'", "linear", "shap") {
        di as err "standard adapter supports explain(linear) or explain(shap)"
        exit 198
    }
    if !inlist("`graph'", "", "global", "temporal", "individual") {
        di as err "graph() must be global, temporal, or individual"
        exit 198
    }
    if "`background'" == "" local background "pooled"
    if "`background'" != "pooled" {
        di as err "standard adapter currently supports background(pooled) only"
        exit 198
    }
    if "`model'" == "qreg" & "`e(cmd)'" != "qreg" { 
        di as err "first run qreg, then xtxai, model(qreg)"
        exit 301
    }
    if "`model'" == "rreg" & "`e(cmd)'" != "rreg" {
        di as err "first run rreg, then xtxai, model(rreg)"
        exit 301
    }
    if "`model'" == "ols" & "`e(cmd)'" != "regress" {
        di as err "first run regress, then xtxai, model(ols)"
        exit 301
    }
    if "`model'" == "fgls" & "`e(cmd)'" != "xtgls" {
        di as err "first run xtgls, then xtxai, model(fgls)"
        exit 301
    }
    if "`model'" == "pcse" & "`e(cmd)'" != "xtpcse" {
        di as err "first run xtpcse, then xtxai, model(pcse)"
        exit 301
    }
    if "`model'" == "gee" {
        if "`e(cmd)'" != "xtgee" {
            di as err "first run xtgee, then xtxai, model(gee)"
            exit 301
        }
        * Deliberately strict: unsupported links/families must not be explained on the wrong scale.
        local family = lower(strtrim("`e(family)'"))
        local link = lower(strtrim("`e(link)'"))
        if "`family'" != "gaussian" | "`link'" != "identity" {
            di as err "gee adapter currently requires family(gaussian) link(identity)"
            di as err "stored family=`family' link=`link'; unsupported or missing metadata"
            exit 198
        }
    }
    if !inlist("`model'", "ols", "fgls", "pcse", "gee", "qreg", "rreg") {
        di as err "unknown standard adapter model"
        exit 198
    }
    if "`graph'" == "individual" & "`id'" == "" {
        di as err "graph(individual) requires id()"
        exit 198
    }
    if "`graph'" != "individual" & "`id'" != "" {
        di as err "id() only applies to graph(individual)"
        exit 198
    }
    local panelvar : char _dta[_TSpanel]
    local timevar : char _dta[_TStvar]
    if inlist("`graph'", "temporal", "individual") & "`timevar'" == "" {
        di as err "xtset panelvar timevar is needed for temporal/individual graph"
        exit 459
    }
    if "`graph'" == "individual" & "`panelvar'" == "" {
        di as err "panel ID is needed for individual graph"
        exit 459
    }
    local terms : colnames e(b)
    local xvars ""
    foreach v of local terms {
        if "`v'" != "_cons" {
            capture confirm numeric variable `v'
            if _rc {
                di as err "coefficient term `v' not a raw numeric regressor; factor terms, interactions and lag terms require a separate adapter"
                exit 198
            }
            capture confirm name `prefix'`v'
            if _rc {
                di as err "invalid contribution name `prefix'`v'"
                exit 198
            }
            local xvars "`xvars' `v'"
        }
    }
    if "`xvars'" == "" {
        di as err "no supported raw numeric regressors in e(b)"
        exit 198
    }
    tempvar smpl fitted check
    quietly gen byte `smpl' = e(sample)
    quietly count if `smpl'
    if r(N) != e(N) {
        di as err "e(sample) count differs from e(N); cannot safely explain this fit"
        exit 459
    }
    local out "`prefix'xb `prefix'baseline `prefix'check"
    foreach v of local xvars {
        local out "`out' `prefix'`v'"
    }
    if "`replace'" == "" {
        foreach v of local out {
            capture confirm new variable `v'
            if _rc {
                di as err "`v' exists; specify replace or a different prefix()"
                exit 110
            }
        }
    }
    else {
        foreach v of local out {
            capture drop `v'
        }
    }
    local base 0
    capture local base = _b[_cons]
    if _rc local base 0
    tempvar basework
    quietly gen double `basework' = `base' if `smpl'
    quietly gen double `fitted' = `base' if `smpl'
    foreach v of local xvars {
        quietly summarize `v' if `smpl', meanonly
        local mu = r(mean)
        quietly gen double `prefix'`v' = _b[`v'] * (`v' - `mu') if `smpl'
        quietly replace `basework' = `basework' + _b[`v'] * `mu' if `smpl'
        quietly replace `fitted' = `fitted' + _b[`v'] * `v' if `smpl'
        label variable `prefix'`v' "Centered linear index contribution: `v'"
    }
    quietly gen double `prefix'xb = `fitted' if `smpl'
    quietly gen double `prefix'baseline = `basework' if `smpl'
    quietly gen double `check' = `prefix'baseline if `smpl'
    foreach v of local xvars {
        quietly replace `check' = `check' + `prefix'`v' if `smpl'
    }
    quietly gen double `prefix'check = abs(`prefix'xb - `check') if `smpl'
    quietly summarize `prefix'check if `smpl', meanonly
    local maxerr = r(max)
    local N = r(N)
    if "`graph'" == "global" {
        preserve
        quietly keep if `smpl'
        local absvars ""
        foreach v of local xvars {
            tempvar a
            quietly gen double `a' = abs(`prefix'`v')
            local absvars "`absvars' `a'"
        }
        graph hbar (mean) `absvars', title("XTXAI: `model' global contributions") note("Prediction index only; not causal effects")
        restore
    }
    if "`graph'" == "temporal" {
        preserve
        quietly keep if `smpl'
        local cvars ""
        local plots ""
        foreach v of local xvars {
            local cvars "`cvars' `prefix'`v'"
            local plots `"`plots' (line `prefix'`v' `timevar', sort)"'
        }
        quietly collapse (mean) `cvars', by(`timevar')
        twoway `plots', title("XTXAI: `model' temporal contributions") note("Prediction index only; not causal effects")
        restore
    }
    if "`graph'" == "individual" {
        preserve
        quietly keep if `smpl'
        capture confirm numeric variable `panelvar'
        if !_rc {
            capture confirm number `id'
            if _rc {
                restore
                di as err "id() must be numeric for this panel ID"
                exit 198
            }
            quietly keep if `panelvar' == `id'
        }
        else quietly keep if `panelvar' == `"`id'"'
        quietly count
        if r(N) == 0 {
            restore
            di as err "no observations for selected id()"
            exit 2000
        }
        local plots ""
        foreach v of local xvars {
            local plots `"`plots' (line `prefix'`v' `timevar', sort)"'
        }
        twoway `plots', title("XTXAI: `model' individual contributions") note("Prediction index only; not causal effects")
        restore
    }
    di as text "XTXAI standard adapter: `model'; N=" as result `N'
    di as text "Linear index reconstruction max error: " as result %10.3e `maxerr'
    if "`explain'" == "shap" di as text "Additive linear interventional SHAP w.r.t. pooled empirical feature means (no interactions)."
    if "`model'" == "qreg" di as text "This is the conditional quantile linear-index decomposition, NOT an expectation or conditional mean decomposition."
    if "`model'" == "rreg" di as text "Robust regression coefficient contributions; NOT an attribution of the robust observation weights."
    di as text "Interpretation: model linear predictor; not a causal contribution."
    return scalar maxerror = `maxerr'
    return scalar N = `N'
    return local backend "standard"
    return local model "`model'"
    return local contributions "`xvars'"
end

* ===== END xtxai_standard.ado =====



* ===== BEGIN xtxai_linear.ado =====
*! xtxai_linear 0.6.0-preview - preserved FE/RE calculation engine
program define xtxai_linear, rclass
    version 16.0
    syntax [, PREFIX(name) REPLACE GRAPH(string) ID(string) METHOD(string) BACKGROUND(string)]

    if "`e(cmd)'" != "xtreg" {
        di as err "xtxai requires preceding xtreg, fe or xtreg, re"
        exit 301
    }
    if !inlist("`e(model)'", "fe", "re") {
        di as err "only xtreg, fe and xtreg, re are supported"
        exit 198
    }
    if "`prefix'" == "" local prefix "xai_"
    if "`method'" == "" local method "linear"
    local method = lower(strtrim("`method'"))
    if !inlist("`method'", "linear", "shap") {
        di as err "method() must be linear or shap"
        exit 198
    }
    if "`background'" == "" local background "pooled"
    local background = lower(strtrim("`background'"))
    if !inlist("`background'", "pooled", "panel") {
        di as err "background() must be pooled or panel"
        exit 198
    }
    if "`background'" == "panel" & "`method'" != "shap" {
        di as err "background(panel) currently requires method(shap)"
        exit 198
    }
    local graph = lower(strtrim("`graph'"))
    if !inlist("`graph'", "", "temporal", "global", "individual") {
        di as err "graph() must be temporal, global, or individual"
        exit 198
    }
    if "`id'" != "" & "`graph'" != "individual" {
        di as err "id() is available only with graph(individual)"
        exit 198
    }
    if "`graph'" == "individual" & "`id'" == "" {
        di as err "graph(individual) requires id()"
        exit 198
    }
    local panelvar : char _dta[_TSpanel]
    local timevar : char _dta[_TStvar]
    if "`timevar'" == "" local timevar "`e(tvar)'"
    if inlist("`graph'", "temporal", "individual") & "`timevar'" == "" {
        di as err "time variable not found; run xtset before estimation"
        exit 498
    }
    if "`graph'" == "individual" & "`panelvar'" == "" {
        di as err "panel identifier not found; run xtset before estimation"
        exit 498
    }
    if "`background'" == "panel" & "`panelvar'" == "" {
        di as err "panel identifier not found; run xtset before estimation"
        exit 498
    }
    local coefnames : colnames e(b)
    local xvars ""
    foreach v of local coefnames {
        if "`v'" != "_cons" {
            capture confirm variable `v'
            if _rc {
                di as err "unsupported coefficient `v': raw numeric variables only"
                exit 198
            }
            capture confirm name `prefix'`v'
            if _rc {
                di as err "invalid output name: `prefix'`v'"
                exit 198
            }
            local xvars "`xvars' `v'"
        }
    }
    if "`xvars'" == "" {
        di as err "no supported explanatory variables found"
        exit 198
    }
    local variables "`prefix'xb `prefix'baseline `prefix'check"
    foreach v of local xvars {
        local variables "`variables' `prefix'`v'"
    }
    if "`replace'" == "" {
        foreach v of local variables {
            capture confirm new variable `v'
            if _rc {
                di as err "output variable `v' already exists; use prefix() or replace"
                exit 110
            }
        }
    }
    else {
        foreach v of local variables {
            capture drop `v'
        }
    }
    tempvar sample reconstructed
    quietly gen byte `sample' = e(sample)
    quietly predict double `prefix'xb if `sample', xb
    local base = 0
    capture local base = _b[_cons]
    if _rc local base = 0
    tempvar baseline_work
    quietly gen double `baseline_work' = `base' if `sample'
    foreach v of local xvars {
        if "`background'" == "pooled" {
            quietly summarize `v' if `sample', meanonly
            local mu = r(mean)
            local base = `base' + _b[`v'] * `mu'
            quietly gen double `prefix'`v' = _b[`v'] * (`v' - `mu') if `sample'
            quietly replace `baseline_work' = `baseline_work' + _b[`v'] * `mu' if `sample'
        }
        else {
            tempvar unitmean
            quietly bysort `panelvar': egen double `unitmean' = mean(cond(`sample', `v', .))
            quietly gen double `prefix'`v' = _b[`v'] * (`v' - `unitmean') if `sample'
            quietly replace `baseline_work' = `baseline_work' + _b[`v'] * `unitmean' if `sample'
        }
        if "`method'" == "shap" {
            label variable `prefix'`v' "Interventional SHAP (linear, `background'): `v'"
        }
        else {
            label variable `prefix'`v' "Centered linear contribution: `v'"
        }
    }
    quietly gen double `prefix'baseline = `baseline_work' if `sample'
    quietly gen double `reconstructed' = `prefix'baseline if `sample'
    foreach v of local xvars {
        quietly replace `reconstructed' = `reconstructed' + `prefix'`v' if `sample'
    }
    quietly gen double `prefix'check = abs(`prefix'xb - `reconstructed') if `sample'
    quietly summarize `prefix'check if `sample', meanonly
    local maxerr = r(max)
    local n_sample = r(N)
    di as txt "XTXAI 0.3.0 | `method' contributions to xtreg xb"
    if "`background'" == "pooled" {
        di as txt "Model: `e(model)' | Background: pooled | Baseline: " as res %10.6f `base'
    }
    else {
        di as txt "Model: `e(model)' | Background: panel (unit-specific baseline)"
    }
    di as txt "Contribution variables: `xvars'"
    di as txt "Maximum reconstruction error: " as res %10.3e `maxerr'
    if "`method'" == "shap" {
        di as txt "Exact interventional Shapley values for an additive linear xb."
        di as txt "No interaction or conditional-dependence attribution is modeled."
    }
    else di as txt "Note: linear contributions; use method(shap) for explicit Shapley interpretation."
    di as txt "Note: explanation of xb, not a causal effect."
    di as txt "Note: xb excludes unit effects."

    if inlist("`graph'", "temporal", "individual") {
        local plots ""
        local legend ""
        local convars ""
        local k = 0
        foreach v of local xvars {
            local ++k
            local convars "`convars' `prefix'`v'"
            local plots `"`plots' (line `prefix'`v' `timevar', sort)"'
            local legend `"`legend' `k' "`v'""'
        }
        preserve
        quietly keep if `sample'
        if "`graph'" == "individual" {
            capture confirm numeric variable `panelvar'
            if !_rc {
                capture confirm number `id'
                if _rc {
                    restore
                    di as err "id() must be numeric for this panel identifier"
                    exit 198
                }
                quietly keep if `panelvar' == `id'
            }
            else {
                quietly keep if `panelvar' == `"`id'"'
            }
            quietly count
            if r(N) == 0 {
                restore
                di as err "no estimation-sample observations for id(`id')"
                exit 2000
            }
            twoway `plots', legend(order(`legend')) title("XTXAI: Individual Contributions") subtitle("`panelvar' = `id'") ytitle("Contribution to xb") xtitle("`timevar'") note("Model-prediction contributions, not causal effects")
        }
        else {
            quietly collapse (mean) `convars', by(`timevar')
            twoway `plots', legend(order(`legend')) title("XTXAI: Temporal Contributions") ytitle("Mean contribution to xb") xtitle("`timevar'") note("Model-prediction contributions, not causal effects")
        }
        restore
    }
    if "`graph'" == "global" {
        preserve
        quietly keep if `sample'
        local absvars ""
        local legend ""
        local k = 0
        foreach v of local xvars {
            local ++k
            tempvar ac
            quietly gen double `ac' = abs(`prefix'`v')
            local absvars "`absvars' `ac'"
            local legend `"`legend' label(`k' "`v'")"'
        }
        graph hbar (mean) `absvars', legend(`legend') title("XTXAI: Global Contributions") ytitle("Mean absolute contribution") note("Model-prediction contributions, not causal effects")
        restore
    }
    return scalar maxerror = `maxerr'
    if "`background'" == "pooled" return scalar baseline = `base'
    return local method "`method'"
    return local background "`background'"
    return scalar N = `n_sample'
    return local model "`e(model)'"
    return local contribution_vars "`xvars'"
end

* ===== END xtxai_linear.ado =====



* ===== BEGIN xtxai_cce.ado =====
*! xtxai_cce 0.16.0-preview 03nov2026 - guarded CCE/MG and DCCE plain-variable index audit
*! Exact e(sample) comparisons against xtdcce2 predict xb and xb2.
*! Does not reconstruct common-factor contributions, level fitted values or dynamic long-run effects.
capture program drop xtxai_cce
program define xtxai_cce, rclass
    version 17.0
    syntax [, PREFIX(name) REPLACE GRAPH(string) EXPLAIN(string)]
    if "`e(cmd)'" != "xtdcce2" {
        di as err "run xtdcce2 before xtxai_cce"
        exit 301
    }
    if "`prefix'" == "" local prefix "xai_cce_"
    if "`explain'" == "" local explain "heterogeneous"
    local graph = lower(strtrim("`graph'"))
    if !inlist("`graph'", "", "global", "individual", "temporal") {
        di as err "CCE supports global/individual/temporal graphs"
        exit 198
    }
    local dep "`e(depvar)'"
    local xs "`e(indepvar)'"
    local pv "`e(idvar)'"
    local tv "`e(tvar)'"
    local csa "`e(csa)'"
    local lags "`e(cr_lags)'"
    local lr "`e(lr)'"
    local cl "`e(cmdline)'"
    if "`xs'" == "" | "`dep'" == "" | "`pv'" == "" {
        di as err "missing estimator metadata"
        exit 498
    }
    if "`lr'" != "" | strpos(lower("`cl'"),"lr_options(") | strpos(lower("`cl'"),"lr(") {
        di as err "CS-ARDL/CS-DL/PMG long-run specifications not supported by this static adapter"
        exit 498
    }
    if strpos(lower("`cl'"),"pooled(") | strpos(lower("`cl'"),"pooledconstant") {
        di as err "pooled coefficients require a separate validated adapter"
        exit 498
    }
    if strpos(lower("`cl'"),"=") {
        di as err "IV or equation-like xtdcce2 specifications are not supported"
        exit 498
    }
    * DCCE with lagged cross-sectional averages is allowed only when the
    * structural regressors are plain numeric variables. Validate against
    * both xtdcce2 prediction definitions rather than assuming equivalence.
    if "`lags'" != "" & "`lags'" != "0" {
        di as txt "DCCE guard: lagged CSA detected (`lags'); xb/xb2 must pass reconstruction."
    }
    local k : word count `xs'
    if `k' < 1 | `k' > 12 {
        di as err "CCE preview requires 1..12 plain explanatory variables"
        exit 498
    }
    foreach x of local xs {
        capture confirm numeric variable `x'
        if _rc {
            di as err "only plain numeric regressors supported (no L., D., i., interactions): `x'"
            exit 498
        }
        if strlen("`prefix'" + "partial_" + "`x'") > 32 | strlen("`prefix'" + "b_" + "`x'") > 32 {
            di as err "prefix() too long for one of the variable names"
            exit 198
        }
    }
    tempvar esample
    quietly gen byte `esample' = e(sample)
    quietly count if `esample'
    local n = r(N)
    if `n' != e(N) {
        di as err "sample mismatch: e(sample) count differs from e(N)"
        exit 459
    }
    local generated "`prefix'xb `prefix'xb2 `prefix'error_raw `prefix'error_partial"
    foreach x of local xs {
        local generated "`generated' `prefix'b_`x' `prefix'partial_`x' `prefix'raw_`x' `prefix'adjusted_`x'"
    }
    local generated "`generated' `prefix'partial_`dep'"
    foreach v of local generated {
        capture confirm variable `v'
        if !_rc & "`replace'" == "" {
            di as err "variable `v' already exists; specify replace"
            exit 110
        }
    }
    if "`replace'" != "" {
        foreach v of local generated {
            capture drop `v'
        }
    }
    * predict creates one variable for each independent variable under the specified stub.
    predict double `prefix'b, coefficients
    predict double `prefix'partial, partial
    predict double `prefix'xb if `esample', xb
    predict double `prefix'xb2 if `esample', xb2
    tempvar re_raw re_partial
    quietly gen double `re_raw' = 0 if `esample'
    quietly gen double `re_partial' = 0 if `esample'
    local absvars ""
    local legendlabels ""
    local nlegend = 0
    foreach x of local xs {
        quietly gen double `prefix'raw_`x' = `prefix'b_`x' * `x' if `esample'
        quietly gen double `prefix'adjusted_`x' = `prefix'b_`x' * `prefix'partial_`x' if `esample'
        quietly replace `re_raw' = `re_raw' + `prefix'raw_`x' if `esample'
        quietly replace `re_partial' = `re_partial' + `prefix'adjusted_`x' if `esample'
        label variable `prefix'raw_`x' "Raw contribution: `x'"
        label variable `prefix'adjusted_`x' "Partial contribution: `x'"
        if "`explain'" == "partial" {
            tempvar abs_`x'
            quietly gen double `abs_`x'' = abs(`prefix'adjusted_`x') if `esample'
        }
        else {
            tempvar abs_`x'
            quietly gen double `abs_`x'' = abs(`prefix'raw_`x') if `esample'
        }
        label variable `abs_`x'' "`x'"
        local absvars "`absvars' `abs_`x''"
        local ++nlegend
        local legendlabels `"`legendlabels' label(`nlegend' "`x'")"'
    }
    quietly gen double `prefix'error_raw = abs(`re_raw' - `prefix'xb2) if `esample'
    quietly gen double `prefix'error_partial = abs(`re_partial' - `prefix'xb) if `esample'
    quietly summarize `prefix'error_raw if `esample', meanonly
    local err_raw = r(max)
    quietly summarize `prefix'error_partial if `esample', meanonly
    local err_partial = r(max)
    di as txt "XTXAI CCE/MG/DCCE guarded prototype | valid rows = " as res `n'
    di as txt "Raw contribution vs xb2 max error: " as res %12.4e `err_raw'
    di as txt "Partial contribution vs xb max error: " as res %12.4e `err_partial'
    di as txt "Both checks exclude partialled-out heterogeneous intercept/common-factor terms."
    if `err_raw' > 1e-7 | `err_partial' > 1e-7 {
        di as err "CCE contribution reconstruction exceeded tolerance"
        exit 459
    }
    if "`graph'" == "global" {
        if "`explain'" == "partial" local gt "Partial-variable contributions | xtdcce2"
        else local gt "Raw-variable contributions | xtdcce2"
        graph bar (mean) `absvars' if `esample', ///
            title("`gt'") ytitle("Mean absolute contribution") ///
            legend(`legendlabels' cols(1) size(small)) name(XTXAI_CCE_Global, replace)
    }
    if inlist("`graph'", "individual", "temporal") {
        if "`graph'" == "individual" local groupvar "`pv'"
        else local groupvar "`tv'"
        preserve
        quietly keep if `esample'
        quietly collapse (mean) `absvars', by(`groupvar')
        local plotcmd ""
        local j = 0
        foreach x of local xs {
            local ++j
            local av : word `j' of `absvars'
            local plotcmd `"`plotcmd' (line `av' `groupvar', sort)"'
        }
        twoway `plotcmd', title("CCE contributions | `graph'") ///
            ytitle("Mean absolute contribution") ///
            legend(`legendlabels' cols(1)) name(XTXAI_CCE_`graph', replace)
        restore
    }
    return scalar N = `n'
    return scalar maxerr_raw = `err_raw'
    return scalar maxerr_partial = `err_partial'
    return local backend "xtdcce2"
    return local explanation "`explain'"
end

* ===== END xtxai_cce.ado =====



* ===== BEGIN xtxai_hscc.ado =====
*! xtxai_hscc 0.9.0-preview 02nov2026 - full HSCC replay and within prediction diagnostics, NOT SSC
capture program drop xtxai_hscc
program define xtxai_hscc, rclass
    version 17.0
    syntax [, PREFIX(name) REPLACE GRAPH(string) EXPLAIN(string) ID(string)]
    if `"`e(cmd)'"' != "hscc" {
        di as err "estimate HSCC before calling XTXAI"
        exit 301
    }
    if `"`prefix'"' == "" local prefix "xai_hscc_"
    local graph = lower(strtrim(`"`graph'"'))
    if !inlist(`"`graph'"', "", "global", "temporal", "individual") {
        di as err "HSCC supports graph(global), graph(temporal), graph(individual)"
        exit 198
    }
    if `"`graph'"' == "individual" & `"`id'"' == "" {
        di as err "graph(individual) requires id()"
        exit 198
    }
    local dep `"`e(depvar)'"'
    local xvars `"`e(indepvars)'"'
    local pv `"`e(panelvar)'"'
    local tv `"`e(timevar)'"'
    local N = e(N)
    local T = e(T)
    local Ng = e(N_g)
    local L = e(lag)
    local tf = (`"`e(timefe)'"' != "")
    if `"`dep'`xvars'`pv'`tv'"' == "" {
        di as err "missing HSCC e() metadata"
        exit 498
    }
    confirm variable `dep' `xvars' `pv' `tv'
    capture confirm numeric variable `pv'
    if _rc {
        di as err "HSCC full replay preview requires a numeric panel ID"
        exit 198
    }
    tempvar sample tgroup
    quietly gen byte `sample' = !missing(`dep', `pv', `tv')
    foreach v of local xvars {
        quietly replace `sample' = 0 if missing(`v')
    }
    quietly count if `sample'
    if r(N) != `N' {
        di as err "full HSCC replay requires exact complete-case sample; if/in restricted estimation is not supported"
        exit 459
    }
    quietly egen long `tgroup' = group(`tv') if `sample'
    quietly levelsof `pv' if `sample', local(ids)
    local ni : word count `ids'
    if `ni' != `Ng' {
        di as err "HSCC group count mismatch"
        exit 459
    }
    foreach ii of local ids {
        quietly count if `pv' == `ii' & `sample'
        if r(N) != `T' {
            di as err "HSCC full replay requires strongly balanced panels"
            exit 459
        }
    }
    tempname origb origtime betai idsout breplay
    matrix `origb' = e(b)
    if `tf' matrix `origtime' = e(timefe_b)
    mata: xtxai_hscc__replay("`dep'", "`xvars'", "`pv'", "`tgroup'", "`sample'", `L', `tf')
    matrix `betai' = XTXAI_HS_BETA_I
    matrix `idsout' = XTXAI_HS_IDS
    matrix `breplay' = XTXAI_HS_CENTRAL
    local K = colsof(`origb')
    if rowsof(`betai') != `Ng' | colsof(`betai') != `K' {
        di as err "HSCC replay returned invalid coefficient dimensions"
        exit 498
    }
    local coeferr = 0
    forvalues j=1/`K' {
        local dev = abs(`origb'[1,`j'] - `breplay'[1,`j'])
        if `dev' > `coeferr' local coeferr = `dev'
    }
    if `coeferr' > 1e-7 {
        di as err "HSCC central slope mismatch after replay: " %12.4e `coeferr'
        exit 459
    }
    if `tf' {
        tempname recov
        matrix `recov' = XTXAI_HS_TIMEFE
        local timerr = 0
        forvalues t=1/`T' {
            local err = abs(`origtime'[1,`t'] - `recov'[1,`t'])
            if `err' > `timerr' local timerr = `err'
        }
        if `timerr' > 1e-7 {
            di as err "HSCC time effects mismatch after replay: " %12.4e `timerr'
            exit 459
        }
    }
    local names `"`prefix'pred `prefix'base `prefix'time `prefix'check `prefix'central `prefix'hetero"'
    foreach v of local xvars {
        local names `"`names' `prefix'`v'"'
    }
    foreach name of local names {
        capture confirm name `name'
        if _rc {
            di as err "invalid prefix/variable combination: `name'"
            exit 198
        }
        capture confirm new variable `name'
        if _rc & `"`replace'"' == "" {
            di as err "output variable `name' exists; specify replace"
            exit 110
        }
    }
    if `"`replace'"' != "" {
        foreach name of local names {
            capture drop `name'
        }
    }
    tempvar unitorder
    quietly egen long `unitorder' = group(`pv') if `sample'
    quietly gen double `prefix'time = 0 if `sample'
    if `tf' {
        forvalues t=1/`T' {
            quietly replace `prefix'time = `origtime'[1,`t'] if `tgroup' == `t' & `sample'
        }
    }
    quietly gen double `prefix'central = 0 if `sample'
    quietly gen double `prefix'hetero = 0 if `sample'
    local j = 0
    foreach v of local xvars {
        local ++j
        tempvar betaj mu
        quietly gen double `betaj' = .
        forvalues i=1/`Ng' {
            quietly replace `betaj' = `betai'[`i',`j'] if `unitorder' == `i' & `sample'
        }
        quietly bysort `pv': egen double `mu' = mean(cond(`sample', `v', .))
        quietly gen double `prefix'`v' = `betaj'*(`v'-`mu') if `sample'
        quietly replace `prefix'central = `prefix'central + `origb'[1,`j']*(`v'-`mu') if `sample'
        quietly replace `prefix'hetero = `prefix'hetero + (`betaj'-`origb'[1,`j'])*(`v'-`mu') if `sample'
        label var `prefix'`v' "HSCC heterogeneous within contribution: `v'"
    }
    quietly gen double `prefix'base = `prefix'time if `sample'
    quietly gen double `prefix'pred = `prefix'base + `prefix'central + `prefix'hetero if `sample'
    tempvar recon
    quietly gen double `recon' = `prefix'base if `sample'
    foreach v of local xvars {
        quietly replace `recon' = `recon' + `prefix'`v' if `sample'
    }
    quietly gen double `prefix'check = abs(`prefix'pred - `recon') if `sample'
    quietly sum `prefix'check if `sample', meanonly
    local errmax = r(max)
    label var `prefix'pred "HSCC within prediction (unit means removed; time effect included)"
    label var `prefix'central "Central-slope within component"
    label var `prefix'hetero "Heterogeneous-slope incremental within component"
    label var `prefix'base "Common time-effect baseline"
    label var `prefix'check "HSCC within contribution consistency error"
    di as txt "XTXAI HSCC v0.9.0-preview: full heterogeneous slope replay"
    di as txt "Replayed unit slopes: " as res `Ng' as txt " units, " as res `K' as txt " covariates"
    di as txt "Original vs replay central-slope max difference: " as res %10.3e `coeferr'
    if `tf' di as txt "Original vs replay time-effect max difference: " as res %10.3e `timerr'
    di as txt "Contribution reconstruction max error: " as res %10.3e `errmax'
    di as txt "Output is within prediction, not full-level fitted values; unit intercepts omitted."
    di as txt "Contributions explain model predictions, not causal effects."
    if `"`graph'"' == "global" {
        preserve
        quietly keep if `sample'
        local absvars ""
        local legend ""
        local k=0
        foreach v of local xvars {
            local ++k
            tempvar a
            quietly gen double `a' = abs(`prefix'`v')
            local absvars `"`absvars' `a'"'
            local legend `"`legend' label(`k' "`v'")"'
        }
        graph hbar (mean) `absvars', legend(`legend') title("XTXAI: HSCC Heterogeneous Contributions") note("HSCC within prediction, not causal effects")
        restore
    }
    if `"`graph'"' == "temporal" {
        preserve
        quietly keep if `sample'
        local plots ""
        local legend ""
        local k = 0
        foreach v of local xvars {
            local ++k
            local plots `"`plots' (line `prefix'`v' `tv', sort)"'
            local legend `"`legend' `k' "`v'""'
        }
        quietly collapse (mean) `prefix'time `xvars', by(`tv')
        * Temporal graph uses common time effects (separate from within heterogeneous contributions).
        twoway line `prefix'time `tv', sort title("HSCC: Common Time Effect") note("Centered time effects; not causal")
        restore
    }
    if `"`graph'"' == "individual" {
        preserve
        quietly keep if `sample' & `pv' == real(`"`id'"')
        quietly count
        if r(N)==0 {
            restore
            di as err "no observations for id(`id')"
            exit 2000
        }
        local plots ""
        local legend ""
        local k = 0
        foreach v of local xvars {
            local ++k
            local plots `"`plots' (line `prefix'`v' `tv', sort)"'
            local legend `"`legend' `k' "`v'""'
        }
        twoway `plots', legend(order(`legend')) title("HSCC: Unit `id' contributions") note("Within model contributions, not causal")
        restore
    }
    return scalar N = `N'
    return scalar N_g = `Ng'
    return scalar replay_error = `coeferr'
    return scalar maxerror = `errmax'
    return local model "hscc"
    return local explanation "heterogeneous"
end

mata:

void xtxai_hscc__replay(
    string scalar depvar,
    string scalar xvars,
    string scalar panelname,
    string scalar timename,
    string scalar tousename,
    real scalar L,
    real scalar timefe)
{
    real colvector use, sel, panel, tt, y, ids, times, idx, yg, yc, ug
    real matrix X, Xg, Xc, XX, Xy

    real matrix BB, Z, ZA, C0, M0, R0
    real matrix Sr, Vbar, Sraw, Seta, EV
    real rowvector EL, ELp, zbar

    real matrix Vi_store, Vi, Qinv, Hdiag, PSI, G0

    real matrix D, Dpre, Pmat, H, Hinv, PenEta, invEig
    real colvector YcAll, YcPre, theta, resid, lev, resid3, timeeff

    real scalar NN, TT, KK, g, Tg, q, k, j
    real scalar pGamma, pEta, pTot
    real scalar col0, e0, a, b
    real scalar s2sum, s2i, s2bar, epsEig
    real scalar hq, u3, r, tpos, ell, ww
    real scalar sse, sst, r2w

    real colvector bg, psi

    real matrix XTXAI_BETA_I, XTXAI_GAMMA, XTXAI_ETA
    real matrix Ghs, Vhs, AA, CC, GG
    real colvector sehs
    real rowvector BHSCC, BMG

    string rowvector xnames

    use = st_data(., tousename)
    sel = selectindex(use :== 1)

    panel = st_data(sel, panelname)
    tt    = st_data(sel, timename)
    y     = st_data(sel, depvar)

    xnames = tokens(xvars)
    X = st_data(sel, xnames)

    ids   = uniqrows(panel)
    times = uniqrows(tt)

    NN = rows(ids)
    TT = rows(times)
    KK = cols(X)

    BB = J(NN,KK,.)
    Z  = J(NN,KK,.)
    Vi_store = J(NN*KK,KK,.)

    s2sum = 0

    /*
     * 1. Preliminary unit-specific within slopes
     */
    for (g=1; g<=NN; g++) {

        idx = selectindex(panel :== ids[g])

        yg = y[idx,.]
        Xg = X[idx,.]
        Tg = rows(yg)

        Z[g,.] = mean(Xg)

        yc = yg :- mean(yg)
        Xc = Xg :- mean(Xg)

        XX = quadcross(Xc,Xc)
        Xy = quadcross(Xc,yc)

        if (rank(XX) < KK) {
            errprintf("unit %g has a rank-deficient within-regressor matrix\n", ids[g])
            _error(459)
        }

        bg = invsym(XX)*Xy
        ug = yc - Xc*bg

        BB[g,.] = bg'

        s2i = quadcross(ug,ug)/(Tg-KK-1)
        s2sum = s2sum + s2i

        /*
         * HC3 covariance proxy V_i
         */
        Qinv = invsym(XX/Tg)
        Hdiag = rowsum((Xc*invsym(XX)) :* Xc)

        PSI = J(Tg,KK,0)

        for (q=1; q<=Tg; q++) {

            hq = Hdiag[q]

            if (hq < 0) hq = 0
            if (hq > .999999) hq = .999999

            u3 = ug[q]/(1-hq)

            psi = Qinv*(Xc[q,.]'*u3)

            PSI[q,.] = psi'
        }

        G0 = quadcross(PSI,PSI)/Tg

        Vi = G0/Tg
        Vi = (Vi+Vi')/2

        e0 = (g-1)*KK + 1
        Vi_store[e0..(e0+KK-1),.] = Vi
    }

    s2bar = s2sum/NN
    BMG = mean(BB)

    /*
     * 2. Systematic slope heterogeneity:
     *    beta_i = beta + Gamma*z_i + eta_i
     */
    zbar = mean(Z)
    Z = Z :- zbar

    ZA = J(NN,1,1), Z

    C0 = pinv(quadcross(ZA,ZA))*quadcross(ZA,BB)

    M0 = ZA*C0
    R0 = BB-M0

    Sr = variance(R0)

    Vbar = J(KK,KK,0)

    for (g=1; g<=NN; g++) {

        e0 = (g-1)*KK + 1
        Vi = Vi_store[e0..(e0+KK-1),.]

        Vbar = Vbar + Vi
    }

    Vbar = Vbar/NN

    Sraw = Sr - Vbar
    Sraw = (Sraw+Sraw')/2

    /*
     * PSD projection of residual slope covariance
     */
    symeigensystem(Sraw, EV=., EL=.)

    ELp = EL :* (EL :> 0)

    Seta = EV*diag(ELp)*EV'
    Seta = (Seta+Seta')/2

    /*
     * 3. Penalty:
     *    P_eta = sigma_u^2 * (Sigma_eta + eps I)^(-1)
     */
    symeigensystem(Seta, EV=., EL=.)

    epsEig = 1e-8

    if (max(EL)>0) {
        epsEig = max((1e-8,1e-8*max(EL)))
    }

    invEig = 1 :/ (EL :+ epsEig)

    PenEta = s2bar * EV*diag(invEig)*EV'
    PenEta = (PenEta+PenEta')/2

    /*
     * 4. Joint design
     *
     * eta_N = -sum_{i=1}^{N-1} eta_i
     */
    pGamma = KK*KK
    pEta   = (NN-1)*KK
    pTot   = KK + pGamma + pEta

    D = J(rows(y),pTot,0)
    YcAll = J(rows(y),1,.)

    for (g=1; g<=NN; g++) {

        idx = selectindex(panel :== ids[g])

        yg = y[idx,.]
        Xg = X[idx,.]

        yc = yg :- mean(yg)
        Xc = Xg :- mean(Xg)

        YcAll[idx,.] = yc

        /*
         * central slope beta
         */
        D[idx,1..KK] = Xc

        /*
         * systematic slope heterogeneity
         */
        for (k=1; k<=KK; k++) {

            for (j=1; j<=KK; j++) {

                col0 = KK + (k-1)*KK + j

                D[idx,col0] = Xc[,k] :* Z[g,j]
            }
        }

        /*
         * residual unit slope deviation
         */
        if (g < NN) {

            e0 = KK + pGamma + (g-1)*KK + 1

            D[idx,e0..(e0+KK-1)] = Xc
        }
        else {

            for (a=1; a<NN; a++) {

                e0 = KK + pGamma + (a-1)*KK + 1

                D[idx,e0..(e0+KK-1)] = -Xc
            }
        }
    }

    /*
     * Preserve the one-way within-transformed joint system so that
     * common time effects can be recovered after FWL estimation.
     */
    Dpre  = D
    YcPre = YcAll

    /*
     * 4b. Optional common time fixed effects
     *
     * Residualize the complete joint design and the within-transformed
     * outcome with respect to common time effects. This is FWL-equivalent
     * to including additive time dummies as unpenalized nuisance terms,
     * while keeping time dummies outside the heterogeneous-slope blocks.
     */
    if (timefe==1) {
        for (tpos=1; tpos<=TT; tpos++) {
            idx = selectindex(tt :== tpos)
            YcAll[idx,.] = YcAll[idx,.] :- mean(YcAll[idx,.])
            D[idx,.]     = D[idx,.]     :- mean(D[idx,.])
        }
    }

    /*
     * 5. Penalized joint estimation
     */
    Pmat = J(pTot,pTot,0)

    for (a=1; a<NN; a++) {

        for (b=1; b<NN; b++) {

            e0   = KK + pGamma + (a-1)*KK + 1
            col0 = KK + pGamma + (b-1)*KK + 1

            Pmat[e0..(e0+KK-1),
                 col0..(col0+KK-1)] =
                Pmat[e0..(e0+KK-1),
                     col0..(col0+KK-1)] + PenEta

            if (a==b) {

                Pmat[e0..(e0+KK-1),
                     col0..(col0+KK-1)] =
                    Pmat[e0..(e0+KK-1),
                         col0..(col0+KK-1)] + PenEta
            }
        }
    }

    H = quadcross(D,D) + Pmat

    Hinv = pinv(H)

    theta = Hinv*quadcross(D,YcAll)

    BHSCC = theta[1..KK]'

    /* XTXAI replay: recover the entire set of jointly penalized unit slopes. */
    XTXAI_GAMMA = J(KK,KK,0)
    for (k=1; k<=KK; k++) {
        for (j=1; j<=KK; j++) {
            XTXAI_GAMMA[k,j] = theta[KK+(k-1)*KK+j]
        }
    }
    XTXAI_ETA = J(NN,KK,0)
    for (g=1; g<NN; g++) {
        XTXAI_ETA[g,.] = theta[(KK+pGamma+(g-1)*KK+1)..(KK+pGamma+g*KK)]'
    }
    XTXAI_ETA[NN,.] = -colsum(XTXAI_ETA[|1,1 \ NN-1,KK|])
    XTXAI_BETA_I = J(NN,KK,.)
    for (g=1; g<=NN; g++) {
        XTXAI_BETA_I[g,.] = BHSCC + Z[g,.]*XTXAI_GAMMA' + XTXAI_ETA[g,.]
    }
    st_matrix("XTXAI_HS_BETA_I", XTXAI_BETA_I)
    st_matrix("XTXAI_HS_IDS", ids')
    st_matrix("XTXAI_HS_CENTRAL", BHSCC)

    /*
     * Recover common time fixed effects after FWL estimation.
     *
     * With unit effects already removed, lambda_t is recovered as the
     * cross-sectional mean of the pre-time-demeaned residual at time t.
     * In a balanced panel, the recovered effects are mean-zero over time.
     */
    timeeff = J(TT,1,0)

    if (timefe==1) {
        for (tpos=1; tpos<=TT; tpos++) {
            idx = selectindex(tt :== tpos)
            timeeff[tpos] = mean(YcPre[idx,.] - Dpre[idx,.]*theta)
        }
    }

    /*
     * Descriptive within R-squared:
     * 1 - SSE_HSCC / SST_within
     *
     * Since YcAll is within-demeaned, its mean is zero by unit.
     */
    resid = YcAll - D*theta
    sse = quadcross(resid,resid)
    sst = quadcross(YcAll,YcAll)
    r2w = 1 - sse/sst

    /*
     * 6. HC3-adjusted DK/SCC covariance
     */
    lev = rowsum((D*Hinv) :* D)

    resid3 = resid

    for (r=1; r<=rows(resid); r++) {

        hq = lev[r]

        if (hq < 0) hq = 0
        if (hq > .999999) hq = .999999

        resid3[r] = resid[r]/(1-hq)
    }

    Ghs = J(TT,KK,0)

    for (r=1; r<=rows(y); r++) {

        tpos = tt[r]

        psi =
            Hinv[1..KK,.] *
            (D[r,.]'*resid3[r])

        Ghs[tpos,.] =
            Ghs[tpos,.] + psi'
    }

    Vhs = quadcross(Ghs,Ghs)

    for (ell=1; ell<=L; ell++) {

        ww = 1 - ell/(L+1)

        AA = Ghs[(ell+1)..TT,.]
        CC = Ghs[1..(TT-ell),.]

        GG = quadcross(AA,CC)

        Vhs =
            Vhs +
            ww*(GG+GG')
    }

    Vhs = (Vhs+Vhs')/2

    /*
     * Return results to Stata
     */
    st_matrix("XTXAI_HS_CENTRAL",BHSCC)
    st_matrix("XTXAI_HS_V",Vhs)
    st_matrix("XTXAI_HS_MG",BMG)
    st_matrix("XTXAI_HS_TIMEFE",timeeff')

    st_numscalar("XTXAI_HS_HETTRACE",trace(Seta))
    st_numscalar("XTXAI_HS_R2W",r2w)
}

end

* ===== END xtxai_hscc.ado =====



* ===== BEGIN xtxai_dynamic.ado =====
*! xtxai_dynamic 0.12.0-preview - Difference GMM and guarded System GMM level-index adapters
program define xtxai_dynamic, rclass
    version 16.0
    syntax [, MODEL(string) EXPLAIN(string) GRAPH(string) PREFIX(name) REPLACE]
    local model = lower(strtrim("`model'"))
    local explain = lower(strtrim("`explain'"))
    local graph = lower(strtrim("`graph'"))
    if "`model'" == "xtdpdsys" {
        local sysopts ""
        if "`explain'" != "" local sysopts "`sysopts' explain(`explain')"
        if "`graph'" != "" local sysopts "`sysopts' graph(`graph')"
        if "`prefix'" != "" local sysopts "`sysopts' prefix(`prefix')"
        if "`replace'" != "" local sysopts "`sysopts' replace"
        xtxai_sysgmm, `sysopts'
        return add
        exit
    }
    if "`model'" != "xtabond" {
        di as err "this revised dynamic adapter currently validates only xtabond; `model' needs a separate equation-specific adapter"
        exit 198
    }
    if "`e(cmd)'" != "xtabond" {
        di as err "first run xtabond; preceding e(cmd) is `e(cmd)'"
        exit 301
    }
    if !inlist("`explain'", "", "auto", "dynamic") {
        di as err "xtabond currently requires explain(dynamic)"
        exit 198
    }
    if !inlist("`graph'", "", "global") {
        di as err "xtabond preview supports graph(global) only"
        exit 198
    }
    if "`prefix'" == "" local prefix "xai_dyn_"
    local y "`e(depvar)'"
    if "`y'" == "" {
        di as err "dependent variable not stored in e(depvar)"
        exit 498
    }
    quietly xtset
    if "`r(panelvar)'" == "" | "`r(timevar)'" == "" {
        di as err "xtset panel and time before interpreting xtabond"
        exit 459
    }
    * Only single-equation, raw numeric regressors plus first lag of the outcome.
    * Reject interactions, multi-equation and other time-series specifications.
    local terms : colnames e(b)
    local k 0
    local seenlag 0
    foreach term of local terms {
        if "`term'" != "_cons" {
            if strpos("`term'", "#") | strpos("`term'", ":") {
                di as err "unsupported interaction or multi-equation term: `term'"
                exit 198
            }
            if "`term'" == "L.`y'" | "`term'" == "L1.`y'" {
                local expr "D.L.`y'"
                local seenlag 1
            }
            else {
                capture confirm numeric variable `term'
                if _rc {
                    di as err "unsupported xtabond term `term'; only raw numeric regressors and L.y are handled"
                    exit 198
                }
                local expr "D.`term'"
            }
            local ++k
            local term`k' "`term'"
            local expr`k' "`expr'"
        }
    }
    if `k' == 0 | !`seenlag' {
        di as err "expected xtabond coefficients with L.`y' and numeric covariates"
        exit 198
    }
    * A first-differenced equation contains no intercept; do not use _b[_cons].
    tempvar marked actual reconstructed
    quietly gen byte `marked' = e(sample)
    quietly count if `marked'
    local markedN = r(N)
    if `markedN' == 0 {
        di as err "missing e(sample)"
        exit 459
    }
    * Check inputs BEFORE touching previously produced output variables.
    tempvar dy
    quietly gen double `dy' = D.`y'
    tempvar tmpterms
    forvalues j=1/`k' {
        tempvar termval`j'
        quietly gen double `termval`j'' = `expr`j''
    }
    tempvar usable
    quietly gen byte `usable' = `marked' & !missing(`dy')
    forvalues j=1/`k' {
        quietly replace `usable' = 0 if missing(`termval`j'')
    }
    quietly count if `usable'
    local N = r(N)
    if `N' != e(N) {
        di as err "valid differenced-equation rows (`N') differ from e(N) (" e(N) ")"
        di as err "cannot infer xtabond estimating equations safely for this specification"
        exit 459
    }
    local outputs "`prefix'xb `prefix'baseline `prefix'check `prefix'sample"
    forvalues j=1/`k' {
        local outputs "`outputs' `prefix'c`j'"
    }
    if "`replace'" == "" {
        foreach v of local outputs {
            capture confirm new variable `v'
            if _rc {
                di as err "output `v' exists; use replace or prefix()"
                exit 110
            }
        }
    }
    else {
        foreach v of local outputs {
            capture drop `v'
        }
    }
    * Mean-centered contributions reconstruct the differenced-equation index.
    * They do NOT measure the level forecast, GMM moment conditions, or causality.
    local base 0
    quietly gen double `actual' = 0 if `usable'
    forvalues j=1/`k' {
        local coef = _b[`term`j'']
        quietly summarize `termval`j'' if `usable', meanonly
        local mu = r(mean)
        local base = `base' + `coef' * `mu'
        quietly gen double `prefix'c`j' = `coef' * (`termval`j'' - `mu') if `usable'
        quietly replace `actual' = `actual' + `coef' * `termval`j'' if `usable'
        label variable `prefix'c`j' "Diff-equation contribution: `term`j''"
    }
    quietly gen double `prefix'xb = `actual' if `usable'
    quietly gen double `prefix'baseline = `base' if `usable'
    quietly gen byte `prefix'sample = `usable'
    quietly gen double `reconstructed' = `prefix'baseline if `usable'
    forvalues j=1/`k' {
        quietly replace `reconstructed' = `reconstructed' + `prefix'c`j' if `usable'
    }
    quietly gen double `prefix'check = abs(`prefix'xb - `reconstructed') if `usable'
    quietly summarize `prefix'check if `usable', meanonly
    local err = r(max)
    if "`graph'" == "global" {
        preserve
        quietly keep if `usable'
        local bars ""
        local legends ""
        forvalues j=1/`k' {
            tempvar av`j'
            quietly gen double `av`j'' = abs(`prefix'c`j')
            label variable `av`j'' "`term`j''"
            local bars "`bars' `av`j''"
            local legends `"`legends' label(`j' "`term`j''")"'
        }
        graph hbar (mean) `bars', legend(`legends') title("XTXAI: Difference GMM contributions") ///
            ytitle("Mean absolute contribution") ///
            note("Differenced linear index; not causal or instrument attribution")
        restore
    }
    di as txt "XTXAI Difference GMM preview | valid differenced rows = " as res `N'
    di as txt "e(sample) rows = " as res `markedN' as txt " | e(N) = " as res e(N)
    di as txt "Differenced-index contribution reconstruction max error: " as res %10.3e `err'
    di as txt "Explained: D.y linear index using D.L.y and D.x; _cons excluded."
    di as txt "NOT a validation of fitted values, instrument quality, or causal effects."
    return scalar N = `N'
    return scalar markedN = `markedN'
    return scalar maxerror = `err'
    return local model "xtabond"
    return local backend "difference_gmm_index"
end


*! Guarded System GMM LEVEL-equation index contribution prototype.
*! This does NOT explain the differenced equation, the GMM moments, or level fixed effects.
program define xtxai_sysgmm, rclass
    version 16.0
    syntax [, EXPLAIN(string) GRAPH(string) PREFIX(name) REPLACE]
    if "`e(cmd)'" != "xtdpdsys" {
        di as err "first estimate xtdpdsys; current e(cmd) is `e(cmd)'"
        exit 301
    }
    if !inlist(lower("`explain'"), "", "auto", "dynamic") {
        di as err "System GMM preview requires explain(dynamic)"
        exit 198
    }
    if !inlist(lower("`graph'"), "", "global") {
        di as err "System GMM preview currently supports graph(global) only"
        exit 198
    }
    if "`prefix'" == "" local prefix "xai_sys_"
    local y "`e(depvar)'"
    capture confirm numeric variable `y'
    if _rc {
        di as err "no usable dependent variable e(depvar)"
        exit 498
    }
    quietly xtset
    if "`r(panelvar)'" == "" | "`r(timevar)'" == "" {
        di as err "xtset panel and time required"
        exit 459
    }
    local terms : colnames e(b)
    local k 0
    local lagfound 0
    local hascons 0
    foreach term of local terms {
        if "`term'" == "_cons" {
            local hascons 1
        }
        else {
            if strpos("`term'", "#") | strpos("`term'", ":") {
                di as err "unsupported multi-equation or factor term: `term'"
                exit 198
            }
            if inlist("`term'", "L.`y'", "L1.`y'") {
                local expression "L.`y'"
                local lagfound 1
            }
            else {
                capture confirm numeric variable `term'
                if _rc {
                    di as err "unsupported xtdpdsys coefficient `term'; raw numeric covariates only"
                    exit 198
                }
                local expression "`term'"
            }
            local ++k
            local term`k' "`term'"
            local expr`k' "`expression'"
        }
    }
    if `k' == 0 | !`lagfound' {
        di as err "expected L.y and raw covariate coefficients in e(b)"
        exit 198
    }
    tempvar marked usable index recon
    quietly gen byte `marked' = e(sample)
    quietly count if `marked'
    local markN = r(N)
    if `markN' == 0 {
        di as err "e(sample) unavailable: cannot identify eligible observations"
        exit 459
    }
    forvalues j=1/`k' {
        tempvar x`j'
        quietly gen double `x`j'' = `expr`j''
    }
    quietly gen byte `usable' = `marked'
    forvalues j=1/`k' {
        quietly replace `usable' = 0 if missing(`x`j'')
    }
    quietly count if `usable'
    local N = r(N)
    if `N' == 0 {
        di as err "no complete level-equation observations in e(sample)"
        exit 2000
    }
    local outputs "`prefix'xb `prefix'baseline `prefix'check `prefix'sample"
    forvalues j=1/`k' {
        local outputs "`outputs' `prefix'c`j'"
    }
    if "`replace'" == "" {
        foreach v of local outputs {
            capture confirm new variable `v'
            if _rc {
                di as err "output variable `v' already exists; specify replace"
                exit 110
            }
        }
    }
    else {
        foreach v of local outputs {
            capture drop `v'
        }
    }
    local base 0
    if `hascons' local base = _b[_cons]
    quietly gen double `index' = `base' if `usable'
    forvalues j=1/`k' {
        local b = _b[`term`j'']
        quietly summarize `x`j'' if `usable', meanonly
        local mu = r(mean)
        local base = `base' + `b'*`mu'
        quietly gen double `prefix'c`j' = `b'*(`x`j''-`mu') if `usable'
        quietly replace `index' = `index' + `b'*`x`j'' if `usable'
        label variable `prefix'c`j' "Level-index contribution `term`j''"
    }
    quietly gen double `prefix'xb = `index' if `usable'
    quietly gen double `prefix'baseline = `base' if `usable'
    quietly gen byte `prefix'sample = `usable'
    quietly gen double `recon' = `base' if `usable'
    forvalues j=1/`k' {
        quietly replace `recon' = `recon' + `prefix'c`j' if `usable'
    }
    quietly gen double `prefix'check = abs(`index'-`recon') if `usable'
    quietly summarize `prefix'check if `usable', meanonly
    local err = r(max)
    if "`graph'" == "global" {
        preserve
        quietly keep if `usable'
        local bars ""
        local legends ""
        forvalues j=1/`k' {
            tempvar a`j'
            quietly gen double `a`j'' = abs(`prefix'c`j')
            local bars "`bars' `a`j''"
            local legends `"`legends' label(`j' "`term`j''")"'
        }
        graph hbar (mean) `bars', legend(`legends') title("XTXAI: System GMM level-index contributions") ytitle("Mean absolute contribution") note("Level equation index only; NOT full System GMM or causal effects")
        restore
    }
    di as txt "XTXAI System GMM preview: LEVEL-index contributions only"
    di as txt "Usable e(sample) rows: " as res `N' as txt " | reported GMM e(N): " as res e(N)
    di as txt "Internal linear-index reconstruction max error: " as res %10.3e `err'
    di as txt "NOT validated against xtdpdsys fitted values; not a differenced-equation decomposition."
    di as txt "Instruments, moment conditions, and unit effects are NOT attributed."
    return scalar N = `N'
    return scalar maxerror = `err'
    return local model "xtdpdsys"
    return local backend "system_gmm_level_index_preview"
end

* ===== END xtxai_dynamic.ado =====



* ===== BEGIN xtxai_rcsardl.ado =====
*! xtxai_rcsardl 0.17.0-preview 03nov2026 - robust adjustment heterogeneity reporting
capture program drop xtxai_rcsardl
program define xtxai_rcsardl, rclass
    version 17.0
    syntax [, GRAPH(string)]
    if "`e(cmd)'" != "rcsardl" {
        di as err "estimate rcsardl first (requires e(cmd)=rcsardl)"
        exit 301
    }
    if !inlist(lower("`graph'"), "", "adjustment") {
        di as err "rcsardl supports graph(adjustment) only"
        exit 198
    }
    tempname LR U
    capture matrix `LR' = e(longrun)
    if _rc {
        di as err "missing e(longrun)"
        exit 498
    }
    local rcs = e(ect_rcs)
    local cs = e(ect_cs)
    if missing(`rcs') | missing(`cs') {
        di as err "missing conventional or robust adjustment coefficient"
        exit 498
    }
    di as text "XTXAI RCSARDL | parameter and robust heterogeneity diagnostics"
    di as text "Conventional CS-ARDL adjustment: " as result %10.6f `cs'
    di as text "Robust RCSARDL adjustment:      " as result %10.6f `rcs'
    di as text "Difference (robust - conventional): " as result %10.6f (`rcs' - `cs')
    di as text "Admissible units: " as result e(n_admissible) as text " / " as result e(n_total)
    di as text "Huber downweighted units: " as result e(n_downweighted)
    matrix list `LR'
    capture matrix `U' = e(unit_adjustment)
    if !_rc {
        local nrow = rowsof(`U')
        local ncol = colsof(`U')
        di as text "Retained unit adjustment matrix: `nrow' rows, `ncol' columns"
        if "`graph'" == "adjustment" {
            if `ncol' < 3 {
                di as error "unit adjustment matrix lacks expected [ID,phi,weight] columns"
                exit 498
            }
            preserve
            quietly clear
            quietly set obs `nrow'
            quietly gen double xai_id = .
            quietly gen double xai_phi = .
            quietly gen double xai_weight = .
            forvalues i = 1/`nrow' {
                quietly replace xai_id = el(`U',`i',1) in `i'
                quietly replace xai_phi = el(`U',`i',2) in `i'
                quietly replace xai_weight = el(`U',`i',3) in `i'
            }
            quietly gen double xai_aggregate = `rcs'
            twoway (scatter xai_phi xai_id, msize(small)) ///
                (line xai_aggregate xai_id, sort lpattern(dash)), ///
                title("RCSARDL unit adjustment coefficients") ///
                ytitle("Robust adjustment coefficient") xtitle("Panel identifier") ///
                legend(order(1 "Unit-specific robust phi" 2 "Huber-weighted aggregate")) ///
                name(XTXAI_RCSARDL_Adjustment, replace)
            restore
        }
    }
    else if "`graph'" != "" {
        di as err "missing e(unit_adjustment); cannot draw the adjustment plot"
        exit 498
    }
    di as text "Long-run parameters are conventional CS-ARDL estimates; robustification affects adjustment only."
    di as text "Weights and phi_i are not SHAP values; no equilibrium-error time-series contributions reconstructed."
    return scalar ect_cs = `cs'
    return scalar ect_rcs = `rcs'
    return scalar adjustment_difference = `rcs' - `cs'
    return local backend "rcsardl"
end

* ===== END xtxai_rcsardl.ado =====



* ===== BEGIN xtxai_xtie2.ado =====
*! xtxai_xtie2 0.16.0-preview - analytic conditional marginal effects (not causal)
capture program drop xtxai_xtie2
program define xtxai_xtie2, rclass
    version 17.0
    syntax [, GRAPH(string)]
    if "`e(cmd)'" != "xtie2" {
        di as error "estimate xtie2 before xtxai, model(xtie2)"
        exit 301
    }
    local dep "`e(depvar)'"
    local vars "`e(indepvars)'"
    local x1 : word 1 of `vars'
    local x2 : word 2 of `vars'
    if "`x2'" == "" {
        di as error "xtie2 requires two independent variables"
        exit 498
    }
    if !inlist("`graph'", "", "marginal") {
        di as error "xtie2 supports graph(marginal) in this preview"
        exit 198
    }
    * The interaction's location in e(b) must be verified by its actual name.
    tempname B V b1 b2 b12 v1 v2 v12 c1 c2 c12 n1 n2
    capture matrix `B'=e(b)
    if _rc {
        di as error "e(b) missing: cannot calculate full marginal effects"
        exit 498
    }
    capture matrix `V'=e(V)
    if _rc {
        di as error "e(V) missing: cannot calculate standard errors"
        exit 498
    }
    local i1=colnumb(`B',"`x1'")
    local i2=colnumb(`B',"`x2'")
    local i12=colnumb(`B',"c.`x1'#c.`x2'")
    if missing(`i12') local i12=colnumb(`B',"c.`x2'#c.`x1'")
    if missing(`i1') | missing(`i2') | missing(`i12') {
        di as error "cannot locate x1/x2 or interaction in e(b); unsupported specification"
        exit 498
    }
    scalar `b1'=`B'[1,`i1']
    scalar `b2'=`B'[1,`i2']
    scalar `b12'=`B'[1,`i12']
    scalar `v1'=`V'[`i1',`i1']
    scalar `v2'=`V'[`i2',`i2']
    scalar `v12'=`V'[`i12',`i12']
    scalar `c1'=`V'[`i1',`i12']
    scalar `c2'=`V'[`i2',`i12']
    if `v1'<0 | `v2'<0 | `v12'<0 {
        di as error "invalid covariance diagonal"
        exit 498
    }
    tempvar sample me1 me2 se1 se2
    quietly gen byte `sample'=e(sample)
    quietly gen double `me1'=`b1'+`b12'*`x2' if `sample'
    quietly gen double `me2'=`b2'+`b12'*`x1' if `sample'
    quietly gen double `se1'=sqrt(max(0,`v1'+2*`x2'*`c1'+`x2'^2*`v12')) if `sample'
    quietly gen double `se2'=sqrt(max(0,`v2'+2*`x1'*`c2'+`x1'^2*`v12')) if `sample'
    quietly summarize `me1' if `sample', meanonly
    local mean1=r(mean)
    quietly summarize `me2' if `sample', meanonly
    local mean2=r(mean)
    quietly count if `sample' & !missing(`me1',`me2',`se1',`se2')
    local n=r(N)
    if `n'==0 {
        di as error "no observations available for marginal-effect calculations"
        exit 2000
    }
    di as txt "XTXAI XTIE2 conditional marginal effects | N=" as res `n'
    di as txt "Mean ME of `x1': " as res %11.6g `mean1'
    di as txt "Mean ME of `x2': " as res %11.6g `mean2'
    di as txt "Interaction coefficient: " as res %11.6g `b12'
    di as txt "SE uses full covariance: Var(beta_x)+2*z*Cov(beta_x,beta_inter)+z^2*Var(beta_inter)."
    di as txt "These are conditional slopes, NOT SHAP values, causal effects or Hansen thresholds."
    if "`graph'"=="marginal" {
        tempvar lo hi
        quietly gen double `lo'=`me1'-invnormal(.975)*`se1' if `sample'
        quietly gen double `hi'=`me1'+invnormal(.975)*`se1' if `sample'
        twoway (rarea `lo' `hi' `x2' if `sample', sort color(gs13)) ///
           (line `me1' `x2' if `sample', sort lcolor(navy)), ///
           yline(0, lpattern(dash)) legend(off) ///
           xtitle("`x2' (moderator)") ytitle("Marginal effect of `x1'") ///
           title("XTIE2 conditional marginal effect (95% Wald CI)") ///
           name(XTXAI_XTIE2_Marginal, replace)
    }
    return scalar N=`n'
    return scalar mean_me_x1=`mean1'
    return scalar mean_me_x2=`mean2'
    return scalar beta_inter=`b12'
    return local backend "xtie2"
    return local explanation "conditional_marginal_effect"
end

* ===== END xtxai_xtie2.ado =====



* ===== BEGIN xtxai_longrun.ado =====
*! xtxai_longrun 0.17.0-preview 03nov2026 - guarded long-run estimates inspector
*! This reports existing estimator long-run coefficients; no unverified observation attribution.
capture program drop xtxai_longrun
program define xtxai_longrun, rclass
    version 17.0
    syntax [, MODEL(string) GRAPH(string)]
    local cmd "`e(cmd)'"
    if !inlist("`cmd'", "xtdcce2", "xtpmg") {
        di as error "xtxai_longrun requires a preceding xtdcce2 or xtpmg estimation"
        exit 301
    }
    local lr "`e(lr)'"
    local cl "`e(cmdline)'"
    if "`cmd'" == "xtdcce2" & "`lr'" == "" {
        di as error "e(lr) is empty: this xtdcce2 estimation has no declared long-run vector"
        exit 498
    }
    if "`graph'" != "" {
        di as error "long-run graph is disabled until coefficient naming and unit mapping are independently validated"
        exit 498
    }
    tempname B
    capture matrix `B' = e(b)
    if _rc {
        di as error "e(b) unavailable"
        exit 498
    }
    local cn : colnames `B'
    local nr = colsof(`B')
    di as text "XTXAI long-run estimator result inspection | `cmd'"
    if "`lr'" != "" di as text "Declared long-run vector: `lr'"
    di as text "Coefficient vector columns: `nr'"
    local hit = 0
    forvalues j=1/`nr' {
        local nm : word `j' of `cn'
        if substr("`nm'",1,3)=="lr_" {
            local ++hit
            di as text "  `nm' = " as result %12.7g el(`B',1,`j')
            return scalar lr_`hit' = el(`B',1,`j')
        }
    }
    if `hit' == 0 {
        di as text "No lr_-prefixed columns in e(b). Inspect estimator matrices below; no contributions assumed."
        matrix list `B'
    }
    else di as result "Identified `hit' lr_-prefixed coefficient(s) in e(b)."
    di as text "These are reported long-run parameter estimates, NOT SHAP or observation-level predictions."
    di as text "Dynamic adjustment, partialled-out common factors, and short-run terms are NOT reconstructed."
    return scalar N_lr = `hit'
    return local backend "`cmd'"
    return local type "longrun_parameters"
end

* ===== END xtxai_longrun.ado =====



* ===== BEGIN xtxai_pending.ado =====
*! xtxai_pending 0.15-preview - explicit unsupported-model diagnostics
capture program drop xtxai_pending
program define xtxai_pending, rclass
    version 17.0
    syntax , MODEL(string)
    di as error "XTXAI model(`model'): model-specific contribution adapter not yet implemented/validated."
    di as text "No prediction, SHAP attribution, or statistical inference has been fabricated."
    di as text "The model is registered for integrated development, not declared supported."
    return local backend "pending"
    return local model "`model'"
end

* ===== END xtxai_pending.ado =====



* ===== BEGIN xtxaiml.ado =====
*! xtxaiml 0.6.0-preview 02nov2026 - multi-model comparison, NOT SSC release
program define xtxaiml, rclass
    version 16.0
    syntax varlist(min=2 numeric) [if] [in], HOLDOUT(real) [MODEL(string) MODELS(string) COMPARE REPLACE]
    marksample touse
    gettoken depvar xvars : varlist

    if ("`model'" != "" & "`models'" != "") {
        di as err "specify either model() or models(), not both"
        exit 198
    }
    if ("`models'" == "" & "`compare'" != "") {
        di as err "compare requires models(xgboost ebm randomforest)"
        exit 198
    }
    if "`model'`models'" == "" {
        di as err "specify model(xgboost|ebm|randomforest) or models(...) compare"
        exit 198
    }
    local multi = ("`models'" != "")
    if `multi' {
        local models = lower(strtrim(itrim("`models'")))
        local engine_models ""
        local tocreate "xtml_set"
        local seen " "
        local nmod 0
        foreach m of local models {
            if !inlist("`m'", "xgboost", "ebm", "randomforest") {
                di as err "models() supports xgboost, ebm, randomforest"
                exit 198
            }
            if strpos("`seen'", " `m' ") {
                di as err "duplicate model `m'"
                exit 198
            }
            local seen "`seen'`m' "
            local ++nmod
            if "`engine_models'"=="" local engine_models "`m'"
            else local engine_models "`engine_models',`m'"
            if "`m'"=="xgboost" local alias "xgb"
            else if "`m'"=="randomforest" local alias "rf"
            else local alias "ebm"
            local tocreate "`tocreate' xtml_`alias'_pred xtml_`alias'_base"
        }
        if `nmod' < 2 {
            di as err "models() requires two or more models"
            exit 198
        }
    }
    else {
        local model = lower(strtrim("`model'"))
        if !inlist("`model'", "xgboost", "ebm", "randomforest") {
            di as err "model() must be xgboost, ebm or randomforest"
            exit 198
        }
        local engine_models "`model'"
        local tocreate "xtml_set xtml_pred xtml_base"
    }
    local panelvar : char _dta[_TSpanel]
    local timevar : char _dta[_TStvar]
    if "`panelvar'" == "" | "`timevar'" == "" {
        di as err "run xtset panelvar timevar before xtxaiml"
        exit 459
    }
    local features ""
    local j = 0
    foreach v of local xvars {
        local ++j
        if `multi' {
            foreach m of local models {
                if "`m'"=="xgboost" local alias "xgb"
                else if "`m'"=="randomforest" local alias "rf"
                else local alias "ebm"
                local tocreate "`tocreate' xtml_`alias'_c`j'"
            }
        }
        else local tocreate "`tocreate' xtml_c`j'"
        if `j' == 1 local features "`v'"
        else local features "`features',`v'"
    }
    if "`replace'" == "" {
        foreach v of local tocreate {
            capture confirm new variable `v'
            if _rc {
                di as err "variable `v' already exists; specify replace"
                exit 110
            }
        }
    }
    capture findfile xtxaiml_engine.py
    if _rc {
        di as err "xtxaiml_engine.py not found; put it in a Stata adopath directory"
        exit 601
    }
    local engine "`r(fn)'"
    tempvar row
    quietly gen long `row' = _n
    tempfile input output result
    preserve
    quietly keep if `touse'
    quietly keep `row' `timevar' `depvar' `xvars'
    quietly rename `row' xtxai_row
    quietly rename `timevar' xtxai_time
    quietly rename `depvar' xtxai_y
    quietly export delimited using "`input'.csv", replace
    restore
    python script "`engine'", args("`input'.csv" "`output'.csv" "`engine_models'" "`holdout'" "`features'")
    preserve
    quietly import delimited using "`output'.csv", clear varnames(1)
    quietly rename xtxai_row `row'
    quietly save "`result'", replace
    restore
    if "`replace'" != "" {
        foreach v of local tocreate {
            capture drop `v'
        }
    }
    quietly merge 1:1 `row' using "`result'", nogen keep(master match)
    quietly drop `row'
    label variable xtml_set "0=train; 1=holdout; missing=excluded"
    if `multi' {
        foreach m of local models {
            if "`m'"=="xgboost" local alias "xgb"
            else if "`m'"=="randomforest" local alias "rf"
            else local alias "ebm"
            label variable xtml_`alias'_pred "`m' prediction"
            label variable xtml_`alias'_base "`m' explanation baseline"
            local j = 0
            foreach v of local xvars {
                local ++j
                if "`m'"=="ebm" local expl "EBM additive term (not SHAP)"
                else local expl "Tree SHAP contribution"
                label variable xtml_`alias'_c`j' "`expl': `v'"
            }
        }
        di as result "XTXAI ML preview complete: `models'"
    }
    else {
        label variable xtml_pred "XTXAI ML prediction (`model')"
        label variable xtml_base "Explanation baseline (`model')"
        local j = 0
        foreach v of local xvars {
            local ++j
            label variable xtml_c`j' "Contribution `v' (`model')"
        }
        di as result "XTXAI ML preview complete: `model'"
    }
    di as text "Do not interpret explanations as causal effects."
    return local models "`engine_models'"
    return local features "`xvars'"
end

* ===== END xtxaiml.ado =====



* ===== BEGIN XTXAI lagged-linear contribution adapter =====
*! xtxai_ardl_lr 0.21.0 - guarded ARDL(p,q) long-run multipliers from regress e(b)
* Supports explicit numeric regressors and Stata time-series lags in a single equation.
* Refuses factor terms, differences and multi-equation structures. Conditional association only.
capture program drop xtxai_ardl_lr
program define xtxai_ardl_lr, rclass
    version 17.0
    if "`e(cmd)'" != "regress" {
        di as error "This ARDL multiplier adapter requires a preceding regress-based ARDL."
        exit 301
    }
    local dep "`e(depvar)'"
    if "`dep'" == "" {
        di as error "Dependent variable could not be identified."
        exit 498
    }
    tempname B
    matrix `B' = e(b)
    local terms : colnames `B'
    local K = colsof(`B')
    local rho = 0
    local ndep = 0
    local xlist ""
    local banned = 0
    forvalues j=1/`K' {
        local term : word `j' of `terms'
        local coef = el(`B',1,`j')
        if "`term'" == "_cons" continue
        if missing(`coef') | strpos("`term'","#") | strpos("`term'",":") | strpos("`term'",".")==1 {
            di as error "Unsupported or missing ARDL coefficient: `term'"
            exit 498
        }
        * Terms must be plain variables, L.var, L2.var, etc. No D., F., or interactions.
        local stem "`term'"
        if strpos("`term'",".") {
            local dot = strpos("`term'",".")
            local op = substr("`term'",1,`dot'-1)
            local stem = substr("`term'",`dot'+1,.)
            if substr("`op'",1,1)!="L" {
                di as error "Only lag L. operators are admitted: `term'"
                exit 498
            }
            local steps = substr("`op'",2,.)
            if "`steps'"!="" {
                capture confirm number `steps'
                if _rc | real("`steps'")<1 | floor(real("`steps'"))!=real("`steps'") {
                    di as error "Invalid lag operator in `term'"
                    exit 498
                }
            }
        }
        capture confirm variable `stem'
        if _rc {
            di as error "ARDL base variable `stem' not found"
            exit 111
        }
        if "`stem'" == "`dep'" {
            if "`stem'" == "`term'" {
                di as error "Contemporaneous dependent variable on RHS cannot enter ARDL"
                exit 498
            }
            local rho = `rho' + `coef'
            local ++ndep
        }
        else {
            if !strpos(" `xlist' ", " `stem' ") local xlist "`xlist' `stem'"
        }
    }
    if `ndep'==0 {
        di as error "No lagged dependent variable: this is not a dynamic ARDL specification."
        exit 498
    }
    local den = 1-`rho'
    if abs(`den') < 1e-8 {
        di as error "ARDL long-run multiplier undefined: 1 - sum(lagged-y coefficients) near zero."
        exit 459
    }
    di as text "XTXAI ARDL long-run multiplier audit | regress-based model"
    di as text "Dependent variable: `dep' | lag-y terms: `ndep'"
    di as text "Sum lag-y coefficients: " as result %12.8g `rho'
    di as text "Long-run denominator (1-sum lag-y): " as result %12.8g `den'
    local i=0
    foreach x of local xlist {
        local num = 0
        forvalues j=1/`K' {
            local term : word `j' of `terms'
            local stem "`term'"
            if strpos("`term'",".") {
                local dot = strpos("`term'",".")
                local stem = substr("`term'",`dot'+1,.)
            }
            if "`stem'"=="`x'" local num = `num' + el(`B',1,`j')
        }
        local lr = `num'/`den'
        local ++i
        di as text "  `x': short-run coefficient sum=" as result %12.8g `num' as text " ; LR multiplier=" as result %12.8g `lr'
        return scalar lr_`i' = `lr'
        return scalar numerator_`i' = `num'
        return local var_`i' "`x'"
    }
    if `i'==0 {
        di as error "ARDL has no independent regressor groups."
        exit 498
    }
    di as text "Diagnostic only: no cointegration, stability, bounds test or causal validity is established."
    di as text "For a native ardl, CS-ARDL or RCSARDL estimate use its model-specific interpretation instead."
    return scalar K=`i'
    return scalar denominator=`den'
    return scalar rho_sum=`rho'
    return local model "regress_ardl"
end

*! xtxai_lagindex 0.20.0 - conditional linear index of explicitly named lag terms
* DOES NOT transform short-run coefficients into long-run multipliers.
capture program drop xtxai_lagindex
program define xtxai_lagindex, rclass
    version 17.0
    syntax [, PREFIX(name) REPLACE GRAPH(string)]
    if !inlist("`e(cmd)'", "regress", "ardl") {
        di as error "xtxai_lagindex requires preceding regress or ardl"
        exit 301
    }
    if !inlist("`graph'", "", "global") {
        di as error "lagged index supports graph(global) only"
        exit 198
    }
    if "`prefix'" == "" local prefix "xai_lag_"
    tempname B
    matrix `B'=e(b)
    local terms : colnames `B'
    local K=colsof(`B')
    tempvar sample calc index err
    quietly gen byte `sample'=e(sample)
    quietly gen double `calc'=0 if `sample'
    local kvalid=0
    local kskip=0
    local names ""
    forvalues j=1/`K' {
        local term : word `j' of `terms'
        local bj=el(`B',1,`j')
        if "`term'"=="_cons" {
            quietly replace `calc'=`calc'+`bj' if `sample'
            continue
        }
        if missing(`bj') {
            di as error "Missing coefficient on `term'"
            exit 459
        }
        * Factor variables, omitted terms and equation-qualified names need separate adapters.
        if strpos("`term'","#") | strpos("`term'",":") | strpos("`term'","bn.") | strpos("`term'","o.") {
            di as error "Unsupported factor/omitted/equation term: `term'. Cannot assert reconstruction."
            exit 498
        }
        local expr "`term'"
        * Confirm Stata can evaluate the actual time-series expression on this panel.
        tempvar value
        capture quietly gen double `value' = `expr' if `sample'
        if _rc {
            di as error "Cannot evaluate coefficient term `term' as data. This model needs a specific adapter."
            exit 498
        }
        quietly count if `sample' & missing(`value')
        if r(N)>0 {
            di as error "Missing regressor term `term' on estimation sample: " r(N)
            exit 459
        }
        local ++kvalid
        local names "`names' `term'"
        local target "`prefix'c`kvalid'"
        capture confirm new variable `target'
        if _rc & "`replace'"=="" {
            di as error "Variable `target' exists; specify replace"
            exit 110
        }
        if "`replace'"!="" capture drop `target'
        quietly gen double `target' = `bj'*`value' if `sample'
        label var `target' "Contribution: `term'"
        quietly replace `calc'=`calc'+`target' if `sample'
    }
    * Compare with native fitted linear index if its postestimation API supports xb.
    capture quietly predict double `index' if `sample', xb
    if _rc {
        di as error "Native predict, xb unavailable; no independent numerical audit."
        exit 498
    }
    quietly count if `sample' & !missing(`index',`calc')
    local n=r(N)
    if `n'==0 {
        di as error "No usable observations"
        exit 2000
    }
    quietly gen double `err'=abs(`index'-`calc') if `sample'
    quietly summarize `err', meanonly
    local maxerr=r(max)
    di as text "XTXAI dynamic lag linear-index audit | e(cmd)=`e(cmd)' N=" as result `n'
    di as text "Contributions: `kvalid' | reconstruction maximum error = " as result %12.4e `maxerr'
    if `maxerr'>1e-7 {
        di as error "Native predictor mismatch: omitted model structure or unsupported terms."
        exit 459
    }
    di as text "Contributions explain the fitted LINEAR INDEX, not long-run multipliers or causal effects."
    if "`graph'"=="global" & `kvalid'>0 {
        preserve
        capture noisily {
            keep if `sample'
            collapse (mean) `prefix'c1-`prefix'c`kvalid'
            graph bar (asis) `prefix'c1-`prefix'c`kvalid', title("Mean signed lag-term contributions")
        }
        restore
    }
    return scalar N=`n'
    return scalar maxerror=`maxerr'
    return scalar K=`kvalid'
    return local backend "lagged_linear"
end
* ===== END XTXAI lagged-linear contribution adapter =====


* ===== BEGIN asymmetric ARDL multiplier and delta-method symmetry audit =====
*! xtxai_asym_lr 0.22.0 - user-supplied positive / negative cumulative-change regressors
* Econometric restriction: coefficients for positive / negative groups must be
* based on precomputed partial sums, with no omitted interactions or omitted terms.
* Reports LR multipliers and a delta-method Wald test of their equality.
capture program drop xtxai_asym_lr
program define xtxai_asym_lr, rclass
    version 17.0
    syntax , POSitive(name) NEGative(name)
    if "`e(cmd)'" != "regress" {
        di as error "Asymmetric LR currently requires a preceding regress specification."
        exit 301
    }
    if "`positive'" == "`negative'" {
        di as error "positive() and negative() must differ"
        exit 198
    }
    confirm variable `positive'
    confirm variable `negative'
    local dep "`e(depvar)'"
    tempname B V G diffvar
    matrix `B'=e(b)
    matrix `V'=e(V)
    local terms : colnames `B'
    local K=colsof(`B')
    if rowsof(`V')!=`K' | colsof(`V')!=`K' {
        di as error "e(V) does not match coefficient vector"
        exit 498
    }
    matrix `G'=J(1,`K',0)
    local rho=0
    local bp=0
    local bn=0
    local nr=0
    local np=0
    local nn=0
    forvalues j=1/`K' {
        local t : word `j' of `terms'
        local c=el(`B',1,`j')
        if "`t'"=="_cons" continue
        if missing(`c') | strpos("`t'","#") | strpos("`t'",":") | strpos("`t'","o.") | strpos("`t'","bn.") {
            di as error "Unsupported or omitted coefficient `t'"
            exit 498
        }
        local stem "`t'"
        if strpos("`t'",".") {
            local k=strpos("`t'",".")
            local op=substr("`t'",1,`k'-1)
            local stem=substr("`t'",`k'+1,.)
            if substr("`op'",1,1)!="L" {
                di as error "Only level and lagged-level regressors are supported: `t'"
                exit 498
            }
            local steps=substr("`op'",2,.)
            if "`steps'"!="" {
                capture confirm number `steps'
                if _rc {
                    di as error "Bad lag operator: `t'"
                    exit 498
                }
                if real("`steps'")<1 | floor(real("`steps'"))!=real("`steps'") exit 498
            }
        }
        capture confirm variable `stem'
        if _rc exit 111
        if "`stem'"=="`dep'" {
            if "`t'"=="`dep'" exit 498
            local rho=`rho'+`c'
            local ++nr
        }
        if "`stem'"=="`positive'" {
            local bp=`bp'+`c'
            local ++np
        }
        if "`stem'"=="`negative'" {
            local bn=`bn'+`c'
            local ++nn
        }
    }
    if `nr'==0 | `np'==0 | `nn'==0 {
        di as error "Need lagged dependent variable and both positive/negative level or lag terms."
        exit 498
    }
    local den=1-`rho'
    if abs(`den')<1e-8 {
        di as error "Long-run multiplier denominator nearly zero"
        exit 459
    }
    local diff=(`bp'-`bn')/`den'
    * d((bp-bn)/den)/d(beta_j): +1/den for positive, -1/den for
    * negative, +(bp-bn)/den^2 for lagged dependent variable.
    forvalues j=1/`K' {
        local t : word `j' of `terms'
        local stem "`t'"
        if strpos("`t'",".") {
            local k=strpos("`t'",".")
            local stem=substr("`t'",`k'+1,.)
        }
        if "`stem'"=="`positive'" matrix `G'[1,`j']=1/`den'
        if "`stem'"=="`negative'" matrix `G'[1,`j']=-1/`den'
        if "`stem'"=="`dep'" & "`t'"!="`dep'" matrix `G'[1,`j']=(`bp'-`bn')/(`den'^2)
    }
    matrix `diffvar'=`G'*`V'*`G''
    local var=el(`diffvar',1,1)
    if missing(`var') | `var'<0 {
        di as error "Delta-method variance unavailable; cannot test symmetry"
        exit 459
    }
    local se=sqrt(`var')
    local chi2=.
    local p=.
    if `se'>0 {
        local chi2=(`diff'/`se')^2
        local p=chi2tail(1,`chi2')
    }
    di as text "XTXAI asymmetric long-run multiplier audit | regress-based partial sums"
    di as text "Positive partial sum `positive': LR = " as result %12.6g (`bp'/`den')
    di as text "Negative partial sum `negative': LR = " as result %12.6g (`bn'/`den')
    di as text "Difference positive - negative: " as result %12.6g `diff'
    di as text "Delta-method SE of difference:  " as result %12.6g `se'
    di as text "Wald chi2(1) for LR symmetry: " as result %12.6g `chi2' as text " ; p=" as result %9.6f `p'
    di as text "Inference conditional on preceding regression covariance and correct partial sums."
    di as text "NOT a full nonlinear dynamic multiplier path or cointegration diagnostic."
    return scalar lr_positive=`bp'/`den'
    return scalar lr_negative=`bn'/`den'
    return scalar difference=`diff'
    return scalar se_difference=`se'
    return scalar chi2=`chi2'
    return scalar p=`p'
    return scalar denominator=`den'
    return local backend "asymmetric_ardl_delta"
end
* ===== END asymmetric ARDL multiplier audit =====

*! xtxai_multiplier_path 0.23.0 - permanent one-unit level shock response from regress-based ARDL
*! Computes m(h)=sum_i phi_i*m(h-i)+sum_{j=0}^{min(h,q)} beta_j, m(-i)=0.
*! Does not estimate a model, check cointegration, or calculate bootstrap intervals.
capture program drop xtxai_multiplier_path
program define xtxai_multiplier_path, rclass
    version 17.0
    syntax , POSitive(name) [NEGative(name) HORIZON(integer 20)]
    if "`e(cmd)'" != "regress" {
        di as error "Requires preceding regress with explicit lagged-level terms."
        exit 301
    }
    if `horizon'<1 | `horizon'>300 exit 198
    confirm variable `positive'
    if "`negative'"!="" {
        confirm variable `negative'
        if "`negative'"=="`positive'" exit 198
    }
    local dep "`e(depvar)'"
    tempname B M P N
    matrix `B'=e(b)
    local names : colnames `B'
    local K=colsof(`B')
    local maxlag=0
    local ny=0
    local nx=0
    local nn=0
    local rho=0
    local bp=0
    local bn=0
    forvalues j=1/`K' {
        local term : word `j' of `names'
        local cf=el(`B',1,`j')
        if "`term'"=="_cons" continue
        if missing(`cf') | strpos("`term'","#") | strpos("`term'",":") {
            di as err "Nonlinear/omitted terms are unsupported: `term'"
            exit 498
        }
        local stem "`term'"
        local lag=0
        if strpos("`term'",".") {
            local dot=strpos("`term'",".")
            local op=substr("`term'",1,`dot'-1)
            local stem=substr("`term'",`dot'+1,.)
            if substr("`op'",1,1)!="L" {
                di as err "Only level and L. lag terms supported: `term'"
                exit 498
            }
            local lagtxt=substr("`op'",2,.)
            if "`lagtxt'"!="" {
                capture confirm integer number `lagtxt'
                if _rc exit 498
                local lag=real("`lagtxt'")
            }
            else local lag=1
            if `lag'<1 | `lag'>300 exit 498
        }
        if "`stem'"=="`dep'" {
            if `lag'==0 exit 498
            if "`phi`lag''"=="" local phi`lag'=0
            local phi`lag'=`phi`lag''+`cf'
            local rho=`rho'+`cf'
            local ny=`ny'+1
            if `lag'>`maxlag' local maxlag=`lag'
        }
        else if "`stem'"=="`positive'" {
            
            local bp=`bp'+`cf'
            local nx=`nx'+1
        }
        else if "`negative'"!="" & "`stem'"=="`negative'" {
            
            local bn=`bn'+`cf'
            local nn=`nn'+1
        }
    }
    if `ny'==0 | `nx'==0 | ("`negative'"!="" & `nn'==0) {
        di as error "Need lagged dependent variable and selected input coefficients."
        exit 498
    }
    local den=1-`rho'
    if abs(`den')<1e-8 {
        di as error "Undefined long-run response: denominator near zero"
        exit 459
    }
    matrix `M'=J(`horizon'+1,3,.)
    matrix colnames `M'=horizon positive negative
    forvalues h=0/`horizon' {
        local pp=0
        local np=0
        forvalues j=1/`K' {
            local term : word `j' of `names'
            if "`term'"=="_cons" continue
            local stem "`term'"
            local lag=0
            if strpos("`term'",".") {
                local dot=strpos("`term'",".")
                local stem=substr("`term'",`dot'+1,.)
                local op=substr("`term'",1,`dot'-1)
                local lagtxt=substr("`op'",2,.)
                if "`lagtxt'"=="" local lag=1
                else local lag=real("`lagtxt'")
            }
            if `lag'<=`h' & "`stem'"=="`positive'" local pp=`pp'+el(`B',1,`j')
            if `lag'<=`h' & "`negative'"!="" & "`stem'"=="`negative'" local np=`np'+el(`B',1,`j')
        }
        if `h'>0 {
            forvalues k=1/`maxlag' {
                if `k'<=`h' {
                    local pcoef=0
                    if "`phi`k''"!="" local pcoef=`phi`k''
                    local pp=`pp'+`pcoef'*el(`M',`h'-`k'+1,2)
                    local np=`np'+`pcoef'*el(`M',`h'-`k'+1,3)
                }
            }
        }
        matrix `M'[`h'+1,1]=`h'
        matrix `M'[`h'+1,2]=`pp'
        if "`negative'"!="" matrix `M'[`h'+1,3]=`np'
    }
    di as text "XTXAI permanent level-shock dynamic multiplier path | horizon 0..`horizon'"
    di as text "Selected positive input: `positive' ; theoretical LR=" as result %12.7g (`bp'/`den')
    di as text "  horizon 0: " as result %12.7g el(`M',1,2) as text " ; horizon `horizon': " as result %12.7g el(`M',`horizon'+1,2)
    if "`negative'"!="" {
        di as text "Selected negative input: `negative' ; theoretical LR=" as result %12.7g (`bn'/`den')
        di as text "  horizon 0: " as result %12.7g el(`M',1,3) as text " ; horizon `horizon': " as result %12.7g el(`M',`horizon'+1,3)
    }
    di as text "Conditional on specified ARDL and permanent unit shift in each selected level input."
    di as text "No stability, bounds, cointegration, or causal-effect validation."
    return matrix path=`M'
    return scalar horizon=`horizon'
    return scalar lr_positive=`bp'/`den'
    return scalar lr_negative=cond("`negative'"!="",`bn'/`den',.)
    return scalar denominator=`den'
    return local backend "regress_ardl_step_response"
end

* ===== BEGIN xtxai_threshold.ado =====
*! xtxai_threshold 0.24.0 - binary regime interaction slope/contribution after regress
capture program drop xtxai_threshold
program define xtxai_threshold, rclass
    version 17.0
    syntax , REGIME(name) EFFECT(name) [REPLACE]
    if "`e(cmd)'" != "regress" {
        di as error "Threshold/regime adapter requires preceding regress with i.regime##c.effect"
        exit 301
    }
    capture confirm numeric variable `regime'
    if _rc exit 111
    capture confirm numeric variable `effect'
    if _rc exit 111
    tempvar touse
    quietly generate byte `touse' = e(sample)
    quietly count if `touse' & !inlist(`regime',0,1)
    if r(N) > 0 {
        di as error "regime() must be 0/1 on the estimation sample"
        exit 459
    }
    quietly count if `touse' & `regime'==0
    if r(N)==0 {
        di as error "no observations in regime 0"
        exit 459
    }
    quietly count if `touse' & `regime'==1
    if r(N)==0 {
        di as error "no observations in regime 1"
        exit 459
    }
    tempname B V b0 db b1 sd se0 se1 vv z p
    matrix `B' = e(b)
    matrix `V' = e(V)
    local colnames : colnames `B'
    local main ""
    foreach candidate in "`effect'" "c.`effect'" {
        local k = colnumb(`B',"`candidate'")
        if !missing(`k') & `k'>0 & `k'<=colsof(`B') local main "`candidate'"
    }
    local interaction ""
    foreach candidate in "1.`regime'#c.`effect'" "c.`effect'#1.`regime'" {
        local k = colnumb(`B',"`candidate'")
        if !missing(`k') & `k'>0 & `k'<=colsof(`B') local interaction "`candidate'"
    }
    if "`main'" == "" | "`interaction'" == "" {
        di as error "required factor-variable terms not found in e(b). Use regress y i.`regime'##c.`effect' [controls]"
        exit 498
    }
    local km = colnumb(`B',"`main'")
    local ki = colnumb(`B',"`interaction'")
    scalar `b0' = el(`B',1,`km')
    scalar `db' = el(`B',1,`ki')
    scalar `b1' = `b0'+`db'
    scalar `se0' = sqrt(max(0,el(`V',`km',`km')))
    scalar `se1' = sqrt(max(0,el(`V',`km',`km')+el(`V',`ki',`ki')+2*el(`V',`km',`ki')))
    scalar `sd' = sqrt(max(0,el(`V',`ki',`ki')))
    if `sd'>0 scalar `z' = `db'/`sd'
    else scalar `z' = .
    if !missing(`z') scalar `p' = 2*normal(-abs(`z'))
    else scalar `p' = .
    if "`replace'" != "" {
        capture drop xai_regime_slope xai_regime_contribution
    }
    capture confirm new variable xai_regime_slope
    if _rc {
        di as error "xai_regime_slope already exists; specify replace"
        exit 110
    }
    capture confirm new variable xai_regime_contribution
    if _rc {
        di as error "xai_regime_contribution already exists; specify replace"
        exit 110
    }
    quietly generate double xai_regime_slope = `b0'+`db'*`regime' if `touse'
    quietly generate double xai_regime_contribution = `effect'*xai_regime_slope if `touse'
    quietly count if `touse'
    local N = r(N)
    di as text "XTXAI binary regime slope / contribution | N=" as result `N'
    di as text "Regime 0 slope: " as result %12.7f `b0' as text " (SE " as result %10.6f `se0' as text ")"
    di as text "Regime 1 slope: " as result %12.7f `b1' as text " (SE " as result %10.6f `se1' as text ")"
    di as text "Difference: " as result %12.7f `db' as text " (SE " as result %10.6f `sd' as text ", normal reference p=" as result %9.6f `p' as text ")"
    di as text "Generated xai_regime_slope and xai_regime_contribution."
    di as text "Only the selected regressor contribution is decomposed; not the entire fitted index."
    di as text "No threshold location search, no Hansen test, no causal interpretation."
    return scalar slope0=`b0'
    return scalar slope1=`b1'
    return scalar difference=`db'
    return scalar se_difference=`sd'
    return scalar p_normal=`p'
    return scalar N=`N'
    return local backend "binary_regime_regress"
end
* ===== END xtxai_threshold.ado =====


* ===== BEGIN explicit heterogeneous panel coefficient adapter =====
*! xtxai_panelhetero 0.25.0 - strict matrix-to-panel matching; no estimator autodetection
capture program drop xtxai_panelhetero
program define xtxai_panelhetero, rclass
    version 17.0
    syntax, ID(varname numeric) VARS(varlist numeric) COEFMATRIX(name) [PREFIX(name) REPLACE WITHIN]
    if "`prefix'" == "" local prefix "xai_hetero"
    capture confirm matrix `coefmatrix'
    if _rc {
        di as error "coefmatrix(`coefmatrix') is not an existing Stata matrix"
        exit 111
    }
    tempname B
    matrix `B' = `coefmatrix'
    local k : word count `vars'
    local cols = colsof(`B')
    local rows = rowsof(`B')
    if `cols' != `k' + 1 & `cols' != `k' + 2 {
        di as error "coefficient matrix must have [id, K slopes] or [id, K slopes, _cons] in exactly vars() order"
        exit 503
    }
    if `rows' < 1 {
        di as error "coefficient matrix contains no panels"
        exit 503
    }
    local hascons = (`cols' == `k' + 2)
    foreach suffix in xb baseline {
        local nm `prefix'_`suffix'
        capture confirm variable `nm'
        if !_rc & "`replace'" == "" {
            di as error "`nm' exists; specify replace"
            exit 110
        }
    }
    local i=0
    foreach v of local vars {
        local ++i
        local nm `prefix'_c`i'
        capture confirm variable `nm'
        if !_rc & "`replace'" == "" {
            di as error "`nm' exists; specify replace"
            exit 110
        }
    }
    * Protect active sample: exclude missing predictors and identifiers.
    tempvar eligible matched count xbcheck
    quietly gen byte `eligible' = !missing(`id')
    foreach v of local vars {
        quietly replace `eligible' = 0 if missing(`v')
    }
    quietly gen byte `matched' = 0
    forvalues j=1/`k' {
        capture drop `prefix'_c`j'
        quietly gen double `prefix'_c`j' = .
    }
    capture drop `prefix'_baseline
    capture drop `prefix'_xb
    quietly gen double `prefix'_baseline = .
    quietly gen double `prefix'_xb = .
    * Each row is an observed numeric panel id followed by ordered slopes.
    * Duplicate panel ids are disallowed; unmatched observations remain missing.
    forvalues r=1/`rows' {
        local pid = el(`B',`r',1)
        if missing(`pid') {
            di as error "missing panel ID in coefficient matrix row `r'"
            exit 503
        }
        if `r' > 1 {
            forvalues previous=1/`=`r'-1' {
                if `pid' == el(`B',`previous',1) {
                    di as error "duplicate panel ID `pid' in coefficient matrix"
                    exit 503
                }
            }
        }
        quietly count if `eligible' & `id'==`pid'
        if r(N)==0 {
            di as error "matrix panel ID `pid' has no eligible observations: refusing silent mismatch"
            exit 459
        }
        quietly replace `matched' = 1 if `eligible' & `id'==`pid'
        local j=0
        foreach v of local vars {
            local ++j
            local b = el(`B',`r',`=`j'+1')
            if missing(`b') {
                di as error "missing slope in coefficient matrix row `r', regressor `v'"
                exit 503
            }
            quietly replace `prefix'_c`j' = `b'*`v' if `eligible' & `id'==`pid'
        }
        local intercept = 0
        if `hascons' local intercept = el(`B',`r',`cols')
        if missing(`intercept') {
            di as error "missing intercept in coefficient matrix row `r'"
            exit 503
        }
        quietly replace `prefix'_baseline = `intercept' if `eligible' & `id'==`pid'
    }
    quietly count if `eligible' & !`matched'
    if r(N)>0 {
        di as error "`=r(N)' eligible observations lack panel coefficients; check coefmatrix()"
        exit 459
    }
    quietly replace `prefix'_xb = `prefix'_baseline if `matched'
    forvalues j=1/`k' {
        quietly replace `prefix'_xb = `prefix'_xb + `prefix'_c`j' if `matched'
    }
    quietly count if `matched'
    local N = r(N)
    if "`within'" != "" {
        foreach suffix in within_base within_xb within_error {
            capture confirm variable `prefix'_`suffix'
            if !_rc & "`replace'" == "" {
                di as error "`prefix'_`suffix' exists; specify replace"
                exit 110
            }
        }
        forvalues j=1/`k' {
            capture confirm variable `prefix'_within_c`j'
            if !_rc & "`replace'" == "" {
                di as error "`prefix'_within_c`j' exists; specify replace"
                exit 110
            }
        }
        tempvar nobs
        bysort `id': egen long `nobs' = total(`matched')
        capture drop `prefix'_within_base
        capture drop `prefix'_within_xb
        capture drop `prefix'_within_error
        quietly gen double `prefix'_within_base = `prefix'_baseline if `matched'
        local j=0
        foreach v of local vars {
            local ++j
            tempvar sm
            bysort `id': egen double `sm' = total(cond(`matched', `v', 0))
            capture drop `prefix'_within_c`j'
            quietly gen double `prefix'_within_c`j' = .
            forvalues r=1/`rows' {
                local pid = el(`B',`r',1)
                local b = el(`B',`r',`=`j'+1')
                quietly replace `prefix'_within_c`j' = `b'*(`v'-`sm'/`nobs') if `matched' & `id'==`pid'
                quietly replace `prefix'_within_base = `prefix'_within_base + `b'*(`sm'/`nobs') if `matched' & `id'==`pid'
            }
        }
        quietly gen double `prefix'_within_xb = `prefix'_within_base if `matched'
        forvalues j=1/`k' {
            quietly replace `prefix'_within_xb = `prefix'_within_xb + `prefix'_within_c`j' if `matched'
        }
        quietly gen double `prefix'_within_error = abs(`prefix'_xb-`prefix'_within_xb) if `matched'
        quietly summarize `prefix'_within_error if `matched', meanonly
        local err = r(max)
        if missing(`err') | `err'>1e-8 {
            di as error "within-panel reference reconstruction error exceeded 1e-8"
            exit 459
        }
        di as result "Within-panel centered decomposition: max error " %12.4e `err'
        di as text "Centered contributions reconstruct supplied-coefficient xb; not SCC/AMG or conditional SHAP."
        return scalar maxerror = `err'
        return local reference "within_panel_means"
    }
    di as result "XTXAI heterogeneous matrix contribution engine | panels=`rows' N=`N' regressors=`k'"
    di as text "`prefix'_xb = `prefix'_baseline + sum(`prefix'_c#) by observation."
    di as text "This is an exact decomposition of supplied coefficients, NOT a comparison with SCC/AMG predictions."
    di as text "No common-dynamic factor, uncertainty, SHAP or causal effects attributed."
    return scalar N = `N'
    return scalar G = `rows'
    return scalar K = `k'
    return local backend "explicit_panel_coefficients"
end
* ===== END explicit heterogeneous panel coefficient adapter =====


* ===== BEGIN guarded RCSARDL observation-level adjustment adapter =====
*! xtxai_rcsardl_ect 0.26.0 - phi_i * supplied equilibrium error, NOT SHAP
capture program drop xtxai_rcsardl_ect
program define xtxai_rcsardl_ect, rclass
    version 17.0
    syntax, ID(varname numeric) ECTVAR(varname numeric) [ECTLAG(integer 1) PREFIX(name) REPLACE]
    if "`e(cmd)'" != "rcsardl" {
        di as error "estimate rcsardl before requesting stored unit adjustment coefficients"
        exit 301
    }
    if !inlist(`ectlag',0,1) {
        di as error "ectlag() must equal 0 (already lagged ECT) or 1 (lag supplied level ECT)"
        exit 198
    }
    if "`prefix'" == "" local prefix "xai_rcs"
    tempname U
    capture matrix `U'=e(unit_adjustment)
    if _rc {
        di as error "RCSARDL stored e(unit_adjustment) is unavailable"
        exit 498
    }
    local ucols : colnames `U'
    if colsof(`U') != 3 | "`ucols'" != "panel_id phi_robust huber_weight" {
        di as error "RCSARDL e(unit_adjustment) column contract mismatch"
        exit 503
    }
    if colsof(`U') < 3 | rowsof(`U') < 1 {
        di as error "e(unit_adjustment) requires [numeric panel ID, phi_i, weight_i] columns"
        exit 503
    }
    * Verify column names when present (matrix contract documented by RCSARDL).
    * Never convert unnamed/ambiguous higher-order columns into coefficients.
    local G=rowsof(`U')
    foreach suff in phi weight ect contribution weighted {
        capture confirm variable `prefix'_`suff'
        if !_rc & "`replace'" == "" {
            di as error "`prefix'_`suff' exists; specify replace"
            exit 110
        }
    }
    if `ectlag'==1 {
        capture quietly tsset
        if _rc {
            di as error "xtset/tsset the panel before ectlag(1)"
            exit 459
        }
    }
    tempvar usable matched errused
    quietly gen byte `usable' = !missing(`id',`ectvar')
    capture drop `prefix'_phi `prefix'_weight `prefix'_ect `prefix'_contribution `prefix'_weighted
    quietly gen double `prefix'_phi = .
    quietly gen double `prefix'_weight = .
    quietly gen double `prefix'_ect = .
    if `ectlag'==1 quietly replace `prefix'_ect=L.`ectvar' if !missing(`id')
    else quietly replace `prefix'_ect=`ectvar' if !missing(`id')
    quietly replace `usable'=0 if missing(`prefix'_ect)
    quietly gen byte `matched'=0
    forvalues r=1/`G' {
        local pid=el(`U',`r',1)
        local phi=el(`U',`r',2)
        local weight=el(`U',`r',3)
        if missing(`pid',`phi',`weight') | `weight'<0 {
            di as error "invalid panel ID, phi or weight in stored unit adjustment row `r'"
            exit 503
        }
        if `r'>1 {
            forvalues j=1/`=`r'-1' {
                if `pid'==el(`U',`j',1) {
                    di as error "duplicate panel ID in unit adjustment matrix"
                    exit 503
                }
            }
        }
        quietly count if `usable' & `id'==`pid'
        if r(N)==0 {
            di as error "unit ID `pid' has no usable equilibrium errors; check id()/ectvar()"
            exit 459
        }
        quietly replace `prefix'_phi=`phi' if `usable' & `id'==`pid'
        quietly replace `prefix'_weight=`weight' if `usable' & `id'==`pid'
        quietly replace `matched'=1 if `usable' & `id'==`pid'
    }
    quietly count if `usable' & !`matched'
    local excluded_obs = r(N)
    if `excluded_obs'>0 {
        di as text "RCSARDL: `excluded_obs' usable observations in excluded/unmatched units; contribution remains missing (NOT zero)."
    }
    quietly gen double `prefix'_contribution = `prefix'_phi*`prefix'_ect if `matched'
    quietly gen double `prefix'_weighted = `prefix'_weight*`prefix'_contribution if `matched'
    quietly count if `matched'
    local N=r(N)
    di as result "XTXAI RCSARDL unit adjustment contribution | G=`G' N=`N'"
    di as text "`prefix'_contribution = phi_i * ECT(i,t-`ectlag')"
    di as text "`prefix'_weighted = Huber weight_i * that contribution (NOT aggregate RCS adjustment)."
    di as text "ECT supplied by user; not validated against estimated cointegrating relation."
    di as text "Does NOT explain short-run regressors, common factors, uncertainty, or SHAP."
    return scalar N=`N'
    return scalar G=`G'
    return scalar excluded_obs=`excluded_obs'
    return local backend "rcsardl_ect_supplied"
end
* ===== END guarded RCSARDL observation-level adjustment adapter =====

* ===== BEGIN RCSARDL ECT from strictly named e(longrun) =====
*! xtxai_rcsardl_autoect 0.27.0 - reconstruct residual conditional on e(longrun)
capture program drop xtxai_rcsardl_autoect
program define xtxai_rcsardl_autoect, rclass
    version 17.0
    syntax, ID(varname numeric) DEPVAR(varname numeric) LRVARS(varlist numeric) [ECTLAG(integer 1) PREFIX(name) REPLACE]
    if "`e(cmd)'" != "rcsardl" {
        di as error "estimate rcsardl first"
        exit 301
    }
    if !inlist(`ectlag',0,1) {
        di as error "ectlag() must be 0 or 1"
        exit 198
    }
    if "`prefix'" == "" local prefix "xai_rcs"
    tempname LR
    capture matrix `LR' = e(longrun)
    if _rc {
        di as error "e(longrun) is required for automatic ECT"
        exit 498
    }
    if rowsof(`LR') != 1 {
        di as error "e(longrun) must be a named 1-row coefficient vector"
        exit 503
    }
    local cols : colnames `LR'
    local n_lr : word count `lrvars'
    local n_cols = colsof(`LR')
    if !inlist(`n_cols',`n_lr',`n_lr'+1) {
        di as error "long-run coefficient count does not match lrvars() (+ optional _cons)"
        exit 503
    }
    * Exact-name mapping only. Never assume coefficient order or rename inputs.
    local constant = 0
    foreach v of local lrvars {
        local hits = 0
        foreach nm of local cols {
            if "`nm'" == "`v'" local hits = `hits'+1
        }
        if `hits' != 1 {
            di as error "e(longrun): expected exactly one coefficient named `v'"
            exit 503
        }
    }
    foreach nm of local cols {
        if "`nm'" == "_cons" {
            local constant = `constant'+1
        }
        else {
            local valid = 0
            foreach v of local lrvars {
                if "`nm'" == "`v'" local valid = 1
            }
            if !`valid' {
                di as error "unknown long-run coefficient `nm'; supply matching lrvars()"
                exit 503
            }
        }
    }
    if `constant' > 1 {
        di as error "duplicate long-run intercept"
        exit 503
    }
    if `constant' == 1 {
        local cpos = colnumb(`LR', "_cons")
        local c = el(`LR',1,`cpos')
        if missing(`c') exit 503
    }
    else local c = 0
    tempvar eqerr
    quietly generate double `eqerr' = `depvar' - (`c')
    foreach v of local lrvars {
        local pos = colnumb(`LR',"`v'")
        local b = el(`LR',1,`pos')
        if missing(`b') {
            di as error "missing long-run coefficient for `v'"
            exit 503
        }
        quietly replace `eqerr' = `eqerr' - (`b')*`v'
    }
    local opts "id(`id') ectvar(`eqerr') ectlag(`ectlag') prefix(`prefix')"
    if "`replace'" != "" local opts "`opts' replace"
    xtxai_rcsardl_ect, `opts'
    return add
    return local backend "rcsardl_named_longrun_ect"
    di as text "ECT = depvar - [optional _cons + sum(e(longrun)[x]*x)], exact name matching."
    di as text "NOT validated against RCSARDL internals or an estimated cointegration convention."
end
* ===== END RCSARDL ECT from strictly named e(longrun) =====

* ===== BEGIN real RCSARDL e() metadata-based ECT =====
*! xtxai_rcsardl_realect 0.29.0 - read e(depvar)/e(indepvars)/e(panelvar)/e(timevar)
capture program drop xtxai_rcsardl_realect
program define xtxai_rcsardl_realect, rclass
    version 17.0
    syntax, [ECTLAG(integer 1) PREFIX(name) REPLACE]
    if "`e(cmd)'" != "rcsardl" {
        di as error "estimate actual rcsardl before model(rcsardl) explain(ect)"
        exit 301
    }
    local y "`e(depvar)'"
    local x "`e(indepvars)'"
    local id "`e(panelvar)'"
    local tm "`e(timevar)'"
    if "`y'"=="" | "`x'"=="" | "`id'"=="" | "`tm'"=="" {
        di as error "RCSARDL stored metadata incomplete: need depvar, indepvars, panelvar, timevar"
        exit 503
    }
    confirm numeric variable `y'
    confirm numeric variable `id'
    confirm numeric variable `tm'
    confirm numeric variable `x'
    capture quietly xtset
    if _rc {
        di as error "xtset the panel with `id' and `tm' before explanation"
        exit 459
    }
    if "`r(panelvar)'" != "`id'" | "`r(timevar)'" != "`tm'" {
        di as error "xtset panel/time do not match actual RCSARDL e(panelvar)/e(timevar)"
        exit 459
    }
    local opts "id(`id') depvar(`y') lrvars(`x') ectlag(`ectlag')"
    if "`prefix'" != "" local opts "`opts' prefix(`prefix')"
    if "`replace'" != "" local opts "`opts' replace"
    xtxai_rcsardl_autoect, `opts'
    return add
    return local backend "rcsardl_real_metadata_ect"
    di as result "RCSARDL real stored-result metadata route: depvar=`y'; indepvars=`x'; panel=`id'; time=`tm'"
    di as text "NOTE: e(longrun) has no constant in the observed Grunfeld fit."
    di as text "ECT normalization must still be compared with Frozen-V3 internal implementation."
end
* ===== END real RCSARDL e() metadata-based ECT =====

* ===== BEGIN inspect actual stored estimator results for missing interfaces =====
*! xtxai_contract_audit 0.28.0 - read-only evidence for RCSARDL/SCC/AMG/xtdcce2 adapters
capture program drop xtxai_contract_audit
program define xtxai_contract_audit, rclass
    version 17.0
    syntax, MODEL(string)
    local cmd "`e(cmd)'"
    if "`cmd'" == "" {
        di as err "estimate the target model before explain(audit)"
        exit 301
    }
    local m=lower("`model'")
    if "`m'"=="rcsardl" & "`cmd'"!="rcsardl" {
        di as err "model(rcsardl): preceding e(cmd) must be rcsardl, found `cmd'"
        exit 301
    }
    if "`m'"=="scc" & "`cmd'"!="scc" {
        di as err "model(scc): preceding e(cmd) must be scc, found `cmd'"
        exit 301
    }
    if "`m'"=="amg" & !inlist("`cmd'","xtmg","amg") {
        di as err "model(amg): preceding e(cmd) must be xtmg or amg, found `cmd'"
        exit 301
    }
    if inlist("`m'","csardl","csdl","pmg") & !inlist("`cmd'","xtdcce2","xtpmg") {
        di as err "long-run audit requires xtdcce2 or xtpmg, found `cmd'"
        exit 301
    }
    di as text _n "XTXAI estimator contract audit (READ ONLY)"
    di as text "Requested model: " as res "`m'" as text " | e(cmd): " as res "`cmd'"
    di as text "e(cmdline): " as res `"`e(cmdline)'"'
    di as text "e(depvar): " as res "`e(depvar)'"
    di as text "e(N): " as res %12.0f e(N)
    capture noisily ereturn list
    local found=0
    foreach nm in b V longrun unit_adjustment bi lr csa unit_coefficients coefficients alpha phi weight {
        tempname M
        capture matrix `M'=e(`nm')
        if !_rc {
            local found=`found'+1
            di as text _n "e(`nm'): " as res rowsof(`M') " rows x " colsof(`M') " columns"
            local cn : colfullnames `M'
            local rn : rownames `M'
            di as text "  column names: " as res `"`cn'"'
            di as text "  row names:    " as res `"`rn'"'
            if inlist("`nm'","longrun","unit_adjustment","lr") & rowsof(`M')<=25 & colsof(`M')<=15 {
                matlist `M', format(%11.6g)
            }
        }
    }
    di as text _n "This audit does not assert SCC/AMG/PMG compatibility or ECT normalization."
    di as text "Do not interpret printed matrices as validated contribution inputs."
    return local model "`m'"
    return local estimator "`cmd'"
    return scalar matrices_found=`found'
end
* ===== END estimator contract audit =====

* ===== BEGIN actual RCSARDL Huber aggregate audit =====
*! xtxai_rcsardl_aggregation 0.30.0 - actual e(unit_adjustment) -> e(ect_rcs) consistency
capture program drop xtxai_rcsardl_aggregation
program define xtxai_rcsardl_aggregation, rclass
    version 17.0
    syntax
    if "`e(cmd)'" != "rcsardl" {
        di as error "estimate rcsardl before explain(aggregation)"
        exit 301
    }
    tempname U
    capture matrix `U'=e(unit_adjustment)
    if _rc {
        di as error "RCSARDL does not expose e(unit_adjustment)"
        exit 498
    }
    local cols : colnames `U'
    if colsof(`U') != 3 | "`cols'" != "panel_id phi_robust huber_weight" {
        di as error "unexpected e(unit_adjustment) columns; no positional assumptions allowed"
        exit 503
    }
    local G=rowsof(`U')
    if `G' < 1 exit 503
    local sw=0
    local swphi=0
    local ndown=0
    forvalues i=1/`G' {
        local pid=el(`U',`i',1)
        local phi=el(`U',`i',2)
        local w=el(`U',`i',3)
        if missing(`pid',`phi',`w') | `pid'!=floor(`pid') | `w'<=0 | `w'>1 | `phi'<=-2 | `phi'>=0 {
            di as error "invalid admissible unit, phi or Huber weight in row `i'"
            exit 503
        }
        if `i' > 1 {
            forvalues j=1/`=`i'-1' {
                if `pid' == el(`U',`j',1) {
                    di as error "duplicate panel ID in e(unit_adjustment)"
                    exit 503
                }
            }
        }
        local sw=`sw'+`w'
        local swphi=`swphi'+`w'*`phi'
        if `w'<1 local ndown=`ndown'+1
    }
    local agg=`swphi'/`sw'
    local stored=e(ect_rcs)
    local expectedG=e(n_admissible)
    local expectedDown=e(n_downweighted)
    if missing(`stored',`expectedG',`expectedDown') {
        di as error "required RCSARDL stored scalar missing"
        exit 503
    }
    local delta=abs(`agg'-`stored')
    local tol=1e-8*(1+abs(`stored'))
    di as text "XTXAI actual RCSARDL aggregation audit (no data altered)"
    di as text "Admissible units in matrix: " as res `G' as text " | reported: " as res `expectedG'
    di as text "Huber downweighted units in matrix: " as res `ndown' as text " | reported: " as res `expectedDown'
    di as text "Reconstructed weighted mean phi: " as res %14.10f `agg'
    di as text "Stored e(ect_rcs):             " as res %14.10f `stored'
    di as text "Absolute difference:            " as res %11.3e `delta'
    if `G'!=`expectedG' | `ndown'!=`expectedDown' | `delta'>`tol' {
        di as error "FAIL: stored RCSARDL robust adjustment is inconsistent with unit matrix"
        exit 459
    }
    di as result "PASS: actual RCSARDL Huber aggregation matches e(ect_rcs)"
    di as text "This verifies the weighted coefficient aggregate, NOT the internal ECT series or short-run model."
    return scalar G=`G'
    return scalar downweighted=`ndown'
    return scalar ect_reconstructed=`agg'
    return scalar ect_stored=`stored'
    return scalar maxerror=`delta'
    return local backend "rcsardl_actual_huber_aggregate"
end
* ===== END actual RCSARDL Huber aggregate audit =====


* ===== BEGIN xtxai_amg_partial =====
*! xtxai_amg_partial 0.33 - observed components, optional reconstructed AMG common process
capture program drop xtxai_amg_partial
program define xtxai_amg_partial, rclass
    version 17.0
    syntax [, VARS(varlist numeric) PREFIX(name) REPLACE WITHIN FULL]
    if "`e(cmd)'" != "xtmg" | "`e(title2)'" != "AMG" {
        di as err "First estimate AMG with xtmg depvar indepvars, augment"
        exit 301
    }
    local id "`e(ivar)'"
    if "`id'" == "" {
        di as err "xtmg has no stored panel identifier"
        exit 498
    }
    capture confirm numeric variable `id'
    if _rc exit 111
    tempname B C
    matrix `B' = e(betas)
    local K=colsof(`B')
    local G=rowsof(`B')
    if `G' != e(N_g) {
        di as err "e(betas) row count does not match e(N_g)"
        exit 498
    }
    local names : colnames `B'
    if "`vars'" == "" {
        foreach term of local names {
            if "`term'" != "_cons" & substr("`term'",1,2) != "__" {
                capture confirm numeric variable `term'
                if !_rc local vars "`vars' `term'"
            }
        }
    }
    if "`vars'" == "" {
        di as err "No observable regressors found; provide vars()"
        exit 498
    }
    foreach v of local vars {
        local k=colnumb(`B',"`v'")
        if missing(`k') | `k'<1 | `k'>`K' {
            di as err "Variable `v' absent from e(betas)"
            exit 498
        }
    }
    local c=colnumb(`B',"_cons")
    if missing(`c') | `c'>`K' {
        di as err "AMG unit intercept missing; unsupported specification"
        exit 498
    }
    tempvar touse g tag
    quietly gen byte `touse'=e(sample)
    quietly egen long `g'=group(`id') if `touse'
    quietly egen byte `tag'=tag(`g') if `touse'
    quietly count if `tag'==1
    if r(N)!=`G' {
        di as err "Observed estimation-sample groups differ from e(betas) rows"
        exit 459
    }
    * xtmg uses egen group(ivar) on its estimation sample before filling e(betas).
    * Retain each row's true original panel ID, not a guessed 1..G ID.
    local nvars : word count `vars'
    matrix `C'=J(`G',`nvars'+2,.)
    forvalues i=1/`G' {
        quietly summarize `id' if `g'==`i' & `touse', meanonly
        matrix `C'[`i',1]=r(min)
        local j=1
        foreach v of local vars {
            local ++j
            local col=colnumb(`B',"`v'")
            matrix `C'[`i',`j']=el(`B',`i',`col')
        }
        matrix `C'[`i',`nvars'+2]=el(`B',`i',`c')
    }
    local pref "`prefix'"
    if "`pref'"=="" local pref "xai_amg"
    local opts "id(`id') vars(`vars') coefmatrix(`C') prefix(`pref')"
    if "`replace'"!="" local opts "`opts' replace"
    if "`within'"!="" local opts "`opts' within"
    xtxai_panelhetero, `opts'
    local N=r(N)
    if "`full'" != "" {
        * Match xtmg 1.0.1 Augmented MG first stage: D.y on D.X and
        * first-differenced time indicators (excluding first), no constant.
        * Reconstruct the time-specific common process using the resulting
        * dummy coefficients (first period normalized to zero).
        local time "`e(tvar)'"
        local dep "`e(depvar)'"
        if "`time'"=="" | "`dep'"=="" {
            di as err "AMG full: xtmg lacks time/response metadata"
            exit 498
        }
        capture confirm numeric variable `time'
        if _rc exit 111
        capture confirm numeric variable `dep'
        if _rc exit 111
        quietly levelsof `time' if `touse', local(periods)
        local T : word count `periods'
        if `T'<3 | `T'>100 {
            di as err "AMG full: time dimension must be 3..100 in guarded reconstruction"
            exit 498
        }
        * xtmg uses a full common calendar and repeats the time process for
        * each panel. Guard against ragged panels and missing time periods.
        forvalues gi=1/`G' {
            quietly count if `g'==`gi' & `touse'
            if r(N)!=`T' {
                di as err "AMG full: unsupported unbalanced/group-specific time sample"
                exit 498
            }
        }
        tempvar ord tagt dyn firststage
        quietly egen long `ord'=group(`time') if `touse'
        quietly egen byte `tagt'=tag(`ord') if `touse'
        local yrp "__xa33"
        * Generate the same indicator-difference regressor design as xtmg.
        * Use dynamically named temporary dummies and clean them afterwards.
        local dummylist ""
        forvalues tt=1/`T' {
            tempvar dum`tt'
            quietly gen byte `dum`tt''=(`ord'==`tt') if `touse'
            if `tt'>1 {
                tempvar dd`tt'
                quietly bysort `id' (`time'): gen double `dd`tt''=`dum`tt''-`dum`tt''[_n-1] if `touse' & `ord'>1
                local dummylist "`dummylist' `dd`tt''"
            }
        }
        tempvar dy
        quietly bysort `id' (`time'): gen double `dy'=`dep'-`dep'[_n-1] if `touse' & `ord'>1
        local dxlist ""
        foreach v of local vars {
            tempvar dx
            quietly bysort `id' (`time'): gen double `dx'=`v'-`v'[_n-1] if `touse' & `ord'>1
            local dxlist "`dxlist' `dx'"
        }
        tempname srcfit coeff
        quietly estimates store `srcfit'
        capture quietly regress `dy' `dxlist' `dummylist' if `touse' & `ord'>1, nocons
        local rc=_rc
        if `rc' {
            quietly estimates restore `srcfit'
            quietly estimates drop `srcfit'
            di as err "AMG common-process first-stage reconstruction failed (rc=`rc')"
            exit `rc'
        }
        matrix `coeff'=e(b)
        quietly estimates restore `srcfit'
        quietly estimates drop `srcfit'
        local common "`pref'_common"
        local fullxb "`pref'_full_xb"
        foreach nm in `common' `fullxb' {
            capture confirm new variable `nm'
            if _rc {
                if "`replace'"=="" {
                    di as err "Variable `nm' exists; use replace"
                    exit 110
                }
                capture drop `nm'
            }
        }
        quietly gen double `common'=0 if `touse'
        local tt=1
        foreach d of local dummylist {
            local ++tt
            local k=colnumb(`coeff',"`d'")
            if missing(`k') | `k'<1 {
                di as err "Missing common-process time coefficient for period `tt'"
                exit 498
            }
            quietly replace `common'=el(`coeff',1,`k') if `ord'==`tt' & `touse'
        }
        local ccol=0
        foreach col of local names {
            if substr("`col'",1,2)=="__" & "`col'"!="_cons" {
                local ++ccol
                local commoncol=colnumb(`B',"`col'")
            }
        }
        if `ccol'!=1 {
            di as err "AMG full requires exactly one estimated common dynamic process coefficient"
            exit 498
        }
        quietly gen double `fullxb'=`pref'_xb if `touse'
        forvalues gi=1/`G' {
            quietly replace `fullxb'=`fullxb'+el(`B',`gi',`commoncol')*`common' if `g'==`gi' & `touse'
        }
        di as result "XTXAI AMG reconstructed common process | G=`G' T=`T' N=`N'"
        di as text "`common' reconstructed from xtmg 1.0.1 first-stage differenced time effects."
        di as text "`fullxb' = observed partial index + unit AMG coefficient * common process."
        di as text "Check against xtmg, augment res(name): y-residual vs `fullxb'; not yet SHAP."
        return local fullindex "`fullxb'"
        return local common "`common'"
        return local scope "full_amg_index_reconstructed_check_residuals"
    }
    di as result "XTXAI xtmg AMG observed-regressor contributions | G=`G'"
    di as text "These contributions include unit intercept + selected observed regressors ONLY."
    di as text "xtmg constructs a temporary common dynamic process (__..._c), then drops it."
    di as text "Therefore `pref'_xb is a PARTIAL index, not the AMG full prediction."
    di as text "No comparison with xtmg fitted values or attribution of common dynamic process."
    return scalar G=`G'
    return scalar N=`N'
    return local model "amg"
    if "`full'"=="" return local scope "observed_regressors_and_intercept_only"
    return local vars "`vars'"
end
* ===== END xtxai_amg_partial =====


* ===== BEGIN xtxai_xtmg_mg v0.34 =====
*! Actual xtmg MG coefficients: unit-specific observed predictor and intercept contributions
capture program drop xtxai_xtmg_mg
program define xtxai_xtmg_mg, rclass
    version 17.0
    syntax [, VARS(varlist numeric) PREFIX(name) REPLACE WITHIN]
    if "`e(cmd)'" != "xtmg" | "`e(title2)'" != "MG" {
        di as err "Estimate plain Mean Group first: xtmg y x1 x2 (without augment/cce)"
        exit 301
    }
    local id "`e(ivar)'"
    if "`id'" == "" {
        di as err "xtmg did not store panel ID"
        exit 498
    }
    confirm numeric variable `id'
    tempname B C
    matrix `B'=e(betas)
    local G=rowsof(`B')
    if `G'!=e(N_g) {
        di as err "xtmg e(betas) count differs from e(N_g)"
        exit 459
    }
    local names : colnames `B'
    if "`vars'"=="" {
        foreach term of local names {
            if "`term'"!="_cons" {
                capture confirm numeric variable `term'
                if !_rc local vars "`vars' `term'"
            }
        }
    }
    if "`vars'"=="" {
        di as err "No observed regressors found; specify vars()"
        exit 498
    }
    local k : word count `vars'
    foreach v of local vars {
        local j=colnumb(`B',"`v'")
        if missing(`j') | `j'<1 {
            di as err "Coefficient for `v' not found in xtmg e(betas)"
            exit 498
        }
    }
    local cons=colnumb(`B',"_cons")
    if missing(`cons') | `cons'<1 {
        di as err "MG without intercept not yet supported in XTXAI"
        exit 498
    }
    tempvar sample g tag
    quietly gen byte `sample'=e(sample)
    quietly egen long `g'=group(`id') if `sample'
    quietly egen byte `tag'=tag(`g') if `sample'
    quietly count if `tag'==1
    if r(N)!=`G' {
        di as err "Panel ID mapping count differs from e(betas)"
        exit 459
    }
    matrix `C'=J(`G',`k'+2,.)
    forvalues i=1/`G' {
        quietly summarize `id' if `g'==`i' & `sample', meanonly
        matrix `C'[`i',1]=r(min)
        local z=1
        foreach v of local vars {
            local ++z
            local col=colnumb(`B',"`v'")
            matrix `C'[`i',`z']=el(`B',`i',`col')
        }
        matrix `C'[`i',`k'+2]=el(`B',`i',`cons')
    }
    local p "`prefix'"
    if "`p'"=="" local p "xai_mg"
    local opts "id(`id') vars(`vars') coefmatrix(`C') prefix(`p')"
    if "`replace'"!="" local opts "`opts' replace"
    if "`within'"!="" local opts "`opts' within"
    xtxai_panelhetero, `opts'
    local n=r(N)
    di as result "XTXAI actual xtmg Mean Group | G=`G' N=`n'"
    di as text "`p'_xb is the full plain MG linear prediction: unit intercept plus unit regressor terms."
    di as text "For comparison estimate xtmg with res(name): residual should agree with y minus `p'_xb within numerical tolerance."
    di as text "No CCE augmentation, AMG common process, causal or SHAP interpretation."
    return scalar G=`G'
    return scalar N=`n'
    return local model "mg"
    return local backend "xtmg_mg_real"
    return local index "`p'_xb"
end
* ===== END xtxai_xtmg_mg =====

* ===== BEGIN xtscc Driscoll-Kraay pooled/FE fitted-index adapter =====
*! xtxai_xtscc 0.35.0 - estimation metadata validated; fitted values do not attribute DK variance
capture program drop xtxai_xtscc
program define xtxai_xtscc, rclass
    version 17.0
    syntax [, PREFIX(name) REPLACE WITHIN]
    if "`e(cmd)'" != "xtscc" {
        di as err "requires preceding xtscc"
        exit 301
    }
    if "`prefix'" == "" local prefix "xai_xtscc"
    local meth = lower(strtrim("`e(method)'"))
    local fe = (strpos("`meth'", "fixed") > 0)
    local pooled = (strpos("`meth'", "pooled") > 0)
    if !`fe' & !`pooled' {
        di as err "unsupported xtscc e(method)=`e(method)'; only pooled or fixed-effects"
        exit 498
    }
    if "`within'" != "" & !`fe' {
        di as err "explain(within) requires xtscc, fe"
        exit 198
    }
    local dep "`e(depvar)'"
    capture confirm numeric variable `dep'
    if _rc {
        di as err "stored xtscc dependent variable missing or nonnumeric"
        exit 111
    }
    local terms : colnames e(b)
    local xx ""
    foreach v of local terms {
        if "`v'" != "_cons" {
            capture confirm numeric variable `v'
            if _rc {
                di as err "xtscc coefficient `v' not a plain numeric data variable; factor/lag terms not yet supported"
                exit 198
            }
            local xx "`xx' `v'"
        }
    }
    local k : word count `xx'
    if `k'==0 {
        di as err "no supported regressors in e(b)"
        exit 498
    }
    local panel "`e(groupvar)'"
    if `fe' {
        capture confirm numeric variable `panel'
        if _rc {
            di as err "xtscc FE e(groupvar) must identify a numeric panel variable"
            exit 498
        }
    }
    local outs "`prefix'_xb `prefix'_baseline `prefix'_check"
    forvalues j=1/`k' {
        local outs "`outs' `prefix'_c`j'"
    }
    if "`replace'"=="" {
        foreach v of local outs {
            confirm new variable `v'
        }
    }
    tempvar smpl fitted ymean
    quietly gen byte `smpl' = e(sample)
    quietly count if `smpl'
    local N = r(N)
    if `N'==0 {
        di as err "xtscc e(sample) contains no observations"
        exit 2000
    }
    foreach v of local xx {
        quietly count if `smpl' & missing(`v')
        if r(N) > 0 {
            di as err "missing regressor `v' in xtscc estimation sample"
            exit 459
        }
    }
    if `fe' {
        quietly bysort `panel': egen double `ymean' = mean(cond(`smpl',`dep',.))
        quietly gen double `fitted' = `ymean' if `smpl'
    }
    else {
        local cons 0
        capture local cons = _b[_cons]
        quietly gen double `fitted' = `cons' if `smpl'
    }
    local j=0
    foreach v of local xx {
        local ++j
        tempvar mu
        if `fe' quietly bysort `panel': egen double `mu' = mean(cond(`smpl',`v',.))
        else {
            quietly gen double `mu' = 0 if `smpl'
        }
        quietly replace `fitted' = `fitted' + _b[`v']*(`v'-`mu') if `smpl'
    }
    if "`replace'"!="" {
        foreach v of local outs {
            capture drop `v'
        }
    }
    quietly gen double `prefix'_xb = `fitted' if `smpl'
    quietly gen double `prefix'_baseline = .
    if `fe' quietly replace `prefix'_baseline = `ymean' if `smpl'
    else {
        local cons 0
        capture local cons = _b[_cons]
        quietly replace `prefix'_baseline = `cons' if `smpl'
    }
    local j=0
    foreach v of local xx {
        local ++j
        tempvar mu
        if `fe' quietly bysort `panel': egen double `mu' = mean(cond(`smpl',`v',.))
        else {
            quietly summarize `v' if `smpl', meanonly
            quietly gen double `mu' = r(mean) if `smpl'
            quietly replace `prefix'_baseline = `prefix'_baseline + _b[`v']*r(mean) if `smpl'
        }
        quietly gen double `prefix'_c`j' = _b[`v']*(`v'-`mu') if `smpl'
        label variable `prefix'_c`j' "xtscc linear centered contribution `v'"
    }
    tempvar reconstructed
    quietly gen double `reconstructed' = `prefix'_baseline if `smpl'
    forvalues j=1/`k' {
        quietly replace `reconstructed' = `reconstructed' + `prefix'_c`j' if `smpl'
    }
    quietly gen double `prefix'_check = abs(`prefix'_xb-`reconstructed') if `smpl'
    quietly summarize `prefix'_check if `smpl', meanonly
    local err = r(max)
    if missing(`err') | `err' > 1e-7 {
        di as err "xtscc index reconstruction failed; maximum error " %12.4e `err'
        exit 459
    }
    if `fe' {
        di as res "XTXAI actual xtscc FE (Driscoll-Kraay) | N=`N' regressors=`k'"
        di as txt "Unit mean y is the baseline; slopes explain within-panel differences."
        di as txt "Level predictions include fitted unit effects, unlike plain xtreg xb."
    }
    else {
        di as res "XTXAI actual xtscc pooled (Driscoll-Kraay) | N=`N' regressors=`k'"
        di as txt "Baseline is pooled intercept plus contributions at sample means."
    }
    di as txt "Additive check max error: " as res %12.4e `err'
    di as txt "No attribution of Driscoll-Kraay standard errors, SHAP, or causal effects."
    return scalar N = `N'
    return scalar K = `k'
    return scalar maxerror = `err'
    return local model "xtscc"
    if `fe' return local estimation "fe"
    else return local estimation "pooled"
end
* ===== END xtscc adapter =====

* ===== BEGIN actual xtpmg PMG coefficient contract v0.36 =====
*! xtxai_pmg_contract 0.36 - inspect real xtpmg PMG results; no unvalidated predictions
capture program drop xtxai_pmg_contract
program define xtxai_pmg_contract, rclass
    version 17.0
    if "`e(cmd)'" != "xtpmg" | "`e(model)'" != "pmg" {
        di as err "First estimate xtpmg ..., pmg; e(cmd) and e(model) must match"
        exit 301
    }
    tempname B BI
    capture matrix `B' = e(b)
    if _rc {
        di as err "e(b) missing"
        exit 498
    }
    capture matrix `BI' = e(b_i)
    if _rc {
        di as err "e(b_i) missing: cannot inspect unit short-run coefficients"
        exit 498
    }
    local k = colsof(`B')
    local G = rowsof(`BI')
    local p = colsof(`BI')
    di as text "XTXAI real xtpmg PMG coefficient contract (READ ONLY)"
    di as text "e(cmd): " as res "`e(cmd)'" as text " | e(model): " as res "`e(model)'"
    di as text "e(ardl_order): " as res "`e(ardl_order)'"
    di as text "e(coef_i): " as res "`e(coef_i)'"
    di as text "e(N): " as res %10.0f e(N)
    di as text "e(b): " as res "1 x `k' (long-run + summary short-run coefficients)"
    matrix list `B'
    di as text "e(b_i): " as res "`G' x `p' (unit short-run coefficients, order not verified)"
    local cni : colfullnames `BI'
    local rni : rownames `BI'
    di as text "e(b_i) columns: " as res `"`cni'"'
    di as text "e(b_i) row names: " as res `"`rni'"'
    if `G' <= 30 & `p' <= 12 matrix list `BI'
    local coeffs "`e(coef_i)'"
    local ec : word 1 of `coeffs'
    if "`ec'" != "" {
        capture confirm variable `ec'
        if !_rc {
            quietly count if e(sample) & !missing(`ec')
            di as text "Observed ECT variable: " as res "`ec'" as text ", nonmissing estimation observations: " as res r(N)
            return local ectvar "`ec'"
            return scalar N_ect = r(N)
        }
        else di as text "ECT term in e(coef_i) is not a preserved variable: " as res "`ec'"
    }
    di as text "Unit coefficient row-to-panel mapping and ECT sign/normalization NOT verified."
    di as text "No observation-level PMG contributions, SHAP or fitted values claimed."
    return scalar N = e(N)
    return scalar G = `G'
    return scalar k_unit = `p'
    return scalar k_summary = `k'
    return local backend "xtpmg"
    return local type "pmg_contract"
end
* ===== END actual xtpmg PMG coefficient contract =====


* ===== BEGIN dynamic PMG decomposition: arbitrary stored ECM regressors =====
*! xtxai_pmg_dynamic 0.44.1-review - generalized short run plus independently checked current-x ECT
capture program drop xtxai_pmg_dynamic
program define xtxai_pmg_dynamic, rclass
    version 17.0
    syntax [, PREFIX(name) REPLACE]
    if "`prefix'" == "" local prefix "xai_pmg"
    if "`e(cmd)'" != "xtpmg" | "`e(model)'" != "pmg" {
        di as err "first estimate xtpmg ..., pmg; then xtxai, model(pmg) explain(dynamic)"
        exit 301
    }
    local dep "`e(depvar)'"
    if substr("`dep'",1,2)!="D." {
        di as err "PMG adapter needs a first-differenced dependent variable D.y"
        exit 498
    }
    local yy = substr("`dep'",3,.)
    local panel "`e(ivar)'"
    capture confirm numeric variable `panel'
    if _rc {
        di as err "PMG requires numeric e(ivar) panel variable"
        exit 498
    }
    local terms "`e(coef_i)'"
    local K : word count `terms'
    if `K'<3 {
        di as err "PMG e(coef_i) must include ECT, at least one short-run regressor, and _cons"
        exit 498
    }
    local ec : word 1 of `terms'
    local last : word `K' of `terms'
    if "`last'"!="_cons" {
        di as err "Unrecognized PMG coefficient layout: last e(coef_i) entry is not _cons"
        exit 498
    }
    capture confirm numeric variable `ec'
    if _rc {
        di as err "Stored PMG ECT `ec' is not available as a numeric variable"
        exit 498
    }
    tempname BI
    capture matrix `BI'=e(b_i)
    if _rc {
        di as err "PMG e(b_i) unavailable"
        exit 498
    }
    local G = rowsof(`BI')
    if `G'!=e(n_g) | colsof(`BI')!=`K' {
        di as err "PMG matrix dimensions do not match e(n_g) and e(coef_i)"
        exit 498
    }
    local rows : rownames `BI'
    local tcols : colnames `BI'
    * Check coefficient column labels when xtpmg exposes usable names.
    * Do not infer meaning from missing or generic matrix colnames.
    if wordcount("`tcols'")==`K' {
        local nmatch=0
        forvalues k=1/`K' {
            local expected : word `k' of `terms'
            local observed : word `k' of `tcols'
            if "`expected'"=="`observed'" local ++nmatch
        }
        if `nmatch'>0 & `nmatch'<`K' {
            di as err "PMG e(b_i) columns partially disagree with e(coef_i); refusing ambiguous alignment"
            exit 498
        }
    }
    tempvar smpl tagged unitmean
    quietly gen byte `smpl'=e(sample)
    quietly count if `smpl'
    local N=r(N)
    if `N'!=e(N) {
        di as err "PMG e(sample) and e(N) disagree"
        exit 459
    }
    quietly gen byte `tagged'=0 if `smpl'
    forvalues j=1/`G' {
        local gid : word `j' of `rows'
        capture confirm number `gid'
        if _rc {
            di as err "PMG e(b_i) row label `gid' is not a numeric panel ID"
            exit 459
        }
        quietly count if `smpl' & `panel'==`gid'
        if r(N)==0 {
            di as err "PMG e(b_i) panel ID `gid' absent from e(sample)"
            exit 459
        }
        quietly replace `tagged'=`tagged'+1 if `smpl' & `panel'==`gid'
    }
    quietly count if `smpl' & `tagged'!=1
    if r(N)>0 {
        di as err "PMG e(b_i) rows do not map one-to-one onto observed panel IDs"
        exit 459
    }
    * Fail closed: independently reconstruct stored ECM with named LR coefficients.
    * Supported LR normalization: L.y - sum(theta_j*x_j), current x_j.
    * Never infer LR coefficient order from an unlabelled matrix.
    tempname LR
    capture matrix `LR'=e(b)
    if _rc {
        di as err "PMG guard: e(b) unavailable for ECT verification"
        exit 498
    }
    local bcols : colnames `LR'
    local beqs : coleq `LR'
    local nc=colsof(`LR')
    local klr=0
    tempvar ectverified
    quietly gen double `ectverified'=L.`yy' if `smpl'
    forvalues j=1/`nc' {
        local eqj : word `j' of `beqs'
        local bj : word `j' of `bcols'
        if "`eqj'"=="`ec'" {
            capture confirm numeric variable `bj'
            if _rc {
                di as err "PMG ECT guard: unsupported LR covariate `bj' (only current numeric variables)"
                exit 498
            }
            local theta=`LR'[1,`j']
            if missing(`theta') {
                di as err "PMG ECT guard: missing LR coefficient `bj'"
                exit 459
            }
            quietly replace `ectverified'=`ectverified'-`theta'*`bj' if `smpl'
            local ++klr
        }
    }
    if `klr'==0 {
        di as err "PMG ECT guard: e(b) has no named long-run coefficients for `ec'; cannot verify normalization"
        exit 498
    }
    quietly count if `smpl' & (missing(`ectverified') | missing(`ec'))
    if r(N) {
        di as err "PMG ECT guard: missing reconstructed or stored ECT on estimation sample"
        exit 459
    }
    tempvar ectgap
    quietly gen double `ectgap'=abs(`ectverified'-`ec') if `smpl'
    quietly summarize `ectgap' if `smpl', meanonly
    local max_ect_gap=r(max)
    if missing(`max_ect_gap') | `max_ect_gap'>1e-6 {
        di as err "PMG ECT guard failed: max discrepancy = " %12.5e `max_ect_gap'
        di as err "Expected stored ECT = L.`yy' minus current LR regressors with e(b) coefficients"
        exit 459
    }
    * Store short-run regressors as temp double variables, evaluating Stata time-series expressions.
    local nshort=`K'-2
    forvalues k=1/`nshort' {
        local index=`k'+1
        local term : word `index' of `terms'
        tempvar x`k'
        capture quietly gen double `x`k''=`term' if `smpl'
        if _rc {
            di as err "Cannot evaluate PMG short-run term `term' from e(coef_i)"
            exit 498
        }
        quietly count if `smpl' & missing(`x`k'')
        if r(N) {
            di as err "PMG short-run term `term' missing on e(sample)"
            exit 459
        }
        local term`k' "`term'"
    }
    local names "`prefix'_xb `prefix'_baseline `prefix'_ec `prefix'_residual `prefix'_check"
    forvalues k=1/`nshort' {
        local names "`names' `prefix'_c`k'"
    }
    foreach nm of local names {
        if strlen("`nm'")>32 {
            di as err "Generated name `nm' exceeds Stata's 32-character limit; shorten prefix()"
            exit 198
        }
        capture confirm variable `nm'
        if !_rc {
            if "`replace'"=="" {
                di as err "`nm' exists; specify replace"
                exit 110
            }
            quietly drop `nm'
        }
    }
    quietly gen double `prefix'_baseline=.
    quietly gen double `prefix'_ec=.
    forvalues k=1/`nshort' {
        quietly gen double `prefix'_c`k'=.
    }
    forvalues j=1/`G' {
        local gid : word `j' of `rows'
        local a=`BI'[`j',1]
        local intercept=`BI'[`j',`K']
        quietly replace `prefix'_baseline=`intercept' if `smpl' & `panel'==`gid'
        quietly replace `prefix'_ec=`a'*`ec' if `smpl' & `panel'==`gid'
        forvalues k=1/`nshort' {
            local idx=`k'+1
            local bk=`BI'[`j',`idx']
            quietly replace `prefix'_c`k'=`bk'*`x`k'' if `smpl' & `panel'==`gid'
        }
    }
    quietly gen double `prefix'_xb=`prefix'_baseline+`prefix'_ec if `smpl'
    forvalues k=1/`nshort' {
        quietly replace `prefix'_xb=`prefix'_xb+`prefix'_c`k' if `smpl'
    }
    quietly count if `smpl' & missing(`prefix'_xb)
    if r(N) {
        di as err "PMG model components missing on e(sample)"
        exit 459
    }
    quietly gen double `prefix'_residual=D.`yy'-`prefix'_xb if `smpl'
    quietly gen double `prefix'_check=`prefix'_baseline+`prefix'_ec if `smpl'
    forvalues k=1/`nshort' {
        quietly replace `prefix'_check=`prefix'_check+`prefix'_c`k' if `smpl'
    }
    quietly replace `prefix'_check=abs(`prefix'_xb-`prefix'_check) if `smpl'
    quietly summarize `prefix'_check if `smpl', meanonly
    local additive=r(max)
    quietly bysort `panel': egen double `unitmean'=mean(cond(`smpl',`prefix'_residual,.))
    quietly summarize `unitmean' if `smpl', meanonly
    local residualmax=max(abs(r(min)),abs(r(max)))
    if missing(`additive') | `additive'>1e-7 {
        di as err "PMG additivity check failed"
        exit 459
    }
    if missing(`residualmax') | `residualmax'>1e-5 {
        di as err "PMG mean within-unit residual inconsistent with stored coefficients: " %12.5e `residualmax'
        exit 459
    }
    di as result "XTXAI PMG dynamic ECM | order=`e(ardl_order)' G=`G' N=`N' K_short=`nshort'"
    di as text "Baseline + stored ECT + all observed short-run terms (NOT Shapley)."
    forvalues k=1/`nshort' {
        di as text "  `prefix'_c`k' = contribution of `term`k''"
        return local term`k' "`term`k''"
    }
    di as text "Additivity max gap: " as result %12.5e `additive'
    di as text "Maximum absolute within-unit residual mean: " as result %12.5e `residualmax'
    di as text "ECT guard: LR coefficients independently reconstruct stored ECT; no causal/factor attribution."
    di as text "ECT maximum reconstruction gap: " as result %12.5e `max_ect_gap' 
    return scalar N=`N'
    return scalar G=`G'
    return scalar max_ect_gap=`max_ect_gap'
    return scalar K_short=`nshort'
    return scalar max_additive_gap=`additive'
    return scalar max_unitmean_residual=`residualmax'
    return local model "pmg"
    return local explanation "dynamic"
end
* ===== END PMG generic dynamic ECM review =====

* ===== xtxai CS-ARDL coefficient identity audit v0.38 =====
* Strictly read-only. No mapping of e(bi) suffixes to panel IDs is asserted.
capture program drop xtxai_csardl_units
program define xtxai_csardl_units, rclass
    version 17.0
    if "`e(cmd)'" != "xtdcce2" {
        di as err "estimate xtdcce2 CS-ARDL first"
        exit 301
    }
    if strpos(lower("`e(cmdline)'"), "lr_options(ardl)") == 0 {
        di as err "this audit requires xtdcce2 with lr_options(ardl)"
        exit 498
    }
    if "`e(lr)'" != "L.invest mvalue kstock L.mvalue L.kstock" {
        di as err "v0.38 supports precisely lr(L.invest mvalue L.mvalue kstock L.kstock)"
        exit 498
    }
    if "`e(indepvar)'" != " " & strtrim("`e(indepvar)'") != "" {
        di as err "v0.38 requires no additional direct regressors"
        exit 498
    }
    tempname B BI U
    matrix `B' = e(b)
    matrix `BI' = e(bi)
    local G = e(N_g)
    if rowsof(`BI') != 1 | colsof(`BI') != 8*`G' | colsof(`B') != 8 {
        di as err "unexpected CS-ARDL matrix sizes; refuse to interpret unit coefficients"
        exit 459
    }
    local bnames : colnames `B'
    if "`bnames'" != "L.invest mvalue kstock L.mvalue L.kstock lr_invest lr_kstock lr_mvalue" {
        di as err "unexpected e(b) coefficient order: `bnames'"
        exit 459
    }
    local bi_names : colnames `BI'
    forvalues i = 1/`G' {
        local base = 5*(`i'-1)
        foreach k in 1 2 3 4 5 {
            local pos = `base'+`k'
            local name : word `pos' of `bi_names'
            local expected : word `k' of L.invest mvalue kstock L.mvalue L.kstock
            if "`name'" != "`expected'_`i'" {
                di as err "e(bi) stripe mismatch at unit suffix `i': `name'"
                exit 459
            }
        }
        foreach suffix in lr_invest lr_kstock lr_mvalue {
            local block = cond("`suffix'"=="lr_invest",0,cond("`suffix'"=="lr_kstock",1,2))
            local pos = 5*`G'+`block'*`G'+`i'
            local found : word `pos' of `bi_names'
            if "`found'" != "`suffix'_`i'" {
                di as err "e(bi) long-run stripe mismatch: `found'"
                exit 459
            }
        }
    }
    matrix `U' = J(`G',8,.)
    matrix colnames `U' = suffix b_Ly b_m b_k phi theta_m theta_k max_gap
    scalar __xtxai_csmax = 0
    forvalues i = 1/`G' {
        local j = 5*(`i'-1)
        scalar __xtxai_a = `BI'[1,`j'+1]
        scalar __xtxai_b = `BI'[1,`j'+2]
        scalar __xtxai_c = `BI'[1,`j'+3]
        scalar __xtxai_d = `BI'[1,`j'+4]
        scalar __xtxai_e = `BI'[1,`j'+5]
        scalar __xtxai_phi = `BI'[1,5*`G'+`i']
        scalar __xtxai_k = `BI'[1,6*`G'+`i']
        scalar __xtxai_m = `BI'[1,7*`G'+`i']
        if abs(1-__xtxai_a) < 1e-10 {
            di as err "near-zero ARDL denominator for suffix `i'"
            exit 459
        }
        scalar __xtxai_gap = max(abs(__xtxai_phi-(__xtxai_a-1)),abs(__xtxai_m-(__xtxai_b+__xtxai_d)/(1-__xtxai_a)),abs(__xtxai_k-(__xtxai_c+__xtxai_e)/(1-__xtxai_a)))
        scalar __xtxai_csmax = max(__xtxai_csmax,__xtxai_gap)
        matrix `U'[`i',1] = `i'
        matrix `U'[`i',2] = __xtxai_a
        matrix `U'[`i',3] = __xtxai_b
        matrix `U'[`i',4] = __xtxai_c
        matrix `U'[`i',5] = __xtxai_phi
        matrix `U'[`i',6] = __xtxai_m
        matrix `U'[`i',7] = __xtxai_k
        matrix `U'[`i',8] = __xtxai_gap
    }
    scalar __xtxai_meangap = 0
    forvalues j = 1/5 {
        scalar __xtxai_total = 0
        forvalues i = 1/`G' {
            scalar __xtxai_total = __xtxai_total + `BI'[1,5*(`i'-1)+`j']/`G'
        }
        scalar __xtxai_meangap = max(__xtxai_meangap,abs(__xtxai_total-`B'[1,`j']))
    }
    forvalues j = 1/3 {
        scalar __xtxai_total = 0
        forvalues i = 1/`G' {
            scalar __xtxai_total = __xtxai_total + `BI'[1,5*`G'+`G'*(`j'-1)+`i']/`G'
        }
        scalar __xtxai_meangap = max(__xtxai_meangap,abs(__xtxai_total-`B'[1,5+`j']))
    }
    di as txt "XTXAI actual xtdcce2 CS-ARDL unit coefficient identity audit | G=" as res `G'
    di as txt "Largest unit adjustment/long-run identity gap: " as res %12.5e __xtxai_csmax
    di as txt "Largest Mean Group aggregation gap: " as res %12.5e __xtxai_meangap
    if __xtxai_csmax > 1e-6 | __xtxai_meangap > 1e-6 {
        di as err "CS-ARDL coefficient consistency threshold failed"
        exit 459
    }
    matrix list `U', format(%12.6g)
    di as txt "Suffix 1..G is NOT independently proven to equal the original panel variable."
    di as txt "No observation-level index, CSA factor contribution, fitted values or SHAP claimed."
    return scalar G = `G'
    return scalar N = e(N)
    return scalar max_identity_gap = __xtxai_csmax
    return scalar max_mean_gap = __xtxai_meangap
    return matrix units = `U'
    return local model "csardl"
end


* ===== CS-ARDL v0.39 strict suffix-aligned observed-dynamic partial contributions =====
* Only for exact two-regressor ARDL(1,1,1) xtdcce2 e(lr) contract.
* Explicit id() must match numeric suffixes 1..G; not a general xtdcce2 id mapping.
* CSA factors and heterogeneous intercepts are partialled out and NOT reconstructed.
capture program drop xtxai_csardl_partial
program define xtxai_csardl_partial, rclass
    version 17.0
    syntax , ID(varname numeric) [PREFIX(name) REPLACE]
    if "`e(cmd)'" != "xtdcce2" | strpos(lower("`e(cmdline)'"),"lr_options(ardl)")==0 {
        di as err "estimate actual xtdcce2 CS-ARDL first"
        exit 301
    }
    if "`e(lr)'" != "L.invest mvalue kstock L.mvalue L.kstock" | strtrim("`e(indepvar)'") != "" {
        di as err "partial index only supports verified lr(L.invest mvalue kstock L.mvalue L.kstock) contract"
        exit 498
    }
    if "`e(idvar)'" != "`id'" {
        di as err "id() must equal xtdcce2 e(idvar)"
        exit 459
    }
    local G = e(N_g)
    local N = e(N)
    tempname BI B
    matrix `BI' = e(bi)
    matrix `B' = e(b)
    if rowsof(`BI')!=1 | colsof(`BI')!=8*`G' | colsof(`B')!=8 {
        di as err "unexpected e(bi)/e(b) dimensions"
        exit 459
    }
    local bnames : colnames `B'
    if "`bnames'" != "L.invest mvalue kstock L.mvalue L.kstock lr_invest lr_kstock lr_mvalue" {
        di as err "unexpected e(b) coefficient names"
        exit 459
    }
    local names : colnames `BI'
    forvalues i=1/`G' {
        local off=5*(`i'-1)
        forvalues k=1/5 {
            local j=`off'+`k'
            local nm : word `j' of `names'
            local token : word `k' of L.invest mvalue kstock L.mvalue L.kstock
            if "`nm'"!="`token'_`i'" {
                di as err "unit coefficient stripe mismatch at suffix `i'"
                exit 459
            }
        }
        foreach type in lr_invest lr_kstock lr_mvalue {
            local grp=cond("`type'"=="lr_invest",0,cond("`type'"=="lr_kstock",1,2))
            local j=5*`G'+`grp'*`G'+`i'
            local nm : word `j' of `names'
            if "`nm'"!="`type'_`i'" {
                di as err "long-run stripe mismatch at suffix `i'"
                exit 459
            }
        }
    }
    tempvar use gtag
    quietly gen byte `use'=e(sample)
    quietly egen byte `gtag'=tag(`id') if `use'
    quietly count if `gtag'
    if r(N)!=`G' {
        di as err "sample has different number of groups from e(N_g)"
        exit 459
    }
    * Explicit bijection: actual numeric IDs 1..G; other IDs rejected.
    quietly count if `use' & (`id'<1 | `id'>`G' | `id'!=floor(`id'))
    if r(N)>0 {
        di as err "id values differ from coefficient suffix 1..G; refusing guessed mapping"
        exit 459
    }
    forvalues i=1/`G' {
        quietly count if `use' & `id'==`i'
        if r(N)==0 {
            di as err "coefficient suffix `i' has no sampled panel with matching ID"
            exit 459
        }
    }
    if "`prefix'"=="" local prefix "xai_csardl"
    foreach t in c_lagy c_mvalue c_kstock c_lagm c_lagk partial_xb {
        local v "`prefix'_`t'"
        if "`replace'"!="" capture drop `v'
        capture confirm new variable `v'
        if _rc {
            di as err "`v' exists; specify replace or another prefix()"
            exit 110
        }
    }
    foreach t in c_lagy c_mvalue c_kstock c_lagm c_lagk partial_xb {
        quietly gen double `prefix'_`t'=.
    }
    forvalues i=1/`G' {
        local j=5*(`i'-1)
        quietly replace `prefix'_c_lagy=`BI'[1,`j'+1]*L.invest if `use' & `id'==`i'
        quietly replace `prefix'_c_mvalue=`BI'[1,`j'+2]*mvalue if `use' & `id'==`i'
        quietly replace `prefix'_c_kstock=`BI'[1,`j'+3]*kstock if `use' & `id'==`i'
        quietly replace `prefix'_c_lagm=`BI'[1,`j'+4]*L.mvalue if `use' & `id'==`i'
        quietly replace `prefix'_c_lagk=`BI'[1,`j'+5]*L.kstock if `use' & `id'==`i'
    }
    quietly replace `prefix'_partial_xb=`prefix'_c_lagy+`prefix'_c_mvalue+`prefix'_c_kstock+`prefix'_c_lagm+`prefix'_c_lagk if `use'
    quietly count if `use' & !missing(`prefix'_partial_xb)
    local actual=r(N)
    if `actual'!=`N' {
        di as err "missing observed partial index; expected `N', obtained `actual'"
        exit 459
    }
    di as txt "XTXAI xtdcce2 CS-ARDL observed dynamics | G=" as res `G' as txt " N=" as res `N'
    di as txt "Explicit id() equals e(bi) suffix 1..G on the estimation sample."
    di as txt "`prefix'_partial_xb = five observed dynamic term contributions."
    di as txt "This is NOT full CS-ARDL fitted index: no CSA coefficients, partialled group constant, or SHAP."
    return scalar G=`G'
    return scalar N=`N'
    return local model "csardl"
    return local explanation "partial"
end

*! xtxai_csardl_predaudit 0.40 - xtdcce2 xb / xb2 prediction-contract diagnostics only
capture program drop xtxai_csardl_predaudit
program define xtxai_csardl_predaudit, rclass
    version 17.0
    syntax , ID(varname numeric) [PREFIX(name) REPLACE]
    if "`e(cmd)'" != "xtdcce2" | strpos(lower("`e(cmdline)'"),"lr_options(ardl)")==0 {
        di as err "estimate xtdcce2 CS-ARDL before prediction audit"
        exit 301
    }
    if "`e(lr)'" != "L.invest mvalue kstock L.mvalue L.kstock" | strtrim("`e(indepvar)'") != "" {
        di as err "this audit only supports the tested Grunfeld CS-ARDL contract"
        exit 498
    }
    if "`id'" != "`e(idvar)'" {
        di as err "id() does not match estimator e(idvar)"
        exit 459
    }
    if "`prefix'"=="" local prefix "xai_csardl"
    foreach v in pred_xb pred_xb2 pred_gap_xb pred_gap_xb2 pred_delta {
        local dest "`prefix'_`v'"
        if "`replace'"!="" capture drop `dest'
        capture confirm new variable `dest'
        if _rc {
            di as err "`dest' exists; use replace or prefix()"
            exit 110
        }
    }
    * Important: do not refit or overwrite e(); only use active estimator prediction interface.
    tempvar sampled
    quietly gen byte `sampled'=e(sample)
    local N=e(N)
    local G=e(N_g)
    capture noisily predict double `prefix'_pred_xb if `sampled', xb
    if _rc {
        di as err "xtdcce2 predict, xb failed; predictions not validated"
        exit 498
    }
    capture noisily predict double `prefix'_pred_xb2 if `sampled', xb2
    if _rc {
        di as err "xtdcce2 predict, xb2 failed; predictions not validated"
        exit 498
    }
    foreach t in pred_gap_xb pred_gap_xb2 pred_delta {
        quietly gen double `prefix'_`t'=.
    }
    * Reuse previously verified partial adapter rather than duplicating coefficient-matching code.
    tempname partprefix
    local internal "_x40temp"
    xtxai_csardl_partial, id(`id') prefix(`internal') replace
    quietly replace `prefix'_pred_gap_xb=`prefix'_pred_xb-`internal'_partial_xb if `sampled'
    quietly replace `prefix'_pred_gap_xb2=`prefix'_pred_xb2-`internal'_partial_xb if `sampled'
    quietly replace `prefix'_pred_delta=`prefix'_pred_xb2-`prefix'_pred_xb if `sampled'
    foreach term in c_lagy c_mvalue c_kstock c_lagm c_lagk partial_xb {
        quietly drop `internal'_`term'
    }
    quietly count if `sampled' & !missing(`prefix'_pred_gap_xb,`prefix'_pred_gap_xb2,`prefix'_pred_delta)
    if r(N)!=`N' {
        di as err "missing prediction diagnostics; expected `N', received " r(N)
        exit 459
    }
    quietly summarize `prefix'_pred_delta if `sampled', meanonly
    local max_abs_delta=max(abs(r(min)),abs(r(max)))
    quietly summarize `prefix'_pred_gap_xb if `sampled', meanonly
    local max_abs_xb=max(abs(r(min)),abs(r(max)))
    quietly summarize `prefix'_pred_gap_xb2 if `sampled', meanonly
    local max_abs_xb2=max(abs(r(min)),abs(r(max)))
    di as text "XTXAI CS-ARDL independent postestimation prediction audit | G=" as res `G' as text " N=" as res `N'
    di as text "Maximum |xb2-xb|: " as res %12.5e `max_abs_delta'
    di as text "Maximum |xb - observed partial|: " as res %12.5e `max_abs_xb'
    di as text "Maximum |xb2 - observed partial|: " as res %12.5e `max_abs_xb2'
    di as text "Gaps are descriptive prediction-interface differences; NOT verified CSA or unit intercept contributions."
    di as text "Do not interpret gap variables as SHAP, latent factors, causal effects, or full decomposition."
    return scalar N=`N'
    return scalar G=`G'
    return scalar max_xb_xb2_gap=`max_abs_delta'
    return scalar max_xb_partial_gap=`max_abs_xb'
    return scalar max_xb2_partial_gap=`max_abs_xb2'
    return local model "csardl"
    return local explanation "predaudit"
end

*! xtxai_csardl_projection 0.41 - source-defined xtdcce2 partialling projection diagnostic
capture program drop xtxai_csardl_projection
program define xtxai_csardl_projection, rclass
    version 17.0
    syntax , ID(varname numeric) [PREFIX(name) REPLACE]
    if "`prefix'"=="" local prefix "xai_csardl"
    foreach v in proj_component proj_xb2 proj_gap {
        if "`replace'"!="" capture drop `prefix'_`v'
        capture confirm new variable `prefix'_`v'
        if _rc {
            di as err "`prefix'_`v' exists; use replace or prefix()"
            exit 110
        }
    }
    tempvar sampleflag
    quietly gen byte `sampleflag'=e(sample)
    local N=e(N)
    local G=e(N_g)
    * This uses actual xtdcce2 predict modes and the validated observed-dynamic adapter.
    * The projection term is the effect of partialling-out, not separately identified CSA factor coefficients.
    xtxai_csardl_predaudit, id(`id') prefix(`prefix') replace
    quietly gen double `prefix'_proj_component=`prefix'_pred_xb2-`prefix'_pred_xb if `sampleflag'
    quietly gen double `prefix'_proj_xb2=`prefix'_pred_xb+`prefix'_proj_component if `sampleflag'
    quietly gen double `prefix'_proj_gap=abs(`prefix'_pred_xb2-`prefix'_proj_xb2) if `sampleflag'
    quietly count if `sampleflag' & !missing(`prefix'_proj_gap)
    if r(N)!=`N' {
        di as err "CS-ARDL projection identity unavailable for entire estimation sample"
        exit 459
    }
    quietly summarize `prefix'_proj_gap if `sampleflag', meanonly
    local maxgap=r(max)
    quietly summarize `prefix'_pred_gap_xb2 if `sampleflag', meanonly
    local maxpartial=max(abs(r(min)),abs(r(max)))
    di as text "XTXAI CS-ARDL projection between xtdcce2 xb and xb2 | G=" as res `G' as text " N=" as res `N'
    di as text "Max |xb2-(xb+projection)|: " as res %12.5e `maxgap'
    di as text "Max |xb2-observed dynamic index|: " as res %12.5e `maxpartial'
    di as text "xtdcce2: xb uses regressors partialled w.r.t. CSA and other controls; xb2 uses original regressors."
    di as text "Projection is NOT separately identified latent factors, unit intercept, structural effect or SHAP."
    return scalar N=`N'
    return scalar G=`G'
    return scalar max_projection_identity_gap=`maxgap'
    return scalar max_xb2_partial_gap=`maxpartial'
    return local model "csardl"
    return local explanation "projection"
end

*! xtxai_pssa_linear 0.42.0 - linear interventional Shapley relative to explicit panel reference
capture program drop xtxai_pssa_linear
program define xtxai_pssa_linear, rclass
    version 17.0
    syntax , VARS(varlist numeric) ID(varname numeric) [BACKGROUND(string) FACTOR(varname numeric) PREFIX(name) REPLACE]
    if !inlist("`e(cmd)'", "regress", "xtreg") {
        di as err "PSSA linear requires a preceding regress or xtreg estimation"
        exit 301
    }
    if "`e(cmd)'" == "xtreg" & !inlist("`e(model)'", "fe", "re") {
        di as err "PSSA linear supports xtreg FE/RE only"
        exit 198
    }
    local bg = lower(strtrim("`background'"))
    if "`bg'" == "" local bg "unit"
    if !inlist("`bg'", "pooled", "unit", "factor") {
        di as err "background() must be pooled, unit, or factor"
        exit 198
    }
    if "`bg'" == "factor" & "`factor'" == "" {
        di as err "background(factor) requires factor(name) with an observed factor"
        exit 198
    }
    if "`bg'" != "factor" & "`factor'" != "" {
        di as err "factor() is used only with background(factor)"
        exit 198
    }
    if "`prefix'" == "" local prefix "xai_pssa"
    local k : word count `vars'
    if `k' < 1 | `k' > 15 {
        di as err "PSSA linear supports 1 to 15 explicitly named regressors"
        exit 198
    }
    tempname B
    matrix `B'=e(b)
    foreach x of local vars {
        local pos=colnumb(`B',"`x'")
        if missing(`pos') {
            di as err "Variable `x' has no unambiguous coefficient in e(b); factor/time operators unsupported"
            exit 498
        }
        if "`e(cmd)'" == "xtreg" & "`x'" == "`id'" {
            di as err "id() must not be an explanatory variable"
            exit 198
        }
    }
    local interceptpos=colnumb(`B',"_cons")
    if missing(`interceptpos') {
        di as err "PSSA linear currently requires a fitted intercept"
        exit 498
    }
    tempvar S group Fcenter Fvar
    quietly gen byte `S'=e(sample)
    quietly count if `S'
    local N=r(N)
    if `N'==0 exit 2000
    quietly count if `S' & missing(`id')
    if r(N)>0 {
        di as err "Missing panel identifiers in estimation sample"
        exit 459
    }
    if "`bg'" == "factor" {
        quietly count if `S' & missing(`factor')
        if r(N)>0 {
            di as err "Observed factor missing on estimation sample"
            exit 459
        }
        tempvar Fbar Fdev Fss
        quietly bysort `id': egen double `Fbar'=mean(cond(`S',`factor',.))
        quietly gen double `Fdev'=`factor'-`Fbar' if `S'
        quietly bysort `id': egen double `Fss'=total(cond(`S',`Fdev'^2,0))
        quietly count if `S' & `Fss'<=1e-12
        if r(N)>0 {
            di as err "Factor must vary within every panel; cannot construct factor-adjusted reference"
            exit 459
        }
    }
    local outputs "`prefix'_baseline `prefix'_xb `prefix'_gap"
    forvalues j=1/`k' {
        local outputs "`outputs' `prefix'_c`j' `prefix'_r`j'"
    }
    foreach v of local outputs {
        if strlen("`v'")>32 {
            di as err "Output name `v' exceeds Stata 32-character limit; choose shorter prefix()"
            exit 198
        }
        if "`replace'"!="" capture drop `v'
        capture confirm new variable `v'
        if _rc {
            di as err "`v' exists; specify replace or prefix()"
            exit 110
        }
    }
    quietly gen double `prefix'_baseline=`B'[1,`interceptpos'] if `S'
    forvalues j=1/`k' {
        local x : word `j' of `vars'
        local p=colnumb(`B',"`x'")
        local beta=`B'[1,`p']
        if "`bg'" == "pooled" {
            quietly summarize `x' if `S', meanonly
            local ref=r(mean)
            quietly gen double `prefix'_r`j'=`ref' if `S'
        }
        if "`bg'" == "unit" {
            quietly bysort `id': egen double `prefix'_r`j'=mean(cond(`S',`x',.))
            quietly replace `prefix'_r`j'=. if !`S'
        }
        if "`bg'" == "factor" {
            tempvar xm dx cross xsum fproj
            quietly bysort `id': egen double `xm'=mean(cond(`S',`x',.))
            quietly gen double `dx'=`x'-`xm' if `S'
            quietly gen double `cross'=`dx'*`Fdev' if `S'
            quietly bysort `id': egen double `xsum'=total(cond(`S',`cross',0))
            quietly gen double `prefix'_r`j'=`xm'+(`xsum'/`Fss')*`Fdev' if `S'
        }
        quietly gen double `prefix'_c`j'=`beta'*(`x'-`prefix'_r`j') if `S'
        quietly replace `prefix'_baseline=`prefix'_baseline+`beta'*`prefix'_r`j' if `S'
    }
    quietly gen double `prefix'_xb=`prefix'_baseline if `S'
    forvalues j=1/`k' {
        quietly replace `prefix'_xb=`prefix'_xb+`prefix'_c`j' if `S'
    }
    tempvar fitted
    quietly gen double `fitted'=`B'[1,`interceptpos'] if `S'
    foreach x of local vars {
        local p=colnumb(`B',"`x'")
        quietly replace `fitted'=`fitted'+`B'[1,`p']*`x' if `S'
    }
    quietly gen double `prefix'_gap=abs(`prefix'_xb-`fitted') if `S'
    quietly summarize `prefix'_gap if `S', meanonly
    local maxgap=r(max)
    if `maxgap'>1e-8 {
        di as err "PSSA contribution identity check failed; max gap=" %12.4e `maxgap'
        exit 459
    }
    di as result "XTXAI PSSA linear interventional Shapley | background=`bg' N=`N' K=`k'"
    di as text "Exact baseline + contribution identity (maximum difference): " %12.4e `maxgap'
    di as text "Reference uses estimation sample. No holdout split, uncertainty, nonlinear SHAP, or causal effect."
    if "`e(cmd)'"=="xtreg" & "`e(model)'"=="fe" di as text "FE: index excludes estimated unit fixed effects; NOT a full FE level prediction."
    if "`bg'"=="factor" di as text "Observed factor adjustment is an in-sample within-unit projection, NOT latent-factor identification."
    return scalar N=`N'
    return scalar k=`k'
    return scalar maxgap=`maxgap'
    return local reference "`bg'"
    return local model "pssa"
end


* ===== XTXAI ML reference-game exact Shapley bridge (not Tree SHAP) =====
program define xtxai_mlpssa, rclass
    version 17.0
    syntax varlist(min=2 numeric) [if] [in], MODEL(string) ID(varname numeric) HOLDOUT(real) [BACKGROUND(string) PREFIX(name) REPLACE]
    marksample touse
    gettoken dep xvars : varlist
    local bg = lower(strtrim("`background'"))
    if "`bg'" == "" local bg "unit"
    if !inlist("`bg'", "unit", "pooled") {
        di as err "ML PSSA currently permits background(unit|pooled) only"
        exit 198
    }
    local k : word count `xvars'
    if `k'>5 {
        di as err "ML PSSA exact coalitional computation supports at most 5 features"
        exit 198
    }
    if "`prefix'" == "" local prefix "xps"
    local tocreate "`prefix'_pred `prefix'_base `prefix'_set"
    forvalues j=1/`k' {
        local tocreate "`tocreate' `prefix'_c`j'"
    }
    if "`replace'" == "" {
        foreach v of local tocreate {
            confirm new variable `v'
        }
    }
    local timevar : char _dta[_TStvar]
    if "`timevar'" == "" {
        di as err "xtset id time before ML PSSA"
        exit 459
    }
    local panelvar : char _dta[_TSpanel]
    if "`id'" != "`panelvar'" {
        di as err "id() must match xtset panel variable"
        exit 459
    }
    capture findfile xtxaiml_pssa_engine.py
    if _rc {
        di as err "xtxaiml_pssa_engine.py not found on Stata adopath"
        exit 601
    }
    local engine "`r(fn)'"
    local features ""
    foreach v of local xvars {
        if "`features'" == "" local features "`v'"
        else local features "`features',`v'"
    }
    tempvar row
    quietly generate long `row'=_n
    tempfile input output result
    preserve
    quietly keep if `touse'
    quietly keep `row' `id' `timevar' `dep' `xvars'
    quietly rename `row' xtxai_row
    quietly rename `id' xtxai_id
    quietly rename `timevar' xtxai_time
    quietly rename `dep' xtxai_y
    quietly export delimited using "`input'.csv", replace
    restore
    python script "`engine'", args("`input'.csv" "`output'.csv" "`model'" "`holdout'" "`features'" "`bg'")
    preserve
    quietly import delimited using "`output'.csv", clear varnames(1) asdouble
    quietly rename xtxai_row `row'
    quietly rename xps_pred `prefix'_pred
    quietly rename xps_base `prefix'_base
    quietly rename xps_set `prefix'_set
    forvalues j=1/`k' {
        quietly rename xps_c`j' `prefix'_c`j'
    }
    quietly save "`result'", replace
    restore
    if "`replace'" != "" {
        foreach v of local tocreate {
            capture drop `v'
        }
    }
    quietly merge 1:1 `row' using "`result'", nogen keep(master match)
    quietly drop `row'
    tempvar gap
    quietly generate double `gap'=(`prefix'_pred-`prefix'_base) if !missing(`prefix'_pred)
    forvalues j=1/`k' {
        quietly replace `gap'= `gap' - `prefix'_c`j' if !missing(`gap')
    }
    quietly replace `gap'=abs(`gap') if !missing(`gap')
    quietly summarize `gap', meanonly
    if missing(r(max)) | r(max)>1e-5 {
        di as err "ML PSSA additive reconstruction failed"
        exit 459
    }
    local err=r(max)
    quietly count if !missing(`prefix'_pred)
    local n=r(N)
    di as result "XTXAI ML PSSA reference-game | model=`model' background=`bg' N=`n' features=`k'"
    di as text "Exact coalitional Shapley for the fitted model, using a finite TRAINING background sample."
    di as text "Not Tree SHAP, not latent factors, not causal; holdout predictions are not explanations of panel effects."
    di as text "Maximum additive gap: " %12.4e `err'
    return scalar maxgap=`err'
    return scalar N=`n'
    return local model "`model'"
    return local background "`bg'"
end
