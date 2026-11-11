"""PIRNEX v1.8 external ML benchmarks. No replacement for neural PIRNEX.
Level-trained XGBoost and optional Explainable Boosting Machine; held-out within-ID pair metrics.
Uses the existing v1.7 CSV split. Never uses test targets for training.
"""
import argparse, csv, math, os
import numpy as np
from sklearn.metrics import mean_squared_error

SEED=20261108

def read(path):
    a=np.atleast_1d(np.genfromtxt(path,delimiter=',',names=True,encoding=None))
    x=np.column_stack([a['x1'],a['x2'],a['union'],a['yridx']]).astype(float)
    return x,np.asarray(a['y'],float),np.asarray(a['idcode'],int)

def make_pairs(ids,rng):
    idx=[]
    for uid in np.unique(ids):
        inds=np.where(ids==uid)[0]
        if len(inds)>=2:
            rng.shuffle(inds)
            idx.extend(zip(inds[::2][:len(inds)//2],inds[1::2][:len(inds)//2]))
    return np.asarray(idx,dtype=int)

def metrics(y,p,ab):
    i,j=ab.T
    obs=y[j]-y[i]
    fitted=p[j]-p[i]
    mse=float(np.mean((obs-fitted)**2))
    denom=float(np.sum((obs-np.mean(obs))**2))
    return mse,math.sqrt(mse),float(1-np.sum((obs-fitted)**2)/denom) if denom>0 else float('nan')

def write_csv(path,rows,fields=None):
    if not rows:return
    with open(path,'w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=fields or list(rows[0].keys()));w.writeheader();w.writerows(rows)

def main():
    a=argparse.ArgumentParser()
    a.add_argument('--folder',default='.')
    a.add_argument('--ebm',type=int,choices=[0,1],default=1)
    a.add_argument('--trees',type=int,default=220)
    args=a.parse_args()
    base=args.folder
    tr=read(os.path.join(base,'pinn_panel_train.csv'))
    va=read(os.path.join(base,'pinn_panel_valid.csv'))
    te=read(os.path.join(base,'pinn_panel_test.csv'))
    rng=np.random.default_rng(SEED)
    # EXACT same RNG calls and same ordering as PIRNEX v1.7 pairs(tr),pairs(va),pairs(te).
    ptrain=make_pairs(tr[2],rng)
    pvalid=make_pairs(va[2],rng)
    ptest=make_pairs(te[2],rng)
    if len(ptest)==0:raise RuntimeError('No independent-ID test pairs')
    ntrain=len(tr[1]);ntest=len(te[1])
    os.makedirs(base,exist_ok=True)
    rows=[]; predictions={}
    def score(model,name,train_type='Level MSE'):
        pred_v=np.asarray(model.predict(va[0]),float)
        pred_t=np.asarray(model.predict(te[0]),float)
        vm,vr,v2=metrics(va[1],pred_v,pvalid)
        tm,trm,r2=metrics(te[1],pred_t,ptest)
        rows.append(dict(model=name,training_target=train_type,valid_pair_mse=round(vm,7),test_pair_mse=round(tm,7),test_pair_rmse=round(trm,7),test_pair_r2=round(r2,7),train_n=ntrain,test_n=ntest,test_pairs=len(ptest),status='OK'))
        predictions[name]=pred_t
    try:
        from xgboost import XGBRegressor
    except ImportError:
        raise RuntimeError('XGBoost is missing. Run: python -m pip install xgboost scikit-learn pandas')
    model=XGBRegressor(n_estimators=args.trees,max_depth=3,learning_rate=0.04,subsample=0.85,colsample_bytree=1.0,reg_lambda=3.0,objective='reg:squarederror',random_state=SEED,n_jobs=1,tree_method='hist')
    model.fit(tr[0],tr[1],verbose=False)
    score(model,'XGBoost')
    ebm_problem=None
    if args.ebm:
        try:
            from interpret.glassbox import ExplainableBoostingRegressor
            ebm=ExplainableBoostingRegressor(interactions=3,random_state=SEED,n_jobs=1,max_rounds=500,outer_bags=2,inner_bags=0)
            ebm.fit(tr[0],tr[1]);score(ebm,'EBM')
        except ImportError:
            ebm_problem='Missing interpret package: python -m pip install interpret'
        except Exception as exc:
            ebm_problem='EBM could not run: '+str(exc)
    # Check exact observed test pair differences vs v1.7 previously exported data.
    old=os.path.join(base,'pirnex_test_pairs_v16.csv')
    check='not_checked'
    if os.path.exists(old):
        z=np.atleast_1d(np.genfromtxt(old,names=True,delimiter=',',encoding=None))
        expected=te[1][ptest[:,1]]-te[1][ptest[:,0]]
        check='PASS' if len(z)==len(expected) and np.allclose(np.asarray(z['observed_diff'],float),expected,atol=1e-5) else 'FAIL'
    # Existing PIRNEX row is loaded, not refitted; its test scores are an exact prior result if split matches.
    oldmet=os.path.join(base,'pirnex_metrics_v17.csv')
    if os.path.exists(oldmet) and check=='PASS':
        m=np.atleast_1d(np.genfromtxt(oldmet,names=True,delimiter=',',encoding=None))[0]
        rows.insert(0,dict(model='PIRNEX Neural',training_target='Within-ID pair MSE',valid_pair_mse=round(float(m['valid_pair_mse']),7),test_pair_mse=round(float(m['test_pair_mse']),7),test_pair_rmse=round(float(m['test_pair_rmse']),7),test_pair_r2=round(float(m['test_pair_r2']),7),train_n=ntrain,test_n=ntest,test_pairs=len(ptest),status='Existing v1.7 result'))
    write_csv(os.path.join(base,'pirnex_ml_comparison_v18.csv'),rows)
    # Keep observed differences in an audit file.
    i,j=ptest.T
    obs=te[1][j]-te[1][i]
    predrows=[]
    for k in range(len(obs)):
        row={'test_id':int(te[2][i[k]]),'observed_diff':float(obs[k])}
        for name,p in predictions.items():row[name.lower()+'_pred_diff']=float(p[j[k]]-p[i[k]])
        predrows.append(row)
    write_csv(os.path.join(base,'pirnex_ml_test_pairs_v18.csv'),predrows)
    with open(os.path.join(base,'pirnex_ml_status_v18.txt'),'w',encoding='utf-8') as f:
        f.write('PIRNEX v1.8 | XGBoost / optional EBM LEVEL-trained benchmarks\n')
        f.write('Test pairs regenerated with v1.7 random sequence: '+check+'\n')
        f.write('ML training objective: level MSE; evaluation: held-out within-ID pair differences.\n')
        if ebm_problem:f.write('EBM STATUS: '+ebm_problem+'\n')
    print('PIRNEX v1.8 benchmark complete; pair integrity:',check)
    for r in rows:print(r['model'],'test pair R2:',r['test_pair_r2'],'RMSE:',r['test_pair_rmse'])
    if ebm_problem:print('EBM:',ebm_problem)
    if check=='FAIL':print('WARNING: Test pair ordering differs from saved v1.7; do not compare until resolved.')
if __name__=='__main__':main()
