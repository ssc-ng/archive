{smcl}
{* *! version 1.0.0 mchaid, modified from chaid 2.1 (Dec 16th, 2014) by J. N. Luchman and M. Escobar}{...}
{vieweralsosee "chaid" "help chaid"}{...}
{vieweralsosee "maid" "help maid"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] mlogit" "help mlogit"}{...}
{vieweralsosee "[R] ologit" "help ologit"}{...}
{vieweralsosee "[R] svy" "help svy"}{...}
{vieweralsosee "[R] permute" "help permute"}{...}
{vieweralsosee "[R] xtile" "help xtile"}{...}
{viewerjumpto "Syntax" "mchaid##syntax"}{...}
{viewerjumpto "Description" "mchaid##description"}{...}
{viewerjumpto "Options" "mchaid##options"}{...}
{viewerjumpto "Remarks" "mchaid##remarks"}{...}
{viewerjumpto "Examples" "mchaid##examples"}{...}
{viewerjumpto "Postestimation" "mchaid##postestimation"}{...}
{viewerjumpto "Stored results" "mchaid##results"}{...}
{viewerjumpto "References" "mchaid##references"}{...}
{p2colset 1 14 16 2}{...}
{p2col:{bf:mchaid} {hline 2}}Chi-square automated interaction detection (CHAID) for a categorical response variable{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:mchaid} {depvar} {ifin} {weight} [{cmd:,} {it:options}]

{p 8 15 2}
{cmd:mchaid} [{cmd:,} {it:graph_options} {opt bra:nches} {opt def:initions}]

{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opth uno:rdered(varlist)}}splitting variables treated as unordered{p_end}
{synopt:{opth ord:ered(varlist)}}splitting variables treated as ordered{p_end}
{synopt:{opt xt:ile(varlist, xtile_opt)}}create ordered splitting variables from quantiles{p_end}
{synopt:{opt force:vars(varlist)}}splitting variables that choose the first levels of the tree{p_end}
{synopt:{opt mis:sing}}treat missing values as one more category{p_end}
{synopt:{opt dvo:rdered}}ordered response variable ({helpb ologit} instead of {helpb mlogit}){p_end}

