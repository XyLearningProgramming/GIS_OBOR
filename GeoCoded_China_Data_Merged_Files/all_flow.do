****
* Jun 6, 2019
****

capture log close
set more off
log using "all_flow", append

import delimited "all_flow_classes.csv", clear

*1 drop projects without year 526
count if year_uncertain == "TRUE"
drop if year_uncertain == "TRUE"

// * From the CGOF readme: “Deflated monetary equivalent of
// reported monetary amount in reported currency to 2014 U.S.
// dollars.”
codebook usd_defl_2014
gen usd_defl_2014_mi = usd_defl_2014/1000000
* sum by year
preserve
collapse (sum) usd_defl_2014_mi, by(year)
save "all_flow_sum_by_year",replace
tw (lfitci usd_defl_2014_mi year) /// 
	(line usd_defl_2014_mi year), ///
	xlabel(2000(1)2014) title("Chinese Official Finance by Year (2000-2014)") ///
	legend(label(2 "Linear Predictions") label(3 "Sum of Chinese Official Finance")) ///
	graphregion(color(white)) ytitle("Amount of Project Equal to 2014 USD (Million)") xtitle("Year") ///
	saving("SumByYear",replace) ysc(r(0 150000))
restore

preserve 
collapse (first) usd_defl_2014_mi, by(project_id)
count if usd_defl_2014_mi !=. & usd_defl_2014_mi!=0
restore 

save "all_flow_classes.dta", replace
// use "all_flow_sum_by_year", replace
// gen trend = _n
// gen trendsq = trend^2 
// tsset trend
// // ac usd_defl_2014_mi
// // pac usd_defl_2014_mi
// corrgram usd_defl_2014_mi
// * unit root problem
// dfuller usd_defl_2014_mi
// reg usd_defl_2014_mi trend trendsq, r
// tw line usd_defl_2014_mi year || lfitci usd_defl_2014_mi year

*2 add continent belonged 
import excel "continent list of countries.xlsx", clear firstrow
drop if recipient_iso3 == "null"
unique recipient_iso3
sort recipient_iso3
quietly by recipient_iso3:  gen dup = cond(_N==1,0,_n)
list if dup>1 | dup == 1
// * Armenia to EU
// drop if recipient_iso3 == "ARM" & CC=="AS"
// * Azerbaijan to EU
// drop if recipient_iso3 == "AZE" & CC=="AS"
// * Georgia to EU
// drop if recipient_iso3 == "GEO" & CC=="AS"
// * Kazakhstan to AS
// drop if recipient_iso3 == "KAZ" & CC=="EU"
// * Russia to EU
// drop if recipient_iso3 == "RUS" & CC=="AS"
// * TUR & UMI 
drop if dup>1
replace CC = "Ambiguous" if dup == 1
save "continent_recipient",replace 	
use "all_flow_classes.dta", clear
merge m:m recipient_iso3 using "continent_recipient.dta"
drop if _merge == 2
* exceptions
replace CC = "AS" if recipient_iso3 == "VNM; MMR; KHM; "
replace CC = "AF" if recipient_iso3 == "BRN; Africa, regional; "
replace CC = "AF" if recipient_iso3 == "Africa, regional; ETH; MLI; GHA"
replace CC = "AF" if recipient_iso3 == "Africa, regional"


* create dataset for ArcGIS
* average usd_defl_2014_mi if multiple projects
bysort project_id: egen avg_usd_defl_2014_mi = mean(usd_defl_2014_mi)
bysort project_id: egen avg_usd_defl_2014 = mean(usd_defl_2014)

export excel using "all_flow_GIS.xlsx", firstrow(variables) replace
save "all_flow_GIS",replace

preserve
keep if year >= 2010 & year <= 2014
export excel using "all_flow_GIS_201014.xlsx", firstrow(variables) replace
restore


preserve
keep if year == 2012
export excel using "all_flow_GIS_2012.xlsx", firstrow(variables) replace
restore

preserve
keep if year == 2014
export excel using "all_flow_GIS_2014.xlsx", firstrow(variables) replace
restore

preserve
keep if year == 2011
export excel using "all_flow_GIS_2011.xlsx", firstrow(variables) replace
restore

drop if avg_usd_defl_2014_mi == .
export excel using "all_flow_GIS_weighted.xlsx", firstrow(variables) replace

preserve
keep if year == 2012
export excel using "all_flow_GIS_wei_2012.xlsx", firstrow(variables) replace
restore

