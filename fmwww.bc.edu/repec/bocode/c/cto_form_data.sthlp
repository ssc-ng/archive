{smcl}
{* *! version 1.0.0  24sep2026}{...}
{vieweralsosee "ctoclient" "help ctoclient"}{...}
{vieweralsosee "cto_form_data_attachment" "help cto_form_data_attachment"}{...}
{viewerjumpto "Syntax" "cto_form_data##syntax"}{...}
{viewerjumpto "Description" "cto_form_data##description"}{...}
{viewerjumpto "Options" "cto_form_data##options"}{...}
{viewerjumpto "Remarks" "cto_form_data##remarks"}{...}
{viewerjumpto "Examples" "cto_form_data##examples"}{...}
{viewerjumpto "Stored results" "cto_form_data##results"}{...}
{viewerjumpto "Author" "cto_form_data##author"}{...}
{title:Title}

{phang}
{bf:cto_form_data} {hline 2} Download SurveyCTO form data and load it into Stata


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cto_form_data} {it:formid}{cmd:,}
{opt server(servername)}
{opt user:name(username)}
{opt pass:word(password)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt server(servername)}}SurveyCTO server name, the part before {it:.surveycto.com}{p_end}
{synopt:{opt user:name(username)}}SurveyCTO username (usually an e-mail address){p_end}
{synopt:{opt pass:word(password)}}SurveyCTO password{p_end}

