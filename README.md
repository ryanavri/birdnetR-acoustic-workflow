# birdnetR Acoustic Workflow

This repository provides a simple R workflow for running BirdNET acoustic classification using the `birdnetR` package. The workflow was developed for processing passive acoustic monitoring data from both mono and stereo recording devices, including AudioMoth and Song Meter / SM4 recorders.

The script supports two common recording situations:

1. **Mono recordings**, such as standard AudioMoth files, which can be analysed directly using `birdnetR`.
2. **Stereo recordings**, such as some Song Meter / SM4 files, which are first converted into mono by selecting one channel before running BirdNET.

The workflow also reformats BirdNET outputs into a cleaner final dataset by extracting recording date and time from filenames.

## Main features

* Predict BirdNET prediction on Song Meter and or Audiomoth
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

The `birdnetR` package should be installed following the official installation instructions from the BirdNET Repos.

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
