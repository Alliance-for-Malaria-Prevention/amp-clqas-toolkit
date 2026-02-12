
#---------------------------------------------------------------------------------------------------------------------------------------------------#
# Program:              1 In-process check and clean.R
# Purpose:              Check in-process assessment data daily as it is collected and produce a clean data set for further reporting and analysis 
# Data inputs:          HH and indiv data sets
# Data outputs:	        Coded variables
# Author(s):            Eleanore Sternberg, Steve Poyer
# Date last modified:   12 Dec 2025 by Eleanore Sternberg
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

#--- Section 0: Import the data ---#
# Once you have manually downloaded the data from your server, read it into R using this section. This assumes that you have exported the data as an .xlsx file.
# If the data file is not in the working directory, remember to add the full pathway or change the working directory to the location of the data
hh <- read_excel("Dummy data/0a_inprocess_dummy_data.xlsx", sheet = "In-process assessment of HHR")
indiv <- read_excel("Dummy data/0a_inprocess_dummy_data.xlsx", sheet = "repeat_hh_residents")

# Note that this won't import variable and value labels; if you want/need labels then you will need to start with a .dta (Stata) or .sav (SPSS) file
# If you have a .dta file exported from Stata, you can import it into R using the haven package and read_dta()

# Set date variable
#hh$dailydate <- as.Date(ymd_hms(hh$date_interview)) # This is the date format from Kobo
hh$dailydate <- as.Date(dmy_hms(hh$date_interview)) # This is the date format in the dummy data

# Add assessment day
hh <- hh %>%  mutate(survey_day = match(dailydate, unique(dailydate)))
# Check assessment days are correct
hh %>% tabyl(dailydate, survey_day)

# Convert hhid from numeric to character so that it can be used to match with indiv data
hh <- hh %>% mutate(calc_hh_id = as.character(calc_hh_id)) 

# Get some basic visit info to merge with individual data
# The dummy data does not have the uuid but _index can be used as a unique identifier in the HH data and _parent_index in the indiv data for this example
indiv <- indiv %>% mutate(`_submission__uuid` = `_parent_index`)
hh <- hh %>% mutate(`_uuid` = `_index`)
# Use the following script to add visit info to indiv data using uuid
visit_df <- hh %>% select(dailydate, survey_day, region, district, subdistrict, cluster, calc_hh_id, final_comments, `_uuid`) 
# Join the visit info with the individual data by uuid
indiv <- left_join(indiv, visit_df, by = c("_submission__uuid" = "_uuid"))

# For the purposes of demonstrating the code, filter data up to day three to simulate running this report part way through fieldwork
# If you are running this report daily, then you do not need to filter and can remove or comment out this line
hh <- hh %>% filter(survey_day <= 3)
indiv <- indiv %>% filter(survey_day <= 3)

#--- Section 1: Data collection checks ---#
# This section is meant to be run daily to ensure data quality and feedback to the field team if there are any issues
# It is intended to be run on the subset of data collected that day

# Restrict to a subset of dates (for example, if doing daily checks during field work)
# Filter on date 
#hh_today <- subset(hh, hh$dailydate == Sys.Date()) # Today's date only based on system date (this only works if checking the same day)
hh_today <- subset(hh, hh$dailydate == as.Date("2025-09-18")) # Data for specified date only
#indiv_today <- subset(indiv, indiv$dailydate == Sys.Date()) # Today's date only based on system date (this only works if checking the same day)
indiv_today <- subset(indiv, indiv$dailydate == as.Date("2025-09-18")) # Data for specified date only

#- Check that there are 10 completed household surveys per cluster
# The clusters should match with those in the fieldwork plan for that day
# Also check that there are some records of refusals/absences to confirm that the data collectors are recording every house they go to, regardless of status
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
# Almost all variables are required in the example form
# If questions are made non-required, then include checks for missing data here for those variables
# For example, this script checks if there are any NAs for "cluster" or "present" variables
#hh_today %>% summarise(across(c(cluster, present), ~ sum(is.na(.))))

#- Check how many households interviewed reported that they were not visited by the HH registration team
hh_today %>% tabyl(visited) # 1 = visited by HHR team; 0 = not visited by HHR team; 98 = don't know if visited by HHR team

#- Check for number of occurrence of mismatch (calc_elig_correct = 0)
hh_today %>% tabyl(cluster, calc_elig_correct, show_na = FALSE) 

#- Check that all interviewed households have a matching entry in the indiv data
# The setup of the ODK form ensures that hh and indiv data should always align but this can be used to check if the ODK form is altered so that's no longer the case
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
nrow(hh_missing_indiv)
# Check for unmatched hh ids in the indiv data
indiv_missing_hh <- indiv_ids %>%
  anti_join(hh_ids, by = "calc_hh_id")
nrow(indiv_missing_hh) 

#- Check that only first names are recorded for the household roster
indiv_today %>% select(name) %>% print(n = nrow(.))

#- Check for unusual/extreme values
# Household size
hist(as.numeric(hh_today$calc_elig_count))
# Ages
hist(indiv_today$age_y)

#- Check open ended comments
# Other reasons for mismatch with HHR
hh_today %>% select(oth_mismatch) %>% 
  filter(!is.na(oth_mismatch)) %>%
  print(n = nrow(.))

