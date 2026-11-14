{smcl}
{* *! googlesheets v0.1.7  2026-11-09}{...}
{cmd:help googlesheets}{...}
{viewerjumpto "Syntax"      "googlesheets##syntax"}{...}
{viewerjumpto "Subcommands" "googlesheets##subcommands"}{...}
{viewerjumpto "Setup"       "googlesheets##setup"}{...}
{viewerjumpto "Examples"    "googlesheets##examples"}{...}
{viewerjumpto "Form data"   "googlesheets##forms"}{...}
{viewerjumpto "Brand styling" "googlesheets##brand"}{...}
{viewerjumpto "Stored results" "googlesheets##results"}{...}
{title:Title}

{phang}{bf:googlesheets} {hline 2} Read, write, edit, and chart Google Sheets directly from Stata

{marker syntax}{...}
{title:Syntax}

{phang}{cmd:googlesheets} {it:subcommand} [...] [, options]{p_end}

{phang}where {it:subcommand} is one of:{p_end}
{p2colset 9 25 27 2}{...}
{p2col :{cmd:import}}read a range into the current dataset (like {cmd:import excel}){p_end}
{p2col :{cmd:export}}write the current dataset to a sheet (like {cmd:export excel}){p_end}
{p2col :{cmd:put}}place a single value, formula, or matrix at a cell (like {cmd:putexcel}){p_end}
{p2col :{cmd:format}}apply colour / font / number-format to a cell range{p_end}
{p2col :{cmd:addchart}}insert a chart object (column / bar / stacked / line / area / scatter / pie / donut){p_end}
{p2col :{cmd:list}}list the sheet (tab) names in a spreadsheet{p_end}
{p2col :{cmd:ping}}confirm OAuth + API access against a target spreadsheet{p_end}
{p2col :{cmd:create}}create a new spreadsheet in the user's Drive (returns its id / URL){p_end}
{p2col :{cmd:addsheet}}add a new tab{p_end}
{p2col :{cmd:deletesheet}}delete a tab by title{p_end}
{p2col :{cmd:renamesheet}}rename a tab{p_end}
{p2colreset}{...}

{marker subcommands}{...}
{title:Subcommand syntax}

{phang}{cmd:googlesheets import using} {it:"<id-or-url>"} {cmd:,}
    {cmdab:sh:eet(}{it:name}{cmd:)}
    [{cmdab:range(}{it:A1:Z}{cmd:)}
     {cmdab:firstrow}
     {cmd:clear}
     {cmd:stringall}
     {cmdab:si:nce(}{it:column=value}{cmd:)}
     {cmd:tail(}{it:N}{cmd:)}
     ...]{p_end}

{phang}{cmd:googlesheets export using} {it:"<id-or-url>"} {cmd:,}
    {cmdab:sh:eet(}{it:name}{cmd:)}
    [{cmd:range(}{it:A1}{cmd:)}
     {cmd:replace} | {cmd:append}
     {cmdab:first:row(variables)}
     ...]{p_end}

