** Sartor & Beamish
* Host market government corruption and the equity-based foreign entry strategies of multinational enterprises
* Replicated by Wu Tao, 30 May 2021
cd "/Users/Tao/Desktop/Sartor & Beamish"
clear
set more off
use Toyokeizai_Needs_merged_stata9
rename ksfaffiliatecode subs_id
rename editionyear year
drop if subs_id==. // 0 obs dropped
* drop if fiscalyear==.
*********************
*** Sample selection
*********************
rename ksfnationcode nation
**** Investment in 30 countries
keep if nation==413 | nation==601 | nation==225 | nation==208 | nation==410 | nation==302 | nation==105 | nation==226 | nation==210 | nation==213 | nation==108 | nation==227 | nation==123 | nation==118 | nation==220 | nation==103 | nation==113 | nation==305 | nation==207 | nation==606 | nation==117 | nation==223 | nation==224 | nation==112 | nation==551 | nation==218 | nation==106 | nation==111 | nation==205 | nation==304
rename nation nationcode
**** Investments between 2004 and 2007
tostring ksfstartdate, replace
gen fdtn_yr=substr(ksfstartdate, 1, 4)
destring ksfstartdate fdtn_yr, replace
*drop if fdtn_yr==. // unknown the date of investing
bysort subs_id: egen fdtn_yr_min=min(fdtn_yr)
replace fdtn_yr=fdtn_yr_min // some cases have multiple fdtn_yr, we use the minimum
bysort subs_id: egen fiscalyear_min=min(fiscalyear)
replace fdtn_yr=fiscalyear_min if fdtn_yr==.
drop if fdtn_yr>fiscalyear
keep if fdtn_yr>=2004 & fdtn_yr<=2007 // ambiguous: edition year or fiscal year? We used fiscal year
keep if fdtn_yr==fiscalyear // only keep obs at entry

******** Alternative selection: sample size is much larger than that of the paper
/*
gen fiscal_yr=year-1
bysort subs_id: egen fdtnyear=min(fiscal_yr)
drop if fdtnyear==.
keep if fdtnyear>=2004 & fdtnyear<=2007
keep if fdtnyear==fiscalyear
*/
********

*********************
*** Measures
*********************
**** Dependent variable
* replace missing ownership with zero
*drop if ksjownratio1==0 | ksjownratio1==. // equity share of the largest Japanese shareholder is zero or missing, dropped
forvalue i=1(1)15{
replace ksjownratio`i'=0 if ksjownratio`i'==.
}
forvalue i=1(1)5{
replace ksgownratio`i'=0 if ksgownratio`i'==.
}

*** Entry mode strategy
gen entry_str=0 if ksjownratio1>80  // WOS
replace entry_str=1 if ksjownratio1<=80 & ksgownratio1+ksgownratio2+ksgownratio3+ksgownratio4+ksgownratio5>0 // with a local partner, traditional jv

*** Partnering strategy
gen part_str=1 if ksjownratio1<=80 & ksjownratio2>0 & ksgownratio1+ksgownratio2+ksgownratio3+ksgownratio4+ksgownratio5==0 // no local partner, only Japanese partner, crossnational jv
replace part_str=0 if entry_str==1 // with a local partner, traditional jv

**** Independent variable
**** Subs-level
*** Subsidiary size
rename ksfpayrollnumber emp
gen subs_size=log(emp+1)

*** Subsidiary capitalization
merge 1:1 subs_id year using sub_capital_USdollar
drop if _merge==2
drop _merge
gen subs_cptl=log(uscptl_both+1)

**** Parent-level
rename tosyo_code1 tosyo_code
merge m:1 tosyo_code year using Nikkei1989_2010
drop if _merge==2
drop _merge

*** parent size, total sales
gen par_size=log(total_sales+1)

*** parent profitability (ROA)
gen par_roa=netincome/total_asset

*** parent leverage: the difference between total assets and total debt as a percentage of total assets to control for slack financial resources 
gen par_leve=(total_asset-total_debt)/total_asset
gen mis=missing(subs_size, subs_cptl, par_size, par_roa, par_leve)
tab entry_str if mis==0
tab part_str if mis==0
save sample1, replace

