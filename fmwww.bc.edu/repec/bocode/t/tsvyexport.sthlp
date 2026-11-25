{smcl}
{* *! version 1.37  23nov2026}{...}
{vieweralsosee "tsvyexport (en espanol)" "help tsvyexport_es"}{...}
{viewerjumpto "Syntax" "tsvyexport##syntax"}{...}
{viewerjumpto "Description" "tsvyexport##description"}{...}
{viewerjumpto "Options" "tsvyexport##options"}{...}
{viewerjumpto "Remarks: wide()" "tsvyexport##wide"}{...}
{viewerjumpto "Examples" "tsvyexport##examples"}{...}
{viewerjumpto "Stored results" "tsvyexport##results"}{...}
{viewerjumpto "Author" "tsvyexport##author"}{...}
{viewerjumpto "Also see" "tsvyexport##also_see"}{...}
{hline}
{title:Title}

{phang}
{bf:tsvyexport} {hline 2} Export a {helpb tsvy} accumulator frame to Excel or Word

{phang}
{it:Version {bf:1.37} (23nov2026)}{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:tsvyexport using} {it:filename} {cmd:}[{cmd:,} {it:options}{cmd:]}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt frame(name)}}accumulator frame to read. Default: {bf:ACUM_ALL}{p_end}
{synopt:{opt excel}}force Excel output regardless of the file extension{p_end}
{synopt:{opt word}}force Word output regardless of the file extension{p_end}
{synopt:{opt sheet(string)}}Excel worksheet name. Default: {bf:tsvy}{p_end}
{synopt:{opt title(string)}}title text placed above the table (Word) or used only for the message on screen (Excel){p_end}
{synopt:{opt numero(string)}}INEI-style table number (chapter.number, e.g. {cmd:"5.1"}) placed before the title, which is then uppercased. Word only{p_end}
{synopt:{opt unidad(string)}}measurement unit shown in parentheses on a line below the title (e.g. {cmd:"Hectareas"} prints as {cmd:"(Hectareas)"}). Word only{p_end}
{synopt:{opt fuente(string [, tamano(#)])}}source line at the foot of the table, printed as {cmd:"Fuente: "}+text+{cmd:"."} (e.g. {cmd:fuente("INEI - Encuesta Nacional Agropecuaria", tamano(9))}). {opt tamano(#)} is an optional suboption (font size in points, default {bf:9}). {opt wide}+Word only; omit for no source line{p_end}
{synopt:{opt elaboracion(string [, tamano(#)])}}"prepared by" line at the foot of the table, printed as {cmd:"Elaboracion: "}+text+{cmd:"."}, with the same optional {opt tamano(#)} suboption. {opt wide}+Word only; omit for no line{p_end}
{synopt:{opt estilo(string)}}format preset for the {opt wide}+Word table: {cmd:clasico}, {cmd:apa7}, or {cmd:revista} -- font, sizes, and (for {cmd:apa7}/{cmd:revista}) a three-line border. Omit for the plain Word default (unchanged from before this option existed). {opt wide}+Word only{p_end}
{synopt:{opt keep(varlist)}}export only these columns, in this order. Default: all columns in the frame{p_end}
{synopt:{opt replace}}overwrite the output file{p_end}
{synopt:{opt append}}add the table as a new sheet (Excel) or a new section (Word) to an existing file{p_end}
{synopt:{opt digits(#)}}decimal places for continuous estimate columns (ESTIMA, ERROR_ST, CV, LIM_INF, LIM_SUP, F_WALD, EFFECT_MMD). Default: {bf:2}{p_end}
{synopt:{opt wide}}one row per level/category/analysis variable, one column per year, instead of one row per year -- see {help tsvyexport##wide:Remarks} below. Cannot be combined with {opt keep()}{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:tsvyexport} writes the results table built by {helpb tsvy} (an
accumulator frame such as {bf:ACUM_ALL}, one row per level/category/year)
to a standalone Excel (.xlsx) or Word (.docx) file, formatted for reading
outside Stata. The format is taken from {opt excel}/{opt word} if given,
otherwise inferred from the extension of {it:filename}.

{pstd}
The original frame is never modified: {cmd:tsvyexport} works on a
temporary copy, applies column-appropriate number formats there, and
discards the copy when it finishes.

{pstd}
{opt replace} and {opt append} follow the same convention in both
formats: {opt replace} recreates the output file from scratch;
{opt append} adds the current export as a new, separate unit (a new
worksheet in Excel, a new section after a page break in Word) without
disturbing whatever the file already contains. If the file does not
exist yet, {opt append} behaves like a first, plain export. If the file
already exists and neither option is given, {cmd:tsvyexport} stops with
an error instead of silently overwriting it.

{marker options}{...}
{title:Options}

{phang}
{opt frame(name)} names the frame to export. This is the same name
passed to {helpb tsvy}'s own {cmd:frame()} option when the table was
built; it defaults to {bf:ACUM_ALL} because that is also {cmd:tsvy}'s
own default.

{phang}
{opt keep(varlist)} restricts and reorders the exported columns. Every
name must exist in the frame; {helpb tsvy}'s frame layout is documented
in {help tsvy##frame:its own help file}.

{phang}
{opt digits(#)} only affects the continuous estimate columns. Counts
(ANIO, N_SIN_PON, N_PONDERA) are always shown as integers, and p-values
(P_WALD, P_VS_REF, P_MMD) are always shown with 3 decimals, regardless
of {opt digits()}.

{phang}
{opt numero(string)} and {opt unidad(string)} follow the numbering
convention set by INEI's official "Manual para la presentacion de
cuadros estadisticos": the table number is a chapter.number code (for
example {cmd:"5.1"} or {cmd:"23.115"}), placed immediately before the
title on the same line, with the title itself in uppercase; the
measurement unit, when it applies to the whole table, goes on its own
line right below, in parentheses (for example {cmd:"(Hectareas)"}). Both
options only affect Word output ({opt wide} or plain); with Excel they
are accepted but have no effect, same as {opt title()}. {opt numero()}
uppercases whatever {opt title()} holds (or the {cmd:VARNAME} used as a
fallback title in {opt wide}); without {opt numero()}, the title is left
exactly as given, same as before this option existed.

{phang}
{bf:New in v1.19:} {opt fuente()} and {opt elaboracion()} follow the
"Pie del cuadro" (footer) convention of the same INEI manual, which
lists notes, callouts, source, and preparer, in that order, at the foot
of the table. When given, they add a {cmd:"Fuente: ..."} line and an
{cmd:"Elaboracion: ..."} line after the Sig./Grupos legend. Font size
lives INSIDE each option as a {opt tamano(#)} suboption (points,
default {bf:9}, smaller than the document body, matching the manual's
own examples) -- e.g. {cmd:fuente("INEI - Direccion X", tamano(8))} --
rather than a separate top-level option, so {opt fuente()} and
{opt elaboracion()} can use different sizes if needed. Both options are
optional and independent of each other; omitting one just skips that
line, and omitting {opt tamano()} inside one just uses the default. Text
with a comma (needed before {opt tamano()} can appear) must be quoted,
e.g. {cmd:fuente("INEI, Encuesta Nacional Agropecuaria")}. {opt wide}+
Word only (same restriction as {opt numero()}/{opt unidad()}).

{phang}
{bf:New in v1.21:} {opt estilo(string)} applies a format preset to the
{opt wide}+Word table -- font, sizes for title/header/body/notes, and
(for {cmd:apa7}/{cmd:revista}) a border style. Researched because the
INEI manual itself specifies no typography at all (only a generic
warning not to distort "the standard typeface" when scaling for print);
the presets below come from real style guides found for statistical
agencies and academic publishing:

{p2colset 9 26 28 2}{...}
{p2col:{cmd:clasico}}Arial Narrow -- title 10pt bold, header 8pt bold,
body 8pt, notes 7pt. Backed by INDEC's (Argentina) own written style
manual, which specifies Helvetica/Arial Bold ~10pt titles and 7pt body
text for statistical tables -- the closest real precedent found, since
INEI's own manual is silent on this.{p_end}
{p2col:{cmd:apa7}}Times New Roman, 12pt throughout (10pt for
{opt fuente()}/{opt elaboracion()}), following the official APA 7th
edition rules for tables at apastyle.apa.org: a three-line border (only
above the table, below the header, and at the bottom -- never vertical
lines), and a title in real APA form -- {cmd:"Tabla N"} in bold on its
own line, the title itself in italics below (NOT the single-line
{cmd:"numero MAYUSCULAS"} format that {opt numero()} uses for
{cmd:clasico}/{cmd:revista}/no {opt estilo()}).{p_end}
{p2col:{cmd:revista}}Generic preset for indexed journals that do not
require APA specifically -- same three-line border, Times New Roman,
somewhat smaller sizes (11/10/10/9pt) common in dense results tables.{p_end}
{p2colreset}{...}

{pstd}
Without {opt estilo()}, the table is unchanged from before this option
existed (Word's own default font/size, full grid of borders). A
{opt tamano(#)} passed explicitly inside {opt fuente()}/
{opt elaboracion()} still overrides the preset's notes size. This
option only affects {opt wide}+Word; the plain Word table and Excel
output are unchanged (a smaller follow-up, not yet implemented, could
extend font/size -- not borders, which do not apply to Excel the same
way -- to Excel too). {bf:Confirmed against real Stata (v1.23):} the
{cmd:apa7}/{cmd:revista} border mechanic (clearing the whole table's
borders and then drawing 3 of them back in by row range) checks out --
see Prueba 13 in the accompanying {cmd:test_putdocx_merge.do}.

{pstd}
{bf:v1.24-v1.26 real bug, fixed in v1.27:} with real data, the header
cells to the right of the {cmd:Estimacion} column merge (Var.%/Sig./
Grupos) could come out without their header shading, and, under
{cmd:estilo(apa7)}/{cmd:estilo(revista)}, with a leftover vertical grid
line instead of the three-line style. Root cause: a {cmd:colspan()}
shifts the column address of every cell to its right in that row, and
the header shading/border-clearing for those columns used to run in a
separate step, always {it:after} that shift already happened. v1.27
formats each header cell in the same call as its own
{cmd:rowspan()}/{cmd:colspan()}, before any address shift can affect
it. See Prueba 14 (kept as the failing reference) and Prueba 15 (the
fix) in {cmd:test_putdocx_merge.do}.

{marker wide}{...}
{title:Remarks: wide()}

{pstd}
By default {cmd:tsvyexport} writes the frame as {helpb tsvy} built it --
one row per level/category/year (the "tidy" shape). {opt wide} instead
writes one row per level/category/[cruce]/analysis variable, with a
separate {cmd:ESTIMA}{it:year} column for each year -- the shape used by
side-by-side, year-over-year comparison tables. This is the same pivot
documented as a {cmd:reshape wide} recipe in {help tsvy##frame:tsvy's
own Frame layout section}, done here automatically, together with the
export.

{pstd}
{opt wide} always exports a fixed set of columns (it cannot be combined
with {opt keep()}): the identifying columns ({cmd:NIVEL}, {cmd:CATEGORIA},
{cmd:CRUCE} if present, {cmd:VARNAME}), one {cmd:ESTIMA}{it:year} column
per distinct value of {cmd:ANIO} in the frame, one {cmd:SIG_VS_REF}{it:year}
column per year if the frame has a {cmd:SIG_VS_REF} column (only present
when {helpb tsvy} was run with a reference category), {cmd:F_WALD}/
{cmd:P_WALD} (the omnibus test across years, constant within each row
since it does not vary by year), a {cmd:SIG_WALD} column with
significance stars computed from {cmd:P_WALD} ({cmd:"*"} p<0.10,
{cmd:"**"} p<0.05, {cmd:"***"} p<0.01 -- the same thresholds
{helpb tsvy}'s own {cmd:SIG_VS_REF} uses; since v1.34 only levels at or
below {helpb tsvy}'s {cmd:alpha()} are used, see below), a {cmd:GRUPOS} column
with each year's Compact Letter Display letter joined by a dash (for
example {cmd:"d-c-b-a"}), read off {cmd:tsvy}'s own {cmd:GRUPO} column, and a {cmd:CLD_INCONS}
column (plus {cmd:CLD_METODO} when the frame has it, v1.34).
The frame needs at least 2 distinct years to pivot.

{pstd}
{opt wide} combined with {opt word} builds one table per {cmd:VARNAME}
when the frame has exactly one. It gets a two-row combined header: a
row label ({cmd:NIVEL}/{cmd:CATEGORIA}/{cmd:CRUCE}), {cmd:Estimacion}
merged across all the year columns, and {cmd:Var. %}/{cmd:Sig.}/
{cmd:Grupos} spanning both header rows -- the same shape as a hand-built
year-over-year comparison table. {cmd:Var. %} is the LAST year against
the one right before it (e.g. {cmd:"Var. % 2026/2025"} -- v1.18; before
that, it compared the first and last year of the whole frame). This
matches how official statistics agencies (INEI, central banks, etc.)
define a year-over-year change; there is no option to go back to the
old definition, since there is no real use case for it. {bf:New in
v1.16/v1.17:} that row label uses {cmd:CATEGORIA_LBL}/{cmd:CRUCE_LBL}
(the real value-label text, e.g. {cmd:"Puno"}) instead of the raw
numeric {cmd:CATEGORIA}/
{cmd:CRUCE} code, when the frame has those columns ({helpb tsvy} v1.21
or later) and they are not blank for that row -- shown BY ITSELF, not
prefixed with the {cmd:nivel()} variable's name (v1.17; earlier v1.16
showed {cmd:"departamento Puno"}, now just {cmd:"Puno"}). When
{cmd:CATEGORIA_LBL} is blank for a row, that row falls back to
{cmd:NIVEL}+the numeric code, same as always.

{pstd}
{bf:New in v1.13/v1.14:} with 2 or more distinct {cmd:VARNAME} values,
{opt wide} combined with {opt word} no longer stops with an error -- it
instead builds ONE table with nested rows: {cmd:Categoria} [and
{cmd:Cruce}, if {cmd:CRUCE} is present] merged with a vertical
{cmd:rowspan} across every {cmd:Variable} (={cmd:VARNAME}) row inside
that group, and two leaf columns per year ({cmd:Valor}/{cmd:Sig.},
where {cmd:Sig.} is {cmd:SIG_VS_REF} for that year -- the significance
of that category against the reference category, not the omnibus
test). The omnibus column is kept at the end, renamed {cmd:Sig. Wald}
to avoid confusion with the per-year {cmd:Sig.} column. This shape
needs a body {cmd:rowspan} that starts inside the range of another
body {cmd:rowspan} in a different column, and a header row with
several {cmd:colspan}s (one per year) applied right-to-left -- both
mechanics are confirmed against real Stata in isolation by the
accompanying {cmd:test_putdocx_merge.do} script (Pruebas 7, 9, 11 and
12); {bf:Fixed in v1.36:} this branch used to stop with "not sorted"
r(5); it has since been run end-to-end against real Stata (2
{cmd:VARNAME}s on {cmd:auto.dta}). With exactly 1 {cmd:VARNAME}, the table is
unchanged from the shape described above.

{pstd}
Numbers in this table use a Latin-American style (space thousands
separator, comma decimal, e.g. {cmd:16 681}; {cmd:Var. %} additionally
gets a leading {cmd:+} when positive), regardless of magnitude ({bf:fixed
in v1.20:} very large {cmd:ESTIMA} values, e.g. in the millions, used to
overflow the fixed-width format used internally and print in broken
scientific notation instead, e.g. {cmd:"3,40e+06"}; large numbers now
format correctly). If a {cmd:NIVEL} {cmd:"NACIONAL"}
row is present, it is shaded as a total row and sorted first (v1.15),
matching the INEI manual's own convention of listing a "Total" before
the categories that make it up. {bf:New in v1.30:} when the frame was
built with {helpb tsvy}'s {opt cldmetodo()} (v1.24+), the Grupos legend
shows the adjustment method in parentheses -- e.g. {cmd:"Grupos (Holm):
..."}, {cmd:"Grupos (Fisher LSD): ..."}. A frame built with an older
{cmd:tsvy} (no {opt cldmetodo()} characteristic saved) shows the legend
exactly as before, with no parenthetical. {bf:New in v1.19:} cells follow the
manual's own symbols for special values (p.25): a missing
{cmd:ESTIMA} prints {cmd:"..."} ("not available" -- plain ASCII dots,
not the actual ellipsis character, to keep this file pure ASCII); an
{cmd:ESTIMA} of exactly 0 prints {cmd:"-"} ("zero magnitude"); and an
{cmd:ESTIMA} that is not 0 but rounds to 0 at {opt digits()} decimals
prints a bare {cmd:"0"} ("amount does not reach half a unit"). A
missing {cmd:Var. %} (missing or zero denominator year) prints
{cmd:"..."} too; the zero/half-unit distinction does not apply to a
percentage change, only to level figures. The table is followed by a
short legend explaining {cmd:Sig.}/{cmd:Sig. Wald} and {cmd:Grupos},
and then, when {opt fuente()}/{opt elaboracion()} are given, the
source/preparer lines described above.

{pstd}
{bf:New in v1.34:} {cmd:Sig.} ({cmd:SIG_WALD}) only uses levels at or
below the {cmd:alpha()} with which {helpb tsvy} computed the letters
(0.05 by default: {cmd:**} p<0.05, {cmd:***} p<0.01), so a star never
appears next to letters that do not separate years merely because two
different thresholds were used. If the Wald F is significant and all
years still share a letter, column {cmd:CLD_INCONS} is 1 and
{cmd:GRUPOS} gets the callout {cmd:b/}, explained in the Word legend.
With {helpb tsvy}'s {cmd:cldmetodo(auto)} (default since tsvy v1.29),
rows where an adjustment other than Bonferroni was used show it in
parentheses in {cmd:GRUPOS}, e.g. {cmd:"b-a-a (holm)"}, and the
{cmd:CLD_METODO} column is exported to Excel.

{marker examples}{...}
{title:Examples}

{pstd}
Every example below is self-contained and runs on {cmd:auto.dta}, one of
Stata's built-in example datasets, the same setup used in
{help tsvy##examples:tsvy's own examples} -- {cmd:sysuse auto} is
enough, no external data needed. Each example first calls
{helpb tsvy} to build (or add to) an accumulator frame, then
{cmd:tsvyexport} to write it out; only the {cmd:tsvyexport} line is new
here.

{phang2}{cmd:* Setup}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen long psu_id = _n}{p_end}
{phang2}{cmd:. svyset psu_id}{p_end}
{phang2}{cmd:. gen byte NACIONAL = 1}{p_end}
{phang2}{cmd:. gen int ANIO_ = 2021 + mod(_n, 3)}{p_end}
{phang2}{cmd:. gen byte precio_alto = (price > 6000)}{p_end}

{pstd}
Builds the default {bf:ACUM_ALL} frame, then exports it -- {cmd:.xlsx}
is enough for {cmd:tsvyexport} to know to write Excel:{p_end}
{phang2}{cmd:* Example 1: basic export, format inferred from the extension}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) frame(ACUM_ALL) replace}{p_end}
{phang2}{cmd:. tsvyexport using resultados.xlsx}{p_end}

{pstd}
{cmd:frame()} on both the {cmd:tsvy} and the {cmd:tsvyexport}
call has to name the same frame:{p_end}
{phang2}{cmd:* Example 2: Word, with a title, from a non-default frame}{p_end}
{phang2}{cmd:. tsvy, varname(weight) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL foreign) frame(MIACUM) replace}{p_end}
{phang2}{cmd:. tsvyexport using resultados.docx, frame(MIACUM) ///}{p_end}
{phang2}{cmd:    title("Peso promedio por region")}{p_end}

{pstd}
A second, independent frame ({cmd:cruce(precio_alto)} this
time) exported with {opt append} into the same {cmd:resultados.xlsx}
from example 1, as its own sheet -- the {cmd:tsvy} sheet from example 1
is untouched:{p_end}
{phang2}{cmd:* Example 3: append -- adds a new sheet, keeps the first one}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) cruce(precio_alto) frame(ACUM2) replace}{p_end}
{phang2}{cmd:. tsvyexport using resultados.xlsx, frame(ACUM2) ///}{p_end}
{phang2}{cmd:    sheet(mpg_por_precio) append}{p_end}

{pstd}
Reuses the {bf:ACUM_ALL} frame from example 1, into a separate file:{p_end}
{phang2}{cmd:* Example 4: subset of columns, 3 decimals}{p_end}
{phang2}{cmd:. tsvyexport using resumen.xlsx, keep(NIVEL CATEGORIA ANIO ESTIMA ERROR_ST) ///}{p_end}
{phang2}{cmd:    digits(3) replace}{p_end}

{pstd}
Three variables looped into the same frame (same pattern as
{help tsvy##examples:tsvy's own Example 3}), then exported wide: each
row is one indicator, with a column per year plus {cmd:SIG_WALD} and
{cmd:GRUPOS}:{p_end}
{phang2}{cmd:* Example 5: wide -- one row per indicator, one column per year}{p_end}
{phang2}{cmd:local indicadores mpg weight length}{p_end}
{phang2}{cmd:local i = 0}{p_end}
{phang2}{cmd:foreach v of local indicadores {c 123}}{p_end}
{phang2}{cmd:    local i = `i' + 1}{p_end}
{phang2}{cmd:    tsvy, varname(`v') stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:        nivel(NACIONAL) frame(ACUM3) `=cond(`i'==1, "replace", "")'}{p_end}
{phang2}{cmd:{c 125}}{p_end}
{phang2}{cmd:tsvyexport using reporte_ancho.xlsx, frame(ACUM3) wide replace}{p_end}

{pstd}
{opt wide} to a {cmd:.docx} file, a single indicator broken down by
category ({cmd:rep78}, the maintenance rating, standing in for a
department-style breakdown; the 5 cars with a missing rating are
dropped first, same as {help tsvy##examples:tsvy's own Example 6}):
one row per {cmd:rep78} value, with the combined year header described
above:{p_end}
{phang2}{cmd:* Example 6: wide -- Word, combined header, several categories}{p_end}
{phang2}{cmd:. tsvy if rep78 < ., varname(mpg) stat(mean) ///}{p_end}
{phang2}{cmd:    years(2021 2022 2023) nivel(rep78) frame(ACUM4) replace}{p_end}
{phang2}{cmd:. tsvyexport using cuadro_categorias.docx, frame(ACUM4) wide replace}{p_end}

{pstd}
Same table as example 6, this time with the real INEI table-numbering
convention: the chapter.number code goes right before the (now
uppercased) title, and the unit of measurement gets its own line in
parentheses below:{p_end}
{phang2}{cmd:* Example 7: wide -- Word, with INEI-style numero()/unidad()}{p_end}
{phang2}{cmd:. tsvyexport using cuadro_categorias.docx, frame(ACUM4) wide replace ///}{p_end}
{phang2}{cmd:    numero("5.1") title("Rendimiento por categoria de mantenimiento") ///}{p_end}
{phang2}{cmd:    unidad("Millas por galon")}{p_end}

{phang2}{cmd:* Example 8: wide -- Word, with the "Pie del cuadro" footer}{p_end}
{phang2}{cmd:. tsvyexport using cuadro_categorias.docx, frame(ACUM4) wide replace ///}{p_end}
{phang2}{cmd:    numero("5.1") title("Rendimiento por categoria de mantenimiento") ///}{p_end}
{phang2}{cmd:    unidad("Millas por galon") ///}{p_end}
{phang2}{cmd:    fuente("INEI - Encuesta Nacional Agropecuaria", tamano(8)) ///}{p_end}
{phang2}{cmd:    elaboracion("INEI - Direccion de Estadisticas Agrarias")}{p_end}

{phang2}{cmd:* Example 9: wide -- Word, APA 7th edition preset}{p_end}
{phang2}{cmd:. tsvyexport using cuadro_categorias.docx, frame(ACUM4) wide replace ///}{p_end}
{phang2}{cmd:    numero("1") title("Rendimiento por categoria de mantenimiento") ///}{p_end}
{phang2}{cmd:    estilo("apa7")}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tsvyexport} does not leave anything in {cmd:r()}; check
{cmd:_rc} or the screen message it prints on completion.

{marker author}{...}
{title:Author}

{pstd}
Andres Talavera Cuya. Affiliation stated for identification purposes
only -- this software is not an official product of INEI and INEI bears
no responsibility for it. Distributed under the GNU General Public License
v3 (https://www.gnu.org/licenses/gpl-3.0.txt).

{marker also_see}{...}
{title:Also see}

{psee}
Online: {helpb tsvy}, {helpb putexcel}, {helpb putdocx}
{p_end}

{psee}
En espanol: {helpb tsvyexport_es}
{p_end}