# Additional observations on mismatch with HHR
hh_today %>% select(descr_mismatch) %>% 
  filter(!is.na(descr_mismatch)) %>%
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
# It also includes code to rename variables, drop unnecessary variables, and generate new variables
# By the end of data collection, all corrections to the data should be included in this section and running the code will generate a cleaned data set

#- Corrections to the data
# This section can include any corrections that are fed back by the assessment team including:
# Correcting adding an extra HH member by mistake
# Correcting the wrong cluster being selected
# Dropping or changing duplicate HH IDs
# Categorizing "other" responses, if appropriate

#- Drop some variables that won't be used (these are all notes or meta data)
dropvars <- c("note_intro",
              "note_ic_check", 
              "note_roster",
              "note_elig",
              "note_under5",
              "note_olderchild",
              "note_adult",
              "note_assessor_flag1", 
              "note_assessor_flag2",
              "note_elig_correct_yes", 
              "note_elig_correct_no",
              "note_farewell_n",
              "_index",
              "_validation_status",
              "_notes",
              "_status",
              "_tags")

# Drop all the variables listed in the dropvars object
hh <- hh %>% select(!all_of(dropvars))
  
#- Rename some variables 
hh <- hh %>% rename(latitude = `_geopoint_latitude`,
                     longitude = `_geopoint_longitude`,
                     altitude = `_geopoint_altitude`,
                     gps_precision = `_geopoint_precision`,
                     source_campaign = `aware_source_1`,
                     source_chw = `aware_source_2`,
                     source_announcer = `aware_source_3`,
                     source_leader = `aware_source_4`,
                     source_family = `aware_source_5`,
                     source_radio = `aware_source_6`,
                     source_tv = `aware_source_7`,
                     source_sms = `aware_source_8`,
                     source_newspaper = `aware_source_9`,
                     source_oth = `aware_source_96`,
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
                     hhid = calc_hh_id,
                     survey_count = calc_elig_count,
                     hhr_count = calc_elig_hhr)

#- Create some new variables
# Create a binary variable for interviewed
hh <- hh %>% mutate(interviewed = case_when(hh_visit_detail == 1 ~ 1,
                                            hh_visit_detail == 2 ~ 0,
                                            hh_visit_detail == 3 ~ 0))

# Create a binary variable for HH not visited by HHR team
hh <- hh %>% mutate(novisit = case_when(visited == 1 ~ 0,
                                        visited == 0 ~ 1))

# Create binary variables for any HHR errors and HHR errors relating to counts
hh <- hh %>% mutate(hhr_err = case_when(calc_elig_correct == 1 ~ 0,
                                        calc_elig_correct == 0 | visited == 0 ~ 1),
                    hhr_err_ct = case_when(calc_elig_correct == 1 ~ 0, # Create a variable that is just error due to mismatch in counts (doesn't include missed HHs)
                                            calc_elig_correct == 0 ~ 1))

# Create variable for whether count error was over or underestimate
hh <- hh %>% mutate(hhr_hi = case_when(hhr_err == 1 & (hhr_count > survey_count) ~ 1, # HHR was higher than assessment yes/no
                                       hhr_err == 1 & (hhr_count < survey_count) ~ 0),
                    hhr_lo = case_when(hhr_err == 1 & (hhr_count < survey_count) ~ 1, # HHR was lower than assessment yes/no
                                       hhr_err == 1 & (hhr_count > survey_count) ~ 0),
                    hhr_hl = case_when(hhr_err == 1 & (hhr_count < survey_count) ~ 1, # HHR was higher = 1 and HHR was lower = 2
                                       hhr_err == 1 & (hhr_count > survey_count) ~ 2))


#--- Section 3: checks on complete data ---#
# These are some final checks to be run on the data set before exporting
# These checks are run iteratively, as the data set is built each day, and ensure that the data are complete with the sampling to date

#- Check that all districts (lots) are there and total number of records
hh %>% tabyl(district, region) %>%
  adorn_totals()

#- Check that there are data from six clusters for each district by counting up distinct combinations of region, district, and cluster
hh %>% distinct(region, district, cluster) %>%  
  count(region, district, name = "n_clusters")

#- Check for any clusters with less than 10 completed interviews
hh %>%
  count(region, district, cluster, hh_visit_detail, name = "n_households") %>%
  pivot_wider(names_from = hh_visit_detail,
              values_from = n_households,
              names_prefix = "visit_",
              values_fill = 0) %>%
  arrange(region, district, cluster) %>%
  filter(visit_1 != 10)

#- Check for any duplicate household IDs 
# Add a duplicate tag
hh <- hh %>% mutate(dup = duplicated(hhid) | duplicated(hhid, fromLast = TRUE))

# Create dataframe with entries where the HH ID is duplicated (if there are any)
hh %>% filter(dup == "TRUE") %>%
  select(date_interview, region, district, subdistrict, cluster, hh_n, hhid, geopoint, hohh_name) %>% # Check location, head of HH name, etc for duplicates
  print(n = nrow(.))

#--- Section 4: Export clean, final data ---#
# This exports the data in three formats: xlsx, csv, and dta
# It can be done daily, with each version of the data replacing the previous day's version, or it run once at the end of data collection

# Main (hh) data
# As xlsx
write.xlsx(hh, "Clean raw data/hh_in_clean.xlsx")
# As .csv
write.csv(hh, "Clean raw data/hh_in_clean.csv", row.names = FALSE)
# As .dta
write_dta(hh, "Clean raw data/hh_in_clean.dta")




    
