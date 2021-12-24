*********
********* By Wu Tao 17 May 2021
********* Paper: Government connections and credit access around the world: Evidence from discouraged borrowers

cd "/Users/Tao/Desktop/Qi and Nguyen replication"

clear
use beeps_iv_v_panel_v14
drop if idstd==. // 27803 left, very close to the raw data

******
****** Different variable names in two waves of survey
*** rejected loans
/* k20a: Outcome of the most recent application for line of credit/loan
-9 Don't know
-8 Refused
-6 APPLICATION STILL IN PROCESS
-3 APPLICATION WITHDRAWN BY THE ESTABLISHMENT
1 Application was approved
2 Application was rejected
k18a: apply for any new loans/lines of credit that were rejected in last fiscal year?
-9 don't know
 1 yes
 2 no
*/

*******************
******************* Dependent variable: The authors couldn't have drop missing values in the three variables or invalid answers. 
* step 1: drop firms without credit demand
drop if ecak17==1 // drop 11,818 obs
* step 2: 
/*
drop if k16==-9 | k16==-8 | k16==.
drop if k20a==-9 | k20a==-8
drop if k18a==-9
drop if k18a==. & k20a==.
*/
*gen k1820a=(k18a==1 | k20a==2)      // rejected loans? 1, yes; 0, no
gen cre_con=0 if k16==1 & (k18a==2 | k20a==1 | k20a==-3 | k20a==-6)  // credit constraint, has constraints, 1
replace cre_con=1 if cre_con==.
* Some firms may also become credit constrained when they did not apply for loans because they think that ‘‘interest rates are not favorable,’’ ‘‘collateral requirements are too high,’’ or the ‘‘size of loan and maturity are insufficient’’. We exclude these firms from the sample because it is difficult to tell whether they are discouraged firms (they never approach a bank) or rejected firms (they have approached a bank but could not afford to borrow at the terms presented to them by the bank).
drop if ecak17==3 | ecak17==4 | ecak17==5
gen cre_rej=(cre_con==1 & k16==1 & (k18a==1 | k20a==2))  // credit rejected
gen cre_dis= (cre_con==1 & ecak17==7)  // credit discouraged

*******************
******************* Independent variable
** government connection
drop if j6a==. | j6a<0
gen gov_conn=(j6a==1) // government connection

* firm age
drop if b6b<0 | b6b==.
gen f_age=a14y-b6b
 
* firm size
drop if l1<=0 
gen f_size=l1

********************** Problematic:No way to get it similar with that in the paper. no matter wheter we calculate growth rate or increased value.
** We use dummy instead as the variation is the closest to that in the paper.
*past growth
drop if d2<0 | n3==-9
replace n3=0 if n3==-7 // n3==-7 means not started business 3 yrs ago
gen past_grow=d2-n3 // use d2 instead of n3 as the denominator to avoid missing.
gen past_grow_dum=(d2>n3)
**********************

* audit_firm
drop if k21<0 | k21==.
gen f_audit=(k21==1)

********************** Problematic: there are 80% missing values. The paper mustn't have dropped the missing values.
* holding firm: headquarter without production and/or sales in this location
**?? drop if a8==. // 7517 non-missing values in raw data
gen f_hold=(a8==1) 
**********************

* publicly listed firm, no missing
drop if b1<0
gen f_list=(b1==1)

* sole proprietorship, no missing
gen f_sole=(b1==3)

* foriegn firm: b2b private foreign individuals, companies or organizations
*** problem: in appendix, the author define foreign firms as those with any foriegn shares. In the body, a firm with over 50% shares is defined as foreign.
drop if b2b<0
gen f_foreign=(b2b>50)

* export firm: d3c what % of establishement's sales were: indirect or direct exports?
drop if d3c<0 & d3b<0
gen f_export=(d3c>0|d3b>0)

* state-owned firm
drop if b2c<0
gen f_soe=(b2c>0)

* female managed firm
drop if b7a<0
gen f_female=(b7a==1)

