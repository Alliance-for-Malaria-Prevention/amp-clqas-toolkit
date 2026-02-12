#---------------------------------------------------------------------------------------------------------------------------------------------------#
# Program:              4 End-process check and clean.R
# Purpose:              Check end-process assessment data daily as it is collected and produce a clean data set for further reporting and analysis 
# Data inputs:          HH and indiv data sets
# Data outputs:	        Coded variables
# Author(s):            Eleanore Sternberg, Steve Poyer
# Date last modified:   05 Jan 2026 by Eleanore Sternberg
#---------------------------------------------------------------------------------------------------------------------------------------------------#

# This script includes checks to be run daily during data collection as well as data cleaning steps
# Outputs will appear in the console window and should be checked at the end of each day of data collection to catch any immediate issues with data quality 
# After a series of checks, there is script to drop some variables and create new variables used for reporting
# At the end of the script, there are some final checks and then a clean raw data file is exported in multiple formats

#--- Libraries ---#
# These are the packages you will need to run the code in this script
library(readxl)
library(openxlsx)
library(tidyverse)
library(lubridate)
library(janitor)
library(haven)

#--- Description of survey design ---#
# Include a brief description of the survey design here so that it is clear what is expected when reviewing the data. For example:
# Number of regions: 3
# Districts: Region 1 = 5 districts; Region 3 = 6 districts, Region 3 = 4 districts
# Clusters: 60 clusters per district and 10 households interviewed in each cluster
# Expected sample size:
# Data collection is from one cluster completed per district per day

# The dummy data represent data from day 6 (i.e. after data collection is complete)


#--- Section 0: Import the data ---#
# Once you have manually downloaded the data from your server, read it into R using this section.
# This code assumes that you have exported the data as an .xlsx (Excel) file.
# If the data file is not in the working directory, remember to add the full pathway or change the working directory to the location of the data
# Note: this code won't import variable and value labels; if you want/need labels then you will need to start with a .dta (Stata) or .sav (SPSS) file
# If you have a .dta file exported from Stata, you can import it into R using the haven package and read_dta()
hh <- read_excel("Dummy data/0b_endprocess_dummy_data.xlsx", sheet = "End-process assessment of distr")
indiv <- read_excel("Dummy data/0b_endprocess_dummy_data.xlsx", sheet = "repeat_hh_residents")

# Set date variable
#hh$dailydate <- as.Date(ymd_hms(hh$date_interview)) # This is the date format from Kobo
hh$dailydate <- as.Date(dmy_hms(hh$date_interview)) # This is the date format in the dummy data

# Add assessment day
hh <- hh %>%  mutate(survey_day = match(dailydate, unique(dailydate)))
# Check assessment days are correct
hh %>% tabyl(dailydate, survey_day)

# Convert hhid from numeric to character so that it can be used to match with indiv data
hh <- hh %>% mutate(calc_hh_id = as.character(calc_hh_id)) 

# Get some basic visit info from the household-level data to merge with individual data
# Note: the dummy data does not include a populated _uuid variable (a Kobo system variable that is constant across tables for the same master case)
# In the dummy data, _index uniquely identifies cases in the HH data and these values appear as _parent_index in the indiv data
indiv <- indiv %>% mutate(`_submission__uuid` = `_parent_index`)
hh <- hh %>% mutate(`_uuid` = `_index`)
# Add visit info to indiv data using _uuid
visit_df <- hh %>% select(dailydate, survey_day, region, district, subdistrict, cluster, calc_hh_id, final_comments, `_uuid`) 
# Join the visit info with the individual data by _uuid
indiv <- left_join(indiv, visit_df, by = c("_submission__uuid" = "_uuid"))


#--- Section 1: Data collection checks ---#
# Run this section daily to review data quality and provide feedback to the field teams as required
# The section is intended to be run on the subset of data collected that day

# Restrict to a subset of dates (for example, if doing daily checks during field work)
# Filter on date 
#hh_today <- subset(hh, hh$dailydate == Sys.Date())           # Today's date only based on system date (this only works if checking the same day)
hh_today <- subset(hh, hh$dailydate == as.Date("2025-10-08")) # Data for specified date only
#indiv_today <- subset(indiv, indiv$dailydate == Sys.Date())  # Today's date only based on system date (this only works if checking the same day)
indiv_today <- subset(indiv, indiv$dailydate == as.Date("2025-10-08")) # Data for specified date only

