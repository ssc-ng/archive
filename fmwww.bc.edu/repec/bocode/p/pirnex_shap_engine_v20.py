"""PIRNEX v2.0: XGBoost exact TreeSHAP contributions + EBM term contributions.
Same v1.8 individual split and disjoint held-out pair selection. No test fitting.
"""
import os, csv, argparse
import numpy as np
from xgboost import XGBRegressor, DMatrix
SEED=20261108
FEATURES=['tenure','hours','union','year']
def read(p):
 a=np.atleast_1d(np.genfromtxt(p,delimiter=',',names=True,encoding=None))
 return np.column_stack([a['x1'],a['x2'],a['union'],a['yridx']]).astype(float),np.asarray(a['y'],float),np.asarray(a['idcode'],int)
def pairs(ids,rng):
 output=[]
 for uid in np.unique(ids):
  inds=np.where(ids==uid)[0]
  if len(inds)>=2:
   rng.shuffle(inds)
   output.extend(zip(inds[::2][:len(inds)//2],inds[1::2][:len(inds)//2]))
 return np.asarray(output,dtype=int)
def write(path,rows):
 if not rows: return
 with open(path,'w',newline='',encoding='utf-8') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def describe(name,terms,contrib,pt,ids,y,predict):
 # Matrix is level-prediction additive contributions for every test observation.
 i,j=pt.T
 dc=contrib[j]-contrib[i]
 dy=y[j]-y[i];dp=predict[j]-predict[i]
 resid=np.max(np.abs(dc.sum(axis=1)-dp))
 if resid>2e-4: raise RuntimeError(f'Additivity failure {name}: {resid}')
 summary=[]
 for k,term in enumerate(terms):
  summary.append(dict(model=name,term=term,mean_abs_level_contribution=float(np.mean(np.abs(contrib[:,k]))),mean_abs_pair_contribution=float(np.mean(np.abs(dc[:,k]))),mean_pair_contribution=float(np.mean(dc[:,k])),pair_positive_share=float(np.mean(dc[:,k]>0)),pair_negative_share=float(np.mean(dc[:,k]<0)),test_pairs=len(pt)))
 # Individual pair attribution. These are contributions to predicted DIFFERENCE, not marginal effects.
 audit=[]
 for q,(a,b) in enumerate(pt):
  row={'model':name,'test_id':int(ids[a]),'observed_wage_difference':float(dy[q]),'predicted_wage_difference':float(dp[q])}
  row.update({term+'_pair_contribution':float(dc[q,k]) for k,term in enumerate(terms)})
  audit.append(row)
 return summary,audit,resid

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--folder',default='.');ap.add_argument('--ebm',type=int,default=1);ap.add_argument('--trees',type=int,default=220)
 a=ap.parse_args();b=a.folder
 tr=read(os.path.join(b,'pinn_panel_train.csv'));va=read(os.path.join(b,'pinn_panel_valid.csv'));te=read(os.path.join(b,'pinn_panel_test.csv'))
 rng=np.random.default_rng(SEED)
 _=pairs(tr[2],rng);_=pairs(va[2],rng);pt=pairs(te[2],rng)
 # Audit ensures exact same held-out pairs as v1.8.
 ref=os.path.join(b,'pirnex_ml_test_pairs_v18.csv')
 if not os.path.isfile(ref):raise RuntimeError('Run PIRNEX v1.8 first: missing pirnex_ml_test_pairs_v18.csv')
 old=np.atleast_1d(np.genfromtxt(ref,delimiter=',',names=True,encoding=None))
 observed=te[1][pt[:,1]]-te[1][pt[:,0]]
 if len(old)!=len(pt) or not np.allclose(old['observed_diff'],observed,atol=1e-5):
  raise RuntimeError('Test pairs differ from v1.8: STOP, do not compare.')
 model=XGBRegressor(n_estimators=a.trees,max_depth=3,learning_rate=0.04,subsample=0.85,colsample_bytree=1.0,reg_lambda=3.0,objective='reg:squarederror',random_state=SEED,n_jobs=1,tree_method='hist')
 model.fit(tr[0],tr[1],verbose=False)
 pred=model.predict(te[0]);full=model.get_booster().predict(DMatrix(te[0]),pred_contribs=True)
 # XGBoost exact TreeSHAP contributions: columns FEATURES + bias.
 if full.shape[1]!=5:raise RuntimeError('Unexpected XGBoost SHAP shape')
 if not np.allclose(full.sum(axis=1),pred,atol=2e-4):raise RuntimeError('TreeSHAP attribution sum mismatch')
 summaries=[];audits=[]
 s,p,e=describe('XGBoost TreeSHAP',FEATURES,full[:,:4],pt,te[2],te[1],pred)
 summaries+=s;audits+=p
 # EBM: native additive term scores, NOT SHAP (and terms may include interactions).
 status='EBM disabled'
 if a.ebm:
  try:
   from interpret.glassbox import ExplainableBoostingRegressor
   ebm=ExplainableBoostingRegressor(interactions=3,random_state=SEED,n_jobs=1,max_rounds=500,outer_bags=2,inner_bags=0)
   ebm.fit(tr[0],tr[1]);ec=np.asarray(ebm.eval_terms(te[0]),float);epred=np.asarray(ebm.predict(te[0]),float)
   raw=[str(z) for z in ebm.term_names_]
   import re
   def readable_ebm(z):
    z=re.sub(r'feature_([0-9]{4})',lambda m: FEATURES[int(m.group(1))] if int(m.group(1))<len(FEATURES) else m.group(0),z)
    return z.replace(' & ','_x_').replace(' × ','_x_').replace(' ','_')
   names=[readable_ebm(z) for z in raw]
   if len(names)!=ec.shape[1]:raise RuntimeError('EBM term-name mismatch')
   s,p,e=describe('EBM native terms',names,ec,pt,te[2],te[1],epred)
   summaries+=s;audits+=p;status='EBM native terms OK'
  except ImportError: status='EBM unavailable: pip install interpret'
  except Exception as exc: status='EBM error: '+str(exc)
 write(os.path.join(b,'pirnex_explain_summary_v20.csv'),summaries)
 # Separate model audit files because EBM has different term columns.
 for name in ('XGBoost TreeSHAP','EBM native terms'):
  rows=[r for r in audits if r['model']==name]
  if rows:write(os.path.join(b,'pirnex_explain_pairs_'+('xgb' if name.startswith('XGBoost') else 'ebm')+'_v20.csv'),rows)
 print('PIRNEX v2.0 explainability complete | Pair integrity: PASS | XGBoost TreeSHAP additivity: PASS')
 print('NOTE: TreeSHAP values explain level predictions; pair attribution = later SHAP - earlier SHAP.')
 print('NOTE: EBM uses native additive term scores; not SHAP.')
 print(status)
 print('Summary file: pirnex_explain_summary_v20.csv')
if __name__=='__main__':main()