{syntab:Stopping rules}
{synopt:{opt minn:ode(#)}}minimum number of observations in a final node; default is {cmd:minnode(100)}{p_end}
{synopt:{opt mins:plit(#)}}minimum number of observations to split a node; default is {cmd:minsplit(200)}{p_end}
{synopt:{opt maxb:ranch(#)}}maximum number of splits from the root to a final node; default is no limit{p_end}

{syntab:Merging and splitting}
{synopt:{opt merga:lpha(#)}}probability for merging categories; default is {cmd:mergalpha(.95)}{p_end}
{synopt:{opt respa:lpha(#)}}probability for splitting a merged group again; default is not to do it{p_end}
{synopt:{opt splta:lpha(#)}}adjusted p-value for splitting a node; default is {cmd:spltalpha(.05)}{p_end}
{synopt:{opt noadj}}do not adjust the p-values of the splits (Bonferroni){p_end}
{synopt:{opt ex:haust}}exhaustive CHAID{p_end}
{synopt:{opt ordt:able}}test ordered splitting variables with the full cross-tabulation{p_end}

{syntab:Method of the tests}
{synopt:{opt p:ermute}}obtain the p-values by permutation{p_end}
{synopt:{opt svy}}use the survey design set with {helpb svyset}{p_end}
{synopt:{opt nof:ast}}use {helpb mlogit} for every test instead of the faster computations in Mata{p_end}

{syntab:Saved variables and results}
{synopt:{opt pred:icted}}create the variable {cmd:CHAID_predict} with the modal category of each node{p_end}
{synopt:{opt imp:ortance}}save the permutation importance of the splitting variables{p_end}
{synopt:{opt nore:number}}number the clusters in the order of creation, as {cmd:chaid} does{p_end}

{syntab:Output}
{synopt:{opt nodisp:lay}}do not show the output nor the graph{p_end}
{synopt:{opt bra:nches}}show the table of the branches of the tree{p_end}
{synopt:{opt def:initions}}show the list of the nodes with their definitions{p_end}
{synopt:{opt step:s}}show every step of the algorithm{p_end}
{synopt:{opt noi:sily}}show the estimation output of the algorithm{p_end}

{syntab:Graph}
{synopt:{opt nogr:aph}}do not draw the graph of the tree{p_end}
{synopt:{opt tree:style(style)}}{it:style} is {cmd:classic} (default) or {cmd:boxes}{p_end}
{synopt:{opt nodep:lot(plot)}}with {cmd:boxes}: {it:plot} is {cmd:bar} (default) or {cmd:box}{p_end}
{synopt:{opt whisk:er(type)}}with {cmd:nodeplot(box)}: {it:type} is {cmd:p5} (default), {cmd:minmax} or {cmd:tukey}{p_end}
{synopt:{opt nosh:ade}}with {cmd:nodeplot(box)}: boxes with one single intensity{p_end}
{synopt:{opt nodeh:ead(head)}}with {cmd:boxes}: {it:head} is {cmd:category} (default) or {cmd:number}{p_end}
{synopt:{opt rootl:abel(label)}}heading of the root node{p_end}
{synopt:{opt col:ors(colours)}}colours of the categories of the response variable{p_end}
{synopt:{opt nopv:al}}do not write the p-values of the splits{p_end}
{synopt:{opt pcut(#)}}write {cmd:p<}{it:#} for the p-values below {it:#}{p_end}
{synopt:{opt quar:tiles(auto|all)}}with {cmd:dvordered}: median and quartile lines on the bars{p_end}
{synopt:{opt lang:uage(code)}}language of the texts of the graph{p_end}
{synopt:{opt graphopts(string)}}{help twoway_options:twoway options} for the graph{p_end}

{syntab:Interactive tree}
{synopt:{opt dir:ectory(folder)}}write the interactive tree, an HTML page, in {it:folder}{p_end}
{synopt:{opt coll:apse(#)}}depth below which the branches start collapsed{p_end}
{synopt:{opt noop:en}}do not open the page in the browser{p_end}
{synoptline}
{p 4 6 2}{opt fweight}s are allowed; see {help weight}.{p_end}
{p 4 6 2}The response variable and the splitting variables must be integers not smaller than 0 with fewer than 21 different values.
At least one of {opt unordered()}, {opt ordered()} and {opt xtile()} is needed.{p_end}
{p 4 6 2}After the estimation, {cmd:mchaid} without a variable list shows the output again; the graph options of the estimation are used again, and those typed now replace them ({opt branches} and {opt definitions} can be added), for example {cmd:mchaid, language(es)}; {opt directory()}, {opt collapse()} and {opt noopen} are not reused: the interactive tree is written again only when they are typed.  {cmd:estat classification} is available after {cmd:mchaid}; see {help mchaid##postestimation:Postestimation}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mchaid} grows a CHAID decision tree for a categorical response variable: it merges the categories of the splitting variables and splits the data into nodes
that differ as much as possible in the distribution of the response variable.  It is a faster, corrected version of {help chaid}, and shows the tree in a table and in a graph.
See {help mchaid##remarks:Remarks}.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}{opt unordered()} treats the variable list included as "unordered."  The unordered treatment affects both how 
categories of the splitting variables are combined (i.e., any categories can be combined), and how final significance of 
the optimally merged splitting variable is computed (i.e., unordered Bonferroni adjustment).  Unordered predictors are 
the most time intensive splitting variables for which to discern an optimal merging, as all categories are potentially 
allowed to be merged. 

{phang}{opt ordered()} treats the variable list included as "ordered."  The ordered treatment affects both how 
categories of the splitting variables are combined (i.e., only adjacent categories can be combined), and how final 
significance of the optimally merged splitting variable is computed (i.e., ordered Bonferroni adjustment).  Ordered 
variables with {opt missing} invoked, when missing data are present, treat the missing category as a "floating" option 
and, consequently, adjusts the p-value for splitting based on the floating category as opposed to the usual ordered 
adjustment. 

{phang}{opt xtile()} is a convenience command to take variables that are otherwise continuous, or ordered with many categories (i.e., counts), 
and generate a set of ordered categorical quantiles from those variables.  The variables created by {opt xtile()} are automatically considered 
as {opt ordered()} and are added to the dataset with the name "xt{it:varname}".  Any variables called "xt{it:varname}" already in the dataset will 
be overwritten when using {opt xtile()}.  The {opt xtile()} option allows the user specify the number of quantiles created as an option 
(i.e., {opt nquantiles(#)}) following a comma.  Not specifying the number of quantiles will result in 2 quantiles (i.e., the default 
for {cmd:xtile}).

{phang}{opt forcevars(varlist)} chooses the splitting variables of the first levels of the tree instead of leaving it to the algorithm: the first variable splits the sample, the second one splits every node of the next level, and so on (any number of variables); below them the tree grows as usual.  The variables must be among those of {opt unordered()}, {opt ordered()} and {opt xtile()} (a variable of {opt xtile()} is given by its name or as {cmd:xt}{it:name}), written in full.  In every node the categories of the forced variable are merged as in the algorithm, and the node is split even if the adjusted p-value is not below {opt spltalpha()}; when it is not, merging goes on until two groups remain, so that the split is binary.  {opt minnode()} is respected: if the sample cannot be split by the first variable the command stops with an error, and in a deeper node where the forced split is not possible (the variable has fewer than two categories there, or a node would be smaller than {opt minnode()}) the node grows freely and a note says in how many nodes it happened.  {opt maxbranch()} cannot be smaller than the number of forced variables.  The graph marks the forced variables; see {help mchaid##forced:Forced splits}.{p_end}

{phang}{opt missing} allows missing data in the response and splitting variables to be treated as another category.  The 
missing option does not affect unordered splitting variables, but does result in all ordered independent variables with missing 
data, to have a "floating" missing data category.  Note that with the {opt dvordered} option that missing data on the response 
variable is not treated as another category but, rather, is treated as missing and marked out of the sample.  Missing data with 
ordered response variables must be imputed through some other means to be included in {cmd:mchaid}.  The {cmd:missing} option 
can also result in missing (i.e., ".") as a predicted value when combined with {cmd:predicted}.

{phang}{opt dvordered} changes the estimation procedure underlying {cmd:mchaid} to be {help ologit} instead of the default 
{help mlogit}.  Hence, {opt dvordered} treats the response variable as being ordered.

{dlgtab:Stopping rules}

{phang}{opt minnode()} specifies the minimum number of observations allowed in a terminal cluster or "node."  If an 
optimally merged splitting variable passes to the point of splitting, but one or more of the clusters that would be created 
by the optimally merged splitting variable is below the {opt minnode()} value, the split will not be carried out. Thus, 
{opt minnode()} prevents {cmd:mchaid} from carrying out Step 2. The default value for {opt minnode()} is 100.

{phang}{opt minsplit()} specifies the minimum number of observations across all levels of an optimally merged splitting 
variable to allow any split to occur, irrespective of how many observations would be in each of the final clusters.  Hence, 
previous to clustering, if a the number of observations does not meet the {opt minsplit()} minimum, no clustering will occur.  
{opt minsplit()} prevents {cmd:mchaid} from executing Step 1.  The default value for {opt minsplit()} is 200.

{phang}{opt maxbranch()} sets the maximum number of "branches" on which the {cmd:mchaid} tree is allowed to take.  In other words, 
{opt maxbranch()} sets a maximum in the number of splits on which a particular terminal cluster can be based.  The default 
value is for there to be {it:no} maximum in terms of the number of splits.  Any negative value will turn off 
{opt maxbranch()}.

{dlgtab:Merging and splitting}

{phang}{opt mergalpha()} sets the alpha level at which an allowable pair of categories in an splitting variable can be 
merged in the merging step.  {opt mergalpha()} refers to the probability values the chi-square would take on that would 
{it:allow} a merge.  The default value is .95.  Thus, p-values that are among the middle 95% of the probability 
density for the chi-square distribution are merged.  In other words, predictors that pass the p > .05 threshold are
allowed to be merged.  Note that the p-value is compared with 1 - {opt mergalpha()}, not with {opt mergalpha()} itself:
the pair of categories with the highest p-value is merged if p > 1 - {opt mergalpha()}.  A {it:higher} {opt mergalpha()}
(e.g. .99, threshold p > .01) therefore merges {it:more} categories, and a lower one (e.g. .80, threshold p > .20) merges fewer.
With large samples almost every pair differs significantly, so {opt mergalpha()} has little visible effect unless it is
set very close to 1.

{phang}{opt respalpha()} sets the alpha level at which an already optimally merged set of 3 or more of an independent variable's 
original categories will be allowed to de-couple into a binary split.  How the splitting variables are split depends, of course, 
on the splitting variable's type and whether the {opt missing} option is invoked.  {opt respalpha()} refers to the probability 
values the chi-square would take on that would {it:allow} a split.  The default setting for this option is to a negative value, which 
shuts this option off.  If the user chooses to invoke the {opt respalpha()} option, the value for this option must be smaller than 
the value of 1 - {opt mergalpha()}.

{phang}{opt spltalpha()} sets the adjusted alpha level at which an optimally merged predictor will be split following the 
merging step.  As compared to {opt mergalpha()}, {opt spltalpha()} works in the same way, save that small p-values will 
produce a split - just as small p-values are deemed to be statistically significant. The default value is .05.  Thus, 
predictors that pass the p < .05 threshold are allowed to be split.

{phang}{opt noadj} prevents {cmd:mchaid} from Bonferroni adjusting the {opt spltalpha()} p-values to prevent potential Type I/"false positive" 
inferential error. {opt noadj} is useful in cases where the user desires to be more lenient in terms of uncovering 
relationships in the data. {opt noadj} is turned on by default when using {opt permute} as the Bonferroni adjustment is
intended to approximate exact/permutation p-values (see Kass, 1980).

{phang}{opt exhaust} implements the exhaustive CHAID algorithm described by Biggs, de Ville, and Suen (1991).  The only difference between exhaustive 
and traditional CHAID is that exhaustive CHAID continues the merging step until only a 2 categories/a binary split remains.  Thus, exhaustive 
CHAID ignores {opt mergalpha()} and will continue to merge categories until 2 optimally merged categories of the original set if categories of 
variable {it:i} remain.  Option {opt exhaust} also changes the way the Bonferroni adjustment is computed as the way it merges categories differs 
from the traditional method.

{phang}{opt ordtable} uses the likelihood-ratio chi-square test of the full cross-tabulation (degrees of freedom (m - 1)(J - 1), with m the number of merged 
categories and J the number of levels of the response) for the final splitting test of ordered splitting variables, as for unordered splitting variables 
(see Kass, 1980).  By default {cmd:mchaid} follows {cmd:chaid} and enters the merged categories coded 1, 2, 3,... as a single linear term (degrees of freedom J - 1).  
{opt ordtable} gives smaller p-values for associations that are not linear and can change the trees.  {opt ordtable} cannot be combined with 
{opt dvordered}, {opt svy}, {opt permute} or {opt nofast}.

{dlgtab:Method of the tests}

{phang}{opt permute} changes the way in which p-values are computed for splitting and merging steps from the traditional large-sample approximation 
to a monte-carlo permutation test-based approach (see {help permute} for details).  Permutation tests are more appropriate for smaller sample sizes 
(i.e., conditions under which large sample approximations will not hold) and tend to be more conservative than the large sample approximation and, 
thus, tend to produce fewer splits than the same model not using {opt permute}. {opt permute}, owing to its monte carlo-based approach, greatly 
increases {cmd:mchaid}'s run time.  Permutation tests also do not require Bonferroni adjustment and thus imply {opt noadj}.  {opt permute} does not 
work with {opt svy} or {help weight}s.

{phang}{opt svy} incorporates {help svyset} complex survey design characteristics into the p-value computation.  As with other {help svy} commands, 
the data must be {help svyset} previous to running {cmd:mchaid}.  Option {opt svy} and {help weight}s cannot be used together.  Additionally, 
option {opt svy} and {opt permute} cannot be used together.

{phang}{opt nofast} uses the original estimation-based procedure for the merging and splitting tests instead of the cross-tabulation computations in Mata.  
The results should be the same; {opt nofast} is only useful to check them.  The original procedure is always used when {opt dvordered}, {opt svy} or {opt permute} is specified.

{dlgtab:Saved variables and results}

{phang}{opt predicted} produces a predicted value for the response variable for each cluster.  The predicted value is the mode of the response 
variable for that cluster.  When {opt predicted} is invoked, {cmd:mchaid} produces a variable called {cmd:CHAID_predict} containing the predicted 
value by default.  Any variable named {cmd:CHAID_predict} in the dataset, including those from previous runs of {cmd:mchaid}, will be overwritten.

{phang}{opt importance} produces a permutation importance matrix for rank ordering the splitting variables.  The permutation importance approach 
derives from the idea that if one randomly permutes the values of any one splitting variable there should be a decrease in fit if that splitting 
variable predicts the response variable.  Larger decreases in fit based on permutations of a splitting variable indicate that a splitting 
variable is better at predicting the response variable than smaller decreases in fit.  All fit scores are computed based on Cram{c e'}r's V 
(see {help tabulate_twoway:tabulate twoway}), which obtains perfect fit when all the clusters have a single value (i.e., are pure) or a similar 
metric when combined with {opt svy}.  The decreases in fit owing to permutation are normed out of 1 and displayed in the "raw" row of 
{cmd:e(importance)}.  Because it is possible to obtain negative decrements to fit (that is, increases in fit) due to permuting the values of a 
splitting variable, and due to the random nature of the permutation, the values in the "raw" row are not particularly meaningful and only the the 
second row, "rank", of {cmd:e(importance)} should be interpreted.  Note that {opt importance} creates a Mata matrix called "ifstmnts" that it uses 
to conduct the permutation importance computations that the user can access.

{phang}{opt norenumber} numbers the clusters in the order in which the algorithm created them, as {cmd:chaid} does, instead of in the order of the tree.  
It also orders the columns of the tree in the output alphabetically by their labels, as {cmd:chaid} does.  See {help mchaid##numbering:Numbering of the clusters}.

{dlgtab:Output}

{phang}{opt nodisp} prevents {cmd:mchaid} from displaying the decision tree structure and graph produced by the algorithm (the page of {opt directory()} is still written).  

{phang}{opt branches} shows in the output the table with the branches of the tree (the matrix read from top to bottom, with the splitting variables, their categories and the nodes).  It is
not shown by default.  It can be typed in the estimation or when typing {cmd:mchaid} again after it. When typed in {cmd:mchaid} again after an estimation without it, the estimation is run again with the same command line to obtain it (the permutations are random, so the values can change slightly).{p_end}

{phang}{opt definitions} shows in the output the list of the nodes with their sizes and the categories that define them.  It is not shown by default.  It can be typed in the estimation or
when typing {cmd:mchaid} again after it.{p_end}

{phang}{opt steps} shows, as the algorithm advances, each of its steps: for every node that is examined, and for every splitting variable, the list of candidate pairs of categories
with the p-value of the test of their difference at each merging step (the pair with the highest p-value is merged if it is greater than 1 - {opt mergalpha()}), the categories left after
merging
with the p-value of the splitting test, its Bonferroni multiplier and the adjusted p-value, and then the list of the candidate variables with their adjusted p-values, followed by the
decision
(the variable chosen for the split and the size of the resulting branches, or the reason why the node is not split).  It works with all the other options and does not change the results.

{phang}{opt noisily} turns on the tracing of the command through split-related data management and estimation runs.  {opt noisily} 
can reassure the user that {cmd:mchaid} is running or, can show the user the entire process of determining the splits arrived at by 
{cmd:mchaid}.

{dlgtab:Graph}

{phang}{opt nograph} suppresses the graph of the tree.

{phang}A tree with very many nodes cannot be drawn (a Stata graph accepts a limited number of options): {cmd:mchaid} then says so and shows the rest of the output.  Use {opt nograph}, a
lower {opt maxbranch()} or higher {opt minnode()} and {opt minsplit()}.{p_end}

{phang}{opt treestyle(classic|boxes)} chooses the style of the graph of the tree. {cmd:classic} (default) is the one described above: the final nodes are aligned at the
bottom, each with its bar of the response variable. With {cmd:boxes} every node of the tree, the root and the intermediate nodes included, is a box with its name, its
size (n and % of the cases) and a horizontal bar with the distribution (%) of the response variable within it; under a node that is split go the splitting variable (its
variable label, if it has one) and the test of the split ({cmd:chi2 = 123; p < 0.001}: the likelihood-ratio chi-square, {cmd:F} with {opt svy}, and the
Bonferroni-adjusted p-value, as in {cmd:e(splitp)}), and, with {cmd:nodehead(number)}, on each branch, in a box, the categories of the splitting variable (by default they are the heading of the boxes, see {opt nodehead()}). The final nodes show below the predicted
category (the modal one, the one that {cmd:estat classification} uses), written in its colour. The legend has the label of the response variable and "(% within each
node)". The numbers are written with the separators of the language of the graph ({cmd:language()}: 1,234.5 in English, 1.234,5 in Spanish and the other languages, 1
234,5 in French). The title is only written if you give one with {cmd:title()}. {opt nopval} leaves out the p-values (the chi-square stays), {opt pcut()} and {opt nopct}
work as in the classic style, and {opt quartiles()} is ignored. Note that the nodes are numbered as in SPSS: all the nodes of the tree, the root being node 0, level by
level and from left to right, so the numbers of the final nodes are not those of the tables, of {cmd:e(sizes)} or of {cmd:estat classification}, which number only the
final nodes. The graph is not limited by the number of nodes (the classic one gives up when the tree is too big for the options of a Stata graph). It can be typed in the
estimation ({cmd:mchaid} {it:...}{cmd:, treestyle(boxes)}) or when typing {cmd:mchaid} again after it ({cmd:mchaid, treestyle(boxes)}).{p_end}

{phang}{opt nodeplot(bar|box)}, with {cmd:treestyle(boxes)}, chooses what each box shows of the distribution of the response variable: {cmd:bar} (default) the stacked bar
of the percentages of its categories; {cmd:box}, only with {opt dvordered}, a box plot on the scale of the categories (category j occupies the band from j-1 to j and the
percentiles are interpolated inside the category where the cumulative percentage reaches them, as the lines of {opt quartiles()} do): a box from the first to the third
quartile with the median in it, and whiskers. Under the name and the size the box writes the median category. A thin green line that sticks out of the boxes, at the same
place of all of them, marks the overall median, and the colour of the box says whether the median of the node is above (blue) or below (orange) it, the stronger the more
standard deviations (of the scale of the categories) it is away from it (one or more, the strongest; {opt noshade} gives all the same intensity). The final nodes keep
their {cmd:Pred.:}. Under the tree a legend explains the plot and a scale shows the first and the last category. {opt whisker()} sets the whiskers: {cmd:p5} (default) the
5th and 95th percentiles, {cmd:minmax} the first and the last occupied categories, {cmd:tukey} the most extreme values within 1.5 times the interquartile range of the
quartiles (outliers are not drawn). They can be typed in the estimation or when typing {cmd:mchaid} again after it.{p_end}

{phang}{opt nodehead(category|number)}, with {cmd:treestyle(boxes)}, chooses the heading of each box. {cmd:category} (default) writes in it the category (or the interval) of the splitting variable that forms the node, the one that {cmd:number} writes on the branch (for example {cmd:Right} or {cmd:<=95}); the branches then have no label, the line goes straight to the box, and the number of the node goes in a small square on its top left corner (dark, with the number in white, when the node is a final one). A heading that does not fit is written with a smaller letter, in two lines or cut with {cmd:...}; so is the {cmd:Pred.:} of the final nodes when it would touch the next one. {cmd:number} is the heading {cmd:Node N} with the categories in a box on each branch (the heading of a final node is dark, with the text in white).  The legend has an item for the final nodes. {opt rootlabel()} sets the heading of the root node, which has no category, with {cmd:nodehead(category)}: {cmd:total} (default; {cmd:Total} in the language of the graph), {cmd:depvar} (the label of the response variable) or any text, for example {cmd:rootlabel("All the sample")}. They can be typed in the estimation or when typing {cmd:mchaid} again after it.{p_end}

{phang}{opt colors(colours)} sets the colours of the categories of the response variable on the graph (both styles, bars and legend). The colours are given by category, {cmd:colors(White=navy Black="230 159 0" Other=#009E73)}, in any order, or without names, one for each category in the order of the legend, {cmd:colors(navy "230 159 0" #009E73)}. The name is the label of the category (the value, if it has no label; {cmd:missing} for the floating category) and does not distinguish upper and lower case; a name or a colour with spaces goes in double quotes, {cmd:colors("Strongly agree"=navy)}. A colour is the name of a Stata colour ({cmd:forest_green}, {cmd:cranberry}, {cmd:gs8}...), red, green and blue between 0 and 255 in quotes ({cmd:"230 159 0"}; an opacity such as {cmd:%50} is ignored) or a hexadecimal code ({cmd:#009E73}). With names, the categories that have no colour keep the default one and the names that are not categories are ignored, both with a note; without names there must be as many colours as categories. {cmd:colors(}{it:colour}{cmd:, ramp)} makes one shade of a single colour for each category, from the lightest (the first category) to the colour itself (the last one), for example {cmd:colors(green, ramp)} for an ordered response; {cmd:colors(green, ramp reverse)} goes from the darkest to the lightest. The shades are the colour mixed with white, from 20% to 100% of it, as the intensities of the trees of {helpb maid}. The labels inside the bars are written in white or black, whichever is more readable on each colour. It can be typed in the estimation or when typing {cmd:mchaid} again after it.{p_end}

{phang}{opt nopval} does not write on the graph the p-value of each split.

{phang}{opt pcut(#)}, with 0 < # < 1, writes {cmd:p<}{it:#} on the graph, as typed, for every p-value of a split that is smaller than {it:#}: {cmd:pcut(.001)} gives {cmd:p<.001}.
The other p-values are written with three decimals, or as {cmd:p<0.001} when they are smaller than that.

{phang}{opt quartiles(auto|all)}, with {opt dvordered}, adds to the graph the median (the second quartile) of each final node and, if the response variable has five categories or more, the
first and third quartiles (without this option none of these lines is drawn).  With {cmd:quartiles(auto)}, in the nodes where a quartile is so close to the median that they cannot be told
apart (almost all the cases in one category) only the median is drawn.  With {cmd:quartiles(all)} the median and the two quartiles of every node are always drawn, and the quartile lines are
thinner so that they can be seen when they are close together.  {cmd:quartiles} and {cmd:quartiles()}, without an argument, are the same as {cmd:quartiles(auto)}.  It can be typed in the
estimation or when typing {cmd:mchaid} again after it ({cmd:mchaid, quartiles(all)}); in the second case it has to be typed again each time.{p_end}

{phang}{opt language(code)} writes the texts of the graph (title, "Node", risk estimate, Cram{c e'}r's V, note of the bars and the category "missing") in another language:
{cmd:en} English (default), {cmd:es} Spanish, {cmd:fr} French, {cmd:de} German, {cmd:it} Italian, {cmd:pt} (or {cmd:po}) Portuguese, {cmd:ca} Catalan, {cmd:gl} Galician,
{cmd:nl} Dutch and {cmd:eu} Basque.  It only changes the graph, not the output in the Results window, the value labels of your variables or the names of the variables.
It needs Stata 14 or later (in earlier versions the graph is in English).  It can also be typed when {cmd:mchaid} is typed again after the estimation: {cmd:mchaid, language(es)}.

{phang}{opt graphopts(string)} passes options to the graph of the tree, for example {cmd:graphopts(title("My tree") name(g1, replace))}.  
After the estimation, the same options can be added when typing {cmd:mchaid} again.

{pstd}
The options of the graph ({opt nograph} excepted) can be typed in the estimation or when typing {cmd:mchaid} again after it.  {opt nodeplot()}, {opt whisker()}, {opt noshade},
{opt nodehead()} and {opt rootlabel()} are explained with {opt treestyle()} and {opt nodehead()}; {opt noshade} gives all the boxes of the box plots one single intensity of
blue or orange instead of making it stronger the farther the node is from the overall median.

{pstd}{opt nodeplot()}, {opt whisker()}, {opt nodehead()} and {opt noshade} belong to the style of boxes: with the classic graph a note says that they are ignored (the interactive tree of {opt directory()} does use them).  {opt rootlabel()} also works with the classic graph, where it is the heading of the root box.{p_end}

{dlgtab:Interactive tree}

{phang}{opt directory(folder)} writes the tree as an interactive HTML page in {it:folder}, which is created if it does not exist (an existing folder must be empty or hold a page written before by {cmd:mchaid}, which is replaced).  The page is {cmd:index.html}; its link is shown in the Results window and it is opened in the browser.  It follows the options of the style of boxes ({opt nodeplot()}, {opt whisker()}, {opt noshade}, {opt nodehead()}, {opt rootlabel()}, {opt colors()}, {opt language()}, {opt nopval}, {opt pcut()} and {cmd:title()} inside {opt graphopts()}), whatever {opt treestyle()} is, except that the page is drawn with the layout of the classic graph (small boxes with the category of the branch, the splitting variable and its test over the branch, and the bars only under the final nodes) when {cmd:treestyle(classic)} is typed together with {opt directory()}; then {opt nodeplot()}, {opt whisker()}, {opt noshade}, {opt nodehead()} are ignored and {opt quartiles()} draws the median and the quartiles on the bars.  {opt nograph} only stops the Stata graph.  It can also be typed when {cmd:mchaid} is typed again after the estimation, and it is written even with {opt nodisplay}.  See {help mchaid##html:The interactive tree}.{p_end}

{phang}{opt collapse(#)} starts the page with the branches below depth {it:#} collapsed: {cmd:collapse(1)} shows only the first split (the root and its nodes).  By default the whole tree is shown.{p_end}

{phang}{opt noopen} writes the page without opening it in the browser.{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
Remarks are presented under the following headings:{p_end}

{phang2}{help mchaid##algorithm:The algorithm}{p_end}
{phang2}{help mchaid##output:The output}{p_end}
{phang2}{help mchaid##display:The graph}{p_end}
{phang2}{help mchaid##html:The interactive tree}{p_end}
{phang2}{help mchaid##forced:Forced splits}{p_end}
{phang2}{help mchaid##numbering:Numbering of the clusters}{p_end}
{phang2}{help mchaid##technical:Speed and technical notes}{p_end}
{phang2}{help mchaid##changes:Differences from chaid 2.2}{p_end}


{marker algorithm}{...}
{bf:The algorithm}

{pstd}
{cmd:mchaid} is a modified version of Joseph Luchman's {cmd:chaid} (version 2.2).  It keeps the syntax and the results of {cmd:chaid},
corrects a few errors (see {help mchaid##changes:Differences from chaid 2.2}) and is considerably faster when the response variable is
treated as unordered (i.e., without {opt dvordered}, {opt svy} or {opt permute}).  {cmd:mchaid} and {cmd:chaid} can be installed side by side.

{pstd}
{cmd:mchaid} is a recursive partitioning algorithm that searches for an optimal decision tree structure based on 
the correspondence between the dependent/response variable and a set of independent/splitting variables.  {cmd:mchaid} is part 
prediction, part clustering estimation command that seeks to reduce uncertainty about the values of/predict a response variable 
but simultaneously partitions the dataset into clusters of observations based on the set of splitting variables.  

{pstd}
The {cmd:mchaid} algorithm cycles through 2 (or, optionally, 3) processes recursively.  First, {cmd:mchaid} seeks to reduce overfitting the data
by optimally merging together categories/levels of a splitting variable {it:i}.  Without the optimal merging step, the splits {cmd:mchaid} uncovers 
tend to be biased toward predictors with more categories.  In the merging step, {cmd:mchaid} chooses a splitting variable {it:i} of the {it:p} total 
splitting variables and deciphers the total number of possible combinations {it:k} of 2 levels {it:j} of splitting variable {it:i} that are 
"mergable" according to the splitting variable type (for unordered splitting variables, all combinations of two levels are possible; for ordered 
splitting variables, only adjacent level value combinations are possible).  {cmd:mchaid} then takes combination {it:j} and conducts a statistical 
association test (i.e., chi-square) using combination {it:j} (i.e., omitting all other combinations, using combination {it:j} as a dummy 
code/indicator) on the response variable to determine the probability (i.e., p-value) of the association between the response variable and the 
categories separated by combination {it:j} being 0. The process of obtaining p-values from a chi-square test continues for all {it:k} combinations 
of splitting variable {it:i}.  After all {it:k} combinations have obtained a p-value, {cmd:mchaid} finds the combination {it:j} that has the highest 
p-value/weakest association with the response variable.  If the magnitude of the p-value is higher than a user-defined threshold, combination 
{it:j} are merged into a single category.  To add a little more detail, high p-values in the merging step indicate a high probability that the 
categories separated by combination {it:j} are independent of the response variable, would not likely produce a meaningful split, and can 
effectively be merged together.  After merging the categories with the highest p-value, {cmd:mchaid} then begins again, deciphering, again for 
splitting variable {it:i}, the number of valid combinations {it:k} with the formerly separate categories now treated as a single category.  
The merging process continues for splitting variable {it:i} until the combination {it:j} with the highest p-value does not pass the user defined 
threshold for merging or there are 2 levels remaining in the optimally merged splitting variable.  When the p-value for combination {it:j} does 
not pass the threshold for merging, {cmd:mchaid} remembers the optimal merging of levels associated with splitting variable {it:i} and moves to 
the next splitting variable. The optimal merging stage continues until all {it:p} splitting variables have an optimally merged structure.  
{cmd:mchaid} then moves to step 2.

{pstd}
Following the merging step, mchaid moves to the second, splitting step. {cmd:mchaid} uses the optimally merged structure to decide which variable, 
if any, should be used to split the data into clusters/nodes.  For all {it:p} optimally merged splitting variables, {cmd:mchaid} conducts a chi-square 
association test of that splitting variable {it:i} on the response variable and records the p-value.  Owing to the multiple comparisons, the 
p-value in the splitting step is Bonferroni adjusted according to splitting variable type.  After obtaining all {it:p} adjusted p-values, 
{cmd:mchaid} finds the smallest and, if the p-value threshold and other splitting criteria are met, the data are split into clusters/nodes based on 
the splitting variable with the smallest adjusted p-value.  Besides the p-value threshold, {cmd:mchaid} imposes several other criteria on splits.
In particular, the clusters/nodes must be of a certain size.  For example, if the minimum cluster/node size is 100, and {cmd:mchaid} finds a split 
in the data that would produce 3 clusters of size 175, 120, and 80 - the split will be prevented as one of the possible splits is smaller than the 
minimum.  When {cmd:mchaid} finds a split that will be smaller than the minimum size, all the observations in the data associated with that potential 
split are removed from consideration of any remaining splits and the algorithm moves to other observations that are still "splitable".  If 
{cmd:mchaid} produces a split in the data, or decides to move along to other splitable observations, it begins again at Step 1 and forgets the 
optimal merging it produced in the previous step.  Moreover, {cmd:mchaid} now searches {bf:within} each cluster for another optimal merger set and 
potential split.  Thus, when a split occurs, all subsequent merging and splitting are contingent on previous splits and the dataset is "partitioned" 
conditional on the previous splits.

{pstd}
The {cmd:mchaid} algorithm stops when a] the minimum cluster/node size is not met for potential splits across all clusters, b] the minimum cluster/node 
size is not met for splitting across all clusters (i.e., when {cmd:mchaid} moves from Step 2 back to Step 1, the size of the cluster is below the 
minimum size allowed to attempt a split, c] the cluster/node is pure (i.e., composed of single value of response variable), d] the maximum number 
of branches/contingencies is met, and e] a cluster has a single value for each splitting variable (i.e., no splits possible).  
When the 5 criteria are met across all observations/clusters/nodes in the data, {cmd:mchaid} stops and reports results.

{pstd}
Traditionally, a third step occurring during Step 1  above involving attempting to "re-split" a merged combination of the levels of a splitting 
variable is attempted.  Specifically, after a merger between combination {it:j} occurs, if combination {it:j} contains 3 or more levels of 
splitting variable {it:i}, {cmd:mchaid} attempts a "Step 2-like" split in which {cmd:mchaid} searches through all potential binary splits (i.e., 
splits into 2 categories) of the 3 or more optimally merged categories.  If the used-defined threshold is met, the split is carried out and the 
newly split set of levels is substituted into the merging levels set in Step 1.  The "re-split" step is implemented in {cmd:mchaid} as an option 
(when {opt respalpha()} receives a positive probability value).  The re-splitting step is necessary to reach near optimal results, but can greatly 
increase run time and as Kass (1980) notes "In practice a merger is rarely split,..." (p. 121).  Hence, the user can choose to invoke or ignore 
this step.

{pstd}
The current implementation of {cmd:mchaid} differs from the traditional use of contingency tables in that it uses logistic models to 
estimate chi-square values and, as such, may require somewhat larger sample sizes than do other implementations of {cmd:mchaid} for the 
{cmd:ml} algorithm to converge.  The default estimation method for {cmd:mchaid} is {help mlogit}.  The use of Stata's {cmd:ml} based commands 
greatly increases the flexibility of the kinds of data {cmd:mchaid} can accommodate.  {cmd:mchaid} also uses {help levelsof} to separate out levels 
of splitting and response variables.  Consequently, all splitting variables and the response variable must non-negative integers and, for the 
current implementation, must have fewer than 21 levels or unique values.

{pstd}
{cmd:mchaid} generates, by default, a variable named {cmd:_CHAID} after finishing execution that indicates each observation's 
membership in a cluster as defined by {cmd:mchaid}.  If you have a variable named {cmd:_CHAID} already in your dataset, {cmd:mchaid} 
will overwrite it with the new value of {cmd:_CHAID} based on the current cluster membership.


{marker output}{...}
{bf:The output}

{pstd}
The decision tree structure is returned in two forms: as a matrix that is read from top-down (option {opt branches}), and as a graph (see {help mchaid##display:The graph}).
For example consider the results from example #1 below (i.e., the below matrix is exactly what {cmd:mchaid} reports with option {opt branches}):

{res}Chi-Square Automated Interaction Detection (CHAID) Tree Branching Results
{txt}{hline 80}

{col 20}1{col 34}2{col 48}3{col 62}4
{txt}{col 6}{c TLC}{hline 57}{c TRC}
{col 4}1{col 6}{c |}{col 11}{res}xtlength@1{col 25}xtlength@2{col 39}xtlength@2{col 53}xtlength@3{col 64}{txt}{c |}
{col 4}2{col 6}{c |}{res}{col 24}rep78@1 3 2{col 40}rep78@4 5{col 64}{txt}{c |}
{col 4}3{col 6}{c |}{res}{col 11}{res}Node #1{col 25}Node #2{col 39}Node #3{col 53}Node #4{col 64}{txt}{c |}
{txt}{col 6}{c BLC}{hline 57}{c BRC}

{pstd}
The results show that 4 clusters were uncovered from the data - each column represents a distinct cluster uncovered by {cmd:mchaid}.  The first split is represented in the first 
row.  Each column in the first row has a variable name, an ampersat sign, and some valid values of the variable.  The variable name represents
the variable on which the first split occurred for the {cmd:mchaid} algorithm - in this case the {help xtile}d length variable from the auto 
dataset.  The values following the ampersat signs refer to the values chosen through the optimal merging steps described above of the variable.  
In this case, all valid values were deemed by {cmd:mchaid} to be different from one another and were not merged.  Thus, split #1 was on the lentile
variable into levels 1, 2, and 3.  The dataset was then partitioned based on that split and the remaining splits are then conditional on the first 
split.  All successful {cmd:mchaid} runs will have a populated first row.

{pstd}
Notice that Clusters #2 and #3 have repeated values of xtlength@2.  This is because another split occurred within xtlength@2, but not for xtlength@1 
or xtlength@3 - which is why each only has an entry at the first row.  The split on xtlength@2 is represented in the second row for the rep78 
variable, splitting into optimally merged 1 3 2 and 4 5 groups.  Thus, given a observation was in xtlength category 2, one additional split was 
possible putting observations into rep78 1 3 and 2 versus 4 and 5.  The rows "lower" on the matrix are then response on the rows "higher"
in the matrix.  Furthermore, the number of rows represents the number of "branches" the decision tree has.  Finally, each column represents each 
cluster's unique "path" leading from the first split in row 1 to the final populated row of the column/cluster in question.

{pstd}
{bf:Node definitions and table.}  In the output the final clusters are called {it:nodes}: {cmd:Node #1}, {cmd:Node #2}, etc.  With option {opt definitions}, {cmd:mchaid} lists each node with
its number,
its size (weighted when {opt fweight}s are used) 
and the categories that define it, using the value labels of the splitting variables when there are any (for example, {cmd:xtlength = 2 & rep78 in {c -(}Poor, Fair, Average{c )-}}), 
and, always, shows the table of the response variable by cluster: clusters in the rows (the first column holds the cluster labels, with their definitions), the categories of the response
variable in the columns, 
and in each cell the row percentage (the distribution of the response variable within the cluster); the column Total shows the frequencies in parentheses.  The table is made with
{help table} (Stata 17 or later) and is kept as the 
collection {cmd:mchaid_tab}, so it can be changed with {help collect} or exported with {cmd:collect export}; in earlier versions of Stata {help tabulate twoway} is used.  Below the 
table, {cmd:mchaid} shows the risk estimate (the proportion of cases that would be misclassified if every case were assigned the modal category of its node; in parentheses, the same
proportion for the root node), the Pearson and likelihood-ratio chi-square tests of the association between the response variable and the clusters and Cram{c e'}r's V.  Because the 
clusters were chosen to be as associated with the response variable as possible, these tests are descriptive and should not be used for inference.  The same definitions are attached to
{cmd:_CHAID} as value labels 
({cmd:label list mchaid_clu}), and are available in {cmd:e(path#)}.

{pstd}
{bf:Ordered splitting variables.}  In the definitions, in the branches of the tree and in the output of {opt steps}, when three or more adjacent categories of an ordered variable
({opt ordered()} or {opt xtile()}) are merged only the first and the last are written: {cmd:{c -(}1-3{c )-}} when the categories have no value labels and {cmd:{c -(}Poor~Average{c )-}} when
they do. Groups of one or two categories are written in full, the {opt missing} category always comes last and on its own ({cmd:{c -(}1-3, missing{c )-}}), and {cmd:e(path#)} keeps all the
categories.  The ordered variables and their categories are saved in {cmd:e(ordered)} and {cmd:e(ordlev#)}.


{marker display}{...}
{marker graph}{...}
{bf:The graph}

{pstd}
The classic graph is drawn as a decision tree: every node is a small box whose heading is the category, or group of categories, of the splitting variable that leads to it (with their value
labels when there are any; the root says {cmd:Total}, or what {opt rootlabel()} says) and, under it, the number of observations of the node (in a smaller type).  The splitting variable of a
node and its test are written over the branches that leave it, on a white block under its box.  Each final node ("cluster") has at the bottom a stacked bar with the distribution (%) of
the response variable; the percentage of the modal category of each node is marked with an asterisk.  The boxes do not carry the number of the node: the numbers of the clusters are those
of {cmd:e(sizes)} and of the table of the output, in the order of the tree from left to right.  Colours are sequential (light to dark)
with {opt dvordered} and qualitative otherwise.  With {opt dvordered} and option {opt quartiles()} a green line marks, in the bar of each final node, the median (the second quartile) of that
node and, when the response variable has five categories or more, dotted green lines mark the first and third quartiles; without {opt quartiles()} no line is drawn.  The height of a line is
the {it:value} of the percentile on the scale of the categories, not the position of the segment where it falls: the bar is divided in as many equal bands as categories (the first category
at the bottom) and the percentile is interpolated inside the category where the cumulative percentage reaches 25, 50 or 75% ({it:category} - 1 + (50 - cumulative percentage before it)/its
percentage, divided by the number of categories, for the median).  Therefore the lines are higher in the nodes with more cases in the high categories, and they can be compared between nodes;
the scale of the lines is that of the categories, not the % of the bar.  When nearly all the cases of a node are in one category the quartiles would be too close to the median to be told
apart from it, and then only the median of that node is drawn; lines that coincide are drawn once.  The lines are interrupted around the percentages so that these can be read; the legend
explains them.  
The sizes of the graph and of the text depend on the number of clusters and the depth of the tree.  The heading of a box is written with a smaller type, in two lines or cut with {cmd:...}
when the list of categories is too long for the box; {cmd:Node definitions} shows them in full. The significance of each split (the Bonferroni-adjusted p-value used to decide it, also stored in {cmd:e(splitp)}) is written
under the name of the splitting variable, in the block over the branches that leave the node, preceded by the test statistic of the split (the
likelihood-ratio chi-square, or F with {opt svy}, also stored in {cmd:e(splitchi)}: {cmd:chi2=2131; p<0.001}), with three decimals ({cmd:p=0.012}) or as {cmd:p<0.001} when it is smaller than that. Two options control it: {opt nopval} removes the test statistics and the p-values, and
{opt pcut(#)} (0 < # < 1) writes {cmd:p<}{it:#} for every p-value below {it:#}, as typed ({cmd:pcut(.001)} gives {cmd:p<.001}); the p-values above it keep the default
format. The last line of the graph
shows, on the left, the
risk estimate (the proportion of cases that would be misclassified if every case were assigned the modal category of its node; in parentheses, the same proportion for the root node,
that is, without the tree: one minus the proportion of the most frequent category of the response variable) and Cram{c e'}r's V between the response variable and the nodes.
The two options for the p-values can be
typed in the estimation, for example {cmd:mchaid} {it:...}{cmd:, pcut(.001)}, or when typing {cmd:mchaid} again after the estimation ({cmd:mchaid, pcut(.001)}).

{pstd}
With {cmd:treestyle(boxes)} every node of the tree is a box (see the options {opt treestyle()}, {opt nodeplot()}, {opt nodehead()} and {opt colors()}).

{pstd}
Option {opt graphopts()} passes {help twoway_options:twoway options} to the graph (for example, {cmd:graphopts(title("My tree") name(g1, replace))}), and {opt nograph} suppresses it.  
Typing {cmd:mchaid} after the estimation (without a variable list) shows the output again, and accepts the same graph options directly, for example 
{cmd:mchaid, name(g2, replace) scheme(s1mono)}, {cmd:mchaid, nopct} (no percentages inside the bars), {cmd:mchaid, nopval} (no p-values on the branches), or
{cmd:mchaid, saving(tree, replace)}.


{marker html}{...}
{bf:The interactive tree}

{pstd}
With {opt directory()} the tree is also written as a page that runs in any browser, with no Internet connection: {cmd:index.html} and the folders {cmd:styles} and {cmd:scripts}.  It is the page that function {cmd:tree_html()} of the R package {cmd:mchaid} writes, and it shows what the graph in the style of boxes shows: a box for every node with the distribution of the response variable (bars, or a box plot with {cmd:nodeplot(box)} and an ordered response), the splitting variables with their tests and the predicted category of the final nodes.  Put the mouse over a node to see its definition, its size and the distribution of the response variable (counts and percentages); click the sign next to a splitting variable to collapse or expand its branches; drag the tree to move it and use the wheel of the mouse to zoom; the buttons expand or collapse the whole tree, fit it to the window and save it as an SVG or PNG image.

{pstd}
The folder can be copied or sent as it is.  The data of the tree are written inside the page, so whoever opens it sees the tree (not the data of your file).  To write the page again with other options, type {cmd:mchaid, directory(}{it:folder}{cmd:)} and the options after the estimation.


{marker forced}{...}
{bf:Forced splits}

{pstd}
With {opt forcevars()} the first levels of the tree are chosen by the user: {cmd:forcevars(}{it:v1 v2}{cmd:)} splits the sample by {it:v1} and every node of the next level by {it:v2}.  Each node merges the categories of the forced variable on its own, so the groups may differ from one branch to another.  The variables are forced whether or not they are significant: the adjusted p-value of the split is still computed and written in the graph, and it may be above {opt spltalpha()}; in that case the split is binary.  If in a node of a deeper level the forced split is not possible, the node grows freely, with all the variables, and the command notes it; {opt steps} shows these decisions.  The tests of the nodes are descriptive, as always, and more so with variables chosen in advance.

{pstd}
In the graph the variable of every split chosen with {opt forcevars()} is followed by an asterisk (a dagger in the classic graph, where the asterisk marks the modal category of the bars) and a note, in the language of {opt language()}, explains the mark.  The splits below the forced levels, and those of the nodes where the forced split was not possible, carry no mark.  {cmd:e(forcevars)} keeps the variables and {cmd:e(splitforced)} marks the splits (1) in the layout of {cmd:e(splitp)}.


{marker numbering}{...}
{bf:Numbering of the clusters}

{pstd}
{cmd:mchaid} numbers the clusters (the values of {cmd:_CHAID}) in the order of the tree: from the first to the last branch 
of the first split and, within each branch, from the first to the last branch of the next split, and so on - that is, from left to right in the tree 
shown above.  Within a split the branches are ordered by their lowest category of the splitting variable (so that {cmd:rep78@1 3 2} comes before 
{cmd:rep78@4 5}).  {cmd:chaid} instead numbered the clusters in the order in which the algorithm created them: the first branch of a split kept the number of the cluster that was split, the 
other branches received the next free numbers, and the algorithm then worked on the clusters in that order.  Option {opt norenumber} restores that 
numbering.


{marker technical}{...}
{bf:Speed and technical notes}

{pstd}{cmd:mchaid} computes the merging and splitting tests of the default analysis ({help mlogit}, no {opt svy}, no {opt permute}) in Mata from 
cross-tabulations instead of estimating one {help mlogit} per candidate pair of categories.  The test statistic (likelihood-ratio chi-square 
of a model with a dummy for the merged categories), the degrees of freedom and the information criterion are the same as those {help mlogit} 
reports, so the trees are the same as those obtained with {opt nofast}.  For ordered splitting variables, the final splitting test uses the 
category code as one linear term, as does {cmd:chaid}; this is also computed in Mata with a Newton-Raphson algorithm.  In speed tests, 
runs with six predictors on {cmd:nhanes2f} take about 0.7 seconds instead of 4.2.  Options {opt dvordered}, {opt svy} and {opt permute}, 
and the re-splitting step ({opt respalpha()}), still use the original estimation based procedures.

{pstd}Because there is a component of randomness to the {cmd:mchaid} results, the user should {help set seed} prior to using {cmd:mchaid}.  
Additionally, {cmd:mchaid} utilizes Mata and saves a string matrix there that the user can access post estimation.  One Mata matrix, called 
"CHAIDsplit", contains information used to create the {cmd:e(split#)} and {cmd:e(path#)} macros.  In some instances, most especially with complicated 
and large CHAID trees, the strings contained in some of the {cmd:e(path#)} macros will be truncated.  Users knowledgeable of Mata can obtain such 
information from the "CHAIDsplit" Mata matrix.  To be specific, "CHAIDsplit" includes, in the first row, information regarding all the splits in 
the data.  The first column is a label, "splits", and each column thereafter corresponds to a split made in the data.  The labels are represented as 
"{it:varname value}" with no space between them.  Thus, the {it:rep78} variable from the auto dataset would have 5 labels: rep781, rep782, rep783, 
rep784, and rep785 - corresponding to all 5 levels of the rep78 variable. Merged categories are separated in the "splits" row by commas.  Thus, any 
labels not separated by a comma have been "optimally merged" by {cmd:mchaid}.  The remaining rows correspond to the "path" represented by each cluster. 
Thus "path1" is the set of contingencies (or "and" logical statements that resulted in "Cluster #1", "path2" is the set of contingencies that 
resulted in "Cluster #2", etc... using the labels as outlined above (i.e., with "{it:varname value}" format).

{pstd}As with other computationally intense programs (e.g., {stata findit gllamm}), collapsing the data over identical observations and 
using a {cmd:fweight} is a way to speed up estimation time for larger datasets.  Given that {cmd:mchaid} requires categorical data, using the 
{help collapse} command is a particularly useful approach - but, again, will not work with {opt svy} or {opt permute}.

{pstd}Due to numerical issues related to storage of very small p-values, {cmd:mchaid} uses the Akaike information criterion (AIC; see {help estat}) 
to decide on splits when p-values are identical (i.e., when both are effectively 0 at ~10^-300). 


{marker changes}{...}
{bf:Differences from chaid 2.2}

{phang}1. When two or more tests of merging categories had identical p-values, the information criterion used to break the tie was compared across all 
candidate pairs rather than only among the tied ones.  Ties are now broken among the tied pairs.  This can change the tree for small samples.{p_end}

{phang}2. The small-sample corrected AIC used the term (2k^2 + 1)/(n - k - 1); it is now 2k(k + 1)/(n - k - 1).  It only matters to break ties.{p_end}

{phang}3. The Bonferroni adjustment for a "floating" missing category was computed but not stored (the adjusted p-value was 0).{p_end}

{phang}4. With {opt respalpha()}, the tie-breaking among splits of merged categories compared strings with the arguments in the wrong order, 
and with {opt exhaust} the threshold for re-splitting was computed from an indicator vector instead of from the largest p-value, so re-splitting never happened.  Correcting this makes
exhaustive CHAID merge and re-split indefinitely, so {opt respalpha()} is now ignored with {opt exhaust} (as it was in practice in {cmd:chaid}).{p_end}

{phang}5. With {opt svy} and {opt respalpha()} a parenthesis was missing in the {cmd:subpop()} specification.{p_end}

{phang}6. Debugging output and no-op commands were removed.  {opt noisily} therefore shows less detail than in {cmd:chaid}.{p_end}

{phang}7. {cmd:mchaid} numbers the clusters in the order of the tree (see {help mchaid##numbering:Numbering of the clusters}); {opt norenumber} gives the numbering of {cmd:chaid}.  
{cmd:mchaid} also lists the definition of each cluster, shows the table of the response variable by cluster with row percentages and tests of association, and labels {cmd:_CHAID} with the
definitions.{p_end}

{phang}8. {cmd:e(sizes)} counted observations even when {opt fweight}s were used; it now adds the weights.{p_end}

{phang}9. After splitting a node with an unordered variable, that variable stayed in the children with a single category: its Bonferroni multiplier was 0, so its adjusted p-value was 0 and
it won over all 
the other variables, and the children were never split.  A variable with fewer than two categories in the node is no longer a candidate.  
Trees with an unordered splitting variable at the first level had stopped there; now they grow.{p_end}

{phang}10. With equal p-values, the split was chosen at random whenever the AIC of the new candidate was not lower than that of the current one; it is now random only when the AIC is also
equal, 
so the same command gives the same tree.{p_end}

{phang}11. With {opt svy} or {opt permute} the unordered splitting variables were not tested ({cmd:xi:} cannot be used inside {cmd:permute}); they are now tested with factor
variables.{p_end}

{phang}12. The Bonferroni multiplier of the unordered splitting variables, the number of ways of merging the {it:C} categories into {it:g} groups (a Stirling number of the second kind), 
left out the last term of its sum, so it was too large by (-1)^({it:g}-1)/({it:g}-1)! (for two groups, 2^({it:C}-1) instead of 2^({it:C}-1) - 1; for {it:C} = {it:g} = 3, 0.5 instead of 1). 
It is now exact; trees can change when an adjusted p-value is close to {opt spltalpha()}.{p_end}

{phang}13. With {opt dvordered}, the tests of the merging and re-splitting steps were run under {cmd:version 10:}, where {help ologit} stops with error 430 when two groups of categories 
are completely separated on the response; the pair then received p = 1 and was merged before any other.  {cmd:version 10:} was removed, so such groups are kept apart. 
When the groups are completely separated {cmd:ologit} still does not converge (error 430, after seconds of iterations): 
the tests now use the limit of the likelihood-ratio statistic (that of the last iteration or, without estimating it when the ranges of the response of the two groups do
not overlap, that of the response within each group) 
and p = 1 is no longer used.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}#1: Basic CHAID analysis with altered {opt minsplit()} and {opt minnode()}{p_end}

{phang}{cmd:. set seed 1234567}{p_end}

{phang}{cmd:. webuse auto}{p_end}

{phang}{cmd:. mchaid foreign, unordered(rep78) minnode(4) minsplit(10) xtile(length, n(3))}{p_end}

{pstd}The graph again in the style of boxes, with your own colours and in Spanish{p_end}

{phang}{cmd:. mchaid, treestyle(boxes) colors(Domestic=navy Foreign="230 159 0") language(es)}{p_end}

{pstd}The first levels of the tree chosen by the user: the length group, then the repair record{p_end}

{phang}{cmd:. mchaid foreign, unordered(rep78) minnode(4) minsplit(10) xtile(length, n(3)) forcevars(length rep78)}{p_end}

{pstd}The same tree as an interactive page (it is written in the folder {cmd:auto_tree} of the current directory), with the branches below the first split collapsed{p_end}

{phang}{cmd:. mchaid, directory(auto_tree) collapse(1)}{p_end}

{pstd}The graph can be saved as an editable vector graphic (SVG; checked in Stata 17 to 19){p_end}
{phang}{cmd:. graph export tree.svg, replace}{p_end}

{pstd}#2: Basic CHAID analysis as in #1 with permutation tests{p_end}

{phang}{cmd:. mchaid foreign, unordered(rep78) minnode(4) minsplit(10) xtile(length, n(3)) permute}{p_end}

{pstd}#3: Larger-scale CHAID with ordered response variable and permutation importance{p_end}

{phang}{cmd:. webuse nhanes2f, clear}{p_end}

{phang}{cmd:. mchaid health, dvordered unordered(region race) ordered(houssiz sizplace diabetes sex smsa heartatk) importance}{p_end}

{pstd}The same tree with a box plot in each node and the categories in shades of green{p_end}

{phang}{cmd:. mchaid, treestyle(boxes) nodeplot(box) colors(forest_green, ramp)}{p_end}

{pstd}#4: Larger-scale CHAID with ordered response variable; collapsed using fweight{p_end}

{phang}{cmd:. preserve}{p_end}

{phang}{cmd:. generate byte fwgt = 1}{p_end}

{phang}{cmd:. collapse (sum) fwgt, by(health region race houssiz sizplace diabetes sex smsa heartatk)}{p_end}

{phang}{cmd:. mchaid health [fweight = fwgt], dvordered unordered(region race) ordered(houssiz sizplace diabetes sex smsa heartatk)}{p_end}

{phang}{cmd:. restore}{p_end}

{pstd}#5: Exhaustive CHAID with complex survey design{p_end}

{phang}{cmd:. svyset psuid [pweight=finalwgt], strata(stratid)}{p_end}

{phang}{cmd:. mchaid health, dvordered unordered(region race) ordered(houssiz sizplace diabetes sex smsa heartatk) svy exhaust}{p_end}


{marker postestimation}{...}
{title:Postestimation: estat classification}

{pstd}Syntax: {cmd:estat classification} [{cmd:,} {opt pos:itive(category)}]

{pstd}After {cmd:mchaid}, {cmd:estat classification} shows the classification table of the analysis: every case is classified in the modal category of its node and compared with its real
category.
The rows are the real categories of the response variable, the columns the categories assigned by the tree, and the table gives the totals and the percentage correctly classified in each
real
category and in the whole sample.  The proportion of cases wrongly classified is the {it:risk estimate} shown in the last line of the graph.  Nodes with ties are classified in the first of
the tied categories.
With {opt missing}, the missing category of the response variable (when it is not ordered) is one more category of the table.  The table uses the sample of the tree and, with {opt fweight}s,
the weights.

{pstd}Below the table, {cmd:estat classification} gives, for every category of the response variable taken in turn as the positive one against all the others, the sensitivity (recall), the
precision (positive predictive value),
the F1 score, the specificity and the negative predictive value (NPV), in this order and in %.  They are not limited to 2x2 tables: with {it:k} categories there are {it:k} sets of
statistics, one for each category versus the rest.
Option {opt positive(category)}, where {it:category} is the label of the category (or its position in the table), also lists all the statistics of that category in the format of
{cmd:estat classification}
after {cmd:logit}: sensitivity, specificity, predictive values, the four false positive and false negative rates and the percentage correctly classified (category versus rest),
for example {cmd:estat classification, positive(PP)}.  A statistic is missing ({cmd:.}) when its denominator is zero, as the PPV of a category in which no case is classified.

{pstd}The F1 score of each category, 2*PPV*sensitivity/(PPV + sensitivity), is the harmonic mean of the positive predictive value (precision) and the sensitivity (recall), that is 2TP/(2TP +
FP + FN); it is 0 for a category without
correct classifications.  It does not use the specificity, so it cannot be obtained from the sensitivity and the specificity alone.  Below the table the F1 is averaged over the categories,
with the same weight for all
({cmd:macro}) and weighted by the number of real cases of each one; the micro-average of F1 is the percentage of correctly classified cases.

{phang}{cmd:estat classification} saves in {cmd:r()}: {cmd:r(N)} (cases), {cmd:r(N_correct)} (correctly classified), {cmd:r(pct_correct)}, {cmd:r(risk)} (risk estimate),
{cmd:r(class)} (matrix: real category in the rows, classified category in the columns), {cmd:r(stats)} (matrix: a row for each category and the columns {cmd:sensitivity}, {cmd:specificity},
{cmd:ppv}, {cmd:npv},
{cmd:fpos_true}, {cmd:fneg_true}, {cmd:fpos_class}, {cmd:fneg_class} and {cmd:f1}, the four before the last being the false + rate for true ~D, the false - rate for true D, the false + rate
for classified + and the false - rate for classified -;
all in %), {cmd:r(f1_macro)} and {cmd:r(f1_weighted)} (in %) and {cmd:r(depvar)}.  It is in the file {cmd:mchaid_estat.ado}, which has to be installed with {cmd:mchaid.ado}.

{marker results}{...}
{title:Saved results}

{pstd}{cmd:mchaid} saves the same results as {cmd:chaid}, with {cmd:e(cmd)} equal to {cmd:mchaid}, and in addition {cmd:e(renumber)} ({cmd:norenumber} when the clusters keep the order of
creation), 
{cmd:e(missing)} ({cmd:missing} if the option was used), and {cmd:e(wtype)} and {cmd:e(wexp)} when {opt fweight}s were used.

{phang}{cmd:mchaid} saves the following results to {cmd: e()}:

{synoptset 16 tabbed}{...}
{p2col 5 15 19 2: scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_clusters)}}number of clusters created by {cmd:mchaid} and returned in {cmd:_CHAID} variable{p_end}
{synopt:{cmd:e(fit)}}purity of the clusters (extent to which each cluster has only a single value of the response variable); 
based on Cram{c e'}r's V{p_end}
{p2col 5 15 19 2: macros}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(cmd)}}{cmd:mchaid}{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(ordered)}}ordered splitting variables ({opt ordered()} and the variables created by {opt xtile()}){p_end}
{synopt:{cmd:e(ordlev#)}}categories of the #th variable in {cmd:e(ordered)}, in order ({cmd:missing} last){p_end}
{synopt:{cmd:e(path#)}}displays the levels of each split leading to cluster #.  Each split is separated by semicolons.  
The splitting variable is first followed by an "at" sign (i.e., @) followed by the levels of the splitting variable that 
describes cluster # at that split{p_end}
{synopt:{cmd:e(split#)}}displays the #th split by {cmd:mchaid}.  Splitting variable is displayed first followed 
by the optimal mergers of levels of the splitting variable.  Each merged set of splitting variable levels is separated 
by parentheses{p_end}
{synopt:{cmd:e(depvar)}}name of dependent/response variable{p_end}
{synopt:{cmd:e(splitstat)}}{cmd:chi2} or {cmd:F}: the statistic in {cmd:e(splitchi)}{p_end}
{synopt:{cmd:e(forcevars)}}variables of {opt forcevars()}{p_end}
{p2col 5 15 19 2: matrices}{p_end}
{synopt:{cmd:e(importance)}}permutation importance matrix{p_end}
{synopt:{cmd:e(sizes)}}sample size of each cluster{p_end}
{synopt:{cmd:e(branches)}}number of branches from the root node for each cluster{p_end}
{synopt:{cmd:e(splitp)}}adjusted p-value of each split on the path of each cluster (rows: clusters; columns: level of the tree; missing where the path ends){p_end}
{synopt:{cmd:e(splitforced)}}1 where the variable of the split was chosen with {opt forcevars()}, like {cmd:e(splitp)}{p_end}
{synopt:{cmd:e(splitchi)}}test statistic of each split, like {cmd:e(splitp)} (likelihood-ratio chi-square; F with {opt svy}){p_end}
{p2col 5 15 19 2: functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{pstd}
{cmd:mchaid} is {cmd:rclass} and also leaves its estimation results in {cmd:e()}.  It saves the following in {cmd:r()}; typing {cmd:mchaid} without arguments 
after the estimation shows the output again and saves {cmd:r()} again:

{synoptset 16 tabbed}{...}
{p2col 5 15 19 2: scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations (sum of the weights){p_end}
{synopt:{cmd:r(N_clusters)}}number of clusters{p_end}
{synopt:{cmd:r(N_dv)}}number of categories of the response variable{p_end}
{synopt:{cmd:r(df)}}degrees of freedom of the tests of association{p_end}
{synopt:{cmd:r(chi2)}, {cmd:r(p)}}Pearson chi-square test of the response variable by cluster and its p-value{p_end}
{synopt:{cmd:r(chi2_lr)}, {cmd:r(p_lr)}}likelihood-ratio chi-square test and its p-value{p_end}
{synopt:{cmd:r(CramersV)}}Cram{c e'}r's V{p_end}
{p2col 5 15 19 2: macros}{p_end}
{synopt:{cmd:r(depvar)}}name of the response variable{p_end}
{synopt:{cmd:r(dvlevels)}}values of the response variable, in the order of the columns of the matrices{p_end}
{synopt:{cmd:r(dvlabels)}}labels of those values (the value labels when there are any){p_end}
{synopt:{cmd:r(label#)}}label of cluster #, with its definition (for example, {cmd:1: xtlength = 2 & rep78 in {c -(}Poor, Fair{c )-}}){p_end}
{synopt:{cmd:r(labels)}}all the cluster labels, each in double quotes{p_end}
{p2col 5 15 19 2: matrices}{p_end}
{synopt:{cmd:r(freq)}}frequencies of the cross-tabulation, clusters in rows and categories of the response variable in columns (weighted when {opt fweight}s are used){p_end}
{synopt:{cmd:r(rowpct)}}row percentages of {cmd:r(freq)} (distribution of the response variable within each cluster){p_end}
{synopt:{cmd:r(colpct)}}column percentages of {cmd:r(freq)} (distribution of the clusters within each category of the response variable){p_end}
{synopt:{cmd:r(clusfreq)}}frequencies of the clusters (column vector){p_end}
{synopt:{cmd:r(dvfreq)}}frequencies of the categories of the response variable (row vector){p_end}

{marker references}{...}
{title:References}

{p 4 8 2}Kass, G. V. (1980). An exploratory technique for investigating large quantities of categorical data. {it:Applied Statistics, 29, 2}, 119-127.{p_end}

{p 4 8 2}Biggs, D., de Ville, B., and Suen, E. (1991). A method of choosing multiway partitions for classification and decision trees. {it:Journal of Applied Statistics, 18}, 49-62.{p_end}

{title:Author}

{p 4}Joseph N. Luchman{p_end}
{p 4}Behavioral Statistics Lead{p_end}
{p 4}Fors Marsh Group LLC{p_end}
{p 4}Arlington, VA{p_end}
{p 4}jluchman@forsmarshgroup.com{p_end}

{p 4}Modesto Escobar{p_end}
{p 4}Universidad de Salamanca{p_end}
{p 4}modesto@usal.es{p_end}

{title:Acknowledgements}

{phang}Thanks to Florian Zettelmeyer, Paul Bergmann, and Kimberly Wilson for bug reporting.  
Thanks also to Jonathan Mendelson and Luke Viera for comments on the functionality of and suggestions about features for {cmd:mchaid}.
Thanks to Claude (Sonnet 5.5) for its contributions to this {cmd: mchaid} version.

{phang}Grants CSO2013-49278-EXP, PGC2018-093755-B-I00, PDC2022-133355-I00, PID2023-147358NB-I00 funded by MICIU/AEI/10.13039/501100011033 and by "European Union NextGenerationEU/PRTR".{p_end}

{title:Also see}

{psee}
{manhelp mlogit R}, {manhelp ologit R}, {manhelp levelsof R}, {manhelp tabulate_twoway R:tabulate twoway}, {manhelp svy R}, {manhelp permute R},
{manhelp xtile R}.
{p_end}