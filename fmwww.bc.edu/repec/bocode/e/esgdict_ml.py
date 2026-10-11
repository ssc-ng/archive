# -*- coding: utf-8 -*-
"""
esgdict_ml.py -- machine-learning ESG dictionary builder for the Stata
                 command esgdict.ado.

The builder turns a corpus of Chinese / English ESG reports into the plain
text dictionary consumed by qta.ado:

    Environmental   /  Social  /  Governance  /  General_ESG
    <term>
    ...

Three fully reproducible methods are implemented (option method()):

  npmi    (default) normalised point-wise mutual information seed expansion.
          Terms are scored by their local co-occurrence with a curated seed
          vocabulary, i.e. a distributional-semantics lexicon learner.
  kmeans  latent semantic analysis (truncated SVD) of the TF-IDF term space
          followed by k-means clustering; clusters are matched to the four
          ESG dimensions with a Hungarian assignment against seed centroids.
  hybrid  average of the (standardised) npmi and kmeans scores.

Author: WU Lianghai, WU Hanyan, XU Huihui   (October 6, 2026)
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import warnings

warnings.filterwarnings("ignore")

import numpy as np
from scipy import sparse
from scipy.optimize import linear_sum_assignment
from sklearn.cluster import KMeans
from sklearn.decomposition import TruncatedSVD
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import normalize

RANDOM_STATE = 2026
DIMENSIONS = ["Environmental", "Social", "Governance", "General_ESG"]

STOP_CN = set("""
的 了 和 与 及 以及 或 是 在 有 为 对 等 中 我们 公司 本 报告 年度 集团 股份 有限公司
这 那 上 下 不 也 都 而 但 并 从 到 将 已 会 可 可以 进行 通过 相关 主要 各 该 其 此
一 二 三 四 五 六 七 八 九 十 百 千 万 亿 元 万元 亿元 人民 币 人民币 年 月 日 本年度
情况 方面 工作 管理 有关 并且 同时 因此 由于 对于 关于 其中 包括
进一步 不断 持续 积极 努力 加强 推进 促进 推动 完善 优化 提升 提高 建立 建设 实现
""".split())

STOP_EN = set("""
the and for with that this from are was were been has have had will would can could
which their its our your they them we you he she it not but all any also into over
under such more most other than then there these those when where while who whom
each few own same so some only very just about above after again against
between during before below off out on at by to of in as is be or if no nor too
shall may should must upon within without per etc year report company group
limited corporation board total number both
""".split())

BLACKLIST = set("""
摘要 全文 目录 第一节 第二节 第三节 第四节 第五节 序号 名称 是否 如下 上述 其他
本次 正文 重要性 议题 对应 机构名称 负责管理 仔细阅读 出版 出版物 图书 保荐 传媒
发行 募集 转让 合伙 等于 存在 情形 代表人 内部 流动资金 核查 首次 上市公司
单位 万吨 亿元 万元 千人 或者 没有 一项 一层 一期 两个 相应 有关 存在
   碳中 专利 危险 有害 无害 产生 应对 处理厂 贮存 气体 电站 管网 分布式 屋顶
   建设项目 从业 专门 下设 召开 邮箱 传达 临时 受理 信访 总数 金额 性别 消费
   签订 期望 强迫 对待 定点 强制 回应 步骤 随着 我国 紧扣 落地 加速 深化
   精益 美丽 贡献力量 积极响应 锚定 实用新型
   发明专利 合同法 劳动法 代表大会 公平 问题 合计 呈现 位于 大赛 物理 侵犯
   互联网 限制 理解 学生 辅助 负面影响 创业 论坛 最佳 推出 加入 细则 引擎
   成就 积累 反对 购买 数字 群体 业务部门 总部 课程 上线 面向 工具 对应 主题