* government subsidy firm: ecaq53, over the last 3 years, has this establishment received any government subsidies?
drop if ecaq53<0
gen f_subsidy=(ecaq53==1)

* informal competition: e30, how much of an obstacle are the informal sector competitiors to your operation
drop if e30<0
gen f_informal=(e30>0)

* country list
drop if a1==196 | a1==300 // cyprus and greece is not in the original country list.

/*
drop if k16==-9 | k16==-8 | k16==.
drop if k20a==-9 | k20a==-8
drop if k18a==-9
drop if k18a==. & k20a==.
*/

* Interest rate
replace ecaq46d=. if ecaq46d<0
gen int_rate=ecaq46d

* Colleteral
gen coll=1 if k13==1
replace coll=0 if k13==2

* duration
replace ecaq46e=. if ecaq46e<0
gen dura=ecaq46e


* corruption perceiption
merge m:1 country a14y using CPI
keep if _merge==3

**** access to state-owned bank: ecak5c, fixed assets: borrowed from state-owned bank
gen acc_soebank=(k9==2) 
replace acc_soebank=. if k9==. | k9<0
************************* fixed effects
*** country*sector 
egen coun_sec=group(a1 a4a)
*** country*year
egen coun_yr=group(a1 a14y)
*** sector*year
egen sec_yr=group(a14y a4a)

rename a14y year
rename a4a sector
rename a1 country_id

*** Table 2
global control "f_age f_size f_audit f_hold f_list f_sole f_foreign f_soe f_export f_informal f_subsidy f_female past_grow_dum"

label variable f_age "Firm age"
label variable f_size "Firm size"
label variable f_audit "Audited firm"
label variable f_hold "Holding firm"
label variable f_list "Publicly listed firm"
label variable f_sole "Sole proprietorship firm"
label variable f_foreign "Foreign firm"
label variable f_soe "State-owned firm"
label variable f_export "Export firm"
label variable f_informal "Informal competition"
label variable f_subsidy "Government subsidy firm"
label variable f_female "Female managed firm"
label variable past_grow_dum "Past growth"
label variable gov_conn "Government connections"


probit cre_dis gov_conn $control i.country_id i.year i.sector, vce(cluster idstd) asis // asis prevent estimation from dropping perfect predictors
est store m1
* reg cre_dis gov_conn $control i.country_id i.year i.sector // for R2

probit cre_dis gov_conn $control i.coun_yr i.sec_yr i.coun_sec, vce(cluster idstd) asis iterate (100) // model nonconvergent, max iteration: 100 times
est store m2
* reg cre_dis gov_conn $control i.coun_yr i.sec_yr i.coun_sec // for R2

probit cre_rej gov_conn $control i.country_id i.year i.sector, vce(cluster idstd) asis iterate (100) // model nonconvergent, max iteration: 100 times
est store m3
* reg cre_rej gov_conn $control i.country_id i.year i.sector // for R2

probit cre_rej gov_conn $control i.coun_yr i.sec_yr i.coun_sec, vce(cluster idstd) asis iterate (100) // model nonconvergent, max iteration: 100 times
est store m4
* reg cre_rej gov_conn $control i.coun_yr i.sec_yr i.coun_sec // for R2

esttab m1 m2 m3 m4 using "/Users/Tao/Desktop/Qi and Nguyen replication/table2.csv", ///
  sca("N Observations" "pr2 PseudoR2")  ///
  sfmt(%6.3f %6.3f %6.3f %6.0f)   ///
  starlevels(* .1 ** .05 *** .01) ///
  nogap  ///
  drop (*.country_id *.year *.sector *.coun_yr *.sec_yr *coun_sec)  ///
  label ///
  mtitles(Model1 Model2 Model3 Model4) b(%9.3f)  se(%9.3f) replace 

*** Table 3
label variable coll "Colleteral"
label variable dura "Duration"
label variable int_rate "Interst rate"

reg dura gov_conn coll int_rate $control i.coun_yr i.sec_yr i.coun_sec, vce(cluster idstd)
est store s1 

