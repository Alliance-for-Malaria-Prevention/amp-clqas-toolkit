** OPITACA AMP Assessments using cLQAS
** Generate dummy data for end-process assessment to run on adaptable R scripts

* Overview of design (same as the in-process data)
	// Lots = districts
	// Districts are grouped into regions
	// Three regions
		// Region 1 	5 districts
		// Region 2		6 districts
		// Region 3		4 districts
	// Each district follows the 6 clusters x 10 households sampling strategy
		// Region 1		Districts 101 to 105	Clusters 10101-10106 to 10501 to 10506
		// Region 2		Districts 201 to 206	Clusters 20101-20106 to 20601 to 20606
		// Region 3		Districts 301 to 304	Clusters 30101-30106 to 30401 to 30406
	
	// Assume ITN allocation rule of 1 ITN per 2 people, capped at 3

* Started: 28 Nov 2025


****************
** Change Log **
****************

* 18 Jan 2026
	// Edited line 948 to stop it setting all values of reason_mismatch to missing (!)
		// replace reason_mismatch = . in L
	// to
		// replace reason_mismatch = . if calc_itn_correct==1 in L
	
* 4 Dec 2025
	// Revised to keep additional 270 cases from the DHS data (in a separate run-through)
	// These are processed after the intial 900 cases to fill gaps in complete interviews


/*
gen region = word("North South East West", ceil(runiform()*4))
gen head_gender = cond(runiform()<0.7,"Male","Female")
*/


****************************************
** Manipulate DHS Programe Model Data **
****************************************
** Steps
	// Restrict to 900 valid HHs
	// Assign to 3 regions / 15 districts
	// Play around with number of ITNs in this file to fix access at different levels in different regions
	// Also need to disaggregate ITNs into campaign and non-campaign and compare HHR rules vs campaign ITNs
	// Extract N of HH members and N of ITNs to HH file
	// Then come back and complete fields in this data once HHs are complete
	
	// 4 Dec: Rerun the above for the additional 270 cases


** Initiate file

	cd "C:\Users\steve.poyer\OneDrive - Tropical Health\Projects - Open\C033 - OPITACA\60 - Implementation\WS3 - Data and cLQAS\TH adaptable tools\Analysis scripts\clqas-tools\Dummy data\"
	dir
	clear

	set seed 97531
	
	use "C:\Users\steve.poyer\Desktop\zz_2016_DHS_11282025_876\zzhr62dt\ZZHR62FL.DTA", clear

** Steps
	// Restrict to 900 valid HHs
		keep if hv227==1				// Has nets
		keep if hv012<13				// De jure size
		keep if hv024==2				// Region 2
			gen temp=runiform()<0.75
			tab temp
			keep if temp==1				// 925 cases
			
			gsort hhid
			drop in 901/925				// Drop 25 HHs based on hhid
			count						// 900 cases
		
		// Restrict variables
		keep hhid hv012 hv014 hv227 hml1 hv103* hv104* hv105* hml19*
			// hv103 = stay
			// hv104 = sex
			// hv105 = age (yrs)
			// hml19 = slept under net last night
			
		drop hv103_13-hv103_90
		drop hv104_13-hv104_90
		drop hv105_13-hv105_90
		drop hml19_13-hml19_90

		renvars, subst(_0 _)

	// Assign to regions and districts before reshaping
		gsort hhid
		gen n=_n
		gen region = 0
			recode region (0=1) if inrange(n,1,300)
			recode region (0=2) if inrange(n,301,660)
			recode region (0=3) if inrange(n,661,900)
		tab region, m
		
		gen district = 0
			recode district (0=101) if inrange(n,1,60)
			recode district (0=102) if inrange(n,61,120)
			recode district (0=103) if inrange(n,121,180)
			recode district (0=104) if inrange(n,181,240)
			recode district (0=105) if inrange(n,241,300)
			recode district (0=201) if inrange(n,301,360)
			recode district (0=202) if inrange(n,361,420)
			recode district (0=203) if inrange(n,421,480)
			recode district (0=204) if inrange(n,481,540)
			recode district (0=205) if inrange(n,541,600)
			recode district (0=206) if inrange(n,601,660)
			recode district (0=301) if inrange(n,661,720)
			recode district (0=302) if inrange(n,721,780)
			recode district (0=303) if inrange(n,781,840)
			recode district (0=304) if inrange(n,841,900)
		tab district region, m
		drop n


	// Manipulate ITN access by changing HH-level varaible
		// Need to increase access in R1 and R3
		mean hv012, over(region)
		tab hml1 region, col
			
			gen r1add = rpoisson(0.5) if region==1
			gen r3add = rpoisson(0.75) if region==3
				tab1 r1add r3add
				recode r?add (4/5 = 3) (.=0)		// Cap additional nets at 3
				
			replace hml1 = hml1 + r1add + r3add
			drop r?add

		tab hml1 region, col


	// Disaggregate ITNs into campaign and non-campaign and compare HHR rules vs campaign ITNs
		// In this file, all HHs will have at least 1 campaign ITN
		// Decisions on HHs with no campaign ITNs will be made in the HH file
		tab hml1 region, col
		gen pop2 = hml1*2
		bysort region: tab hv012 pop2
		bysort region: tab hv012 hml1
		
		// Assume ITN allocation rule of 1 ITN per 2 people, capped at 3
		recode hv012 (1/2=1) (3/4=2) (5/6=3) (7/12=3), gen(alloc)
		
			// Households with sufficient ITNs to meet alloc rules
			compare alloc hml1
				// 472 cases with sufficient ITNs to meet alloc rule (52%)
				// Note: If we cap at 4 then only 364/900 HHs have sufficient ITNs in their records
			tab alloc hml1
			
			gen Ncitn = .
			gen Nncitn = .
			
				replace Ncitn = alloc if alloc<=hml1
				replace Nncitn = hml1 - alloc if alloc<hml1

			// Households without sufficient ITNs to meet alloc rules
			tab alloc hml1 if missing(Ncitn)
			
				replace Ncitn = hml1 if missing(Ncitn)
				replace Nncitn = 0 if missing(Nncitn)
			
			gen temp=Ncitn + Nncitn
			compare hml1 temp
			drop temp

			*hist Ncitn, by(region) discrete
				// Okay, R1 and R3 are "better" than R2 in terms of more ITNs distirbuted


	// Back to data management - wide to long to assess population access and use
		reshape long hv103_ hv104_ hv105_ hml19_, i(hhid) j(res_no)

		ren hv103_ stay
		ren hv104_ gender
		ren hv105_ age_y
		ren hml19_ use_itn

		drop if res_no > hv012
		gsort hhid res_no

		tab res_no, m	// Okay
		tab stay, m		// 73 No (1.4%) - Okay, just need "some" cases to drop out of the use calculation
						// 10 missing
			tab stay use_itn, m
			recode stay (.=0) if use_itn==0
			recode stay (.=1) if use_itn==1
		tab gender, m	// Okay
		tab age_y, m	// Good distribution for a country like Nigeria
						// 1 missing
			list if missing(age_y)
			list if hhid=="      191 28"
			recode age_y (.=8)	// Recode to 8 years
			codebook age_y
			lab list HV105_12
			lab drop HV105_12
		tab use_itn, m	// 69% Yes in the raw data
		tab hv012, m	// 
		tab hv014, m	//
		tab hv227, m	// 100% have net(s)
		tab hml1, m		// Okay - number of ITNs makes sense post-distribution after r1add and r3add step above

		drop hv014		// Will recalculate with other age groups to match end-process questionnaire


	// Estimate ITN access by region
		tab hml1, m
		gen pot2use = hml1*2
		gen access= res_no<=pot2use
		mean access, over(region)
			// Original in raw data: 64%, 62%, 65%
			// Revised with additional nets: 74%, 62%, 78%

		// Need to decrease use in R2 so it is below access value, and in R1 generally
		tab use_itn region, col
			by hhid: egen num_use = total(use_itn)
			tab hml1 num_use if res_no==1 & region==1, m
			
			// Apply runiform and randomly set some folks to not sleep under nets
			// R1 needs generally lower levels of use to differentiate performance from R3 (say, -10 %pts)
			// R2 needs to be lower than access and poorly performing overall
			gen r1del = runiform()<0.15 if region==1 & use_itn==1
			gen r2del = runiform()<0.4 if region==2 & use_itn==1
				tab1 r1del r2del
				recode use_itn (1=0) if r1del==1 | r2del==1
			drop r?del

		mean use_itn, over(region)
			// Original in raw data: 71%, 66%, 72% (Note these are higher than access!)
			// Revised: 60%, 40%, 72%
			// Use:Access is therefore: 81%, 65%, 92%


	// Extract N of HH members by age and N of ITNs to HH file
		gen cu5=1 if age_y<5
		gen oc=1 if inrange(age_y,5,17)
		gen adult=1 if age_y>17
		
		tab1 cu5 oc adult
			di 865+1801+2412
		bysort hhid: egen Ncu5=total(cu5)
		bysort hhid: egen Noc=total(oc)
		bysort hhid: egen Nadult=total(adult)
			tab1 N* if res_no==1, m
			*br if Nadult==0
			// 2 single-ind HHs with 17 year olds - edit to 18 to avoid confusion
			recode age_y (17=18) if Nadult==0
				recode oc adult (1=.) (.=1) if Nadult==0
				recode Noc (1=0) if Nadult==0
				recode Nadult (0=1)
		
		*histogram hv012, discrete
		*histogram hml1, discrete	
		
		ren hhid hhid_Ind
		compress
		save "end_ind_900cases.dta", replace

		keep if res_no==1
		keep hhid_Ind region district hv012 hml1 alloc Ncitn Nncitn N* num_use
		gsort district
		gen _indexInd = _n
		
		compress
		save "end_ind_hhsummary.dta", replace

			*use "end_ind_900cases.dta", clear
			*merge m:1 hhid using "end_ind_hhsummary.dta", keepusing(_indexInd)
			*save "end_ind_900cases.dta", replace



