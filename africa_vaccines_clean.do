

   * ******************************************************************** *
   * ******************************************************************** *
   *                                                                      *
   *               Tracking vaccination in SSA	                          *
   *                                                                      *
   * ******************************************************************** *
   * ******************************************************************** *

       /*
       ** PURPOSE:      Create charts showing vaccination rollout in SSA

       ** OUTLINE:      PART 0: Global and install packages
                        PART 1: Prepare data from GitHub repositories
                        PART 2: Create maps
                        PART 3: Create charts


       ** IDS VAR:      iso3

       ** WRITEN BY:    Alexis Rivera Ballesteros

       ** Last date modified:  15 June 2021
       */


   * ******************************************************************** *
   *
   *       PART 0:  SETTING GLOBAL AND INSTALL PACKAGES NEEDED
   *
   * ******************************************************************** *
   
   
   global projectfolder = "" // define global path
   
   ssc install "kountry"
   
   
   
	
   * ******************************************************************** *
   *
   *       PART 1:  PREPARE DATA FROM GITHUB REPOSITORIES
   *
   * ******************************************************************** *	

   
********************************************************   
***** Merge doses delivered with doses administered
********************************************************

	import delimited using "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/vaccinations.csv", clear
	gen day = substr(date, 9, 2)
	gen month = substr(date, 6, 2)
	gen year = substr(date, 1, 4)
	
	destring day, replace
	destring month, replace
	destring year, replace
	
	gen date2 = mdy(month, day, year)
	
	gen week = week(date2)
	
	gsort iso_code date2
	
	gen latest = 1 if week != week[_n+1]
	
	keep if latest==1
			
	kountry iso_code, from(iso3c) geo(un)

	keep if GEO == "Africa"
	
	rename iso_code iso3
	
	keep iso3 week total_vaccinations people_vaccinated people_fully_vaccinated
	
	save "$projectfolder/data/vaccination_owid.dta", replace
	
	gen latest = 1 if iso3 != iso3[_n+1]

	keep if latest == 1

	drop latest week
	
	keep iso3 total_vaccinations
	
	rename total_vaccinations cumu_doses_administered
	
	save "$projectfolder/data/vaccination_owid_latest.dta", replace
	
	
**********************************************************************
**** Merge delirveried doses data with administered doses from OWID
**********************************************************************

	import delimited using "https://raw.githubusercontent.com/alexis-ribal/covid19_vaccination_africa/main/data/vaccination%20in%20Africa%20-%20MASTER%20PANEL.csv", clear
		
	destring doses_received delivery_date cumulative_doses pop cumulative_doses_p1000 covax_first_allocation, replace ignore(",")
	
	
	merge 1:1 iso3 week using "$projectfolder/data/vaccination_owid.dta"
	
	drop if _merge==2
	
	drop _merge
	
	merge m:1 iso3 using "$projectfolder/data/vaccination_owid_latest.dta", keepusing(cumu_doses_administered)
	
	drop if _merge ==2
	
	drop _merge
	
	gen doses_admin_pct = (cumu_doses_administered/cumulative_doses)*100
	
	format source %10s
	
	tab country if doses_admin_pct > 100 & doses_admin_pct != . & week == 62
		
	save "$projectfolder/data/vaccination_master.dta", replace
	
	export delimited using "$projectfolder/data/vaccination_master.csv", replace
	
	
	keep if week == 2
	
	keep country
	
	export delimited using "$projectfolder/data/country_list.csv", replace 

	
	
	
   * ******************************************************************** *
   *
   *       PART 2:  CREATE MAPS
   *
   * ******************************************************************** *		
	
	
		
