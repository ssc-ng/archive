{smcl}
{title:Title}

{p 4 8}
{cmd:elecdisp} — Calculate election disproportionality indices for electoral results data.

{title:Syntax}

{p 8 17 2}
{cmd:elecdisp} {it:vote_share} {it:seat_share} {it:election_id} {ifin}{cmd:,} {opt inputscale(percentage|proportion)} {opt outputscale(percentage|proportion)} [{opt noprint}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt inputscale()}}specifies the scale of your data.{p_end}
{synopt:{opt outputscale()}}specifies the scale of the calculated disproportionality indices.{p_end}
{synopt:{opt noprint}}suppresses the displayed results; stored results are still returned in {cmd:r()}.{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:elecdisp} calculates six disproportionality indices for individual elections. If your data contains results from multiple elections, {cmd:elecdisp} computes these indices separately for each election:

{p 8 12 2}
- {it:Rae index}{p_end}
{p 8 12 2}
- {it:Adjusted Rae index}{p_end}
{p 8 12 2}
- {it:Loosemore-Hanby index}{p_end}
{p 8 12 2}
- {it:Adjusted Loosemore-Hanby index}{p_end}
{p 8 12 2}
- {it:Two-major-parties index}{p_end}
{p 8 12 2}
- {it:Gallagher index}{p_end}

{pstd}
If your dataset instead contains results for only one election, {cmd:elecdisp} returns the same six disproportionality indices for that single election.

{title:Options}

{phang}
{opt inputscale(percentage|proportion)} specifies the scale of your data. When working with electoral 
results data, it is common for the vote and seat shares of the contesting parties to be reported either 
as percentages or as proportions. For example, a vote share of 12% can be reported either as 12 ({it:percentage}) 
or as 0.12 ({it:proportion}). The option {cmd:inputscale} therefore allows you to specify whether your data are 
reported as {it: proportion} or {it: percentage}. It is important to note that the vote share and seat share 
variables must be reported in the same format.

{phang}
{opt outputscale(percentage|proportion)} specifies the scale of the returned disproportionality indices. Depending
on your specific interests, you may want the calculated disproportionality indices to be returned either as proportions 
({it:proportion}) or as percentages ({it:percentage}). The option {cmd:outputscale} therefore allows you to specify the scale
in which the calculated disproportionality indices are returned.

{phang}
{opt noprint} suppresses the displayed results. The results remain available in {cmd:r()}.

{title:Remarks}

{pstd}
It is important to note that your dataset needs to have a certain structure in order for the disproportionality indices to be calculated correctly.

{pstd}
Each row in the dataset represents a single party. The dataset must contain the following variables:

{p 8 12 2}
- {it:vote_share} defines the variable in your dataset containing the share of the vote obtained by each party.{p_end}
{p 8 12 2}
- {it:seat_share} defines the variable containing the corresponding share of the seats obtained by each party.{p_end}
{p 8 12 2}
- {it:election_id} identifies the election to which the vote and seat shares correspond, thereby grouping all party observations by election.{p_end}

{pstd}
The figure below illustrates the structure of the dataset that is required.

{pstd}
In this illustration, vote shares and seat shares are expressed as proportions.

    {c TLC}{hline 46}{c TRC}
    {c |}    vote_share   seat_share   election_id     {c |}
    {c LT}{hline 46}{c RT}
    {c |}      0.55         0.60        Election 1     {c |}
    {c |}      0.45         0.40        Election 1     {c |}
    {c |}      0.20         0.10        Election 2     {c |}
    {c |}      0.30         0.20        Election 2     {c |}
    {c |}      0.50         0.70        Election 2     {c |}
    {c BLC}{hline 46}{c BRC}

{title:Examples}

{phang2}
. elecdisp vote_share seat_share election_id, inputscale(percentage) outputscale(percentage)

{phang2}
. elecdisp vote_share seat_share election_id, inputscale(percentage) outputscale(proportion)

{phang2}
. elecdisp vote_share seat_share election_id, inputscale(proportion) outputscale(proportion)

{phang2}
. elecdisp vote_share seat_share election_id, inputscale(proportion) outputscale(percentage)

{title:Stored results}

{pstd}
{cmd:elecdisp} stores the following in {cmd:r()}:{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2:Macros}{p_end}
{synopt:{cmd:r(output_scale)}}specified scale of the output.{p_end}
{synopt:{cmd:r(internal_scale)}}internal scale used by {cmd:elecdisp} for all calculations.{p_end}
{synopt:{cmd:r(input_scale)}}specified scale of the input data.{p_end}
{synopt:{cmd:r(elections)}}list of election identifiers included in the calculations.{p_end}

{p2col 5 24 28 2:Matrices}{p_end}
{synopt:{cmd:r(results_ls)}}matrix containing the calculated Gallagher index for each election in your dataset.{p_end}
{synopt:{cmd:r(results_tmp)}}matrix containing the calculated Two-Major-Parties index for each election in your dataset.{p_end}
{synopt:{cmd:r(results_adj_lh)}}matrix containing the calculated Adjusted Loosemore-Hanby index for each election in your dataset.{p_end}
{synopt:{cmd:r(results_lh)}}matrix containing the calculated Loosemore-Hanby index for each election in your dataset.{p_end}
{synopt:{cmd:r(results_adj_rae)}}matrix containing the calculated Adjusted Rae index for each election in your dataset.{p_end}
{synopt:{cmd:r(results_rae)}}matrix containing the calculated Rae index for each election in your dataset.{p_end}
{synopt:{cmd:r(results)}}matrix containing the number of parties for each election in your dataset.{p_end}
{p2colreset}{...}

{title:References}

{pstd}
All formulas used to calculate the disproportionality indices are based on the original works in which the indices were developed. For further details about a specific formula, please consult the corresponding original work.

{phang}
Douglas W. Rae. (1971). The Political Consequences of Electoral Laws. Yale University Press{p_end}

{phang}
Lijphart, Arend. (1985). The Field of Electoral Systems Research: A Critical Survey. Electoral Studies, 4 (1), 3–14. https://doi.org/10.1016/0261-3794(85)90028-9{p_end}

{phang}
Loosemore, John and Hanby, Victor, J. (1971). The Theoretical Limits of Maximum Distortion: Some Analytic Expressions for Electoral Systems. British Journal of Political Science, 1 (4), 467-477. https://doi.org/10.1017/S000712340000925X{p_end}

{phang}
Gallagher, Michael. (1991). Proportionality, disproportionality and electoral systems. Electoral Studies, 10 (1), 33-51. https://doi.org/10.1016/0261-3794(91)90004-C{p_end}

{title:Author Information}
{pstd}
Oscar Martínez Coello{p_end}
{pstd}
Universität Mannheim, Germany{p_end}
{pstd}
oscarmtc@outlook.de{p_end}
