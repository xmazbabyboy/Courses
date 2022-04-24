cd "D:\duke-nus\PhD life\2 Modules\14 SPH5104\Assignment\MIMIC data"
use "2 Cleaned obesity ventilation duration.dta"

***Exposures
*BMI status (4 categories)
generate obesity4 = 0
replace obesity4 = 1 if bmi < 18
replace obesity4 = 2 if bmi >= 25
replace obesity4 = 3 if bmi >= 30
label define obesity4 0 "Normal" 1 "Underweight" 2 "Overweight" 3 "Obese"
label value obesity4 obesity4
label variable obesity4 "bmi status"
codebook obesity4

*Obesity status (2 categories)
generate obesity2 = 0
replace obesity2 = 1 if bmi >= 30
label define obesity2 0 "Not Obese" 1 "Obese"
label value obesity2 obesity2
label variable obesity2 "obesity status"
codebook obesity2
*Table 1: Baseline characristics difference between obese and non-obese 
tabulate obesity2
by obesity2, sort: summarize age
ttest age, by(obesity2) unequal
tabulate obesity2 gender, row exact
tabulate obesity2 ethnicity, row exact
tabulate obesity2 first_careunit, row exact
ttest sapsii, by(obesity2) unequal
ttest cci, by(obesity2) unequal