preserve
keep if year == 2014
export excel using "all_flow_GIS_wei_2014.xlsx", firstrow(variables) replace
restore

preserve
keep if year == 2011
export excel using "all_flow_GIS_wei_2011.xlsx", firstrow(variables) replace
restore

* panel data analysis
*3 keep only one project if multiple locations
drop dup
* drop variables if projects are not country-specific for further panel data analysis
drop if _merge == 1
qui bysort project_id: gen dup = cond(_N==1,0,_n)
drop if dup>1
save "all_flow_unique_projects",replace

*Add OBOR by py
use "all_flow_unique_projects_OBOR", clear
* sum received amount by country
* mark how many is recorded a finance number
bysort recipient_iso3 year: egen with_num = count(index) if usd_defl_2014_mi!= .

* create pie chart
encode flow_class, gen(flow_cat)
bysort recipient_iso3 flow_cat: egen each_flow = sum(usd_defl_2014_mi)

preserve
collapse (count) index (mean) OBOR (first) CC (max) with_num (mean) each_flow , by(recipient_iso3 flow_cat)
bysort recipient_iso3: egen usd_defl_2014_mi = sum(each_flow)
reshape wide each_flow usd_defl_2014_mi index with_num, i(recipient_iso3) j(flow_cat)
egen usd_defl_2014_mi = rowmax(usd_defl_2014_mi*)
drop usd_defl_2014_mi1 usd_defl_2014_mi2 usd_defl_2014_mi3
export excel using "all_cnt_piechart.xlsx", firstrow(variables) replace
restore

//                          2,351         1  ODA-like
//                            575         2  OOF-like
//                            186         3  Vague (Official Finance)



preserve
keep if year == 2012
collapse (count) index (mean) OBOR (first) CC (max) with_num (mean) each_flow , by(recipient_iso3 flow_cat)
bysort recipient_iso3: egen usd_defl_2014_mi = sum(each_flow)
reshape wide each_flow usd_defl_2014_mi index with_num, i(recipient_iso3) j(flow_cat)
egen usd_defl_2014_mi = rowmax(usd_defl_2014_mi*)
drop usd_defl_2014_mi1 usd_defl_2014_mi2 usd_defl_2014_mi3
export excel using "all_cnt_piechart_2012.xlsx", firstrow(variables) replace
restore

preserve
keep if year == 2014
collapse (count) index (mean) OBOR (first) CC (max) with_num (mean) each_flow , by(recipient_iso3 flow_cat)
bysort recipient_iso3: egen usd_defl_2014_mi = sum(each_flow)
reshape wide each_flow usd_defl_2014_mi index with_num, i(recipient_iso3) j(flow_cat)
egen usd_defl_2014_mi = rowmax(usd_defl_2014_mi*)
drop usd_defl_2014_mi1 usd_defl_2014_mi2 usd_defl_2014_mi3
export excel using "all_cnt_piechart_2014.xlsx", firstrow(variables) replace
restore

* collapse by country
collapse (count) index (mean) OBOR (sum) usd_defl_2014_mi (first) CC (max) with_num, by(recipient_iso3 year)
save "all_flow_by_country",replace

* average project size
use "all_flow_by_country",clear
gen avg_scale = usd_defl_2014_mi/with_num
gen id = [_n]

* show how unbalanced
encode recipient_iso3, gen(country)
bysort country: egen time_periods = count(id)
preserve
collapse (mean) time_periods, by(country)
tab time_periods
restore

count if year == 2014
count if year == 2013
count if year == 2012
* list country which fulfills
gen num = 0
replace num = 1 if year == 2012 | year == 2014 | year == 2013 | year == 2011
preserve 
collapse (sum) num, by(country)
keep if num == 4
tab country
restore
* 67 countries that have data in 2012 & 2014
* 53 countries that have data in 12 13 14
* 47 countries that have data in 11 12 13 14

* joint control variable
import excel using "control_var_clean.xlsx", clear firstrow
save "control_var_clean.dta", replace
use "all_flow_by_country",clear
merge 1:1 recipient_iso3 year using "control_var_clean.dta"
drop if _merge == 1 | _merge==2
drop _merge

save "all_flow_by_country_merged",replace

* OBOR test
use "all_flow_by_country_merged",clear
save "all_flow_by_country_tp",replace
gen t = 0 if year == 2012
replace t = 1 if year == 2014
gen treat = 0
replace treat = 1 if OBOR == 1 & t == 1