******************************************		
*****  Map of delivered doses
***********************************


	use "/$projectfolder/data/vaccination_master.dta", clear


	
	keep if week == 23    // modify with today's week of the year
	
	drop source
	
	merge 1:1 iso3 using "$projectfolder/data/world.dta"

	drop _merge
	
	rename iso3 iso3c
	
	kountry iso3c, from(iso3c) geo(un)

	keep if GEO=="Africa"
	
	

	gen africa_map = 1 if cumulative_doses_p1000 > 50 & cumulative_doses_p1000 !=.
	replace africa_map = 2 if cumulative_doses_p1000 > 25 & cumulative_doses_p1000 <= 50
	replace africa_map = 3 if cumulative_doses_p1000 > 0 & cumulative_doses_p1000 <= 25
	replace africa_map = 4 if cumulative_doses_p1000 == 0 | cumulative_doses_p1000 == .
	replace africa_map = 5 if iso3 == "MAR" | iso3 == "ESH" | iso3 == "DZA" | iso3 == "TUN" | iso3 == "LBY" | iso3 == "EGY" | iso3 == "DJI"


	label define map 1 "More than 50" 2 "(25-50]" 3 "(1-25]" 4 "0 or no data" 5 "North Africa"

	label values africa_map map
	
	sum cumulative_doses, d
	di r(sum)

	spmap africa_map using "$projectfolder/data/worldcoord.dta", ///
	id(id) fcolor ("19 60 85" "56 111 164" "132 210 246" "sand*0.2" "221 213 208") clmethod(unique) legend(size(medium)) title("Sub-Saharan African countries have received very few COVID-19 doses" "Most of them do not have enough doses to cover even 5% of their population", size(small) position(11) span) ///
	note("{bf:Source}: @Econ4Transform with data obtained from gavi.org, UN press releases and news agencies." "{bf: Note}: lack of data can result in underreporting. Updated on $S_DATE {bf:CC BY}", size(vsmall) span)	///
	legend(size(small) title("Doses delivered" "per 1K people", position(11) size(small)))
	
	graph export "$projectfolder/charts/totaldosesper1k_latest.png", replace



******************************
**** Get maps by week
******************************

	use "$projectfolder/data/vaccination_master.dta", clear

	drop source
	
	local week 10 15 20 23
	
	foreach w of local week{

	preserve
	
	keep if week == `w'
	
	
	merge 1:1 iso3 using "$projectfolder/data/world.dta"

	drop _merge
	
	rename iso3 iso3c
	
	kountry iso3c, from(iso3c) geo(un)

	keep if GEO=="Africa"
	
	

	gen africa_map = 1 if cumulative_doses_p1000 > 50 & cumulative_doses_p1000 !=.
	replace africa_map = 2 if cumulative_doses_p1000 > 25 & cumulative_doses_p1000 <= 50
	replace africa_map = 3 if cumulative_doses_p1000 > 0 & cumulative_doses_p1000 <= 25
	replace africa_map = 4 if cumulative_doses_p1000 == 0 | cumulative_doses_p1000 == .
	replace africa_map = 5 if iso3 == "MAR" | iso3 == "ESH" | iso3 == "DZA" | iso3 == "TUN" | iso3 == "LBY" | iso3 == "EGY" | iso3 == "DJI"


	label define map 1 "More than 50" 2 "(25-50]" 3 "(1-25]" 4 "0 or no data" 5 "North Africa"

	label values africa_map map
	
	sum cumulative_doses, d
	di r(sum)

	spmap africa_map using "$projectfolder/data/worldcoord.dta", ///
	id(id) fcolor ("19 60 85" "56 111 164" "132 210 246" "sand*0.2" "221 213 208") clmethod(unique) legend(size(medium)) title("Progress of COVID-19 vaccine doses deliveries over time" "Week `w' of the year", size(medium) position(11) span) ///
	note("{bf:Source}: @Econ4Transform with data obtained from gavi.org, UN press releases and news agencies." "{bf: Note}: lack of data can result in underreporting. Updated on $S_DATE {bf:CC BY}", size(vsmall) span)	///
	legend(size(small) title("Doses delivered" "per 1K people", position(11) size(small)))
	
	graph export "$projectfolder/maps/totaldosesper1k_week`w'.png", replace
	
	restore
	}


		
