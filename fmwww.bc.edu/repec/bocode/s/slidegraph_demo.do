/*==============================================================================
  slidegraph_demo.do
  Demonstration of the slidegraph package for stepped presentation builds
==============================================================================*/

// Clear environment and ensure local directory is in adopath
clear all
adopath ++ "."
adopath ++ ".."

// Load auto dataset
sysuse auto, clear

// =============================================================================
// Demonstration 1: 2-Slide Build (Domestic -> Foreign)
// =============================================================================
di as text _newline(2) "{hline 70}"
di as text "DEMONSTRATION 1: 2-Slide Build (twoway scatter, default off(0))"
di as text "{hline 70}"

// Step 1: Configure slide build
// navy (Domestic) is visible in frames 1 and 2 (pattern: 11)
// cranberry (Foreign) is hidden in frame 1 and visible in frame 2 (pattern: 01)
// off() defaults to 0 (converted automatically to %0)
slidegraph set, patterns(navy 11 cranberry 01)

// Step 2: Execute graph sequence
// Notice: twoway options like title() are placed directly in twoway after the colon
slidegraph : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy))         ///
    (scatter price mpg if foreign==1, mcolor(cranberry)),   ///
    title("Price vs MPG by Foreign Status")

// Verify graphs in memory (default stub is "sg", creating sg_1, sg_2)
graph dir sg*


// =============================================================================
// Demonstration 2: 4-Slide Scalable Build with saving(demo_build.png)
// =============================================================================
di as text _newline(2) "{hline 70}"
di as text "DEMONSTRATION 2: 4-Slide Scalable Build with Postfix Export"
di as text "{hline 70}"

// Step 1: Configure 4-frame build with 4 distinct series
//   Frame 1: Domestic points only
//   Frame 2: Domestic + Foreign points
//   Frame 3: Domestic + Foreign points + Domestic trend
//   Frame 4: Domestic + Foreign points + Domestic trend + Foreign trend
slidegraph set, patterns(navy 1111 cranberry 0111 midblue 0011 orange 0001) off(0)

// Step 2: Execute graph with custom stub and automatic PNG export via saving()
// saving(demo_build.png) automatically detects .png and calls graph export for each frame
slidegraph, stub(build4) saving(demo_build.png) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy) msymbol(circle))                       ///
    (scatter price mpg if foreign==1, mcolor(cranberry) msymbol(diamond))                 ///
    (lfit price mpg if foreign==0,    lcolor(midblue) lwidth(medthick))                   ///
    (lfit price mpg if foreign==1,    lcolor(orange) lwidth(medthick) lpattern(dash)),    ///
    title("Evolution of Price vs MPG with Fits")                                          ///
    subtitle("Demonstrating 4-frame stepped progression")                                 ///
    legend(order(1 "Domestic" 2 "Foreign" 3 "Domestic Fit" 4 "Foreign Fit") rows(1))

// Verify 4-frame graphs in memory
graph dir build4*

// Clean up demo exported PNG files (ignored by git, but clean environment)
forvalues i = 1/4 {
    capture erase "demo_build_`i'.png"
}


// =============================================================================
// Demonstration 3: Custom RGB Colors Build ("R G B")
// =============================================================================
di as text _newline(2) "{hline 70}"
di as text "DEMONSTRATION 3: Custom RGB Colors Build"
di as text "{hline 70}"

// Step 1: Configure build with custom RGB triples (in quotes)
// slidegraph detects RGB values, warns, and places opacity modifiers inside quotes
slidegraph set, patterns("230 60 60" 11 "40 120 220" 01) off(0)

// Step 2: Execute graph with RGB colors
slidegraph, stub(rgb_demo) : twoway ///
    (scatter price mpg if foreign==0, mcolor("230 60 60"))       ///
    (scatter price mpg if foreign==1, mcolor("40 120 220")),     ///
    title("Price vs MPG with Custom RGB Colors")                 ///
    legend(order(1 "Custom Red (Domestic)" 2 "Custom Blue (Foreign)"))

