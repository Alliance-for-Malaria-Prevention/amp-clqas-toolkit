** OPITACA AMP Assessments using cLQAS
** Generate dummy data for HHR in-process assessment to run on adaptable R scripts

* Overview of HHR design
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
	
* Started: 04 Nov 2025


****************
** Change Log **
****************

* Date
	// Activity

/*

runiformint(a,b) → draws discrete integers uniformly between a and b (inclusive)
rnormal(mean, sd) → draws from a normal (Gaussian) distribution
rbinomial(n, p) → draws from a binomial distribution
rpoisson(lambda) → draws from a Poisson distribution

gen region = word("North South East West", ceil(runiform()*4))
gen head_gender = cond(runiform()<0.7,"Male","Female")

set obs `=_N + 1'
replace var1 = "NewName" in L
replace var2 = 2025 in L
replace var3 = 1 if _n == _N

*/

**************************
** Household-level data **
**************************

** Initiate file

	cd "C:\Users\steve.poyer\OneDrive - Tropical Health\Projects - Open\C033 - OPITACA\60 - Implementation\WS3 - Data and cLQAS\TH adaptable tools\Analysis scripts\clqas-tools\Dummy data\"
	dir
	clear
	
	set seed 1357

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
	gen int calc_rec_elig = .
	gen int hhr_verbal = .
	gen int verbal_elig = .
	gen int calc_verbal_elig = .
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
	gen int calc_elig_hhr = .
	gen int calc_elig_correct = .
	gen int note_elig_correct_yes = .
	gen int note_elig_correct_no = .
	gen int reason_mismatch = .
		gen str1 rmm_temp = ""
	gen str32 oth_mismatch = ""
	gen str32 descr_mismatch = ""
	gen int aware = .
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
	gen int info_date = .
	gen int correct_date = .
	gen int info_loc = .
	gen int correct_loc = .
	gen int sbc_hhrstaff = .
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



