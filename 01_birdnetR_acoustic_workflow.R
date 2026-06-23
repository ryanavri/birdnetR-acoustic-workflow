# BirdNET Acoustic Analysis Workflow
# For AudioMoth mono files and Song Meter / SM4 stereo files
library(birdnetR)
library(tidyverse)
library(tuneR)
library(lubridate)
library(hms)


# 0. Initialize / load BirdNET model ----

# You only need to download the model once.
# You need to check whether birdnet has latest update model from their website
# birdnet_model_tflite("v2.4")
# birdnet_model_protobuf("v2.4")
model <- birdnet_model_tflite(
  version = "v2.4",
  language = "en_us"
)


# 1. General settings ----
min_conf <- 0.55 # Could set in here or in each code

# Note:
# 0.55 is an arbitrary threshold.
# Higher threshold = fewer detections, but usually more reliable.
# Lower threshold = more detections, but higher chance of false positives.


# 2. Functions ----
## 2.1 List audio files from a folder ----
list_audio_files <- function(audio_dir) {
  list.files(
    audio_dir,
    pattern = "\\.(wav|WAV|mp3|flac)$",
    full.names = TRUE,
    ignore.case = TRUE
  )
}


## 2.2 Convert stereo files to mono by selecting one channel ----

# This is mainly used for Song Meter / SM4 files.
# birdnetR v0.3.2 works best with mono files, so stereo files
# are converted into mono before prediction.

# channel can be "right" or "left".
# At the moment, only one channel is selected to avoid doubling
# detections from the same recording.
convert_stereo_to_mono <- function(
    in_dir,
    out_dir,
    channel = "right"
) {
  
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  
  files <- list_audio_files(in_dir)
  
  if (length(files) == 0) {
    stop("No audio files found in: ", in_dir)
  }
  
  for (f in files) {
    
    message("Checking/converting: ", basename(f))
    
    wav <- readWave(f)
    base <- tools::file_path_sans_ext(basename(f))
    
    if (wav@stereo) {
      
      wav_mono <- mono(wav, which = channel)
      
      suffix <- ifelse(channel == "right", "_R.wav", "_L.wav")
      
      writeWave(
        wav_mono,
        file.path(out_dir, paste0(base, suffix))
      )
      
    } else {
      
      # If the file is already mono, copy it into the mono folder
      writeWave(
        wav,
        file.path(out_dir, paste0(base, "_mono.wav"))
      )
    }
  }
  
  message("Finished preparing mono files in: ", out_dir)
}


## 2.3 Run BirdNET prediction for one folder ----
run_birdnet_folder <- function(
    audio_dir,
    station_id,
    model,
    min_confidence = 0.55
) {
  
  audio_files <- list_audio_files(audio_dir)
  
  if (length(audio_files) == 0) {
    stop("No audio files found in: ", audio_dir)
  }
  
  birdnet_results <- map_dfr(audio_files, function(file) {
    
    message("Processing: ", basename(file))
    
    pred <- predict_species_from_audio_file(
      model = model,
      audio_file = file,
      min_confidence = min_confidence,
      batch_size = 1L,
      keep_empty = FALSE
    )
    
    pred %>%
      mutate(
        file_path = file,
        file_name = basename(file),
        Point = station_id
      )
  })
  
  return(birdnet_results)
}


## 2.4 Process one station ----
# audio_type:
#   "mono"   = AudioMoth or already-mono recordings
#   "stereo" = Song Meter / SM4 stereo recordings

process_station <- function(
    station_id,
    audio_dir,
    audio_type = "mono",
    channel = "right",
    model,
    min_confidence = 0.55
) {
  
  if (audio_type == "mono") {
    
    message("Running mono station: ", station_id)
    
    results <- run_birdnet_folder(
      audio_dir = audio_dir,
      station_id = station_id,
      model = model,
      min_confidence = min_confidence
    )
    
  } else if (audio_type == "stereo") {
    
    message("Running stereo station: ", station_id)
    
    mono_dir <- file.path(audio_dir, paste0("Mono_", channel))
    
    convert_stereo_to_mono(
      in_dir = audio_dir,
      out_dir = mono_dir,
      channel = channel
    )
    
    results <- run_birdnet_folder(
      audio_dir = mono_dir,
      station_id = station_id,
      model = model,
      min_confidence = min_confidence
    )
    
  } else {
    
    stop("audio_type must be either 'mono' or 'stereo'")
  }
  
  return(results)
}



# 3. Run BirdNET for each station----


## 3.1 AudioMoth example ----
# AudioMoth files are usually mono, so audio_type = "mono".

SL_T01_P1 <- process_station(
  station_id = "SL_T01_P1", #Change this to your station/folder
  audio_dir = "SL_T1_P1",   #Change this to your station/folder
  audio_type = "mono",
  model = model,
  min_confidence = min_conf #Change to your desire conf
)


## 3.2 Song Meter / SM4 example ----

# Song Meter / SM4 files may be stereo, so audio_type = "stereo".
# The script will extract one channel and save it in a temporary
# mono folder before running BirdNET.

SL_T01_P5 <- process_station(
  station_id = "SL_T01_P5", # Change this to your station/folder
  audio_dir = "SL_T1_P5",   # Change this to your station/folder
  audio_type = "stereo",    
  channel = "right",        # Change to your desire channel
  model = model,
  min_confidence = min_conf # Change to your desire conf
)


# 4. Combine all station results ----
full_list <- bind_rows(
  SL_T01_P1,
  SL_T01_P5
)

# glimpse(full_list)


# 5. Reformat into final dataset ----

# This extracts recording date and time from filenames.

# It works for both filename formats:
#   20260112_103000.WAV
#   S4A07878_20260117_092000_R.wav

# Because the code searches for this pattern anywhere in the filename:
#   YYYYMMDD_HHMMSS

birdnet_final <- full_list %>%
  mutate(
    # Extract datetime pattern wherever it appears in filename
    datetime_raw = str_extract(file_name, "\\d{8}_\\d{6}"),
    
    # Separate date and time
    recording_date_raw = str_sub(datetime_raw, 1, 8),
    recording_time_raw = str_sub(datetime_raw, 10, 15),
    
    # Convert date
    recording_date = ymd(recording_date_raw),
    
    # Convert time
    recording_time = as_hms(
      paste0(
        str_sub(recording_time_raw, 1, 2), ":",
        str_sub(recording_time_raw, 3, 4), ":",
        str_sub(recording_time_raw, 5, 6)
      )
    ),
    
    # Combine date and time into one datetime column
    recording_datetime = ymd_hms(
      paste0(recording_date_raw, recording_time_raw),
      tz = "Asia/Jakarta"
    )
  ) %>%
  filter(confidence >= min_conf) %>%
  select(
    Point,
    file_name,
    file_path,
    recording_date,
    recording_time,
    recording_datetime,
    start,
    end,
    scientific_name,
    common_name,
    confidence
  )

# glimpse(birdnet_final)



# 6. Save final output----
write_csv(
  birdnet_final,
  paste0("birdnet_final_conf_", min_conf, ".csv")
)