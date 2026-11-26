{smcl}
{* *! version 1.5.0 24nov2026 Arman Mahmud}{...}
{viewerjumpto "Syntax" "odkrepeatmerge##syntax"}{...}
{viewerjumpto "Description" "odkrepeatmerge##description"}{...}
{viewerjumpto "Files and folders" "odkrepeatmerge##files"}{...}
{viewerjumpto "Options" "odkrepeatmerge##options"}{...}
{viewerjumpto "Remarks" "odkrepeatmerge##remarks"}{...}
{viewerjumpto "Examples" "odkrepeatmerge##examples"}{...}
{viewerjumpto "Stored results" "odkrepeatmerge##results"}{...}
{viewerjumpto "Author" "odkrepeatmerge##author"}{...}
{hline}
help for {bf:odkrepeatmerge} {right:version 1.5.0 24nov2026}
{hline}

{title:Title}

{p 4 4 2}
{bf:odkrepeatmerge} {hline 2} Merge ODK repeat-group data into one wide dataset in questionnaire order


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:odkrepeatmerge using} {it:maincsv}{cmd:,}
{opt xls:form(filename)}
[{cmd:saving(}{it:filename} [{cmd:, replace}]{cmd:)}
{opt replace}
{opt sep:arator}
{opt all:string}]

{p 4 4 2}
{it:maincsv} is the main (parent) CSV file exported from ODK Central,
with its folder, e.g. {cmd:"D:/survey/raw/hh_survey.csv"}.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt xls:form(filename)}}XLSForm file used to collect the data{p_end}

{syntab:Optional}
{synopt:{cmd:saving(}{it:filename} [{cmd:, replace}]{cmd:)}}output file; default is {it:stem}{cmd:.dta} in the current working directory{p_end}
{synopt:{opt replace}}overwrite the output file if it exists{p_end}
{synopt:{opt sep:arator}}put {cmd:_} before the instance number: question {cmd:q1}, instance 11 becomes {cmd:q1_11} (not {cmd:q111}); recommended when question names end in a digit{p_end}
{synopt:{opt all:string}}import all columns as strings (keeps leading zeros){p_end}
{synoptline}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:odkrepeatmerge} combines the main CSV file and the repeat-group CSV files
exported from ODK Central into one Stata dataset with one row per submission.
It reads the XLSForm to find the repeat groups and how they are nested,
reshapes each repeat group to wide form, merges it into its parent, and
orders all variables to follow the questionnaire.

{p 4 4 2}
The data in memory are not changed; the result is saved as a {cmd:.dta}
file.  {cmd:odkrepeatmerge} requires Stata 14 or newer; it was developed
and tested on Stata 17.


{marker files}{...}
{title:Files and folders}

{p 4 4 2}
The data and the XLSForm can be in different folders, for example:

        {cmd:D:/survey/raw/hh_survey.csv}{col 52}{it:main (parent) CSV}
        {cmd:D:/survey/raw/hh_survey-member.csv}{col 52}{it:child CSV, repeat "member"}
        {cmd:D:/survey/raw/hh_survey-illness.csv}{col 52}{it:child CSV, repeat "illness"}
        {cmd:D:/survey/instrument/HH Survey.xlsx}{col 52}{it:XLSForm}

{p 4 4 2}
{bf:Child CSVs must be in the same folder as the main CSV} and be named
{it:stem}{cmd:-}{it:groupname}{cmd:.csv}, where {it:stem} is the main CSV's
name without {cmd:.csv} ({cmd:hh_survey} above) and {it:groupname} is the
repeat group's name in the XLSForm.  This is how ODK Central names them.

{p 4 4 2}
File names can be full paths or paths relative to the current working
directory.  Forward slashes work on all platforms.

{p 4 4 2}
Use the files as downloaded from ODK Central: the main CSV needs a
{cmd:KEY} column, and each child CSV needs {cmd:KEY} and {cmd:PARENT_KEY}.
Use the XLSForm version that collected the data.