*****************************************************************
*** parent experience in the same host country
clear
use Toyokeizai_Needs_merged_stata9
rename ksfaffiliatecode subs_id
rename ksfnationcode nationcode
drop if subs_id==.
drop if fiscalyear==.
drop if fiscalyear>2007
tostring ksfstartdate, replace
gen fdtn_yr=substr(ksfstartdate, 1, 4)
destring ksfstartdate fdtn_yr, replace
* drop if fdtn_yr==.

keep subs_id fiscalyear fdtn_yr nationcode tosyo_code1 tosyo_code2 tosyo_code3 tosyo_code4 tosyo_code5 tosyo_code6 tosyo_code7 tosyo_code8 tosyo_code9 tosyo_code10 tosyo_code11 tosyo_code12 tosyo_code13 tosyo_code14 tosyo_code15 // experience both as the largest shareholder and as the non-largest shareholder 
reshape long tosyo_code, i(subs_id fiscalyear) j(rank_shrhldr) 
drop if tosyo_code==. // not listed firms
egen subs_par_id=group(tosyo_code subs_id) // subs-parent pair ID
bysort subs_par_id: egen year_m=max(fiscalyear)
bysort subs_par_id: egen year_min=min(fiscalyear)
replace fdtn_yr=year_min if fdtn_yr==.
gen n2007=2007-year_m+1  // if the firm exit before 2007. we create virtual observations until 2007
expand n2007 if fiscalyear==year_m
sort subs_par_id fiscalyear
bysort subs_par_id: gen year_virtual=year_min+_n-1
replace year_virtual=year_m if year_virtual>=year_m
drop if year_virtual<fdtn_yr
gen subs_year=year_virtual-fdtn_yr+1
bysort tosyo_code nationcode year_virtual: egen par_exp=sum(subs_year)
contract tosyo_code nationcode year_virtual par_exp
drop _freq
rename year_virtual fiscalyear

bysort tosyo_code nationcode: egen year_m=max(fiscalyear)
bysort tosyo_code nationcode: egen year_min=min(fiscalyear)
gen n2007=2007-year_m+1  // if a parent firm exit a given country before 2007, it doesn't mean the experience disappears. we create virtual observations until 2007
expand n2007 if fiscalyear==year_m // duplicate the experience of the last year
sort tosyo_code nationcode fiscalyear
bysort tosyo_code nationcode: gen year_virtual=year_min+_n-1

keep nationcode tosyo_code year_virtual par_exp
rename year_virtual fiscalyear
replace fiscalyear=fiscalyear+1  // experience at t-1
save parent_experience_host_country, replace
*******************************************************************************************

*******************************************************************************************
*** Cultural distance
clear
use hofstede_30_countries // derived from Hofstede (2001)
egen sd_pd=sd(pd)  // standard errors
egen sd_ua=sd(ua)
egen sd_ic=sd(ic)
egen sd_mf=sd(mf)
gen diff_pd=pd-pd_jp // difference 
gen diff_ua=ua-ua_jp
gen diff_ic=ic-ic_jp
gen diff_mf=mf-mf_jp
gen cul_dist=(diff_pd^2/sd_pd^2+diff_ua^2/sd_ua^2+diff_ic^2/sd_ic^2+diff_mf^2/sd_mf^2)/4 // refer to Kogut and Singh (1988)

keep nationcode nation_name cul_dist
save cul_distance_from_japan, replace
*******************************************************************************************

clear 
use sample1
*** parent exprience merged 
merge m:1 nationcode tosyo_code fiscalyear using parent_experience_host_country
drop if _merge==2
replace par_exp=0 if _merge==1
drop _merge

*** Cultural distance
merge m:1 nationcode using cul_distance_from_japan
drop if _merge==2
drop _merge