***********************************	
***** Map of administered doses
***********************************
	

	use "$projectfolder/data/vaccination_master.dta", clear

	keep if week == 23
	
	drop source
	
	merge 1:1 iso3 using "$projectfolder/data/world.dta"

	drop _merge
	
	rename iso3 iso3c
	
	kountry iso3c, from(iso3c) geo(un)

	keep if GEO=="Africa"
	
	gen cumu_doses_administered_p1000 = cumu_doses_administered/(pop/1000)

	gen africa_map = 1 if cumu_doses_administered_p1000 > 50 & cumu_doses_administered_p1000 !=.
	replace africa_map = 2 if cumu_doses_administered_p1000 > 25 & cumu_doses_administered_p1000 <= 50
	replace africa_map = 3 if cumu_doses_administered_p1000 > 0 & cumu_doses_administered_p1000 <= 25
	replace africa_map = 4 if cumu_doses_administered_p1000 == 0 | cumu_doses_administered_p1000 == .
	replace africa_map = 5 if iso3 == "MAR" | iso3 == "ESH" | iso3 == "DZA" | iso3 == "TUN" | iso3 == "LBY" | iso3 == "EGY" | iso3 == "DJI"


	label define map 1 "More than 50" 2 "(25-50]" 3 "(1-25]" 4 "0 or no data" 5 "North Africa"

	label values africa_map map
	
	sum cumu_doses_administered, d
	di r(sum)

	spmap africa_map using "$projectfolder/data/worldcoord.dta", ///
	id(id) fcolor ("19 60 85" "56 111 164" "132 210 246" "sand*0.2" "221 213 208") clmethod(unique) legend(size(medium)) title("COVID-19 vaccination rollout has been slow in sub-Saharan Africa" "Most countries have inoculated less than 3% of their population.", size(small) position(11) span) ///
	note("{bf:Source}: @Econ4Transform with data from Our World in Data." "{bf: Note}: lack of data can result in underreporting. Updated on $S_DATE {bf:CC BY}", size(vsmall) span)	///
	legend(size(small) title("Doses adminstered" "per 1K people", position(11) size(small)))
	
	graph export "$projectfolder/maps/totaladmindosesper1k_latest.png", replace
	
	

	
	
   * ******************************************************************** *
   *
   *       PART 3:  CREATE CHARTS
   *
   * ******************************************************************** *		

   
   
   
*******************************************************   
****** Linechart of deliveries and administered doses
************************************************************

	use "$projectfolder/data/vaccination_master.dta", clear
	
	bysort iso3 : replace total_vaccinations = total_vaccinations[_n-1] if missing(total_vaccinations)
	
	collapse (sum) cumulative_doses total_vaccinations, by(week)
		
	tw line cumulative_doses week if week <= 23, lw(1) lcolor("33 69 91") || ///
	line total_vaccinations week if week <= 23, lw(1) lcolor("222 110 75") ///
	ylab(5e6 "5" 10e6 "10" 15e6 "15" 20e6 "20" 25e6 "25" 30e6 "30") xlab(1(1)23) ///
	legend(cols(2) order(1 "Available COVID-19 doses" 2 "Doses administered" )) ///
	graphregion(color(white)) bgcolor(white) xtitle("Week of the year") ytitle("Million doses") ///
	note("{bf:Source}: @Econ4Transform using data from official announcements, news agencies articles and data from Our World in Data." ///
	"{bf: Note}: lack of data can result in underreporting. Updated on $S_DATE {bf:CC BY}", size(vsmall) span) ///
	title("The COVID-19 vaccination rollout has been slow in sub-Saharan Africa:" "available vs administered doses in the region" " ", position(11) size(medium) span)
	
	graph export "$projectfolder/charts/vaccinations_linetrend.png", replace
	
	
	
	

