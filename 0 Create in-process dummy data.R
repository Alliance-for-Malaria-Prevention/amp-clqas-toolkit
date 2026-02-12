
#
# This script generates a dummy data set for an in-process LQAS survey of HHR during an ITN distribution
# It can be used to try the checking, cleaning, and analysis scripts
#

# Libraries
library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(janitor)
library(uuid)

# Also tried koboloadeR from github but couldn't get it to work. I think the dependencies are maybe out of date? 



# Set seed
set.seed(42)

# Create region and district variables
# Assume 8 regions
dummy_df <- tibble(region = 1:8) %>% mutate(n_dist = if_else(region <= 2, 7L, 6L)) %>% # n_dist = 7 for regions 1 & 2 and n_dist = 6 for regions 3 - 8
  uncount(n_dist, .id = "district_in_region") %>%      # expand rows by the number given in n_dist
  mutate(district = row_number()) %>%                   # create district by row number
  select(region, district) # Keep only region and district
# !!! Add in sub-district

# Add clusters (6 per district)
dummy_df <- dummy_df %>% crossing(cluster_n = 1:6) %>%
  mutate(cluster = sprintf("%02d%02d", district, cluster_n))

# Add 10 - 15 random households per cluster  
dummy_df <- dummy_df %>% mutate(hh_per_cluster = sample(10:15, n(), replace = TRUE)) %>%
  uncount(hh_per_cluster, .id = "hh_n") %>%
  mutate(hhid = )
  arrange(region, district, cluster, hh_n)


## Fill in the rest of the variables by..
  # Create a small subset of data manually and randomly draw?
  # Do each variable one by one?
  # Use some of the ChatGPT script below to automate variable creation?






# Code written with Chat GPT to create dummy code whole cloth
  # It kind of works.. 

# Null-coalescing helper
`%||%` <- function(a,b) if (is.null(a)) b else a

# ====== Paste your export column list here ======
desired_cols <- c(
  "date_interview","endtime","deviceid","note_intro","region","district",
  "subdistrict","cluster","hh_n","calc_hh_id","geopoint","_geopoint_latitude",
  "_geopoint_longitude","_geopoint_altitude","_geopoint_precision","latitude",
  "longitude","reason_nogps","present","introduced","participate","ic_check",
  "hohh_name","phone_n","hhr_voucher","voucher_qr","corr_voucher","voucher_n",
  "note_roster","calc_elig_count","calc_under5_count","calc_olderchild_count",
  "calc_adult_count","note_elig","note_under5","note_olderchild","note_adult",
  "visited","notreg","oth_notreg","hhr_record","rec_seen","rec_elig",
  "calc_rec_elig","hhr_verbal","verbal_elig","calc_verbal_elig","hhr_u5",
  "hhr_u5_elig","hhr_olderchild","hhr_olderch_elig","hhr_adult","hhr_adult_elig",
  "calc_hhr_elig_count","assessor_flag1","assessor_flag2","elig_check",
  "calc_elig_hhr","calc_elig_correct","elig_correct_yes","elig_correct_no",
  "reason_mismatch","oth_mismatch","descr_mismatch","aware","aware_source",
  "aware_source/1","aware_source/2","aware_source/3","aware_source/4",
  "aware_source/5","aware_source/6","aware_source/7","aware_source/8",
  "aware_source/9","aware_source/98","oth_aware_source","info_date",
  "correct_date","info_loc","correct_loc","sbc_hhrstaff","sbc_msg",
  "sbc_msg/1","sbc_msg/2","sbc_msg/3","sbc_msg/4","sbc_msg/5","sbc_msg/6",
  "sbc_msg/96","oth_sbc_msg","hh_visit_detail","note_result_chk1",
  "note_result_chk2","note_farewell_n","final_comments", 
  "_id","_uuid","_submission_time","_validation_status","_notes","_status",
  "_submitted_by","__version__","_tags","_index"
)