probit coll gov_conn dura int_rate $control i.coun_yr i.sec_yr i.coun_sec, vce(cluster idstd) asis iterate(100)
est store s2
* reg coll gov_conn dura int_rate $control i.coun_yr i.sec_yr i.coun_sec // for R2

reg int_rate gov_conn dura coll $control i.coun_yr i.sec_yr i.coun_sec, vce(cluster idstd)
est store s3

esttab s1 s2 s3 using "/Users/Tao/Desktop/Qi and Nguyen replication/table3.csv", ///
  sca("N Observations" "pr2 PseudoR2" "r2 R-square")  ///
  sfmt(%6.3f %6.3f %6.3f %6.0f)   ///
  starlevels(* .1 ** .05 *** .01) ///
  nogap  ///
  drop (*.coun_yr *.sec_yr *coun_sec)  ///
  label ///
  mtitles(Model1 Model2 Model3) b(%9.3f)  se(%9.3f) replace 

*** Table 4
rename score corr_score
gen corr_country=(corr_score<50)
gen govconn_corr=gov_conn*corr_country
gen govconn_foreign=gov_conn*f_foreign
gen govconn_soebank=gov_conn*acc_soebank

label variable corr_country "Corrupt country"
label variable govconn_corr "Government connections x corrupt country"
label variable govconn_foreign "Government connections x foreign firm"
label variable govconn_soebank "Government connections x access to state-owned bank"

* Panel A
probit cre_dis govconn_corr gov_conn corr_country $control i.coun_yr i.sec_yr i.coun_sec, vce(cluster coun_yr) asis iterate(100)
est store x1
probit cre_rej govconn_corr gov_conn corr_country $control i.coun_yr i.sec_yr i.coun_sec, vce(cluster coun_yr) asis iterate(100)
est store x2

esttab x1 x2 using "/Users/Tao/Desktop/Qi and Nguyen replication/table4_panelA.csv", ///
  sca("N Observations" "pr2 PseudoR2" "r2 R2")  ///
  sfmt(%6.3f %6.3f %6.3f %6.0f)   ///
  starlevels(* .1 ** .05 *** .01) ///
  nogap  ///
  drop (*.coun_yr *.sec_yr *coun_sec)  ///
  label ///
  mtitles(Model1 Model2) b(%9.3f)  se(%9.3f) replace 

* Panel B
probit cre_dis govconn_foreign gov_conn  $control i.coun_yr i.sec_yr i.coun_sec, vce(cluster idstd) asis iterate(100)
est store y1
probit cre_rej govconn_foreign gov_conn  $control i.coun_yr i.sec_yr i.coun_sec, vce(cluster idstd) asis iterate(100)
est store y2

esttab y1 y2 using "/Users/Tao/Desktop/Qi and Nguyen replication/table4_panelB.csv", ///
  sca("N Observations" "pr2 Pseudo R2")  ///
  sfmt(%6.3f %6.3f %6.3f %6.0f)   ///
  starlevels(* .1 ** .05 *** .01) ///
  nogap  ///
  drop (*.coun_yr *.sec_yr *coun_sec)  ///
  label ///
  mtitles(Model1 Model2) b(%9.3f)  se(%9.3f) replace 

* Panel B
probit cre_dis govconn_soebank gov_conn acc_soebank $control i.coun_yr i.sec_yr i.coun_sec, vce(cluster idstd) asis iterate(100)
est store z1
probit cre_rej govconn_soebank gov_conn acc_soebank $control i.coun_yr i.sec_yr i.coun_sec, vce(cluster idstd) asis iterate(100)
est store z2

esttab z1 z2 using "/Users/Tao/Desktop/Qi and Nguyen replication/table4_panelC.csv", ///
  sca("N Observations" "pr2 Pseudo R2")  ///
  sfmt(%6.3f %6.3f %6.3f %6.0f)   ///
  starlevels(* .1 ** .05 *** .01) ///
  nogap  ///
  drop (*.coun_yr *.sec_yr *coun_sec)  ///
  label ///
  mtitles(Model1 Model2) b(%9.3f)  se(%9.3f) replace 