#- Check that there are 10 completed household interviews per cluster
# The clusters / cluster numbers should match with those in the fieldwork plan for the selected day
# Check that there are some records of refusals/absences to confirm that the data collectors are recording every house they approach, regardless of status
# 1 = completed survey; 2 = absent, 3 = refused

# By cluster
hh_today %>%
  count(region, district, cluster, hh_visit_detail, name = "n_households") %>%
  pivot_wider(names_from = hh_visit_detail,
              values_from = n_households,
              names_prefix = "visit_",
              values_fill = 0) %>%
  arrange(region, district, cluster)

# In total how many households were visited and interviewed that day
hh_today %>% tabyl(hh_visit_detail)

#- Check for any duplicate household IDs 
# Add a duplicate tag
hh_today <- hh_today %>% mutate(dup = duplicated(calc_hh_id) | duplicated(calc_hh_id, fromLast = TRUE))

# Create dataframe with entries where the HH ID is duplicated (if there are any)
hh_today %>% filter(dup == "TRUE") %>%
  select(date_interview, region, district, subdistrict, cluster, hh_n, calc_hh_id, geopoint, hohh_name) %>% # Check location, head of HH name, etc for duplicates
  print(n = nrow(.))

#- Check for missing data
# Almost all variables are required in the adaptable ODK form used to produce the dummy data
# If questions are made non-required, then include checks for missing data here for those variables
# For example, this script checks if there are any NAs for "cluster" or "present" variables
hh_today %>% summarise(across(c(cluster, present), ~ sum(is.na(.))))

#- Check how many households reported that they were not visited by the HH registration team
hh_today %>% tabyl(visited) # 1 = visited by HHR team; 0 = not visited by HHR team; 98 = don't know if visited by HHR team

#- Check how many cases were flagged as receiving an incorrect number of ITNs (calc_itn_correct = 0 in the adaptable ODK form)
hh_today %>% tabyl(cluster, calc_itn_correct, show_na = FALSE) 

#- Check that only first names are recorded for the household roster (as specified in the adaptable protocol)
indiv_today %>% select(name) %>% print(n = nrow(.))

#- Check for unusual/extreme values (examples provided here for household size and age from the individual data)
# Household size
hist(as.numeric(hh_today$calc_elig_count))
# Ages
hist(indiv_today$age_y)

#- Check open ended comments
# Other reasons why HH wasn't registered
hh_today %>% select(oth_notreg) %>% 
  filter(!is.na(oth_notreg)) %>%
  print(n = nrow(.))

# Other reasons why individuals did not sleep under an ITN the previous night
indiv_today %>% select(oth_noitn) %>% 
  filter(!is.na(oth_noitn)) %>%
  print(n = nrow(.))

# Other reasons why HH didn't receive ITNs from the recent campaign
# Note: The adaptable questionnaire and ODK file includes different questions/responses for fixed point and door-to-door campaign strategies
# The dummy data assumes a fixed-point (double-phase) campaign took place
# Fixed point
hh_today %>% select(oth_noitn_fp) %>% 
  filter(!is.na(oth_noitn_fp)) %>%
  print(n = nrow(.))
# Door-to-door
#hh_today %>% select(oth_noitn_d2d) %>% 
#  filter(!is.na(oth_noitn_d2d)) %>%
#  print(n = nrow(.))

# Other reasons why there is a mismatch between ITN allocation based on reported HHR outcomes and the number of ITNs received
hh_today %>% select(oth_mismatch) %>% 
  filter(!is.na(oth_mismatch)) %>%
  print(n = nrow(.))

# Other reasons sources of information on campaign
hh_today %>% select(oth_aware_source) %>% 
  filter(!is.na(oth_aware_source)) %>%
  print(n = nrow(.))

# Other sbc messages received
hh_today %>% select(oth_sbc_msg) %>% 
  filter(!is.na(oth_sbc_msg)) %>%
  print(n = nrow(.))

# Final notes
hh_today %>% select(final_comments) %>% 
  filter(!is.na(final_comments)) %>%
  print(n = nrow(.))


