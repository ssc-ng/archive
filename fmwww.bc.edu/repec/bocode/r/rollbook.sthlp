{smcl}
{title:Title}

{phang}
{cmd:rollbook} {hline 2} Draw student roll calls from Chinese-language Excel roll files

{title:Description}

{pstd}
{cmd:rollbook} draws students from a class roll stored in an Excel workbook.  Students may
be selected at random ({cmd:n()}), by serial number ({cmd:serial()}), by the parity of the
last digit of the student ID ({cmd:even()}), and by major ({cmd:major()}).  These options
may be combined freely, and the workbook and worksheet to read are given with {cmd:using}
and {cmd:sheet()}.  The selected students are displayed and left in memory.

{pstd}
The program is written for Chinese roll files, and it also accepts English column
headings.  In particular it reads

{p 8 8}* {cmd:.xls} and {cmd:.xlsx} workbooks whose file names are Chinese (for example {it:花名册.xlsx}){p_end}
{p 8 8}* workbooks whose file names mix Chinese, letters and Arabic numerals (for example {it:物流管理2024级1班.xls}){p_end}
{p 8 8}* worksheets whose names are Chinese or mixed (for example {cmd:sheet("学生名单")}){p_end}
{p 8 8}* columns headed in Chinese or in English ({cmd:序号} / {cmd:No}, {cmd:学号} / {cmd:ID}, {cmd:姓名} / {cmd:Name}, {cmd:专业} / {cmd:Major}){p_end}

{title:Syntax}

