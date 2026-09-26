{smcl}
{* *! version 1.0.0  24sep2026}{...}
{vieweralsosee "ctoclient" "help ctoclient"}{...}
{vieweralsosee "cto_form_data" "help cto_form_data"}{...}
{viewerjumpto "Syntax" "cto_form_data_attachment##syntax"}{...}
{viewerjumpto "Description" "cto_form_data_attachment##description"}{...}
{viewerjumpto "Options" "cto_form_data_attachment##options"}{...}
{viewerjumpto "Remarks" "cto_form_data_attachment##remarks"}{...}
{viewerjumpto "Examples" "cto_form_data_attachment##examples"}{...}
{viewerjumpto "Stored results" "cto_form_data_attachment##results"}{...}
{viewerjumpto "Author" "cto_form_data_attachment##author"}{...}
{title:Title}

{phang}
{bf:cto_form_data_attachment} {hline 2} Download SurveyCTO form data and its media files


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cto_form_data_attachment} {it:formid}{cmd:,}
{opt med:ia(folder)}
{opt server(servername)}
{opt user:name(username)}
{opt pass:word(password)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt med:ia(folder)}}folder for the media files; created if it does not exist{p_end}
{synopt:{opt server(servername)}}SurveyCTO server name, the part before {it:.surveycto.com}{p_end}
{synopt:{opt user:name(username)}}SurveyCTO username (usually an e-mail address){p_end}
{synopt:{opt pass:word(password)}}SurveyCTO password{p_end}

{syntab:Optional}
{synopt:{opt key(filename)}}private key ({it:.pem}) for encrypted forms and their media{p_end}
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
{cmd:cto_form_data_attachment} downloads the submissions of a SurveyCTO form with
{helpb cto_form_data} and then downloads the media files the submissions refer to,
such as images, audio recordings, signatures, videos and text audits.

{pstd}
Media variables are found automatically: a string variable is treated as a media
variable when every non-empty value is a SurveyCTO attachment link of the form

{p 8 8 2}
{it:https://servername}{cmd:.surveycto.com/api/v2/forms/}{it:formid}{cmd:/submissions/uuid:}{it:id}{cmd:/attachments/}{it:filename}

{pstd}
Other links, for example web addresses typed into text fields, are not treated as
media. For every non-empty value, the file is
downloaded into {opt media()} unless a file with the same name is already there,
so running the command again only downloads new files.

{pstd}
All missing files are downloaded in a single {cmd:curl} call, and the list of
files is built in Mata, so even forms with many thousands of media files are
handled quickly.

{pstd}
The data in memory are the form data, exactly as returned by {helpb cto_form_data};
the links are not changed.


{marker options}{...}
{title:Options}

{phang}
{opt media(folder)} specifies the folder where the media files are stored. A
relative path is interpreted from the working directory. The folder is created if
it does not exist, but its parent folder must exist.

{phang}
{opt key(filename)} specifies the private key of an encrypted form. It is used to
decrypt both the data and the media files.

{pstd}
All other options are passed to {helpb cto_form_data}; see
{help cto_form_data##options:its options} for details.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:File names.} Each file is saved under the last part of its link, without the
query string (the part after {cmd:?}); for example
{it:https://myserver.surveycto.com/.../1695729384123.jpg} is saved as
{it:1695729384123.jpg}. These are the names SurveyCTO gives to media files, and
they are the same as in SurveyCTO's own exports. Characters that are not allowed
in file names are replaced by {cmd:_}.

{pstd}
{bf:Download.} All missing files are downloaded with a single call to {cmd:curl},
which reads the list of links from a temporary configuration file
{cmd:__cto_media_}{it:formid}{cmd:.cfg} in the working directory. The file contains
the login and is deleted as soon as the download ends.

{pstd}
{bf:Failed downloads.} A file that cannot be downloaded is not created, so it is
retried the next time the command runs. The command reports the number of failed
files and the HTTP status returned by the server. If a download is interrupted, a
partly written file may remain; delete it and run the command again.


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
(see {help cto_form_data_attachment##remarks:Remarks}).{p_end}

{pstd}Download the data and all media files{p_end}
{phang2}{cmd:. cto_form_data_attachment hh_survey, media("data/media") server(myserver)} ///{p_end}
{phang3}{cmd:username(me@org.org) pass("$sctopassword") save("data/hh_survey.dta") replace clear}{p_end}

{pstd}Media files of an encrypted form{p_end}
{phang2}{cmd:. cto_form_data_attachment hh_survey, media("data/media") server(myserver)} ///{p_end}
{phang3}{cmd:username(me@org.org) pass("$sctopassword") key("keys/hh_survey.pem") clear}{p_end}

{pstd}List the media variables that were found{p_end}
{phang2}{cmd:. display "`r(mediavars)'"}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:cto_form_data_attachment} stores the results of {helpb cto_form_data}
({cmd:r(N)}, {cmd:r(k)}, {cmd:r(file)}, {cmd:r(json)}) and the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(n_files)}}number of distinct media files in the data{p_end}
{synopt:{cmd:r(n_existing)}}number already present in {opt media()} before the download{p_end}
{synopt:{cmd:r(n_downloaded)}}number downloaded{p_end}
{synopt:{cmd:r(n_failed)}}number that could not be downloaded{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(mediavars)}}names of the media variables{p_end}
{synopt:{cmd:r(media)}}full path of the media folder{p_end}


{marker author}{...}
{title:Author}

{pstd}
Gutama Girja Urago{break}
Laterite{break}
{browse "mailto:gurago@laterite.com":gurago@laterite.com}
