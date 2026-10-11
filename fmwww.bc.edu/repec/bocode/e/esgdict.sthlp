{smcl}
{* *! version 1.0.0  06 October 2026}{...}
{hline}
help {bf:esgdict}
{hline}

{viewerjumpto "Syntax" "esgdict##syntax"}{...}
{viewerjumpto "Description" "esgdict##description"}{...}
{viewerjumpto "Options" "esgdict##options"}{...}
{viewerjumpto "Remarks" "esgdict##remarks"}{...}
{viewerjumpto "Examples" "esgdict##examples"}{...}
{viewerjumpto "Stored results" "esgdict##results"}{...}
{viewerjumpto "Author" "esgdict##author"}{...}

{title:Title}

{phang}
{bf:esgdict} {hline 2} Machine-learning generation of the built-in ESG dictionary that
{help qta} requires

{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmd:esgdict} {cmd:using} {it:filename} {cmd:[}{it:options}{cmd:]}
{p_end}

{p2colset 5 22 26 2}{...}
{p2col:{opt corpus(filename)}}CSV file holding the report corpus{p_end}
{p2col:{opt textcol(varname)}}name of the text column in {cmd:corpus()}; default {cmd:textcol(ESGreport)}{p_end}
{p2col:{opt textdir(dirname)}}directory of plain-text files to use as the corpus{p_end}
{p2col:{opt textvar(varname)}}string variable in memory holding the report text{p_end}
{p2col:{opt language(cn|en)}}language of the corpus; default {cmd:language(cn)}{p_end}
{p2col:{opt method(npmi|kmeans|hybrid)}}learning strategy; default {cmd:method(npmi)}{p_end}
{p2col:{opt topics(#)}}number of k-means clusters; default {cmd:topics(8)}{p_end}
{p2col:{opt top(#)}}number of terms kept per dimension; default {cmd:top(45)}{p_end}
{p2col:{opt minfreq(#)}}minimum corpus frequency for a candidate term; default {cmd:minfreq(15)}{p_end}
{p2col:{opt maxdf(#)}}maximum document frequency, as a proportion; default {cmd:maxdf(0.98)}{p_end}
{p2col:{opt minseed(#)}}minimum number of distinct seed words a document must contain to enter the corpus; default {cmd:minseed(6)}{p_end}
{p2col:{opt window(#)}}co-occurrence window, in tokens, used by NPMI; default {cmd:window(6)}{p_end}
{p2col:{opt minco(#)}}minimum co-occurrence count; default {cmd:minco(8)}{p_end}
{p2col:{opt margin(#)}}tie margin used when assigning a term to a dimension; default {cmd:margin(0.02)}{p_end}
{p2col:{opt seeds(filename)}}text file with user-supplied seed words{p_end}
{p2col:{opt cohesion}}drop short fragments that are contained in longer retained terms{p_end}
{p2col:{opt report(filename)}}write a term-by-term detail file{p_end}
{p2col:{opt maxchars(#)}}maximum number of characters read per document; default {cmd:maxchars(40000000)}{p_end}
{p2col:{opt python(executable)}}Python executable to use{p_end}
{p2col:{opt script(filename)}}full path to the Python helper {cmd:esgdict_ml.py}{p_end}
{p2col:{opt show}}display the generated dictionary on the screen{p_end}
{p2col:{opt verbose}}display the Python command and let its output appear on screen{p_end}
{p2col:{opt replace}}overwrite {it:filename} if it already exists{p_end}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{bf:esgdict} learns the built-in dictionary that {help qta} uses for its keyword-frequency,
cosine-similarity and Jaccard methods, instead of requiring the researcher to hard-code the
keywords.  It reads a corpus of environmental, social and governance (ESG) reports, screens the
documents, tokenises the text, and returns a dictionary file organised into the four dimensions
{cmd:Environmental}, {cmd:Social}, {cmd:Governance} and {cmd:General_ESG}.  The resulting file is
passed directly to {help qta} through its {cmd:esgdictionary()} option.

{pstd}
Three reproducible machine-learning strategies are available.

{p2colset 5 14 16 2}{...}
{p2col:{cmd:npmi}(default)}normalised point-wise mutual information seed expansion.  Every candidate term is scored by its co-occurrence with a curated seed vocabulary inside a sliding window, which is a distributional-semantics approach to lexicon expansion.{p_end}
{p2col:{cmd:kmeans}}latent semantic analysis followed by clustering.  A truncated singular value decomposition of the TF-IDF term space yields term vectors; k-means forms term clusters, and the clusters are matched to the four dimensions with a Hungarian assignment against the seed centroids.{p_end}
{p2col:{cmd:hybrid}}the average of the standardised {cmd:npmi} and {cmd:kmeans} scores.{p_end}
{p2colreset}{...}

{pstd}
The random seed is fixed, so the same corpus and the same options always produce the same
dictionary.

{marker options}{...}
{title:Options}

{phang}
{opt using(filename)} names the dictionary file to be written.  It must be supplied.  Because the
file is read by {help qta}, the conventional extension is {cmd:.txt}.

{phang}
{opt corpus(filename)} names a CSV file that holds the corpus.  It is one of the three ways of
supplying the text, the others being {cmd:textdir()} and {cmd:textvar()}.

{phang}
{opt textcol(varname)} names the column of {cmd:corpus()} that contains the report text.  The
default, {cmd:ESGreport}, matches the variable name used in the accompanying analysis do-file.

{phang}
{opt textdir(dirname)} takes the corpus from a directory of plain-text files, one document per
file.

{phang}
{opt textvar(varname)} takes the corpus from a string variable already in memory.  The variable is
exported to a temporary CSV file and the data in memory are left unchanged.

{phang}
{opt language(cn|en)} declares the language of the corpus.  {cmd:cn} (the default) segments Chinese
text with {cmd:jieba} and uses the built-in Chinese seed vocabulary; {cmd:en} uses whitespace
tokenisation and the built-in English seed vocabulary.

{phang}
{opt method(npmi|kmeans|hybrid)} selects the learning strategy; see {bf:Description} above.

{phang}
{opt topics(#)} sets the number of k-means clusters; the default is 8.  It is used only by
{cmd:method(kmeans)} and {cmd:method(hybrid)}.

{phang}
{opt top(#)} sets how many terms are kept for each of the four dimensions; the default is 45.  The
dictionary therefore holds at most {cmd:4} times {it:#} terms.

{phang}
{opt minfreq(#)} requires a candidate term to occur at least {it:#} times in the screened corpus;
the default is 15.  Raising it yields a shorter, more conservative dictionary.

{phang}
{opt maxdf(#)} drops terms that occur in more than this proportion of documents; the default is
0.98.  It removes near-ubiquitous words that carry little discriminating information.

{phang}
{opt minseed(#)} requires a document to contain at least {it:#} distinct seed words before it is
admitted to the corpus; the default is 6.  This is the corpus-screening rule that removes reports
which were retrieved by mistake and are not about ESG.

{phang}
{opt window(#)} sets the width, in tokens, of the co-occurrence window used by the NPMI scorer; the
default is 6.

{phang}
{opt minco(#)} requires a term to co-occur with the seeds at least {it:#} times before it is
scored; the default is 8.

{phang}
{opt margin(#)} sets how far a term's best dimension score must exceed the runner-up before the
term is assigned without ambiguity; the default is 0.02.  Raising it keeps the assignment more
conservative.

{phang}
{opt seeds(filename)} replaces the built-in seed vocabulary with one read from a text file.  The
file lists a dimension name on a line of its own, followed by the seed words for that dimension,
one line per dimension, for example

{phang2}
{cmd:Environmental}

{phang2}
{cmd:碳排放 环境保护 污染物}

{phang2}
{cmd:Social}

{phang2}
{cmd:员工 安全生产 公益}

{phang}
{opt cohesion} removes short terms that are merely fragments of longer retained terms, which
reduces redundancy in the dictionary.

{phang}
{opt report(filename)} writes a detail file with one observation per retained term, giving its
dimension, document frequency and association score.  This is the file to inspect when judging
dictionary quality.

{phang}
{opt maxchars(#)} caps the number of characters read from each document; the default is 40,000,000.
It guards against a few very long files dominating the corpus.

{phang}
{opt python(executable)} names the Python executable.  If it is not specified, the global macro
{cmd:$ESGDICT_PYTHON} is used when it is defined, and {cmd:python} otherwise.  The interpreter must
have {cmd:scikit-learn}, {cmd:scipy}, {cmd:numpy} and {cmd:pandas} installed, and {cmd:jieba} for
Chinese corpora.

{phang}
{opt script(filename)} gives the full path to {cmd:esgdict_ml.py}.  By default the helper is
located with {helpb findfile}, so it is normally enough to keep it in the folder that holds
{cmd:esgdict.ado} and to place that folder on the adopath.

{phang}
{opt show} prints the generated dictionary on the screen after it has been written.

{phang}
{opt verbose} displays the Python command that is executed and lets the helper's progress messages
appear on the screen.

{phang}
{opt replace} allows an existing dictionary file to be overwritten.

{marker remarks}{...}
{title:Remarks}

{phang}
{bf:Output format.}  The dictionary file is plain text.  Comment lines begin with {cmd:#}; the
four dimension names appear on lines of their own and are followed by one term per line.  A file
begins, for example, as follows:

{phang2}
{cmd:# ESG dictionary generated by esgdict.ado (machine learning)}

{phang2}
{cmd:# language=cn  method=npmi  top=45  minfreq=15  window=6  minco=8}

{phang2}
{cmd:# generated on 06 October 2026 by WU Lianghai, WU Hanyan, XU Huihui}

{phang2}
{cmd:Environmental}

{phang2}
{cmd:氮氧化物}

{phang2}
{cmd:废弃物}

{phang}
{bf:Using the dictionary.}  Pass the file to {help qta}:

{phang2}
{cmd:. qta, method(kwf) language(cn) esgdictionary("esgdict_cn.txt")}

{phang}
{bf:Inspection.}  Always inspect the {cmd:report()} output before using a dictionary in
estimation.  Automatic learning captures industry-specific terminology that a hand-made list
misses, but the semantic purity of the terms still depends on the quality of the corpus, so the
result should be checked against expert judgement.

{phang}
{bf:Reproducibility.}  The random seed is fixed at 2026, so the same corpus and the same options
always yield the same dictionary.  To check reproducibility, re-run the command with
{cmd:replace} and compare the two files.

{phang}
{bf:Error handling.}  The helper writes a side-car file named {it:filename}{cmd:.status}.  Its first
line is {cmd:OK} on success and the second line summarises the run; otherwise it reports the
failure.  When the helper produces nothing, run the command again with {cmd:verbose} to see the
Python error message.

{marker examples}{...}
{title:Examples}

{phang}
Learn a Chinese dictionary from a corpus held in a CSV file, and write the term detail:

        {cmd:. esgdict using "esgdict_cn.txt", ///}
        {cmd:    corpus("ESG_text_data.csv") ///}
        {cmd:    textcol(ESGreport) language(cn) ///}
        {cmd:    method(npmi) topics(8) top(45) ///}
        {cmd:    minfreq(15) maxdf(0.98) minseed(6) ///}
        {cmd:    window(6) minco(8) verbose ///}
        {cmd:    report("esgdict_cn_terms.csv") replace}

{phang}
Learn a dictionary from text that is already in memory:

        {cmd:. use esg_text, clear}

        {cmd:. esgdict using "esgdict_cn.txt", ///}
        {cmd:    textvar(ESGreport) replace}

{phang}
Use the k-means strategy, or the hybrid strategy, and display the result:

        {cmd:. esgdict using "esgdict_kmeans.txt", ///}
        {cmd:    corpus("ESG_text_data.csv") ///}
        {cmd:    method(kmeans) topics(10) show replace}

        {cmd:. esgdict using "esgdict_hybrid.txt", ///}
        {cmd:    corpus("ESG_text_data.csv") ///}
        {cmd:    method(hybrid) top(60) replace}

{phang}
Generate the dictionary and immediately use it with {help qta}:

        {cmd:. qta, method(kwf) language(cn) ///}
        {cmd:    esgdictionary("esgdict_cn.txt")}

{marker results}{...}
{title:Stored results}

{phang}
{bf:esgdict} stores the following in {cmd:r()}:

{p2colset 5 20 24 2}{...}
{p2col:{cmd:r(dictionary)}}path of the dictionary file that was written{p_end}
{p2col:{cmd:r(method)}}{cmd:npmi}, {cmd:kmeans} or {cmd:hybrid}{p_end}
{p2col:{cmd:r(language)}}{cmd:cn} or {cmd:en}{p_end}
{p2col:{cmd:r(n_env)}}number of {cmd:Environmental} terms{p_end}
{p2col:{cmd:r(n_soc)}}number of {cmd:Social} terms{p_end}
{p2col:{cmd:r(n_gov)}}number of {cmd:Governance} terms{p_end}
{p2col:{cmd:r(n_gen)}}number of {cmd:General_ESG} terms{p_end}
{p2colreset}{...}

{marker author}{...}
{title:Author}

{phang}
{bf:esgdict} was written by

{phang2}
WU Lianghai, School of Business, Anhui University of Technology (AHUT),
Ma'anshan, Anhui, China, {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}

{phang2}
WU Hanyan, Department of Accountancy, City University of Hong Kong (CityU),
{browse "mailto:2325476320@qq.com":2325476320@qq.com}

{phang2}
XU Huihui, School of Business, Anhui University of Technology (AHUT),
Ma'anshan, Anhui, China, {browse "mailto:2847844621@qq.com":2847844621@qq.com}

{phang}
Version 1.0.0, 6 October 2026.

{marker alsosee}{...}
{title:Also see}

{pstd}
{help wordfreq}, {help qta}