#--- Section 2: Cleaning ---#
# This section is to be run on the full data set, with corrections added daily as needed
# It includes code to rename variables, drop unnecessary variables, and generate new variables
# By the end of data collection, all corrections to the data should be included in this section and running the code will generate a cleaned data set

#- Corrections to the data
# This section can include any corrections that are fed back by the assessment team including:
# Correcting adding an extra HH member by mistake
# Correcting the wrong cluster being selected
# Dropping or changing duplicate HH IDs
# Categorizing "other" responses, if appropriate

#-- Household data
#- Drop some variables that won't be used (these are all notes in the adaptable ODK file or Kobo meta data)
dropvars1 <- c("note_intro",
               "note_ic_check", 
               "note_roster",
               "note_elig",
               "note_under5",
               "note_olderchild",
               "note_adult",
               "note_assessor_flag1", 
               "note_assessor_flag2",
               "note_farewell_n",
               "_index",
               "_validation_status",
               "_notes",
               "_status",
               "_tags")

# Drop all the variables listed in the dropvars object
hh <- hh %>% select(!all_of(dropvars1))


#--- Section 3: Edit variables for analysis (drop, rename and generate analysis variables) ---#
#-- Household data
#- Rename some variables 
hh <- hh %>% rename(hhid = calc_hh_id,
                    latitude = `_geopoint_latitude`,
                    longitude = `_geopoint_longitude`,
                    altitude = `_geopoint_altitude`,
                    gps_precision = `_geopoint_precision`,
                    aware = `aware_fp`, # Raw var name is aware_dd in the adaptable ODK file for single-phase campaigns
                    src_cam = `aware_source_1`,
                    src_chw = `aware_source_2`,
                    src_ann = `aware_source_3`,
                    src_lea = `aware_source_4`,
                    src_fam = `aware_source_5`,
                    src_rad = `aware_source_6`,
                    src_tv = `aware_source_7`,
                    src_sms = `aware_source_8`,
                    src_new = `aware_source_9`,
                    src_oth = `aware_source_96`,
                    sbc_use = `sbc_msg_1`,
                    sbc_care = `sbc_msg_2`,
                    sbc_hang = `sbc_msg_3`,
                    sbc_sleep = `sbc_msg_4`,
                    sbc_prevent = `sbc_msg_5`,
                    sbc_repair = `sbc_msg_6`,
                    sbc_oth = `sbc_msg_96`,
                    id = `_id`,
                    uuid = `_uuid`,
                    submission_time = `_submission_time`,
                    submitted_by = `_submitted_by`,
                    version = `__version__`,
                    survey_count = calc_elig_count) # Count of eligible HH members based on assessment roster

#- Generate weights
# Read in regional and district populations
pop.data <- read_excel("Population data.xlsx")
# Merge with the survey data
# Note: Values of the merge variables (here, region and district) must match exactly between files (e.g. spelling, capitalization)
pop.data <- pop.data %>% rename(region_n = `Region name`,
                                region = `Region Code`,
                                reg_pop = `Reg Population`,
                                distr_n = `District name`,
                                district = `District Code`,
                                distr_pop = `District population`,
                                tot_pop = `Total population`)
# Merge by region and district, keeping all in the survey data
hh <- left_join(hh, pop.data, by = c("region", "district"))
# Check there are no unmatched regions/districts in the dataframe
unmatched <- hh %>%
  filter(is.na(reg_pop) | is.na(distr_pop)) %>%
  distinct(region, district)

# The dummy data come from a sampling design that has clusters within districts within regions
# Clusters are selected PPS and so the data are self-weighting at this level (within a district)
# Regional-level and Total (i.e. national-level) results are weighted averages
#hh <- hh %>% mutate(wt = distr_pop/reg_pop)  # Example of district-level weights to estimate regional totals if not all regions in the country are included in the campaign
hh <- hh %>% mutate(wt = distr_pop/tot_pop)   # Example that assumes all admin units in country are included in the campaign (and in study)
                                              # tot_pop is the national population (i.e. the sum of the population of all admin units in the country)


#- Create some new variables

# Create a binary variable for interviewed y/n
hh <- hh %>% mutate(interviewed = case_when(hh_visit_detail == 1 ~ 1,
                                            hh_visit_detail == 2 ~ 0,
                                            hh_visit_detail == 3 ~ 0))