""".split())

_CJK = re.compile(r"^[\u3400-\u4dbf\u4e00-\u9fff]{2,6}$")
_ASCII = re.compile(r"^[a-z][a-z\-]{2,24}$")

SEEDS = {
    "Environmental": """
    环保 环境保护 环境 生态 绿色 低碳 碳 碳排放 碳中和 碳达峰 温室气体 气候 气候变化
    能源 节能 能耗 可再生能源 清洁能源 光伏 风电 水资源 用水 节水 废水 污水 排放 污染物
    废气 固废 废弃物 废物 循环经济 资源利用 生物多样性 环保投入 环境治理 绿色生产 绿色技术
    二氧化硫 化学需氧量 危险废物 减排 降碳 清洁生产 环境保护设施 环境影响
    """.split(),
    "Social": """
    员工 雇员 职工 培训 职业健康 健康 安全 安全生产 劳动 劳动合同 薪酬 福利
    社会保险 人权 平等 多元化 反歧视 社区 公益 慈善 捐赠 志愿服务 客户 消费者 产品质量
    产品安全 供应链 供应商 社会责任 利益相关方 乡村振兴 就业 教育 帮扶 客户满意度
    职业发展 员工权益 工伤保险 诉求 关爱 慰问
    """.split(),
    "Governance": """
    治理 公司治理 董事会 监事会 独立董事 股东 股东大会 审计 内部控制 合规 风险 风险管理
    反腐败 廉洁 商业道德 信息披露 透明度 关联交易 投资者关系 股权 章程 委员会 战略 监督
    问责 制度 规范 授权 决策 诚信 法律 法规 利益冲突 举报 审计委员会 反贪污 反贿赂
    内幕信息 内部控制制度 规范运作
    """.split(),
    "General_ESG": """
    ESG 可持续 可持续发展 可持续披露 社会责任报告 环境社会及管治 企业公民 高质量发展
    长期价值 绿色金融 绿色信贷 绿色债券 双碳 利益相关者 非财务信息 披露 ESG报告
    社会责任 环境信息 可持续发展报告
    """.split(),
}

SEEDS_EN = {
    "Environmental": "environment environmental emission emissions carbon climate energy water waste pollution green renewable biodiversity discharge recycling ozone".split(),
    "Social": "employee employees labour labor safety health training welfare community charity donation customer consumer product quality diversity rights supplier".split(),
    "Governance": "governance board director shareholder audit risk compliance control transparency corruption ethics disclosure committee integrity".split(),
    "General_ESG": "esg sustainability sustainable responsibility stakeholder citizenship".split(),
}


def say(msg):
    enc = getattr(sys.stdout, "encoding", None) or "utf-8"
    try:
        print(msg, flush=True)
    except UnicodeEncodeError:
        print(msg.encode(enc, "replace").decode(enc, "replace"), flush=True)


# ------------------------------------------------------------------ tokens
def _jieba_stopwords():
    try:
        from jieba.analyse.tfidf import STOP_WORDS as SW
        return set(SW)
    except Exception:
        try:
            from jieba.analyse import default_tfidf
            return set(default_tfidf.stop_words)
        except Exception:
            return set()


def _jieba_idf():
    try:
        from jieba.analyse.tfidf import IDFLoader
        from jieba.analyse import DEFAULT_IDF
        return IDFLoader(DEFAULT_IDF).get_idf()
    except Exception:
        return {}


def tokenize_cn(text, jieba, stop=()):
    out = []
    for tok in jieba.cut(text):
        tok = tok.strip()
        if len(tok) < 2 or tok in STOP_CN or tok in stop:
            continue
        if _CJK.match(tok):
            out.append(tok)
        elif re.match(r"^[A-Za-z][A-Za-z\-]{1,7}$", tok):
            out.append(tok.lower())
    return out


def tokenize_en(text):
    out = []
    for tok in re.findall(r"[A-Za-z][A-Za-z\-]{1,}", text.lower()):
        if tok in STOP_EN or len(tok) < 3:
            continue
        if _ASCII.match(tok):
            out.append(tok)
    return out


def normalise(word, lang):
    return word.lower() if lang == "en" else word


# ------------------------------------------------------------------ corpus
def load_corpus(spec):
    docs = []
    corpus = spec.get("corpus", "")
    textcol = spec.get("textcol", "ESGreport")
    maxchars = int(spec.get("maxchars", 40000000))
    if corpus and os.path.isdir(corpus):
        for fn in sorted(os.listdir(corpus)):
            if fn.lower().endswith(".txt"):
                with open(os.path.join(corpus, fn), encoding="utf-8", errors="ignore") as fh:
                    docs.append(fh.read())
    elif corpus.lower().endswith(".dta"):
        import pandas as pd
        df = pd.read_stata(corpus, convert_categoricals=False)
        col = textcol if textcol in df.columns else df.columns[-1]
        docs = [str(v) for v in df[col].tolist()]
    elif corpus.lower().endswith(".csv"):
        import pandas as pd
        df = pd.read_csv(corpus, encoding="utf-8-sig", dtype=str,
                         engine="python", on_bad_lines="skip")
        col = textcol if textcol in df.columns else df.columns[-1]
        docs = ["" if v is None or (isinstance(v, float) and np.isnan(v)) else str(v)
                for v in df[col].tolist()]
    elif corpus:
        with open(corpus, encoding="utf-8", errors="ignore") as fh:
            docs = [fh.read()]
    docs = [d for d in docs if d and d.strip()]
    total, trimmed = 0, []
    for d in docs:
        if total >= maxchars:
            break
        trimmed.append(d[: max(0, maxchars - total)])
        total += len(d)
    return trimmed


def load_seeds(spec, lang):
    seeds = {k: list(v) for k, v in (SEEDS if lang == "cn" else SEEDS_EN).items()}
    seed_file = spec.get("seeds", "")
    if seed_file and os.path.exists(seed_file):
        cur = None
        for line in open(seed_file, encoding="utf-8-sig"):
            s = line.strip()
            if not s:
                continue
            if s in DIMENSIONS:
                cur = s
                seeds[cur] = []
            elif cur:
                seeds[cur].extend(s.split())
    return seeds


def screen_documents(docs, tokenised, seeds, minseed):
    bag = {w for lst in seeds.values() for w in lst}
    keep_docs, keep_toks, dropped = [], [], 0
    for doc, toks in zip(docs, tokenised):
        if len(set(toks) & bag) >= minseed:
            keep_docs.append(doc)
            keep_toks.append(toks)
        else:
            dropped += 1
    return keep_docs, keep_toks, dropped


# --------------------------------------------------------------- NPMI score
def npmi_scores(tok_docs, index, df, seeds, lang, window=6, minco=5):
    """Seed-anchored normalised PMI expansion (distributional semantics)."""
    V = len(index)
    ntok = sum(len(d) for d in tok_docs)
    freq = np.zeros(V)
    for d in tok_docs:
        for t in d:
            freq[index[t]] += 1
    rr, cc = [], []
    for d in tok_docs:
        idx = np.array([index[t] for t in d], dtype=np.int64)
        for off in range(1, window + 1):
            if len(idx) <= off:
                break
            rr.append(idx[:-off])
            cc.append(idx[off:])
    if rr:
        rr = np.concatenate(rr)
        cc = np.concatenate(cc)
        C = sparse.coo_matrix((np.ones(rr.size, dtype=np.float32), (rr, cc)),
                              shape=(V, V)).tocsr()
        C = C + C.T
    else:
        C = sparse.csr_matrix((V, V), dtype=np.float32)
    P = float(C.sum()) or 1.0

    score = np.zeros((V, len(DIMENSIONS)))
    for r, dim in enumerate(DIMENSIONS):
        rows = []
        for w in seeds.get(dim, []):
            ww = normalise(w, lang)
            if ww in index:
                rows.append(index[ww])
        if not rows:
            continue
        sub = C[rows].toarray()                       # seeds x V
        ps = freq[rows] / max(ntok, 1)                # seed marginals
        pt = freq / max(ntok, 1)                      # term marginals
        with np.errstate(divide="ignore", invalid="ignore"):
            pst = sub / P
            npmi = np.log(pst / (ps[:, None] * pt[None, :])) / (-np.log(pst))
        npmi[sub < minco] = -np.inf
        npmi[~np.isfinite(npmi)] = -np.inf
        score[:, r] = np.nanmax(npmi, axis=0)
    return score


# ------------------------------------------------------------- k-means score
def kmeans_scores(tok_docs, index, terms, df, seeds, lang, topics):
    filtered = [" ".join(t for t in d) for d in tok_docs]
    vec = TfidfVectorizer(token_pattern=r"(?u)\S+", lowercase=False,
                          sublinear_tf=True, norm="l2")
    X = vec.fit_transform(filtered)
    vocab = list(vec.get_feature_names_out())
    pos = {t: i for i, t in enumerate(vocab)}
    Xt = X.T.tocsr()
    n_comp = int(min(80, max(2, min(Xt.shape) - 1)))
    svd = TruncatedSVD(n_components=n_comp, random_state=RANDOM_STATE)
    Zt = normalize(svd.fit_transform(Xt))
    k = max(2, topics)
    km = KMeans(n_clusters=k, n_init=10, random_state=RANDOM_STATE)
    lab = km.fit_predict(Zt)
    cent = normalize(np.vstack([Zt[lab == c].mean(axis=0) if np.any(lab == c)
                                else np.zeros(Zt.shape[1]) for c in range(k)]))
    seed_cent = np.zeros((4, Zt.shape[1]))
    present = 0
    for r, dim in enumerate(DIMENSIONS):
        rows = [pos[normalise(w, lang)] for w in seeds.get(dim, [])
                if normalise(w, lang) in pos]
        present += len(rows)
        if rows:
            seed_cent[r] = Zt[rows].mean(axis=0)
    if present == 0:
        return np.zeros((len(terms), 4)), 0, 0.0
    seed_cent = normalize(seed_cent)
    sim = cent @ seed_cent.T
    big = np.full((max(k, 4), max(k, 4)), -1e9)
    big[:k, :4] = sim
    row, col = linear_sum_assignment(-big)
    mapping = {int(r): DIMENSIONS[int(c)] for r, c in zip(row, col) if r < k and c < 4}
    for c in range(k):
        mapping.setdefault(int(c), DIMENSIONS[int(np.argmax(sim[c]))])
    dim_of_cluster = np.array([DIMENSIONS.index(mapping[c]) for c in range(k)])
    score = np.zeros((V_len := len(terms), 4))
    map_pos = np.array([pos.get(t, -1) for t in terms])
    ok = map_pos >= 0
    for r in range(4):
        hit = ok & (dim_of_cluster[lab[map_pos.clip(0)]] == r) & ok
        score[hit, r] = 1.0
    sem = np.zeros((len(terms), 4))
    sem[ok] = Zt[map_pos[ok]] @ seed_cent.T
    score = score + sem
    return score, k, float(svd.explained_variance_ratio_.sum())


# ------------------------------------------------------------------- main
def zscore(a):
    a = a.copy()
    a[~np.isfinite(a)] = -1e9
    m, s = a.mean(), a.std()
    if s > 0:
        a = (a - m) / s
    return a


def build(spec):
    lang = spec.get("lang", "cn")
    method = (spec.get("method", "npmi") or "npmi").lower()
    topics = int(spec.get("topics", 8))
    top = int(spec.get("top", 40))
    minfreq = int(spec.get("minfreq", 15))
    minseed = int(spec.get("minseed", 6))
    window = int(spec.get("window", 6))
    minco = int(spec.get("minco", 5))
    margin = float(spec.get("margin", 0.02))
    out = spec["out"]
    report = spec.get("report", "")

    docs = load_corpus(spec)
    if len(docs) < 2:
        raise SystemExit("corpus too small: %d document(s)" % len(docs))
    seeds = load_seeds(spec, lang)

    stop_extra, idf = set(), {}
    if lang == "cn":
        import jieba
        jieba.setLogLevel(60)
        stop_extra = _jieba_stopwords()
        idf = _jieba_idf()
        tokenised = [tokenize_cn(d, jieba, stop_extra) for d in docs]
    else:
        tokenised = [tokenize_en(d) for d in docs]
    say("Tokenised %d document(s); raw vocabulary = %d"
        % (len(docs), len({t for d in tokenised for t in d})))

    docs, tokenised, dropped = screen_documents(docs, tokenised, seeds, minseed)
    if dropped:
        say("Corpus screening: kept %d report(s), dropped %d low-ESG document(s)"
            % (len(docs), dropped))
    if len(docs) < 2:
        raise SystemExit("too few ESG reports survived screening (minseed=%d)" % minseed)

    df = {}
    for d in tokenised:
        for t in set(d):
            df[t] = df.get(t, 0) + 1
    maxdf = max(minfreq + 1, int(float(spec.get("maxdf", 0.90)) * len(docs)))
    vocab = sorted(t for t, c in df.items()
                   if minfreq <= c <= maxdf and t not in BLACKLIST)
    if len(vocab) < 20:
        raise SystemExit("vocabulary too small after pruning (%d terms)" % len(vocab))
    index = {t: i for i, t in enumerate(vocab)}
    say("Vocabulary after pruning (%d <= df <= %d) = %d terms"
        % (minfreq, maxdf, len(vocab)))

    filt_docs = [[t for t in d if t in index] for d in tokenised]
    weight = np.log1p(np.array([df[t] for t in vocab], dtype=float))
    if idf:
        med = float(np.median(list(idf.values())))
        iw = np.array([idf.get(t, med) for t in vocab], dtype=float)
        iw = np.clip(iw / (np.median(iw) or 1.0), 0.25, 4.0)
    else:
        iw = np.ones(len(vocab))

    scores = {}
    if method in ("npmi", "hybrid"):
        s = npmi_scores(filt_docs, index, df, seeds, lang, window, minco)
        scores["npmi"] = s
        say("NPMI co-occurrence model: window=%d, minco=%d" % (window, minco))
    if method in ("kmeans", "hybrid"):
        s, k, var = kmeans_scores(filt_docs, index, vocab, df, seeds, lang, topics)
        scores["kmeans"] = s
        say("LSA + k-means model: %d clusters, explained variance %.3f" % (k, var))
    if not scores:
        raise SystemExit("unknown method(): %s" % method)

    if len(scores) == 1:
        total = list(scores.values())[0]
    else:
        total = np.mean([zscore(v) for v in scores.values()], axis=0)

    # document-frequency / IDF weighting and dimension selection with margin
    total = total * weight[:, None] * iw[:, None]
    dedup = {d: [] for d in DIMENSIONS}
    chosen = {d: {} for d in DIMENSIONS}
    order = np.argsort(-np.nanmax(total, axis=1))
    for i in order:
        row = total[i]
        if not np.isfinite(row).any():
            break
        best = int(np.nanargmax(row))
        val = row[best]
        if val <= 0:
            break
        others = np.delete(row, best)
        others = others[np.isfinite(others)]
        if len(others) and val - others.max() < margin * max(abs(val), 1e-9):
            continue
        if len(dedup[DIMENSIONS[best]]) >= top:
            continue
        dedup[DIMENSIONS[best]].append(vocab[i])
        chosen[DIMENSIONS[best]][vocab[i]] = float(val)

    # optional cohesion filter: drop 2-character fragments of longer terms
    if str(spec.get("cohesion", "0")).lower() in ("1", "yes", "on", "true"):
        for dim in DIMENSIONS:
            lst = dedup[dim]
            frag = {x for x in lst if len(x) <= 2
                    and any(x != y and x in y for y in lst)}
            if frag:
                dedup[dim] = [x for x in lst if x not in frag]
                say("  cohesion filter removed %d fragment(s) from %s"
                    % (len(frag), dim))

    # always keep the curated seed terms that occur in the corpus
    for dim in DIMENSIONS:
        for w in seeds.get(dim, []):
            ww = normalise(w, lang)
            if ww in index and ww not in dedup[dim] and len(dedup[dim]) < top + 10:
                dedup[dim].append(ww)
                chosen[dim].setdefault(ww, float("nan"))

    with open(out, "w", encoding="utf-8") as fh:
        fh.write("# ESG dictionary generated by esgdict.ado (machine learning)\n")
        fh.write("# language=%s  method=%s  top=%d  minfreq=%d  window=%d  minco=%d\n"
                 % (lang, method, top, minfreq, window, minco))
        fh.write("# generated on 06 October 2026 by WU Lianghai, WU Hanyan, XU Huihui\n")
        for dim in DIMENSIONS:
            fh.write(dim + "\n")
            for t in dedup[dim]:
                fh.write(t + "\n")
    say("Dictionary written to %s" % out)
    for dim in DIMENSIONS:
        say("  %-14s %3d terms" % (dim, len(dedup[dim])))

    if report:
        with open(report, "w", encoding="utf-8-sig", newline="") as fh:
            w = csv.writer(fh)
            w.writerow(["dimension", "rank", "term", "document_frequency", "score"])
            for dim in DIMENSIONS:
                for i, t in enumerate(dedup[dim], 1):
                    w.writerow([dim, i, t, df.get(t, 0),
                                "" if np.isnan(chosen[dim].get(t, np.nan))
                                else round(chosen[dim][t], 6)])
        say("Term report written to %s" % report)

    return {"dimensions": {d: len(dedup[d]) for d in DIMENSIONS},
            "n_docs": len(docs), "n_dropped": dropped, "n_terms": len(vocab),
            "method": method}


def _parse_spec(path):
    spec = {}
    with open(path, encoding="utf-8-sig", errors="replace") as fh:
        for line in fh:
            line = line.rstrip("\r\n")
            if not line.strip() or line.lstrip().startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            spec[k.strip().lower()] = v.strip()
    return spec


def main():
    p = argparse.ArgumentParser(description="ML ESG dictionary builder")
    p.add_argument("--spec", required=True)
    a = p.parse_args()
    spec = _parse_spec(a.spec)
    out = spec.get("out", os.path.join(os.path.dirname(os.path.abspath(a.spec)),
                                       "esgdict.txt"))
    spec["out"] = out
    try:
        info = build(spec)
    except BaseException as exc:
        with open(out + ".status", "w", encoding="utf-8") as fh:
            fh.write("ERROR\n%s: %s" % (type(exc).__name__, exc))
        say("ERROR: %s: %s" % (type(exc).__name__, exc))
        raise
    with open(out + ".status", "w", encoding="utf-8") as fh:
        fh.write("OK\n" + json.dumps(info, ensure_ascii=False))


if __name__ == "__main__":
    main()