foreach var of varlist PopulationtotalSPPOPTOTL GDPpercapitaconstant2010US Importsofgoodsandservices Exportsofgoodsandservices{
	replace `var' = "" if `var'==".."
}

destring PopulationtotalSPPOPTOTL, gen(pop)
destring GDPpercapitaconstant2010US, gen(gdppc)
destring Importsofgoodsandservices, gen(import)
destring Exportsofgoodsandservices, gen(export)
* OBOR
reg usd_defl_2014_mi OBOR i.year , r cluster(country)
outreg2 using "OBOR_var.doc", ctitle("POLS clustered(robust)") replace
reg usd_defl_2014_mi OBOR i.year pop gdppc import export, r cluster(country)
outreg2 using "OBOR_var.doc", ctitle("POLS with controls(robust)") append
reg usd_defl_2014_mi OBOR i.year i.country pop gdppc import export, r
outreg2 using "OBOR_var.doc", ctitle("OBOR with country dummies") append

reg index OBOR i.year , r cluster(country)
outreg2 using "OBOR_var_cnt.doc", ctitle("POLS clustered(robust)") replace
reg index OBOR i.year pop gdppc import export, r cluster(country)
outreg2 using "OBOR_var_cnt.doc", ctitle("POLS with controls(robust)") append
reg index OBOR i.year i.country pop gdppc import export, r
outreg2 using "OBOR_var_cnt.doc", ctitle("OBOR with country dummies") append


* two periods
* 
drop if year != 2012 & year != 2014 
xtset country year
xtreg usd_defl_2014_mi OBOR i.year, i(country) fe r
outreg2 using "TP.doc", ctitle("FE(robust)") append
* need more control variables
xtreg usd_defl_2014_mi OBOR i.year pop gdppc import export, i(country) fe r
outreg2 using "TP.doc", ctitle("FE with control(robust)") append
save "all_flow_by_country_tp",replace

* multi periods
use "all_flow_by_country_merged",clear
save "all_flow_by_country_mp",replace
drop if year != 2012 & year != 2014 & year != 2013 & year != 2011 
xtset country year
reg usd_defl_2014_mi i.OBOR i.year i.country, r
gen treat = 0
replace treat = 1 if OBOR == 1 & year == 2013
replace treat = 1 if OBOR == 1 & year == 2014

foreach var of varlist PopulationtotalSPPOPTOTL GDPpercapitaconstant2010US Importsofgoodsandservices Exportsofgoodsandservices{
	replace `var' = "" if `var'==".."
}

destring PopulationtotalSPPOPTOTL, gen(pop)
destring GDPpercapitaconstant2010US, gen(gdppc)
destring Importsofgoodsandservices, gen(import)
destring Exportsofgoodsandservices, gen(export)

keep if year==2012 | year == 2014

reg usd_defl_2014_mi i.OBOR##i.year, r cluster(country)
outreg2 using "MP.doc", ctitle("POLS") replace
reg usd_defl_2014_mi i.OBOR##i.year i.country pop gdppc import export, r cluster(country)
outreg2 using "MP.doc", ctitle("POLS with control") append
* FE
xtreg usd_defl_2014_mi i.OBOR##i.year, i(country) fe r
outreg2 using "MP.doc", ctitle("FE") append
xtreg usd_defl_2014_mi i.OBOR##i.year pop gdppc import export, i(country) fe r
outreg2 using "MP.doc", ctitle("FE with control") append


reg index i.OBOR##i.year, r cluster(country)
outreg2 using "MP.doc", ctitle("POLS") append
reg index i.OBOR##i.year i.country pop gdppc import export, r cluster(country)
outreg2 using "MP.doc", ctitle("POLS with control") append
* FE
xtreg index i.OBOR##i.year, i(country) fe r
outreg2 using "MP.doc", ctitle("FE") append
xtreg index i.OBOR##i.year pop gdppc import export, i(country) fe r
outreg2 using "MP.doc", ctitle("FE with control") append

save "all_flow_by_country_mp",replace
collapse (sum) index (mean) OBOR (mean) treat (first) CC (sum) with_num (sum) usd_defl_2014_mi , by(recipient_iso3 year)
gen inter = treat*OBOR
save "GWR11214",replace
bysort recipient_iso3 (year): gen FD = usd_defl_2014_mi - usd_defl_2014_mi[_n+1]
drop if FD==.
export excel using "GWR4.xls", firstrow(variables) replace
