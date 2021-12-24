***** Transforming Disadvantages into Advantages: Developing-Country MNEs in the Least Developed Countries
*** 2 June 2021
*** By Wu Tao

cd "/Users/Tao/Desktop/Cuervo_2008"
clear
set more off
use sample0 // manually collected

**** Dependent variables
gen dv_1=de_aff/all_aff*100 // prevalence of developing country MNEs
gen dv_2=(de_aff-de_rs_aff)/(all_aff-rs_aff)*100 // prevalence of developing country MNEs exclusing firms in natural resource industries
gen dv_3=de_aff/(all_aff-col_aff)*100 // prevalence of developing-country MNEs excluding firms from former colonial power
replace dv_3=0 if all_aff-col_aff==0  // How to address missing values?
merge m:1 wbcode using atlas
drop if _merge==2
drop _merge

****** Independent variables
****** problem, the paper seems to have used two years (1999, 2001) of observations, while the 6 independent variables are only available in 1998, 2000, 2002
*** political stability and absence of violence
gen pol_1=pol_2002 // simply use 2002
gen pol_2=.
replace pol_2=pol_2000 if year==1999 // use two years of data
replace pol_2=pol_2002 if year==2001
gen pol_3=.
replace pol_3=pol_1998 if year==1999 // use two years of data
replace pol_3=pol_2000 if year==2001

*** voice and accountability
gen voi_1=voice_2002
gen voi_2=.
replace voi_2=voice_2000 if year==1999
replace voi_2=voice_2002 if year==2001
gen voi_3=.
replace voi_3=voice_1998 if year==1999
replace voi_3=voice_2000 if year==2001

*** government effectiveness
gen gov_1=gov_2002
gen gov_2=.
replace gov_2=gov_2000 if year==1999
replace gov_2=gov_2002 if year==2001
gen gov_3=.
replace gov_3=gov_1998 if year==1999
replace gov_3=gov_2000 if year==2001

*** regulatory quality
gen reg_1=reg_2002
gen reg_2=.
replace reg_2=reg_2000 if year==1999
replace reg_2=reg_2002 if year==2001
gen reg_3=.
replace reg_3=reg_1998 if year==1999
replace reg_3=reg_2000 if year==2001

*** control of corruption
gen corr_1=corr_2002
gen corr_2=.
replace corr_2=corr_2000 if year==1999 
replace corr_2=corr_2002 if year==2001
gen corr_3=.
replace corr_3=corr_1998 if year==1999 
replace corr_3=corr_2000 if year==2001

*** rule of law
gen law_1=law_2002
gen law_2=.
replace law_2=law_2000 if year==1999 
replace law_2=law_2002 if year==2001
gen law_3=.
replace law_3=law_1998 if year==1999 
replace law_3=law_2000 if year==2001

******** control variables
gen road_1=road_2001
gen road_2=.
replace road_2=road_1999 if year==1999
replace road_2=road_2001 if year==2001

gen phone_1=fixed_2001+mobile_2001
replace phone_1=10*phone_1
gen phone_2=.
replace phone_2=10*(fixed_1999+mobile_1999) if year==1999
replace phone_2=10*(fixed_2001+mobile_2001) if year==2001

******* fixed line: closest to the paper
replace fixed_2001=10*fixed_2001
replace fixed_1999=10*fixed_1999
gen phone_2_1=fixed_2001
gen phone_2_2=.
replace phone_2_2=fixed_2001 if year==2001
replace phone_2_2=fixed_1999 if year==1999

*** Geographic proximity: Dummy indicator of existence of a firm from a country with common border with the LDC among the largest affiliattes of foreign firms in the country
gen geo= neighbor_fdi

*** Colonial link: Dummy indicator of the existence of a firm from the former coloni9al power of the LDC among largest affilliates of foreign firms in the country
gen col_link=1 if col_aff>0
replace col_link=0 if col_aff==0

********Model 1a & model 1b
egen nation_code=group(wbcode)
xtset nation_code year
*** random-effect
xttobit dv_1 gni_capita road_2 phone_2_1 geo col_link, tobit ll(0) ul(100)
est store m1

xttobit dv_1 voi_3 pol_3 gov_3 reg_3 law_3 corr_3 gni_capita road_2 phone_2_1 geo col_link,tobit ll(0) ul(100)
est store m2

********Model 2a & model 2b
*** random-effect
xttobit dv_2 gni_capita road_2 phone_2_1 geo col_link,tobit ll(0) ul(100)
est store m3

xttobit dv_2 voi_3 pol_3 gov_3 reg_3 law_3 corr_3 gni_capita road_2 phone_2_1 geo col_link,tobit ll(0) ul(100)
est store m4

********Model 3a & model 3b
*** random-effect
xttobit dv_3 gni_capita road_2 phone_2_1 geo,tobit ll(0) ul(100)
est store m5

xttobit dv_3 voi_3 pol_3 gov_3 reg_3 law_3 corr_3 gni_capita road_2 phone_2_1 geo,tobit ll(0) ul(100)
est store m6

label variable dv_1 "Prevalence of developing-country MNEs"
label variable dv_2 "Prevalence of developing-country MNEs exclusing firms in natural resource industries"
label variable dv_3 "Prevalence of developing-country MNEs exclusing firms from former colonial power"
label variable voi_3 "Voice and accountability"
label variable pol_3 "Political stability and absense of violence"
label variable gov_3 "Government effectiveness"
label variable reg_3 "Regulatory quality"
label variable law_3 "Rule of law"
label variable corr_3 "Control of corruption"
label variable gni_capita "GNI per capita"
label variable road_2 "Roads paved"
label variable phone_2_1 "Phones per capital" 
label variable geo "Geographical proximity"
label variable col_link "Colonial link"