** Repeat same process for additional 270 HHs
	// Note: I could have done this once by setting 78 HHs in each district, 
	// then saving the additional 18 per district in a separate file... not sure why I didn't do this
	// think it was because I like the 900 cases generated by the code above and didn't want to change
	// them with the random distirbutions used
	
	use "C:\Users\steve.poyer\Desktop\zz_2016_DHS_11282025_876\zzhr62dt\ZZHR62FL.DTA", clear
	
	// Pull additional cases from region 1 as most similar to region 2 for hh size and nets
		mean hv012, over(hv024)
		mean hml1, over(hv024)		
	
	// Restrict to 270 valid HHs
		keep if hv227==1				// Has nets
		keep if hv012<13				// De jure size
		keep if hv024==1				// Region 1
		count
			gen temp=runiform()<0.19
			tab temp
			keep if temp==1				// 277 cases
		
			gsort hhid
			drop in 271/277				// Drop 7 HHs based on hhid
			count						// 270 cases

		// Restrict variables
		keep hhid hv012 hv014 hv227 hml1 hv103* hv104* hv105* hml19*
			// hv103 = stay
			// hv104 = sex
			// hv105 = age (yrs)
			// hml19 = slept under net last night
			
		drop hv103_13-hv103_90
		drop hv104_13-hv104_90
		drop hv105_13-hv105_90
		drop hml19_13-hml19_90

		renvars, subst(_0 _)

	// Assign to regions and districts before reshaping
		gsort hhid
		gen n=_n
		gen region = 0
			recode region (0=1) if inrange(n,1,90)
			recode region (0=2) if inrange(n,91,198)
			recode region (0=3) if inrange(n,199,270)
		tab region, m
		
		gen district = 0
			recode district (0=101) if inrange(n,1,18)
			recode district (0=102) if inrange(n,19,36)
			recode district (0=103) if inrange(n,37,54)
			recode district (0=104) if inrange(n,55,72)
			recode district (0=105) if inrange(n,73,90)
			recode district (0=201) if inrange(n,91,108)
			recode district (0=202) if inrange(n,109,126)
			recode district (0=203) if inrange(n,127,144)
			recode district (0=204) if inrange(n,145,162)
			recode district (0=205) if inrange(n,163,180)
			recode district (0=206) if inrange(n,181,198)
			recode district (0=301) if inrange(n,199,216)
			recode district (0=302) if inrange(n,217,234)
			recode district (0=303) if inrange(n,235,252)
			recode district (0=304) if inrange(n,253,270)
		tab district region, m
		drop n


	// Manipulate ITN access by changing HH-level varaible
		// Need to increase access in R1 and R3
		mean hv012, over(region)
		tab hml1 region, col
			
			gen r1add = rpoisson(0.5) if region==1
			gen r3add = rpoisson(0.75) if region==3
				tab1 r1add r3add
				recode r?add (4/5 = 3) (.=0)		// Cap additional nets at 3
				
			replace hml1 = hml1 + r1add + r3add
			drop r?add

		tab hml1 region, col


	// Disaggregate ITNs into campaign and non-campaign and compare HHR rules vs campaign ITNs
		// In this file, all HHs will have at least 1 campaign ITN
		// Decisions on HHs with no campaign ITNs will be made in the HH file
		tab hml1 region, col
		gen pop2 = hml1*2
		bysort region: tab hv012 pop2
		bysort region: tab hv012 hml1
		
		// Assume ITN allocation rule of 1 ITN per 2 people, capped at 3
		recode hv012 (1/2=1) (3/4=2) (5/6=3) (7/12=3), gen(alloc)
		
			// Households with sufficient ITNs to meet alloc rules
			compare alloc hml1
				// 145 cases with sufficient ITNs to meet alloc rule (54%)
			tab alloc hml1
			
			gen Ncitn = .
			gen Nncitn = .
			
				replace Ncitn = alloc if alloc<=hml1
				replace Nncitn = hml1 - alloc if alloc<hml1

			// Households without sufficient ITNs to meet alloc rules
			tab alloc hml1 if missing(Ncitn)
			
				replace Ncitn = hml1 if missing(Ncitn)
				replace Nncitn = 0 if missing(Nncitn)
			
			gen temp=Ncitn + Nncitn
			compare hml1 temp
			drop temp

			*hist Ncitn, by(region) discrete
				// Okay, R1 and R3 are "better" than R2 in terms of more ITNs distirbuted


	// Back to data management - wide to long to assess population access and use
		reshape long hv103_ hv104_ hv105_ hml19_, i(hhid) j(res_no)

		ren hv103_ stay
		ren hv104_ gender
		ren hv105_ age_y
		ren hml19_ use_itn

		drop if res_no > hv012
		gsort hhid res_no

		tab res_no, m	// Okay
		tab stay, m		// 31 No (1.8%)
			tab stay use_itn, m
			recode stay (.=0) if use_itn==0
			recode stay (.=1) if use_itn==1
		tab gender, m	// Okay
		tab age_y, m	// Good distribution for a country like Nigeria
			list if missing(age_y)
			list if hhid=="      195 26"
			recode age_y (.=79)		// Older person to accompany res 9 in this HH
			codebook age_y
			lab list HV105_12
			lab drop HV105_12
		tab use_itn, m	// 66% Yes in the raw data
		tab hv012, m	//
		tab hv014, m	//
		tab hv227, m	// 100% have net(s)
		tab hml1, m		// Okay - number of ITNs makes sense post-distribution after r1add and r3add step above

		drop hv014		// Will recalculate with other age groups to match end-process questionnaire


	// Estimate ITN access by region
		tab hml1, m
		gen pot2use = hml1*2
		gen access= res_no<=pot2use
		mean access, over(region)
			// In 900 cases: 74%, 62%, 78%
			// This file: 72%, 62%, 73%

		// Need to decrease use in R2 so it is below access value, and in R1 generally
		tab use_itn region, col
			by hhid: egen num_use = total(use_itn)
			tab hml1 num_use if res_no==1 & region==1, m
			
			// Apply runiform and randomly set some folks to not sleep under nets
			// R1 needs generally lower levels of use to differentiate performance from R3 (say, -10 %pts)
			// R2 needs to be lower than access and poorly performing overall
			gen r1del = runiform()<0.15 if region==1 & use_itn==1
			gen r2del = runiform()<0.4 if region==2 & use_itn==1
				tab1 r1del r2del
				recode use_itn (1=0) if r1del==1 | r2del==1
			drop r?del

		mean use_itn, over(region)
			// In 900 cases: 60%, 40%, 72%
			// This file: 61%, 37%, 60%


	// Extract N of HH members by age and N of ITNs to HH file
		gen cu5=1 if age_y<5
		gen oc=1 if inrange(age_y,5,17)
		gen adult=1 if age_y>17
		
		tab1 cu5 oc adult
			di 292+626+770
		bysort hhid: egen Ncu5=total(cu5)
		bysort hhid: egen Noc=total(oc)
		bysort hhid: egen Nadult=total(adult)
			tab1 N* if res_no==1, m
			list if Nadult==0
			// 1 single-ind HHs with 16 year old - edit to 18 to avoid confusion
			recode age_y (16=18) if Nadult==0
				recode oc adult (1=.) (.=1) if Nadult==0
				recode Noc (1=0) if Nadult==0
				recode Nadult (0=1)
		
		*histogram hv012, discrete
		*histogram hml1, discrete
		
		ren hhid hhid_Ind
		compress
		save "end_ind_270cases.dta", replace

		keep if res_no==1
		keep hhid_Ind region district hv012 hml1 alloc Ncitn Nncitn N* num_use
		gsort district
		gen _indexInd = _n + 2900		// 900 cases in first file, so index starts at 2901 for this file
		
		compress
		save "end_ind_hhsummary_270cases.dta", replace

			*use "end_ind_270cases.dta", clear
			*merge m:1 hhid using "end_ind_hhsummary_270cases.dta", keepusing(_indexInd)
			*save "end_ind_270cases.dta", replace




