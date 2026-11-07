"""XTXAI ML preview v0.6.0 — pooled predictive ML and additive explanations.
This is a prototype, not an SSC release. Not causal, no panel effect estimation.
"""
import sys
import numpy as np
import pandas as pd


def fit_explain(model_name, Xtr, ytr, Xall):
    if model_name == 'xgboost':
        import xgboost as xgb
        import shap
        model = xgb.XGBRegressor(n_estimators=80, max_depth=3, learning_rate=0.05,
                                 subsample=1.0, colsample_bytree=1.0,
                                 objective='reg:squarederror', random_state=2026, n_jobs=2)
        model.fit(Xtr, ytr)
        pred = np.asarray(model.predict(Xall), dtype=float)
        explainer = shap.TreeExplainer(model, feature_perturbation='tree_path_dependent')
        contrib = np.asarray(explainer.shap_values(Xall), dtype=float)
        base = float(np.asarray(explainer.expected_value).reshape(-1)[0])
        label = 'Tree SHAP (tree-path-dependent)'
    elif model_name == 'randomforest':
        from sklearn.ensemble import RandomForestRegressor
        import shap
        model = RandomForestRegressor(n_estimators=80, min_samples_leaf=2,
                                      max_features=1.0, random_state=2026, n_jobs=2)
        model.fit(Xtr, ytr)
        pred = np.asarray(model.predict(Xall), dtype=float)
        explainer = shap.TreeExplainer(model, feature_perturbation='tree_path_dependent')
        explained = explainer(Xall, check_additivity=False)
        contrib = np.asarray(explained.values, dtype=float)
        rawbase = np.asarray(explained.base_values, dtype=float)
        if rawbase.ndim == 0:
            base = float(rawbase)
        elif rawbase.size == len(pred) and np.max(rawbase)-np.min(rawbase) < 1e-9:
            base = float(rawbase.flat[0])
        else:
            raise ValueError('Random Forest Tree SHAP baseline not constant or not scalar.')
        label = 'Random Forest Tree SHAP (tree-path-dependent)'
    elif model_name == 'ebm':
        from interpret.glassbox import ExplainableBoostingRegressor
        model = ExplainableBoostingRegressor(interactions=0, random_state=2026,
                                             outer_bags=1, inner_bags=0, n_jobs=2)
        model.fit(Xtr, ytr)
        pred = np.asarray(model.predict(Xall), dtype=float)
        terms = np.asarray(model.eval_terms(Xall), dtype=float)
        if terms.ndim != 2 or terms.shape[0] != len(Xall):
            raise ValueError('Unexpected EBM eval_terms() dimensions.')
        contrib = np.zeros((len(Xall), len(Xall.columns)), dtype=float)
        for k, indices in enumerate(model.term_features_):
            if len(indices) != 1:
                raise ValueError('EBM interactions are disabled in this preview.')
            contrib[:, indices[0]] += terms[:, k]
        base = float(np.asarray(model.intercept_).item())
        label = 'EBM additive terms (NOT SHAP)'
    else:
        raise ValueError('Unsupported model: ' + model_name)
    base_arr = np.full(len(pred), base)
    if contrib.shape != (len(pred), len(Xall.columns)):
        raise ValueError('Incorrect contribution array shape.')
    error = float(np.max(np.abs(pred - base_arr - contrib.sum(axis=1))))
    if not np.isfinite(error) or error > 1e-5:
        raise ValueError(f'Failed explanation reconstruction: {error:g}')
    return pred, base_arr, contrib, error, label


def main(input_csv, output_csv, model_list, holdout_text, feature_list):
    features = feature_list.split(',')
    models = model_list.split(',')
    if not features or len(set(features)) != len(features):
        raise ValueError('Provide distinct explanatory variables.')
    if not models or len(set(models)) != len(models) or any(m not in ('xgboost', 'ebm', 'randomforest') for m in models):
        raise ValueError('Models must be one or both of xgboost and ebm, without repetition.')
    df = pd.read_csv(input_csv).dropna(subset=['xtxai_row', 'xtxai_time', 'xtxai_y'] + features).copy()
    if df.empty:
        raise ValueError('No complete-case observations.')
    cutoff = float(holdout_text)
    train = (df['xtxai_time'] < cutoff).to_numpy()
    test = (df['xtxai_time'] >= cutoff).to_numpy()
    if train.sum() < 30 or test.sum() < 5:
        raise ValueError('Holdout requires >=30 training and >=5 test observations.')
    Xall = df[features].astype(float)
    Xtr = Xall.iloc[np.where(train)[0]]
    ytr = df.loc[train, 'xtxai_y'].astype(float)
    y_test = df.loc[test, 'xtxai_y'].to_numpy(dtype=float)
    out = pd.DataFrame({'xtxai_row': df['xtxai_row'].astype('int64')})
    out['xtml_set'] = np.where(train, 0, 1)
    multiple = len(models) > 1
    print(f'XTXAI ML v0.6.0-preview: train N={int(train.sum())}; test N={int(test.sum())}; holdout >= {cutoff:g}')
    print(f'{"Model":<12} {"RMSE":>12} {"MAE":>12} {"Decomp.error":>16}  Explanation')
    for m in models:
        pred, base, contrib, error, label = fit_explain(m, Xtr, ytr, Xall)
        suffix = {'xgboost':'xtml_xgb', 'ebm':'xtml_ebm', 'randomforest':'xtml_rf'}[m] if multiple else 'xtml'
        out[f'{suffix}_pred'] = pred
        out[f'{suffix}_base'] = base
        for i in range(contrib.shape[1]):
            out[f'{suffix}_c{i+1}'] = contrib[:, i]
        residual = y_test - pred[test]
        rmse = float(np.sqrt(np.mean(residual ** 2)))
        mae = float(np.mean(np.abs(residual)))
        print(f'{m:<12} {rmse:>12.6f} {mae:>12.6f} {error:>16.3e}  {label}')
    if out.columns.duplicated().any():
        raise ValueError('Duplicate output columns.')
    out.to_csv(output_csv, index=False, float_format='%.16g')
    print('IMPORTANT: pooled models; panel effects not modeled; predictions are not causal effects.')


if __name__ == '__main__':
    if len(sys.argv) != 6:
        raise SystemExit('Usage: xtxaiml_engine.py input.csv output.csv models holdout feature1,feature2,...')
    main(*sys.argv[1:])