** Create 10 household entries per cluster, with varying responses
	// Probability of response for key questions
		global p_present = 0.96		// P(present)
		global p_participate = 0.92	// P(participate)
		global p_visited1 = 0.93	// P(HHR visted HHs in cluster 1) 
		global p_visited2 = 0.98	// P(HHR visted HHs in other clusters)
		global p_aware = 0.98		// P(aware of campaign)
		global p_date = 0.95		// P(HHR team said campaign date)
		global p_corrdate = 0.85	// P(HH say correct date)
		global p_loc	= 0.95		// P(HHR team said correct location)
		global p_corrloc = 0.92		// P(HH say correct location)
		global p_sbc = 0.90			// P(HHR team did other messaging)
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

			// Start and end times
				// Start times are 8:00, 8:30, 9:00 etc from the 16 Sep to 21 Sep 2025 (6 days)
			replace day = 15 + `clus' in L
			replace month = 9 in L
			replace year = 2025 in L
			replace hr = 8 + floor(`hh'/2) in L
			if mod(`hh',2) == 1 in L {
				replace mins = 0 in L
			} 
			else {
				replace mins = 30 in L
			}
		
			replace date_interview = mdyhms(month, day, year, hr, mins, 0) in L
			
			replace mins = mins + 15 + runiformint(1,11) in L
			replace endtime = mdyhms(month, day, year, hr, mins, 0) in L
			
			*replace date_interview = 23999 + `clus' in L	// 23999 is 15 Sep 2025 so this is 16 Sep for Cluster 1
			*replace endtime = 23999 + `clus' in L
			
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

			replace _geopoint_latitude = . if runiform()<0.05 in L
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
							
							// Digital matching
							replace hohh_name = "Test name" in L
							replace phone_n = "Test number" in L
							replace hhr_voucher = 3 in L			// 3 = No coupon or voucher
							replace voucher_qr = "" in L
							replace corr_voucher = . in L
							replace voucher_n = "" in L
							
							// Section 1. People living in the household
								// Generated later from roster count results
								// For eligible HHs (hh_visit_detail=1)
								// Method:
									// For all participate=1 households, drop all variables apart from sum of HH roster
										// (Might need to add another set of calc_ that brings in the total number, not just eligible)
									// Expand on number of u5s, older children and adults so the total number of rows equals number of people in HH
									// Then flag cases as u5, older child, adult
									// Stock name
									// Randomise gender
									// Randomise age within integer bounds by age group
									// Make all eligible
										// (For now, might need to add some ineligible in later)
							
							// Roster count
							replace calc_elig_count = rpoisson(5) in L
								replace calc_elig_count = 1 if calc_elig_count == 0 in L
							replace calc_adult_count = rpoisson(2) in L
								replace calc_adult_count = 1 if calc_adult_count == 0 in L
							replace calc_under5_count = rpoisson(2) in L
							replace calc_olderchild_count = calc_elig_count - calc_adult_count - calc_under5_count in L
								if calc_olderchild_count < 0 in L {
									replace calc_olderchild_count = 0 in L
									if calc_elig_count >= 2  in L {
										replace calc_adult_count = 2 in L
										replace calc_under5_count = calc_elig_count - calc_adult_count in L
									}
									else if calc_elig_count < 2  in L {
										replace calc_adult_count = 1 in L
										replace calc_under5_count = calc_elig_count - calc_adult_count in L
									}
								}
							
							// Section 2. Outcome of HHR
							// Household visited by HHR team?
							if `clus'==1 in L {
								replace visited = runiform()<$p_visited1 in L
								}
								else replace visited = runiform()<$p_visited2 in L
									recode visited (0=98) if runiform()<0.1 in L // Recode 10% No to DKN
								
								// Responses for HHs visited by HHR team
								if visited==1 in L {
									replace notreg = . in L
									replace oth_notreg = "" in L
								
								// Written record
									replace hhr_record = runiform()>1 in L		// Assume no written records
									replace rec_seen = . in L
									replace rec_elig = . in L
									replace calc_rec_elig = . in L
								
								// Verbal record
									replace hhr_verbal = runiform()>1 in L		// Assume no verbal recall
									replace verbal_elig = . in L
									replace calc_verbal_elig = . in L
								
								// Recall of HH members the previous day
									// Chance of error varies by district and cluster number
									*gen x4 = (runiform() + (region/10) + ((6-cluster_count)/20))
									*su x4, detail
									// Use 95% value across all regions/clusters as the cut-off
									// Really chuffed with this - see tables copied at end of code
									local u5_same = (runiform() + (`reg'/10) + ((6-`clus')/20))<1.28
									local u5_delta = runiform()<0.5
										if `u5_same' == 1 {
											replace hhr_u5_elig = calc_under5_count in L
											replace hhr_u5 = calc_under5_count in L
										}
										else {
											replace hhr_u5_elig = calc_under5_count - 1 if `u5_delta'==0 in L
												replace hhr_u5_elig = 0 if hhr_u5_elig<0 in L
											replace hhr_u5_elig = calc_under5_count + 1 if `u5_delta'==1 in L
											replace hhr_u5 = calc_under5_count in L
												replace hhr_u5 = hhr_u5_elig if hhr_u5_elig > calc_under5_count in L
										}

									local oc_same = (runiform() +  (`reg'/10) + ((6-`clus')/20))<1.28
									local oc_delta = runiform()<0.5
										if `oc_same' == 1 {
											replace hhr_olderch_elig = calc_olderchild_count in L
											replace hhr_olderchild = calc_olderchild_count in L
										}
										else {
											replace hhr_olderch_elig = calc_olderchild_count - 1 if `oc_delta'==0 in L
												replace hhr_olderch_elig = 0 if hhr_olderch_elig<0 in L
											replace hhr_olderch_elig = calc_olderchild_count + 1 if `oc_delta'==1 in L
											replace hhr_olderchild = calc_olderchild_count in L
												replace hhr_olderchild = hhr_olderch_elig if hhr_olderch_elig > calc_olderchild_count in L
										}

									local ad_same = (runiform() +  (`reg'/10) + ((6-`clus')/20))<1.28
									local ad_delta = runiform()<0.5
										if `ad_same' == 1 {
											replace hhr_adult_elig = calc_adult_count in L
											replace hhr_adult = calc_adult_count in L
										}
										else {
											replace hhr_adult_elig = calc_adult_count - 1 if `ad_delta'==0 in L
												replace hhr_adult_elig = 0 if hhr_adult_elig<0 in L
											replace hhr_adult_elig = calc_adult_count + 1 if `ad_delta'==1 in L
											replace hhr_adult = calc_adult_count in L
												replace hhr_adult = hhr_adult_elig if hhr_adult_elig > calc_adult_count in L
										}

									replace calc_hhr_elig_count = hhr_u5_elig + hhr_olderch_elig + hhr_adult_elig in L
								
								// Enumerator confirms figures are correct
									replace elig_check = 1 in L
								
								// Compare HHR visit outcome with assessment day count in HH roster
									// Written record > Verbal record > Roster recall
									if !missing(calc_rec_elig) in L {
										replace calc_elig_hhr = calc_rec_elig in L
									}
									else if !missing(calc_verbal_elig) in L {
										replace calc_elig_hhr = calc_verbal_elig in L
									}
									else replace calc_elig_hhr = calc_hhr_elig_count in L
									
									replace calc_elig_correct = cond(calc_elig_hhr==calc_elig_count,1,0) in L
								
									// Mismatch reaon for calc_elig_correct = 0
									if calc_elig_correct==0 in L {
										if calc_elig_hhr > calc_elig_count in L {		// HHR visit higher than assessment
											replace rmm_temp = word("1 3 4 5", ceil(runiform()*4)) in L
												replace reason_mismatch=1 if rmm_temp=="1" in L
												replace reason_mismatch=3 if rmm_temp=="3" in L
												replace reason_mismatch=4 if rmm_temp=="4" in L
												replace reason_mismatch=5 if rmm_temp=="5" in L
											
										}
										else if calc_elig_hhr < calc_elig_count in L {	// HHR visit lower than assessment
											replace rmm_temp = word("2 3 5", ceil(runiform()*3)) in L
												replace reason_mismatch=2 if rmm_temp=="2" in L
												replace reason_mismatch=3 if rmm_temp=="3" in L
												replace reason_mismatch=5 if rmm_temp=="5" in L
										}
									else {
										replace reason_mismatch = . in L
										replace oth_mismatch = "" in L
										replace descr_mismatch = "" in L
									}
									}

								// Section 3. Information from HHR team (for visited=1 cases)
									replace info_date = runiform()<$p_date in L
										recode info_date (0=98) if runiform()<0.2 in L 		// Recode 20% No to DKN
										replace correct_date = runiform()<$p_corrdate if info_date==1 in L
									
									replace info_loc = runiform()<$p_loc in L
										recode info_loc (0=98) if runiform()<0.2 in L		// Recode 20% No to DKN
										replace correct_loc = runiform()<$p_corrloc if info_loc==1 in L
									
									replace sbc_hhrstaff = runiform()<$p_sbc in L
										replace sbc_msg = "" in L
										if sbc_hhrstaff==1 in L {
											replace sbc_msg_1 = runiform()<0.7 in L
											replace sbc_msg_2 = runiform()<0.7 in L
											replace sbc_msg_3 = runiform()<0.7 in L
											replace sbc_msg_4 = runiform()<0.7 in L
											replace sbc_msg_5 = runiform()<0.7 in L
											replace sbc_msg_6 = runiform()<0.7 in L
											replace sbc_msg_96 = runiform()<0.1 in L
												replace oth_sbc_msg = "Test SBC message" if sbc_msg_96==1 in L	
										}
							
							// Final comments
							replace final_comments = "" in L
							}
							
							// Why wasn't household visited for campaign (visited!=0)
							if visited!=1 in L {
								replace notreg_temp = word("1 2 3 8", ceil(runiform()*4)) in L
									replace notreg=1 if notreg_temp=="1" in L
									replace notreg=2 if notreg_temp=="2" in L
									replace notreg=3 if notreg_temp=="3" in L
									replace notreg=8 if notreg_temp=="8" in L
							}
							
							// Section 3: Aware of the campaing
							// Asked for visit = 1 and visit = 0 cases
							replace aware = runiform()<$p_aware in L
							replace aware_source = "" in L
								if aware==1  in L {
									replace aware_source_1 = runiform()<0.8 in L
										replace aware_source_1 = 0 if visit==0		// Campaign staff not src if no HHR
									replace aware_source_2 = runiform()<0.7 in L
									replace aware_source_3 = runiform()<0.8 in L
									replace aware_source_4 = runiform()<0.5 in L
									replace aware_source_5 = runiform()<0.4 in L
									replace aware_source_6 = runiform()<0.4 in L
									replace aware_source_7 = runiform()<0.1 in L
									replace aware_source_8 = runiform()<0.3 in L
									replace aware_source_9 = runiform()<0.5 in L
									replace aware_source_96 = runiform()<0.1 in L
										replace oth_aware_source = "Test SBC source" if aware_source_96==1 in L		
								}
							}
						}
					
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
					replace _index = _n in L

				}											// Loop for household
			}												// Loop for cluster	
		}													// Loop for district
		mac shift											// Shift the tokenized count of districts
	}														// Loop for region



** Tables of errors by region and cluster_count (day)
/*
	. tab calc_elig_correct region, col

	calc_elig_ |              region
	   correct |         1          2          3 |     Total
	-----------+---------------------------------+----------
			 0 |         4         44         57 |       105 
			   |      1.54      14.24      27.80 |     13.58 
	-----------+---------------------------------+----------
			 1 |       255        265        148 |       668 
			   |     98.46      85.76      72.20 |     86.42 
	-----------+---------------------------------+----------
		 Total |       259        309        205 |       773 
			   |    100.00     100.00     100.00 |    100.00 


	. tab calc_elig_correct cluster_count, col

	calc_elig_ |                           cluster_count
	   correct |         1          2          3          4          5          6 |     Total
	-----------+------------------------------------------------------------------+----------
			 0 |        33         29         21         13          8          1 |       105 
			   |     28.45      22.14      16.15      10.48       5.80       0.75 |     13.58 
	-----------+------------------------------------------------------------------+----------
			 1 |        83        102        109        111        130        133 |       668 
			   |     71.55      77.86      83.85      89.52      94.20      99.25 |     86.42 
	-----------+------------------------------------------------------------------+----------
		 Total |       116        131        130        124        138        134 |       773 
			   |    100.00     100.00     100.00     100.00     100.00     100.00 |    100.00 


	. tab region cluster_count if calc_elig_correct==0

			   |                           cluster_count
		region |         1          2          3          4          5          6 |     Total
	-----------+------------------------------------------------------------------+----------
			 1 |         2          2          0          0          0          0 |         4 
			 2 |        14         18          8          4          0          0 |        44 
			 3 |        17          9         13          9          8          1 |        57 
	-----------+------------------------------------------------------------------+----------
		 Total |        33         29         21         13          8          1 |       105 
*/



** Now, for each cluster, we need to add in clean visited records to bring total to 10 HHs visited per cluster

	tab present region
		// 37 HHs not present
	tab participate region
		// +66 HHs do not participate
	tab participate present, m
		
		// 103 HHs to add

		codebook cluster
		bysort cluster: egen complete=total(participate)
		bysort cluster: gen clus_n=_n
		
			tab complete if clus_n==1, m


	** Can't think of a clever way to do this, so let's do it a quick and dirty way
		// Create 900 perfect records added to same data
			// HH number runs from 11 to 20
		// Drop new records if the HH number is above the number of records required
			// So clusters with 10 participating records (0 required) drop all HHs (11 to 20)
			// Clusters with 9 participating records (1 required) keep HH 11 and drop 12-20
			// etc
		
	// My original code for generating perfect records (all visited, no mismatches)
	local r_total=3
	tokenize 5 6 4
	
	foreach reg of num 1/`r_total' {
		foreach dis of num 1/`1' {
			foreach clus of num 1/6 {
			foreach hh of num 1/10 {
			
			set obs `=_N + 1'

			// Start and end times
				// Start times are 15:00, 15:30, 16:00 etc from the 16 Sep to 21 Sep 2025 (6 days)
			replace day = 15 + `clus' in L
			replace month = 9 in L
			replace year = 2025 in L
			replace hr = 15 + floor(`hh'/2) in L
			if mod(`hh',2) == 1 in L {
				replace mins = 0 in L
			} 
			else {
				replace mins = 30 in L
			}
		
			replace date_interview = mdyhms(month, day, year, hr, mins, 0) in L
			
			replace mins = mins + 15 + runiformint(1,11) in L
			replace endtime = mdyhms(month, day, year, hr, mins, 0) in L
						
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

			replace _geopoint_latitude = . if runiform()<0.05 in L
			replace _geopoint_longitude = . if missing(_geopoint_latitude) in L
			replace _geopoint_altitude = . if missing(_geopoint_latitude) in L
			replace _geopoint_precision = . if missing(_geopoint_latitude) in L		

			replace reason_nogps = "Test data" if missing(_geopoint_latitude) in L
			replace reason_nogps = "" if !missing(_geopoint_latitude) in L
			
			replace geopoint = "" in L
			
			// Intro
			replace present = runiform()<1 in L
			replace introduced = 1 in L
			replace participate = runiform()<1 in L
			
			// Digital matching
			replace hohh_name = "Test name" in L
			replace phone_n = "Test number" in L
			replace hhr_voucher = 2 in L
			replace voucher_qr = "" in L
			replace corr_voucher = . in L
			replace voucher_n = "Test number" in L
			
			// Section 1. People living in the household
				// Missing
			
			// Roster count
				// Generate at HH level then back-fill the HH roster
			replace calc_elig_count = rpoisson(5) in L
				replace calc_elig_count = 1 if calc_elig_count == 0 in L
			replace calc_adult_count = rpoisson(2) in L
				replace calc_adult_count = 1 if calc_adult_count == 0 in L
			replace calc_under5_count = rpoisson(2) in L
			replace calc_olderchild_count = calc_elig_count - calc_adult_count - calc_under5_count in L
				if calc_olderchild_count < 0 in L {
					replace calc_olderchild_count = 0 in L
					if calc_elig_count >= 2  in L {
						replace calc_adult_count = 2 in L
						replace calc_under5_count = calc_elig_count - calc_adult_count in L
					}
					else if calc_elig_count < 2  in L {
						replace calc_adult_count = 1 in L
						replace calc_under5_count = calc_elig_count - calc_adult_count in L
					}
				}
			
			// Section 2. Outcome of HHR
				replace visited = runiform()<1 in L
				replace notreg = . in L
				replace oth_notreg = "" in L
			// Written record
				replace hhr_record = runiform()>1 in L
				replace rec_seen = . in L
				replace rec_elig = . in L
				replace calc_rec_elig = . in L
			// Verbal record
				replace hhr_verbal = runiform()>1 in L
				replace verbal_elig = . in L
				replace calc_verbal_elig = . in L
			// Recall of HH members the previous day
				replace hhr_u5 = calc_under5_count in L
				replace hhr_u5_elig = calc_under5_count in L
				replace hhr_olderchild = calc_olderchild_count in L
				replace hhr_olderch_elig = calc_olderchild_count in L
				replace hhr_adult = calc_adult_count in L
				replace hhr_adult_elig = calc_adult_count in L
				replace calc_hhr_elig_count = hhr_u5_eli + hhr_olderch_elig + hhr_adult_elig in L
			// Enumerator confirms figures are correct
				replace elig_check = 1 in L
			// Compare HHR visit count with assessment day count in HH roster
				replace calc_elig_hhr = calc_hhr_elig_count in L
				replace calc_elig_correct = cond(calc_elig_hhr==calc_elig_count,1,0) in L
			// Mismatch reaon (if relevant)
				replace reason_mismatch = . in L
				replace oth_mismatch = "" in L
				replace descr_mismatch = "" in L
			
			// Section 3. Knowledge of the campaign
				replace aware = runiform()<1 in L
				replace aware_source = "" in L
				
				if aware==1  in L {
					replace aware_source_1 = runiform()<0.8 in L
					replace aware_source_2 = runiform()<0.7 in L
					replace aware_source_3 = runiform()<0.8 in L
					replace aware_source_4 = runiform()<0.5 in L
					replace aware_source_5 = runiform()<0.4 in L
					replace aware_source_6 = runiform()<0.4 in L
					replace aware_source_7 = runiform()<0.1 in L
					replace aware_source_8 = runiform()<0.3 in L
					replace aware_source_9 = runiform()<0.5 in L
					replace aware_source_96 = runiform()<0.1 in L
						replace oth_aware_source = "Test SBC source" if aware_source_96==1 in L			
				}
				
				if visited==1 in L {
					replace info_date = runiform()<1 in L
					replace correct_date = runiform()<1 if info_date==1 in L
					
					replace info_loc = runiform()<1 in L
					replace correct_loc = runiform()<1 if info_loc==1 in L
					
					replace sbc_hhrstaff = runiform()<1 in L
					replace sbc_msg = "" in L
					
					if sbc_hhrstaff==1 in L {
						replace sbc_msg_1 = runiform()<0.7 in L
						replace sbc_msg_2 = runiform()<0.7 in L
						replace sbc_msg_3 = runiform()<0.7 in L
						replace sbc_msg_4 = runiform()<0.7 in L
						replace sbc_msg_5 = runiform()<0.7 in L
						replace sbc_msg_6 = runiform()<0.7 in L
						replace sbc_msg_96 = runiform()<0.1 in L
							replace oth_sbc_msg = "Test SBC message" if sbc_msg_96==1 in L	
					}
				}
			
			// End of visit section
			replace hh_visit_detail = runiform()<1 in L
			
			replace final_comments = "" in L
			replace _id = "" in L
			replace _uuid = "" in L
			replace _submission_time = "" in L
			replace _validation_status = "" in L
			replace _notes = "" in L
			replace _status = "" in L
			replace _submitted_by = "" in L
			replace __version__ = "" in L
			replace _tags = "" in L
			replace _index = _n in L
		
			}
			}
		}
		mac shift
	}


	// Now drop records that aren't required
		gen required = 10 + (10-complete)
			// 900 missing values, as expected
		
		// Carry required over to the new records
		bysort cluster: egen req_temp = max(required)
			replace required = req_temp if missing(required)
		
		drop if hh_n>required
			// 797 dropped (103 kept, as expected)



** Check data set
	
	tab district region, m
	tab district region if participate==1, m
	
		tab region present, r				// 3.7% not present
		tab region participate, r			// 6.8% not participate
		tab region participate, r m
		tab region visited, r				// 2.7% not visited
		// HHR errors vary by region and cluster day
			tab region calc_elig_correct, r			// 12% incorrect
			tab cluster_count calc_elig_correct, r	// 12% incorrect
				// This also works assuming clusters 1,2 done on same day
				// Clusters 3,4 and 5,6
		
	/*
			   |   calc_elig_correct
		region |         0          1 |     Total
	-----------+----------------------+----------
			 1 |         4        289 |       293 
			   |      1.37      98.63 |    100.00 	// Good
	-----------+----------------------+----------
			 2 |        44        306 |       350 
			   |     12.57      87.43 |    100.00 	// Middle
	-----------+----------------------+----------
			 3 |        57        176 |       233 
			   |     24.46      75.54 |    100.00 	// Worse
	-----------+----------------------+----------
		 Total |       105        771 |       876 
			   |     11.99      88.01 |    100.00 


	cluster_co |   calc_elig_correct
		   unt |         0          1 |     Total
	-----------+----------------------+----------
			 1 |        33        107 |       140 
			   |     23.57      76.43 |    100.00 	// Most on day 1
	-----------+----------------------+----------
			 2 |        29        116 |       145 
			   |     20.00      80.00 |    100.00 
	-----------+----------------------+----------
			 3 |        21        128 |       149 
			   |     14.09      85.91 |    100.00 
	-----------+----------------------+----------
			 4 |        13        135 |       148 
			   |      8.78      91.22 |    100.00 
	-----------+----------------------+----------
			 5 |         8        138 |       146 
			   |      5.48      94.52 |    100.00 
	-----------+----------------------+----------
			 6 |         1        147 |       148 
			   |      0.68      99.32 |    100.00 	// Leaast on day 6
	-----------+----------------------+----------
		 Total |       105        771 |       876 
			   |     11.99      88.01 |    100.00 
	*/


** Final variable edits prior to saving

	drop complete clus_n required req_temp notreg_temp rmm_temp
	drop day month year hr mins cluster_count
	gsort calc_hh_id
	format date_interview endtime %tc


** Save files

	compress
	save "0a_inprocess_dummy_hh.dta", replace
	export 	excel using "0a_inprocess_dummy_data", ///
			sheet("In-process assessment of HHR", replace) firstrow(var) nolabel date("%tc")




***************************
** Individual-level data **
***************************

** Initiate file

	drop if missing(calc_elig_count)
	
	keep 	calc_hh_id calc_elig_count calc_under5_count calc_olderchild_count calc_adult_count ///
			_id _uuid _submission_time _validation_status _notes _status _submitted_by __version__ _tags _index
	
	ren _index _parent_index
	
	gen calc_id_field = ""
	gen res_no = .
	gen name = ""
	gen idp = .
	gen gender = .
	gen age_y = .
	gen age_m = .
	gen eligible = .
	gen calc_elig = .
	gen calc_under5 = .
	gen calc_olderchild = .
	gen calc_adult = .
	gen _index = .
	gen _parent_table_name = "In-process assessment of HHR"

	order _id _uuid _submission_time _validation_status _notes _status _submitted_by __version__ _tags _index, last

** Expand file and create fictional individuals

	// Expand file to one record per required person and add IDs
	expand calc_elig_count
		bysort calc_hh_id: replace res_no = _n
		
			tostring(calc_hh_id), gen(hhstr)
			tostring(res_no), gen(res) format(%02.0f)
			replace calc_id_field = hhstr + res
			drop hhstr res

			
	// Flag age bands for ind cases based on the calc_X_count variables
	bysort calc_hh_id: gen byte ageband = .
	bysort calc_hh_id: replace ageband = 1 if res_no <= calc_under5_count
	bysort calc_hh_id: replace ageband = 2 if 	res_no > calc_under5_count & ///
												res_no <= calc_under5_count + calc_olderchild_count
	bysort calc_hh_id: replace ageband = 3 if res_no > calc_under5_count + calc_olderchild_count

	
	// IDP / Vulnerable group
	replace idp = runiform()>1		// Assume all "No"
	
	
	// Gender
	replace gender = cond(runiform() < 0.5, 1, 2)
	
	
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

		
	// Ages - set up so they follow a rough "West African" population distribution
		// Note that this doesn't match adults in the HH, so 2 adults could have very different ages
		
		// Ages 0-4
		// P(exact age n) are 0.22, 0.21, 0.20, 0.19, 0.18
		gen _u = runiform() if ageband==1

		replace age_y = 0 if ageband==1 & _u < 0.22
			// Age in months for years = 0
			replace age_m = round(runiform(1,11)) if age_y==0

		replace age_y = 1 if ageband==1 & _u >= 0.22 & _u < 0.43
		replace age_y = 2 if ageband==1 & _u >= 0.43 & _u < 0.63
		replace age_y = 3 if ageband==1 & _u >= 0.63 & _u < 0.82
		replace age_y = 4 if ageband==1 & _u >= 0.82
		

		// Ages 5-17
		// Split into 3 segments then randomise within those on runiform
		// P(5-9, 10-14, 15-17) are 0.45, 0.4, 0.15
		replace _u = runiform() if ageband==2
		
		gen byte _cat5_17 = .
			replace _cat5_17 = 1 if ageband==2 & _u < 0.45
			replace _cat5_17 = 2 if ageband==2 & _u >= 0.45 & _u < 0.85
			replace _cat5_17 = 3 if ageband==2 & _u >= 0.85

			// Subrange 1: 5–9 (5 integers)
			replace age_y = 5 + floor(5*runiform()) if ageband==2 & _cat5_17==1

			// Subrange 2: 10–14 (5 integers)
			replace age_y = 10 + floor(5*runiform()) if ageband==2 & _cat5_17==2

			// Subrange 3: 15–17 (3 integers)
			replace age_y = 15 + floor(3*runiform()) if ageband==2 & _cat5_17==3
		
		drop _cat5_17


		// Ages 18 and above (limit at 80)
		// Split into 7 segments then randomise within those on runiform
			// 18–24, 25–34, 35–44, 45–54, 55–64, 65–74, 75–80
			// P(in segment)
			// 18–24 = 0.23
			// 25–34 = 0.28
			// 35–44 = 0.20
			// 45–54 = 0.14
			// 55–64 = 0.08
			// 65–74 = 0.05
			// 75–80 = 0.02
		replace _u = runiform() if ageband==3
		gen byte _cat18p = .
			replace _cat18p = 1 if ageband==3 & _u < 0.23
			replace _cat18p = 2 if ageband==3 & _u >= 0.23 & _u < 0.51
			replace _cat18p = 3 if ageband==3 & _u >= 0.51 & _u < 0.71
			replace _cat18p = 4 if ageband==3 & _u >= 0.71 & _u < 0.85
			replace _cat18p = 5 if ageband==3 & _u >= 0.85 & _u < 0.93
			replace _cat18p = 6 if ageband==3 & _u >= 0.93 & _u < 0.98
			replace _cat18p = 7 if ageband==3 & _u >= 0.98

			// 18–24 (7 integers)
			replace age_y = 18 + floor(7*runiform()) if ageband==3 & _cat18p==1

			// 25–34 (10 integers)
			replace age_y = 25 + floor(10*runiform()) if ageband==3 & _cat18p==2

			// 35–44 (10 integers)
			replace age_y = 35 + floor(10*runiform()) if ageband==3 & _cat18p==3

			// 45–54 (10 integers)
			replace age_y = 45 + floor(10*runiform()) if ageband==3 & _cat18p==4

			// 55–64 (10 integers)
			replace age_y = 55 + floor(10*runiform()) if ageband==3 & _cat18p==5

			// 65–74 (10 integers)
			replace age_y = 65 + floor(10*runiform()) if ageband==3 & _cat18p==6

			// 75–80 (6 integers)
			replace age_y = 75 + floor(6*runiform()) if ageband==3 & _cat18p==7
		
		drop _cat18p ageband

		
	// Eligible and associated flags
	replace eligible = runiform()<1		// All "Yes" based on how the ind file has been created
	
		replace calc_elig = 1 if eligible == 1
		replace calc_under5 = 1 if eligible == 1 & age_y<5
		replace calc_olderchild = 1 if eligible == 1 & inrange(age_y,5,17)
		replace calc_adult = 1 if eligible == 1 & inrange(age_y,18,80)
		

	// Index for this table
	replace _index = _n
	
	
** Final variable edits prior to saving
	
	drop calc_hh_id calc_elig_count calc_under5_count calc_olderchild_count calc_adult_count _u
	order 	res_no name calc_id_field idp gender age_y age_m eligible-calc_adult ///
			_index _parent_table_name _parent_index _id-_tags
			

** Save files
	
	compress
	save "0a_inprocess_dummy_ind.dta", replace
	export 	excel using "0a_inprocess_dummy_data", ///
			sheet("repeat_hh_residents", replace) firstrow(var) nolabel date("%tc")