*******************************************************	
***** Doses in SSA compared to other countries
*******************************************************

	import delimited using "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/vaccinations.csv", clear
	gen day = substr(date, 9, 2)
	gen month = substr(date, 6, 2)
	gen year = substr(date, 1, 4)
	
	destring day, replace
	destring month, replace
	destring year, replace
	
	gen date2 = mdy(month, day, year)
	
	gen week = week(date2)
	
	gsort iso_code date2
	
	gen latest = 1 if week != week[_n+1] & iso_code != iso_code[_n+1]
	
	kountry iso_code, from(iso3c) geo(meb)
	
	format date2 %d


	
	tw line total_vaccinations_per_hundred date2 if iso_code == "OWID_AFR", lcolor(red) lw(1) || ///
	line total_vaccinations_per_hundred date2 if iso_code == "OWID_NAM", lcolor(navy) || ///
	line total_vaccinations_per_hundred date2 if iso_code == "OWID_EUR", lcolor(blue) || ///
	line total_vaccinations_per_hundred date2 if iso_code == "OWID_SAM", lcolor(green) || ///
	line total_vaccinations_per_hundred date2 if iso_code == "OWID_ASI", lcolor(orange) || ///
	scatter total_vaccinations_per_hundred date2 if iso_code == "OWID_AFR" & latest == 1, mlab(location) mcolor(red) mlabcolor(red) || ///
	scatter total_vaccinations_per_hundred date2 if iso_code == "OWID_NAM" & latest == 1, mlab(location) mcolor(navy) mlabcolor(navy) || ///
	scatter total_vaccinations_per_hundred date2 if iso_code == "OWID_EUR" & latest == 1, mlab(location) mcolor(blue) mlabcolor(blue) || ///
	scatter total_vaccinations_per_hundred date2 if iso_code == "OWID_SAM" & latest == 1, mlab(location) mcolor(green) mlabcolor(green) || ///
	scatter total_vaccinations_per_hundred date2 if iso_code == "OWID_ASI" & latest == 1, mlab(location) mcolor(orange) mlabcolor(orange) ///
	graphregion(color(white)) bgcolor(white)  legend(off) ///
	tscale(r(22250 22500)) tlab(,labsize(small) angle(45))  ///
	ytitle("Administered doses per 100 people") ttitle("") title("Administered doses of COVID-19 vaccine per hundred people by region", size(medium)) ///
	note("{bf:Note}: Africa includes North and sub-Saharan Africa." "{bf:Source}: @Econ4Transform based on Our World in Data.  Accessed on $S_DATE {bf:CC BY}", size(vsmall) span)
	
	graph export "$projectfolder/charts/admin_p100_regions.png", replace		
	
	
**********************************************************************	
**** Share of cumulative vaccines in SSA of total world vaccines	
**********************************************************************

	import delimited using "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/vaccinations.csv", clear
	
	gen day = substr(date, 9, 2)
	gen month = substr(date, 6, 2)
	gen year = substr(date, 1, 4)
	
	destring day, replace
	destring month, replace
	destring year, replace
	
	gen date2 = mdy(month, day, year)
	
	gen week = week(date2)
	
	gsort iso_code date2
	
	gen latest = 1 if week != week[_n+1] & iso_code != iso_code[_n+1]
	
	kountry iso_code, from(iso3c) geo(meb)
	
	format date2 %d
	
	keep iso_code total_vaccinations date2
	
	keep if iso_code == "OWID_AFR" | iso_code == "OWID_WRL"
	
	reshape wide total_vaccinations, i(date2) j(iso_code) string

	gen africa_pct = (total_vaccinationsOWID_AFR/total_vaccinationsOWID_WRL)*100
	
	tw line africa_pct date2, lw(1) title("Africa's share of world's total COVID-19 vaccine administered doses", size(medium)) ///
	graphregion(color(white)) bgcolor(white)  legend(off) ttitle("") ytitle(%) tlab(,labsize(small) angle(45)) ///
	note("{bf:Source}: @Econ4Transform based on Our World in Data.  Accessed on $S_DATE {bf:CC BY}", size(vsmall) span)
	
	graph export "$projectfolder/charts/ssa_share_world.png", replace
	
	

	
