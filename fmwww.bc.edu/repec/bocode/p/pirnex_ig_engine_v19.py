"""PIRNEX v1.9 pair Integrated Gradients for its OWN retrained neural network.
Additive decomposition of predicted within-ID pair differences, not causal effects.
Dependencies numpy, torch and companion pirnex_engine_v17.py (bundled).
"""
import argparse, csv, os
import numpy as np
import torch
from pirnex_engine_v17 import read, pairs, fit, pred, SEED

FEATURES=['tenure','hours','union','year_effect']

def write_csv(path, rows):
    with open(path,'w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0].keys()));w.writeheader();w.writerows(rows)

def explain_core(net, xi, xj, steps, batch):
    """Midpoint Riemann Integrated Gradients on the direct xi -> xj path.
    IG_k=(xjk-xik)* Integral_0^1 (d core(xi+a*(xj-xi))/d xk) da.
    Time effects handled exactly outside IG.
    """
    out=[]
    net.eval()
    for start in range(0,len(xi),batch):
        a=xi[start:start+batch];b=xj[start:start+batch]
        d=b-a
        accum=torch.zeros_like(a)
        for n in range(steps):
            alpha=(n+.5)/steps
            p=(a+alpha*d).detach().requires_grad_(True)
            z=net.core(p).sum()
            accum+=torch.autograd.grad(z,p)[0].detach()
        out.append((d*accum/steps).numpy())
    return np.vstack(out)

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--folder',default='.');ap.add_argument('--steps',type=int,default=128)
    ap.add_argument('--batch',type=int,default=256);ap.add_argument('--epochs',type=int,default=150)
    ap.add_argument('--tolerance',type=float,default=2e-5)
    args=ap.parse_args()
    if args.steps<8: raise ValueError('steps must be at least 8')
    torch.set_num_threads(1)
    rng=np.random.default_rng(SEED)
    folder=args.folder
    tr=read(os.path.join(folder,'pinn_panel_train.csv'))
    va=read(os.path.join(folder,'pinn_panel_valid.csv'))
    te=read(os.path.join(folder,'pinn_panel_test.csv'))
    ny=int(max(tr[3].max(),va[3].max(),te[3].max()))+1
    ptrain=pairs(tr,rng);pvalid=pairs(va,rng);ptest=pairs(te,rng)
    net,ep,val_loss=fit(ptrain,pvalid,ny,args.epochs,SEED)
    xi,ti,xj,tj,observed,fe_delta,ids=ptest
    ig=explain_core(net,xi,xj,args.steps,args.batch)
    with torch.no_grad():
        years=(net.yr(tj)-net.yr(ti)).flatten().numpy()
        core_delta=(net.core(xj)-net.core(xi)).flatten().numpy()
        target=pred(net,ptest).numpy()
    contrib=np.column_stack([ig,years])
    reconstructed=contrib.sum(axis=1)
    error=np.abs(reconstructed-target)
    maxerr=float(error.max());meanerr=float(error.mean())
    if maxerr>args.tolerance:
        raise RuntimeError('INTEGRATED GRADIENTS ADDITIVITY FAILED: max error %.9g > %.9g; increase --steps' % (maxerr,args.tolerance))
    test_mse=float(np.mean((target-observed.numpy())**2))
    denom=float(np.sum((observed.numpy()-observed.numpy().mean())**2))
    test_r2=1.-float(np.sum((target-observed.numpy())**2))/denom
    # Optional consistency check with v1.7 metrics, tolerate float roundoff.
    mpath=os.path.join(folder,'pirnex_metrics_v17.csv')
    if os.path.exists(mpath):
        with open(mpath,newline='',encoding='utf-8-sig') as f: prev=next(csv.DictReader(f))
        old=float(prev['test_pair_mse'])
        if abs(test_mse-old)>5e-5:
            raise RuntimeError('MODEL REPRODUCTION FAILED: v1.9 MSE %.8f versus v1.7 %.8f' % (test_mse,old))
    rows=[]
    for k in range(len(ids)):
        rec={'test_id':int(ids[k]),'observed_delta':float(observed[k]),'predicted_delta':float(target[k]),
             'tenure_ig':float(ig[k,0]),'hours_ig':float(ig[k,1]),'union_ig':float(ig[k,2]),
             'year_effect':float(years[k]),'sum_contributions':float(reconstructed[k]),
             'additivity_error':float(error[k])}
        rows.append(rec)
    write_csv(os.path.join(folder,'pirnex_neural_pair_ig_v19.csv'),rows)
    summary=[]
    for j,key in enumerate(FEATURES):
        v=contrib[:,j]
        summary.append({'variable':key,'mean_abs_contribution':float(np.mean(np.abs(v))),
                        'mean_signed_contribution':float(np.mean(v)),
                        'positive_share':float(np.mean(v>0)),
                        'negative_share':float(np.mean(v<0)),
                        'p05_contribution':float(np.quantile(v,.05)),
                        'p95_contribution':float(np.quantile(v,.95)),
                        'test_pairs':len(v)})
    write_csv(os.path.join(folder,'pirnex_neural_ig_summary_v19.csv'),summary)
    write_csv(os.path.join(folder,'pirnex_neural_ig_metrics_v19.csv'),[{
        'test_pairs':len(ids),'best_epoch':ep,'test_pair_mse':test_mse,'test_pair_r2':test_r2,
        'ig_steps':args.steps,'max_additivity_error':maxerr,'mean_additivity_error':meanerr,
        'additivity_pass':1}])
    print('PIRNEX v1.9 OWN-NEURAL Integrated Gradients: PASS')
    print('Test pairs:',len(ids),'R2:',round(test_r2,7),'MSE:',round(test_mse,7),'best epoch:',ep)
    print('Pair decomposition: tenure IG + hours IG + union IG + exact year component')
    print('Maximum additivity error:',round(maxerr,10),'threshold:',args.tolerance)
    print('Attributions are descriptive, path-dependent, and NOT causal effects.')

if __name__=='__main__': main()