# Create a binary variable for HH visited by HHR team that codes "don't know" response as unvisited
hh <- hh %>% mutate(yesvisit = case_when(visited == 1 ~ 1,
                                         visited == 0 | visited == 98 ~ 0))

# Create a binary variable for HH not visited to use as denominator in Annex Table 1 (exluding Don't know responses)
hh <- hh %>% mutate(novisit = case_when(visited == 0 ~ 1,
                                        visited == 1 | visited == 98 ~ 0))

# Create a binary variable for HH received ITNs that codes "don't know" response as didn't receive an ITN
hh <- hh %>% mutate(netyn = case_when(recvd_itn == 1 ~ 1,
                                      recvd_itn == 0 | recvd_itn == 98 ~ 0))

# Create a binary variable for HH that definitely did NOT get a net
# These cases have non-missing why_noitn* values; this question only being asked if recvd_itn=0 (not Don't Know)
hh <- hh %>% mutate(nonet = case_when(recvd_itn == 1 | recvd_itn == 98 ~ 0,
                                      recvd_itn == 0 ~ 1))

# Create binary variables for any mismatch in the number of ITNs eligible and received
# Note: calc_itn_correct = 0 if received ITNs != ITNs assigned by HHR team OR if HHR team visit (visited) was No or Don't Know
# Note: This ensures calc_itn_correct is non-missing for all interviewed HHs and can be used for the LQAS classification of lots with N=60
hh <- hh %>% mutate(itn_err = case_when(calc_itn_correct == 1 ~ 0,
                                        calc_itn_correct == 0 ~ 1))

# Create a binary variable for whether the household has noncampaign ITNs or not
hh <- hh %>% mutate(ncyn = case_when(ncitn_n > 0 ~ 1,
                                     ncitn_n == 0 ~ 0))

# Create binary variables for aware of date AND location of distribution
# Aware of both date and location
hh <- hh %>% 
  mutate(aware_y = case_when(aware == 1 ~ 1,
                             aware == 0 | aware >1 ~ 0)) 
# Aware of neither date nor location
hh <- hh %>%
  mutate(aware_n = case_when(aware > 0 ~ 0,
                             aware == 0 ~ 1))

# Aware of date OR location (used as denominator in Table 8b)
hh <- hh %>% 
  mutate(aware_8b = case_when(aware > 0 ~ 1,
                              aware == 0 ~ 0))

# Create a binary variable to flag HHs eligible for the question on SBC
# Note: These are cases that received an ITN OR didn't receive an ITN and have a reason other than "no distribution"
hh <- hh %>% mutate(sbc_denom = case_when(recvd_itn == 1 ~ 1,
                                          recvd_itn == 0 & why_noitn_fp != "1" ~ 1,
                                          recvd_itn == 0 & why_noitn_fp == "1" ~ 0))

# Create a binary variable for received information about ITNs or malaria
hh <- hh %>% mutate(sbc_y = case_when(sbc_distrstaff == 1 ~ 1,
                                      sbc_distrstaff == 0 | sbc_distrstaff == 98 ~ 0))

# Create dummy variable for reaons why HH was not visited by HHR
hh <- hh %>%
  mutate(nreg_novisit = case_when(notreg == "1" ~ 1,   # The HHR team did not visit
                                  notreg != "1" ~0),
         nreg_away    = case_when(notreg == "2" ~ 1,   # No one was at home when the HHR team were in the community
                                  notreg != "2" ~0),
         nreg_refuse  = case_when(notreg == "3" ~ 1,   # Refused to be registered when HHR team came
                                  notreg != "3" ~0),
         nreg_dkn     = case_when(notreg == "8" ~ 1,   # Respondent does not know why household wasn’t registered
                                  notreg != "8" ~0),
         nreg_oth     = case_when(notreg == "96" ~ 1,  # Other reason
                                  notreg != "96" ~ 0))

