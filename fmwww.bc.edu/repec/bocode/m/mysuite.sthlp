{smcl}
{* 31Oct2026}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "myedit" "help myedit"}{...}
{vieweralsosee "ff" "help ff"}{...}
{viewerjumpto "Syntax" "mysuite##syntax"}{...}
{viewerjumpto "Description" "mysuite##description"}{...}
{viewerjumpto "Options" "mysuite##options"}{...}
{viewerjumpto "Examples" "mysuite##examples"}{...}
{viewerjumpto "References and compilation" "mysuite##references"}{...}
{viewerjumpto "Authors" "mysuite##authors"}{...}
{viewerjumpto "Acknowledgments" "mysuite##acknowledgments"}{...}
{title:Title}

{phang}
{bf:mysuite} {hline 2} Built-in extensible program suite for empirical research


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:mysuite}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt All}}Install missing SSC modules only{p_end}
{synopt:{opt Installed}}List currently installed modules{p_end}
{synopt:{opt Download}}Force reinstall all modules (when combined with {opt all}){p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mysuite} is a comprehensive Stata program suite designed for empirical research,
teaching management, and academic writing. It provides access to 48 specialized
programs (delivered through 45 SSC packages) available from the SSC archive.

{pstd}
{bf:Core Features:}

{phang2}
- Centralized module discovery and installation{p_end}
{phang2}
- Smart installation: only installs missing modules (with {opt all}){p_end}
{phang2}
- Force reinstall all 48 programs when needed (with {opt all download}){p_end}
{phang2}
- Installation status checking and reporting{p_end}
{phang2}
- List all currently installed modules (with {opt installed}){p_end}

{pstd}
{bf:Operation Modes:}

{phang2}
{bf:MODE 1 - Display}
  No options specified
  → Show program banner, complete list of 48 programs,
     current installation status, and detailed usage instructions.
     No modules are downloaded or installed.{p_end}

{phang2}
{bf:MODE 2 - Install Missing}
  {opt all} option specified
  → Scan and install only SSC packages that are not currently installed.
     Already installed packages are skipped for efficiency.{p_end}

{phang2}
{bf:MODE 3 - List Installed}
  {opt installed} option specified
  → Display a complete list of all currently installed programs.
     Shows installation count summary (e.g., "40/48 modules installed").{p_end}

{phang2}
{bf:MODE 4 - Force Reinstall}
  {opt all} and {opt download} options combined
  → Force reinstall ALL 48 programs (45 SSC packages) regardless of current
     installation status.
     Useful for updating to latest versions or fixing corrupted installations.{p_end}


{title:Updates in version 1.3.0}

{pstd}
The following improvements have been made in version 1.3.0:

{phang2}
- Three recently collected SSC programs have been added to the suite:
  {bf:esgdict} (machine-learning generation of the ESG dictionary used by
  {cmd:qta}), {bf:wordfreq} (bilingual keyword frequencies for PDF corpora and
  in-memory text), and {bf:xtcsd} (cross-sectional dependence tests after
  {cmd:xtreg}).{p_end}
{phang2}
- {bf:esgdict} and {bf:wordfreq} have been added beside {cmd:qta} in the
  {bf:Support Kits} category. {bf:xtcsd} has also been added to this category.{p_end}
{phang2}
- The references workflow in {help reftex}, {help getref}, and {help get2ref}
  has been updated. Use {cmd:mysuite, all download} to refresh all three files
  together; {bf:get2ref} requires the current {bf:getref}.{p_end}
{phang2}
- Total module count increased from 45 to 48 programs, and the number of SSC
  packages increased from 42 to 45.{p_end}


{title:Updates in version 1.2.1}

{pstd}
The following improvements were made in version 1.2.1:

{phang2}
- A new module {bf:ff} (browse and search Stata's built-in functions) has been
  added to the suite and is now available on SSC; it was first released on
  21 September 2026.{p_end}
{phang2}
- The SSC package {bf:plssem2} has been revised and redistributed on SSC
  (distribution date 21 September 2026). Reinstalling it with
  {cmd:mysuite, all download} updates an earlier installation.{p_end}
{phang2}
- {bf:ff} has been added to the {bf:3. Research & Teaching Management}
  category of the module menu.{p_end}
{phang2}
- Total module count increased from 44 to 45 programs, and the number of SSC
  packages increased from 41 to 42.{p_end}


{title:Updates in version 1.2.0}

{pstd}
The following improvements have been made in version 1.2.0:

{phang2}
- Five new modules have been added to the suite and are now available on SSC:
  {bf:mkes} (spoken-English sentence generator using Stata's Python integration),
  {bf:plssem2} (partial least squares structural equation modeling, PLS-SEM),
  {bf:stataedu} (Stata beginner learning program),
  {bf:pythonedu} (Python beginner learning program), and
  {bf:latexedu} (LaTeX beginner learning program).{p_end}
{phang2}
- {bf:stataedu}, {bf:pythonedu}, and {bf:latexedu} are bundled in the single SSC
  package {bf:learn_bilingual}. Typing {cmd:ssc install learn_bilingual} downloads
  all three programs at once.{p_end}
{phang2}
- A new module category, {bf:4. Teaching & Learning Kits}, has been added to the
  module menu, and {bf:plssem2} has been added to the {bf:Support Kits} category.{p_end}
{phang2}
- Total module count increased from 39 to 44 programs.{p_end}


{title:Updates in version 1.1.2}

{pstd}
The following improvements have been made in version 1.1.2:

{phang2}
- Two new modules from the {bf:鼎园会计} (Dingyuan Accounting) team have been
  added to the suite and are now available on SSC:
  {bf:fm} (file classification manager) and
  {bf:varck} (variable existence check).{p_end}
{phang2}
- The {bf:ssc} module has been removed from the suite as it is not an original
  work of the {bf:鼎园会计} (Dingyuan Accounting) team.{p_end}
{phang2}
- Total module count: 39.{p_end}


{title:Updates in version 1.1.1}

{pstd}
The following improvements have been made in version 1.1.1:

{phang2}
- A new module {bf:ccgi} (corporate governance indicator) from the
  {bf:鼎园会计} (Dingyuan Accounting) team has been added to the suite
  and is now available on SSC.{p_end}
{phang2}
- Total module count increased from 38 to 39.{p_end}


{title:Updates in version 1.1.0}

{pstd}
The following improvements have been made in version 1.1.0:

{phang2}
- Three new modules from the {bf:鼎园会计} (Dingyuan Accounting) team have been
  added to the suite and are now available on SSC:
  {bf:editprofile} (Stata profile editor),
  {bf:reduce_aigc} (AIGC text reduction tool), and
  {bf:myinterval} (confidence interval computation).{p_end}
{phang2}
- Total module count increased from 33 to 36.{p_end}


{title:Updates in version 1.0.9}

{pstd}
The following improvements have been made in version 1.0.9:

{phang2}
- {bf:bmc} and {bf:conservatism}, previously distributed as local ado-files,
  are now fully available on SSC and can be installed via {cmd:mysuite, all}.{p_end}
{phang2}
- A new module {bf:polishpaper} (academic paper polishing template) has been
  added to the suite and is available on SSC.{p_end}
{phang2}
- {bf:regtex} and {bf:reg2tex} are bundled in a single SSC package. Typing
  {cmd: ssc desc regtex} and clicking the hyperlink in the results window
  downloads both programs at once.{p_end}


{marker options}{...}
{title:Options}

{phang}
{opt All} installs only missing SSC packages in the mysuite collection.
Checks each package's installation status first and only downloads those not found.
Some packages provide more than one program, e.g. {cmd:learn_bilingual} installs
{cmd:stataedu}, {cmd:pythonedu}, and {cmd:latexedu} together.
Shows installation progress and summary statistics upon completion.

{phang}
{opt Installed} lists all currently installed programs without making any changes.
Displays each of the 48 modules with "Installed" or "Not installed" status,
followed by a count summary.

{phang}
{opt Download} modifies the behavior of {opt all}. When combined:
- {cmd:mysuite, all} → Install missing modules only
- {cmd:mysuite, all download} → Force reinstall ALL 48 programs


{marker examples}{...}
{title:Examples}

{pstd}
{bf:MODE 1 - Display Program Information:}

{phang}{cmd:. mysuite}{p_end}
{phang}Display program banner, complete module list (48 programs),
current installation status (e.g., "SSC modules installed: 20/48"),
and detailed usage instructions. No modules are downloaded or installed.{p_end}

{pstd}
{bf:MODE 2 - Install Missing Modules:}

{phang}{cmd:. mysuite, all}{p_end}
{phang}Smart installation - checks each of the 45 SSC packages and installs
only those not currently found. Already installed packages are skipped.
Packages that provide several programs, such as {cmd:learn_bilingual} (installing
{cmd:stataedu}, {cmd:pythonedu}, and {cmd:latexedu}), are handled in one step.
Example output:
  {bf:sumtex}: Already installed
  Installing {bf:regtex}... Done
  {bf:corrtex2}: Already installed
Installation Summary:
  Already installed: 30 packages
  Newly installed:   2 packages{p_end}

{pstd}
{bf:MODE 3 - List Installed Modules:}

{phang}{cmd:. mysuite, installed}{p_end}
{phang}Display complete list of currently installed modules:
  {bf:Currently Installed SSC Modules:}
    {bf:art2tex}: Installed
    {bf:case2tex}: Installed
    ...
    {bf:varck}: Installed
    {bf:latexedu}: Not installed
  {bf:Summary:} 43/48 SSC modules installed
Useful for quick inventory of your setup.{p_end}

{pstd}
{bf:MODE 4 - Force Reinstall All Modules:}

{phang}{cmd:. mysuite, all download}{p_end}
{phang}Force reinstall ALL 48 programs (45 SSC packages) regardless of current status.
Use this to update to latest versions or fix corrupted installations.
Example output:
  Reinstalling {bf:art2tex}... Done
  Reinstalling {bf:case2tex}... Done
  ...
  Reinstalling {bf:learn_bilingual} (stataedu, pythonedu, latexedu)... Done
Reinstallation Summary:
  Successfully reinstalled: 45 packages{p_end}

{pstd}
{bf:Checking Installation Status:}

{phang}{cmd:. mysuite}{p_end}
{phang}Running without options shows current installation status:
"SSC modules installed: 18/48" - quickly see what's missing.{p_end}

{pstd}
{bf:Editing Installed Modules:}

{phang}{cmd:. myedit regtex}{p_end}
{phang}After installation, use {help myedit} to view and edit any module's source code.
This is useful for learning, customization, and debugging.{p_end}

{phang}{cmd:. help regtex}{p_end}
{phang}View help documentation for any installed module.{p_end}

{pstd}
{bf:Common Workflows:}

{phang}1. Check what's installed: {cmd:. mysuite}{p_end}
{phang}2. Install missing modules: {cmd:. mysuite, all}{p_end}
{phang}3. Verify installation: {cmd:. mysuite, installed}{p_end}
{phang}4. Update all modules (quarterly): {cmd:. mysuite, all download}{p_end}


{marker references}{...}
{title:参考文献获取与编译}

{pstd}
The reference workflow uses three commands. {bf:reftex} (version 10.0)
converts a plain-text CNKI or similar bibliography into LaTeX or BibTeX.
{bf:getref} (version 3.1) retrieves Crossref-verified metadata for a known DOI
or a small topic query. {bf:get2ref} (version 4.1) is the batch front end for
reviewed DOI files and delegates retrieval to {bf:getref}. All three programs
and their help files were updated on 28 October 2026. The earlier retrieval
sources that produced simulated records have been removed.

{pstd}
Update the three commands together before using them:

{phang2}
{cmd:. mysuite, all download}

{pstd}
For a CNKI-style text export, create a BibTeX database with {bf:reftex}:

{phang2}
{cmd:. reftex using "cnki.txt", saving("cnki.bib") format(bib) lang(mix) replace}

{pstd}
For a known DOI, use {bf:getref}. For a reviewed DOI list, use {bf:get2ref}.
The two commands share a Crossref-verified retrieval core:

{phang2}
{cmd:. getref, saving("references.bib") doi("10.1257/aer.109.4.1197") replace}

{phang2}
{cmd:. get2ref, saving("references.bib") doifile("dois.txt") replace}

{pstd}
Use {opt format(bib)} for the usual {cmd:art2tex} and {cmd:case2tex} workflow.
Inspect {cmd:return list} for citation keys and review the automatically
created audit file. Keep separately generated databases when both CNKI text
and Crossref retrieval are needed, or append later Crossref batches with
{opt append}. Existing records and citation keys are preserved by {opt append}.

{pstd}
For the BibTeX route, declare {cmd:natbib} and {cmd:url}, then compile with
XeLaTeX and BibTeX. A minimal sequence is:

{phang2}
{cmd:\usepackage[round]{natbib}}

{phang2}
{cmd:\usepackage{url}}

{phang2}
{cmd:\bibliographystyle{plainnat}}

{phang2}
{cmd:\bibliography{references,cnki}}

{phang2}
{cmd:xelatex paper.tex}

{phang2}
{cmd:bibtex paper}

{phang2}
{cmd:xelatex paper.tex}

{phang2}
{cmd:xelatex paper.tex}

{pstd}
If {bf:reftex} writes a complete {cmd:thebibliography} file, insert it with
{cmd:\input{cnki_refs.tex}} and compile with XeLaTeX twice. In both routes,
check authors, title, journal, year, volume, issue, pages, DOI, publication
version and the full text before submission. A DOI verifies an identifier and
metadata record; it does not establish that the work supports a particular
argument.


{marker authors}{...}
{title:Authors}

{pstd}
{help agd2010@yeah.net:Wu Lianghai} (agd2010@yeah.net){p_end}
{pstd}School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}Ma'anshan, Anhui, China{p_end}

{pstd}
{help 2184844526@qq.com:Chen Liwen} (2184844526@qq.com){p_end}
{pstd}School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}Ma'anshan, Anhui, China{p_end}