# ====== Function ======
generate_dummy_kobo_exact <- function(
    xlsform_path,
    desired_cols,
    seed = 42,
    # --- sample design ---
    lots = 50,                 # districts/lots
    clusters_per_lot = 6,
    hh_per_cluster = 10,       # EXACT interviewed HHs per cluster (present=yes, participate=yes)
    # extras (added in addition to the 10 interviewed HHs)
    not_present_rate = 0.05,   # expected share of EXTRA not-present HHs per cluster
    not_consent_rate = 0.03    # expected share of EXTRA non-consent HHs per cluster (among present)
) {
  if (!is.null(seed)) set.seed(seed)
  
  # -- load form --
  survey  <- read_excel(xlsform_path, sheet = "survey")  |> clean_names()
  choices <- read_excel(xlsform_path, sheet = "choices") |> clean_names()
  
  # -- map list_name -> vector of choice codes (character) --
  choice_map <- choices |>
    mutate(list_name = as.character(list_name), name = as.character(name)) |>
    group_by(list_name) |>
    reframe(values = list(name)) |>
    (\(d) setNames(d$values, d$list_name))()
  
  survey <- survey |> mutate(type = tolower(type))
  skip_exact <- c("note","begin group","end group","begin repeat","end repeat","calculate")
  survey_use <- survey |>
    filter(!is.na(name), name != "") |>
    filter(!tolower(type) %in% skip_exact)
  
  # helper: identify yes/no codes from a listname
  get_yes_no_codes <- function(list_nm) {
    opts <- choice_map[[list_nm]] %||% character(0)
    o_low <- tolower(opts)
    yes_idx <- which(o_low %in% c("1","yes","y","true"))
    no_idx  <- which(o_low %in% c("0","no","n","false"))
    yes <- if (length(yes_idx)) opts[yes_idx[1]] else if (length(opts)) opts[1] else "1"
    no  <- if (length(no_idx))  opts[no_idx[1]]  else if (length(opts) >= 2) opts[2] else "0"
    list(yes = yes, no = no)
  }
  
  # pull lists for location cascades (if present)
  district_df <- choices |> filter(list_name == "district_list") |>
    transmute(name_district = as.character(name), region = as.character(region))
  cluster_df  <- choices |> filter(list_name == "cluster_list")  |>
    transmute(name_cluster = as.character(name), district = as.character(district))
  subd_df     <- choices |> filter(list_name == "subdistr_list") |>
    transmute(name_subdistrict = as.character(name), district = as.character(district))
  
  # pick 50 districts
  if (nrow(district_df) >= lots) {
    districts <- unique(district_df$name_district)[1:lots]
  } else if (nrow(district_df) > 0) {
    districts <- rep(unique(district_df$name_district), length.out = lots)
  } else {
    districts <- sprintf("LOT%02d", 1:lots)
    district_df <- tibble(name_district = districts, region = NA_character_)
  }
  
  # pick clusters per district
  clusters_by_district <- map(districts, function(d) {
    pool <- cluster_df |> filter(district == d) |> pull(name_cluster)
    if (length(pool) >= clusters_per_lot) {
      sample(pool, clusters_per_lot)
    } else if (length(pool) > 0) {
      rep(pool, length.out = clusters_per_lot)
    } else {
      sprintf("%s_CL%02d", d, 1:clusters_per_lot)
    }
  })
  names(clusters_by_district) <- districts
  
  # --- BASE: 10 interviewed HHs per cluster (present=YES, participate=YES) ---
  base_design <- map_dfr(districts, function(d) {
    tibble(district = d, cluster = clusters_by_district[[d]])
  }) |>
    uncount(weights = hh_per_cluster, .remove = FALSE) |>
    mutate(hh_seq = ave(seq_len(n()), district, cluster, FUN = seq_along))
  
  # add region/subdistrict to base
  base_design <- base_design |>
    left_join(district_df |> select(district = name_district, region), by = "district") |>
    mutate(subdistrict = {
      if (nrow(subd_df)) {
        vapply(seq_len(n()), function(i) {
          pool <- subd_df |> filter(district == district[i]) |> pull(name_subdistrict)
          if (length(pool) == 0) NA_character_ else sample(pool, 1)
        }, character(1))
      } else NA_character_
    })
  
  # --- EXTRAS: random not-present and non-consent HHs per cluster (ADDED to the 10 interviewed) ---
  uc <- base_design |> distinct(district, cluster, region, subdistrict)
  extras <- pmap_dfr(list(uc$district, uc$cluster, uc$region, uc$subdistrict), function(d, c, rgn, subd) {
    k_np <- rbinom(1, size = hh_per_cluster, prob = not_present_rate)   # EXTRA not-present
    k_nc <- rbinom(1, size = hh_per_cluster, prob = not_consent_rate)   # EXTRA non-consent (present=yes)
    tibble(
      district = c(rep(d, k_np + k_nc)),
      cluster  = c(rep(c, k_np + k_nc)),
      region   = c(rep(rgn, k_np + k_nc)),
      subdistrict = c(rep(subd, k_np + k_nc)),
      extra_type  = c(rep("np", k_np), rep("nc", k_nc))
    )
  })
  
  # combine base + extras into one design table
  design_all <- base_design |>
    mutate(extra_type = NA_character_) |>
    bind_rows(extras |> mutate(hh_seq = NA_integer_)) |>
    mutate(row_id = row_number())
  
  # -- init output with design keys (only if in survey) --
  out <- tibble(.rows = nrow(design_all))
  if ("region"      %in% survey_use$name) out$region      <- design_all$region %||% NA_character_
  if ("district"    %in% survey_use$name) out$district    <- design_all$district
  if ("subdistrict" %in% survey_use$name) out$subdistrict <- design_all$subdistrict
  if ("cluster"     %in% survey_use$name) out$cluster     <- design_all$cluster
  
  # -- generator for other questions --
  gen_col <- function(type_str, qname) {
    t <- tolower(trimws(type_str %||% ""))
    
    if (qname %in% c("region","district","subdistrict","cluster")) return(NULL)
    
    if (str_starts(t, "select_one")) {
      ln <- str_replace(t, "^select_one\\s+", "")
      opts <- choice_map[[ln]]
      if (is.null(opts) || length(opts) == 0) return(rep(NA_character_, nrow(out)))
      return(sample(opts, nrow(out), TRUE))
    }
    if (str_starts(t, "select_multiple")) {
      ln <- str_replace(t, "^select_multiple\\s+", "")
      opts <- choice_map[[ln]] %||% character(0)
      if (length(opts) == 0) return(rep("", nrow(out)))
      v <- character(nrow(out))
      for (i in seq_len(nrow(out))) {
        kmax <- min(3, length(opts))
        k <- sample(0:kmax, 1, prob = rev(seq_len(kmax + 1)))
        v[i] <- if (k == 0) "" else paste(sample(opts, k), collapse = " ")
      }
      return(v)
    }
    
    if (t == "integer")   return(sample(0:10, nrow(out), TRUE))
    if (t == "decimal")   return(round(runif(nrow(out), 0, 100), 2))
    if (t == "date")      return(sample(seq(Sys.Date()-60, Sys.Date(), by="day"), nrow(out), TRUE))
    if (t == "time") {
      secs <- sample(0:(24*3600-1), nrow(out), TRUE)
      return(sprintf("%02d:%02d:%02d", secs%/%3600, (secs%%3600)%/%60, secs%%60))
    }
    if (t == "datetime") {
      base <- Sys.time()-60*60*24*60; return(base + runif(nrow(out), 0, 60*60*24*60))
    }
    if (t == "geopoint") {
      lat <- runif(nrow(out), -1, 1); lon <- runif(nrow(out), -1, 1)
      return(paste(round(lat, 6), round(lon, 6)))
    }
    if (t %in% c("start","end")) {
      base <- Sys.time()-60*60*24*30; return(base + runif(nrow(out), 0, 60*60*24*30))
    }
    if (t %in% c("text","string")) return(paste0(qname, "_", sample(100000:999999, nrow(out), TRUE)))
    
    return(rep(NA_character_, nrow(out)))
  }
  
  # generate remaining survey vars
  for (i in seq_len(nrow(survey_use))) {
    nm <- survey_use$name[i]; tp <- survey_use$type[i]
    if (!nm %in% names(out)) {
      vals <- gen_col(tp, nm)
      if (!is.null(vals)) out[[nm]] <- vals
    }
  }
  
  # -- enforce present/participate:
  # base rows (extra_type NA): present=YES, participate=YES
  present_row <- survey_use |> filter(name == "present") |> slice(1)
  part_row    <- survey_use |> filter(name == "participate") |> slice(1)
  
  pres_codes <- if (nrow(present_row) && str_starts(present_row$type, "select_one"))
    get_yes_no_codes(str_replace(present_row$type, "^select_one\\s+", ""))
  else list(yes = "1", no = "0")
  part_codes <- if (nrow(part_row) && str_starts(part_row$type, "select_one"))
    get_yes_no_codes(str_replace(part_row$type, "^select_one\\s+", ""))
  else list(yes = "1", no = "0")
  
  if ("present" %in% names(out)) {
    out$present <- ifelse(is.na(design_all$extra_type), pres_codes$yes, out$present)
  }
  if ("participate" %in% names(out)) {
    out$participate <- ifelse(is.na(design_all$extra_type), part_codes$yes, out$participate)
  }
  
  # extras: set according to type
  idx_np <- which(design_all$extra_type == "np")
  if (length(idx_np) && "present" %in% names(out)) out$present[idx_np] <- pres_codes$no
  if (length(idx_np) && "participate" %in% names(out)) out$participate[idx_np] <- part_codes$no
  
  idx_nc <- which(design_all$extra_type == "nc")
  if (length(idx_nc) && "present" %in% names(out)) out$present[idx_nc] <- pres_codes$yes
  if (length(idx_nc) && "participate" %in% names(out)) out$participate[idx_nc] <- part_codes$no
  
  # --- expand select_multiple split columns if requested ---
  smeta <- survey_use |>
    filter(str_starts(type, "select_multiple")) |>
    mutate(list_nm = str_replace(type, "^select_multiple\\s+", "")) |>
    transmute(qname = name, list_nm, opts = map(list_nm, ~ choice_map[[.x]] %||% character(0)))
  if (nrow(smeta)) {
    for (j in seq_len(nrow(smeta))) {
      q <- smeta$qname[j]; opts <- smeta$opts[[j]]
      if (!q %in% names(out)) next
      sel_list <- strsplit(out[[q]], "\\s+")
      for (opt in opts) {
        split_col <- paste0(q, "/", opt)
        if (split_col %in% desired_cols) {
          out[[split_col]] <- as.integer(vapply(sel_list, function(v) opt %in% v, logical(1)))
        }
      }
    }
  }
  
  # --- geopoint split columns if requested ---
  if ("geopoint" %in% names(out) && any(c("_geopoint_latitude","_geopoint_longitude") %in% desired_cols)) {
    latlon <- str_split(out$geopoint, "\\s+")
    get_part <- function(idx) vapply(latlon, function(x) ifelse(length(x)>=idx, x[[idx]], NA_character_), character(1))
    out[["_geopoint_latitude"]]  <- suppressWarnings(as.numeric(get_part(1)))
    out[["_geopoint_longitude"]] <- suppressWarnings(as.numeric(get_part(2)))
    out[["_geopoint_altitude"]]  <- NA_real_
    out[["_geopoint_precision"]] <- NA_real_
  }
  
  # convenience lat/long if requested but missing
  if ("latitude" %in% desired_cols && !"latitude" %in% names(out))
    out$latitude <- out[["_geopoint_latitude"]] %||% runif(nrow(out), -1, 1)
  if ("longitude" %in% desired_cols && !"longitude" %in% names(out))
    out$longitude <- out[["_geopoint_longitude"]] %||% runif(nrow(out), -1, 1)
  
  # Some handy fields if requested
  if ("deviceid" %in% desired_cols && !"deviceid" %in% names(out))
    out$deviceid <- sprintf("imei:%015d", sample(1e14:9e14, nrow(out), TRUE))
  if ("date_interview" %in% desired_cols && !"date_interview" %in% names(out))
    out$date_interview <- sample(seq(Sys.Date()-30, Sys.Date(), by="day"), nrow(out), TRUE)
  if ("endtime" %in% desired_cols && !"endtime" %in% names(out)) {
    secs <- sample(0:(24*3600-1), nrow(out), TRUE)
    out$endtime <- sprintf("%02d:%02d:%02d", secs%/%3600, (secs%%3600)%/%60, secs%%60)
  }
  
  # -- Kobo-like metadata --
  if (!("_uuid" %in% names(out))) {
    uuids <- replicate(nrow(out), UUIDgenerate())
    out[["_uuid"]] <- paste0("uuid:", substr(gsub("-", "", uuids), 1, 32))
  }
  if (!("_submission_time" %in% names(out)))
    out[["_submission_time"]] <- as.POSIXct(Sys.time()) - runif(nrow(out), 0, 60*60*24*30)
  if (!("_id" %in% names(out))) out[["_id"]] <- seq_len(nrow(out))
  if (!("_validation_status" %in% names(out))) out[["_validation_status"]] <- NA_character_
  if (!("_notes" %in% names(out))) out[["_notes"]] <- NA_character_
  if (!("_status" %in% names(out))) out[["_status"]] <- sample(c("submitted_via_web","submitted_via_app"), nrow(out), TRUE)
  if (!("_submitted_by" %in% names(out))) out[["_submitted_by"]] <- NA_character_
  if (!("__version__" %in% names(out))) out[["__version__"]] <- "v-dummy"
  if (!("_tags" %in% names(out))) out[["_tags"]] <- NA_character_
  if (!("_index" %in% names(out))) out[["_index"]] <- seq_len(nrow(out)) - 1L
  
  # -- add any missing desired columns with sensible NA defaults --
  add_missing <- setdiff(desired_cols, names(out))
  for (cn in add_missing) {
    if (grepl("^calc_|_count$|_index$|_elig$|_id$", cn)) {
      out[[cn]] <- as.integer(NA)
    } else if (grepl("date$", cn) || cn %in% c("date_interview","correct_date","info_date","distr_date")) {
      out[[cn]] <- as.Date(NA)
    } else if (grepl("time$", cn)) {
      out[[cn]] <- NA_character_
    } else if (grepl("^_geopoint_", cn) || cn %in% c("latitude","longitude")) {
      out[[cn]] <- as.numeric(NA)
    } else if (grepl("/", cn)) { # select_multiple splits → 0/1
      out[[cn]] <- as.integer(0)
    } else {
      out[[cn]] <- NA_character_
    }
  }
  
  # -- exact ordering to match the export --
  out |> select(any_of(desired_cols))
}

# ====== Example run ======
dummy_df <- generate_dummy_kobo_exact(
  "In-process - qq eligible persons v2.xlsx",
  desired_cols = desired_cols,
  seed = 42,
  lots = 50,
  clusters_per_lot = 6,
  hh_per_cluster = 10,   # fixed 10 interviewed HHs/cluster
  not_present_rate = 0.05,
  not_consent_rate = 0.03
)

# Quick checks
#nrow(df)                       # should be >= 3000 (3000 interviewed + extras)
# with(df, table(district))    # at least 60 per district (plus extras)
# with(df, table(present, participate, useNA="ifany"))

# Save if you want:
# write.csv(df, "dummy_export_like_kobo.csv", row.names = FALSE)
