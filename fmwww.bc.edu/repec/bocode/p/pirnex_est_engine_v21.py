"""Panel pair-difference neural prototype. Noncausal. Cluster exploratory bootstrap."""
import argparse, csv, os, copy, math
import numpy as np
import torch
from torch import nn
SEED=20261108

def read(path):
    a=np.genfromtxt(path, delimiter=',', names=True, encoding=None)
    a=np.atleast_1d(a)
    X=np.column_stack((a['x1'],a['x2'],a['union'])).astype('float32')
    Y=np.asarray(a['y'],dtype='float32'); ids=np.asarray(a['idcode'],dtype='int64')
    years=np.asarray(a['yridx'],dtype='int64')
    assert np.isfinite(X).all() and np.isfinite(Y).all()
    return X,Y,ids,years,np.asarray(a['fe_xb'],dtype='float32')

def save(name, rows):
    with open(name,'w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)

class Net(nn.Module):
    def __init__(self, ny):
        super().__init__()
        self.core=nn.Sequential(nn.Linear(3,16),nn.Tanh(),nn.Linear(16,16),nn.Tanh(),nn.Linear(16,1))
        self.yr=nn.Embedding(ny,1)
        nn.init.zeros_(self.yr.weight)
    def forward(self,x,t): return self.core(x).flatten()+self.yr(t).flatten()

def pairs(data,rng):
    X,y,ids,t,*extra=data
    groups=[]
    for k in np.unique(ids):
        inds=np.where(ids==k)[0]
        if len(inds)>=2:
            rng.shuffle(inds)
            groups.extend(zip(inds[::2][:len(inds)//2],inds[1::2][:len(inds)//2]))
    if len(groups)<20: raise RuntimeError('Too few within-person pairs')
    ab=np.array(groups,dtype=int)
    i,j=ab[:,0],ab[:,1]
    return (torch.tensor(X[i]),torch.tensor(t[i]),torch.tensor(X[j]),torch.tensor(t[j]),torch.tensor(y[j]-y[i]),torch.tensor(extra[0][j]-extra[0][i]),ids[i])

def pred(net,p):
    xi,ti,xj,tj,d,*_=p
    return net(xj,tj)-net(xi,ti)

def mse(net,p):
    with torch.no_grad():
        err=pred(net,p)-p[4]
        return float((err**2).mean()),float(1-(err**2).sum()/((p[4]-p[4].mean())**2).sum())

def fit(train,valid,ny,epochs,seed):
    torch.manual_seed(seed)
    net=Net(ny)
    opt=torch.optim.Adam(net.parameters(),lr=.01,weight_decay=.0001)
    best=1e50; bestep=0; state=None; patience=0
    for ep in range(1,epochs+1):
        net.train();opt.zero_grad()
        loss=((pred(net,train)-train[4])**2).mean();loss.backward();opt.step()
        vm,_=mse(net,valid)
        if vm<best-1e-7:
            best=vm;bestep=ep;state=copy.deepcopy(net.state_dict());patience=0
        else: patience+=1
        if patience>=25:break
    net.load_state_dict(state);return net,bestep,best

def effects(net, data, ranges):
    X,y,ids,tt,*extra=data
    x=torch.tensor(X,requires_grad=True); t=torch.tensor(tt)
    out=net(x,t)
    grads=torch.autograd.grad(out.sum(),x)[0].detach().numpy()
    base=X.copy();base[:,2]=0
    alt=X.copy();alt[:,2]=1
    with torch.no_grad():
        diff=(net(torch.tensor(alt),t)-net(torch.tensor(base),t)).numpy()
    return np.array([grads[:,0].mean()/ranges[0],grads[:,1].mean()/ranges[1],diff.mean()])



def effect_distribution(net, data, ranges):
    """Observation-level partial derivatives and counterfactual binary contrasts.
    Evaluated on held-out IDs only; they are descriptive predictions, not causal effects.
    """
    X,y,ids,tt,*_=data
    xx=torch.tensor(X,requires_grad=True)
    ttensor=torch.tensor(tt)
    grad=torch.autograd.grad(net(xx,ttensor).sum(),xx)[0].detach().numpy()
    low=X.copy(); high=X.copy()
    low[:,2]=0.; high[:,2]=1.
    with torch.no_grad():
        union=(net(torch.tensor(high),ttensor)-net(torch.tensor(low),ttensor)).numpy()
    return np.column_stack((grad[:,0]/ranges[0],grad[:,1]/ranges[1],union))

def conditional_profiles(net, data, ranges):
    """At 10th and 90th percentiles of each continuous X, others at test medians.
    For union, low/high are effect contrasts at low/high tenure, respectively.
    """
    X,y,ids,t,*_=data
    base=np.median(X,axis=0).astype('float32')
    base[2]=0.
    year=int(np.median(t))
    ans=[]
    for j in range(3):
        rows=np.tile(base,(2,1))
        if j<2:
            rows[:,j]=np.quantile(X[:,j],[.1,.9]).astype('float32')
            inp=torch.tensor(rows,requires_grad=True)
            g=torch.autograd.grad(net(inp,torch.tensor([year,year])).sum(),inp)[0].detach().numpy()
            ans.append((float(g[0,j]/ranges[j]),float(g[1,j]/ranges[j])))
        else:
            rows[:,0]=np.quantile(X[:,0],[.1,.9]).astype('float32')
            a=rows.copy();b=rows.copy(); a[:,2]=0.;b[:,2]=1.
            with torch.no_grad():
                diff=(net(torch.tensor(b),torch.tensor([year,year]))-net(torch.tensor(a),torch.tensor([year,year]))).numpy()
            ans.append((float(diff[0]),float(diff[1])))
    return ans

def bootstrapped(data,rng):
    X,y,ids,t,*extra=data
    uid=np.unique(ids)
    sampled=rng.choice(uid,size=len(uid),replace=True)
    indices=[]; newids=[]
    for b,k in enumerate(sampled):
        ix=np.where(ids==k)[0]
        indices.extend(ix);newids.extend([b]*len(ix))
    indices=np.asarray(indices,dtype=int)
    return X[indices],y[indices],np.asarray(newids),t[indices],extra[0][indices]

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--folder',default='.');ap.add_argument('--epochs',type=int,default=150);ap.add_argument('--boots',type=int,default=60);ap.add_argument('--compare-fe',type=int,choices=[0,1],default=0);ap.add_argument('--names',nargs=3,default=['tenure','hours','union']);ap.add_argument('--seed',type=int,default=20261108);o=ap.parse_args()
    torch.set_num_threads(1)
    rng=np.random.default_rng(o.seed)
    folder=o.folder
    tr=read(os.path.join(folder,'pinn_panel_train.csv'));va=read(os.path.join(folder,'pinn_panel_valid.csv'));te=read(os.path.join(folder,'pinn_panel_test.csv'))
    ranges=np.genfromtxt(os.path.join(folder,'pinn_panel_ranges.csv'),delimiter=',',names=True)
    ranges=[float(ranges['range_tenure']),float(ranges['range_hours'])]
    ny=int(max(tr[3].max(),va[3].max(),te[3].max()))+1
    ptrain=pairs(tr,rng);pvalid=pairs(va,rng);ptest=pairs(te,rng)
    net,ep,v=fit(ptrain,pvalid,ny,o.epochs,o.seed)
    test,r2=mse(net,ptest);ame=effects(net,te,ranges)
    fe_err=(ptest[5]-ptest[4]).numpy()
    fe_mse=float(np.mean(fe_err**2))
    fe_r2=float(1-(fe_err**2).sum()/((ptest[4].numpy()-ptest[4].numpy().mean())**2).sum())
    nn_err=(pred(net,ptest).detach()-ptest[4]).numpy()
    # same test pairs, same test groups; positive gain favors neural model
    improvement=float(np.mean(fe_err**2-nn_err**2))
    save(os.path.join(folder,'pirnex_test_pairs_v16.csv'),[
        {'test_id':int(ptest[6][k]),'observed_diff':float(ptest[4][k]),
        'nn_pred_diff':float(pred(net,ptest).detach()[k]),'fe_pred_diff':float(ptest[5][k]),
        'nn_sqerr':float(nn_err[k]**2),'fe_sqerr':float(fe_err[k]**2)}
        for k in range(len(fe_err))])
    # Cluster-level resampling of test pairs is descriptive uncertainty of test loss gap,
    # conditional on the already-trained models (not parameter inference).
    tids=ptest[6]; unq=np.unique(tids)
    test_gains=[]
    for bb in range(500):
        sampled=rng.choice(unq,len(unq),replace=True)
        loc=np.concatenate([np.where(tids==q)[0] for q in sampled])
        test_gains.append(float(np.mean(fe_err[loc]**2-nn_err[loc]**2)))
    gain_lo,gain_hi=np.percentile(test_gains,[2.5,97.5])
    # Conditional derivative across tenure points, holding other features at test medians;
    # union fixed to 0; age/time encoded by observed year distribution.
    xgrid=np.array([0., .25, .5, .75, 1.],dtype=np.float32)
    reference=np.median(te[0],axis=0).astype(np.float32)
    reference[2]=0.
    yrs=np.full(5,int(np.median(te[3])),dtype=np.int64)
    xplot=np.tile(reference,(5,1));xplot[:,0]=xgrid
    gX=torch.tensor(xplot,requires_grad=True);gT=torch.tensor(yrs)
    deriv=torch.autograd.grad(net(gX,gT).sum(),gX)[0].detach().numpy()[:,0]/ranges[0]
    save(os.path.join(folder,'pinn_panel_tenure_curve_v15.csv'),[
        {'tenure_scaled':float(z),'tenure_years':float(z*ranges[0]+float(np.genfromtxt(os.path.join(folder,'pinn_panel_ranges.csv'),delimiter=',',names=True)['min_tenure'])),
        'conditional_slope':float(v)} for z,v in zip(xgrid,deriv)])
    distribution=effect_distribution(net,te,ranges)
    profiles=conditional_profiles(net,te,ranges)
    out=[]; boot=[]
    for b in range(o.boots):
        bt=bootstrapped(tr,rng)
        try:
            pb=pairs(bt,rng)
            bn,be,bv=fit(pb,pvalid,ny,o.epochs,o.seed+100+b)
            eb=effects(bn,te,ranges)
            boot.append(eb)
        except (RuntimeError,ValueError):continue
    arr=np.asarray(boot, dtype=float)
    # Experimental normal-reference Wald tests on the VECTOR of mean effects.
    # These tests are NOT validated for adaptive neural net estimation.
    valid = len(boot) >= max(30, len(ame)+5) and np.isfinite(arr).all()
    wald = float('nan'); wald_p = float('nan'); wald_df = 0
    se_vector = np.full(3, np.nan)
    if valid:
        cov = np.cov(arr, rowvar=False, ddof=1)
        se_vector = np.sqrt(np.diag(cov))
        if np.all(se_vector > 0):
            eig = np.linalg.eigvalsh(cov)
            if eig[0] > 1e-12*eig[-1] and eig[0]>0:
                wald = float(ame @ np.linalg.solve(cov, ame))
                wald_df = len(ame)
                wald_p = float(torch.special.gammaincc(torch.tensor(wald_df/2, dtype=torch.float64), torch.tensor(wald/2,dtype=torch.float64)).item())
    def normal_two_sided(z):
        return float(math.erfc(abs(z)/math.sqrt(2))) if math.isfinite(z) else float('nan')
    # Export joint bootstrap draws so the covariance calculation is auditable.
    if len(arr):
        save(os.path.join(folder, 'pirnex_boot_draws_v17.csv'), [
            {'rep':b+1,o.names[0]:float(z[0]),o.names[1]:float(z[1]),o.names[2]+'_0_to_1':float(z[2])} for b,z in enumerate(arr)])
    for j,name in enumerate([o.names[0],o.names[1],o.names[2]+'_0_to_1']):
        se=float(arr[:,j].std(ddof=1)) if len(boot)>1 else float('nan')
        lo,hi=np.percentile(arr[:,j],[2.5,97.5]) if len(boot)>1 else (np.nan,np.nan)
        out.append({'variable':name,'effect':round(float(ame[j]),7),'boot_se':round(se,7),'ci_lo':round(float(lo),7),'ci_hi':round(float(hi),7),'bootstrap_n':len(boot)})
    save(os.path.join(folder,'pirnex_effects_v16.csv'),out)
    unified=[]
    for j,name in enumerate([o.names[0],o.names[1],o.names[2]+'_0_to_1']):
        values=distribution[:,j]
        unified.append({'variable':name, 'effect_type':'AME' if j<2 else 'Discrete_0_to_1',
            'ame':out[j]['effect'],'boot_se':out[j]['boot_se'],
            'ci_lo':out[j]['ci_lo'],'ci_hi':out[j]['ci_hi'],
            'z_exploratory':float(ame[j]/se_vector[j]) if valid and se_vector[j]>0 else float('nan'),
            'p_exploratory':normal_two_sided(float(ame[j]/se_vector[j])) if valid and se_vector[j]>0 else float('nan'),
            'low_effect':round(profiles[j][0],7), 'high_effect':round(profiles[j][1],7),
            'effect_sd':round(float(values.std(ddof=1)),7),
            'pos_share':round(float((values>0).mean()),6),
            'neg_share':round(float((values<0).mean()),6),
            'p05_effect':round(float(np.quantile(values,.05)),7),
            'p95_effect':round(float(np.quantile(values,.95)),7),
            'bootstrap_n':out[j]['bootstrap_n']})
    save(os.path.join(folder,'pirnex_unified_v17.csv'),unified)
    save(os.path.join(folder,'pirnex_metrics_v17.csv'),[{'train_n':len(tr[1]),'valid_n':len(va[1]),'test_n':len(te[1]),'train_ids':len(np.unique(tr[2])),'test_ids':len(np.unique(te[2])),'train_pairs':len(ptrain[4]),'test_pairs':len(ptest[4]),'best_epoch':ep,'valid_pair_mse':round(v,7),'test_pair_mse':round(test,7),'test_pair_r2':round(r2,7),'test_pair_rmse':round(math.sqrt(test),7), 'wald_chi2_exploratory':wald,'wald_df':wald_df,'wald_prob_exploratory':wald_p,'fe_test_pair_mse':round(fe_mse,7) if o.compare_fe else '', 'fe_test_pair_r2':round(fe_r2,7) if o.compare_fe else '', 'fe_minus_nn_mse':round(improvement,7) if o.compare_fe else '', 'gain_ci_lo':round(float(gain_lo),7) if o.compare_fe else '', 'gain_ci_hi':round(float(gain_hi),7) if o.compare_fe else ''}])
    print('Panel NN completed; independent-ID test MSE:',round(test,6),'R2:',round(r2,5),'FE test MSE:' if o.compare_fe else 'FE omitted:',round(fe_mse,6) if o.compare_fe else '-', 'bootstrap reps:',len(boot))
    print('EXPLORATORY Wald chi2:',round(wald,4),'df:',wald_df,'Prob > chi2:',round(wald_p,5));print('WARNING: Normal/chi2 reference p-values NOT validated for neural net; not causal.')
if __name__=='__main__': main()