*** FDI restriction
replace nation_name="Austria" if strmatch(nation_name, "Austria*")
replace nation_name="China" if strmatch(nation_name, "China*")
replace nation_name="France" if strmatch(nation_name, "France*")
replace nation_name="Hungary" if strmatch(nation_name, "Hungary*")
replace nation_name="Italy" if strmatch(nation_name, "Italy*")
replace nation_name="Poland" if strmatch(nation_name, "Poland*")
replace nation_name="Russia" if strmatch(nation_name, "Russia*")
replace nation_name="Spain" if strmatch(nation_name, "Spain*")
replace nation_name="Czech Republic" if strmatch(nation_name, "The Czech Republic*")
replace nation_name="Netherlands" if strmatch(nation_name, "The Netherlands*")
replace nation_name="United Kingdom" if strmatch(nation_name, "The United Kingdom*")
replace nation_name="United States" if strmatch(nation_name, "The United States*")
merge m:1 nation_name fiscalyear using fdi_restriction_heritage_04_07, keepusing (fdi_restr)
drop if _merge==2
drop _merge

*** Exchange rate
gen exchange_rate=.
replace exchange_rate=1/108.15 if fiscalyear==2004
replace exchange_rate=1/110.11 if fiscalyear==2005
replace exchange_rate=1/116.31 if fiscalyear==2006
replace exchange_rate=1/117.76 if fiscalyear==2007
gen ex_rate_scale=exchange_rate*100 // Notes of Table 4: rescaled by a factor of 100. 


*** Infrastructure: not made clear. We use IMD composite index: infrastructure.
merge m:1 nation_name fiscalyear using infrastructure_04_07
drop if _merge==2
drop _merge

******* To manually check whether a third country engaged in the joint venture
/*
preserve
keep if mis==0 // 713 subsidiary
keep subs_id year nationcode ksfnationnamealph ksgstring1 ksgownratio1 ksgstring2 ksgownratio2 ksgstring3 ksgownratio3 ksgstring4 ksgownratio4 ksgstring5 ksgownratio5
export delimited using "/Users/Tao/Desktop/Sartor & Beamish/foreign_partner.csv", replace
restore
*/
merge m:1 subs_id using third_country_jv_yes, keepusing(third_country) // third_country_jv_yes，indicator manually coded
drop _merge
drop if third_country==1 // a third country engaged

*** Host market size (log)
merge m:1 nation_name fiscalyear using gdp_host_country //gdp, unit: USD
drop if _merge==2
drop _merge

*Taiwan is not in the country list of world bank: GDP from other sources
replace gdp=346.92*10^9  if nation_name=="Taiwan" & fiscalyear==2004
replace gdp=374.06*10^9  if nation_name=="Taiwan" & fiscalyear==2005
replace gdp=386.45*10^9  if nation_name=="Taiwan" & fiscalyear==2006
replace gdp=406.91*10^9  if nation_name=="Taiwan" & fiscalyear==2007
gen gdp_scaled_log=log(gdp/10^11) 
replace mis=1 if entry_str==. & part_str==.

**** Distance in religion, education, socialism
*** Difference in religion (only three years, 1995, 2005, 2015, we used 2005): diff_reli or dist_reli
merge m:1 nation_name using diff_religion_from_japan
drop if _merge==2
drop _merge

*** Difference in education (only three years, 1995, 2005, 2015, we used 2005): diff_edu
merge m:1 nation_name using diff_education_from_japan
drop if _merge==1
drop if _merge==2
drop _merge

save sample2, replace