{syntab:Optional}
{synopt:{opt key(filename)}}private key ({it:.pem}) for encrypted forms{p_end}
{synopt:{opt date(#)}}only submissions after this Unix timestamp (seconds, UTC); default is 1 January 2000{p_end}
{synopt:{opt save(filename)}}save the data as a {it:.dta} file{p_end}
{synopt:{opt replace}}overwrite existing files named by {cmd:save()} and {cmd:keepjson}{p_end}
{synopt:{opt keepjson}}keep the downloaded JSON file{p_end}
{synopt:{opt allstr:ing}}store all variables as strings{p_end}
{synopt:{opt clear}}replace the data in memory{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cto_form_data} downloads the submissions of one SurveyCTO form through the
SurveyCTO REST API (wide JSON format) and loads them into memory as a Stata
dataset. It works in three steps:

{phang2}1. The data are downloaded with {cmd:curl}.{p_end}
{phang2}2. The JSON file is parsed in Mata, which makes the command very fast,
memory-efficient and robust. The parser processes whole blocks of the file with
vectorised operations rather than looping over values in Stata, and it reads the
file in pieces of 8 MB, so memory use does not grow with the size of the download.
Text in any language is kept exactly as SurveyCTO sent it.{p_end}
{phang2}3. The data are prepared in memory: the SurveyCTO date-time variables
{cmd:SubmissionDate}, {cmd:CompletionDate}, {cmd:starttime} and {cmd:endtime}
are converted to {cmd:%tc}, {cmd:KEY} is checked to identify submissions uniquely,
and the data are compressed and, if requested, saved.{p_end}

{pstd}
Repeat groups are already flattened by SurveyCTO in the wide format
(for example {cmd:member_name_1}, {cmd:member_name_2}, ...).

{pstd}
To download the media files (images, audio, text audits, ...) as well, use
{helpb cto_form_data_attachment}. Both commands are part of the {helpb ctoclient}
package.


{marker options}{...}
{title:Options}

{phang}
{opt server(servername)} specifies the server name. {cmd:myserver},
{cmd:myserver.surveycto.com} and {cmd:https://myserver.surveycto.com} are all accepted.

{phang}
{opt user:name(username)} and {opt password(password)} specify the login of a server
user who is allowed to download data. Neither may contain the {cmd:"} character.
To keep passwords out of do-files and logs, store the password in a global macro
defined in a separate file (see {help cto_form_data##examples:Examples}).

{phang}
{opt key(filename)} specifies the private key used to decrypt an encrypted form.
Without it, only fields marked as publishable are returned for encrypted forms.

{phang}
{opt date(#)} requests only submissions received after the given moment, specified
as a Unix timestamp in seconds (UTC). The default, {cmd:date(946684800)}, is
1 January 2000 00:00 UTC and so returns all submissions. Unlike {cmd:date(0)},
which SurveyCTO allows only once every 5 minutes per server, the default is not
subject to that limit.

{phang}
{opt save(filename)} saves the data under the given file name; {cmd:.dta} is added
if no extension is given.

{phang}
{opt replace} permits {cmd:save()} (and {cmd:keepjson}) to overwrite existing files.
Without {cmd:replace}, the command stops before contacting the server if a file
already exists. {cmd:replace} may only be specified with {cmd:save()}.

{phang}
{opt keepjson} keeps the downloaded JSON file. It is stored next to the
{it:.dta} file when {cmd:save()} is specified, and otherwise in the working
directory as {it:formid}{cmd:.json}.

{phang}
{opt allstring} stores all variables as strings. By default, a variable is stored
as {cmd:double} when every non-empty value is a number of at most 15 characters
without a leading zero; values such as phone numbers and IDs with leading zeros
remain strings.

{phang}
{opt clear} permits the data in memory to be replaced, even if they have changed
since last saved.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Requirements.} {cmd:cto_form_data} requires Stata 15 or newer and the
{cmd:curl} program, which is included in Windows 10 (version 1803) and later,
macOS and most Linux distributions. Type {cmd:shell curl --version} to check.

{pstd}
{bf:Working files.} The download is written to {cmd:__cto_}{it:formid}{cmd:.json}
and {cmd:__cto_}{it:formid}{cmd:.code} in the working directory, which must be
writable. Both files are deleted when the command finishes, whether it succeeds
or fails.

{pstd}
{bf:Errors.} When the server refuses a request, {cmd:cto_form_data} reports the
HTTP status and its likely cause, for example a wrong server name, a wrong form ID,
a rejected login (HTTP 401) or the 5-minute limit on full downloads (HTTP 417),
together with the message returned by the server.

{pstd}
{bf:Variable names.} Field names are converted to valid Stata names with at most
32 characters. Variables whose names had to be changed are labeled with the
original field name.


{pstd}
{bf:Storing the password.} Rather than typing the password in your do-files, store
it once in {cmd:profile.do}, the do-file that Stata runs automatically every time
it starts. Add this line to {cmd:profile.do}:

{phang2}{cmd:global sctopassword "your-password"}{p_end}

{pstd}
The global macro {cmd:$sctopassword} is then defined in every Stata session, and
your do-files only contain {cmd:password("$sctopassword")}. Save {cmd:profile.do}
in your home folder or in your {cmd:PERSONAL} folder (type {cmd:sysdir} to see
where it is), not in a project folder that is shared with others. The password is
stored as plain text, so keep the file private. The macro is available from the
next time Stata starts.


{marker examples}{...}
{title:Examples}

{pstd}The examples assume that {cmd:$sctopassword} is defined in {cmd:profile.do}
(see {help cto_form_data##remarks:Remarks}).{p_end}

{pstd}Download all submissions and keep them in memory{p_end}
{phang2}{cmd:. cto_form_data hh_survey, server(myserver) username(me@org.org) pass("$sctopassword") clear}{p_end}

{pstd}Download and save as a .dta file{p_end}
{phang2}{cmd:. cto_form_data hh_survey, server(myserver) username(me@org.org) pass("$sctopassword")} ///{p_end}
{phang3}{cmd:save("data/hh_survey.dta") replace clear}{p_end}

{pstd}Download only submissions received after 24 September 2025, 00:00 UTC{p_end}
{phang2}{cmd:. cto_form_data hh_survey, server(myserver) username(me@org.org) pass("$sctopassword")} ///{p_end}
{phang3}{cmd:date(1758672000) clear}{p_end}

{pstd}Unix timestamp for a given moment (UTC){p_end}
{phang2}{cmd:. display %12.0f (tc(24sep2025 00:00:00) - tc(01jan1970 00:00:00)) / 1000}{p_end}

{pstd}Several forms{p_end}
{phang2}{cmd:. foreach f in hh_survey hh_listing {c -(}}{p_end}
{phang3}{cmd:cto_form_data `f', server(myserver) username(me@org.org) pass("$sctopassword")} ///{p_end}
{phang3}{cmd:save("data/`f'.dta") replace clear}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cto_form_data} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of submissions{p_end}
{synopt:{cmd:r(k)}}number of variables{p_end}

{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(file)}}name of the saved {it:.dta} file, if {cmd:save()} was specified{p_end}
{synopt:{cmd:r(json)}}name of the kept JSON file, if {cmd:keepjson} was specified{p_end}


{marker author}{...}
{title:Author}

{pstd}
Gutama Girja Urago{break}
Laterite{break}
{browse "mailto:gurago@laterite.com":gurago@laterite.com}

{pstd}
Please report bugs and suggestions to the author by opening an issue {browse "https://github.com/GutUrago/stata-ctoclient/issues":on Github here}
.