{pstd}
{help 2325476320@qq.com:Wu Hanyan} (2325476320@qq.com){p_end}
{pstd}School of Economics and Management{p_end}
{pstd}Nanjing University of Aeronautics and Astronautics (NUAA){p_end}
{pstd}Nanjing, Jiangsu, China{p_end}

{pstd}
{help 2957833979@qq.com:Wu Xinzhuo} (2957833979@qq.com){p_end}
{pstd}University of Bristol (UB){p_end}
{pstd}Leeds, West Yorkshire, England{p_end}

{pstd}
{help 1536496199@qq.com:Li Juan} (1536496199@qq.com){p_end}
{pstd}Red Cross Society of Ma'anshan City{p_end}
{pstd}Ma'anshan, Anhui, China{p_end}

{pstd}
Development Date: 31 Oct 2026{p_end}
{pstd}
Version: 1.3.0{p_end}


{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd}
We would like to express our sincere gratitude to {bf:Christopher F. Baum}!
Thanks to his enthusiastic support and timely scientific guidance, we have successfully developed a series of intelligent accounting research and teaching toolkits from the end of July 2025 to the present, which have been uploaded to the SSC platform as scheduled.{p_end}


{title:Also see}

{psee}
Online: {help ff}, {help myedit}, {help editprofile}, {help reduce_aigc}, {help myinterval},
{help ccgi}, {help fm}, {help varck}, {help esgdict}, {help wordfreq}, {help xtcsd},
{help reftex}, {help getref}, {help get2ref}, {help mkes}, {help plssem2},
{help stataedu}, {help pythonedu}, {help latexedu}
{p_end}
{*}