*********************************************************************************************************
*** Difference in socialism: average between 2004-2007; average 1993-1998 in cited paper; 2004-2007 annual
*** Hong Kong is not listed as a country in the dataset. We use PRC to replace it, or just drop it. 
*** execrlc, gov1rlc: right, 1; center, 2; left, 3; 
*** Formular: diff_soci=abs(social1-social2); social1=(execrlc+gov1rlc)/2
*** Missing values replaced by means
clear
use diff_socialism_from_japan
rename year fiscalyear
**** average between 2004-2007: closest descriptive stats
keep if fiscalyear>=2004 & fiscalyear<=2007
replace execrlc=. if execrlc==-999 | execrlc==0
replace gov1rlc=. if gov1rlc==-999 | gov1rlc==0
replace execrlc=. if nation_name=="Hong Kong"
replace execrlc=. if nation_name=="Hong Kong"
gen social=(execrlc+gov1rlc)/2
gen social_japan=(japan_execrlc_04_07+japan_gov1rlc_04_07)/2
bysort nation_name: egen social_host=mean(social)
gen diff_social=abs(social_host-social_japan)
contract nation_name diff_social
egen mean_diff=mean(diff_social)
replace diff_social=mean_diff if diff_social==.
drop _freq mean_diff
save diff_socialism_from_japan_0407_average, replace
*********************************************************************************************************

*********************************************************************************************************
********Principal Component Analysis
*********************************************************************************************************
clear
set more off
use GCR_twoyears
rename nationcode nation
gen sample_country=1 if nation==413 | nation==601 | nation==225 | nation==208 | nation==410 | nation==302 | nation==105 | nation==226 | nation==210 | nation==213 | nation==108 | nation==227 | nation==123 | nation==118 | nation==220 | nation==103 | nation==113 | nation==305 | nation==207 | nation==606 | nation==117 | nation==223 | nation==224 | nation==112 | nation==551 | nation==218 | nation==106 | nation==111 | nation==205 | nation==304
rename nation nationcode

/*
preserve
keep if year==2003 & sample_country==1
pca pu la tc pd gp, comp(2)
rotate, varimax
predict pc1 pc2
factor pu la tc pd gp, factors(2)
alpha pu la tc
alpha pd gp
restore

preserve
keep if year==2004 & sample_country==1
pca pu la tc pd gp, comp(2)
rotate, varimax
predict pc1 pc2
factor pu la tc pd gp, factors(2)
alpha pu la tc
alpha pd gp
restore

preserve
keep if sample_country==1
pca pu la tc pd gp, comp(2)
rotate, varimax
predict pc1 pc2
factor pu la tc pd gp, factors(2)
alpha pu la tc
alpha pd gp
restore

preserve
keep if year==2003
pca pu la tc pd gp, comp(2)
rotate, varimax
predict pc1 pc2
factor pu la tc pd gp, pcf factors(2)
alpha pu la tc
alpha pd gp
restore
*/
preserve
keep if year==2004
pca pu la tc pd gp, comp(2)
rotate, varimax
*rotate, entropy // results are highly consistent
predict pc1 pc2
factor pu la tc pd gp, factors(2)
/* Factor loading
   -------------------------------------------------
        Variable |  Factor1   Factor2 |   Uniqueness 
    -------------+--------------------+--------------
              pu |   0.9216   -0.2164 |      0.1038  
              la |   0.9177   -0.2539 |      0.0934  
              tc |   0.9549   -0.1476 |      0.0664  
              pd |   0.7343    0.4766 |      0.2336  
              gp |   0.9406    0.2375 |      0.0589  
    -------------------------------------------------
*/
alpha pu la tc //  0.9681
alpha pd gp // 0.8955
gen petty_reverse=0-pc1
gen grand_reverse=0-pc2
gen illegal_dona=8-pd // reversely coded
drop if nationcode==.
save corruption_host_county, replace
restore
/*
preserve
pca pu la tc pd gp, comp(2)
rotate, varimax
predict pc1 pc2
factor pu la tc pd gp, factors(2)
alpha pu la tc
alpha pd gp
restore
*/
*********************************************************************************************************

clear
use sample2
*** difference in socialism: diff_social
merge m:1 nation_name using diff_socialism_from_japan_0407_average
drop if _merge==2
drop _merge
duplicates drop subs_id, force
*** Corruption: Grand, Petty, Political donation: petty_reverse grand_reverse illegal_dona
merge m:1 nationcode using corruption_host_county
drop if _merge==2
drop _merge