# Create dummy variable for reason why HH didn't get a net
hh <- hh %>% 
  mutate(noitn_nodis = case_when(why_noitn_fp == "1" ~ 1,   # No distribution point was set up / no distribution occurred
                                 why_noitn_fp != "1" ~ 0), 
         noitn_noitn = case_when(why_noitn_fp == "2" ~ 1,   # Visited distribution point but received no ITNs
                                 why_noitn_fp != "2" ~ 0),
         noitn_forg  = case_when(why_noitn_fp == "3" | why_noitn_fp == "4" ~ 1, # Knew about distribution but was unable/forgot to attend
                                why_noitn_fp != "3" & why_noitn_fp != "4" ~ 0),
         noitn_decl  = case_when(why_noitn_fp == "5" ~ 1,   # Knew about distribution but did not want to attend
                                 why_noitn_fp != "5" ~ 0),
         noitn_unaw  = case_when(why_noitn_fp == "6" ~ 1,   # Didn't know distribution was happening
                                 why_noitn_fp != "6" ~ 0),
         noitn_dk    = case_when(why_noitn_fp == "8" ~ 1,   # Don't know
                                 why_noitn_fp != "8" ~ 0),
         noitn_oth   = case_when(why_noitn_fp == "96" ~ 1,  # Other reason
                                 why_noitn_fp != "96" ~ 0))

# Create dummy variable for reason for mismatch between ITNs assigned/allocated and ITNs received
hh <- hh %>%
  mutate(mis_ration = case_when(reason_mismatch == "1" ~ 1,   # Staff rationed ITNs
                                reason_mismatch != "1" ~0),
         mis_ranout = case_when(reason_mismatch == "2" ~ 1,   # Staff ran out of ITNs
                                reason_mismatch != "2" ~0),
         mis_recall = case_when(reason_mismatch == "3" ~ 1,   # Error in respondent recall of HHR process
                                reason_mismatch != "3" ~0),
         mis_unk    = case_when(reason_mismatch == "4" ~ 1,   # Unable to determine reason
                                reason_mismatch != "4" ~0),
         mis_oth    = case_when(reason_mismatch == "96" ~ 1,  # Other reason
                                reason_mismatch != "96" ~ 0))

# Create dummy variables for information sources about the campaign
# Note: This step may be required, depending on how you have programmed multiple response questions and the digital platform used.
# The dummy data already includes binary variables for each response in multiple response questions (var names are source_*).

# Create dummy variables for SBC sources
# Note: This step may be required, depending on how you have programmed multiple response questions and the digital platform used.
# The dummy data already includes binary variables for each response in multiple response questions (var names are sbc_*).

#- Ensure that variables are the right variable type
hh <- hh %>% 
  mutate(across(c(region, district, cluster), as.character))


#-- Individual data
#- Drop some variables that won't be used (these are all notes or meta data)
dropvars2 <- c("_parent_table_name",
              "_id",
              "_index",
              "_submission_time",
              "_validation_status",
              "_notes",
              "_status",
              "_submitted_by",
              "__version__",
              "_tags",
              "_parent_index",
              "_index",
              "_submission__uuid")

# Drop all the variables listed in the dropvars object
indiv <- indiv %>% select(!all_of(dropvars2))

#- Rename some variables 
indiv <- indiv %>% rename(hhid = calc_hh_id,
                          uuid = `_uuid`)

#- Create variables needed to calculate population net access
# Access is defined for the de facto population (those who stayed in the house the night before the survey)
# Sum the de facto population for each household and join this to the hh data which contains information on ITNs 

# Sum de facto populations (all, u5 and pregnant women)
df <- indiv %>% group_by(hhid) %>%
  summarise(defacto = sum(stay == 1, na.rm = TRUE),                   # Sum de facto population
            dfu5 = sum(stay == 1 & calc_under5 == 1, na.rm = TRUE),
            dfpw = sum(stay == 1 & pregnant == 1, na.rm = TRUE),
            df_itn = sum(stay == 1 & use_itn == 1, na.rm = TRUE),     # Sum de facto population that used a net the previous night
            u5_itn = sum(stay == 1 & calc_under5 == 1 & use_itn == 1, na.rm = TRUE),
            pw_itn = sum(stay == 1 & pregnant == 1 & use_itn == 1, na.rm = TRUE)) 

# Join the de facto population to the hh data
hh <- left_join(hh, df, by = "hhid")