// Verify RGB graphs in memory
graph dir rgb_demo*


// =============================================================================
// Demonstration 4: Layered Bar Chart (graph bar)
// =============================================================================
di as text _newline(2) "{hline 70}"
di as text "DEMONSTRATION 4: Layered Bar Chart (graph bar)"
di as text "{hline 70}"

// Reveal Price in Frame 1, and add MPG comparison bar in Frame 2
slidegraph set, patterns(navy 11 cranberry 01) off(0)

slidegraph, stub(demo_bar) : graph bar (mean) price (mean) mpg, ///
    bar(1, color(navy)) bar(2, color(cranberry))                ///
    title("Average Price and MPG Comparison")                   ///
    legend(order(1 "Mean Price" 2 "Mean MPG"))

// Verify bar graphs in memory
graph dir demo_bar*


// =============================================================================
// Demonstration 5: Comparative Box Plot (graph box)
// =============================================================================
di as text _newline(2) "{hline 70}"
di as text "DEMONSTRATION 5: Comparative Box Plot (graph box)"
di as text "{hline 70}"

// Stepwise reveal of distribution metrics for Price and Weight
slidegraph set, patterns(navy 11 cranberry 01) off(0)

slidegraph, stub(demo_box) : graph box price weight,            ///
    box(1, color(navy)) box(2, color(cranberry))                ///
    title("Distribution of Price and Weight")                   ///
    legend(order(1 "Price" 2 "Weight"))

// Verify box graphs in memory
graph dir demo_box*


// =============================================================================
// Demonstration 6: Shorthand Presets & 3-State Spotlight Build
// =============================================================================
di as text _newline(2) "{hline 70}"
di as text "DEMONSTRATION 6: Shorthand Presets & 3-State Spotlight Build"
di as text "{hline 70}"

// Step 1: Spotlight preset automatically sets:
// navy: 21 (frame 1 focus, frame 2 dimmed to %20)
// cranberry: 02 (frame 1 off, frame 2 focus)
slidegraph set, colors(navy cranberry) spotlight dim(20) off(0)

// Step 2: Execute graph
slidegraph, stub(spotlight_demo) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy))         ///
    (scatter price mpg if foreign==1, mcolor(cranberry)),   ///
    title("Spotlight Progression: Domestic Focus -> Foreign Focus")

graph dir spotlight_demo*


// =============================================================================
// Demonstration 7: Full Figure + Slide Sequence + LaTeX Beamer Export
// =============================================================================
di as text _newline(2) "{hline 70}"
di as text "DEMONSTRATION 7: Full Figure + Slide Sequence + LaTeX Beamer Export"
di as text "{hline 70}"

// Step 1: Set up cumulative 3-frame build
slidegraph set, colors(navy cranberry midblue) cumulative

// Step 2: Execute with full option and PDF saving
// full generates both suffixed slide frames (paper_slide_1.pdf, ...)
// AND the unsuffixed full paper figure (paper_slide.pdf and paper_slide in memory)
slidegraph, stub(paper_slide) saving(paper_slide.pdf) full : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy))                 ///
    (scatter price mpg if foreign==1, mcolor(cranberry))           ///
    (lfit price mpg, lcolor(midblue)),                             ///
    title("Price vs MPG with Overall Trend")

// Step 3: Export LaTeX Beamer overlay snippet with custom relative path
slidegraph export using "paper_slide_overlays.tex", path("figures/slides") replace

// Display the generated .tex file content
type "paper_slide_overlays.tex"

// Clean up demo files
capture erase "paper_slide.pdf"
capture erase "paper_slide_1.pdf"
capture erase "paper_slide_2.pdf"
capture erase "paper_slide_3.pdf"
capture erase "paper_slide_overlays.tex"


di as text _newline(2) "{hline 70}"
di as text "All 7 demonstrations completed successfully!"
di as text "{hline 70}"
