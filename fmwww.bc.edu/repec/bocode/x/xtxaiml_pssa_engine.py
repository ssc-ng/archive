"""Reference-game empirical interventional Shapley for fixed XGBoost / additive EBM fits.
Finite background from training data only, fixed deterministic sampling per context.
NOT a latent-factor estimator, not Tree SHAP, and not causal explanations.
"""
import itertools
import sys
import numpy as np
import pandas as pd

SEED = 20261103
MAX_BACKGROUND = 24


def fit(name, x, y):
    if name == "xgboost":
        import xgboost as xgb
        m = xgb.XGBRegressor(n_estimators=80, max_depth=3, learning_rate=0.05,
                             subsample=1.0, colsample_bytree=1.0,
                             objective="reg:squarederror", random_state=2026, n_jobs=2)
    elif name == "ebm":
        from interpret.glassbox import ExplainableBoostingRegressor
        m = ExplainableBoostingRegressor(interactions=0, random_state=2026,
                                         outer_bags=1, inner_bags=0, n_jobs=2)
    else:
        raise ValueError("Only xgboost and ebm supported")
    m.fit(x, y)
    return m


def shap_for_row(model, observation, background, feature_names):
    """Evaluate 2**K coalition values and exact Shapley combinatorial weights."""
    import math
    k=len(feature_names)
    n=len(background)
    values=np.empty(1 << k, dtype=float)
    ref=background.to_numpy(dtype=float)
    for mask in range(1 << k):
        hybrid=ref.copy()
        for j in range(k):
            if mask & (1 << j):
                hybrid[:, j]=observation[j]
        values[mask]=float(np.mean(model.predict(pd.DataFrame(hybrid,columns=feature_names))))
    phi=np.zeros(k,dtype=float)
    for j in range(k):
        for mask in range(1 << k):
            if mask & (1 << j):
                continue
            size=mask.bit_count()
            w=1.0/k / math.comb(k-1,size)
            phi[j]+=w*(values[mask | (1 << j)]-values[mask])
    return values[0],phi,values[(1 << k)-1]


def main(path, outpath, model_name, cutoff, csvvars, mode):
    feats=csvvars.split(',')
    if len(feats)<1 or len(feats)>5 or len(set(feats))!=len(feats):
        raise ValueError("Use 1..5 distinct features")
    df=pd.read_csv(path).dropna(subset=['xtxai_row','xtxai_id','xtxai_time','xtxai_y']+feats).copy()
    if df.empty:
        raise ValueError("No usable data")
    train=df.xtxai_time.to_numpy() < float(cutoff)
    if train.sum()<30 or (~train).sum()<5:
        raise ValueError("Require >=30 training and >=5 holdout observations")
    X=df[feats].astype(float).reset_index(drop=True)
    y=df['xtxai_y'].astype(float).to_numpy()
    m=fit(model_name,X.loc[train],y[train])
    ids=df.xtxai_id.to_numpy()
    rng=np.random.default_rng(SEED)
    # Fixed background per context; no test observations enter the reference pool.
    pools={}
    for key in (np.unique(ids) if mode=='unit' else ['pooled']):
        eligible=np.where(train & (ids==key))[0] if mode=='unit' else np.where(train)[0]
        if len(eligible)==0:
            raise ValueError(f"No training background for panel {key}")
        if len(eligible)>MAX_BACKGROUND:
            eligible=np.sort(rng.choice(eligible,MAX_BACKGROUND,replace=False))
        pools[key]=X.iloc[eligible]
    pred=[];base=[];contrib=[]; maxdiff=0.0; maxdirect=0.0
    for i in range(len(df)):
        key=ids[i] if mode=='unit' else 'pooled'
        b,ph,full=shap_for_row(m,X.iloc[i].to_numpy(),pools[key],feats)
        direct=float(m.predict(X.iloc[[i]])[0])
        # Coalitional Shapley efficiency is with respect to v(all), evaluated
        # via the same fixed-background prediction pathway as every coalition.
        # XGBoost's float32 prediction is not bit-identical for batch sizes 1
        # and N_background; track this separately rather than mixing targets.
        diff=abs(full-b-ph.sum())
        maxdiff=max(maxdiff,diff)
        direct_diff=abs(full-direct)
        maxdirect=max(maxdirect,direct_diff)
        # Numerical precision guard, NOT a relaxed SHAP efficiency criterion.
        # Bound float32 inference differences relative to prediction scale.
        direct_tol=8*np.finfo(np.float32).eps*max(1.0,abs(full),abs(direct))
        if direct_diff>direct_tol:
            raise ValueError(f"Standalone/batch prediction mismatch: {direct_diff} > {direct_tol}")
        pred.append(full);base.append(b);contrib.append(ph)
    if maxdiff>1e-5:
        raise ValueError(f"Shapley additivity failure {maxdiff}")
    out=pd.DataFrame({'xtxai_row':df.xtxai_row.astype('int64'), 'xps_set':(~train).astype(int),
                      'xps_pred':pred,'xps_base':base})
    mat=np.array(contrib)
    for j in range(len(feats)):
        out[f'xps_c{j+1}']=mat[:,j]
    out.to_csv(outpath,index=False,float_format='%.16g')
    print(f"ML PSSA: {model_name} | background={mode} | train={train.sum()} | holdout={(~train).sum()} | additive_maxgap={maxdiff:.3e} | standalone_batch_maxgap={maxdirect:.3e}")
    print("Finite empirical training reference; exact coalitions for chosen background. Not Tree SHAP, not EBM term scoring.")

if __name__=='__main__':
    if len(sys.argv)!=7:
        raise SystemExit('Usage: xtxaiml_pssa_engine.py input.csv output.csv xgboost|ebm holdout feature_csv unit|pooled')
    main(*sys.argv[1:])
