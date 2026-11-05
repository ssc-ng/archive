{smcl}
{* *! version 1.0.32  30oct2026}{...}
{vieweralsosee "ustrregexm()" "help ustrregexm()"}{...}
{vieweralsosee "by" "help by"}{...}
{viewerjumpto "Syntax" "lusinfoscore##syntax"}{...}
{viewerjumpto "Description" "lusinfoscore##description"}{...}
{viewerjumpto "Options" "lusinfoscore##options"}{...}
{viewerjumpto "Scoring rules" "lusinfoscore##scoring"}{...}
{viewerjumpto "Text handling" "lusinfoscore##text"}{...}
{viewerjumpto "Remarks" "lusinfoscore##remarks"}{...}
{viewerjumpto "Examples" "lusinfoscore##examples"}{...}
{viewerjumpto "Stored results" "lusinfoscore##results"}{...}
{viewerjumpto "Author" "lusinfoscore##author"}{...}
{title:Title}

{phang}
{bf:lusinfoscore} {hline 2} Information score for free-text point-of-care lung ultrasound (LUS) reports


{marker syntax}{...}
{title:Syntax}

{p 8 21 2}
{cmd:lusinfoscore}
{it:strvar}
{ifin}
{cmd:,}
{opth gen:erate(newvar)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opth gen:erate(newvar)}}name of the new information-score variable{p_end}

{syntab:Output}
{synopt:{opt rep:lace}}overwrite {it:newvar} and the detail variables if they exist{p_end}
{synopt:{opt det:ail}}also create one variable per score component{p_end}
{synopt:{opt pre:fix(name)}}prefix for the detail variables; default is {cmd:lus_}{p_end}