{p 4 4 2}
The output is saved as {it:stem}{cmd:.dta} ({cmd:hh_survey.dta} above) in
the {bf:current working directory}, so nothing is written to the raw data
folder.  Use {cmd:cd} to choose the folder first, or give the output file
with {opt saving()}.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt using} {it:maincsv} is the main (parent) CSV file.  The
{cmd:.csv} extension may be omitted.  The child CSVs are looked for next to
it (see {help odkrepeatmerge##files:Files and folders}).

{phang}
{opt xlsform(filename)} is the XLSForm used to collect the data, e.g.
{cmd:xlsform("D:/survey/instrument/HH Survey.xlsx")}.  It is read from its
{cmd:survey} sheet (or, if there is none, its first sheet, with a note),
which must have {cmd:type} and {cmd:name} columns.
{opt formtitle()} is an older name for this option and still works.

{dlgtab:Optional}

{phang}
{cmd:saving(}{it:filename} [{cmd:, replace}]{cmd:)} saves the result under
another name or in another folder.  Add {cmd:, replace} inside the
parentheses to overwrite an existing file.  The output must be a
{cmd:.dta} file; the extension is added if omitted.

{phang}
{opt replace} overwrites the output file if it already exists.  Without
{opt replace} (here or inside {opt saving()}), {cmd:odkrepeatmerge} never
overwrites a file; use it when you run the command again.

{phang}
{opt separator} puts an underscore before the instance number: question
{cmd:q1}, instance 11, becomes {cmd:q1_11} instead of {cmd:q111}.  It is
recommended when question names end in a digit, and needed when two
questions differ only by trailing digits (e.g. {cmd:q1} and {cmd:q11}) or
when select_multiple choices inside a repeat are exported as separate
columns ({cmd:food/1}, {cmd:food/11}).  Without it,
{cmd:q1} instance 11 and {cmd:q11} instance 1 would both be {cmd:q111};
{cmd:odkrepeatmerge} checks every name before it is created and stops with
an error if two would be the same.

{phang}
{opt allstring} imports every CSV column as a string.  By default numbers
are detected automatically (decimals are stored as {cmd:double}, so GPS
coordinates keep full precision), and codes such as {cmd:007} become
{cmd:7}.  Integers longer than 15 digits (national ID or long phone
numbers) cannot be stored exactly as numbers; use {opt allstring} if the
data have such columns.  Use {helpb destring} afterwards for the variables
you want as numbers.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Variable names.} Repeat-group questions get the instance number added:
{cmd:name2} is question {cmd:name} for member 2.  For a repeat nested inside
another, the numbers are listed innermost first: {cmd:ill_type2_1} is
question {cmd:ill_type} for illness 2 of member 1 ({cmd:ill_type_2_1} with
{opt separator}).

{pstd}
{bf:Variable labels.} Each variable gets the question's label from the
XLSForm (the first {cmd:label} column), with the instance numbers in
brackets for repeat questions: {cmd:[2_1] Type of illness}.  Questions
without a label are labelled with their name.

{pstd}
{bf:Order.} {cmd:key} comes first; the other variables follow the order of
the {cmd:survey} sheet, with each
repeat instance kept together.  Notes and the parts of a geopoint
({it:gps}{cmd:latitude}, {it:gps}{cmd:longitude}, ...) are placed with their
question.  Columns that are not in the XLSForm (for example from an older
form version, or split select_multiple columns such as {cmd:food/1}) are
placed at the end and listed on screen.  ODK Central system columns such as
{cmd:SubmissionDate} are placed at the end without being listed.

{pstd}
{bf:Question names.} Names should be unique across the form.  A name used
twice is reported when the XLSForm is read; if both questions have a
column in the data (in the same CSV, or in a repeat and its parent), the
command stops with an error, because the two columns cannot both get that
name.  Rename one of the questions.  Hyphens and dots
in names are dropped, as {helpb import delimited} does
({cmd:start-geopoint} becomes {cmd:startgeopoint}).  If select_multiple
questions inside a repeat are exported as separate columns ({cmd:food/1},
{cmd:food/11}), use {opt separator}.

{pstd}
{bf:Instance numbers.} Instance numbers are read from the {cmd:[}{it:n}{cmd:]}
at the end of {cmd:KEY}, so {cmd:member[3]} is always instance 3, even if
earlier instances were deleted or rows are out of order.

{pstd}
{bf:Group names.} ODK Central may name fields inside groups
{it:group}{cmd:-}{it:field} (geopoints {it:group}{cmd:-}{it:gps}{cmd:-Latitude},
...).  Each column header is matched to the question with that group path
in the XLSForm, so the prefixes are removed even when a group name contains
{cmd:-}, and exports with or without "Remove group names" both work.

{pstd}
{bf:Edge cases.} Child CSVs with no rows are skipped.  Child rows whose
parent is not in the data are dropped, and their number is shown.  Names
that would clash, names longer than 32 characters, and data wider than
{cmd:c(maxvar)} stop the command with an error message saying what to do.


{marker examples}{...}
{title:Examples}

{pstd}Data and XLSForm in different folders; output in the current working directory:{p_end}
{phang2}{cmd:. cd "D:/survey/clean"}{p_end}
{phang2}{cmd:. odkrepeatmerge using "D:/survey/raw/hh_survey.csv", xlsform("D:/survey/instrument/HH Survey.xlsx")}{p_end}

{pstd}Run again and overwrite the previous output:{p_end}
{phang2}{cmd:. odkrepeatmerge using "D:/survey/raw/hh_survey.csv", xlsform("D:/survey/instrument/HH Survey.xlsx") replace}{p_end}

{pstd}Paths relative to a project folder; save under another name:{p_end}
{phang2}{cmd:. cd "D:/survey"}{p_end}
{phang2}{cmd:. odkrepeatmerge using "raw/hh_survey.csv", xlsform("instrument/HH Survey.xlsx") saving("clean/hh_wide.dta", replace)}{p_end}

{pstd}Keep codes as strings and use underscore names:{p_end}
{phang2}{cmd:. odkrepeatmerge using "raw/hh_survey.csv", xlsform("instrument/HH Survey.xlsx") allstring separator replace}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:odkrepeatmerge} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations in the output{p_end}
{synopt:{cmd:r(k)}}number of variables in the output{p_end}
{synopt:{cmd:r(n_repeat)}}number of repeat groups in the XLSForm{p_end}
{synopt:{cmd:r(n_unmatched)}}number of variables not found in the XLSForm{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(fn)}}output file name{p_end}
{synopt:{cmd:r(unmatched)}}variables not found in the XLSForm (not stored if there are none){p_end}


{marker author}{...}
{title:Author}

{pstd}
Arman Mahmud{break}
Email: {browse "mailto:arman.mahmud.stat@gmail.com":arman.mahmud.stat@gmail.com}{break}
Web: {browse "https://www.arman-mahmud.com":arman-mahmud.com}{break}
Issues: {browse "https://github.com/armanmahmud1/odkrepeatmerge/issues"}


{title:Also see}

{psee}
{helpb import_delimited:import delimited}, {helpb reshape}, {helpb merge};
{help odkmeta} (if installed), {help odksplit} (if installed)
{p_end}
