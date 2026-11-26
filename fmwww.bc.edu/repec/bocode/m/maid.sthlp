{smcl}
{* *! version 1.0.0 maid, parallel to mchaid for a quantitative response variable (J. N. Luchman and M. Escobar)}{...}
{vieweralsosee "mchaid" "help mchaid"}{...}
{vieweralsosee "chaid" "help chaid"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "[R] svy" "help svy"}{...}
{vieweralsosee "[R] permute" "help permute"}{...}
{vieweralsosee "[R] xtile" "help xtile"}{...}
{viewerjumpto "Syntax" "maid##syntax"}{...}
{viewerjumpto "Description" "maid##description"}{...}
{viewerjumpto "Options" "maid##options"}{...}
{viewerjumpto "Remarks" "maid##remarks"}{...}
{viewerjumpto "Examples" "maid##examples"}{...}
{viewerjumpto "Stored results" "maid##results"}{...}
{viewerjumpto "References" "maid##references"}{...}
{p2colset 1 14 16 2}{...}
{p2col:{bf:maid} {hline 2}}Automatic interaction detection with F tests (MAID): CHAID tree for a quantitative response variable{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:maid} {depvar} {ifin} {weight} [{cmd:,} {it:options}]

{p 8 15 2}
{cmd:maid} [{cmd:,} {it:graph_options} {opt bra:nches} {opt def:initions}]

{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opth uno:rdered(varlist)}}splitting variables treated as unordered{p_end}
{synopt:{opth ord:ered(varlist)}}splitting variables treated as ordered{p_end}
{synopt:{opt xt:ile(varlist, xtile_opt)}}create ordered splitting variables from quantiles{p_end}
{synopt:{opt force:vars(varlist)}}splitting variables that choose the first levels of the tree{p_end}
{synopt:{opt mis:sing}}treat missing values as one more category{p_end}
{synopt:{opt anova}}test ordered splitting variables with the analysis of variance{p_end}