{syntab:Scoring}
{synopt:{opth norm:al(varname)}}numeric 0/1 variable that overrides the text rule for a normal study{p_end}
{synopt:{opt ptx:points(#)}}points for a pneumothorax; default is {cmd:20}{p_end}
{synopt:{opt pnit:ispoints(#)}}points for pneumonitis or bronchiolitis with no severity word; default is {cmd:5}{p_end}
{synopt:{opt keept:emplate}}score reports that contain unfilled template placeholders{p_end}

{syntab:Text cleaning}
{synopt:{opt noclip}}do not remove the indication field, signature block or ED-course text{p_end}
{synopt:{opt strip(regex)}}regular expression for boilerplate to delete before scoring{p_end}
{synoptline}
{p 4 6 2}
{it:strvar} is a {cmd:str}{it:#} or {cmd:strL} variable holding the report text.{p_end}
{p 4 6 2}
{cmd:by} is allowed; see {help by}.{p_end}
{p 4 6 2}
Requires Stata 14 or later.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:lusinfoscore} reads free-text point-of-care lung ultrasound reports and assigns each
report an information score. The score measures how much clinically useful information a
report contains, using the items and point values of Table 1 (B-lines, sub-zones, pleural
abnormalities, consolidation and air bronchograms, pleural effusion, laterality,
localization, etiology or differential diagnosis, and cardiac findings). Higher scores mean
more documented findings and more detail about them. It is not a measure of disease
severity.

{pstd}
Findings are found with regular expressions. Negated findings ("no effusion",
"consolidation not seen") are not scored. A report read as normal scores 0. Blank reports,
and by default reports that still contain unfilled template placeholders, get a missing
score.

{pstd}
Each report is scored on its own text only, so {cmd:if}, {cmd:in} and {cmd:by} only choose
which observations are scored.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opth generate(newvar)} names the new variable that holds the total score. It is stored as
a {cmd:double} and labeled "LUS report information score".

{dlgtab:Output}

{phang}
{opt replace} allows {cmd:generate()} and the detail variables to be overwritten if they
already exist.

{phang}
{opt detail} also creates the component scores below. Their sum equals the total score. For
reports with a missing total, all components are missing. For normal reports, {it:prefix}{cmd:normal}
is 1 and all other components are 0.

{p2colset 9 32 34 2}{...}
{p2col:{it:prefix}{cmd:bline}}B-lines{p_end}
{p2col:{it:prefix}{cmd:blzone}}sub-zone count points (with B-lines){p_end}
{p2col:{it:prefix}{cmd:pleura}}pleural pathology{p_end}
{p2col:{it:prefix}{cmd:parench}}air bronchograms, consolidation, pneumonia, pneumonitis{p_end}
{p2col:{it:prefix}{cmd:effusion}}pleural effusion{p_end}
{p2col:{it:prefix}{cmd:ptx}}pneumothorax{p_end}
{p2col:{it:prefix}{cmd:laterality}}laterality{p_end}
{p2col:{it:prefix}{cmd:location}}sub-zone localization{p_end}
{p2col:{it:prefix}{cmd:etiology}}etiology or differential diagnosis{p_end}
{p2col:{it:prefix}{cmd:cardiac}}cardiac finding{p_end}
{p2col:{it:prefix}{cmd:normal}}1 if the report was read as normal (score set to 0), else 0{p_end}
{p2colreset}{...}

{phang}
{opt prefix(name)} sets the prefix of the detail variables. The default is {cmd:lus_}, which
gives {cmd:lus_bline}, {cmd:lus_pleura} and so on.

{dlgtab:Scoring}

{phang}
{opth normal(varname)} names a numeric variable that overrides the text rule for a normal
study: 1 = normal (score set to 0), 0 = not normal, missing = use the text rule.

{phang}
{opt ptxpoints(#)} sets the points for a pneumothorax that is not negated. The default is 20,
the threshold associated with considering admission for a single finding. Users may prefer
a different value if they are using this for neonates or trauma.}

{phang}
{opt pnitispoints(#)} sets the points for pneumonitis or bronchiolitis when no severity word
is near it. The default is 5. When a severity word is present, the fixed values in
{help lusinfoscore##scoring:Scoring rules} are used instead.

{phang}
{opt keeptemplate} scores reports that contain unfilled Epic, a widely used electronic 
health record, template placeholders such as {cmd:{c -(}location:138623{c )-}} or 
{cmd:{c -(}sh:125346::"presence","absence"{c )-}}. By default these reports get a missing 
score, because the report was never completed.

{dlgtab:Text cleaning}

{phang}
{opt noclip} turns off the default removal of text that is not part of the findings: the
"indication:" field, any ED-note text before "lung ultrasound indication:", and everything
after "electronically signed", "digitally signed", "signed by", "ED course", "ED medication",
or (after the impression) "medical decision making".

{phang}
{opt strip(regex)} gives a regular expression for non-patient-specific boilerplate (for
example machine, probe or image-storage text). Matching text is deleted before scoring. The
pattern is applied to lower-case text. It uses the same syntax as {help ustrregexm()}, which
is based on ICU (International Components for Unicode), so word boundaries ({cmd:\b}),
lookaheads ({cmd:(?=...)}) and non-greedy matches ({cmd:.*?}) are allowed.


{marker scoring}{...}
{title:Scoring rules}

{pstd}
The total is the sum of the components below. Within a component, the highest tier reached
counts unless the rule says the points add.

{pstd}
{ul:B-lines} (highest tier reached; B-lines also match "vertical artifacts" and "comet tails")

{p2colset 9 60 62 2}{...}
{p2col:borderline, few, occasional, rare, isolated, scattered, several,}{p_end}
{p2col:{space 2}minimal, trace, small number of, increased}1{p_end}
{p2col:excess short, patchy, multifocal, multiple zones}3{p_end}
{p2col:carpet-like}5{p_end}
{p2col:long, excess, diffuse, all zones, lots of (Kerley)}10{p_end}
{p2col:coalescent, confluent, white-out}15{p_end}
{p2colreset}{...}

{pmore}
A limiting word before excess, diffuse or numerous caps the score at 1 ("occasional excess
B-lines" = 1). "Upper limit of normal to slightly abnormal B-lines" = 1.

{pstd}
{ul:Sub-zone count} (only when B-lines score 5 or more)

{pmore}
Distinct sub-zone terms are counted once each: upper posterior, mid posterior, lower
posterior, posterior (also scapular, subscapular, infrascapular, interscapular), base (also
bibasal, bibasilar), axillary, anterior, diaphragm. "All zones", "all lung fields" and
similar count as 5. Points: 2 sub-zones = 5, 3 = 7, 4 = 10, 5 or more = 15.

{pstd}
{ul:Pleural pathology} (irregular, thickened or edematous pleura; moth-eaten, string of
pearls, punched-out)

{p2colset 9 60 62 2}{...}
{p2col:very mild, minimal, trace, tiny, slight}1{p_end}
{p2col:no severity word, or mild}2{p_end}
{p2col:mild to moderate}4{p_end}
{p2col:moderate}7{p_end}
{p2col:moderate to severe}15{p_end}
{p2col:severe}20{p_end}
{p2colreset}{...}

{pstd}
{ul:Parenchyma} (highest tier reached, then air-bronchogram points added for pneumonia)

{p2colset 9 60 62 2}{...}
{p2col:air bronchograms (incl. static); atelectasis}5{p_end}
{p2col:dynamic, clustered, irregular or concentric air bronchograms;}{p_end}
{p2col:{space 2}C-line, cupola, dome}15{p_end}
{p2col:pneumonia, consolidation, shred sign}15{p_end}
{p2col:pneumonia that is multilobar, bilateral, extensive or severe;}{p_end}
{p2col:{space 2}cauliflower sign, hepatization}20{p_end}
{p2col:pneumonitis or bronchiolitis: very mild / mild / mild to moderate /}{p_end}
{p2col:{space 2}moderate / moderate to severe / severe}2/5/7/10/12/15{p_end}
{p2col:pneumonitis or bronchiolitis, no severity word}{cmd:pnitispoints()}{p_end}
{p2colreset}{...}

{pmore}
With pneumonia or consolidation, air bronchograms add +5 (static air bronchograms count here),
or +10 if described as dynamic, clustered, irregular or concentric.

{pstd}
{ul:Pleural effusion} (scored per side)

{p2colset 9 60 62 2}{...}
{p2col:tiny, trace, minimal}5{p_end}
{p2col:small, or no size word}10{p_end}
{p2col:moderate}15{p_end}
{p2col:large, extensive, massive}20{p_end}
{p2col:loculated or non-loculated (added)}+5{p_end}
{p2colreset}{...}

{pmore}
Left and right both named: the two sides are added ("small right and moderate left
effusions" = 10 + 15). "Bilateral" alone: twice the size points. With pneumonia, the larger
of this and the pneumonia tiers (tiny 5, small 15, moderate or large 20) counts. Pericardial
effusion is not scored here.

{pstd}
{ul:Other components} (laterality and localization only when at least one abnormal finding
scored)

{p2colset 9 60 62 2}{...}
{p2col:laterality (left, right, bilateral; not heart)}3{p_end}
{p2col:sub-zone localization (any sub-zone named)}2{p_end}
{p2col:etiology or differential diagnosis (capped)}15{p_end}
{p2col:cardiac finding, including a normal one}1{p_end}
{p2col:pneumothorax}{cmd:ptxpoints()}{p_end}
{p2colreset}{...}

{pmore}
Etiology needs a named cause (COVID-19, RSV, influenza, adenovirus, metapneumovirus,
rhinovirus, parainfluenza, mycoplasma, MIS-C, bacterial, pneumococcal, cardiogenic or
pulmonary edema, heart failure, aspiration, contusion, foreign body). "Viral" alone, asthma
and reactive airway disease do not count. A differential is read from "differential",
"versus", "vs", "consider", "considerations", "should be considered" and "cannot be
excluded"; "findings considered consistent with ..." and "bronchiolitis versus pneumonitis"
alone do not count. Named etiology, multiple etiologies and differential together are capped at
15.


{marker text}{...}
{title:Text handling}

{pstd}
{ul:Normal reports.} A report scores 0 when the impression says normal, essentially normal,
almost normal, unremarkable, within normal limits, upper limit of normal, or "negative lung
ultrasound", or when the whole report is just such a statement. The normal word must end
the statement or describe the whole study ("normal study", "normal lung ultrasound",
"normal lungs", "normal windows", "normal B-lines"). "Impression: normal lung sliding ...
with long B-lines" and "essentially normal cardiac function" do not make the report normal.
"Impression: abnormal", "normal, but ..." and "otherwise normal" are not read as normal. Use
{cmd:normal()} to override.

{pstd}
{ul:Negation.} Pre-negation cues (no, not, without, absent, absence of, none, nor, negative
for, free of, rule out, r/o) cancel findings in up to the next 60 characters of the same
sentence, stopping at but, however, with, although, except, shows, there is or are,
impression and findings. A comma or "and" also ends the negation when the next item has a
quantity, size or severity word: in "no pneumothorax, long B-lines in the left base" the
B-lines are scored, while "no effusion, consolidation, or pneumothorax" stays negated. 
Post-negation ("not seen", "not identified", "absent", "ruled out")cancels up to four words
 before it. "Cannot be excluded" is not a negation and counts as a differential.

{pstd}
{ul:Severity words} are matched as phrases, so "very mild" is not read as "mild", and they
are only attached to a finding in the same sentence within about 60 characters.

{pstd}
{ul:Scanning statements.} In a clause with interrogated, scanned, examined, evaluated,
imaged, assessed or visualized, generic window names (posterior, axillary, anterior),
bilateral and "all zones" describe what was scanned, not where findings were, and do not
count toward sub-zones or laterality.

{pstd}
{ul:Missing scores.} Blank reports, and (unless {cmd:keeptemplate}) reports containing
placeholders of the form {cmd:{c -(}}{it:name}{cmd::}{it:digits}...{cmd:{c )-}}, get a
missing score. Other unfilled template fields ({cmd:{c -(}...{c )-}} choice lists and
{cmd:***}) are deleted before scoring.


{marker remarks}{...}
{title:Remarks}

{pstd}
The score is assigned by pattern matching, not by reading the report the way a clinician
would. Unusual wording, spelling errors or long sentences that mix normal and abnormal
findings can be scored wrongly. Check a sample of reports by hand, for example with the
{cmd:detail} option, before using the score in an analysis.

{pstd}
The version history is in the header of {cmd:lusinfoscore.ado}; type
{cmd:viewsource lusinfoscore.ado} to read it.


{marker examples}{...}
{title:Examples}

{pstd}Score every report{p_end}
{phang2}{cmd:. lusinfoscore narrative_l, generate(lus_score)}{p_end}

{pstd}Score again, keeping the components{p_end}
{phang2}{cmd:. lusinfoscore narrative_l, generate(lus_score) detail replace}{p_end}

{pstd}Use a different prefix for the components{p_end}
{phang2}{cmd:. lusinfoscore narrative_l, generate(score2) detail prefix(s2_)}{p_end}

{pstd}Give a pneumothorax 15 points and unqualified pneumonitis 10{p_end}
{phang2}{cmd:. lusinfoscore narrative_l, generate(lus_score) replace ptxpoints(15) pnitispoints(10)}{p_end}

{pstd}Remove machine and probe lines before scoring{p_end}
{phang2}{cmd:. lusinfoscore narrative_l, generate(lus_score) replace strip("machine\s*:[^.]*|probe\s*:[^.]*")}{p_end}

{pstd}Score a subset, and score by site{p_end}
{phang2}{cmd:. lusinfoscore narrative_l if year >= 2020, generate(lus_recent)}{p_end}
{phang2}{cmd:. bysort site: lusinfoscore narrative_l, generate(lus_score) replace}{p_end}

{pstd}Look at the reports that were not scored{p_end}
{phang2}{cmd:. list narrative_l if missing(lus_score)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:lusinfoscore} stores the following in {cmd:r()}. With {cmd:by}, they refer to the last
group.

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N_scored)}}number of reports with a non-missing score{p_end}
{synopt:{cmd:r(N_positive)}}number of reports with a score greater than 0{p_end}
{synopt:{cmd:r(N_unscored)}}number of reports with a missing score{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(version)}}version of {cmd:lusinfoscore}{p_end}


{marker author}{...}
{title:Author}

{pstd}
{it:Paul Walsh Sutter Health Research Institute, yousentwhohome@gmail.com }  
{Claude (Opus 5.5; Anthropic) was used via Claude Code in October 2026 to review the 
Stata program lusinfoscore.ado, identify and correct coding errors (version 1.0.30),
 extend the regression test suite, and draft the Stata help file. All changes were 
 reviewed by the authors and checked against the regression tests and the study
 datasets, and the authors take full responsibility for the code and its output.}

{This user-defined command is described in  Creating a lung ultrasound information
 score to measure the information content of point-of-care lung ultrasound reports. 
 Brianna Dinh; Tatiana Vidal; Andrea Hankins; Samuel Lam; Paul Walsh. at
 MedRXiV  doi: 10.64898/2026.10.30.26366367} 



{pstd}
Version 1.0.32, 30 October 2026.
{p_end}
