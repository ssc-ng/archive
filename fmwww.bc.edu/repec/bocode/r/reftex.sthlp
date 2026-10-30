{smcl}
{* *! reftex help revision 28oct2026}{...}
{vieweralsosee "getref" "help getref"}{...}
{vieweralsosee "get2ref" "help get2ref"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "art2tex" "help art2tex"}{...}
{vieweralsosee "case2tex" "help case2tex"}{...}
{vieweralsosee "mysuite" "help mysuite"}{...}
{viewerjumpto "Syntax" "reftex##syntax"}{...}
{viewerjumpto "Description" "reftex##description"}{...}
{viewerjumpto "Options" "reftex##options"}{...}
{viewerjumpto "Input formats" "reftex##input"}{...}
{viewerjumpto "Deduplication" "reftex##dedupe"}{...}
{viewerjumpto "Output and integration" "reftex##integration"}{...}
{viewerjumpto "Compiling" "reftex##compile"}{...}
{viewerjumpto "Stored results" "reftex##results"}{...}
{viewerjumpto "Troubleshooting" "reftex##troubleshooting"}{...}
{viewerjumpto "Authors" "reftex##authors"}{...}
{p2colset 1 15 17 2}{...}
{p2col:{bf:reftex} {hline 2}}Convert plain-text references to LaTeX or BibTeX{p_end}
{p2col:}({help mysuite:Part of the mysuite program suite}){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:reftex} {cmd:using} {it:filename} , {cmd:outfile(}{it:file}{cmd:)}
{break}
        [{cmd:format(}{it:tex|bib}{cmd:)}
         {cmd:lang(}{it:chn|eng|mix}{cmd:)}
         {opt replace} | {opt nodedupe} | {opt noescape} | {opt debug}]
{break}
{cmd:saving(}{it:file}{cmd:)} may be used as an alias for {cmd:outfile(}{it:file}{cmd:)}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:reftex} converts a plain-text bibliography, such as a CNKI{break}
reference export, into a file that LaTeX can use directly.{break}
It removes duplicated records, escapes LaTeX special{break}
characters, creates stable citation keys, and writes either{break}
a complete {cmd:thebibliography} environment or a BibTeX database.

{pstd}
The default output format follows the output extension. A{break}
file ending in {cmd:.bib} produces BibTeX; all other names produce{break}
a LaTeX {cmd:thebibliography} file. Use {cmd:format()} to override the{break}
extension.

{pstd}
The input may use numbered CNKI entries such as {cmd:[1]}, {cmd:【1】},{break}
{cmd:1.}, or {cmd:1、}. Continuation lines are joined to the current{break}
entry. If no numbering is present, each nonblank line is{break}
treated as one reference.

{pstd}
{cmd:reftex} does not invent authors, years, journals, pages, or{break}
DOIs. It normalizes text from the supplied export. The{break}
output header records the number of source entries,{break}
duplicates removed, and records written.


{marker options}{...}
{title:Options}

{phang}
{opt outfile(file)} specifies the output file and is required.{break}
{cmd:saving(file)} is an equivalent alias.

{phang}
{opt format(tex|bib)} selects the output format. {opt format(tex)}{break}
writes a complete {cmd:thebibliography} environment. {opt format(bib)}{break}
writes BibTeX records for natbib, BibTeX, {cmd:art2tex}, {cmd:case2tex},{break}
{cmd:getref}, and {cmd:get2ref}.

{phang}
{opt lang(chn|eng|mix)} controls the presentation of TeX entries.{break}
The default is {opt lang(chn)}. {opt lang(eng)} uses an English{break}
presentation. {opt lang(mix)} detects Chinese characters in each{break}
entry and formats Chinese and English entries accordingly.{break}
BibTeX fields are language-neutral; the option does not{break}
translate text.

{phang}
{opt replace} permits replacement of an existing output file. The{break}
new file is prepared first and published after successful{break}
conversion. Without {opt replace}, an existing file is not{break}
changed.

{phang}
{opt nodedupe} disables deduplication. By default, duplicates are{break}
identified by DOI and by normalized title and year. The{break}
first occurrence in the source file is retained.

{phang}
{opt noescape} preserves input exactly instead of applying LaTeX{break}
escaping. Use it only when the text is already valid LaTeX.

{phang}
{opt debug} displays each parsed entry, detected type, year,{break}
title, duplicate decisions, and generated citation key.


{marker input}{...}
{title:Input formats}

{pstd}
A numbered entry may be written on one line:

{phang2}
{cmd:[1] 张三,李四. 数字化转型与企业绩效[J]. 管理世界, 2023, 39(1): 1-20.}