keep if mis==0  // 649 investments
tab entry_str 
/*
  entry_str |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        465       77.37       77.37
          1 |        136       22.63      100.00
------------+-----------------------------------
      Total |        601      100.00
*/
tab part_str 
/*
   part_str |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        136       73.91       73.91
          1 |         48       26.09      100.00
------------+-----------------------------------
      Total |        184      100.00
*/
*** Before investigating the effects of any of the interaction terms in our models, the focal independent variables (grand and petty corruption) were mean centered (Aiken & West, 1991).
center petty_reverse grand_reverse illegal_dona
**** Industry: service vs nonservice
gen ind_service=(ksksectorcode20001==400 |ksksectorcode20001>=2600)
**** Asian country
gen region_asia=(nationcode== 103|nationcode== 105|nationcode== 106|nationcode== 108|nationcode== 111|nationcode== 112|nationcode==113|nationcode== 117|nationcode== 118|nationcode== 123)

****** variable rescaled
gen diff_edu_scale=diff_edu*100
replace infra=infra/10

global control "subs_size subs_cptl par_size par_roa par_leve par_exp ind_service ex_rate_scale region_asia gdp_scaled_log infra fdi_restr cul_dist diff_reli diff_edu_scale diff_social"

label variable subs_size "Subsidiary size (log)" 
label variable subs_cptl "Subsidiary capitalization (log)" 
label variable par_size "Parent size (log)" 
label variable par_roa "Parent profitability (ROA)" 
label variable par_leve "Parent leverage" 
label variable par_exp "Parent experience" 
label variable ind_service "Industry" 
label variable ex_rate_scale "Exchange rate" 
label variable region_asia "Region" 
label variable gdp_scaled_log "Host market size (log)" 
label variable infra "Infrastructure development" 
label variable fdi_restr "FDI restrictions" 
label variable cul_dist "Cultural distance" 
label variable diff_reli "Differences in religion" 
label variable diff_edu_scale "Differences in education" 
label variable diff_social "Differences in degree of socialism" 

logit entry_str $control
est store x1
reg entry_str $control
vif

logit entry_str petty_reverse grand_reverse $control
est store x2
reg entry_str petty_reverse grand_reverse $control
vif

logit entry_str petty_reverse illegal_dona $control
est store x3
reg entry_str petty_reverse grand_reverse $control
vif

gen  petty_grand=c_petty_reverse*c_grand_reverse
logit entry_str c_petty_reverse c_grand_reverse petty_grand $control
est store x4
reg entry_str c_petty_reverse c_grand_reverse petty_grand $control
vif

gen petty_donation=c_petty_reverse*illegal_dona
logit entry_str c_petty_reverse illegal_dona petty_donation $control
est store x5
reg entry_str c_petty_reverse illegal_dona petty_donation $control
vif

label variable petty_reverse "Petty corruption" 
label variable grand_reverse "Grand corruption" 
label variable illegal_dona "Illegal political donation" 
label variable petty_grand "Petty corruption x grand corruption" 
label variable petty_donation "Petty corruption x illegal political donations" 

esttab x1 x2 x3 x4 x5 using "/Users/Tao/Desktop/Sartor & Beamish_table4.csv", ///
  sca("N Observations" "pr2 Pseudo R2")  ///
  sfmt(%6.3f %6.3f %6.3f %6.0f)   ///
  starlevels(* .05 ** .01 *** .001) ///
  nogap  ///
  label ///
  mtitles(Model1A Model1B Model1C Model1D Model1E) b(%6.2f)  se(%6.2f) replace 
  
/****** drop grand_reverse
logit entry_str $control
est store x1
reg entry_str $control
vif

logit entry_str petty_reverse  $control
est store x2
reg entry_str petty_reverse  $control
vif

logit entry_str petty_reverse illegal_dona $control
est store x3
reg entry_str petty_reverse illegal_dona $control
vif
/*
gen  petty_grand=c_petty_reverse*c_grand_reverse
logit entry_str c_petty_reverse c_grand_reverse petty_grand $control
est store x4
reg entry_str c_petty_reverse c_grand_reverse petty_grand $control
vif
*/
gen petty_donation=c_petty_reverse*illegal_dona
logit entry_str c_petty_reverse illegal_dona petty_donation $control
est store x5
reg entry_str c_petty_reverse illegal_dona petty_donation $control
vif

