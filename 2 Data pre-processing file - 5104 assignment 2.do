cd "D:\duke-nus\PhD life\2 Modules\14 SPH5104\Assignment\MIMIC data"
import excel "D:\duke-nus\PhD life\2 Modules\14 SPH5104\Assignment\MIMIC data\obesity_7.xlsx", sheet("obesity_7") firstrow case(lower)

label variable a "numbering"
label variable subject_id "subject id"
label variable hadm_id "admission id"
label variable stay_id "stay id"
label variable gender "gender"
label variable admission_age "age at admission"
rename admission_age age
label variable ethnicity "ethnicity"
label variable los_icu "length of stay icu"
label variable icu_intime "icu in time"
label variable icu_outtime "icu out time"
label variable first_careunit "care unit"
label variable admission_type "admission type"
label variable vent_type "intubation vs extubation"
label variable patientweight "weight"
rename patientweight weight
label variable sapsii "saps score"
label variable charlson_comorbidity_index "charlson score"
rename charlson_comorbidity_index csi
label variable height "height"

***recode string to numeric  
*vent_type
codebook vent_type
encode vent_type, generate(ventilation_type)
codebook ventilation_type
*gender
codebook gender
encode gender, generate(gender_stata)
codebook gender_stata
*ethnicity
codebook ethnicity
encode ethnicity, generate(ethnicity_stata)
recode ethnicity_stata (7 = 1) (5 = .) (6 = .) (4 = 5) (1 = 4) 
label drop ethnicity_stata
label define ethnicity_stata 1 "WHITE" 2 "BLACK/AFRICAN AMERICAN" 3 "HISPANIC/LATINO" 4"ASIAN" 5 "OTHER"
label value ethnicity_stata ethnicity_stata
codebook ethnicity_stata
*first_careunit
codebook first_careunit
encode first_careunit, generate(first_careunit_stata)
codebook first_careunit_stata
*admission_type
codebook admission_type
encode admission_type, generate(admission_type_stata)
codebook admission_type_stata

*convert datetime (*36525 days = 100 years)
generate double icu_intime_stata = clock(icu_intime,"DM19Yhm")
generate double icu_outtime_stata = clock(icu_outtime, "DM19Yhm")
generate double vent_storetime_stata = clock(vent_storetime,"DM19Yhm")
generate double deathtime_stata = clock(deathtime,"DM19Yhm")

*mortality variables (0 = survive, 1 = death)
generate mortality = 1
replace mortality = 0 if deathtime_stata == .

*order variables
drop hadm_id gender ethnicity icu_intime icu_outtime icustay_seq first_careunit admission_type vent_storetime vent_type deathtime
order subject_id stay_id age gender_stata ethnicity_stata height weight sapsii sapsii_prob csi first_careunit_stata admission_type_stata los_icu ventilation_type

***reshape dataset
bysort subject_id stay_id (a): generate id = _n /*generate observation number according to subject_id and stay_id with preservation of time sequence (v1)*/
order a, last
drop a
codebook id
list subject_id if id == 3 /*manual calculation of ventilation duration for subjects with equal to or more than 3 rows*/
*Replace weight to weight at first time point
replace weight = 60 in 273
replace weight = 60 in 274
replace weight = 108 in 356
replace weight = 58.5 in 363
replace weight = 58.5 in 364
replace weight = 58.5 in 365
replace weight = 58.5 in 366
replace weight = 138 in 370
replace weight = 56.9 in 373
replace weight = 80 in 478
replace weight = 67 in 552
replace weight = 67 in 553
replace weight = 90 in 635
replace weight = 104.5 in 791
replace weight = 73 in 846
replace weight = 97.9 in 868
replace weight = 49 in 1117
replace weight = 49 in 1118
replace weight = 49 in 1119
replace weight = 70 in 1130
replace weight = 90 in 1246
replace weight = 75.4 in 1265
replace weight = 79.2 in 1298
*drop patient_id 13036533 stay_id 37187494 (repeated measure)
drop if subject_id == 13036533 & stay_id == 37187494
*drop observations with id >= 3
drop if id >= 3
*reshape from long format to wide format
reshape wide ventilation_type vent_storetime_stata, i(subject_id stay_id) j(id)