**************************
** Household-level data **
**************************

** Initiate file
	// Known issues: I'm doing this from the in-process code so some note_* will be missing

	clear
	
	set seed 97531

	gen day = .
	gen month = .
	gen year = .
	gen hr = .
	gen mins = .
	gen double date_interview = .
	gen double endtime = .
	gen str32 deviceid = ""
	gen int note_intro = .
	gen int region = .
	gen int district = .
	gen int subdistrict = .
	gen int cluster_count = .
	gen int cluster = .
	gen int hh_n = .
	gen long calc_hh_id = .
	gen str64 geopoint = ""
	gen float _geopoint_latitude = .
	gen float _geopoint_longitude = .
	gen float _geopoint_altitude = .
	gen float _geopoint_precision = .
	gen str32 reason_nogps = ""
	gen int present = .
	gen int introduced = .
	gen int participate = .
	gen int note_ic_check = .
	gen str32 hohh_name = ""
	gen str32 phone_n = ""
	gen int hhr_voucher = .
	gen str32 voucher_qr = ""
	gen int corr_voucher = .
	gen str32 voucher_n = ""
	gen int note_roster = .
	gen int calc_elig_count = .
	gen int calc_under5_count = .
	gen int calc_olderchild_count = .
	gen int calc_adult_count = .
	gen int note_elig = .
	gen int note_under5 = .
	gen int note_olderchild = .
	gen int note_adult = .
	gen int visited = .
	gen int notreg = .
		gen str1 notreg_temp = ""
	gen str32 oth_notreg = ""
	gen int hhr_record = .
	gen int rec_seen = .
	gen int rec_elig = .
	gen int rec_itn = .
	gen int calc_rec_itn = .
	gen int hhr_verbal = .
	gen int verbal_elig = .
	gen int verbal_itn = .
	gen int calc_verbal_itn = .
	gen int hhr_u5 = .
	gen int hhr_u5_elig = .
	gen int hhr_olderchild = .
	gen int hhr_olderch_elig = .
	gen int hhr_adult = .
	gen int hhr_adult_elig = .
	gen int calc_hhr_elig_count = .
	gen int note_assessor_flag1 = .
	gen int note_assessor_flag2 = .
	gen int elig_check = .
	gen int calc_hhr_elig_itn = .
	gen int itn_elig = .
	gen recvd_itn = .
	gen visit_check = .
	gen why_noitn_fp = .
		gen str1 noitnfp_temp = ""
	gen str32 oth_noitn_fp = ""
	gen itn_recvd_n = .
	gen calc_itn_recvd = .
	gen calc_itn_correct = .
	gen int reason_mismatch = .
		gen str1 rmm_temp = ""
	gen str32 oth_mismatch = ""
	gen str32 descr_mismatch = ""
	gen citn_n = .
	gen calc_citn_n = .
	gen slept_citn = .
	gen ncitn_n = .
	gen ncitn_n_check = .
	gen slept_ncitn = .
	gen total_itns = .
	gen confirm_total = .
	gen int aware_fp = .
	gen str32 aware_source = ""
	gen int aware_source_1 = .
	gen int aware_source_2 = .
	gen int aware_source_3 = .
	gen int aware_source_4 = .
	gen int aware_source_5 = .
	gen int aware_source_6 = .
	gen int aware_source_7 = .
	gen int aware_source_8 = .
	gen int aware_source_9 = .
	gen int aware_source_96= .
	gen str32 oth_aware_source = ""	
	gen sbc_distrstaff = .
	gen str32 sbc_msg = ""
	gen int sbc_msg_1 = .
	gen int sbc_msg_2 = .
	gen int sbc_msg_3 = .
	gen int sbc_msg_4 = .
	gen int sbc_msg_5 = .
	gen int sbc_msg_6 = .
	gen int sbc_msg_96 = .
	gen str32 oth_sbc_msg = ""
	gen int hh_visit_detail = .
	gen int note_result_abs = .
	gen int note_result_ref = .
	gen int note_farewell_n = .
	gen str32 final_comments = ""
	gen str32 _id = ""
	gen str32 _uuid = ""
	gen str32 _submission_time = ""
	gen str32 _validation_status = ""
	gen str32 _notes = ""
	gen str32 _status = ""
	gen str32 _submitted_by = ""
	gen str32 __version__ = ""
	gen str32 _tags = ""
	gen int _index = .
	
	gen int _indexInd = .
	gen str12 hhid = ""
	gen acc_use = .
	gen nm_use = .


