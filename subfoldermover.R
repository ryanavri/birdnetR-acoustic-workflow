# Main folder containing the subfolders
main_dir <- "E:/00_Biodive_IP_allsite/02_KSL/04_Survei_Kehati/Sarolangun/Wald/Avifauna/Dokumentasi/Audio/SL_T22/AudioMoth"

# Find all files inside subfolders
files <- list.files(
  main_dir,
  recursive = TRUE,
  full.names = TRUE
)

# Keep only files that are not already directly in main_dir
files_to_move <- files[dirname(files) != normalizePath(main_dir)]

# New destination: one level above each file's current folder
new_paths <- file.path(dirname(dirname(files_to_move)), basename(files_to_move))

# Move files
file.rename(files_to_move, new_paths)