{pstd}
It may also continue across several lines. Lines after the{break}
numbered line are joined with spaces until the next number{break}
is found. Text before the first numbered entry is ignored.

{pstd}
An unnumbered file is supported when each reference occupies{break}
one nonblank line. Blank lines are ignored.

{pstd}
Recognized publication-type markers include {cmd:[J]} for journal{break}
articles, {cmd:[M]} for books, {cmd:[C]} for conference papers, {cmd:[D]} for{break}
dissertations, and {cmd:[R]} for reports. Other forms are retained{break}
as misc entries.


{marker dedupe}{...}
{title:Deduplication}

{pstd}
Deduplication runs in two independent passes. First, records{break}
with the same normalized DOI are treated as duplicates.{break}
Second, records with the same normalized title and year are{break}
treated as duplicates. This catches repeated exports even{break}
when one copy contains a DOI and another does not.

{pstd}
Title normalization ignores case, whitespace, and{break}
punctuation. The first record in input order is retained.{break}
The command reports the number removed in {cmd:r(n_duplicates)}{break}
and in the output header. Use {opt nodedupe} when distinct{break}
versions with the same title and year must be retained.


{marker integration}{...}
{title:Output and integration}

{pstd}
{bf:LaTeX thebibliography.} The {cmd:tex} output contains a full{break}
{cmd:thebibliography} environment. Add it near the end of the{break}
document with {cmd:\input{cnki_refs.tex}} and cite one of the{break}
keys returned in {cmd:r(keys)}.

{pstd}
{bf:BibTeX.} The {cmd:bib} output contains standard records and can be{break}
used directly by {cmd:art2tex}, {cmd:case2tex}, natbib, {cmd:getref}, and{break}
{cmd:get2ref}. The command creates readable author, title,{break}
journal, year, volume, number, pages, and DOI fields when{break}
they can be identified.

{pstd}
For a CNKI bibliography that accompanies a Crossref library:

{phang2}
{cmd:. reftex using "cnki.txt", outfile("cnki.bib") format(bib) lang(mix) replace}

{phang2}
{cmd:. get2ref, saving("references.bib") doifile("dois.txt") replace}

{pstd}
In the LaTeX document, use either separate databases{break}
{cmd:\bibliography{references,cnki}} or one combined{break}
database. To combine them, create {cmd:references.bib} with {cmd:reftex}{break}
and then add Crossref records with {cmd:get2ref ..., append}. The{break}
{cmd:reftex} header is preserved when {cmd:get2ref} appends.

{pstd}
Citation keys are deterministic. An English first author{break}
uses the Latin surname plus year, for example {cmd:smith2022}. A{break}
Chinese-only author uses {cmd:ref} plus the retained record number{break}
and year, for example {cmd:ref00012023}. Keys are made unique by a{break}
numeric suffix when necessary.

{pstd}
Special characters including {cmd:\}, {cmd:&}, {cmd:\%}, {cmd:\$}, {cmd:\#}, {cmd:\_}, braces,{break}
tilde, and caret are escaped as LaTeX text. DOI underscores{break}
are preserved inside BibTeX DOI fields so duplicate{break}
detection remains reliable. Load {cmd:url} when using plainnat{break}
BibTeX output.


{marker compile}{...}
{title:Compiling the bibliography}

{pstd}
Use XeLaTeX for Chinese text. A minimal preamble is:

{phang2}
{cmd:\documentclass[UTF8]{ctexart}}

{phang2}
{cmd:\usepackage[round]{natbib}}

{phang2}
{cmd:\usepackage{url}}

{pstd}
For the direct {cmd:tex} route, place the generated bibliography{break}
near the end of the document:

{phang2}
{cmd:\input{cnki_refs.tex}}

{pstd}
For the BibTeX route, use:

{phang2}
{cmd:\bibliographystyle{plainnat}}

{phang2}
{cmd:\bibliography{references,cnki}}

{pstd}
Compile the direct TeX route twice:

{phang2}
{cmd:xelatex paper.tex}

{phang2}
{cmd:xelatex paper.tex}

{pstd}
Compile the BibTeX route in this order:

{phang2}
{cmd:xelatex paper.tex}

{phang2}
{cmd:bibtex paper}

{phang2}
{cmd:xelatex paper.tex}

{phang2}
{cmd:xelatex paper.tex}

{pstd}
If {cmd:latexmk} is installed, use {cmd:latexmk -xelatex paper.tex}.{break}
Recompile when citation keys or the bibliography file{break}
change.


{marker examples}{...}
{title:Examples}

{pstd}
Create a direct LaTeX bibliography:

{phang2}
{cmd:. reftex using "cnki.txt", outfile("cnki_refs.tex") lang(mix) replace}

{pstd}
Create a BibTeX library for natbib:

{phang2}
{cmd:. reftex using "cnki.txt", saving("cnki.bib") format(bib) lang(mix) replace}

{pstd}
Inspect citation keys and conversion counts:

{phang2}
{cmd:. return list}

{pstd}
Keep all records, including apparent duplicates:

{phang2}
{cmd:. reftex using "cnki.txt", outfile("all.tex") nodedupe replace}

{pstd}
Use an input whose LaTeX characters have already been{break}
escaped:

{phang2}
{cmd:. reftex using "escaped.txt", outfile("escaped.tex") noescape replace}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:reftex} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 19 2: Scalars}{p_end}
{synopt:{cmd:r(n_input)}}number of parsed source entries{p_end}
{synopt:{cmd:r(n)}}number of bibliography entries written{p_end}
{synopt:{cmd:r(n_duplicates)}}number of duplicate entries removed{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 19 2: Macros}{p_end}
{synopt:{cmd:r(keys)}}space-separated generated citation keys{p_end}
{synopt:{cmd:r(outfile)}}output file{p_end}
{synopt:{cmd:r(format)}}selected format: {cmd:tex} or {cmd:bib}{p_end}
{synopt:{cmd:r(lang)}}selected language mode{p_end}
{synopt:{cmd:r(escape)}}escape mode: {cmd:latex} or {cmd:none}{p_end}
{p2colreset}{...}