{p 8 15 2}
{cmd:rollbook} {cmd:using} {it:filename}{cmd:,} [{cmd:n(}{it:integer}{cmd:)} {cmd:serial(}{it:string}{cmd:)} {cmd:even(}{it:string}{cmd:)} {cmd:major(}{it:string}{cmd:)} {cmd:sheet(}{it:name}{cmd:|}{it:#}{cmd:)} {cmd:seed(}{it:integer}{cmd:)}]

{synoptset 22 tabbed}{...}
{synopthdr}{...}
{synoptline}
{synopt:{cmd:n(}{it:integer}{cmd:)}}Number of students to draw at random{p_end}
{synopt:{cmd:serial(}{it:string}{cmd:)}}Serial numbers (序号) to select; spaces or commas separate several values{p_end}
{synopt:{cmd:even(}{it:string}{cmd:)}}Parity of the last digit of the student ID: {cmd:odd} or {cmd:even}{p_end}
{synopt:{cmd:major(}{it:string}{cmd:)}}Select only students of this major (专业){p_end}
{synopt:{cmd:sheet(}{it:name}{cmd:|}{it:#}{cmd:)}}Worksheet to read, by name (Chinese allowed) or by number{p_end}
{synopt:{cmd:seed(}{it:integer}{cmd:)}}Seed of the random draw, for reproducible sampling{p_end}
{synoptline}

{title:Options}

{phang}
{cmd:n(}{it:integer}{cmd:)} draws {it:integer} students at random from the students that
remain after {cmd:serial()}, {cmd:even()} and {cmd:major()} have been applied.  If
{it:integer} is larger than the number of remaining students, all of them are listed.

{phang}
{cmd:serial(}{it:string}{cmd:)} selects students by their serial number (序号).  Several
serial numbers may be given, separated by spaces or by commas.

{phang}
{cmd:even(}{it:string}{cmd:)} keeps the students whose student ID (学号) ends in an odd or
in an even digit.  Specify {cmd:odd} or {cmd:even}; {cmd:奇数} and {cmd:偶数} are also
accepted.

{phang}
{cmd:major(}{it:string}{cmd:)} keeps only the students of the named major (专业).  The
value may be Chinese, English, or a mixture of the two.

{phang}
{cmd:sheet(}{it:name}{cmd:|}{it:#}{cmd:)} reads the named worksheet, or the worksheet in
the given position.  The name may contain Chinese characters, letters and Arabic numerals.
The name is matched exactly; if there is no such worksheet and the value is a number, the
worksheet in that position is read, so {cmd:sheet(2)} reads the second worksheet.  If
neither matches, {cmd:rollbook} lists the worksheets that are available and stops.

{phang}
{cmd:seed(}{it:integer}{cmd:)} sets the seed of the random number generator.  By default a
seed is drawn from the clock, so that two roll calls give different students; give
{cmd:seed()} to reproduce a particular draw.

{title:Examples}

{phang}
{cmd:. rollbook using "rollbook.xlsx", n(5)}

{pstd}
Draws 5 students at random.

{phang}
{cmd:. rollbook using "花名册.xls", n(5)}

{pstd}
Draws 5 students from a workbook whose name is Chinese and whose format is the older .xls.

{phang}
{cmd:. rollbook using "物流管理2024级1班.xls", sheet("学生名单") n(3)}

{pstd}
Reads the worksheet {it:学生名单} of a workbook whose name mixes Chinese and Arabic
numerals, and draws 3 students.

{phang}
{cmd:. rollbook using "ClassA花名册.xlsx", sheet(2) major("物流管理") even(odd) n(4)}

{pstd}
From the second worksheet, keeps the odd-ID students of 物流管理, and draws 4 of them.

{phang}
{cmd:. rollbook using "rollbook.xlsx", major("会计学") even(even)}

{pstd}
Lists every 会计学 student whose student ID ends in an even digit.

{phang}
{cmd:. rollbook using "rollbook.xlsx", serial(8, 18)}

{pstd}
Selects the students whose serial number is 8 or 18.

{title:Required Excel Format}

{pstd}
The worksheet must contain four columns: the serial number, the student ID, the name, and
the major.  The headings may be Chinese or English.  The Chinese names are

{p 8 8}{it:序号} serial number{p_end}
{p 8 8}{it:学号} student ID{p_end}
{p 8 8}{it:姓名} name{p_end}
{p 8 8}{it:专业} major{p_end}

{pstd}
Headings are compared ignoring case, spaces and the separators {cmd:.}, {cmd:-} and
{cmd:_}, so {cmd:Student ID}, {cmd:student_id} and {cmd:STUDENT-ID} all name the student
ID column.  These English headings are recognised as well:

{p 8 8}{cmd:No} {cmd:Num} {cmd:Number} {cmd:Serial} {cmd:Index} {cmd:Seq} {cmd:Order} ({it:序号}, serial number){p_end}
{p 8 8}{cmd:ID} {cmd:SID} {cmd:StuID} {cmd:StudentID} {cmd:StuNo} {cmd:StudentNo} {cmd:StudentNumber} {cmd:IDNo} ({it:学号}, student ID){p_end}
{p 8 8}{cmd:Name} {cmd:StuName} {cmd:StudentName} {cmd:FullName} ({it:姓名}, name){p_end}
{p 8 8}{cmd:Major} {cmd:MajorName} {cmd:Specialty} {cmd:Speciality} {cmd:Department} {cmd:Dept} {cmd:Profession} {cmd:Program} ({it:专业}, major){p_end}

{pstd}
Pinyin headings ({cmd:xuhao}, {cmd:xuehao}, {cmd:xingming}, {cmd:zhuanye}) are accepted
too, and Chinese synonyms such as {it:编号}, {it:学籍号}, {it:学生姓名} and
{it:专业名称} are understood.  If a column cannot be found, {cmd:rollbook} lists the
headings that the worksheet does contain and stops.

{pstd}
The columns may hold numbers or text; {cmd:rollbook} converts them as needed.

{title:Notes}

{phang}
{cmd:Encoding} Save the ado-file, and every do-file that calls it, as UTF-8 so that the
Chinese column names and the file or worksheet names are interpreted correctly.

{phang}
{cmd:Column names} The four required columns may be headed in Chinese or in English (or in
pinyin).  {cmd:rollbook} compares headings after removing case, spaces and the separators
{cmd:.}, {cmd:-} and {cmd:_}, so {cmd:No.}, {cmd:No} and {cmd:no} are treated alike.  The
headings that are recognised are listed under {it:Required Excel Format}.

{phang}
{cmd:File names} If a Stata build cannot open a file whose name contains Chinese
characters, {cmd:rollbook} reads the workbook through a temporary copy with an ASCII name,
so the draw still works.

{phang}
{cmd:Worksheets} To see the worksheet names in a workbook before calling {cmd:rollbook},
type {cmd:import excel using }{it:filename}{cmd:, describe}.  Worksheet names are matched
exactly as they appear in Excel, including Chinese characters.

{phang}
{cmd:Combining options} {cmd:major()}, {cmd:serial()} and {cmd:even()} first keep the
matching students; {cmd:n()} then draws at random from the students that remain.  Any
combination of the options is allowed.

{title:Authors}

{pstd}
Wu Lianghai{p_end}
{pstd}
School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}
Ma'anshan, China{p_end}
{pstd}
E-mail: {browse "agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}
Chen Liwen{p_end}
{pstd}
School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}
Ma'anshan, China{p_end}
{pstd}
E-mail: {browse "2184844526@qq.com":2184844526@qq.com}{p_end}

{pstd}
Hu Fangfang{p_end}
{pstd}
School of Finance and Economics, Wanjiang University of Technology (WJUT){p_end}
{pstd}
Ma'anshan, China{p_end}
{pstd}
E-mail: {browse "huff470@163.com":huff470@163.com}{p_end}

{pstd}
Jin Xuening{p_end}
{pstd}
School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}
Ma'anshan, China{p_end}
{pstd}
E-mail: {browse "1418924481@qq.com":1418924481@qq.com}{p_end}

{title:Also see}

{pstd}
{help import excel} for reading Excel files into Stata{p_end}
{pstd}
{help sample} for Stata's built-in sampling command{p_end}
