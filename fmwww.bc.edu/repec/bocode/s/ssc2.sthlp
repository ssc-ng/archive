{smcl}
{* *! version 3.0.0  29sep2026}{...}
{vieweralsosee "[R] ssc2" "mansection R ssc2"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] ssc" "help ado update"}{...}
{viewerjumpto "Syntax" "ssc2##syntax"}{...}
{viewerjumpto "Description" "ssc2##description"}{...}
{viewerjumpto "Command overview" "ssc2##overview"}{...}
{viewerjumpto "Options for selecting a snapshot" "ssc2##options_snapshot"}{...}
{viewerjumpto "Options for use with ssc2 install" "ssc2##options_ssc2_install"}{...}
{viewerjumpto "Options inherited from ssc" "ssc2##options_inherited"}{...}
{viewerjumpto "Keeping packages up to date" "ssc2##adoupdate"}{...}
{viewerjumpto "Examples" "ssc2##examples"}{...}
{p2colset 1 12 14 2}{...}
{p2col:{bf:ssc2} {hline 2}}Install and uninstall packages from SSC, including from date-based snapshots of an SSC mirror{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}



{phang}
Describe a specified package at SSC mirror

{p 8 12 2}
{cmd:ssc2}
{opt d:escribe}
{c -(} {it:pkgname} | {it:letter} {c )-}
[{cmd:,}
{cmd:saving(}{it:{help filename}}[{cmd:, replace}]{cmd:)}
{opt date(datespec)}
{opt from(url)}]



{phang}
Install a specified package from SSC mirror

{p 8 12 2}
{cmd:ssc2}
{opt inst:all}
{it:pkgname}
[{cmd:,}
{opt all}
{opt replace}
{opt update}
{opt replaceall}
{opt date(datespec)}
{opt from(url)}]




{phang}
Type a specific file stored at SSC mirror

{p 8 12 2}
{cmd:ssc2}
{opt type}
{it:{help filename}}
[{cmd:, asis}
{opt date(datespec)}
{opt from(url)}]


{phang}
Copy a specific file from SSC mirror to your computer

{p 8 12 2}
{cmd:ssc2}
{opt copy}
{it:{help filename}}
[{cmd:,}
{opt pl:us}
{opt p:ersonal}
{opt replace}
{opt pub:lic}
{opt bin:ary}
{opt date(datespec)}
{opt from(url)}]


{p 4 6 2}
where {it:letter} in {opt ssc2 describe} is {opt a}-{opt z} or {opt _},
and {it:datespec} is a date in {bf:YYYY-MM-DD} format or the word
{bf:latest}.


{marker description}{...}
{title:Description}

{pstd}
{opt ssc2} works with packages (and files) from the Statistical Software
Components (SSC) archive.  It extends the official {helpb ssc} command with
the ability to install packages {it:as they existed on a given date}, using
date-based snapshots of the SSC archive stored in the
{browse "https://github.com/ssc-ng/archive":ssc-ng/archive}
repository.  This supports reproducibility: an analysis can be re-run with
the exact package versions that were current at a given date.

{pstd}
{cmd:ssc2} is a strict superset of {cmd:ssc}.  Anything {cmd:ssc} does,
{cmd:ssc2} does identically: the subcommands {cmd:new}, {cmd:hot}, and
{cmd:uninstall} are always passed through to {helpb ssc}, and
{cmd:describe}, {cmd:install}, {cmd:type}, and {cmd:copy} are passed
through whenever neither {opt date()} nor {opt from()} is specified.
For the behavior and options of the passed-through subcommands, see
{helpb ssc}.  Only the parts that differ are documented here.

{pstd}
Daily snapshots exist from {bf:2021-12-21} onward; three earlier snapshots
exist ({bf:2017-08-10}, {bf:2021-04-15}, {bf:2021-08-10}).  Type
{cmd:ssc2 snapshots} for details.


{marker overview}{...}
{title:Command overview}

{pstd}
Subcommands that accept {opt date()} and {opt from()}, and therefore can
act on a snapshot:

{phang}
{opt ssc2 install} {it:pkgname} installs the specified package, from a
    dated snapshot when {opt date()} is given.  See
    {help ssc2##options_snapshot:Options for selecting a snapshot} and
    {help ssc2##options_ssc2_install:Options for use with ssc2 install}.

{phang}
{opt ssc2 describe} {it:pkgname} describes, but does not install, the
    specified package as it stood in the selected snapshot.  Give a single
    letter, {opt a}-{opt z} or {opt _}, instead of a package name to list
    all packages starting with that letter in that snapshot.

{phang}
{opt ssc2 type} {it:{help filename}} and {opt ssc2 copy} {it:filename}
    display and copy an individual file from the selected snapshot.
    {opt ssc2 cat} and {opt ssc2 cp} are synonyms.

{pstd}
Subcommands specific to {cmd:ssc2}:

{phang}
{opt ssc2 snapshots} reports the snapshot coverage of the mirror and how
    to point {cmd:ssc2} at a different one.

{phang}
{opt ssc2 versions} {it:pkgname} is not yet implemented.  It will list the
    versions of a package available across snapshots.

{pstd}
Subcommands passed through to {helpb ssc} unchanged:
{opt ssc2 new} ({opt whatsnew}), {opt ssc2 hot} ({opt whatshot}), and
{opt ssc2 uninstall}.  Their options are documented in {helpb ssc}.


{marker options_snapshot}{...}
{title:Options for selecting a snapshot (describe, install, type, copy)}

{phang}
{opt date(datespec)} selects the snapshot of the SSC archive as of the
    specified date.  {it:datespec} is either a date in {bf:YYYY-MM-DD}
    format (for example, {cmd:date(2022-01-07)}) or {bf:latest}, which uses
    the most recently mirrored state of the archive.  If no snapshot exists
    for the specified date, an error message points to the
    {browse "https://github.com/ssc-ng/archive/tags":list of available snapshot dates}.

{phang}
{opt from(url)} specifies the base URL of the snapshot mirror.
    If {opt from()} is not specified, the URL is taken from the Stata
    global {cmd:SSC2_MIRROR} if that is set; otherwise from the
    environment variable {cmd:SSC2_MIRROR} if that is set; otherwise the
    built-in default
    {cmd:https://raw.githubusercontent.com/ssc-ng/archive}
    is used.  The overrides exist because the mirror may move to a
    different host; they also let you point at your own clone, which must
    use the same layout
    ({it:url}{cmd:/}{it:ref}{cmd:/fmwww.bc.edu/repec/bocode/}).
    The analogous {cmd:SSC2_MIRROR_API} global or environment variable
    overrides the API endpoint used only for diagnosing failed snapshot
    lookups.


{marker options_ssc2_install}{...}
{title:Options for use with ssc2 install}

{pstd}
When a snapshot is requested with {opt date()} or {opt from()},
{cmd:ssc2 install} compares the requested snapshot with any installed
copy of the same package, using the snapshot date recorded in the
installed copy's source; a copy installed from SSC directly carries no
snapshot date and cannot be compared.  Because repeated dated installs
would otherwise accumulate multiple entries in the ado directory (each
snapshot is a distinct source URL, and {cmd:ado uninstall} would then
report that more than one package matches), each of the three options
below removes the superseded copies before installing.

{phang}
{opt replace} reinstalls the {it:same} snapshot.  If an installed copy is
    from a different snapshot, or has no snapshot date, the install is
    refused and the message points to {opt update} and {opt replaceall}.
    Without {opt date()} or {opt from()}, {opt replace} has its usual
    {cmd:ssc} meaning (see {help ssc2##options_inherited:below}), except
    that a snapshot-installed copy of the package is retired first so the
    package remains singly tracked.

{phang}
{opt update} (only with {opt date()} or {opt from()}) installs the
    requested snapshot only if it is newer than every installed copy of
    the package.  If the installed copy is the same age or newer, nothing
    is done.

{phang}
{opt replaceall} (only with {opt date()} or {opt from()}) replaces any
    installed version of the package without comparing versions; this is
    the option to use for downgrading, and the only applicable one with
    {cmd:date(latest)}.

{pstd}
If none of the three is specified and any file of the package already
exists, nothing is downloaded or installed, exactly as with {cmd:ssc}.


{marker options_inherited}{...}
{title:Options inherited from ssc}

{pstd}
The following options behave exactly as they do in {cmd:ssc}, and are
documented in {helpb ssc}: {opt all} with {cmd:ssc2 install};
{opt replace} with {cmd:ssc2 install} when no snapshot is requested (see
{help ssc2##options_ssc2_install:above} for the snapshot case);
{cmd:saving()} with {cmd:ssc2 describe} and {cmd:ssc2 new};
{opt type} with {cmd:ssc2 new}; {cmd:n()} and {cmd:author()} with
{cmd:ssc2 hot}; {opt asis} with {cmd:ssc2 type}; and {opt plus},
{opt personal}, {opt replace}, {opt public}, and {opt binary} with
{cmd:ssc2 copy}.


{marker adoupdate}{...}
{title:Keeping packages up to date}

{pstd}
{helpb ado update} checks each installed package against the source it
was installed from and updates those that have changed.  Packages
installed by {cmd:ssc2} from a dated snapshot record that snapshot's URL
as their source, and a snapshot never changes, so {cmd:ado update} leaves
them as they are: a pinned package stays pinned.  Packages installed
without {opt date()} come from SSC itself and are updated normally.

{pstd}
To move a pinned package to a different snapshot, install it again with
the new {opt date()} and {opt update} (to move forward only) or
{opt replaceall} (to move in either direction).  To return a package to
ordinary SSC tracking, install it without {opt date()}, using
{opt replace}.

{pstd}
Use {cmd:ssc2 uninstall} (a synonym for {helpb ado uninstall}) to remove a
package, however it was installed.


{marker examples}{...}
{title:Examples}


{pstd}Describe the package {cmd:oaxaca}{p_end}
{phang2}{cmd:. ssc2 describe oaxaca}

{pmore}
    This passes through the request to {cmd:ssc}, describing the package on SSC.

{pstd}Describe the package {cmd:oaxaca} as of a specific date{p_end}
{phang2}{cmd:. ssc2 describe oaxaca, date(2022-01-07)}

{pstd}Install package {cmd:oaxaca} as of a specific date{p_end}
{phang2}{cmd:. ssc2 install oaxaca, date(2022-01-07)}

{pstd}Uninstall previously installed package {cmd:oaxaca}{p_end}
{phang2}{cmd:. ssc2 uninstall oaxaca}

{pmore}
    This uninstalls the installed copy of {cmd:oaxaca}, regardless of how it was installed.