{phang}{cmd:googlesheets put using} {it:"<id-or-url>"} {cmd:,}
    {cmdab:sh:eet(}{it:name}{cmd:)} {cmd:cell(}{it:A1}{cmd:)}
    (one of {cmd:value(}{it:#}{cmd:)} {cmd:string(}{it:text}{cmd:)} {cmd:formula(}{it:=...}{cmd:)} {cmd:matrix(}{it:M}{cmd:)}) [{cmd:names}]{p_end}

{phang}{cmd:googlesheets format using} {it:"<id-or-url>"} {cmd:,}
    {cmdab:sh:eet(}{it:name}{cmd:)} {cmd:range(}{it:A1:E1}{cmd:)}
    [{cmdab:bg:color(}{it:"#1B2D55"}{cmd:)}
     {cmdab:fg:color(}{it:"#FFFFFF"}{cmd:)}
     {cmd:bold} {cmdab:ital:ic}
     {cmd:font(}{it:Montserrat}{cmd:)}
     {cmd:fontsize(}{it:#}{cmd:)}
     {cmd:numfmt(}{it:"0.0%"}{cmd:)}
     {cmdab:hal:ign(}{it:left|center|right}{cmd:)}
     {cmd:wrap}]{p_end}

{phang}{cmd:googlesheets addchart using} {it:"<id-or-url>"} {cmd:,}
    {cmdab:sh:eet(}{it:source}{cmd:)} {cmd:type(}{it:column|bar|stacked_column|stacked_bar|line|area|scatter|pie|donut}{cmd:)}
    {cmdab:dom:ain(}{it:A2:A6}{cmd:)} {cmd:series(}{it:B2:B6}|{it:C2:C6}|...{cmd:)}
    [{cmd:names(}{it:"label1|label2|..."}{cmd:)}
     {cmd:colors(}{it:"#1B2D55|#D44500|..."}{cmd:)}
     {cmd:title(}{it:"..."}{cmd:)} {cmdab:sub:title(}{it:"..."}{cmd:)}
     {cmd:xlabel(}{it:"..."}{cmd:)} {cmd:ylabel(}{it:"..."}{cmd:)}
     {cmd:header}
     {cmd:legendpos(}{it:top|right|bottom|left|none|labeled}{cmd:)}   (default {cmd:bottom})
     {cmd:tx2036style}
     {cmd:piehole(}{it:0.5}{cmd:)}
     {cmd:targetsheet(}{it:name}{cmd:)} {cmd:anchor(}{it:H1}{cmd:)}
     {cmd:width(}{it:#}{cmd:)} {cmd:height(}{it:#}{cmd:)}]{p_end}

{phang}{cmd:googlesheets create,} {cmd:title(}{it:"My report"}{cmd:)} [{cmd:sheettitle(}{it:"Data"}{cmd:)}]{p_end}
{phang}{cmd:googlesheets list, spreadsheet(}{it:"<id-or-url>"}{cmd:)}{p_end}
{phang}{cmd:googlesheets ping, spreadsheet(}{it:"<id-or-url>"}{cmd:)}{p_end}
{phang}{cmd:googlesheets addsheet, spreadsheet(}{it:"..."}{cmd:) title(}{it:"New Tab"}{cmd:)} [{cmd:rows(}{it:#}{cmd:)} {cmd:cols(}{it:#}{cmd:)} {cmd:index(}{it:#}{cmd:)}]{p_end}
{phang}{cmd:googlesheets deletesheet, spreadsheet(}{it:"..."}{cmd:) title(}{it:"Old Tab"}{cmd:)}{p_end}
{phang}{cmd:googlesheets renamesheet, spreadsheet(}{it:"..."}{cmd:) from(}{it:"Old"}{cmd:) to(}{it:"New"}{cmd:)}{p_end}

{phang}Spreadsheets are addressed by either the bare ~44-character ID or a full URL.
The wrapper extracts the ID either way, including from the multi-account form
{bf:.../spreadsheets/u/1/d/}{it:<id>}{bf:/edit} that the browser shows when more
than one Google account is signed in.{p_end}

{phang}{ul:import} behaves like {cmd:import excel}: when data are in memory,
{cmd:clear} is required, and without it the command stops with error 4 ("no;
data in memory would be lost").  The data in memory are replaced only after
the Sheet has been read, so a failed read leaves them in place.  With
{cmd:firstrow}, row 1 becomes the variable names; they are lowercased, as
{cmd:import delimited} does by default (a header {bf:Timestamp} becomes the
variable {bf:timestamp}).  {cmd:since()} still takes the header text as it
appears in the Sheet.{p_end}

{phang}{ul:export} writes numeric variables as numbers and string variables as
text.  A string such as {bf:"00123"} keeps its leading zeros, and {bf:"1e5"} or
{bf:"2026-01-01"} is stored as typed rather than converted to a number or a
date.  (Each string cell is sent with Sheets' leading-apostrophe "store as
text" marker, which Sheets does not display.)  Numeric variables with value
labels are written as their labels, as {cmd:export delimited} does.  A
{cmd:float} variable is written at the precision a float holds: 3.58 is sent
as 3.58, not as 3.5799999, the digits of its binary value.{p_end}

{phang}{ul:create} makes a new spreadsheet in your Drive.  {cmd:title()} names
the spreadsheet and {cmd:sheettitle()} names its first tab (default: Sheets'
own {bf:Sheet1}).  The new id and URL are returned in {cmd:r(id)} and
{cmd:r(url)}; see {help googlesheets##results:Stored results}.{p_end}

{phang}{ul:addchart} accepts only the {cmd:type()} values listed above (in any
case); anything else is an error.  {cmd:subtitle()} adds a line under the
title, and {cmd:header} tells Sheets that the first row of {cmd:domain()} and
{cmd:series()} holds labels rather than data.{p_end}

{phang}{ul:format} takes {cmd:range()} with or without a tab name; a range
that names its own tab ({bf:'Auto'!A1:B2}) is used as given.{p_end}

{phang}Every subcommand accepts these common options:{p_end}
{p2colset 9 25 27 2}{...}
{p2col :{cmd:keyfile(}{it:path}{cmd:)}}OAuth Desktop client JSON (overrides {cmd:$GS_CLIENT}){p_end}
{p2col :{cmd:tokenfile(}{it:path}{cmd:)}}OAuth token cache file (overrides {cmd:$GS_TOKEN}){p_end}
{p2col :{cmd:verbose}}echo the underlying Python invocation + Sheets API result; the helper also writes its full reply, with any Python traceback, to a {bf:.json} file next to its result file (the path is printed){p_end}
{p2colreset}{...}

{marker setup}{...}
{title:One-time setup}

{pstd}This package talks to Google's Sheets API via a small Python helper that
ships with the package.  Auth uses an OAuth 2.0 Desktop client.{p_end}

{phang}{bf:Step 1.}  Create a new project in {browse "https://console.cloud.google.com"}
(any name).  Under {bf:APIs & Services > Library}, enable the {bf:Google Sheets API}
and {bf:Google Drive API}.{p_end}

{phang}{bf:Step 2.}  {bf:APIs & Services > OAuth consent screen}: choose {bf:External}.
Fill in the required fields, add yourself as a test user, and add the scopes
the helper asks for: {bf:.../auth/spreadsheets}, {bf:.../auth/drive.file}, and
{bf:.../auth/drive.metadata.readonly}.{p_end}

{phang}{bf:Step 3.}  {bf:APIs & Services > Credentials > Create credentials > OAuth
client ID}.  Application type: {bf:Desktop app}.  Download the JSON file.{p_end}

{phang}{bf:Step 4.}  Save the JSON locally and tell Stata where to find it by
setting {cmd:$GS_CLIENT} once.  The recommended place is your {bf:profile.do},
which Stata reads on every launch.  On macOS the profile is usually at
{bf:/Users/}{it:yourname}{bf:/Documents/Stata/ado/personal/profile.do}; on Windows it lives next to
the Stata executable.  Add one of these blocks to it:{p_end}

{phang}{ul:Simple form -- absolute path}{p_end}
{phang}{cmd}global GS_CLIENT "/Users/yourname/.config/stata-googlesheets/client.json"{p_end}
{phang}{cmd}global GS_CLIENT "C:/Users/yourname/AppData/Roaming/stata-googlesheets/client.json"{p_end}

{pstd}Give the full path, as above, rather than one that starts with {bf:~}.
Operating systems, Stata versions and Python handle {bf:~} differently.
{cmd:googlesheets} expands a leading {bf:~} itself as a safety net, but a full
path works everywhere.{p_end}

{phang}{ul:macOS form -- finds the Google Drive for desktop folder}{p_end}
{pstd}On macOS, Google Drive for desktop mounts under
{bf:~/Library/CloudStorage}.  The lines below find that folder; on Linux or
Windows (where the Drive letter varies), give the full path instead, as in
the simple form above.{p_end}
{phang}{cmd}if "`c(os)'" == "MacOSX" {c -(}{p_end}
{phang}{cmd}    local _gd_base "/Users/`c(username)'/Library/CloudStorage"{p_end}
{phang}{cmd}    local _gd_folders : dir "`_gd_base'" dirs "GoogleDrive-*"{p_end}
{phang}{cmd}    local _gd_folder  : word 1 of `_gd_folders'{p_end}
{phang}{cmd}    local _gd_folder  = subinstr(`"`_gd_folder'"', `"""', "", .){p_end}
{phang}{cmd}    local _my_drive   `"`_gd_base'/`_gd_folder'/My Drive"'{p_end}
{phang}{cmd}    global GS_CLIENT `"`_my_drive'/path/to/client.json"'{p_end}
{phang}{cmd}{c )-}{p_end}

{phang}You can also point at a default test Sheet so the shipped
{bf:test_googlesheets.do} example just runs:{p_end}
{phang}{cmd}global GS_TEST_SHEET "https://docs.google.com/spreadsheets/d/<your-id>/edit"{p_end}

{phang}{bf:Step 5.}  Run any {cmd:googlesheets} command.  The first call opens
a browser for Google sign-in (one time per machine); click {bf:Allow}, and a
refresh token is cached next to the client JSON ({bf:token.json}, mode 0600).
All future calls are silent.{p_end}

{pstd}On the very first invocation the package also creates a private Python
virtualenv at {bf:.config/stata-googlesheets/venv} in your home folder
({bf:%APPDATA%\stata-googlesheets\venv} on Windows) and pip-installs the
Google client libraries into it.  The user's system Python is left untouched.{p_end}

{pstd}{ul:Verify the setup}{p_end}
{phang}{cmd}display "$GS_CLIENT"                  // should print the JSON path{p_end}
{phang}{cmd}display fileexists("$GS_CLIENT")      // should print 1{p_end}
{phang}{cmd}googlesheets ping, spreadsheet("$GS_TEST_SHEET"){p_end}

{marker brand}{...}
{title:Styling a chart or a range}

{pstd}Pass explicit hex codes to {cmd:colors()} on {cmd:addchart}, and to
{cmd:bgcolor()} / {cmd:fgcolor()} on {cmd:format}, to style a chart or a cell
range yourself.  The {cmd:tx2036style} option is an {it:internal} house style
used in the authors' own workflows (a Montserrat title in navy plus a matching
series palette).  It is off unless you ask for it, and you do not need it; if
the Montserrat font is unavailable, Google Sheets uses its default font and the
chart is still drawn.  A manual call looks like this:{p_end}

{phang}{cmd}googlesheets format using "..."  , sheet("Auto") range("A1:L1") ///{p_end}
{phang}{cmd}    bgcolor("#1B2D55") fgcolor("#FFFFFF") bold font("Montserrat") fontsize(12){p_end}

{marker examples}{...}
{title:Examples}

{pstd}The examples below use Stata's built-in {bf:auto.dta}.  They work
end-to-end against any Google Sheet you own -- replace {bf:$SS} with your
own spreadsheet URL or ID.  Each example builds on the previous one.{p_end}

{phang}First, set the global pointing to your auth client JSON and the global
pointing to a Sheet you can edit:{p_end}

{phang}{cmd}global GS_CLIENT "/Users/yourname/.config/stata-googlesheets/client.json"{p_end}
{phang}{cmd}global SS "https://docs.google.com/spreadsheets/d/.../edit"{p_end}


{dlgtab:1.  Verify auth works, list the existing tabs}

{phang}{cmd}googlesheets ping, spreadsheet("$SS"){p_end}
{phang}{cmd}googlesheets list, spreadsheet("$SS"){p_end}

{pstd}The first time you run this on a new machine your browser pops a Google
sign-in screen.  Click {bf:Allow} once and the token is cached forever.{p_end}


{dlgtab:2.  Push the auto dataset to a fresh tab}

{phang}{cmd}sysuse auto, clear{p_end}
{phang}{cmd}capture googlesheets deletesheet, spreadsheet("$SS") title("Auto"){p_end}
{phang}{cmd}googlesheets addsheet, spreadsheet("$SS") title("Auto"){p_end}
{phang}{cmd}googlesheets export using "$SS", sheet("Auto") firstrow(variables){p_end}

{pstd}{cmd:firstrow(variables)} writes the Stata variable names as row 1 so
the resulting Sheet has a real header.  Without it the data starts at row 1
and the Sheet has no header.{p_end}


{dlgtab:3.  Brand-style the header row}

{phang}{cmd}googlesheets format using "$SS", sheet("Auto") range("A1:L1") ///{p_end}
{phang}{cmd}    bgcolor("#1B2D55") fgcolor("#FFFFFF") bold font("Montserrat") fontsize(12){p_end}

{pstd}Applies the navy / white / Montserrat / 12pt / bold treatment.  Useful
above any range, not just headers (e.g. highlighting a totals row).{p_end}


{dlgtab:4.  Format a numeric column as a percentage / currency}

{phang}{cmd}googlesheets format using "$SS", sheet("Auto") range("C2:C75") numfmt("0.0"){p_end}
{phang}{cmd}googlesheets format using "$SS", sheet("Auto") range("B2:B75") numfmt("\$#,##0"){p_end}

{pstd}{cmd:numfmt()} accepts any Sheets number-format pattern: {bf:0.0%},
{bf:#,##0.00}, {bf:yyyy-mm-dd}, {bf:[h]:mm:ss}, etc.  The pattern is applied
to every cell in the range.{p_end}


{dlgtab:5.  Place individual cell values (titles, notes, totals)}

{phang}{cmd}googlesheets put using "$SS", sheet("Auto") cell(O1) string("Auto data summary"){p_end}
{phang}{cmd}googlesheets put using "$SS", sheet("Auto") cell(O2) string("Run date: `=c(current_date)'"){p_end}
{phang}{cmd}summarize price{p_end}
{phang}{cmd}googlesheets put using "$SS", sheet("Auto") cell(O3) value(`=r(mean)'){p_end}
{phang}{cmd}googlesheets put using "$SS", sheet("Auto") cell(O4) formula("=AVERAGE(B2:B75)"){p_end}

{pstd}{cmd:value(#)} writes a number.  {cmd:string("text")} writes text
verbatim.  {cmd:formula("=...")} writes a Sheets formula -- the cell will
display the computed result.{p_end}


{dlgtab:6.  Drop a Stata matrix at a target cell}

{phang}{cmd}correlate price mpg weight length{p_end}
{phang}{cmd}matrix C = r(C){p_end}
{phang}{cmd}googlesheets put using "$SS", sheet("Auto") cell(O6) matrix(C) names{p_end}

{pstd}{cmd:matrix(M)} writes a {it:rowsof(M)} x {it:colsof(M)} block starting
at the given cell.  Missing values become blank cells (a value already in such
a cell is cleared).  {cmd:value(.)} likewise blanks a single cell.  Add {cmd:names} to write the matrix's row and column names as well: the column names go in a header row and the row names in the column to their left.  Numbers are written
as numbers (USER_ENTERED parsing applies, so Sheets stores them as numeric).{p_end}


{dlgtab:7.  Insert a chart from the data on the Sheet}

{phang}{cmd}googlesheets addchart using "$SS", sheet("Auto") type(column) ///{p_end}
{phang}{cmd}    domain(A2:A75) series(B2:B75)                             ///{p_end}
{phang}{cmd}    names("Price")                                            ///{p_end}
{phang}{cmd}    title("Price by make")                                    ///{p_end}
{phang}{cmd}    xlabel("Make")  ylabel("Price (USD)")                     ///{p_end}
{phang}{cmd}    legendpos(NONE)                                           ///{p_end}
{phang}{cmd}    targetsheet("Auto") anchor(O15) width(640) height(360){p_end}

{phang}Multi-series example -- price by gear ratio and weight:{p_end}

{phang}{cmd}googlesheets addchart using "$SS", sheet("Auto") type(scatter) ///{p_end}
{phang}{cmd}    domain(K2:K75)                                             ///{p_end}
{phang}{cmd}    series(B2:B75)                                             ///{p_end}
{phang}{cmd}    names("Price")                                             ///{p_end}
{phang}{cmd}    title("Price vs gear ratio")                               ///{p_end}
{phang}{cmd}    xlabel("Gear ratio") ylabel("Price")                       ///{p_end}
{phang}{cmd}    legendpos(NONE)                                            ///{p_end}
{phang}{cmd}    targetsheet("Auto") anchor(O35) width(560) height(360){p_end}

{phang}Diverging-style stacked bar across categories (Sheets has no native
diverging chart; this stacks normally with a red-to-blue palette):{p_end}

{phang}{cmd}googlesheets addchart using "$SS", sheet("Auto") type(stacked_bar) ///{p_end}
{phang}{cmd}    domain(A2:A11) series(B2:B11)                                  ///{p_end}
{phang}{cmd}    names("Price")                                                 ///{p_end}
{phang}{cmd}    colors("#10487F") title("First 10 makes")                      ///{p_end}
{phang}{cmd}    legendpos(NONE)                                                ///{p_end}
{phang}{cmd}    targetsheet("Auto") anchor(O60) width(560) height(400){p_end}

{phang}Donut variant -- pie with 50% inner hole:{p_end}

{phang}{cmd}googlesheets addchart using "$SS", sheet("Auto") type(donut) ///{p_end}
{phang}{cmd}    domain(A2:A11) series(F2:F11) piehole(0.5)               ///{p_end}
{phang}{cmd}    title("Trunk space (first 10 rows)")                     ///{p_end}
{phang}{cmd}    legendpos(BOTTOM)                                        ///{p_end}
{phang}{cmd}    targetsheet("Auto") anchor(O90) width(420) height(340){p_end}


{dlgtab:8.  Read the Sheet back into Stata for round-trip QA}

{phang}{cmd}googlesheets import using "$SS", sheet("Auto") range("A1:L75") firstrow clear{p_end}
{phang}{cmd}list make price mpg in 1/5, abbrev(15) noobs{p_end}

{pstd}{cmd:firstrow} maps row 1 to Stata variable names.  Without it every
cell is treated as data and Stata auto-names columns {it:v1 v2 ...}.{p_end}


{dlgtab:9.  Append more rows on a subsequent run}

{phang}{cmd}sysuse auto, clear{p_end}
{phang}{cmd}keep in 1/5                                   // stand-in for new rows{p_end}
{phang}{cmd}googlesheets export using "$SS", sheet("Auto") append{p_end}

{pstd}{cmd:append} adds the current dataset below the existing rows.  The
{cmd:firstrow(variables)} option is intentionally NOT passed here -- you'd
end up with a duplicate header in the middle of the data.{p_end}


{marker forms}{...}
{title:Working with Google Forms response sheets}

{pstd}When a Form writes to a Sheet, every response is a new row appended to
{bf:Form Responses 1}.  Two helpers make incremental ingestion painless:{p_end}

{phang}{ul:Pull only new responses since a date}{p_end}
{phang}{cmd}googlesheets import using "$SS", sheet("Form Responses 1") firstrow clear ///{p_end}
{phang}{cmd}    since(Timestamp=2026-01-01){p_end}

{pstd}{cmd:since(column=value)} keeps rows where the named column is greater
than or equal to the value.  {it:column} is the header text in row 1 of the
Sheet (as typed there, before any lowercasing) or a 0-based column number.
When both sides parse as numbers they are compared as numbers; when both parse
as dates or date-times (for example {bf:2026-01-01}, {bf:2026-07-04 9:00:00}, or
{bf:7/4/2026}) they are compared as date-times; otherwise they are compared as
text.{p_end}

{phang}{ul:Pull only the last N responses}{p_end}
{phang}{cmd}googlesheets import using "$SS", sheet("Form Responses 1") firstrow clear tail(50){p_end}

{phang}{ul:Pull only respondents matching a column condition (post-import)}{p_end}
{phang}{cmd}googlesheets import using "$SS", sheet("Form Responses 1") firstrow clear{p_end}
{phang}{cmd}keep if email == "foo@bar.org"{p_end}

{pstd}For column-equality filters, importing the whole sheet and applying
Stata's {cmd:if} clause is simplest.  For very large response sheets,
combine {cmd:since()} + {cmd:tail()} so that no more rows than you asked
for enter Stata (the helper filters the reply before loading it).{p_end}


{marker tips}{...}
{title:Tips, gotchas, and headless / scheduled runs}

{phang}-- {ul:Tabs must exist before you write to them.}  {cmd:googlesheets
export} and {cmd:put} both fail if the target sheet doesn't exist.  Create
it first with {cmd:googlesheets addsheet, title("...")} (the helpfile examples
above always do this).{p_end}

{phang}-- {ul:Tab names are case-sensitive.}  {bf:Auto} and {bf:auto} are two
different tabs.{p_end}

{phang}-- {ul:Ranges follow A1 notation.}  {bf:A1} is a single cell; {bf:A1:E10}
is a rectangle; {bf:'My Sheet'!A1:E10} is an A1 with explicit sheet name
(equivalent to passing the sheet via {cmd:sheet()}).{p_end}

{phang}-- {ul:Tab names with apostrophes.}  A name such as {bf:Bob's data} can be
passed to {cmd:sheet()} as is; the wrapper writes it as {bf:'Bob''s data'} in
A1 notation.  {cmd:r(sheets)} joins tab names with {bf:|}, so a {bf:|} inside a
tab name is shown there as a space.{p_end}

{phang}-- {ul:Headless / scheduled runs.}  OAuth needs a browser the first
time per machine.  After that the cached refresh token in {bf:token.json}
lets later runs, including batch runs on the same machine, proceed without a
browser.  For a machine with no browser at all (a scheduled server job, for
example), use a service account instead: in the Google Cloud console create a
service account, download its JSON key, share the spreadsheet with the
service account's e-mail address (as an editor), and point {cmd:keyfile()} or
{cmd:$GS_CLIENT} at the key.  {cmd:googlesheets} recognizes a service-account
key from the file itself and signs in with no browser and no token file.{p_end}

{phang}-- {ul:Token expiry.}  While the OAuth consent screen is in Google's
{it:Testing} status, Google issues refresh tokens that expire after about seven
days.  When one expires the next call opens the browser again; click Allow and
you're back.  Publishing the consent screen ({it:In production}) removes that
seven-day limit.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:googlesheets import} stores the following in {cmd:r()}:{p_end}
{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations loaded{p_end}
{synopt:{cmd:r(k)}}number of variables loaded{p_end}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(spreadsheet)}}the spreadsheet id or URL as given{p_end}
{synopt:{cmd:r(sheet)}}the tab that was read{p_end}

{pstd}{cmd:googlesheets create} stores:{p_end}
{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(id)}}the new spreadsheet id{p_end}
{synopt:{cmd:r(url)}}the new spreadsheet URL{p_end}
{synopt:{cmd:r(spreadsheet)}}the URL again, for use in later {cmd:using} or {cmd:spreadsheet()}{p_end}
{synopt:{cmd:r(title)}}the spreadsheet title{p_end}

{pstd}{cmd:googlesheets ping} stores:{p_end}
{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(title)}}the spreadsheet title{p_end}
{synopt:{cmd:r(sheets)}}the tab names, separated by {bf:|}{p_end}
{synopt:{cmd:r(client_json)}}the OAuth client JSON path used{p_end}
{synopt:{cmd:r(token_json)}}the token cache path used{p_end}

{pstd}{cmd:googlesheets list} stores {cmd:r(sheets)}, the tab names separated
by {bf:|}.  {cmd:googlesheets addsheet} stores {cmd:r(title)} and
{cmd:r(sheetId)} of the new tab.  {cmd:export}, {cmd:put}, {cmd:format},
{cmd:addchart}, {cmd:deletesheet}, and {cmd:renamesheet} store nothing in
{cmd:r()}.{p_end}


{title:Author and license}

{phang}Authored by Eric A. Booth, Sr Researcher, Texas2036.org (eric.a.booth@gmail.com), 2026.  MIT-licensed.  Built atop
the Google Sheets API; this package is not affiliated with Google.{p_end}

{phang}Thanks to Marshall W. Garland and Elizabeth Teas for debugging, review, and input.{p_end}