{syntab:Stopping rules}
{synopt:{opt minn:ode(#)}}minimum number of observations in a final node; default is {cmd:minnode(100)}{p_end}
{synopt:{opt mins:plit(#)}}minimum number of observations to split a node; default is {cmd:minsplit(200)}{p_end}
{synopt:{opt maxb:ranch(#)}}maximum number of splits from the root to a final node; default is {cmd:maxbranch(3)}{p_end}

{syntab:Merging and splitting}
{synopt:{opt merga:lpha(#)}}probability for merging categories; default is {cmd:mergalpha(.95)}{p_end}
{synopt:{opt respa:lpha(#)}}probability for splitting a merged group again; default is not to do it{p_end}
{synopt:{opt splta:lpha(#)}}adjusted p-value for splitting a node; default is {cmd:spltalpha(.05)}{p_end}
{synopt:{opt noadj}}do not adjust the p-values of the splits (Bonferroni){p_end}
{synopt:{opt ex:haust}}exhaustive CHAID{p_end}

{syntab:Method of the tests}
{synopt:{opt svy}}use the survey design set with {helpb svyset}{p_end}
{synopt:{opt p:ermute}}obtain the p-values by permutation{p_end}

{syntab:Saved variables and results}
{synopt:{opt pred:icted}}create the variable {cmd:MAID_predict} with the mean of each node{p_end}
{synopt:{opt imp:ortance}}save the permutation importance of the splitting variables{p_end}
{synopt:{opt nore:number}}number the nodes in the order of creation{p_end}

{syntab:Output}
{synopt:{opt nodisp:lay}}do not show the output nor the graph{p_end}
{synopt:{opt bra:nches}}show the table of the branches of the tree{p_end}
{synopt:{opt def:initions}}show the list of the nodes with their definitions{p_end}
{synopt:{opt step:s}}show the merging and splitting tests of every node{p_end}
{synopt:{opt noi:sily}}show the Stata output of the algorithm{p_end}

{syntab:Graph}
{synopt:{opt nogr:aph}}do not draw the graph of the tree{p_end}
{synopt:{opt tree:style(style)}}{it:style} is {cmd:classic} (default) or {cmd:boxes}{p_end}
{synopt:{opt nodep:lot(plot)}}with {cmd:boxes}: {it:plot} is {cmd:bar}, {cmd:box} (default), {cmd:both} or {cmd:dots}{p_end}
{synopt:{opt maxd:ots(#)}}with {cmd:nodeplot(dots)}: most points drawn in a node; default is {cmd:200}{p_end}
{synopt:{opt cent:er(stat)}}with {cmd:boxes}: {it:stat} is {cmd:mean} (default) or {cmd:median}{p_end}
{synopt:{opt whisk:er(type)}}with {cmd:nodeplot(box)}, {cmd:both} or {cmd:dots}: {it:type} is {cmd:p5} (default), {cmd:minmax} or {cmd:tukey}{p_end}
{synopt:{opt nosh:ade}}with {cmd:boxes}: one single intensity of colour{p_end}
{synopt:{opt dig:its(#)}}decimals of the means, medians and standard deviations; default is {cmd:digits(1)}{p_end}
{synopt:{opt nodeh:ead(head)}}with {cmd:boxes}: {it:head} is {cmd:category} (default) or {cmd:number}{p_end}
{synopt:{opt rootl:abel(label)}}heading of the root node{p_end}
{synopt:{opt col:ors(colours)}}colours of the nodes above and below the overall mean{p_end}
{synopt:{opt nopv:al}}do not write the p-values of the splits{p_end}
{synopt:{opt pcut(#)}}write {cmd:p<}{it:#} for the p-values below {it:#}{p_end}
{synopt:{opt quar:tiles(auto|all)}}median and quartile lines over the bars (classic style){p_end}
{synopt:{opt lang:uage(code)}}language of the texts of the graph{p_end}
{synopt:{opt graphopts(string)}}{help twoway_options:twoway options} for the graph{p_end}

{syntab:Interactive tree}
{synopt:{opt dir:ectory(folder)}}write the interactive tree, an HTML page, in {it:folder}{p_end}
{synopt:{opt coll:apse(#)}}depth below which the branches start collapsed{p_end}
{synopt:{opt noop:en}}do not open the page in the browser{p_end}
{synoptline}
{p 4 6 2}{opt fweight}s are allowed; see {help weight}.{p_end}
{p 4 6 2}The splitting variables must be integers not smaller than 0 with at most 20 different values.  At least one of {opt unordered()}, {opt ordered()} and {opt xtile()} is needed.{p_end}
{p 4 6 2}{cmd:maid} needs the Mata library {cmd:moremata} ({stata ssc install moremata}).{p_end}
{p 4 6 2}After the estimation, {cmd:maid} without a variable list shows the output again; the graph options of the estimation are used again, and those typed now replace them ({opt branches} and {opt definitions} can be added), for example {cmd:maid, language(es)}; {opt directory()}, {opt collapse()} and {opt noopen} are not reused: the interactive tree is written again only when they are typed.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:maid} is the version of {helpb mchaid} for a {it:quantitative} response variable: it grows a CHAID decision tree whose nodes differ as much as possible in the mean of the
response variable, with F tests instead of chi-square tests, and shows the tree in a table and in a graph.  See {help maid##remarks:Remarks}.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}{opt unordered(varlist)} splitting variables treated as unordered (any categories can be merged).  {opt ordered(varlist)} splitting variables treated as ordered
(only adjacent categories can be merged).  At least one of them or {opt xtile()} is required.  The splitting variables must have non-negative integer values and no more than 20
different values.{p_end}

{phang}{opt xtile(varlist, xtile_opt)} creates, for each variable of {it:varlist}, an ordered variable with its quantiles ({helpb xtile}; for example {cmd:xtile(income, nq(5))})
and uses it as an ordered splitting variable.{p_end}

{phang}{opt forcevars(varlist)} chooses the splitting variables of the first levels of the tree instead of leaving it to the algorithm: the first variable splits the sample, the second one splits every node of the next level, and so on (any number of variables); below them the tree grows as usual.  The variables must be among those of {opt unordered()}, {opt ordered()} and {opt xtile()} (a variable of {opt xtile()} is given by its name or as {cmd:xt}{it:name}), written in full.  In every node the categories of the forced variable are merged as in the algorithm, and the node is split even if the adjusted p-value is not below {opt spltalpha()}; when it is not, merging goes on until two groups remain, so that the split is binary.  {opt minnode()} is respected: if the sample cannot be split by the first variable the command stops with an error, and in a deeper node where the forced split is not possible (the variable has fewer than two categories there, or a node would be smaller than {opt minnode()}) the node grows freely and a note says in how many nodes it happened.  {opt maxbranch()} cannot be smaller than the number of forced variables.  The graph marks the forced variables; see {help maid##forced:Forced splits}.{p_end}

{phang}{opt missing} treats the missing values of the splitting variables as one more category that cannot be merged with the others (the cases with a missing response variable are
always excluded).{p_end}

{phang}{opt anova} tests the {it:ordered} splitting variables with the F test of the analysis of variance (the merged groups as a factor, with groups - 1 degrees of freedom) instead of
the linear term of their codes.  The order of the categories is then used only to decide which categories can be merged, not their spacing; this is the test of the classic CHAID for a
quantitative response variable.  It does not change the tests of the unordered variables.{p_end}

{dlgtab:Stopping rules}

{phang}{opt minnode(#)} the minimum number of observations in a final node.  The default is 100.{p_end}

{phang}{opt minsplit(#)} the minimum number of observations that a node must have to be split.  It cannot be smaller than {opt minnode()}.  The default is 200.{p_end}

{phang}{opt maxbranch(#)} the maximum number of splits from the root node to a final node (the depth of the tree).  The default is 3, so that the tree does not grow indefinitely with many
cases (a tree with many nodes takes long and cannot be drawn: Stata stops with {cmd:too many options}); {cmd:maxbranch(-1)} removes the limit.{p_end}

{dlgtab:Merging and splitting}

{phang}{opt mergalpha(#)} the threshold for merging categories.  The default is .95: two categories are merged when the p-value of their difference is above 1 - .95 = .05.{p_end}

{phang}{opt respalpha(#)} the threshold for splitting again a group of merged categories.  By default it is not done.{p_end}

{phang}{opt spltalpha(#)} the threshold for splitting a node: a node is split when the adjusted p-value of the best variable is below it.  The default is .05.{p_end}

{phang}{opt noadj} omits the Bonferroni adjustment of the p-values of the splits.{p_end}

{phang}{opt exhaust} uses the exhaustive CHAID algorithm, which merges the categories until only two remain and always splits into two branches.{p_end}

{dlgtab:Method of the tests}

{phang}{opt svy} uses the survey design set with {helpb svyset} ({cmd:svy: regress} and its F tests).  {opt permute} obtains the p-values by permutation of the response variable
({helpb permute}; 100 permutations by test, so the p-values are multiples of 0.01).  They cannot be combined with each other nor with {cmd:fweight}s.{p_end}

{dlgtab:Saved variables and results}

{phang}{opt predicted} creates the variable {cmd:MAID_predict} with the mean of the response variable in the node of each case.{p_end}

{phang}{opt importance} saves in {cmd:e(importance)} the permutation importance of the splitting variables, based on the R-squared of the tree. When typed in {cmd:maid} again after an estimation without it, the estimation is run again with the same command line to obtain it (the permutations are random, so the values can change slightly).{p_end}

{phang}{opt norenumber} keeps the numbers of the nodes in the order in which they were created, instead of the order of the tree.{p_end}

{dlgtab:Output}

{phang}{opt nodisplay} does not show the output nor the graph (the page of {opt directory()} is still written).{p_end}

{phang}{opt branches} and {opt definitions} add to the output the table of the branches of the tree and the definitions of the nodes.  They are not shown by default.  They can be
typed in the estimation or when typing {cmd:maid} again after it ({cmd:maid, definitions}).{p_end}

{phang}{opt steps} writes the merging and splitting tests of each node: the candidate pairs and their p-values, the Bonferroni multiplier, the adjusted p-value of each variable
and the decision.  {opt noisily} shows the Stata output of the algorithm.{p_end}

{dlgtab:Graph}

{phang}{opt nograph} does not draw the graph.{p_end}

{phang}A tree with very many nodes cannot be drawn (a Stata graph accepts a limited number of options): {cmd:maid} then says so and shows the rest of the output.  Use {opt nograph}, a
lower {opt maxbranch()} or higher {opt minnode()} and {opt minsplit()}, or {cmd:treestyle(boxes)}.{p_end}

{phang}{opt treestyle(classic|boxes)} chooses the style of the graph of the tree. {cmd:classic} (default) is the one described in {help maid##display:The graph}. With {cmd:boxes} every node of the
tree, the root and the intermediate nodes included, is a box with its name, its size (n and % of the cases), its mean (or median, see {opt center()}) with, in
parentheses, the difference with the overall one, the standard deviation, and a plot of the distribution of the response variable (see {opt nodeplot()}). Under a node
that is split go the splitting variable (its variable label, if it has one) and the test of the split ({cmd:F = 12.3; p < 0.001}: the F statistic, kept in
{cmd:e(splitF)}, and the Bonferroni-adjusted p-value, as in {cmd:e(splitp)}), and, with {cmd:nodehead(number)}, on each branch, in a box, the categories of the splitting variable (by default they are the heading of the boxes, see {opt nodehead()}). The title is only
written if you give one with {cmd:title()}; {opt nopval} leaves out the p-values (F stays), {opt pcut()} works as in the classic style and {opt quartiles()} is ignored.
The graph is not limited by the number of nodes (the classic one gives up when the tree is too big for the options of a Stata graph). Note that the nodes are numbered as
in SPSS: all the nodes of the tree, the root being node 0, level by level and from left to right, so the numbers of the final nodes are not those of the tables, of
{cmd:e(sizes)} or of {cmd:r(nodes)}, which number only the final nodes. It can be typed in the estimation or when typing {cmd:maid} again after it
({cmd:maid, treestyle(boxes)}).{p_end}

{phang}{opt nodeplot(bar|box|both|dots)}, with {cmd:treestyle(boxes)}, chooses the plot that each box shows. {cmd:bar}: the deviation of the mean (or median) of the node from
the overall one, as a bar to the right (above, blue) or to the left (below, orange) of a line that sticks out of the bar (dark grey for the overall mean, green for the overall median), on the scale of
the largest deviation of the tree, with the standard deviation of the node under it. {cmd:box} (default): a box plot, from the first to the third quartile with the median
in it, and whiskers, on a scale common to all the nodes, so that they can be compared; a thin green line that sticks out of the boxes, at the same place of all of them,
marks the overall median, and under the tree a scale gives the minimum, the reference and the maximum of the scale. {cmd:both}: the box plot and, under it, a bar from the
overall mean (or median, see {opt center()}) to the mean (or median) of the node on the same scale, with the line of the overall mean in the colour of the bar. {cmd:dots}: the box plot and, under it, the observations of the node as points (grey, with some transparency from Stata 15), on the same scale; the scale holds all of them, also the
outliers and the extremes that the whiskers leave out, and their vertical position is fixed, so the graph is always the same.  With frequency weights an observation counts as many
times as its weight, except those outside the whiskers, which are drawn once.  See {opt maxdots()}.  The colour
says whether the node is above (blue) or below (orange) the reference, the stronger the more overall standard deviations it is away from it (one or more, the strongest;
see {opt noshade}).{p_end}

{phang}{opt maxdots(#)}, with {cmd:nodeplot(dots)}, is the most points drawn in a node (a whole number from 20 to 5000; default 200).  All the observations outside the whiskers
are always drawn; of those between them only as many as leave the node at {it:#} (never fewer than a tenth of it) are drawn, a systematic sample of the sorted values that keeps the
shape of the distribution (always the same).  The legend says it when a node has been sampled.{p_end}

{phang}{opt center(mean|median)}, with {cmd:treestyle(boxes)}, is the statistic of each node that is compared with the overall one: it is written in the box, decides the
colour and is the reference of the bars. In the box plots the green line is always the overall median. The default is {cmd:mean}: each box writes its mean with, in
parentheses, the difference with the overall mean, and the standard deviation of the node; with {cmd:center(median)} it writes the median and its difference with the
overall median (the standard deviation stays).{p_end}

{phang}{opt whisker(p5|minmax|tukey)}, with {cmd:nodeplot(box)}, {cmd:nodeplot(both)} or {cmd:nodeplot(dots)}, sets the whiskers of the box plots: {cmd:p5} (default) the 5th and 95th
percentiles, {cmd:minmax} the minimum and the maximum, {cmd:tukey} the most extreme values within 1.5 times the interquartile range of the quartiles (the outliers are not
drawn). The percentiles are those of {cmd:summarize, detail}, also with frequency weights.{p_end}

{phang}{opt noshade}, with {cmd:treestyle(boxes)}, paints the blue and the orange of the boxes with one single intensity instead of making them stronger the farther the
node is from the reference.{p_end}

{phang}{opt digits(#)} (0 to 6, default 1) sets the decimals with which the graph writes the mean, the median and the standard deviation of the nodes, their differences with the overall one and the numbers of the legend and of the scale, in both styles of the graph. The percentages, the tests and the p-values are not affected. Before it was four significant digits, which gave a different number of decimals in each node. It can be typed in the estimation or when typing {cmd:maid} again after it.{p_end}

{phang}{opt nodehead(category|number)}, with {cmd:treestyle(boxes)}, chooses the heading of each box. {cmd:category} (default) writes in it the category (or the interval) of the splitting variable that forms the node, the one that {cmd:number} writes on the branch (for example {cmd:Right} or {cmd:<=95}); the branches then have no label, the line goes straight to the box, and the number of the node goes in a small square on its top left corner (dark, with the number in white, when the node is a final one). A heading that does not fit is written with a smaller letter, in two lines or cut with {cmd:...}; so is the {cmd:Pred.:} of the final nodes when it would touch the next one. {cmd:number} is the heading {cmd:Node N} with the categories in a box on each branch (the heading of a final node is dark, with the text in white).  The legend has an item for the final nodes. {opt rootlabel()} sets the heading of the root node, which has no category, with {cmd:nodehead(category)}: {cmd:total} (default; {cmd:Total} in the language of the graph), {cmd:depvar} (the label of the response variable) or any text, for example {cmd:rootlabel("All the sample")}. They can be typed in the estimation or when typing {cmd:maid} again after it.{p_end}

{phang}{opt colors(colours)} sets the two colours of the graph: that of the nodes whose mean (or median) is above the overall one and that of the nodes below it (blue and orange by default; the intensity of each one still grows with the distance). They are given by name, {cmd:colors(above=forest_green below=cranberry)}, in any order, or as two colours without names, first the one above and then the one below, {cmd:colors("0 114 178" #D55E00)}. A colour is the name of a Stata colour, red, green and blue between 0 and 255 in quotes (an opacity such as {cmd:%50} is ignored) or a hexadecimal code; one with spaces goes in double quotes. It can be typed in the estimation or when typing {cmd:maid} again after it.{p_end}

{phang}{opt nopval} does not write the p-values of the splits on the graph; {opt pcut(#)} writes {cmd:p<}{it:#} for those below {it:#}.{p_end}

{phang}{opt quartiles(auto|all)} draws on the bar of each final node the median (solid green line) and the first and third quartiles (dotted green lines) of the response variable in the
node, at their value on the same scale as the deviation of the mean.  With {cmd:quartiles(auto)} (the same as {cmd:quartiles} or {cmd:quartiles()}), in the nodes where a quartile is so
close to the median that it cannot be told apart, only the median is drawn.  With {cmd:quartiles(all)} the three lines are always drawn, and the quartiles are thinner.  It can be typed
in the estimation or when typing {cmd:maid} again after it ({cmd:maid, quartiles}).  Without it none of these lines is drawn.{p_end}

{phang}{opt language(code)} writes the texts of the graph in another language: {cmd:en} English (default), {cmd:es} Spanish, {cmd:fr} French, {cmd:de} German, {cmd:it} Italian,
{cmd:pt} (or {cmd:po}) Portuguese, {cmd:ca} Catalan, {cmd:gl} Galician, {cmd:nl} Dutch and {cmd:eu} Basque.  Stata 14 or later is needed for the accents; otherwise the graph is in English.{p_end}

{phang}{opt graphopts(string)} {help twoway_options:twoway options} for the graph, for example {cmd:graphopts(name(g1, replace) scheme(s1mono))}.{p_end}

{pstd}{opt nodeplot()}, {opt center()}, {opt whisker()}, {opt nodehead()}, {opt noshade} and {opt maxdots()} belong to the style of boxes: with the classic graph a note says that they are ignored (the interactive tree of {opt directory()} does use them).  {opt rootlabel()} also works with the classic graph, where it is the heading of the root box.{p_end}

{dlgtab:Interactive tree}

{phang}{opt directory(folder)} writes the tree as an interactive HTML page in {it:folder}, which is created if it does not exist (an existing folder must be empty or hold a page written before by {cmd:maid}, which is replaced).  The page is {cmd:index.html}; its link is shown in the Results window and it is opened in the browser.  It follows the options of the style of boxes ({opt nodeplot()}, {opt center()}, {opt digits()}, {opt whisker()}, {opt noshade}, {opt nodehead()}, {opt rootlabel()}, {opt colors()}, {opt language()}, {opt nopval}, {opt pcut()} and {cmd:title()} inside {opt graphopts()}), whatever {opt treestyle()} is, except that the page is drawn with the layout of the classic graph (small boxes with the category of the branch, the splitting variable and its test over the branch, and the bars only under the final nodes) when {cmd:treestyle(classic)} is typed together with {opt directory()}; then {opt nodeplot()}, {opt whisker()}, {opt noshade}, {opt nodehead()}, {opt center()} are ignored and {opt quartiles()} draws the median and the quartiles on the bars.  {opt nograph} only stops the Stata graph.  It can also be typed when {cmd:maid} is typed again after the estimation, and it is written even with {opt nodisplay}.  See {help maid##html:The interactive tree}.{p_end}

{phang}{opt collapse(#)} starts the page with the branches below depth {it:#} collapsed: {cmd:collapse(1)} shows only the first split (the root and its nodes).  By default the whole tree is shown.{p_end}

{phang}{opt noopen} writes the page without opening it in the browser.{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
Remarks are presented under the following headings:{p_end}

{phang2}{help maid##algorithm:How maid works}{p_end}
{phang2}{help maid##output:The output}{p_end}
{phang2}{help maid##display:The graph}{p_end}
{phang2}{help maid##html:The interactive tree}{p_end}
{phang2}{help maid##forced:Forced splits}{p_end}
{phang2}{help maid##numbering:Numbering of the nodes}{p_end}


{marker algorithm}{...}
{bf:How maid works}

{pstd}
{cmd:maid} builds the tree by the same CHAID procedure as {helpb mchaid} (merging of the categories of each splitting variable, choice of the best split with a Bonferroni-adjusted
p-value, recursive partitioning), but every test is an {it:F test} obtained with {helpb regress} instead of the likelihood-ratio tests of {helpb mlogit} or {helpb ologit}.  The result
is a set of nodes (clusters) that differ as much as possible in the mean of the response variable.  {cmd:maid} and {cmd:mchaid} can be installed side by side.

{pstd}
For each splitting variable {cmd:maid} first merges its categories: it computes, for every pair of categories that can be merged (any pair for an unordered variable, only adjacent
categories for an ordered one), the F test of the difference between their means of the response variable, merges the pair with the highest p-value if it is above
{cmd:1 - mergalpha()} and repeats until no pair can be merged.  Then it tests the association between the response variable and the merged categories and keeps the variable with
the lowest p-value after the Bonferroni adjustment (the number of ways in which the original categories could have been merged).  If that adjusted p-value is below {opt spltalpha()}
and every new node has at least {opt minnode()} observations, the node is split, and the process continues in each new node with at least {opt minsplit()} observations.

{pstd}
The test of an {it:unordered} splitting variable is the F test of the differences between the means of its categories (the analysis of variance of {cmd:regress} on the indicators
of its categories).  The test of an {it:ordered} splitting variable is, as in {cmd:mchaid}, the F test of the linear term of the codes of its categories (the groups coded 1, 2, 3...
enter as one variable, which assumes equally spaced categories and has 1 degree of freedom), unless option {opt anova} is used: then it is tested with the analysis of variance, like
an unordered one.  {cmd:maid} needs the Mata library {cmd:moremata} ({stata ssc install moremata}).


{marker output}{...}
{bf:The output}

{pstd}
By default {cmd:maid} shows the graph of the tree, the table of the response variable by node, the risk estimate and the F test.  The table (see {helpb table}, Stata 17 or later,
or {helpb tabstat}) has a row for each node with its definition, its number of observations, the mean, the standard deviation, the minimum, the median and the maximum of the
response variable.  Below the table:

{p 8 8 2}{cmd:Risk estimate = }{it:x}{cmd: (root node: }{it:y}{cmd:)}: the variance of the response variable around the mean of its node (that is, the mean squared error of the
prediction that gives every case the mean of its node); in parentheses, the same for the root node, that is, around the overall mean (without the tree).  The graph shows the same.{p_end}

{p 8 8 2}{cmd:F(}{it:df1}{cmd:, }{it:df2}{cmd:) = }{it:x}: the F test of the differences between the means of the nodes, with its p-value, the R-squared (proportion of the variance
of the response variable between the nodes) and eta.  Because the nodes were chosen to be as different as possible, these tests are descriptive and should not be used for inference.{p_end}

{pstd}
The options {opt branches} and {opt definitions} add to the output the matrix with the branches of the tree and the list of the nodes with their definitions and sizes.


{marker display}{...}
{marker graph}{...}
{bf:The graph}

{pstd}
The classic graph is drawn as a decision tree: every node is a small box whose heading is the category, or group of categories, of the splitting variable that leads to it (the root says
{cmd:Total}, or what {opt rootlabel()} says) with the number of observations of the node under it; the splitting variable of a node, the F statistic ({cmd:F=12.3}, also stored in
{cmd:e(splitF)}) and the Bonferroni-adjusted p-value of each split are written over the branches that leave it, on a white block under its box; the boxes do not carry the number of the
node (the clusters are numbered as in {cmd:e(sizes)} and in the output, from left to right).  The heading of a box is written with a smaller type, in two lines or cut with {cmd:...} when
the list of categories is too long for the box.  Each final node appears at the bottom with a bar: the deviation of the mean of the node from the overall mean (dashed line), in blue when it is above and in orange when it is
below.  The bars share one scale: the largest deviation takes half of the height.  Under each bar the mean and the standard deviation of the node are written.  With option
{opt quartiles} the median (solid green line) and the first and third quartiles (dotted green lines) of each node are drawn over its bar, at their value on the same scale as the
bar; the scale then includes them.  The last line shows the risk estimate and eta squared (equal to the R-squared).  Options {opt nopval}, {opt pcut(#)}, {opt language(code)} and the
options of {help twoway} ({cmd:graphopts()}, or directly when typing {cmd:maid} again) work as in {help mchaid##display:mchaid}.

{pstd}
With {cmd:treestyle(boxes)} every node of the tree is a box (see the options {opt treestyle()}, {opt nodeplot()}, {opt center()}, {opt nodehead()} and {opt colors()}).


{marker html}{...}
{bf:The interactive tree}

{pstd}
With {opt directory()} the tree is also written as a page that runs in any browser, with no Internet connection: {cmd:index.html} and the folders {cmd:styles} and {cmd:scripts}.  It is the page that function {cmd:tree_html()} of the R package {cmd:mchaid} writes, and it shows what the graph in the style of boxes shows: a box for every node with its mean (or median), its standard deviation and the plot of its distribution (the deviation from the overall mean, a box plot, both or the box plot with the observations as points, as {opt nodeplot()} says), and the splitting variables with their tests.  Put the mouse over a node to see its definition, its size, its mean, standard deviation and quartiles; click the sign next to a splitting variable to collapse or expand its branches; drag the tree to move it and use the wheel of the mouse to zoom; the buttons expand or collapse the whole tree, fit it to the window and save it as an SVG or PNG image.

{pstd}
The folder can be copied or sent as it is.  The data of the tree are written inside the page, so whoever opens it sees the tree (not the data of your file), except with {cmd:nodeplot(dots)}: then the values of the response variable of the points drawn (at most {opt maxdots()} per node) go inside the page, which is a consideration if it is going to be shared.  To write the page again with other options, type {cmd:maid, directory(}{it:folder}{cmd:)} and the options after the estimation.


{marker forced}{...}
{bf:Forced splits}

{pstd}
With {opt forcevars()} the first levels of the tree are chosen by the user: {cmd:forcevars(}{it:v1 v2}{cmd:)} splits the sample by {it:v1} and every node of the next level by {it:v2}.  Each node merges the categories of the forced variable on its own, so the groups may differ from one branch to another.  The variables are forced whether or not they are significant: the adjusted p-value of the split is still computed and written in the graph, and it may be above {opt spltalpha()}; in that case the split is binary.  If in a node of a deeper level the forced split is not possible, the node grows freely, with all the variables, and the command notes it; {opt steps} shows these decisions.  The tests of the nodes are descriptive, as always, and more so with variables chosen in advance.

{pstd}
In the graph the variable of every split chosen with {opt forcevars()} is followed by an asterisk and a note, in the language of {opt language()}, explains the mark.  The splits below the forced levels, and those of the nodes where the forced split was not possible, carry no mark.  {cmd:e(forcevars)} keeps the variables and {cmd:e(splitforced)} marks the splits (1) in the layout of {cmd:e(splitp)}.


{marker numbering}{...}
{bf:Numbering of the nodes}

{pstd}
The nodes are numbered, and the variable {cmd:_MAID} with the node of each case (labelled with the definitions of the nodes) is added to the data, as in {cmd:mchaid}
({help mchaid##numbering:numbering of the clusters}).


{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse nlsw88, clear}{p_end}
{phang}{cmd:. maid wage, unordered(occupation) ordered(grade) minnode(30) minsplit(60)}{p_end}
{phang}{cmd:. maid, definitions branches}{p_end}

{pstd}The same tree in the style of boxes, with box plots, your own colours and in Spanish{p_end}
{phang}{cmd:. maid, treestyle(boxes) nodeplot(both) colors(above=forest_green below=cranberry) language(es)}{p_end}

{pstd}The graph can be saved as an editable vector graphic (SVG; checked in Stata 17 to 19){p_end}
{phang}{cmd:. graph export tree.svg, replace}{p_end}

{pstd}The box plot with the observations as points under it (at most 100 per node){p_end}
{phang}{cmd:. maid, treestyle(boxes) nodeplot(dots) maxdots(100)}{p_end}

{pstd}The first two levels chosen by the user: the race, then the grade{p_end}
{phang}{cmd:. maid wage, unordered(occupation race) ordered(grade) forcevars(race grade) minnode(30) minsplit(60)}{p_end}

{pstd}The tree as an interactive page, written in the folder {cmd:wages_tree}{p_end}
{phang}{cmd:. maid, directory(wages_tree)}{p_end}

{pstd}Other analyses{p_end}
{phang}{cmd:. maid wage, unordered(occupation) ordered(grade) minnode(30) minsplit(60) steps nograph}{p_end}
{phang}{cmd:. maid wage [fweight = hours], unordered(occupation) ordered(grade) minnode(500) minsplit(1000) language(es)}{p_end}
{phang}{cmd:. maid wage, unordered(race occupation) xtile(age, nq(4)) minnode(30) minsplit(60) predicted}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:maid} saves in {cmd:e()}, with {cmd:e(cmd)} equal to {cmd:maid}, the same results as {helpb mchaid} that do not depend on the type of the response variable: {cmd:e(N)},
{cmd:e(N_clusters)}, {cmd:e(depvar)}, {cmd:e(path#)}, {cmd:e(split#)}, {cmd:e(ordered)}, {cmd:e(ordlev#)}, {cmd:e(sizes)}, {cmd:e(branches)}, {cmd:e(splitp)},
{cmd:e(splitF)} (the F statistic of each split, in the layout of {cmd:e(splitp)}), {cmd:e(splitstat)} ({cmd:F}), {cmd:e(forcevars)} and {cmd:e(splitforced)} (see {opt forcevars()}), {cmd:e(importance)}, {cmd:e(sample)}, and
{cmd:e(fit)}, which is here the R-squared of the tree (the proportion of the variance of the response variable explained by the nodes).{p_end}

{pstd}
{cmd:maid} is {cmd:rclass}; typing {cmd:maid} without arguments after the estimation shows the output again and saves {cmd:r()} again:

{synoptset 16 tabbed}{...}
{p2col 5 15 19 2: scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations (sum of the weights){p_end}
{synopt:{cmd:r(N_clusters)}}number of nodes{p_end}
{synopt:{cmd:r(mean)}, {cmd:r(sd)}}overall mean and standard deviation of the response variable{p_end}
{synopt:{cmd:r(sst)}, {cmd:r(sse)}, {cmd:r(ssb)}}total, within-nodes and between-nodes sums of squares{p_end}
{synopt:{cmd:r(r2)}, {cmd:r(eta)}}R-squared and eta{p_end}
{synopt:{cmd:r(F)}, {cmd:r(df1)}, {cmd:r(df2)}, {cmd:r(p)}}F test of the differences between the means of the nodes{p_end}
{synopt:{cmd:r(risk)}, {cmd:r(risk0)}}risk estimate: variance around the mean of the node, and around the overall mean (root node){p_end}
{p2col 5 15 19 2: macros}{p_end}
{synopt:{cmd:r(depvar)}}name of the response variable{p_end}
{synopt:{cmd:r(label#)}}label of node #, with its definition{p_end}
{synopt:{cmd:r(labels)}}all the node labels, each in double quotes{p_end}
{p2col 5 15 19 2: matrices}{p_end}
{synopt:{cmd:r(nodes)}}one row per node: n, mean, sd, min, p25, p50, p75 and max of the response variable (weighted when {opt fweight}s are used){p_end}


{marker references}{...}
{title:References}

{p 4 8 2}Kass, G. V. (1980). An exploratory technique for investigating large quantities of categorical data. {it:Applied Statistics, 29, 2}, 119-127.{p_end}

{p 4 8 2}Morgan, J. N. and Sonquist, J. A. (1963). Problems in the analysis of survey data, and a proposal. {it:Journal of the American Statistical Association, 58},
415-434.{p_end}


{title:Author}

{p 4}Modesto Escobar{p_end}
{p 4}Universidad de Salamanca{p_end}
{p 4}modesto@usal.es{p_end}

{p 4}Based on {cmd:chaid} by Joseph N. Luchman (Fors Marsh Group LLC).{p_end}


{title:Acknowledgements}

{phang}Grants CSO2013-49278-EXP, PGC2018-093755-B-I00, PDC2022-133355-I00, PID2023-147358NB-I00 funded by MICIU/AEI/10.13039/501100011033 and by "European Union NextGenerationEU/PRTR".{p_end}


{title:Also see}

{psee}
{helpb mchaid}, {manhelp regress R}, {manhelp svy R}, {manhelp permute R}, {manhelp xtile R}, {manhelp table R}, {manhelp tabstat R}.
{p_end}
