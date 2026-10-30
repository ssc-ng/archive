{smcl}
{* *! get2ref help revision 28oct2026}{...}
{vieweralsosee "getref" "help getref"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "art2tex" "help art2tex"}{...}
{vieweralsosee "case2tex" "help case2tex"}{...}
{vieweralsosee "mysuite" "help mysuite"}{...}
{viewerjumpto "Syntax" "get2ref##syntax"}{...}
{viewerjumpto "Description" "get2ref##description"}{...}
{viewerjumpto "Options" "get2ref##options"}{...}
{viewerjumpto "Unique value and use cases" "get2ref##usecases"}{...}
{viewerjumpto "Examples" "get2ref##examples"}{...}
{viewerjumpto "Stored results" "get2ref##results"}{...}
{viewerjumpto "Limitations" "get2ref##limitations"}{...}
{viewerjumpto "Authors" "get2ref##authors"}{...}
{p2colset 1 15 17 2}{...}
{p2col:{bf:get2ref} {hline 2}}Build verified bibliography libraries for papers and teams{p_end}
{p2col:}({help mysuite:Part of the mysuite program suite}){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:get2ref} [{it:query}] , {cmd:saving(}{it:filename}{cmd:)}
{break}
        [{cmd:format(}{it:bib|tex|txt|ris}{cmd:)}
         {cmd:replace} | {cmd:append}
{break}
         {cmd:language(}{it:english|chinese}{cmd:)}
         {cmd:source(}{it:crossref}{cmd:)}
{break}
         {cmd:n(}{it:#}{cmd:)}
         {cmd:yearfrom(}{it:yyyy}{cmd:)}
         {cmd:yearto(}{it:yyyy}{cmd:)}
{break}
         {cmd:doi(}{it:doi-list}{cmd:)}
         {cmd:doifile(}{it:filename}{cmd:)}
{break}
         {cmd:email(}{it:address}{cmd:)}
         {cmd:sortby(}{it:field}{cmd:)}
{break}
         {cmd:type(}{it:record-type}{cmd:)}
         {cmd:audit(}{it:filename}{cmd:)}
         {cmd:noaudit}
         {cmd:verbose}]

{pstd}
{it:query} is a topic or bibliographic search phrase. Use {cmd:doi()}{break}
or {cmd:doifile()} for exact DOIs. Input methods can be combined:{break}
exact DOI values receive priority, and a query fills any{break}
remaining slots allowed by {cmd:n()}. If the exact DOI count{break}
reaches {cmd:n()}, no query is sent.


{marker description}{...}
{title:Description}

{pstd}
{cmd:get2ref} is the batch front end to {help getref}. It accepts a{break}
query, exact DOIs, or a DOI file, then delegates validation,{break}
Crossref retrieval, duplicate detection, citation-key{break}
generation, and file writing to the same verified core used{break}
by {cmd:getref}.

{pstd}
The added value is project-scale organization. A DOI list{break}
can be stored as the reviewed input for a paper or seminar,{break}
combined with a topic query when more records are needed,{break}
and appended in later batches without duplicating entries.{break}
The output can be used by {help art2tex}, {help case2tex}, natbib, BibTeX,{break}
or a reference manager through RIS.

{pstd}
No records are simulated. A successful output record has a{break}
Crossref-registered DOI and is accompanied by provenance{break}
information. A DOI and its Crossref metadata identify a{break}
publication, but they do not replace reading the work or{break}
judging whether it supports a research claim.


{marker options}{...}
{title:Options}

{phang}
{opt saving(filename)} specifies the required output file. For a{break}
LaTeX project, the usual value is {cmd:saving("references.bib")}.

{phang}
{opt format(bib|tex|txt|ris)} selects the output format. The{break}
default is {opt format(bib)}, the preferred format for {cmd:art2tex},{break}
{cmd:case2tex}, natbib, and BibTeX. {opt format(tex)} creates {cmd:\bibitem}{break}
fragments for an existing {cmd:thebibliography} environment.{break}
{opt format(txt)} creates a human-readable list. {opt format(ris)}{break}
creates records for import into Zotero, EndNote, or another{break}
reference manager.

{phang}
{opt replace} replaces an existing output file. The target is left{break}
unchanged when no record can be retrieved. When retrieval{break}
partly succeeds, the successful records are published{break}
together, failed DOIs are reported, and {cmd:r(n)} counts only the{break}
records written.

{phang}
{opt append} adds records to an existing bibliography and skips{break}
DOI values that are already present. The existing file{break}
should use the same format as the new batch. When every{break}
requested record is already present, the command exits{break}
normally with {cmd:r(n) = 0}, reports the number skipped, and{break}
leaves existing entries unchanged. {opt replace} and {opt append} are{break}
mutually exclusive. A getref/get2ref provenance header is normalized to{break}
{cmd:get2ref v4.1} even when all records are skipped.

{phang}
{opt language(english|chinese)} controls the prose style of{break}
plain-text entries and the formatting of LaTeX entries. The{break}
default is {opt language(english)}. It does not translate a{break}
Crossref query.

{phang}
{opt source(crossref)} selects Crossref, the only supported search{break}
and metadata source in this version. For a work found in{break}
CNKI, a publisher site, or another licensed database, verify{break}
its DOI and supply it through {cmd:doi()} or {cmd:doifile()}.

{phang}
{opt n(#)} limits all DOI records processed in the run to an{break}
integer from 1 through 100. The default is 10. The limit{break}
applies to inline DOIs, DOI-file values, and query results.

{phang}
{opt yearfrom(yyyy)} and {opt yearto(yyyy)} restrict publication dates{break}
for a topic query. The defaults are 2000 and 2026. Explicit{break}
DOI records are not filtered by year.

{phang}
{opt doi(doi-list)} supplies exact DOIs. Separate values with a{break}
semicolon, comma, space, or vertical bar. Duplicate DOI{break}
values are removed.

{phang}
{opt doifile(filename)} reads DOIs from a text or CSV file. In a{break}
CSV file, put the DOI in the first column. A text line may{break}
contain a DOI by itself, a {cmd:doi:} prefix, a DOI URL, or a DOI{break}
embedded in other text. Blank lines and lines beginning with{break}
{cmd:#} are ignored. For unusual punctuation or careful team{break}
review, put one raw DOI on each line.

{phang}
{opt email(address)} identifies the requester to Crossref so that{break}
requests can be assigned to its polite pool. The address is{break}
not written to the bibliography.

{phang}
{opt sortby(field)} controls query-result ordering. The available{break}
fields are {opt relevance}, {opt published}, {opt cited}, {opt updated}, and{break}
{opt deposited}. The default is {opt relevance}. Sorting does not apply{break}
to the order of explicit DOI input.

{phang}
{opt type(record-type)} restricts query results by Crossref work{break}
type. Available values are {opt journal-article},{break}
{opt proceedings-article}, {opt book-chapter}, {opt book}, and {opt any}. The{break}
default is {opt journal-article}; {opt any} disables the type filter.

{phang}
{opt audit(filename)} writes the provenance audit to a custom CSV{break}
file. By default, the audit uses the bibliography stem plus{break}
{cmd:_audit.csv}; for example, {cmd:references.bib} produces{break}
{cmd:references_audit.csv}.

{phang}
{opt noaudit} suppresses the provenance audit.

{phang}
{opt verbose} reports each verified, skipped, or failed record.


{marker usecases}{...}
{title:Unique value and use cases}

{pstd}
{cmd:get2ref} is designed for bibliography assembly rather than{break}
one-off lookup. It turns a reviewed DOI inventory into a{break}
reproducible reference library, while retaining the direct{break}
query route when a topic search is still needed.

{phang2}
{bf:Team DOI intake.} A coauthor, research assistant, or seminar{break}
group can review a plain-text or CSV DOI list before the{break}
write step. Everyone works from the same input file, and one{break}
command converts that reviewed list into a bibliography with{break}
an audit trail.

{phang2}
{bf:Multi-paper projects.} A lab can maintain separate{break}
{cmd:references.bib} files for papers that share a literature{break}
domain. Appending later batches skips DOIs already in the{break}
relevant library, so repeated updates do not create{break}
duplicate entries.

{phang2}
{bf:Mixed curated and exploratory retrieval.} A researcher can{break}
place confirmed core references in {cmd:doi()} or {cmd:doifile()} and{break}
add a query that fills the remaining part of {cmd:n()}. Exact{break}
references are retained first, while the query broadens{break}
coverage under the same provenance policy.

{phang2}
{bf:Long-paper and case-study assembly.} The command creates the{break}
bibliography consumed by {cmd:art2tex} or {cmd:case2tex}, with stable{break}
citation keys and transaction-safe writes. This reduces the{break}
gap between a literature matrix, a LaTeX manuscript, and a{break}
coauthor's local reference library.

{pstd}
Relative to {help getref}, {cmd:get2ref} is the better choice when the{break}
DOI list is itself an input artifact, when files are handed{break}
between people, or when a library must be updated in{break}
repeated batches. {cmd:getref} remains the simpler choice for a{break}
single DOI or a small set typed directly into the command.


{marker examples}{...}
{title:Examples}

{pstd}
Create an empirical-paper framework and replace its example{break}
bibliography:

{phang2}
{stata `"art2tex, filename("paper") replace"'}{p_end}

{phang2}
{stata `"get2ref "ESG performance and firm value", saving("references.bib") replace n(20) yearfrom(2018) yearto(2026) email("name@example.com")"'}{p_end}

{pstd}
Create a case-study framework and build its bibliography{break}
from reviewed DOIs:

{phang2}
{stata `"case2tex, filename("case_study") replace"'}{p_end}

{phang2}
For example, save {cmd:case_dois.txt} with one DOI per line:

{pin}
10.1257/aer.109.4.1197
{break}
10.1002/csr.2218

{phang2}
{stata `"get2ref, saving("references.bib") doifile("case_dois.txt") replace n(2) email("name@example.com")"'}{p_end}

{pstd}
Retrieve two known works directly:

{phang2}
{stata `"get2ref, saving("references.bib") doi("10.1257/aer.109.4.1197; 10.1002/csr.2218") replace n(2)"'}{p_end}

{pstd}
Combine confirmed DOIs with a query that fills the remaining{break}
slots:

{phang2}
{stata `"get2ref "corporate governance", saving("references.bib") doi("10.1257/aer.109.4.1197") replace n(10) yearfrom(2020)"'}{p_end}

{pstd}
Add another literature batch later:

{phang2}
{stata `"get2ref "corporate governance", saving("references.bib") append n(10) yearfrom(2020)"'}{p_end}

{pstd}
Sort query results by Crossref citation count:

{phang2}
{stata `"get2ref "corporate social responsibility", saving("csr.bib") replace n(30) yearfrom(2015) sortby(cited) type(journal-article)"'}{p_end}

{pstd}
Create RIS output for Zotero:

{phang2}
{stata `"get2ref "ESG performance", saving("esg.ris") format(ris) replace n(20)"'}{p_end}

{pstd}
Inspect the returned values:

{phang2}
{cmd:. return list}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:get2ref} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 19 2: Scalars}{p_end}
{synopt:{cmd:r(n)}}number of new records written in this run; can be 0 when
all requested records were skipped{p_end}
{synopt:{cmd:r(skipped)}}number of DOIs skipped because they were already
present{p_end}
{synopt:{cmd:r(n_doi_file)}}number of unique DOI values extracted from
{cmd:doifile()}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 19 2: Macros}{p_end}
{synopt:{cmd:r(keys)}}space-separated citation keys of new records{p_end}
{synopt:{cmd:r(key)}}citation key of the first new record; empty when no record
was added{p_end}
{synopt:{cmd:r(saving)}}requested output path{p_end}
{synopt:{cmd:r(audit)}}audit path; empty with {cmd:noaudit}{p_end}
{synopt:{cmd:r(route)}}verification route; {cmd:crossref-verified}{p_end}
{p2colreset}{...}


{marker formats}{...}
{title:Output formats}

{phang}
{bf:BibTeX.} Writes a standard multi-line entry using Crossref{break}
metadata. Citation keys contain lowercase letters and{break}
digits. The DOI field contains the registered identifier,{break}
and the URL field uses {cmd:https://doi.org/}.

{phang}
{bf:TeX.} Writes {cmd:\bibitem} entries containing the available{break}
author, title, journal, year, volume, issue, pages, and DOI{break}
fields. These are fragments for an existing {cmd:thebibliography}{break}
environment; BibTeX output is preferable for {cmd:art2tex} and{break}
{cmd:case2tex}.

{phang}
{bf:Plain text.} Builds a readable entry from the RIS metadata.{break}
English entries follow an author-year structure; Chinese{break}
entries use the core field order of GB/T 7714. This is a{break}
compact readable output, not a full bibliographic-style{break}
validation tool.

{phang}
{bf:RIS.} Writes the RIS representation obtained from the{break}
Crossref DOI record. Legacy {cmd:http://dx.doi.org/} links are{break}
normalized to {cmd:https://doi.org/}.


{marker limitations}{...}
{title:Limitations and research practice}

{pstd}
Crossref metadata can contain abbreviated names,{break}
inconsistent capitalization, missing volume or issue fields,{break}
publication-date differences, or character-conversion{break}
problems. Before final submission, check the DOI, authors,{break}
title, journal, volume, issue, pages, publisher, publication{break}
version, and full text.

{pstd}
Use the command to build traceable bibliography records, not{break}
as evidence that a paper makes a particular claim. Respect{break}
database licenses, publisher terms, and the version actually{break}
read. Do not treat a working paper, preprint, and published{break}
version as interchangeable.

{pstd}
The former simulation modes have been removed. Earlier{break}
versions generated random authors, journals, pages, and{break}
DOI-like strings that could be mistaken for real literature.{break}
The current command reports retrieval failure rather than{break}
producing a false record.

{pstd}
Crossref is the only supported retrieval source. CNKI,{break}
Google Scholar, Semantic Scholar, and arXiv are not{break}
simulated fallbacks. Obtain and verify an exact DOI in the{break}
licensed or discovery system, then use {cmd:doi()} or {cmd:doifile()}.


{marker troubleshooting}{...}
{title:Troubleshooting}

{phang}
{bf:getref is required.} {cmd:get2ref} delegates retrieval and writing{break}
to {cmd:getref}. Install or update both commands together.

{phang2}
{cmd:. which getref}

{phang2}
{cmd:. which get2ref}

{phang}
{bf:DOI list file not found.} Check that {cmd:doifile()} refers to the{break}
intended text or CSV file. The path may be quoted when it{break}
contains spaces.

{phang}
{bf:No Crossref records were found.} Broaden the query, year{break}
range, or type restriction. Alternatively, verify a DOI{break}
outside Stata and supply it with {cmd:doi()} or {cmd:doifile()}.

{phang}
{bf:Download failed.} Check the network, proxy settings, Crossref{break}
availability, and the system {cmd:curl} executable. Add {cmd:email()}{break}
when appropriate.

{phang}
{bf:File already exists.} Use {opt replace} to create a new{break}
bibliography or {opt append} to add records without duplicating{break}
existing DOIs.

{phang}
{bf:Some DOIs failed.} Successfully retrieved records are{break}
written, failed DOIs are reported, and {cmd:r(n)} counts only the{break}
records written. Retry the failed DOIs with {opt append}.

{phang}
{bf:All records were skipped.} The bibliography already contains{break}
the requested DOIs. The command exits normally with {cmd:r(n) = 0}{break}
and leaves existing entries unchanged. A getref/get2ref provenance{break}
header is updated to {cmd:get2ref v4.1}.

{phang}
{bf:An old bibliography uses underscore keys.} Earlier versions{break}
may contain keys such as {cmd:doi_10_...}. Regenerate the file{break}
with {opt replace}; {opt append} intentionally preserves existing{break}
entries.


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
Chen Liwen
{break}
School of Business, Anhui University of Technology (AHUT)
{break}
Ma'anshan, China
{break}
E-mail: {browse "mailto:2184844526@qq.com":2184844526@qq.com}

{pstd}
Wu Hanyan
{break}
School of Economics and Management, Nanjing University of Aeronautics and{break}
Astronautics (NUAA)
{break}
Nanjing, China
{break}
E-mail: {browse "mailto:2325476320@qq.com":2325476320@qq.com}

{pstd}
Program version: 4.1
{break}
Help revision: October 28, 2026
{break}
Dingyuan Accounting: Scientific rigor and humanistic goodwill


{marker alsosee}{...}
{title:Also see}

{pstd}
{help getref}, {help art2tex}, {help case2tex}, {help getiref}, {help mysuite}

{*}
