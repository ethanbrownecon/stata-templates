*******************************************************************************
*                                                                             *
*   STATA SNIPPETS: TABLES AND FIGURES FOR RESEARCH WRITING                   *
*                                                                             *
*   Purpose:   Master copy of reusable code blocks. Copy a block into a       *
*              project do file, replace every XXXX, and run.                  *
*   Updated:   (add date)                                                     *
*                                                                             *
*   How to use                                                                *
*     1. Paste the SETUP block at the top of each project do file.            *
*     2. Paste only the blocks you need below it.                             *
*     3. Search the pasted code for XXXX. Each one is a placeholder.          *
*     4. When you improve a block in a project, copy the improvement back     *
*        here so this file stays the master copy.                             *
*                                                                             *
*   Notes                                                                     *
*     This file was written without running it in Stata, so test each block   *
*     once before relying on it (the test file does this on sample data).     *
*     Tables are saved as LaTeX with a numbered caption and a label. Your     *
*     LaTeX file needs \usepackage{booktabs}. LaTeX numbers the captions      *
*     itself (Table 1, Table 2) and you cite them with \ref{tab:summary}.     *
*     Figures are saved as JPG with the number and title written inside the   *
*     image. Numbers advance automatically through the globals fignum and     *
*     tabnum, which are set in the SETUP block.                               *
*     If a table fails to compile, delete its fragment, prehead and postfoot  *
*     lines and use title() and addnotes() instead.                           *
*                                                                             *
*******************************************************************************




//    _____   ______   _______   _    _   _____
//   / ____| |  ____| |__   __| | |  | | |  __ \
//  | (___   | |__       | |    | |  | | | |__) |
//   \___ \  |  __|      | |    | |  | | |  ___/
//   ____) | | |____     | |    | |__| | | |
//  |_____/  |______|    |_|     \____/  |_|

*******************************************************************************
* BLOCK 1: SETUP (paste at the top of every project do file)
*******************************************************************************

* Project:  XXXX
* Author:   XXXX
* Date:     XXXX
* Inputs:   XXXX
* Outputs:  XXXX

clear all
set more off
set seed 12345                    // only matters if anything is random

* The ONLY line a reader must edit: the full path to the project folder.
* Do not end the path with a slash.
global route "XXXX PUT PROJECT FOLDER PATH HERE"

* Create output folders if they do not already exist
capture mkdir "${route}/output"
capture mkdir "${route}/output/tables"
capture mkdir "${route}/output/figures"
capture mkdir "${route}/logs"

* Log file
capture log close
log using "${route}/logs/XXXX.log", replace text

* Required packages
capture which esttab
if _rc ssc install estout, replace
capture which grstyle
if _rc ssc install grstyle, replace
capture which palettes
if _rc ssc install palettes, replace
capture which colrspace
if _rc ssc install colrspace, replace
capture which coefplot
if _rc ssc install coefplot, replace
capture which ftools
if _rc ssc install ftools, replace
capture which reghdfe
if _rc ssc install reghdfe, replace

* Table and figure counters (used in file names and figure captions)
global tabnum = 1
global fignum = 1

* Standard table options, written once so every table matches
global tabopts "booktabs label b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)"

* Significance note printed under every regression table
global starnote "\sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)."

* Standard figure export options (JPG, high resolution)
global figopts "as(jpg) quality(100) width(2400) replace"

* Standard graph style, applied to every figure that follows
grstyle clear
grstyle init
grstyle set plain, horizontal
grstyle set legend 6, nobox
grstyle set color mono

* Load data
use "${route}/data/XXXX.dta", clear


*******************************************************************************
* BLOCK 2: QUICK DATA CHECKS
*******************************************************************************

describe
summarize
misstable summarize
duplicates report XXXX            // XXXX = the id variable(s) that should be unique





//   _______              ____    _        ______    _____
//  |__   __|     /\     |  _ \  | |      |  ____|  / ____|
//     | |       /  \    | |_) | | |      | |__    | (___
//     | |      / /\ \   |  _ <  | |      |  __|    \___ \
//     | |     / ____ \  | |_) | | |____  | |____   ____) |
//     |_|    /_/    \_\ |____/  |______| |______| |_____/
//
//
*******************************************************************************
* BLOCK 3: SUMMARY STATISTICS TABLE
*******************************************************************************

* The number in l*{5}{c} must equal the number of statistics in cells().
* Title and notes below are placeholders. Edit the text, keep the LaTeX.

estpost summarize XXXX1 XXXX2 XXXX3

esttab using "${route}/output/tables/Table${tabnum}_summary.tex", replace ///
    fragment booktabs label nonotes ///
    cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2)) count(fmt(0))") ///
    collabels("Mean" "SD" "Min" "Max" "N") ///
    nomtitles nonumbers noobs ///
    prehead("\begin{table}[htbp]\centering" ///
            "\caption{XXXX Summary Statistics\label{tab:summary}}" ///
            "\begin{tabular}{l*{5}{c}}" ///
            "\toprule") ///
    prefoot("") ///
    postfoot("\bottomrule" ///
             "\end{tabular}" ///
             "\par\vspace{4pt}" ///
             "{\footnotesize \textit{Notes:} XXXX describe the sample and data source.\par}" ///
             "\end{table}")

global tabnum = ${tabnum} + 1


*******************************************************************************
* BLOCK 4: REGRESSION TABLE (several specifications side by side)
*******************************************************************************

* Caption and number sit above the table. Notes sit below, centered.
* To put the caption under the table instead, move the \caption line from
* prehead into postfoot, after "\end{tabular}".

eststo clear

