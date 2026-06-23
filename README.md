# birdnetR Acoustic Workflow

This repository provides a simple R workflow for running BirdNET acoustic classification using the `birdnetR` package. The workflow was developed for processing passive acoustic monitoring data from both mono and stereo recording devices, including AudioMoth and Song Meter / SM4 recorders.

The script supports two common recording situations:

1. **Mono recordings**, such as standard AudioMoth files, which can be analysed directly using `birdnetR`.
2. **Stereo recordings**, such as some Song Meter / SM4 files, which are first converted into mono by selecting one channel before running BirdNET.

The workflow also reformats BirdNET outputs into a cleaner final dataset by extracting recording date and time from filenames.

## Repository structure

```text
birdnetR-acoustic-workflow/
│
├── README.md
├── scripts/
│   └── 01_birdnetR_acoustic_workflow.R
│
├── data/
│   └── README.md
│
├── outputs/
│   └── README.md
└── .gitignore
```

## Main features

The workflow includes:

* loading the BirdNET model through `birdnetR`;
* listing audio files from station folders;
* running BirdNET prediction on mono recordings;
* converting stereo recordings to mono by selecting the left or right channel;
* running BirdNET prediction on converted Song Meter / SM4 files;
* combining outputs from multiple sampling points or stations;
* extracting recording date and time from filenames;
* filtering detections by confidence threshold;
* saving the final BirdNET detection table as a CSV file.

## Required R packages

The workflow uses the following R packages:

```r
library(birdnetR)
library(tidyverse)
library(tuneR)
library(lubridate)
library(hms)
```

Install missing packages before running the script.

```r
install.packages(c("tidyverse", "tuneR", "lubridate", "hms"))
```

The `birdnetR` package should be installed following the official installation instructions from the BirdNET team.

## BirdNET model

The workflow uses the TensorFlow Lite BirdNET model.

```r
model <- birdnet_model_tflite(
  version = "v2.4",
  language = "en_us"
)
```

The model only needs to be downloaded or initialized the first time. Newer BirdNET model versions may be used if available.

## Input data

Audio files should be arranged by station or sampling point. For example:

```text
data/
├── SL_T1_P1/
│   ├── 20260112_092000.WAV
│   ├── 20260112_093000.WAV
│   └── 20260112_094000.WAV
│
└── SL_T1_P5/
    ├── S4A07878_20260117_092000.wav
    ├── S4A07878_20260117_093000.wav
    └── S4A07878_20260117_094000.wav
```

The workflow can read common audio formats, including:

```text
.wav
.WAV
.mp3
.flac
```

## Filename format

The script extracts recording date and time from filenames using the pattern:

```text
YYYYMMDD_HHMMSS
```

This means the workflow can handle both of the following filename formats:

```text
20260112_103000.WAV
S4A07878_20260117_092000_R.wav
```

These will be converted into recording date and time fields such as:

```text
2026-01-12 10:30:00
2026-01-17 09:20:00
```

## Mono recordings: AudioMoth example

AudioMoth recordings are usually mono and can be analysed directly.

```r
SL_T01_P1 <- process_station(
  station_id = "SL_T01_P1",
  audio_dir = "SL_T1_P1",
  audio_type = "mono",
  model = model,
  min_confidence = min_conf
)
```

## Stereo recordings: Song Meter / SM4 example

Song Meter / SM4 recordings may be stereo. In this workflow, one channel is selected and converted to mono before BirdNET analysis.

```r
SL_T01_P5 <- process_station(
  station_id = "SL_T01_P5",
  audio_dir = "SL_T1_P5",
  audio_type = "stereo",
  channel = "right",
  model = model,
  min_confidence = min_conf
)
```

The channel can be changed to `"left"` if needed.

```r
channel = "left"
```

Only one channel is selected to avoid doubling detections from the same recording. The original stereo files are not modified. Converted mono files are saved in a temporary mono folder inside the station folder.

## Confidence threshold

The confidence threshold can be changed here:

```r
min_conf <- 0.55
```

A higher threshold will usually produce fewer but more reliable detections. A lower threshold will produce more detections but may include more false positives.

The threshold should be selected based on project objectives, target species, local species list, and manual validation where possible.

## Final output

The final dataset includes:

```text
Point
file_name
file_path
recording_date
recording_time
recording_datetime
start
end
scientific_name
common_name
confidence
```

The final output is saved as a CSV file:

```r
write_csv(
  birdnet_final,
  paste0("birdnet_final_conf_", min_conf, ".csv")
)
```

Example output filename:

```text
birdnet_final_conf_0.55.csv
```

## Notes and limitations

This workflow is intended as a practical starting point for processing passive acoustic monitoring data using `birdnetR`.

Some important considerations:

* BirdNET results should be reviewed carefully, especially for rare species or unexpected detections.
* Confidence thresholds are project-specific and should not be treated as universal.
* Stereo recordings are simplified by selecting one channel only.
* If both stereo channels are analysed separately, detections may be duplicated and should be handled carefully.
* Local species lists and manual validation are recommended for improving data reliability.
* The workflow assumes filenames contain a date-time pattern in the format `YYYYMMDD_HHMMSS`.

## Suggested citation

If this workflow is used in a report or publication, please cite BirdNET and `birdnetR` according to the official recommendations from the BirdNET team.

## Author

Developed as a practical R workflow for biodiversity and acoustic monitoring using BirdNET.