# Calculate potential users and access (capping access at 1)
hh <- hh %>% mutate(potuse1 = total_itns*2, # all ITNs
                    potuse2 = calc_citn_n*2, # campaign ITNs
                    potuse3 = ncitn_n*2, # non-campaign ITNs
                    access1 = case_when(interviewed == 1 & potuse1/defacto <= 1 ~ potuse1/defacto,
                                        interviewed == 1 & potuse1/defacto > 1 ~ 1),
                    access2 = case_when(interviewed == 1 & potuse2/defacto <= 1 ~ potuse2/defacto,
                                        interviewed == 1 & potuse2/defacto > 1 ~ 1),
                    access3 = case_when(interviewed == 1 & potuse3/defacto <= 1 ~ potuse3/defacto,
                                        interviewed == 1 & potuse3/defacto > 1 ~ 1))

# !!! Here is calculating access the way that Steve described:
# Merge count of de facto population with individual data
#indiv <- left_join(indiv, df, by = "hhid")
#rm(df)

# Get number of nets from HH data
#nets <- hh %>% select(hhid, calc_citn_n, ncitn_n, total_itns)
# Merge with indiv data
#indiv <- left_join(indiv, nets, by = "hhid")
#rm(nets)

# Create variables with potential users (two users per net)
#indiv <- indiv %>% mutate(potuser1 = total_itns*2, # all ITNs
#                          potuser2 = calc_citn_n*2, # campaign ITNs
#                          potuser3 = ncitn_n*2) # non-campaign ITNs
# Create an indiv dataframe with only people who slept at the house the previous night
#indiv_df <- indiv %>% filter(stay == 1)
# Create access variables
#indiv_df <- indiv_df %>% 
#  group_by(hhid) %>% 
#  mutate(dfres_no = row_number()) %>% # assign a sequential number (1, 2, 3...) to each HH member by HHID (this is basically the res_no but with the absent members dropped) 
#  ungroup() %>%
#  mutate(access1 = case_when(dfres_no <= potuser1 ~ 1, # If the HH member has a number less than potential users then access is 1 otherwise it's 0; all ITNs
#                             dfres_no > potuser1 ~ 0),
#         access2 = case_when(dfres_no <= potuser2 ~ 1, # campaign ITNs
#                             dfres_no > potuser2 ~ 0),
#         access3 = case_when(dfres_no <= potuser3 ~ 1, # non-campaign ITNs
#                             dfres_no > potuser3 ~ 0))

# Add access back into full indiv data
#indiv <- indiv %>% left_join(select(indiv_df, calc_id_field, access1, access2, access3), by = "calc_id_field")

# Can also count this up to merge in with HH data
#access <- indiv_df %>%
#  group_by(hhid) %>%
#  summarise(across(c(access1, access2, access3), \(x) sum(x, na.rm = TRUE)), .groups = "drop")

# !!! Check if the two ways of calculating access give you the same answer (IT DOES!)
# Merge and calculate access
#hh <- left_join(hh, access, by = "hhid") 
#hh <- hh %>% mutate(access1 = access1/defacto,
#                    access2 = access2/defacto,
#                    access3 = access3/defacto)
#rm(indiv_df)

# Flag eligible people not sleeping under a net the previous night
indiv <- indiv %>% mutate(nouse = case_when(stay==1 & use_itn == 0 ~ 1,
                                            stay==1 & use_itn == 1 ~ 0))

# Create dummy variables for reasons for ITN non-use
indiv <- indiv %>%
  mutate(r_few = case_when(reason_noitn == "1" ~ 1,       # Not enough ITNs to cover sleeping space
                           reason_noitn != "1" ~0),
         r_smell = case_when(reason_noitn == "2" ~ 1,     # Don't like smell/irritation
                             reason_noitn != "2" ~0),
         r_hot   = case_when(reason_noitn == "3" ~ 1,     # Too hot
                             reason_noitn != "3" ~0),
         r_nomal  = case_when(reason_noitn == "4" | reason_noitn == "5" ~ 1,      # No malaria / No mosquitos
                              reason_noitn != "4" & reason_noitn != "5" ~ 0),
         r_dislike = case_when(reason_noitn == "6" ~ 1,   # Don't like using an ITN
                               reason_noitn != "6" ~ 0),
         r_out    = case_when(reason_noitn == "7" ~ 1,    # Sleep outside
                              reason_noitn != "7" ~ 0),
         r_dkn    = case_when(reason_noitn == "98" ~ 1,   # Don't know
                              reason_noitn != "98" ~ 0),
         r_oth    = case_when(reason_noitn == "96" ~ 1, # Other reason
                                reason_noitn != "96" ~ 0))