{marker integrity}{...}
{title:Research integrity}

{pstd}
Deduplication reduces accidental repetition; it does not{break}
decide which version of a work was read. Escaping makes text{break}
portable; it does not verify bibliographic accuracy. Before{break}
submission, check authors, title, journal, year, volume,{break}
issue, pages, DOI, publication version, and the full text.

{pstd}
Respect database and publisher terms. These habits express{break}
the Dingyuan Accounting commitment to{break}
{bf:scientific rigor and humanistic goodwill}: reliable records{break}
for readers, transparent work for collaborators, and careful{break}
stewardship of the scholarly record.


{marker troubleshooting}{...}
{title:Troubleshooting}

{phang}
{bf:No entries were found.} Check that each reference begins with{break}
one of the accepted numbers or place one reference on each{break}
nonblank line. Use {opt debug} to inspect parsing.

{phang}
{bf:Citation undefined.} Use a key listed by {cmd:return list}. For{break}
BibTeX, run XeLaTeX, BibTeX, and XeLaTeX twice. Check that{break}
the bibliography file name matches
{cmd:\bibliography}{cmd:(filename)}.

{phang}
{bf:LaTeX reports underscore or hash errors in DOI output.} Load{break}
{cmd:\usepackage{url}} in the document preamble, then{break}
regenerate the BibTeX file. Current {cmd:art2tex} and{break}
{cmd:case2tex} templates provide URL support.

{phang}
{bf:Chinese characters do not render.} Compile with XeLaTeX and{break}
use a Chinese-capable class or package, such as {cmd:ctexart}.

{phang}
{bf:Distinct versions were removed.} Re-run with {opt nodedupe}, or{break}
keep the versions in separate source files.

{phang}
{bf:Output exists.} Use {opt replace}, or choose a new file name.

{phang}
{bf:Text is double-escaped.} Remove {opt noescape} when the input{break}
contains ordinary plain text. Use {opt noescape} only for text{break}
that already contains valid LaTeX commands.


{marker authors}{...}
{title:Authors}

{pstd}
Wu Lianghai
{break}
School of Business, Anhui University of Technology (AHUT)
{break}
Ma'anshan, China
{break}
E-mail: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}

{pstd}
Wu Hanyan
{break}
School of Economics and Management, Nanjing University of
Aeronautics and Astronautics (NUAA)
{break}
Nanjing, China
{break}
E-mail: {browse "mailto:2325476320@qq.com":2325476320@qq.com}

{pstd}
Chen Liwen
{break}
School of Business, Anhui University of Technology (AHUT)
{break}
Ma'anshan, China
{break}
E-mail: {browse "mailto:2184844526@qq.com":2184844526@qq.com}

{pstd}
Program version: 10.0
{break}
Help revision: October 28, 2026
{break}
Dingyuan Accounting: Scientific rigor and humanistic goodwill


{marker alsosee}{...}
{title:Also see}

{pstd}
{help getref}, {help get2ref}, {help art2tex}, {help case2tex}, {help mysuite}

{*}
