{smcl}
{* *! getref help revision 28oct2026}{...}
{vieweralsosee "get2ref" "help get2ref"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "art2tex" "help art2tex"}{...}
{vieweralsosee "case2tex" "help case2tex"}{...}
{vieweralsosee "mysuite" "help mysuite"}{...}
{viewerjumpto "Syntax" "getref##syntax"}{...}
{viewerjumpto "Description" "getref##description"}{...}
{viewerjumpto "Options" "getref##options"}{...}
{viewerjumpto "Unique value and use cases" "getref##usecases"}{...}
{viewerjumpto "Examples" "getref##examples"}{...}
{viewerjumpto "Stored results" "getref##results"}{...}
{viewerjumpto "Limitations" "getref##limitations"}{...}
{viewerjumpto "Authors" "getref##authors"}{...}
{p2colset 1 15 17 2}{...}
{p2col:{bf:getref} {hline 2}}Build bibliography records from Crossref DOI metadata{p_end}
{p2col:}({help mysuite:Part of the mysuite program suite}){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:getref} [{it:query}] , {cmd:saving(}{it:filename}{cmd:)}
{break}
        [{cmd:format(}{it:bib|tex|txt|ris}{cmd:)}
         {cmd:replace} | {cmd:append}
{break}
         {cmd:language(}{it:english|chinese}{cmd:)}
         {cmd:source(}{it:crossref}{cmd:)}
         {cmd:n(}{it:#}{cmd:)}
{break}
         {cmd:yearfrom(}{it:yyyy}{cmd:)}
         {cmd:yearto(}{it:yyyy}{cmd:)}
{break}
         {cmd:doi(}{it:doi-list}{cmd:)}
         {cmd:email(}{it:address}{cmd:)}
{break}
         {cmd:sortby(}{it:field}{cmd:)}
         {cmd:type(}{it:record-type}{cmd:)}
{break}
         {cmd:audit(}{it:filename}{cmd:)}
         {cmd:noaudit}
         {cmd:verbose}]

{pstd}
{it:query} is a topic or bibliographic search phrase. To retrieve{break}
a known work, use {cmd:doi()} and omit {it:query}. Separate multiple{break}
DOIs with a semicolon, comma, space, or vertical bar.


{marker description}{...}
{title:Description}

{pstd}
{cmd:getref} creates publication-ready bibliography records from{break}
live Crossref metadata. A topic query first identifies{break}
candidate DOIs. Each selected DOI is then read through its{break}
Crossref DOI record, after which {cmd:getref} generates a stable{break}
citation key and writes BibTeX, LaTeX, plain-text, or RIS{break}
output.

{pstd}
Bibliographic fields are never reconstructed from a{break}
search-result snippet and the program does not generate{break}
simulated records. A successful output record has a{break}
Crossref-registered DOI. This establishes an identifier and{break}
associated metadata; it does not replace inspection of the{break}
article or verification that the work supports a particular{break}
argument.

{pstd}
The command is intended for a single known work, a small{break}
curated set of DOI values, or a quick Crossref topic search{break}
inside a LaTeX-writing workflow. For DOI-file intake,{break}
recurrent batch updates, and team-managed reference queues,{break}
use {help get2ref}.


{marker options}{...}
{title:Options}

{phang}
{opt saving(filename)} specifies the required output file. For a{break}
LaTeX project, use the name expected by the manuscript,{break}
usually {cmd:saving("references.bib")}.

{phang}
{opt format(bib|tex|txt|ris)} selects the output format. The{break}
default is {opt format(bib)}, the preferred format for {cmd:art2tex},{break}
{cmd:case2tex}, natbib, and BibTeX. {opt format(tex)} creates {cmd:\bibitem}{break}
fragments for an existing {cmd:thebibliography} environment.{break}
{opt format(txt)} creates a human-readable list. {opt format(ris)}{break}
creates records for import into Zotero, EndNote, or another{break}
reference manager.

{phang}
{opt replace} replaces an existing output file. New records and{break}
their audit file are prepared in temporary files and{break}
published only after at least one record has been retrieved{break}
successfully. If every attempt fails, an existing target is{break}
left unchanged.

{phang}
{opt append} adds new records to an existing file and skips DOIs{break}
already present in that file. The existing file should use{break}
the same format as the new batch. When every requested DOI{break}
is already present, the command exits normally with{break}
{cmd:r(n) = 0}, reports the number skipped, and leaves the file{break}
unchanged. {opt replace} and {opt append} are mutually exclusive.

{phang}
{opt language(english|chinese)} controls the prose style of{break}
plain-text entries and the formatting of LaTeX entries. The{break}
default is {opt language(english)}. It changes presentation, not{break}
the language of a Crossref query.

{phang}
{opt source(crossref)} selects Crossref. It is the only supported{break}
search and metadata source in this version. For a work found{break}
in CNKI, a publisher site, or another licensed database,{break}
verify its DOI and import that exact DOI with {cmd:doi()}.

{phang}
{opt n(#)} limits the number of DOI records processed in the run{break}
to an integer from 1 through 100. The default is 10. The{break}
limit applies to explicit DOI input as well as to query{break}
results.

{phang}
{opt yearfrom(yyyy)} and {opt yearto(yyyy)} restrict publication dates{break}
for a topic query. The defaults are 2000 and 2026. Explicit{break}
DOI records are not filtered by year.

{phang}
{opt doi(doi-list)} supplies one or more exact DOIs. Separate{break}
values with a semicolon, comma, space, or vertical bar.{break}
Quoting the complete option value is recommended when it{break}
contains spaces. Duplicate DOI values are removed.

{phang}
{opt email(address)} identifies the requester to Crossref so that{break}
requests can be assigned to its polite pool. The address is{break}
not written to the bibliography.

{phang}
{opt sortby(field)} controls query-result ordering. The available{break}
fields are {opt relevance}, {opt published}, {opt cited}, {opt updated}, and{break}
{opt deposited}. The default is {opt relevance}. {opt cited} orders records by{break}
Crossref citation count. Sorting does not apply to the order{break}
of an explicit DOI list.

{phang}
{opt type(record-type)} restricts query results by Crossref work{break}
type. Available values are {opt journal-article},{break}
{opt proceedings-article}, {opt book-chapter}, {opt book}, and {opt any}. The{break}
default is {opt journal-article}; {opt any} disables the type filter.

{phang}
{opt audit(filename)} writes the provenance audit to a custom CSV{break}
file. By default, {cmd:references.bib} produces{break}
{cmd:references_audit.csv}. The audit records the DOI, citation{break}
key, year, status, source, and retrieval date.

{phang}
{opt noaudit} suppresses the provenance audit.

{phang}
{opt verbose} reports each record that is verified, skipped, or{break}
cannot be retrieved.


{marker usecases}{...}
{title:Unique value and use cases}

{pstd}
{cmd:getref} is useful when the citation itself is the immediate{break}
task. It keeps the DOI, key generation, bibliography{break}
formatting, and provenance record in one Stata command,{break}
within the project directory where the manuscript is being{break}
written.

{phang2}
{bf:Known-paper drafting.} A researcher has a DOI from a{break}
publisher page, CNKI, or a reading list and needs a correct{break}
BibTeX entry immediately. {cmd:doi()} avoids copying author,{break}
title, volume, and page fields by hand.

{phang2}
{bf:Focused topic exploration.} A researcher searches a bounded{break}
topic and year range, requests a small number of records,{break}
and inspects the resulting bibliography before deciding{break}
which articles merit close reading.

{phang2}
{bf:Reproducible coauthor handoff.} A DOI always maps to the same{break}
LaTeX-safe key, and the audit CSV records where the metadata{break}
came from. A coauthor can regenerate the same citation key{break}
and check the provenance without guessing which search{break}
result was copied.

{phang2}
{bf:Reference-manager interchange.} A user who reads references{break}
in Stata but works in Zotero or EndNote can export RIS and{break}
import it into that program, avoiding an intermediate{break}
spreadsheet.

{pstd}
Relative to {help get2ref}, {cmd:getref} has fewer moving parts and is{break}
the better fit for one paper, one DOI, or a small set typed{break}
directly on the command line. {help get2ref} is the better fit when{break}
the DOI list itself must be reviewed by a team or supplied{break}
through a text or CSV file.


{marker examples}{...}
{title:Examples}

{pstd}
Retrieve one known work and create BibTeX:

{phang2}
{stata `"getref, saving("references.bib") doi("10.1257/aer.109.4.1197") replace"'}{p_end}

{pstd}
Search Crossref for a bounded topic:

{phang2}
{stata `"getref "corporate social responsibility", saving("csr.bib") replace n(20) yearfrom(2020) yearto(2026) email("name@example.com")"'}{p_end}

{pstd}
Retrieve two known works:

{phang2}
{stata `"getref, saving("references.bib") doi("10.1257/aer.109.4.1197; 10.1002/csr.2218") replace n(2)"'}{p_end}

{pstd}
Add another batch without duplicating existing DOIs:

{phang2}
{stata `"getref "corporate governance", saving("references.bib") append n(10) yearfrom(2020)"'}{p_end}

{pstd}
Create a Chinese-style plain-text record:

{phang2}
{stata `"getref, saving("reference.txt") doi("10.69979/3029-2700.24.7.020") format(txt) language(chinese) replace"'}{p_end}

{pstd}
Create RIS output for a reference manager:

{phang2}
{stata `"getref, saving("references.ris") doi("10.1257/aer.109.4.1197") format(ris) replace"'}{p_end}

{pstd}
Use the result in a Stata session:

{phang2}
{cmd:. return list}

{pstd}
Then cite the key in LaTeX with {cmd:\citet} or {cmd:\citep}. For an{break}
empirical paper framework, use {help art2tex}; for a case-study{break}
framework, use {help case2tex}.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:getref} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 19 2: Scalars}{p_end}
{synopt:{cmd:r(n)}}number of new records written in this run; can be 0 when
all requested records were skipped{p_end}
{synopt:{cmd:r(skipped)}}number of requested DOIs skipped because they were
already present{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 19 2: Macros}{p_end}
{synopt:{cmd:r(keys)}}space-separated citation keys of new records{p_end}
{synopt:{cmd:r(key)}}citation key of the first new record; not set when no
record was added{p_end}
{synopt:{cmd:r(saving)}}requested output path{p_end}
{synopt:{cmd:r(audit)}}audit path; empty with {cmd:noaudit}{p_end}
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
Crossref metadata is supplied by publishers and registration{break}
agencies, but it can contain abbreviated names, inconsistent{break}
capitalization, missing volume or issue fields,{break}
publication-date differences, or character-conversion{break}
problems. Before submission, check the DOI, authors, title,{break}
journal, volume, issue, pages, publisher, publication{break}
version, and full text.

{pstd}
Use the command to create traceable bibliography records,{break}
not as evidence that a paper makes a particular claim.{break}
Respect database licenses, publisher terms, and the version{break}
actually read. CNKI and Google Scholar are not search{break}
sources because they do not provide stable public APIs for{break}
this workflow.

{pstd}
The former {opt format(docx)} mode has been removed. It wrote{break}
plain text to a file with a {cmd:.docx} extension and did not{break}
create a valid Word document. For Word workflows, export RIS{break}
and import it into Zotero or EndNote.


{marker troubleshooting}{...}
{title:Troubleshooting}

{phang}
{bf:Download failed.} Check the network, proxy settings, Crossref{break}
availability, and the system {cmd:curl} executable. Add {cmd:email()}{break}
when appropriate. A failed request is reported rather than{break}
replaced with simulated data.

{phang}
{bf:No Crossref records were found.} Broaden the query or year{break}
range, try {opt type(any)}, or supply an exact DOI verified{break}
outside Stata.

{phang}
{bf:File already exists.} Use {opt replace} to create a new{break}
bibliography or {opt append} to add records without duplicating{break}
existing DOIs.

{phang}
{bf:Some DOIs failed.} Successfully retrieved records are{break}
written, failed DOIs are reported, and {cmd:r(n)} counts only the{break}
records written. Retry the failed DOIs with {opt append}.

{phang}
{bf:All records were skipped.} The requested DOIs already occur{break}
in the target file. The command exits normally with {cmd:r(n) = 0}{break}
and does not add duplicate entries.

{phang}
{bf:An old bibliography uses underscore keys.} Earlier versions{break}
may contain keys such as {cmd:doi_10_...}. Regenerate the file{break}
with {opt replace}; {opt append} intentionally preserves existing keys{break}
and entries.


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
School of Economics and Management, Nanjing University of Aeronautics and{break}
Astronautics (NUAA)
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
Program version: 3.1
{break}
Help revision: October 28, 2026
{break}
Dingyuan Accounting: Scientific rigor and humanistic goodwill


{marker alsosee}{...}
{title:Also see}

{pstd}
{help get2ref}, {help art2tex}, {help case2tex}, {help getiref}, {help mysuite}

{*}