# Merge weight information onto indiv data
indiv <- left_join(indiv, pop.data, by = c("region", "district"))

# Check there are no unmatched regions/districts in the dataframe
unmatched <- indiv %>%
  filter(is.na(reg_pop) | is.na(distr_pop)) %>%
  distinct(region, district)

# Generate weights (see notes above for HH-level data)
indiv <- indiv %>% mutate(wt = distr_pop/tot_pop)

#- Ensure that variables are the right variable type
indiv <- indiv %>% 
  mutate(across(c(region, district, cluster), as.character))


#--- Section 4: checks on complete data ---#
# These are some final checks to be run on the data set before exporting
# These checks are run iteratively, as the data set is built each day, and ensure that the data are complete with the sampling to date

#- Check expected districts (lots) are present and check total number of records
hh %>% tabyl(district, region) %>%
  adorn_totals()

#- Check each district contains six clusters
hh %>% distinct(region, district, cluster) %>%  
  count(region, district, name = "n_clusters")

#- Check for any clusters with less than 10 completed interviews (there should be none)
hh %>%
  count(region, district, cluster, hh_visit_detail, name = "n_households") %>%
  pivot_wider(names_from = hh_visit_detail,
              values_from = n_households,
              names_prefix = "visit_",
              values_fill = 0) %>%
  arrange(region, district, cluster) %>%
  filter(visit_1 != 10)

#- Check full data for any duplicate household IDs 
# Add a duplicate tag
hh <- hh %>% mutate(dup = duplicated(hhid) | duplicated(hhid, fromLast = TRUE))

# Create dataframe with entries where the HH ID is duplicated (if there are any)
hh %>% filter(dup == "TRUE") %>%
  select(date_interview, region, district, subdistrict, cluster, hh_n, hhid, geopoint, hohh_name) %>% # Check location, head of HH name, etc for duplicates
  print(n = nrow(.))

#- Check that all interviewed households have a matching entry in the indiv data
# The setup of the adaptable ODK form ensures that hh and indiv data should always align
# This check is useful if the adaptable form has been edited
# Create list of distinct household IDs 
# For hh data
hh_ids <- hh_today %>% filter(hh_visit_detail == 1) %>%
  distinct(calc_hh_id)
# For indiv data
indiv_ids <- indiv_today %>%
  distinct(calc_hh_id)

# Check for unmatched hh ids in the hh data
hh_missing_indiv <- hh_ids %>%
  anti_join(indiv_ids, by = "calc_hh_id")
# Get all of the data for these unmatched HH
hh_missing_indiv <- left_join(hh_missing_indiv, hh_today, by = "calc_hh_id")
# Check number of rows (number of unmatched)
nrow(hh_missing_indiv)

# Check for unmatched hh ids in the indiv data
indiv_missing_hh <- indiv_ids %>%
  anti_join(hh_ids, by = "calc_hh_id")
# Get all of the data for these unmatched indivs
indiv_missing_hh <- left_join(indiv_missing_hh, indiv_today, by = "calc_hh_id")
# Check number of rows (number of unmatched)
nrow(indiv_missing_hh)


#--- Section 5: Export clean, final data ---#
# This exports the data in three formats: xlsx, csv, and dta
# It can be done daily, with each version of the data replacing the previous day's version, or it run once at the end of data collection

# Household-level data
# As xlsx
write.xlsx(hh, "Clean raw data/hh_end_clean.xlsx")
# As .csv
write.csv(hh, "Clean raw data/hh_end_clean.csv", row.names = FALSE)
# As .dta
write_dta(hh, "Clean raw data/hh_end_clean.dta")

# Individual-level data
# As xlsx
write.xlsx(indiv, "Clean raw data/indiv_end_clean.xlsx")
# As .csv
write.csv(indiv, "Clean raw data/indiv_end_clean.csv", row.names = FALSE)
# As .dta
write_dta(indiv, "Clean raw data/indiv_end_clean.dta")