eststo m1: regress XXXX_y XXXX_x, vce(robust)
eststo m2: regress XXXX_y XXXX_x XXXX_control1 XXXX_control2, vce(robust)
eststo m3: regress XXXX_y XXXX_x XXXX_control1 XXXX_control2 i.XXXX_factor, vce(robust)

esttab m1 m2 m3 using "${route}/output/tables/Table${tabnum}_regression.tex", replace ///
    fragment ${tabopts} nonotes ///
    mtitles("Baseline" "Controls" "Full") ///
    indicate("Factor fixed effects = *.XXXX_factor") ///
    stats(N r2, fmt(%9.0fc %9.3f) labels("Observations" "R-squared")) ///
    prehead("\begin{table}[htbp]\centering" ///
            "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" ///
            "\caption{XXXX Regression Results\label{tab:regression}}" ///
            "\begin{tabular}{l*{@M}{c}}" ///
            "\toprule") ///
    postfoot("\bottomrule" ///
             "\end{tabular}" ///
             "\par\vspace{4pt}" ///
             "{\footnotesize \textit{Notes:} Robust standard errors in parentheses. ${starnote}\par}" ///
             "\end{table}")

global tabnum = ${tabnum} + 1





//    _____   _____               _____    _    _    _____
//   / ____| |  __ \      /\     |  __ \  | |  | |  / ____|
//  | |  __  | |__) |    /  \    | |__) | | |__| | | (___
//  | | |_ | |  _  /    / /\ \   |  ___/  |  __  |  \___ \
//  | |__| | | | \ \   / ____ \  | |      | |  | |  ____) |
//   \_____| |_|  \_\ /_/    \_\ |_|      |_|  |_| |_____/
//
//
*******************************************************************************
* BLOCK 5: COEFFICIENT PLOT
*******************************************************************************

* Every figure block follows the same pattern: caption() holds the number and
* title and sits centered under the figure, note() holds the notes. Delete
* both lines if you prefer to write captions in LaTeX instead.

coefplot (m1, label("Baseline")) (m2, label("Controls")) (m3, label("Full")), ///
    drop(_cons) xline(0) ///
    ciopts(recast(rcap)) ///
    legend(rows(1) position(6)) ///
    caption("Figure ${fignum}. XXXX Title", position(6) size(medsmall)) ///
    note("Notes: XXXX bars show 95 percent confidence intervals.", position(7) size(small))

graph export "${route}/output/figures/Figure${fignum}_XXXX_coefplot.jpg", ${figopts}
global fignum = ${fignum} + 1


*******************************************************************************
* BLOCK 6: SCATTER PLOT WITH FITTED LINE
*******************************************************************************

twoway (scatter XXXX_y XXXX_x, msize(small)) ///
       (lfit XXXX_y XXXX_x), ///
    xtitle("XXXX x label") ytitle("XXXX y label") legend(off) ///
    caption("Figure ${fignum}. XXXX Title", position(6) size(medsmall)) ///
    note("Notes: XXXX source and description.", position(7) size(small))

graph export "${route}/output/figures/Figure${fignum}_XXXX_scatter.jpg", ${figopts}
global fignum = ${fignum} + 1


*******************************************************************************
* BLOCK 7: HISTOGRAM
*******************************************************************************

histogram XXXX, fraction ///
    xtitle("XXXX label") ytitle("Fraction") ///
    caption("Figure ${fignum}. XXXX Title", position(6) size(medsmall)) ///
    note("Notes: XXXX source and description.", position(7) size(small))

graph export "${route}/output/figures/Figure${fignum}_XXXX_histogram.jpg", ${figopts}
global fignum = ${fignum} + 1


*******************************************************************************
* BLOCK 8: LINES OVER TIME, TWO GROUPS
*******************************************************************************

* Average the outcome by year and group first
preserve
    collapse (mean) XXXX_y, by(XXXX_year XXXX_group)
    reshape wide XXXX_y, i(XXXX_year) j(XXXX_group)

    twoway (line XXXX_y1 XXXX_year) ///
           (line XXXX_y0 XXXX_year), ///
        xtitle("Year") ytitle("XXXX y label") ///
        legend(order(1 "Group 1" 2 "Group 0") rows(1) position(6)) ///
        caption("Figure ${fignum}. XXXX Title", position(6) size(medsmall)) ///
        note("Notes: XXXX source and description.", position(7) size(small))

    graph export "${route}/output/figures/Figure${fignum}_XXXX_timeseries.jpg", ${figopts}
restore
global fignum = ${fignum} + 1


*******************************************************************************
* BLOCK 9: BAR CHART OF MEANS BY GROUP
*******************************************************************************

graph bar (mean) XXXX_y, over(XXXX_group) ///
    ytitle("Mean of XXXX y label") ///
    blabel(bar, format(%9.2f)) ///
    caption("Figure ${fignum}. XXXX Title", position(6) size(medsmall)) ///
    note("Notes: XXXX source and description.", position(7) size(small))

graph export "${route}/output/figures/Figure${fignum}_XXXX_bar.jpg", ${figopts}
global fignum = ${fignum} + 1



//    _____   _         ____     _____   _____   _   _    _____
//   / ____| | |       / __ \   / ____| |_   _| | \ | |  / ____|
//  | |      | |      | |  | | | (___     | |   |  \| | | |  __
//  | |      | |      | |  | |  \___ \    | |   | . ` | | | |_ |
//  | |____  | |____  | |__| |  ____) |  _| |_  | |\  | | |__| |
//   \_____| |______|  \____/  |_____/  |_____| |_| \_|  \_____|
*******************************************************************************
* BLOCK 10: CLOSE (paste at the bottom of every project do file)
*******************************************************************************

log close