*******************************************************	
**** Unequal vaccine distribution bar chart	
*******************************************************
	
	import delimited using "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/vaccinations.csv", clear
	gen day = substr(date, 9, 2)
	gen month = substr(date, 6, 2)
	gen year = substr(date, 1, 4)
	
	destring day, replace
	destring month, replace
	destring year, replace
	
	gen date2 = mdy(month, day, year)
	
	gen week = week(date2)
	
	gsort iso_code date2
	
	gen latest = 1 if week != week[_n+1]
	
	keep if latest==1
	
	kountry iso_code, from(iso3c) geo(meb)
	
	format date2 %d
	
	encode iso_code, gen(ccode)
	replace ccode = 500 if GEO == "Africa"
		
	gsort ccode week
	
	gen select = ccode == 500 | iso_code == "RUS" | iso_code == "TUR" | iso_code == "ITA" | iso_code == "FRA" | iso_code == "DEU" | iso_code == "BRA" | iso_code == "GBR" | iso_code == "IND" | iso_code == "USA" | iso_code == "CHN"
	
	drop if strpos(iso_code , "OWID")!=0
	
	bysort week: egen world_admin_doses = sum(total_vaccinations)
	
	keep if select == 1
		
	gen pop = 1106958900 if ccode == 500
	replace pop = 144406261 if iso_code == "RUS"
	replace pop = 83429615 if iso_code == "TUR"
	replace pop = 60302093 if iso_code == "ITA"
	replace pop = 67055854 if iso_code == "FRA"
	replace pop = 83092962 if iso_code == "DEU"
	replace pop = 211049527 if iso_code == "BRA"
	replace pop = 66836327 if iso_code == "GBR"
	replace pop = 1366417750 if iso_code == "IND"
	replace pop = 328239523 if iso_code == "USA"
	replace pop = 1397715000 if iso_code == "CHN"
	
	gen pop_pct = 1106958900/7673656870 if ccode == 500
	replace pop_pct = 144406261/7673656870 if iso_code == "RUS"
	replace pop_pct = 83429615/7673656870 if iso_code == "TUR"
	replace pop_pct = 60302093/7673656870 if iso_code == "ITA"
	replace pop_pct = 67055854/7673656870 if iso_code == "FRA"
	replace pop_pct = 83092962/7673656870 if iso_code == "DEU"
	replace pop_pct = 211049527/7673656870 if iso_code == "BRA"
	replace pop_pct = 66836327/7673656870 if iso_code == "GBR"
	replace pop_pct = 1366417750/7673656870 if iso_code == "IND"
	replace pop_pct = 328239523/7673656870 if iso_code == "USA"
	replace pop_pct = 1397715000/7673656870 if iso_code == "CHN"
	
	collapse (sum) total_vaccinations (first) pop pop_pct location iso_code world_admin_doses, by(week ccode)

	replace pop_pct = pop_pct*100
	
	gen admin_doses_world_pct = (total_vaccinations/world_admin_doses)*100
	
	replace location = "Sub-Saharan Africa" if ccode == 500
	
	gsort ccode week
	
	forval i = 16/23 {
	
	
	graph hbar pop_pct admin_doses_world_pct if week == `i', over(location, sort(admin_doses_world_pct) descending) blabel(total, format(%12.1f) size(vsmall)) ///
	bar(1, color(33 69 91)) bar(2, color(222 110 75)) ///
	legend(cols(1) order(1 "Share of world's population (2019)" 2 "Share of total administered doses")) ylab(0(10)40) graphregion(color(white)) bgcolor(white) ///
	title("Week `i' of the year", span pos(11)) ///
	note("{bf:Source}: @Econ4Transform based on Our World in Data and World Bank data.  Accessed on $S_DATE {bf:CC BY}", size(vsmall) span)
	
	graph export "$projectfolder/charts/vaccine_inequity_`i'.png", replace
	
	
	}
	

	
***** end of do-file	
	
	
	
	
	