** Create 10 household entries per cluster, with varying responses
	// Probability of response for key questions
		global p_present = 0.98		// P(present)
		global p_participate = 0.98	// P(participate)
		global p_visited = 0.98		// P(HHR visted HH)
		global p_citn13 = 0.96		// P(received campaign ITNs) in Regions 1 and 3
		global p_citn2 = 0.85		// P(received campaign ITNs) in Region 2		
		global p_aware = 0.90		// P(aware of campaign) i.e. 10% have aware_fp==0
		global p_sbc = 0.95			// P(distribution team did other messaging)
		global origin1lat = 10.163560	// Approx centre of Kaduna
		global origin1lon = 7.9101563
		global origin2lat = 11.743681	// Approx centre of Kano
		global origin2lon = 8.5913086
		global origin3lat = 10.606620	// Approx centre of Bauchi
		global origin3lon = 9.6954346

	// Set up geographies
		local r_total=3				// Number of regions
		tokenize 5 6 4				// Number of districts in each region

	// Loop over everything
		foreach reg of num 1/`r_total' {	// Loop for regions
		foreach dis of num 1/`1' {			// Loop for districts
		foreach clus of num 1/6 {			// Loop for clusters
		foreach hh of num 1/10 {			// Loop for households
			
			set obs `=_N + 1'
			replace _index = _n in L
			replace _indexInd = _index in L
			
			// Start and end times
				// Start times are 8:00, 8:30, 9:00 etc from the 6 Oct to 11 Oct 2025 (6 days)
			replace day = 5 + `clus' in L
			replace month = 10 in L
			replace year = 2025 in L
			replace hr = 8 + floor(`hh'/2) in L
			if mod(`hh',2) == 1 in L {
				replace mins = 0 in L
			} 
			else {
				replace mins = 30 in L
			}
		
			replace date_interview = mdyhms(month, day, year, hr, mins, 0) in L
			
			replace mins = mins + 20 + runiformint(1,7) in L
			replace endtime = mdyhms(month, day, year, hr, mins, 0) in L
			
			*replace date_interview = 24019 + `clus' in L	// Two weeks after the end of HHR ;)
			*replace endtime = 24019 + `clus' in L
			
			replace deviceid = "Test data" in L

			// Household identification
			replace region = `reg' in L
			replace district = (`reg'*100) + `dis' in L
			replace subdistrict = . in L
			replace cluster_count = `clus' in L
			replace cluster = (district*100) + `clus' in L
			replace hh_n = `hh' in L
				replace calc_hh_id = (cluster*100) + hh_n in L
			
			// GPS values
					// Set different region origins
						// See origin1lat etc above
					// Add points by district
						// Even numbered (0.05, 0.05) x `dis'
						// Odd numbered (0.05, 0.05) x `dis' x(-1)
					// Add points by cluster
						// Even numbered (0.002, 0.002) x `clus'
						// Odd numbered (0.002, 0.002) x `clus' x(-1)
					// Add points for HH
						// Even numbered (runiform()/10000, runiform()/10000)
						// Odd numbered (runiform()/10000, runiform()/10000) x(-1)
				// Calculate all these parts and add them together for final longitude and latitude values
				// This produces districts and clusters that fall on straight lines, but they are distinct
				
				if region==1 in L {
				replace _geopoint_latitude = ${origin1lat} + ///
											 (0.05 * `dis' * ((-1)^`dis')) + ///
											 (0.002 * `clus' * ((-1)^`clus')) + ///
											 1.5* ((runiform()/10000) * ((-1)^`hh')) in L

				replace _geopoint_longitude = ${origin1lon} + ///
											  (0.1 * `dis' * ((-1)^(`dis'+1))) + ///
											  (0.002 * `clus' * ((-1)^(`clus'+1))) + ///
											  1.5* ((runiform()/10000) * ((-1)^`hh')) in L
				}
				else {
					if region==2 in L {
				replace _geopoint_latitude = ${origin2lat} + ///
											 (0.1 * `dis' * ((-1)^`dis')) + ///
											 (0.002 * `clus' * ((-1)^(`clus'+1))) + ///
											 2* ((runiform()/10000) * ((-1)^`hh')) in L

				replace _geopoint_longitude = ${origin2lon} + ///
											  (0.05 * `dis' * ((-1)^`dis')) + ///
											  (0.002 * `clus' * ((-1)^`clus')) + ///
											  ((runiform()/10000) * ((-1)^`hh')) in L
						
					}
					else {
				replace _geopoint_latitude = ${origin3lat} + ///
											 (0.05 * `dis' * ((-1)^`dis')) + ///
											 (0.002 * `clus' * ((-1)^`clus')) + ///
											 ((runiform()/10000) * ((-1)^`hh')) in L

				replace _geopoint_longitude = ${origin3lon} + ///
											  (0.1 * `dis' * ((-1)^`dis')) + ///
											  (0.002 * `clus' * ((-1)^`clus')) + ///
											  2* ((runiform()/10000) * ((-1)^`hh')) in L
						
					}
				}

			replace _geopoint_altitude = runiformint(5,8) + runiform() in L
			replace _geopoint_precision = runiformint(2,15) + runiform() in L			

			replace _geopoint_latitude = . if runiform()<0.05 in L				// 5% GPS have missing data
			replace _geopoint_longitude = . if missing(_geopoint_latitude) in L
			replace _geopoint_altitude = . if missing(_geopoint_latitude) in L
			replace _geopoint_precision = . if missing(_geopoint_latitude) in L		

			replace reason_nogps = "Test data" if missing(_geopoint_latitude) in L
			replace reason_nogps = "" if !missing(_geopoint_latitude) in L
			
			replace geopoint = "" in L
			
			// Household present?
			replace present = runiform()<$p_present in L
			
				// Responses for present households
				if present==1 in L {
					replace introduced = 1 in L
					
					// Household agrees to participate?
					replace participate = runiform()<$p_participate in L
					
						// Responses for participating households
						if participate==1 in L {

						// Pull in values from the individual/DHS model data
							merge 1:1 _indexInd using "end_ind_hhsummary.dta", keep(match master) nogen
							gsort _index
							replace hhid = hhid_Ind in L
							
							// Digital matching
							replace hohh_name = "Test name" in L
							replace phone_n = "Test number" in L
							replace hhr_voucher = 3 in L			// 3 = No coupon or voucher
							replace voucher_qr = "" in L
							replace corr_voucher = . in L
							replace voucher_n = "" in L
							
							// Section 1. People living in the household
								// Initiated at top of syntax from DHS model data
								// Will call at end of this file to add missing variables

							// Roster count
							replace calc_elig_count = hv012 in L
							replace calc_under5_count = Ncu5 in L
							replace calc_olderchild_count = Noc in L
							replace calc_adult_count = Nadult in L
							
							// Section 2. Outcome of HHR
							// Household visited by HHR team?
							replace visited = runiform()<$p_visited in L
									recode visited (0=98) if runiform()<0.1 in L // Recode 10% No to DKN
								
								// Responses for HHs visited by HHR team
								if visited==1 in L {
									replace notreg = . in L
									replace oth_notreg = "" in L
								
								// Written record
									replace hhr_record = runiform()>1 in L		// Assume no written records
									replace rec_seen = . in L
									replace rec_elig = . in L
									replace rec_itn = . in L									
									replace calc_rec_itn = . in L
								
								// Verbal record
									replace hhr_verbal = runiform()>1 in L		// Assume no verbal recall
									replace verbal_elig = . in L
									replace verbal_itn = . in L
									replace calc_verbal_itn = . in L
								
								// Recall of HH members the previous day
									// Use values pulled in from individual file in first instance
									replace hhr_u5 = calc_under5_count in L
									replace hhr_u5_elig = calc_under5_count in L									
									
									replace hhr_olderchild = calc_olderchild_count in L
									replace hhr_olderch_elig = calc_olderchild_count in L

									replace hhr_adult = calc_adult_count in L
									replace hhr_adult_elig = calc_adult_count in L
									
									replace calc_hhr_elig_count = hhr_u5_elig + hhr_olderch_elig + hhr_adult_elig in L
								
								// Enumerator confirms figures are correct
									replace elig_check = 1 in L
								
								// Calculate number of ITNs based on HHR roster recall
								// Assume 1 ITN for 2 people with cap at 3
									replace calc_hhr_elig_itn = round(calc_hhr_elig_count/2) in L
									replace calc_hhr_elig_itn = 3 if calc_hhr_elig_itn>3 in L
								
								// Calculate itn_elig based on values of calc_*_itn variables
									// Written record > Verbal record > HHR roster recall
									replace itn_elig = calc_rec_itn if missing(itn_elig) in L
									replace itn_elig = calc_verbal_itn if missing(itn_elig) in L
									replace itn_elig = calc_hhr_elig_itn if missing(itn_elig) in L
									
								}	// End of visited=1 section for end-process

							// Why wasn't household visited by HHR team (visited!=0)
							if visited!=1 in L {
								replace notreg_temp = word("1 2 3 8", ceil(runiform()*4)) in L
									replace notreg=1 if notreg_temp=="1" in L
									replace notreg=2 if notreg_temp=="2" in L
									replace notreg=3 if notreg_temp=="3" in L
									replace notreg=8 if notreg_temp=="8" in L
							}

							// Section 3: ITN distribution (Asked to all with participate=1)
							// Household received ITNs from campaign
							replace recvd_itn = runiform()<$p_citn13 if inlist(region,1,3) in L
							replace recvd_itn = runiform()<$p_citn2 if inlist(region,2) in L
								recode visited (0=98) if runiform()<0.1 in L // Recode 10% No to DKN
							
								// Check when visit=0 and recvd_itn=1
									if visited!=1 & recvd_itn==1 in L {
										replace visit_check = runiform()<1 in L		// Assume all Yes
									}
								
								// Why no ITNs from campaign
								if recvd_itn==0 in L {
									if inlist(region,1,3) in L {
										replace noitnfp_temp = word("2 3 4 5 6 8", ceil(runiform()*6)) in L
											// Reduce % of 2 responses
											replace noitnfp_temp="3" if runiform()<0.8 & noitnfp_temp=="2" in L
										replace why_noitn_fp=2 if noitnfp_temp=="2" in L
										replace why_noitn_fp=3 if noitnfp_temp=="3" in L
										replace why_noitn_fp=4 if noitnfp_temp=="4" in L
										replace why_noitn_fp=5 if noitnfp_temp=="5" in L
										replace why_noitn_fp=6 if noitnfp_temp=="6" in L
										replace why_noitn_fp=8 if noitnfp_temp=="8" in L
									}
									if inlist(region,2) in L {
										replace noitnfp_temp = word("1 2 3 4 5 6 8", ceil(runiform()*7)) in L
											// Focus responses on 1 (No DP) and 2 (No ITN recvd at DP)
											gen temp = runiform() in L
											replace noitnfp_temp="1" if inrange(temp,0,0.4) in L
											replace noitnfp_temp="2" if inrange(temp,0.4,0.8) in L
											drop temp
										replace why_noitn_fp=1 if noitnfp_temp=="1" in L
										replace why_noitn_fp=2 if noitnfp_temp=="2" in L
										replace why_noitn_fp=3 if noitnfp_temp=="3" in L
										replace why_noitn_fp=4 if noitnfp_temp=="4" in L
										replace why_noitn_fp=5 if noitnfp_temp=="5" in L
										replace why_noitn_fp=6 if noitnfp_temp=="6" in L
										replace why_noitn_fp=8 if noitnfp_temp=="8" in L
									}
									// calc_itn_recvd
									replace calc_itn_recvd = 0 in L
									// Compare ITNs received with the expected allocation
									replace calc_itn_correct = cond(calc_itn_recvd==itn_elig,1,0) in L
								}
							
								// Households that received ITNs from campaign
								if recvd_itn==1 in L {
									replace itn_recvd_n = Ncitn in L
									
									// Some HHs with hml1<alloc received more citns but lost some
									// Recall that 48% of HHs have hml1<alloc
									gen lostnets = runiform() in L
										replace itn_recvd_n = itn_recvd_n+1 if alloc-hml1==1 & ///
																			inlist(region,1,3) & lostnets<0.65 in L
										replace itn_recvd_n = itn_recvd_n+2 if alloc-hml1==2 & ///
																			inlist(region,1,3) & lostnets<0.30 in L
										replace itn_recvd_n = itn_recvd_n+1 if alloc-hml1==1 & ///
																			region==2 & lostnets<0.35 in L
										replace itn_recvd_n = itn_recvd_n+2 if alloc-hml1==2 & ///
																			region==2 & lostnets<0.15 in L
									drop lostnets										
									
									// calc_itn_recvd
									replace calc_itn_recvd = 0 in L
										replace calc_itn_recvd = itn_recvd_n if !missing(itn_recvd_n) in L
									
									// Compare ITNs received with the expected allocation
									replace calc_itn_correct = cond(calc_itn_recvd==itn_elig,1,0) in L
									
									// Mismatch reaon for calc_elig_itn = 0
									// Need visited==1 here otherwise there is no comparison to be made
									if visited==1 & calc_itn_correct==0 in L {
										if inlist(region,1,3) in L {
											replace rmm_temp = word("1 2 3 4", ceil(runiform()*4)) in L
												replace reason_mismatch=1 if rmm_temp=="1" in L
												replace reason_mismatch=2 if rmm_temp=="2" in L
												replace reason_mismatch=3 if rmm_temp=="3" in L
												replace reason_mismatch=4 if rmm_temp=="4" in L											
										}
										if inlist(region,2) in L {
											replace rmm_temp = word("1 2 3 4", ceil(runiform()*4)) in L
												// Focus responses on 1 (ration) and 2 (ran out)
													gen temp = runiform() in L
													replace rmm_temp="1" if inrange(temp,0,0.4) in L
													replace rmm_temp="2" if inrange(temp,0.4,0.8) in L
													drop temp
												replace reason_mismatch=1 if rmm_temp=="1" in L
												replace reason_mismatch=2 if rmm_temp=="2" in L
												replace reason_mismatch=3 if rmm_temp=="3" in L
												replace reason_mismatch=4 if rmm_temp=="4" in L
										}
										replace reason_mismatch = . if calc_itn_correct==1 in L
										replace oth_mismatch = "" in L
										replace descr_mismatch = "" in L
									}

									// ITN status (for recvd_itn=1)
									replace citn_n = Ncitn in L
									
										// Campaign ITNs for sleeping
										*replace slept_citn = Ncitn in L	
										*	replace slept_citn = Ncitn-1 if runiform()<0.4 in L
										replace acc_use = 2*(Ncitn + Nncitn) in L
										replace nm_use = num_use in L
										if acc_use <= nm_use in L {
											replace slept_citn = Ncitn in L
										}
										else {
											replace slept_citn = nm_use if nm_use < Ncitn in L
											replace slept_citn = Ncitn if nm_use >= Ncitn in L
										}	
								}
								
								// ITN status for all households with participate=1
								replace calc_citn_n = citn_n if recvd_itn==1 in L
									replace calc_citn_n = 0 if recvd_itn!=1 in L
								
								// Non-campaign nets
								replace ncitn_n = Nncitn in L
									replace ncitn_n_check = 1 if Nncitn>5 & !missing(Nncitn) in L

									// Non-campaign ITNs for sleeping
									*replace slept_ncitn = Nncitn if Nncitn>0 in L
									*	replace slept_ncitn = Ncitn-1 if runiform()<0.6 & Nncitn>0 in L
										if acc_use <= nm_use in L {
											if nm_use > (slept_citn*2) {
												replace slept_ncitn = Nncitn if Nncitn>0 in L
											}
											else {
												replace slept_ncitn = 0 in L
											}
										}
										else {
											replace slept_ncitn = Nncitn if Nncitn>0 & (slept_citn*2)<nm_use in L
											replace slept_ncitn = 0 if Nncitn>0 & (slept_citn*2)>=nm_use in L
											*replace slept_ncitn = Ncitn-1 if runiform()<0.6 & Nncitn>0 in L
										}	
									
								
								// Total ITNs in HH
								replace total_itns = calc_citn_n + ncitn_n in L
								
							// Section 4: Campaign knowledge and SBC exposure
							// Aware of date and location of distribution
							replace aware_fp = runiform()<$p_aware in L
								gen temp = runiform() in L
									recode aware_fp (1=2) if inrange(temp,0,0.1) in L
									recode aware_fp (1=3) if inrange(temp,0.8,1) in L
								drop temp
					
								// Source of distribution information
								replace aware_source = "" in L
								if aware_fp!=0 in L {
									replace aware_source_1 = runiform()<0.9 in L
									replace aware_source_2 = runiform()<0.8 in L
									replace aware_source_3 = runiform()<0.8 in L
									replace aware_source_4 = runiform()<0.5 in L
									replace aware_source_5 = runiform()<0.4 in L
									replace aware_source_6 = runiform()<0.8 in L
									replace aware_source_7 = runiform()<0.3 in L
									replace aware_source_8 = runiform()<0.4 in L
									replace aware_source_9 = runiform()<0.6 in L
									replace aware_source_96 = runiform()<0.1 in L
										replace oth_aware_source = "Test SBC message" if aware_source_96==1 in L	
								}								
								
							// Distribution staff gave malaria information?
							replace sbc_distrstaff = runiform()<$p_sbc in L
								recode sbc_distrstaff (0=98) if runiform()<0.2 in L					// Recode 20% No to DKN
								replace sbc_distrstaff = . if recvd_itn!=1 & why_noitn_fp==1 in L	// Missing if no campaign ITN
																									// & reason is not "no distrubtion"
							
								// Type of message
								replace sbc_msg = "" in L
								if sbc_distrstaff==1 in L {
									replace sbc_msg_1 = runiform()<0.9 in L
									replace sbc_msg_2 = runiform()<0.7 in L
									replace sbc_msg_3 = runiform()<0.8 in L
									replace sbc_msg_4 = runiform()<0.8 in L
									replace sbc_msg_5 = runiform()<0.8 in L
									replace sbc_msg_6 = runiform()<0.6 in L
									replace sbc_msg_96 = runiform()<0.1 in L
										replace oth_sbc_msg = "Test SBC message" if sbc_msg_96==1 in L	
								}
							
							drop hv012-Nadult hhid_Ind num_use		// Clear for merge

							}	// Participate = 1
							
						}	// Present = 1
					
					// Final comments
					replace final_comments = "" in L
					
					// Household visit results
					replace hh_visit_detail = 1 if participate==1 in L
					replace hh_visit_detail = 2 if present!=1 in L
					replace hh_visit_detail = 3 if present==1 & participate!=1 in L
					
					// For all households
					replace _id = "" in L
					replace _uuid = "" in L
					replace _submission_time = "" in L
					replace _validation_status = "" in L
					replace _notes = "" in L
					replace _status = "" in L
					replace _submitted_by = "" in L
					replace __version__ = "" in L
					replace _tags = "" in L
					
					replace _indexInd = 900+_index in L		// Clear previous value for next merge
				}											// Loop for household
			}												// Loop for cluster	
		}													// Loop for district
		mac shift											// Shift the tokenized count of districts
	}														// Loop for region


tab1 present participate visited notreg calc_hhr_elig_itn itn_elig recvd_itn calc_itn_correct reason_mismatch citn_n slept_citn ncitn_n slept_ncitn aware_fp sbc_distrstaff



** Create additional clean visited records to bring total to 10 HHs visited per cluster

	// Need to understand where there are missing interviews
	tab cluster if participate!=1
	list cluster present participate if participate!=1, sepby(cluster)
		// Max in one cluster = 3
		// Will create 3 additional cases per cluster with participate=1 to fill the gaps
		// Then append to cases above so each cluster has at least 10 full interviews
		// Then drop excess cases

	// To do this, go back to Ind file and add 3 x 6 x 15 = 270 cases
	// Will run these two steps separately, so the original 900 cases remain as at present

	tab present region
		// 26 HHs not present
	tab participate region
		// +18 HHs do not participate
	tab participate present, m
		
		// 44 HHs to add

		codebook cluster
		bysort cluster: egen complete=total(participate)
		bysort cluster: gen clus_n=_n
		
			tab complete if clus_n==1, m
				// 57 clusters complete; 24 with 9 records; 7 with 8 records; 2 with 7 records

	// Create 270 perfect records added to same data
		// HH number runs from 11 to 13
	// Drop new records if the HH number is above the number of records required
		// So clusters with 10 participating records (0 required) drop all HHs (11 to 17)
		// Clusters with 9 participating records (1 required) keep HH 11 and drop 12-13
		// etc

	// Main HH-level code from above, copied here, edited to these HHs have no inconsistencies
	// Set up geographies
		local r_total=3				// Number of regions
		tokenize 5 6 4				// Number of districts in each region

	// Loop over everything
		foreach reg of num 1/`r_total' {	// Loop for regions
		foreach dis of num 1/`1' {			// Loop for districts
		foreach clus of num 1/6 {			// Loop for clusters
		foreach hh of num 1/3 {			// Loop for households

			set obs `=_N + 1'
			replace _index = _n in L
			replace _indexInd = _index +2000 in L
			
			// Start and end times
				// Start times are 15:00, 15:30, 16:00 etc from the 6 Oct to 11 Oct 2025 (6 days)
			replace day = 5 + `clus' in L
			replace month = 10 in L
			replace year = 2025 in L
			replace hr = 15 + floor(`hh'/2) in L
			if mod(`hh',2) == 1 in L {
				replace mins = 0 in L
			} 
			else {
				replace mins = 30 in L
			}
		
			replace date_interview = mdyhms(month, day, year, hr, mins, 0) in L
			
			replace mins = mins + 20 + runiformint(1,7) in L
			replace endtime = mdyhms(month, day, year, hr, mins, 0) in L
			
			*replace date_interview = 24019 + `clus' in L	// Two weeks after the end of HHR ;)
			*replace endtime = 24019 + `clus' in L
			
			replace deviceid = "Test data" in L

			// Household identification
			replace region = `reg' in L
			replace district = (`reg'*100) + `dis' in L
			replace subdistrict = . in L
			replace cluster_count = `clus' in L
			replace cluster = (district*100) + `clus' in L
			replace hh_n = 10+`hh' in L								// HH count starts at 11 now
				replace calc_hh_id = (cluster*100) + hh_n in L
			
			// GPS values
				if region==1 in L {
				replace _geopoint_latitude = ${origin1lat} + ///
											 (0.05 * `dis' * ((-1)^`dis')) + ///
											 (0.002 * `clus' * ((-1)^`clus')) + ///
											 1.5* ((runiform()/10000) * ((-1)^`hh')) in L

				replace _geopoint_longitude = ${origin1lon} + ///
											  (0.1 * `dis' * ((-1)^(`dis'+1))) + ///
											  (0.002 * `clus' * ((-1)^(`clus'+1))) + ///
											  1.5* ((runiform()/10000) * ((-1)^`hh')) in L
				}
				else {
					if region==2 in L {
				replace _geopoint_latitude = ${origin2lat} + ///
											 (0.1 * `dis' * ((-1)^`dis')) + ///
											 (0.002 * `clus' * ((-1)^(`clus'+1))) + ///
											 2* ((runiform()/10000) * ((-1)^`hh')) in L

				replace _geopoint_longitude = ${origin2lon} + ///
											  (0.05 * `dis' * ((-1)^`dis')) + ///
											  (0.002 * `clus' * ((-1)^`clus')) + ///
											  ((runiform()/10000) * ((-1)^`hh')) in L
						
					}
					else {
				replace _geopoint_latitude = ${origin3lat} + ///
											 (0.05 * `dis' * ((-1)^`dis')) + ///
											 (0.002 * `clus' * ((-1)^`clus')) + ///
											 ((runiform()/10000) * ((-1)^`hh')) in L

				replace _geopoint_longitude = ${origin3lon} + ///
											  (0.1 * `dis' * ((-1)^`dis')) + ///
											  (0.002 * `clus' * ((-1)^`clus')) + ///
											  2* ((runiform()/10000) * ((-1)^`hh')) in L
						
					}
				}

			replace _geopoint_altitude = runiformint(5,8) + runiform() in L
			replace _geopoint_precision = runiformint(2,15) + runiform() in L			

			replace _geopoint_latitude = . if runiform()<0.05 in L				// 5% GPS have missing data
			replace _geopoint_longitude = . if missing(_geopoint_latitude) in L
			replace _geopoint_altitude = . if missing(_geopoint_latitude) in L
			replace _geopoint_precision = . if missing(_geopoint_latitude) in L		

			replace reason_nogps = "Test data" if missing(_geopoint_latitude) in L
			replace reason_nogps = "" if !missing(_geopoint_latitude) in L
			
			replace geopoint = "" in L
			
			// Household present?
			replace present = runiform()<1 in L					// All present
			
				// Responses for present households
				replace introduced = 1 in L
					
					// Household agrees to participate?
					replace participate = runiform()<1 in L		// All participate
					
						// Responses for participating households
						
						// Pull in values from the individual/DHS model data
							merge 1:1 _indexInd using "end_ind_hhsummary_270cases.dta", keep(match master) nogen
							gsort _index
							replace hhid = hhid_Ind in L

							// Digital matching
							replace hohh_name = "Test name" in L
							replace phone_n = "Test number" in L
							replace hhr_voucher = 3 in L		// 3 = No coupon or voucher
							replace voucher_qr = "" in L
							replace corr_voucher = . in L
							replace voucher_n = "" in L
							
							// Section 1. People living in the household
								// Will call at end of this file to add missing variables

							// Roster count
							replace calc_elig_count = hv012 in L
							replace calc_under5_count = Ncu5 in L
							replace calc_olderchild_count = Noc in L
							replace calc_adult_count = Nadult in L
							
							// Section 2. Outcome of HHR
							// Household visited by HHR team?
							replace visited = runiform()<1 in L	// All visited			
									recode visited (0=98) if runiform()<0.1 in L
								
								// Responses for HHs visited by HHR team
								if visited==1 in L {
									replace notreg = . in L
									replace oth_notreg = "" in L
								
								// Written record
									replace hhr_record = runiform()>1 in L		// Assume no written records
									replace rec_seen = . in L
									replace rec_elig = . in L
									replace rec_itn = . in L									
									replace calc_rec_itn = . in L
								
								// Verbal record
									replace hhr_verbal = runiform()>1 in L		// Assume no verbal recall
									replace verbal_elig = . in L
									replace verbal_itn = . in L
									replace calc_verbal_itn = . in L
								
								// Recall of HH members the previous day
									// Use values pulled in from individual file in first instance
									replace hhr_u5 = calc_under5_count in L
									replace hhr_u5_elig = calc_under5_count in L									
									
									replace hhr_olderchild = calc_olderchild_count in L
									replace hhr_olderch_elig = calc_olderchild_count in L

									replace hhr_adult = calc_adult_count in L
									replace hhr_adult_elig = calc_adult_count in L
									
									replace calc_hhr_elig_count = hhr_u5_elig + hhr_olderch_elig + hhr_adult_elig in L
								
								// Enumerator confirms figures are correct
									replace elig_check = 1 in L
								
								// Calculate number of ITNs based on HHR roster recall
								// Assume 1 ITN for 2 people with cap at 3
									replace calc_hhr_elig_itn = round(calc_hhr_elig_count/2) in L
									replace calc_hhr_elig_itn = 3 if calc_hhr_elig_itn>3 in L
								
								// Calculate itn_elig based on values of calc_*_itn variables
									// Written record > Verbal record > HHR roster recall
									replace itn_elig = calc_rec_itn if missing(itn_elig) in L
									replace itn_elig = calc_verbal_itn if missing(itn_elig) in L
									replace itn_elig = calc_hhr_elig_itn if missing(itn_elig) in L
									
								}	// End of visited=1 section for end-process
									replace notreg = . in L

							// Section 3: ITN distribution (Asked to all with participate=1)
							// Household received ITNs from campaign
							replace recvd_itn = runiform()<1 if inlist(region,1,3) in L		// All yes
							replace recvd_itn = runiform()<1 if inlist(region,2) in L		// All yes
								recode visited (0=98) if runiform()<0.1 in L
								replace visit_check = . in L									

								replace why_noitn_fp = . in L
								
								// Households that received ITNs from campaign
								*if recvd_itn==1 in L {
									replace itn_recvd_n = Ncitn in L
									
									// Some HHs with hml1<alloc received more citns but lost some
									gen lostnets = runiform() in L
										replace itn_recvd_n = itn_recvd_n+1 if alloc-hml1==1 & ///
																			inlist(region,1,3) & lostnets<0.65 in L
										replace itn_recvd_n = itn_recvd_n+2 if alloc-hml1==2 & ///
																			inlist(region,1,3) & lostnets<0.30 in L
										replace itn_recvd_n = itn_recvd_n+1 if alloc-hml1==1 & ///
																			region==2 & lostnets<0.35 in L
										replace itn_recvd_n = itn_recvd_n+2 if alloc-hml1==2 & ///
																			region==2 & lostnets<0.15 in L
									drop lostnets										
									
									// calc_itn_recvd
									replace calc_itn_recvd = 0 in L
										replace calc_itn_recvd = itn_recvd_n if !missing(itn_recvd_n) in L
									
									// Compare ITNs received with the expected allocation
									replace calc_itn_correct = cond(calc_itn_recvd==itn_elig,1,0) in L
									
									// Mismatch reaon for calc_elig_itn = 0
									// Need visited==1 here otherwise there is no comparison to be made
									if visited==1 & calc_itn_correct==0 in L {
										if inlist(region,1,3) in L {
											replace rmm_temp = word("1 2 3 4", ceil(runiform()*4)) in L
												replace reason_mismatch=1 if rmm_temp=="1" in L
												replace reason_mismatch=2 if rmm_temp=="2" in L
												replace reason_mismatch=3 if rmm_temp=="3" in L
												replace reason_mismatch=4 if rmm_temp=="4" in L											
										}
										if inlist(region,2) in L {
											replace rmm_temp = word("1 2 3 4", ceil(runiform()*4)) in L
												// Focus responses on 1 (ration) and 2 (ran out)
													gen temp = runiform() in L
													replace rmm_temp="1" if inrange(temp,0,0.4) in L
													replace rmm_temp="2" if inrange(temp,0.4,0.8) in L
													drop temp
												replace reason_mismatch=1 if rmm_temp=="1" in L
												replace reason_mismatch=2 if rmm_temp=="2" in L
												replace reason_mismatch=3 if rmm_temp=="3" in L
												replace reason_mismatch=4 if rmm_temp=="4" in L
										}
										replace reason_mismatch = . in L
										replace oth_mismatch = "" in L
										replace descr_mismatch = "" in L
									}

									// ITN status (for recvd_itn=1)
									replace citn_n = Ncitn in L
									
										// Campaign ITNs for sleeping
										replace acc_use = 2*(Ncitn + Nncitn) in L
										replace nm_use = num_use in L
										if acc_use <= nm_use in L {
											replace slept_citn = Ncitn in L
										}
										else {
											replace slept_citn = nm_use if nm_use < Ncitn in L
											replace slept_citn = Ncitn if nm_use >= Ncitn in L
										}	
								*}
								
								// ITN status for all households with participate=1
								replace calc_citn_n = citn_n if recvd_itn==1 in L
									replace calc_citn_n = 0 if recvd_itn!=1 in L
								
								// Non-campaign nets
								replace ncitn_n = Nncitn in L
									replace ncitn_n_check = 1 if Nncitn>5 & !missing(Nncitn) in L

									// Non-campaign ITNs for sleeping
									*replace slept_ncitn = Nncitn if Nncitn>0 in L
									*	replace slept_ncitn = Ncitn-1 if runiform()<0.6 & Nncitn>0 in L
										if acc_use <= nm_use in L {
											if nm_use > (slept_citn*2) {
												replace slept_ncitn = Nncitn if Nncitn>0 in L
											}
											else {
												replace slept_ncitn = 0 in L
											}
										}
										else {
											replace slept_ncitn = Nncitn if Nncitn>0 & (slept_citn*2)<nm_use in L
											replace slept_ncitn = 0 if Nncitn>0 & (slept_citn*2)>=nm_use in L
											*replace slept_ncitn = Ncitn-1 if runiform()<0.6 & Nncitn>0 in L
										}	
								
								// Total ITNs in HH
								replace total_itns = calc_citn_n + ncitn_n in L
								
							// Section 4: Campaign knowledge and SBC exposure
							// Aware of date and location of distribution
							replace aware_fp = runiform()<1 in L			// All yes
								gen temp = runiform() in L
									recode aware_fp (1=2) if inrange(temp,0,0.1) in L
									recode aware_fp (1=3) if inrange(temp,0.8,1) in L
								drop temp
					
								// Source of distribution information
								replace aware_source = "" in L
								if aware_fp!=0 in L {
									replace aware_source_1 = runiform()<0.9 in L
									replace aware_source_2 = runiform()<0.8 in L
									replace aware_source_3 = runiform()<0.8 in L
									replace aware_source_4 = runiform()<0.5 in L
									replace aware_source_5 = runiform()<0.4 in L
									replace aware_source_6 = runiform()<0.8 in L
									replace aware_source_7 = runiform()<0.3 in L
									replace aware_source_8 = runiform()<0.4 in L
									replace aware_source_9 = runiform()<0.6 in L
									replace aware_source_96 = runiform()<0.1 in L
										replace oth_aware_source = "Test SBC message" if aware_source_96==1 in L	
								}								
								
							// Distribution staff gave malaria information?
							replace sbc_distrstaff = runiform()<1 in L		// All yes	
								recode sbc_distrstaff (0=98) if runiform()<0.2 in L
								replace sbc_distrstaff = . if recvd_itn!=1 & why_noitn_fp==1 in L	// Missing if no campaign ITN
																									// & reason is not "no distrubtion"
							
								// Type of message
								replace sbc_msg = "" in L
								if sbc_distrstaff==1 in L {
									replace sbc_msg_1 = runiform()<0.9 in L
									replace sbc_msg_2 = runiform()<0.7 in L
									replace sbc_msg_3 = runiform()<0.8 in L
									replace sbc_msg_4 = runiform()<0.8 in L
									replace sbc_msg_5 = runiform()<0.8 in L
									replace sbc_msg_6 = runiform()<0.6 in L
									replace sbc_msg_96 = runiform()<0.1 in L
										replace oth_sbc_msg = "Test SBC message" if sbc_msg_96==1 in L	
								}
							
							drop hv012-Nadult hhid_Ind num_use		// Clear for merge

					// Final comments
					replace final_comments = "" in L
					
					// Household visit results
					replace hh_visit_detail = 1 if participate==1 in L
					replace hh_visit_detail = 2 if present!=1 in L
					replace hh_visit_detail = 3 if present==1 & participate!=1 in L
					
					// For all households
					replace _id = "" in L
					replace _uuid = "" in L
					replace _submission_time = "" in L
					replace _validation_status = "" in L
					replace _notes = "" in L
					replace _status = "" in L
					replace _submitted_by = "" in L
					replace __version__ = "" in L
					replace _tags = "" in L
					
					replace _indexInd = 3000+_index in L	// Clear previous value for next merge
				}											// Loop for household
			}												// Loop for cluster	
		}													// Loop for district
		mac shift											// Shift the tokenized count of districts
	}														// Loop for region



	// Now drop records that aren't required
		gen required = 10 + (10-complete)
			// 270 missing values, as expected
		
		// Carry required over to the new records
		bysort cluster: egen req_temp = max(required)
			replace required = req_temp if missing(required)
		
		drop if hh_n>required
			// 226 dropped (44 kept, as expected)



** Check data set
	
	tab district region, m
	tab district region if participate==1, m
	
		tab region present, r				// 2.8% not present
		tab region participate, r			// 2.0% not participate
		tab region participate, r m
		tab region visited, r				// 1.1% not visited ny HHR team
		
		tab region recvd_itn, r
		
		/*
				   |       recvd_itn
			region |         0          1 |     Total
		-----------+----------------------+----------
				 1 |        16        284 |       300 
				   |      5.33      94.67 |    100.00 	Okay
		-----------+----------------------+----------
				 2 |        53        307 |       360 
				   |     14.72      85.28 |    100.00 	Poor
		-----------+----------------------+----------
				 3 |         8        232 |       240 
				   |      3.33      96.67 |    100.00 	Okay
		-----------+----------------------+----------
			 Total |        77        823 |       900 
				   |      8.56      91.44 |    100.00 
		*/
		
		tab region calc_itn_correct, r
		/*
				   |   calc_itn_correct
			region |         0          1 |     Total
		-----------+----------------------+----------
				 1 |        67        217 |       284 
				   |     23.59      76.41 |    100.00 	Poor
		-----------+----------------------+----------
				 2 |       135        172 |       307 
				   |     43.97      56.03 |    100.00 	Bad
		-----------+----------------------+----------
				 3 |        32        200 |       232 
				   |     13.79      86.21 |    100.00 	Better
		-----------+----------------------+----------
			 Total |       234        589 |       823 
				   |     28.43      71.57 |    100.00 
		*/
		
		tab region calc_itn_recvd, r
		/*
				   |          calc_itn_recvd
			region |         1          2          3 |     Total
		-----------+---------------------------------+----------
				 1 |        62         92        130 |       284 
				   |     21.83      32.39      45.77 |    100.00 
		-----------+---------------------------------+----------
				 2 |       100        105        102 |       307 
				   |     32.57      34.20      33.22 |    100.00 
		-----------+---------------------------------+----------
				 3 |        27         70        135 |       232 
				   |     11.64      30.17      58.19 |    100.00 
		-----------+---------------------------------+----------
			 Total |       189        267        367 |       823 
				   |     22.96      32.44      44.59 |    100.00 
		*/


** Final variable edits prior to saving

	drop complete clus_n required req_temp notreg_temp noitnfp_temp rmm_temp acc_use nm_use
	drop day month year hr mins cluster_count
	gsort calc_hh_id
	format date_interview endtime %tc
	

	** Save hhid values of participating HHs to pull their Ind data
	codebook hhid calc_hh_id _index
	preserve
		keep if participate==1
		keep hhid calc_hh_id _index
		save "end_hhid_participate.dta", replace
	restore


** Save files
	
	drop hhid _indexInd

	save "0b_endprocess_dummy_hh.dta", replace
	export 	excel using "0b_endprocess_dummy_data", ///
			sheet("End-process assessment of distr", replace) firstrow(var) nolabel date("%tc")





***************************
** Individual-level data **
***************************

** Append the two Ind files with all HHs that enter the HH data

	// Pull in data
	use "end_ind_900cases.dta", replace
	append using "end_ind_270cases.dta"


	// Set required variables
	keep hhid_Ind res_no stay gender age_y use_itn hv012 Ncitn Nncitn
	
	ren hhid_Ind hhid
	
	gen long calc_id_field = .
	gen name = ""
	gen idp = .
	gen age_m = .
	gen pregnant = .
	gen eligible = .
	gen calc_allelig = .
	gen calc_under5 = .
	gen calc_olderchild = .
	gen calc_adult = .
	gen reason_noitn = .
	gen oth_noitn = ""
	gen detailed_reason_noitn = ""

	gen str32 _id = ""
	gen str32 _uuid = ""
	gen str32 _submission_time = ""
	gen str32 _validation_status = ""
	gen str32 _notes = ""
	gen str32 _status = ""
	gen str32 _submitted_by = ""
	gen str32 __version__ = ""
	gen str32 _tags = ""
		
	gen _parent_table_name = "End-process assessment of distr"

	order _id _uuid _submission_time _validation_status _notes _status _submitted_by __version__ _tags, last

	// Merge HH-level flag to identify interviewed households
	merge m:1 hhid using "end_hhid_participate.dta"
		// 1666 cases in master only from 270 HHs that aren't in the final data - Okay
		codebook hhid if _m==3	// 900 HH matches, with 5,117 individuals
		keep if _m==3
		drop _m

	codebook hhid calc_hh_id _index
		// Okay
	
	ren _index _parent_index

	order hhid calc_hh_id res_no name calc_id_field idp gender age_y age_m pregnant eligible calc*, first


	// res_no
	codebook res_no
		tab res_no, m
	
	
	// Names, aligned with gender
	global males "Emeka Chinedu Ibrahim Tunde Segun Babatunde Femi Sani Musa Kunle Chuka Obinna Oluwaseun Ahmed Yusuf"
	global females "Chioma Amina Ngozi Funke Yetunde Bisi Hauwa Zainab Ada Kemi Ndidi Latifat Rukayat Halima Fatima"
	
	global n_male : word count $males
	global n_female  : word count $females
	
		// Generate random index value and pull name at that position from appropriate list
		gen _u_name = runiform()
		gen _idxm   = ceil(_u_name*$n_male)
		gen _idxf   = ceil(_u_name*$n_female)

		forvalues i = 1/$n_male {
			replace name = word("$males", `i') if gender==1 & _idxm==`i'
		}
		forvalues j = 1/$n_female {
			replace name = word("$females$", `j') if gender==2 & _idxf==`j'
		}

		drop _u_name _idxm _idxf


	// calc_id_field
	codebook calc_hh_id
	replace calc_id_field = (calc_hh_id*100) + res_no
		gsort calc_id_field
		list calc_hh_id res_no calc_id_field in 1/20, sepby(calc_hh_id)


	// IDP / Vulnerable group
	replace idp = runiform()>1		// Assume all "No"
	
	
	// Gender
	codebook gender
	

	// Ages
	codebook age_y
		replace age_m = round(runiform(1,11)) if age_y==0
		tab age_m, m
	

	// Pregnant (women aged [15,49])
	replace pregnant = runiform()<0.06 if gender==2 & inrange(age_y,15,49)
		tab pregnant, m
		tab pregnant if gender==2 & inrange(age_y,15,49)


	// Eligible and associated flags
	replace eligible = runiform()<1		// All "Yes" for now
		tab eligible

		replace calc_allelig = 1 if eligible == 1
		replace calc_under5 = 1 if eligible == 1 & age_y<5
		replace calc_olderchild = 1 if eligible == 1 & inrange(age_y,5,17)
		replace calc_adult = 1 if eligible == 1 & inrange(age_y,18,95)


	// Index for this table
	gsort calc_id_field
		gen _index = _n
	

	// Stay
	codebook stay
		lab drop HV103_12


	// ITN use
	tab stay use_itn, m
		recode stay (0=1) if use_itn==1		// Recode 12 cases to match ITN use which is already in HH data


	// Reason ITN not used
	gen temp = Ncitn + Nncitn
		tab hv012 temp if use_itn==0
	
	codebook reason_noitn
		gen _u = runiform() if stay==1 & use_itn==0
			// First assign reasons that are not related to net access
			replace reason_noitn = 2 if !missing(_u) & _u<0.15				// Smell
			replace reason_noitn = 3 if !missing(_u) & inrange(_u,0.15,0.35)	// Too hot
			replace reason_noitn = 4 if !missing(_u) & inrange(_u,0.35,0.65)	// No malaria
			replace reason_noitn = 5 if !missing(_u) & inrange(_u,0.65,0.75)	// No mosis
			replace reason_noitn = 6 if !missing(_u) & inrange(_u,0.75,0.95)	// Don't like using
			*replace reason_noitn = 7 if !missing(_u) & _u>=0.98				// Slept outside
			replace reason_noitn = 98 if !missing(_u) & inrange(_u,0.95,0.97)	// DKN
			replace reason_noitn = 96 if !missing(_u) & _u>=0.97 & _u<1			// Other
				replace oth_noitn = "Test reason" if reason_noitn == 96
		
			// Now add net access as the most common reason, overwriting earlier reasons
			replace _u = runiform() if stay==1 & use_itn==0
				replace reason_noitn = 1 if !missing(_u) & _u<0.3 & hv012>temp

		tab reason_noitn
		
			// Introduce some regional variation in responses
			gen region = substr(string(calc_hh_id),1,1)
			codebook region
			tab reason_noitn region, col
			
			replace _u = runiform() if !missing(reason_noitn)
				recode reason_noitn (1=4) if _u < 0.3 & region=="1"
				recode reason_noitn (4=1) if _u < 0.3 & region=="2"
				recode reason_noitn (1=3) if _u < 0.3 & region=="3"
			
			tab reason_noitn region, col
			drop _u

	replace detailed_reason_noitn = "Test detailed reason" if !missing(reason_noitn)


** Final variable edits prior to saving
	
	drop 	hhid calc_hh_id hv012 Ncitn Nncitn temp region
	lab drop _all
	

** Save files
	
	compress
	save "0b_endprocess_dummy_ind.dta", replace
	export 	excel using "0b_endprocess_dummy_data", ///
			sheet("repeat_hh_residents", replace) firstrow(var) nolabel date("%tc")