***calculate ventilation duration for patients with 1 or 2 rows of ventilation_type
*28-day mortality variable
generate day_28_mortality = mortality
generate mortality_duration = (deathtime_stata - icu_intime_stata)/(1000*60*60*24) /*ventilation_type1 = extubation*/
replace mortality_duration = (deathtime_stata - vent_storetime_stata1)/(1000*60*60*24) if ventilation_type1 == 2 /*ventilation_type1 = intubation*/
replace mortality_duration = mortality_duration + 36525 if mortality_duration < -30000
replace mortality_duration = mortality_duration - 36525 if mortality_duration > 30000
summarize mortality_duration
replace day_28_mortality = 0 if mortality_duration > 28
codebook day_28_mortality
list subject_id stay_id mortality_duration if day_28_mortality == 1
*12 scenarios with intubation(2)/extubation(1) in ventilation_type1, intubation(2)/extubation(1)/missing(.) in ventilation_type2, and 0(survive)/1(death) in day_28_mortality
generate vent_duration = . /*missing vent_duration will be excluded*/
*calculate duration of ventilation for 28-day survivor
replace vent_duration = (vent_storetime_stata2 - vent_storetime_stata1)/(1000*60*60*24) if ventilation_type1 == 2 & ventilation_type2 == 1 & day_28_mortality == 0
replace vent_duration = (vent_storetime_stata2 - icu_intime_stata)/(1000*60*60*24) if ventilation_type1 == 1 & ventilation_type2 == 1 & day_28_mortality == 0
replace vent_duration = (vent_storetime_stata1 - icu_intime_stata)/(1000*60*60*24) if ventilation_type1 == 1 & ventilation_type2 == . & day_28_mortality == 0
replace vent_duration = vent_duration + 36525 if vent_duration < -30000
replace vent_duration = vent_duration - 36525 if vent_duration > 30000
summarize vent_duration
*calculate duration of ventilation for patients who died within 28 days
replace vent_duration = mortality_duration if day_28_mortality == 1

***combine duration of ventilation for all patients
*merge with manual calculation of ventilation duration
merge 1:1 subject_id stay_id using "D:\duke-nus\PhD life\2 Modules\14 SPH5104\Assignment\MIMIC data\1 Notes for duration of ventilation calculation.dta"
replace vent_duration = vent_dur_manual if _merge == 3
*drop missing observations
drop if vent_duration == . 
drop if vent_duration == 999
drop if vent_duration < 0
codebook vent_duration

*28_day_extubation
generate day_28_extubation = day_28_mortality
replace day_28_extubation = 1 if vent_duration > 28
label define day_28_extubation 0 "Success" 1 "Fail"
label value day_28_extubation day_28_extubation
codebook day_28_extubation
histogram vent_duration, frequency
histogram los_icu, frequency

*drop variables
drop ventilation_type1 vent_storetime_stata1 ventilation_type2 vent_storetime_stata2 icu_intime_stata icu_outtime_stata deathtime_stata vent_dur_manual _merge

***BMI calculation
*impute height
histogram height /*normally distributed*/
summarize height, detail
replace height = 168.8 if height == . /*impute height with mean value*/
*weight
histogram weight, frequency 
summarize weight, detail
list if weight < 20
replace weight = 81.7 if weight < 5 /*imput physiologically impossible weight with median value*/
*BMI
generate bmi = weight/((height/100)^2)
summarize bmi, detail

*cleaning
order subject_id stay_id age gender ethnicity_stata first_careunit_stata admission_type_stata sapsii sapsii_prob csi height weight bmi mortality day_28_mortality mortality_duration day_28_extubation vent_duration 
label variable mortality_duration "time to death"
label variable day_28_extubation "day_28_extubation"
label variable day_28_mortality "day_28_mortality"
label variable mortality "overall mortality"
label variable bmi "body mass index"
label variable vent_duration "ventilation duration"
rename gender_stata gender
rename ethnicity_stata ethnicity
rename first_careunit_stata first_careunit
rename admission_type_stata admission_type
label variable csi "charlson comorbility index score"
rename csi cci
label define mortality 0 "survive" 1 "death"
label value mortality mortality
label value day_28_mortality mortality

save "D:\duke-nus\PhD life\2 Modules\14 SPH5104\Assignment\MIMIC data\2 Cleaned obesity ventilation duration.dta"
export excel using "D:\duke-nus\PhD life\2 Modules\14 SPH5104\Assignment\MIMIC data\2 Cleaned obesity ventilation duration.xlsx", sheetreplace firstrow(variables)
