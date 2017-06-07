// set your working directory here
cd .

// macros
local quartersPerYear 	= 4
local year_min_data 	= 1994
local year_min_graph 	= 2000
local year_max_graph 	= 2015
local year_law 			= 2012

**********************************************************

// download raw data
set more off
copy http://www.rockinst.org/government_finance/data/StateGovQTax_State_2016Q2_11.29.2016.xlsx revenue.xlsx, replace
import excel using revenue.xlsx, firstrow clear sheet(PIT)

// name raw variables
rename Q* Q*____1
rename ? ?1
rename ?? ??1
rename *1 var#, renumber
rename Pers state

// identify year and quarter
forvalues i = 1/`=c(k)-1' {
	local y = floor(`i'/`quartersPerYear') + `year_min_data'
	local q = mod(`i',`quartersPerYear') 
	if `q' {
		rename var`i' pit`y'q`q'
	}
	else {
		rename var`i' pit`y'q`quartersPerYear'
	}
}

// reshape by year and quarter
unab stubs: pit*
forvalues q = 1/`quartersPerYear' {
	local stubs: subinstr local stubs "q`q'" "q", all
}
local stubs: list uniq stubs	
reshape long `stubs', i(state) j(q)
rename pit*q pit*
reshape long pit, i(state q) j(y)

// get annual revenue
destring pit, replace force
collapse (sum) pit, by(state y)

// scale relative to law passage
gen pit`year_law' = pit if (y == `year_law')
bysort state: egen norm = mean(pit`year_law')
replace pit = pit / norm

// restrict time range
sort state y
keep if inrange(y, 2000, 2015)

// plot graph
#delimit ;
twoway
	(line pit y if state == "Kansas", 		lcolor(red))
	(line pit y if state == "Iowa", 		lcolor(black) lpattern(dash_dot))
	(line pit y if state == "Missouri", 	lcolor(black) lpattern(shortdash))
	(line pit y if state == "Arkansas", 	lcolor(black) lpattern(longdash))
	,
	title("State Income Tax Revenue", lcolor(black) size(medium))
	xtitle(year)
	ytitle("personal income tax revenue" "(2012 revenue = 1)" " ")
	legend(label(1 "Kansas") label(2 "Iowa") label(3 "Missouri") label(4 "Arkansas") order(2 3 4 1) rows(2) holes(4 6) region(lcolor(white)) size(medlarge))
	xline(`year_law', lcolor(gs10) lwidth(medium))
	ylabel(0(.2)1.4)
	yscale(range(0 1.4))
	xlabel(`year_min_graph'(5)`year_max_graph')
	xtick(`year_min_graph'(1)`year_max_graph', nolabel)
	graphregion(color(white)) bgcolor(white) 
;
graph export "kansas.png", replace ; 
#delimit cr

**********************************************************