label variable petty_reverse "Petty corruption" 
label variable grand_reverse "Grand corruption" 
label variable illegal_dona "Illegal political donation" 

label variable petty_donation "Petty corruption x illegal political donations" 

esttab x1 x2 x3 x5 using "/Users/Tao/Desktop/Sartor & Beamish_table4x.csv", ///
  sca("N Observations" "pr2 Pseudo R2")  ///
  sfmt(%6.3f %6.3f %6.3f %6.0f)   ///
  starlevels(* .05 ** .01 *** .001) ///
  nogap  ///
  label ///
  mtitles(Model1A Model1B Model1C Model1D Model1E) b(%6.2f)  se(%6.2f) replace 
*****/

logit part_str $control
est store y1
reg part_str petty_reverse grand_reverse $control
vif

logit part_str petty_reverse grand_reverse $control
est store y2
reg part_str petty_reverse grand_reverse $control
vif

logit part_str petty_reverse illegal_dona $control
est store y3
reg part_str petty_reverse grand_reverse $control
vif

logit part_str c_petty_reverse c_grand_reverse petty_grand $control
est store y4
reg part_str c_petty_reverse c_grand_reverse petty_grand $control
vif

logit part_str c_petty_reverse illegal_dona petty_donation $control
est store y5
reg part_str c_petty_reverse illegal_dona petty_donation $control
vif

esttab y1 y2 y3 y4 y5 using "/Users/Tao/Desktop/Sartor & Beamish/table5.csv", ///
  sca("N Observations" "pr2 Pseudo R2")  ///
  sfmt(%6.3f %6.3f %6.3f %6.0f)   ///
  starlevels(* .05 ** .01 *** .001) ///
  nogap  ///
  label ///
  mtitles(Model1A Model1B Model1C Model1D Model1E) b(%6.2f)  se(%6.2f) replace 

pwcorr subs_size subs_cptl par_size par_roa par_leve par_exp ind_service exchange_rate region_asia gdp_scaled_log infra fdi_restr cul_dist diff_reli diff_edu diff_social petty_reverse grand_reverse illegal_dona petty_grand petty_donation

sum entry_str part_str subs_size subs_cptl par_size par_roa par_leve par_exp ind_service exchange_rate region_asia gdp_scaled_log infra fdi_restr cul_dist diff_reli diff_edu diff_social petty_reverse grand_reverse illegal_dona petty_grand petty_donation



logit part_str $control
est store x1
reg part_str $control
vif

logit part_str petty_reverse  $control
est store x2
reg part_str petty_reverse  $control
vif

logit part_str petty_reverse illegal_dona $control
est store x3
reg part_str petty_reverse illegal_dona $control
vif
/*
gen  petty_grand=c_petty_reverse*c_grand_reverse
logit entry_str c_petty_reverse c_grand_reverse petty_grand $control
est store x4
reg entry_str c_petty_reverse c_grand_reverse petty_grand $control
vif
*/

logit part_str c_petty_reverse illegal_dona petty_donation $control
est store x5
reg part_str c_petty_reverse illegal_dona petty_donation $control
vif

label variable petty_reverse "Petty corruption" 
label variable grand_reverse "Grand corruption" 
label variable illegal_dona "Illegal political donation" 

label variable petty_donation "Petty corruption x illegal political donations" 

esttab x1 x2 x3 x5 using "/Users/Tao/Desktop/Sartor & Beamish_table3x.csv", ///
  sca("N Observations" "pr2 Pseudo R2")  ///
  sfmt(%6.3f %6.3f %6.3f %6.0f)   ///
  starlevels(* .05 ** .01 *** .001) ///
  nogap  ///
  label ///
  mtitles(Model1A Model1B Model1C Model1D Model1E) b(%6.2f)  se(%6.2f) replace 