***Outcome 1
*3-day mortality 
generate day_3_mortality = mortality
replace day_3_mortality = 0 if mortality_duration > 3
codebook day_3_mortality
*3_day_extubation 
generate day_3_extubation = day_3_mortality
replace day_3_extubation = 1 if vent_duration > 3
label define day_3_extubation 0 "Success" 1 "Fail"
label value day_3_extubation day_3_extubation
label variable day_3_extubation "day_3_extubation"
codebook day_3_extubation
tabulate obesity2 day_3_extubation, row exact
tabulate obesity2 day_3_mortality, row exact
*3_day_vent_duration
generate day_3_vent_duration = vent_duration
replace day_3_vent_duration = 3 if vent_duration > 3
label variable day_3_vent_duration "ventilation duration up to day 3"
*Figure 1: Kaplan Meier curve of Failed extubation at day 3
stset vent_duration, failure(day_3_extubation==1) scale(1)
sts graph, by(obesity2) risktable risktable(, failevents title(Number at risk (failed extubation):)) risktable(, rowtitle(Not Obese) group(#1)) risktable(, rowtitle(Obese) group(#2)) ytitle(Successful Extubation) yscale(noline) ylabel(0(0.1)1, angle(horizontal) format(%9.1g) nogrid) xtitle(Days from Intubation) legend(off)
*Table 2, 3, and 4: Model selection and CoxPH day 3
*Table 2: Models with obesity2
stset day_3_vent_duration, failure(day_3_extubation==0) scale(1)
stcox i.obesity2
estat phtest, detail
estat ic
stcox i.obesity2 age i.gender i.ethnicity i.first_careunit sapsii cci
estat phtest, detail
estat ic
*SAPS score violates CoxPH assumptions -> change SAPS score into quantiles for stratified CoxPH
xtile saps_bin = sapsii, nq(2)
stcox i.obesity2 age i.gender i.ethnicity i.first_careunit cci, strata(saps_bin)
estat phtest, detail
xtile saps_tert = sapsii, nq(3)
stcox i.obesity2 age i.gender i.ethnicity i.first_careunit cci, strata(saps_tert)
estat phtest, detail
xtile saps_quart = sapsii, nq(4)
stcox i.obesity2 age i.gender i.ethnicity i.first_careunit cci, strata(saps_quart)
estat phtest, detail
xtile saps_quint = sapsii, nq(5)
stcox i.obesity2 age i.gender i.ethnicity i.first_careunit cci, strata(saps_quint)
estat phtest, detail
*There is not much difference between saps-categories -> choose saps_bin 
stcox i.obesity2 age i.gender i.ethnicity i.first_careunit cci, strata(saps_bin)
estat phtest, detail
test (2.ethnicity 3.ethnicity 4.ethnicity 5.ethnicity)
test (2.first_careunit 3.first_careunit 4.first_careunit)
estat ic
*Table 3: Sensitivity analysis
*Stratified by first_careunit
by first_careunit, sort: stcox i.obesity2 age i.gender i.ethnicity cci, strata(saps_bin)
estat phtest
estat ic
*Table 4: Sensitivity analysis
*Model with obesity4
stcox i.obesity4 age i.gender i.ethnicity i.first_careunit cci, strata(saps_bin)
test (1.obesity4 2.obesity4 3.obesity4)
estat phtest
estat ic

*Stratified by age
generate age_grp = 0
replace age_grp = 1 if age >= 60
by age_grp, sort: stcox i.obesity2 i.gender i.ethnicity first_careunit cci, strata(saps_bin)


***Outcome 2
*7-day mortality 
generate day_7_mortality = mortality
replace day_7_mortality = 0 if mortality_duration > 7
codebook day_7_mortality
*7_day_extubation 
generate day_7_extubation = day_7_mortality
replace day_7_extubation = 1 if vent_duration > 7
label define day_7_extubation 0 "Success" 1 "Fail"
label value day_7_extubation day_7_extubation
label variable day_7_extubation "day_7_extubation"
codebook day_7_extubation
*7_day_vent_duration
generate day_7_vent_duration = vent_duration
replace day_7_vent_duration = 7 if vent_duration > 7
label variable day_7_vent_duration "ventilation duration up to day 7"
*Figure: Kaplan Meier curve of failed extubation at day 7
stset vent_duration, failure(day_7_extubation==1) scale(1)
sts graph, by(obesity2) risktable risktable(, failevents title(Number at risk (failed extubation):)) risktable(, rowtitle(Not Obese) group(#1)) risktable(, rowtitle(Obese) group(#2)) ytitle(Successful Extubation) yscale(noline) ylabel(0(0.1)1, angle(horizontal) format(%9.1g) nogrid) xtitle(Days from Intubation) legend(off)
*Table 6: CoxPH day 7
*Model with obesity2
stset day_7_vent_duration, failure(day_7_extubation==0) scale(1)
stcox i.obesity2 age i.gender i.ethnicity i.first_careunit cci sapsii
estat phtest, detail
stcox i.obesity2 age i.gender i.ethnicity i.first_careunit cci, strata (saps_bin)
estat phtest, detail
estat ic

***Outcome 3
*14-day mortality 
generate day_14_mortality = mortality
replace day_14_mortality = 0 if mortality_duration > 14
codebook day_14_mortality
*14_day_extubation 
generate day_14_extubation = day_14_mortality
replace day_14_extubation = 1 if vent_duration > 14
label define day_14_extubation 0 "Success" 1 "Fail"
label value day_14_extubation day_14_extubation
label variable day_14_extubation "day_14_extubation"
codebook day_14_extubation
*14_day_vent_duration
generate day_14_vent_duration = vent_duration
replace day_14_vent_duration = 14 if vent_duration > 14
label variable day_14_vent_duration "ventilation duration up to day 14"
*Figure: Kaplan Meier curve of failed extubation at day 7
stset vent_duration, failure(day_14_extubation==1) scale(1)
sts graph, by(obesity2) risktable risktable(, failevents title(Number at risk (failed extubation):)) risktable(, rowtitle(Not Obese) group(#1)) risktable(, rowtitle(Obese) group(#2)) ytitle(Successful Extubation) yscale(noline) ylabel(0(0.1)1, angle(horizontal) format(%9.1g) nogrid) xtitle(Days from Intubation) legend(off)
*Table 6: CoxPH day 14
*Model with obesity2
stset day_14_vent_duration, failure(day_14_extubation==0) scale(1)
stcox i.obesity2 age i.gender i.ethnicity i.first_careunit cci sapsii
estat phtest, detail
estat ic
stcox i.obesity2 age i.gender i.ethnicity i.first_careunit cci, strata (saps_bin)
estat phtest, detail
estat ic
