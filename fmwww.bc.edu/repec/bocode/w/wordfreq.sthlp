{smcl}
{* *! version 1.0.0  06 October 2026}{...}
{hline}
help {bf:wordfreq}
{hline}

{viewerjumpto "Syntax" "wordfreq##syntax"}{...}
{viewerjumpto "Description" "wordfreq##description"}{...}
{viewerjumpto "Options" "wordfreq##options"}{...}
{viewerjumpto "Remarks" "wordfreq##remarks"}{...}
{viewerjumpto "Examples" "wordfreq##examples"}{...}
{viewerjumpto "Stored results" "wordfreq##results"}{...}
{viewerjumpto "Author" "wordfreq##author"}{...}

{title:Title}

{phang}
{bf:wordfreq} {hline 2} Bilingual (Chinese/English) keyword-frequency statistics for PDF report
corpora and for text already held in memory

{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmd:wordfreq} {cmd:[}{it:using}{cmd:]} {cmd:,} {cmd:keywords}({it:string}) {cmd:[}{it:options}{cmd:]}
{p_end}

{p 8 20 2}
{cmd:wordfreq} {cmd:,} {cmd:textvar}({it:varname}) {cmd:keywords}({it:string}) {cmd:[}{it:options}{cmd:]}
{p_end}

{p2colset 5 20 24 2}{...}
{p2col:{opt path(string)}}directory that holds the source documents; required unless {cmd:textvar()} is specified{p_end}
{p2col:{opt pattern(string)}}filename pattern used when scanning the directory; default {cmd:pattern("*.pdf")}{p_end}
{p2col:{opt keywords(string)}}comma-separated list of keywords; Chinese, English, or both{p_end}
{p2col:{opt kwfile(filename)}}text file holding one keyword per line (an alternative to {cmd:keywords()}){p_end}
{p2col:{opt language(cn|en)}}language of the corpus; default {cmd:language(cn)}{p_end}
{p2col:{opt textvar(varname)}}string variable in memory that holds the document text{p_end}
{p2col:{opt name(string)}}prefix for the new word-frequency variables; default {cmd:name(wordfreq)}{p_end}
{p2col:{opt normalize(#)}}additionally report frequency per {it:#} words (English) or characters (Chinese); default {cmd:normalize(0)}{p_end}
{p2col:{opt python(executable)}}Python executable to use{p_end}
{p2col:{opt script(filename)}}full path to the Python helper {cmd:wordfreq_pdf.py}{p_end}
{p2col:{opt cachedir(dirname)}}directory in which extracted text is cached{p_end}
{p2col:{opt workers(#)}}number of parallel Python workers; default {cmd:workers(4)}{p_end}
{p2col:{opt merge}}merge the result 1:1 into the data in memory by {cmd:stkcd} and {cmd:year}{p_end}
{p2col:{opt nosubdir}}do not search subdirectories of {cmd:path()}{p_end}
{p2col:{opt verbose}}display the Python command and let its output appear on screen{p_end}
{p2col:{opt replace}}overwrite {it:using} if it already exists{p_end}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{bf:wordfreq} counts how often each of a set of user-supplied keywords occurs in a corpus of
documents and returns one word-frequency variable per keyword, together with a total-frequency
variable.  Both Chinese and English are supported.

{pstd}
The command works in either of two modes.

{pstd}
In {bf:folder mode} ({cmd:path()} is specified) {bf:wordfreq} batches over every PDF (or plain
text) file found under a user-supplied directory, extracts the text of each document, counts the
keywords, and produces a dataset with one observation per document.  The output contains the
identifiers {cmd:stkcd} and {cmd:year}, recovered from the file name (for example
{cmd:000521_2023.pdf} yields {cmd:stkcd} = {cmd:"000521"} and {cmd:year} = {cmd:2023}), so the
results can be merged directly into a firm-year panel.  PDF extraction is performed by the Python
helper {cmd:wordfreq_pdf.py}, which sits next to {cmd:wordfreq.ado}; extracted text is cached, so
repeated runs are fast.

{pstd}
In {bf:variable mode} ({cmd:textvar()} is specified) the documents are already in memory as a
string variable, and the counting is done entirely inside Stata without Python.  This mode is
faster and is convenient when the report texts have already been imported into a panel dataset.

{pstd}
{bf:wordfreq} is designed to work with {help qta} (quantitative text analysis) and with
{help esgdict} (machine-learning ESG dictionary generation).

{marker options}{...}
{title:Options}

{phang}
{opt path(string)} specifies the directory in which the documents are stored.  It is required in
folder mode and is ignored in variable mode.  Unless {cmd:nosubdir} is specified the directory is
searched recursively.

{phang}
{opt pattern(string)} restricts the files that are read; the default is {cmd:"*.pdf"}.  Use, for
example, {cmd:pattern("*.txt")} to read text that has already been extracted.

{phang}
{opt keywords(string)} supplies the keywords, separated by commas.  Chinese and English keywords
may be mixed: {cmd:keywords("环境保护,碳排放,员工")} and
{cmd:keywords("environment,employee")} are both valid.

{phang}
{opt kwfile(filename)} reads the keywords from a text file instead, one keyword per line.  Blank
lines are ignored.  Keywords supplied through {cmd:kwfile()} are added to those given in
{cmd:keywords()}.

{phang}
{opt language(cn|en)} declares the language of the corpus.  {cmd:cn} (the default) counts literal
occurrences of the keyword string and divides by the number of characters; {cmd:en} lowercases the
text, matches whole words on word boundaries, and divides by the number of words.  The value is
also used to label the new variables.

{phang}
{opt textvar(varname)} names a string variable that contains the document text.  When it is
specified, {cmd:path()} is not required and Python is not used.

{phang}
{opt name(string)} sets the prefix of the new variables; the default is {cmd:wordfreq}.

{phang}
{opt normalize(#)} creates one additional variable holding the keyword frequency per {it:#} words
or characters, for example {cmd:normalize(1000)} for "per 1,000 words".  This removes the influence
of document length on the raw counts.  The default, {cmd:normalize(0)}, creates no such variable.

{phang}
{opt python(executable)} names the Python executable.  If it is not specified, the global macro
{cmd:$WORDFREQ_PYTHON} is used when it is defined, and {cmd:python} otherwise.

{phang}
{opt script(filename)} gives the full path to {cmd:wordfreq_pdf.py}.  By default the helper is
located with {helpb findfile}, so it is normally enough to keep it in the folder that holds
{cmd:wordfreq.ado} and to place that folder on the adopath.

{phang}
{opt cachedir(dirname)} sets the directory in which the extracted text of each document is cached.
By default a subdirectory of the temporary directory is used.  Pointing several runs at the same
cache avoids re-extracting unchanged documents.

{phang}
{opt workers(#)} sets the number of parallel Python processes used for extraction; the default is
4.

{phang}
{opt merge} merges the word-frequency variables 1:1 into the data currently in memory, using
{cmd:stkcd} and {cmd:year} as the key.  Both variables must exist in memory.  Available only in
folder mode.

{phang}
{opt nosubdir} restricts the scan to the files that lie directly in {cmd:path()}.

{phang}
{opt verbose} displays the Python command that is executed and lets the helper's messages appear on
the screen; by default the helper runs quietly.

{phang}
{opt replace} allows the dataset named in {it:using} to be overwritten.

{marker remarks}{...}
{title:Remarks}

{phang}
{bf:New variables.}  For {it:k} keywords the following variables are created:

{p2colset 5 20 24 2}{...}
{p2col:{it:name}{cmd:_1} ... {it:name}{cmd:_k}}frequency of each individual keyword, in the order in which the keywords were supplied{p_end}
{p2col:{it:name}}total frequency across all keywords{p_end}
{p2col:{it:name}{cmd:_per}}frequency per {it:#} words or characters (only if {cmd:normalize()} is greater than 0){p_end}
{p2colreset}{...}

{pstd}
In folder mode the output additionally contains {cmd:stkcd}, {cmd:year}, {cmd:filename},
{cmd:n_chars} (characters in the document) and {cmd:n_words} (words for {cmd:language(en)},
Chinese characters for {cmd:language(cn)}).

{phang}
{bf:File names.}  In folder mode {bf:wordfreq} recovers the firm identifier and the year from the
document name.  The preferred form is {cmd:000521_2023.pdf}, that is, a six-digit stock code and a
four-digit year separated by an underscore, hyphen or space.  If that pattern is not found,
{bf:wordfreq} falls back to the first six digits of the name and to the first four-digit number
starting with "20".

{phang}
{bf:Counting rules.}  With {cmd:language(cn)} the keyword is counted as a literal substring, so
overlapping occurrences and occurrences inside longer words are counted.  With
{cmd:language(en)} the text is lowercased and padded with spaces, and the keyword is counted only
on word boundaries, so {cmd:"employee"} does not match {cmd:"employees"}.  Supply the plural form
as an additional keyword if it should be counted.

{phang}
{bf:Requirements.}  Variable mode requires no external software.  Folder mode requires Python with
{cmd:pypdf} installed; {cmd:pdfminer.six} is used as a fallback for documents that {cmd:pypdf}
cannot read.  Install them with

{phang2}
{cmd:python -m pip install pypdf pdfminer.six}

{phang}
{bf:Error handling.}  The Python helper writes a side-car file named {it:output}{cmd:.status} whose
first line is {cmd:OK} on success.  {bf:wordfreq} checks that file, so a failed extraction is
reported as an error rather than as silently missing data.  If the helper produces nothing, run the
command again with {cmd:verbose} to see the Python error message, and check that the interpreter
named in {cmd:python()} is the one in which {cmd:pypdf} was installed.

{marker examples}{...}
{title:Examples}

{phang}
Count four keywords over every PDF under a folder, write the result to a dataset, and cache the
extracted text:

        {cmd:. wordfreq using "kwf_panel.dta", ///}
        {cmd:    path("E:/ESG_reports") ///}
        {cmd:    keywords("环境保护,碳排放,员工,董事会") ///}
        {cmd:    language(cn) cachedir("_cache_pdf") ///}
        {cmd:    workers(6) replace}

{phang}
Count keywords in reports that are already in memory:

        {cmd:. use esg_panel, clear}

        {cmd:. wordfreq, textvar(ESGreport) ///}
        {cmd:    keywords("环境保护,碳排放") name(wf)}

{phang}
Take the keywords from a file and report frequency per 1,000 characters:

        {cmd:. wordfreq using "kwf.dta", ///}
        {cmd:    path("E:/ESG_reports") ///}
        {cmd:    kwfile("keywords.txt") ///}
        {cmd:    normalize(1000) replace}

{phang}
Count English keywords, ignoring word fragments:

        {cmd:. wordfreq, textvar(report_en) ///}
        {cmd:    keywords("environment,employee,board") ///}
        {cmd:    language(en) name(enwf)}

{phang}
Use the result with {help qta} and {help esgdict} in the analysis pipeline:

        {cmd:. do "esg_qta_analysis.do"}

{marker results}{...}
{title:Stored results}

{phang}
{bf:wordfreq} stores the following in {cmd:r()}:

{p2colset 5 20 24 2}{...}
{p2col:{cmd:r(keywords)}}the keyword list, as supplied{p_end}
{p2col:{cmd:r(nkeywords)}}number of keywords{p_end}
{p2col:{cmd:r(language)}}{cmd:cn} or {cmd:en}{p_end}
{p2col:{cmd:r(nmatched)}}variable mode only: number of observations with a nonzero total frequency{p_end}
{p2col:{cmd:r(nobs)}}variable mode only: number of observations{p_end}
{p2col:{cmd:r(ndocs)}}folder mode only: number of documents processed{p_end}
{p2col:{cmd:r(varlist)}}name of the new total-frequency variable{p_end}
{p2colreset}{...}

{marker author}{...}
{title:Author}

{phang}
{bf:wordfreq} was written by

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
{help esgdict}, {help qta}