esttab m1 m2 m3 m4 m5 m6 using "/Users/Tao/Desktop/c-c-g_final_result.csv", ///
  sca("N Observations" "ch2 Chi-squared" "ll Log-likelihood")  ///
  sfmt(%6.3f %6.3f %6.3f %6.0f)   ///
  starlevels(+ .1 * .05 ** .01 *** .001) ///
  nogap  ///
  label ///
  mtitles(Model1a Model1b Model2a Model2b Model3a Model3b) b(%6.3f)  se(%6.3f) replace 


pwcorr_a dv_1 dv_2 dv_3 voi_3 pol_3 gov_3 reg_3 law_3 corr_3 gni_capita road_2 phone_2_1 geo col_link, star1(0.001) star5(0.01) star10(0.05)
sum dv_1 dv_2 dv_3 voi_3 pol_3 gov_3 reg_3 law_3 corr_3 gni_capita road_2 phone_2_1 geo col_link


***** use pca


pca voi_3 pol_3 gov_3 reg_3 law_3 corr_3
rotate, varimax
factor voi_3 pol_3 gov_3 reg_3 law_3 corr_3
alpha voi_3 pol_3 gov_3 reg_3 law_3 corr_3

predict pc1

xttobit dv_1 gni_capita road_2 phone_2_1 geo col_link, tobit ll(0) ul(100)
est store m1

xttobit dv_1 pc1 gni_capita road_2 phone_2_1 geo col_link,tobit ll(0) ul(100)
est store m2

xttobit dv_2 gni_capita road_2 phone_2_1 geo col_link,tobit ll(0) ul(100)
est store m3

xttobit dv_2 pc1 gni_capita road_2 phone_2_1 geo col_link,tobit ll(0) ul(100)
est store m4

xttobit dv_3 gni_capita road_2 phone_2_1 geo,tobit ll(0) ul(100)
est store m5

xttobit dv_3 pc1 gni_capita road_2 phone_2_1 geo,tobit ll(0) ul(100)
est store m6

esttab m1 m2 m3 m4 m5 m6 using "/Users/Tao/Desktop/pca.csv", ///
  sca("N Observations" "ch2 Chi-squared" "ll Log-likelihood")  ///
  sfmt(%6.3f %6.3f %6.3f %6.0f)   ///
  starlevels(+ .1 * .05 ** .01 *** .001) ///
  nogap  ///
  label ///
  mtitles(Model1a Model1b Model2a Model2b Model3a Model3b) b(%6.3f)  se(%6.3f) replace 
  
  
 ***** only corruption

xttobit dv_1 gni_capita road_2 phone_2_1 geo col_link, tobit ll(0) ul(100)
est store m1

xttobit dv_1 corr_3 gni_capita road_2 phone_2_1 geo col_link,tobit ll(0) ul(100)
est store m2

********Model 2a & model 2b
*** random-effect
xttobit dv_2 gni_capita road_2 phone_2_1 geo col_link,tobit ll(0) ul(100)
est store m3

xttobit dv_2 corr_3 gni_capita road_2 phone_2_1 geo col_link,tobit ll(0) ul(100)
est store m4

********Model 3a & model 3b
*** random-effect
xttobit dv_3 gni_capita road_2 phone_2_1 geo,tobit ll(0) ul(100)
est store m5

xttobit dv_3 corr_3 gni_capita road_2 phone_2_1 geo,tobit ll(0) ul(100)
est store m6

esttab m1 m2 m3 m4 m5 m6 using "/Users/Tao/Desktop/only_corr.csv", ///
  sca("N Observations" "ch2 Chi-squared" "ll Log-likelihood")  ///
  sfmt(%6.3f %6.3f %6.3f %6.0f)   ///
  starlevels(+ .1 * .05 ** .01 *** .001) ///
  nogap  ///
  label ///
  mtitles(Model1a Model1b Model2a Model2b Model3a Model3b) b(%6.3f)  se(%6.3f) replace 



xttobit dv_1 gni_capita road_2 phone_2_1 geo col_link, tobit ll(0) ul(100)
est store m1

xttobit dv_1 reg_3 gni_capita road_2 phone_2_1 geo col_link,tobit ll(0) ul(100)
est store m2

********Model 2a & model 2b
*** random-effect
xttobit dv_2 gni_capita road_2 phone_2_1 geo col_link,tobit ll(0) ul(100)
est store m3

xttobit dv_2 reg_3 gni_capita road_2 phone_2_1 geo col_link,tobit ll(0) ul(100)
est store m4

********Model 3a & model 3b
*** random-effect
xttobit dv_3 gni_capita road_2 phone_2_1 geo,tobit ll(0) ul(100)
est store m5

xttobit dv_3 reg_3 gni_capita road_2 phone_2_1 geo,tobit ll(0) ul(100)
est store m6

esttab m1 m2 m3 m4 m5 m6 using "/Users/Tao/Desktop/only_reg.csv", ///
  sca("N Observations" "ch2 Chi-squared" "ll Log-likelihood")  ///
  sfmt(%6.3f %6.3f %6.3f %6.0f)   ///
  starlevels(+ .1 * .05 ** .01 *** .001) ///
  nogap  ///
  label ///
  mtitles(Model1a Model1b Model2a Model2b Model3a Model3b) b(%6.3f)  se(%6.3f) replace 








