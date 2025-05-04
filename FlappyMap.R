#======================================
#RUN ONCE ONLY -- install most of the commonly used R packages for geospatial data analysis
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}
remotes::install_github("ebird/ebird-best-practices")

# =============================================================================
# ⛔ RUN ONCE ONLY: Download and Save Southeast Asia GIS Data
#    Only rerun if the geopackage file is deleted or you want to refresh it.
# =============================================================================

library(dplyr)
library(rnaturalearth)
library(sf)

# File to save geopackage
gpkg_file <- "data/sea-gis-data.gpkg"
dir.create(dirname(gpkg_file), showWarnings = FALSE, recursive = TRUE)

# Define target Southeast Asian countries
target_countries <- c("Thailand", "Laos", "Vietnam", "Cambodia")
target_iso_a2 <- c("TH", "LA", "VN", "KH")

# -------------------------------------------------------------------------
# Land polygons (used to mask country border lines)
ne_land <- ne_download(scale = 50, category = "cultural",
                       type = "admin_0_countries_lakes",
                       returnclass = "sf") |>
  filter(ADMIN %in% target_countries) |>
  st_set_precision(1e6) |>
  st_union()

# -------------------------------------------------------------------------
# Country boundaries
ne_countries <- ne_download(scale = 50, category = "cultural",
                            type = "admin_0_countries_lakes",
                            returnclass = "sf") |>
  filter(ADMIN %in% target_countries) |>
  select(country = ADMIN, country_code = ISO_A2)

# -------------------------------------------------------------------------
# State/province boundaries
ne_states <- ne_download(scale = 50, category = "cultural",
                         type = "admin_1_states_provinces",
                         returnclass = "sf") |>
  filter(iso_a2 %in% target_iso_a2) |>
  select(state = name, state_code = iso_3166_2)

# -------------------------------------------------------------------------
# Land-only country border lines (filtered to Southeast Asia)
ne_country_lines <- ne_download(scale = 50, category = "cultural",
                                type = "admin_0_boundary_lines_land",
                                returnclass = "sf") |>
  st_geometry()
lines_on_land <- st_intersects(ne_country_lines, ne_land, sparse = FALSE) |>
  as.logical()
ne_country_lines <- ne_country_lines[lines_on_land]

# -------------------------------------------------------------------------
# Save all layers to a geopackage file
unlink(gpkg_file)  # delete existing geopackage if it exists
write_sf(ne_land, gpkg_file, "ne_land")
write_sf(ne_countries, gpkg_file, "ne_countries")
write_sf(ne_states, gpkg_file, "ne_states")
write_sf(ne_country_lines, gpkg_file, "ne_country_lines")

# =============================================================================
# 🔁 RERUN AFTER CRASH: Load and Combine SED Files from Southeast Asia
# =============================================================================

library(auk)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(lubridate)
library(readr)
library(sf)
library(purrr)

# Define SED file paths for all 4 countries
f_sed <- c("data-raw/ebd_KH_smp_relMar-2025_sampling.txt",  # Cambodia
           "data-raw/ebd_LA_smp_relMar-2025_sampling.txt",  # Laos
           "data-raw/ebd_TH_smp_relMar-2025_sampling.txt",  # Thailand
           "data-raw/ebd_VN_smp_relMar-2025_sampling.txt")  # Vietnam

# Read and combine all SED files
checklists <- map_dfr(f_sed, read_sampling)

# Preview combined dataset
glimpse(checklists)

# OPTIONAL: Show checklist counts per country
checklists |> count(country, sort = TRUE)
# =============================================================================
# 🔁 RERUN AFTER CRASH: Load eBird Observation File for Bar-bellied Pitta
# =============================================================================

# Define the file path for the eBird observation file (Bar-bellied Pitta)
f_ebd <- "data-raw/ebd_babpit1_smp_relMar-2025.txt"

# Read the eBird observations
observations <- read_ebd(f_ebd)

# Preview the eBird observations
glimpse(observations)
# =============================================================================
# 🔁 RERUN AFTER CRASH: Load and Combine SED Files for Southeast Asia
# =============================================================================

# Load required libraries
library(auk)
library(dplyr)
library(purrr)

# Define file paths for the 4 Southeast Asia SED files (Cambodia, Laos, Thailand, Vietnam)
f_sed <- c("data-raw/ebd_KH_smp_relMar-2025_sampling.txt",  # Cambodia
           "data-raw/ebd_LA_smp_relMar-2025_sampling.txt",  # Laos
           "data-raw/ebd_TH_smp_relMar-2025_sampling.txt",  # Thailand
           "data-raw/ebd_VN_smp_relMar-2025_sampling.txt")  # Vietnam

# Read and combine all SED files
checklists_shared <- map_dfr(f_sed, read_sampling, unique = FALSE)

# Identify shared checklists using group_identifier
shared_checklists <- checklists_shared |> 
  filter(!is.na(group_identifier)) |> 
  arrange(group_identifier) |> 
  select(sampling_event_identifier, group_identifier)

# Display a preview of the shared checklists
head(shared_checklists)
# =============================================================================
# 🔁 RERUN AFTER CRASH: Deduplicate Shared Checklists Using auk_unique()
# =============================================================================

# Load required libraries
library(auk)
library(dplyr)

# Combine all SED files into one shared checklists data frame
f_sed <- c("data-raw/ebd_KH_smp_relMar-2025_sampling.txt",  # Cambodia
           "data-raw/ebd_LA_smp_relMar-2025_sampling.txt",  # Laos
           "data-raw/ebd_TH_smp_relMar-2025_sampling.txt",  # Thailand
           "data-raw/ebd_VN_smp_relMar-2025_sampling.txt")  # Vietnam

# Read and combine all SED files
checklists_shared <- map_dfr(f_sed, read_sampling, unique = FALSE)

# =============================================================================
# Deduplicate Shared Checklists
# =============================================================================

# Apply auk_unique to identify unique checklists
checklists_unique <- auk_unique(checklists_shared, checklists_only = TRUE)

# Compare the number of rows before and after deduplication
cat("Before deduplication:", nrow(checklists_shared), "\n")
cat("After deduplication:", nrow(checklists_unique), "\n")

# Optional: Inspect the first few rows of the unique checklists
head(checklists_unique)
# =============================================================================
# 🔁 RERUN AFTER CRASH: Preview `checklist_id` in Unique Checklists
# =============================================================================

# Assuming you have already run the deduplication step and obtained `checklists_unique`

# Display the first few `checklist_id` values in the unique checklists
head(checklists_unique$checklist_id)
#> Output: First few checklist_ids after deduplication

# Display the last few `checklist_id` values in the unique checklists
tail(checklists_unique$checklist_id)
#> Output: Last few checklist_ids after deduplication
# Save the filtered data
write_csv(checklists, "data/filtered_checklists.csv")
write_csv(observations, "data/filtered_observations.csv")

# Reload them later if needed:
checklists <- read_csv("data/filtered_checklists.csv")
observations <- read_csv("data/filtered_observations.csv")
#================================================================
# filter the checklist data
checklists <- checklists |> 
  filter(all_species_reported)

# filter the observation data
observations <- observations |> 
  filter(all_species_reported)
#===================================================================
# =============================================================================
# 🔁 RERUN AFTER CRASH: Filter Checklists and Observations to Study Region
#    This step filters checklists to include only those within the Southeast Asia study region.
#    Rerun this after a crash if 'checklists' or 'observations' are lost.
# =============================================================================

# Load required libraries
library(dplyr)
library(sf)

# Convert checklist locations to points geometries
checklists_sf <- checklists |> 
  select(checklist_id, latitude, longitude) |> 
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# =============================================================================
# Define study region (buffered boundary for Southeast Asia countries: Thailand, Laos, Cambodia, Vietnam)
# =============================================================================

# Boundary of the study region, buffered by 1 km (using the `ne_countries` layer)
study_region_buffered <- read_sf("data/sea-gis-data.gpkg", layer = "ne_countries") |>
  # Project to a planar coordinate system to properly buffer the polygons
  st_transform(crs = 8857) |>
  filter(country_code %in% c("TH", "LA", "VN", "KH")) |>
  st_buffer(dist = 1000) |> 
  st_transform(crs = st_crs(checklists_sf))

# =============================================================================
# Spatially subset the checklists to those within the study region
# =============================================================================
in_region <- checklists_sf[study_region_buffered, ]

# =============================================================================
# Join to checklists and observations to remove checklists outside the region
# =============================================================================
checklists <- semi_join(checklists, in_region, by = "checklist_id")
observations <- semi_join(observations, in_region, by = "checklist_id")

# Optional: Preview the filtered checklists and observations
head(checklists)
head(observations)

#==================================================================================
# remove observations without matching checklists
observations <- semi_join(observations, checklists, by = "checklist_id")

#================================================================================
zf <- auk_zerofill(observations, checklists, collapse = TRUE)

#================================================================================
names(zf)  # Check column names
glimpse(zf)  # Get a brief overview of the dataset


#===============================================================================
# function to convert time observation to hours since midnight
time_to_decimal <- function(x) {
  x <- hms(x, quiet = TRUE)
  hour(x) + minute(x) / 60 + second(x) / 3600
}

# clean up variables
zf <- zf |> 
  mutate(
    # convert count to integer and X to NA
    # ignore the warning "NAs introduced by coercion"
    observation_count = as.integer(observation_count),
    # effort_distance_km to 0 for stationary counts
    effort_distance_km = if_else(protocol_name == "Stationary", 
                                 0, effort_distance_km),
    # convert duration to hours
    effort_hours = duration_minutes / 60,
    # speed km/h
    effort_speed_kmph = effort_distance_km / effort_hours,
    # convert time to decimal hours since midnight
    hours_of_day = time_to_decimal(time_observations_started),
    # split date into year and day of year
    year = year(observation_date),
    day_of_year = yday(observation_date)
  )

#=================================================================================
# additional filtering
zf_filtered <- zf |> 
  filter(protocol_name %in% c("Stationary", "Traveling"),
         effort_hours <= 6,
         effort_distance_km <= 10,
         effort_speed_kmph <= 100,
         number_observers <= 10)
#================================================================================
zf_filtered$type <- if_else(runif(nrow(zf_filtered)) <= 0.8, "train", "test")
# confirm the proportion in each set is correct
table(zf_filtered$type) / nrow(zf_filtered)
#> 
#>  test train 
#>   0.2   0.8
#================================================================================
checklists <- zf_filtered |> 
  select(checklist_id, observer_id, type,
         observation_count, species_observed, 
         state_code, locality_id, latitude, longitude,
         protocol_name, all_species_reported,
         observation_date, year, day_of_year,
         hours_of_day, 
         effort_hours, effort_distance_km, effort_speed_kmph,
         number_observers)

# Updated file name and directory for your Bar-bellied Pitta project
write_csv(checklists, "data/zero_filled_checklists_babpit_sea.csv", na = "")
#===============================================================================
# EXPLORATORY DATA ANALYSIS
#===============================================================================
# =============================================================================
# Load GIS data for Southeast Asia (Bar-bellied Pitta)
# =============================================================================

# Load GIS data for different layers
ne_land <- read_sf("data/sea-gis-data.gpkg", "ne_land") |> 
  st_geometry()

ne_country_lines <- read_sf("data/sea-gis-data.gpkg", "ne_country_lines") |> 
  st_geometry()

# Study region for Southeast Asia (Thailand, Laos, Vietnam, Cambodia)
study_region <- read_sf("data/sea-gis-data.gpkg", "ne_countries") |> 
  filter(country_code %in% c("TH", "LA", "VN", "KH")) |>  # Corrected to use country_code column
  st_geometry()

# =============================================================================
# Prepare eBird data for mapping (Bar-bellied Pitta observations)
# =============================================================================

checklists_sf <- checklists |> 
  # Convert to spatial points (latitude and longitude)
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) |> 
  select(species_observed)

# =============================================================================
# Map the data
# =============================================================================

par(mar = c(0.25, 0.25, 4, 0.25))

# Set up plot area
plot(st_geometry(checklists_sf), 
     main = "Bar-bellied Pitta eBird Observations",
     col = NA, border = NA)

# Add contextual GIS data
plot(ne_land, col = "#cfcfcf", border = "#888888", lwd = 0.5, add = TRUE)
plot(study_region, col = "#e6e6e6", border = NA, add = TRUE)
plot(ne_country_lines, col = "#ffffff", lwd = 1.5, add = TRUE)

# Plot eBird observations
# Not observed
plot(filter(checklists_sf, !species_observed),
     pch = 19, cex = 0.1, col = alpha("#555555", 0.25),
     add = TRUE)

# Observed
plot(filter(checklists_sf, species_observed),
     pch = 19, cex = 0.3, col = alpha("#4daf4a", 1),
     add = TRUE)

# Add a legend
legend("bottomright", bty = "n",
       col = c("#555555", "#4daf4a"),
       legend = c("eBird checklist", "Bar-bellied Pitta sightings"),
       pch = 19)

# Draw box around the plot
box()


#===============================================================================
# Check available layers in the GeoPackage
st_layers("data/sea-gis-data.gpkg")

#===============================================================================
# Load the ne_countries layer
ne_countries <- read_sf("data/sea-gis-data.gpkg", "ne_countries")

# Check the column names in the ne_countries layer
names(ne_countries)
#===============================================================================

# summarize data by hourly bins
breaks <- seq(0, 24)
labels <- breaks[-length(breaks)] + diff(breaks) / 2
checklists_time <- checklists |> 
  mutate(hour_bins = cut(hours_of_day, 
                         breaks = breaks, 
                         labels = labels,
                         include.lowest = TRUE),
         hour_bins = as.numeric(as.character(hour_bins))) |> 
  group_by(hour_bins) |> 
  summarise(n_checklists = n(),
            n_detected = sum(species_observed),
            det_freq = mean(species_observed))

# histogram
g_tod_hist <- ggplot(checklists_time) +
  aes(x = hour_bins, y = n_checklists) +
  geom_segment(aes(xend = hour_bins, y = 0, yend = n_checklists),
               color = "grey50") +
  geom_point() +
  scale_x_continuous(breaks = seq(0, 24, by = 3), limits = c(0, 24)) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = "Hours since midnight",
       y = "# checklists",
       title = "Distribution of observation start times")

# frequency of detection
g_tod_freq <- ggplot(checklists_time |> filter(n_checklists > 100)) +
  aes(x = hour_bins, y = det_freq) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = seq(0, 24, by = 3), limits = c(0, 24)) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Hours since midnight",
       y = "% checklists with detections",
       title = "Detection frequency")

# combine
grid.arrange(g_tod_hist, g_tod_freq)
#================================================================================
# summarize data by hour long bins
breaks <- seq(0, 6)
labels <- breaks[-length(breaks)] + diff(breaks) / 2
checklists_duration <- checklists |> 
  mutate(duration_bins = cut(effort_hours, 
                             breaks = breaks, 
                             labels = labels,
                             include.lowest = TRUE),
         duration_bins = as.numeric(as.character(duration_bins))) |> 
  group_by(duration_bins) |> 
  summarise(n_checklists = n(),
            n_detected = sum(species_observed),
            det_freq = mean(species_observed))

# histogram
g_duration_hist <- ggplot(checklists_duration) +
  aes(x = duration_bins, y = n_checklists) +
  geom_segment(aes(xend = duration_bins, y = 0, yend = n_checklists),
               color = "grey50") +
  geom_point() +
  scale_x_continuous(breaks = breaks) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = "Checklist duration [hours]",
       y = "# checklists",
       title = "Distribution of checklist durations")

# frequency of detection
g_duration_freq <- ggplot(checklists_duration |> filter(n_checklists > 100)) +
  aes(x = duration_bins, y = det_freq) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = breaks) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Checklist duration [hours]",
       y = "% checklists with detections",
       title = "Detection frequency")

# combine
grid.arrange(g_duration_hist, g_duration_freq)

#================================================================================
# summarize data by 1 km bins
breaks <- seq(0, 10)
labels <- breaks[-length(breaks)] + diff(breaks) / 2
checklists_dist <- checklists |> 
  mutate(dist_bins = cut(effort_distance_km, 
                         breaks = breaks, 
                         labels = labels,
                         include.lowest = TRUE),
         dist_bins = as.numeric(as.character(dist_bins))) |> 
  group_by(dist_bins) |> 
  summarise(n_checklists = n(),
            n_detected = sum(species_observed),
            det_freq = mean(species_observed))

# histogram
g_dist_hist <- ggplot(checklists_dist) +
  aes(x = dist_bins, y = n_checklists) +
  geom_segment(aes(xend = dist_bins, y = 0, yend = n_checklists),
               color = "grey50") +
  geom_point() +
  scale_x_continuous(breaks = breaks) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = "Distance travelled [km]",
       y = "# checklists",
       title = "Distribution of distance travelled")

# frequency of detection
g_dist_freq <- ggplot(checklists_dist |> filter(n_checklists > 100)) +
  aes(x = dist_bins, y = det_freq) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = breaks) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Distance travelled [km]",
       y = "% checklists with detections",
       title = "Detection frequency")

# combine
grid.arrange(g_dist_hist, g_dist_freq)
#===============================================================================
# summarize data
breaks <- seq(0, 10)
labels <- seq(1, 10)
checklists_obs <- checklists |> 
  mutate(obs_bins = cut(number_observers, 
                        breaks = breaks, 
                        label = labels,
                        include.lowest = TRUE),
         obs_bins = as.numeric(as.character(obs_bins))) |> 
  group_by(obs_bins) |> 
  summarise(n_checklists = n(),
            n_detected = sum(species_observed),
            det_freq = mean(species_observed))

# histogram
g_obs_hist <- ggplot(checklists_obs) +
  aes(x = obs_bins, y = n_checklists) +
  geom_segment(aes(xend = obs_bins, y = 0, yend = n_checklists),
               color = "grey50") +
  geom_point() +
  scale_x_continuous(breaks = breaks) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = "# observers",
       y = "# checklists",
       title = "Distribution of the number of observers")

# frequency of detection
g_obs_freq <- ggplot(checklists_obs |> filter(n_checklists > 100)) +
  aes(x = obs_bins, y = det_freq) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = breaks) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "# observers",
       y = "% checklists with detections",
       title = "Detection frequency")

# combine
grid.arrange(g_obs_hist, g_obs_freq)
#================================================================================
# LAND COVER DATA (environmental variables)
#===============================================================================
# RUN ONCE
# install luna
install.packages('luna', repos='https://rspatial.r-universe.dev')

#================================================================================
library(terra)
library(luna)
# lists all products that are currently searchable0
prod <- getProducts()
head(prod)
#==================================================================================
# List available MODIS products (including MCD12Q1)
modis_products <- getProducts("^MCD12Q1")

# Print the available MODIS MCD12Q1 products (check the versions available)
print(modis_products)
#===============================================================================
# Specify the MODIS product and version
product <- "MCD12Q1"
version <- "061"

# Define start and end dates (adjust as needed)
start <- "2001-01-01"
end <- "2022-12-31"

#================================================================================
install.packages("geodata")
library(geodata)

#=================================================================================
# Load the necessary library
library(geodata)

# Download administrative boundaries for each of the Southeast Asian countries
thailand <- gadm("Thailand", level=1, path=".")
laos <- gadm("Laos", level=1, path=".")
vietnam <- gadm("Vietnam", level=1, path=".")
cambodia <- gadm("Cambodia", level=1, path=".")

# Combine all the downloaded countries into a single spatial object
study_region <- rbind(thailand, laos, vietnam, cambodia)

# Check the structure of the combined data
str(study_region)

# At this point, 'study_region' contains all provinces of the four countries.
# Plot the entire Southeast Asia region (all provinces) from Thailand, Laos, Vietnam, Cambodia
plot(study_region, col="lightblue", main="Southeast Asia Region: Thailand, Laos, Vietnam, Cambodia")

# Check if all provinces have been included by inspecting unique 'NAME_1' values
print(unique(study_region$NAME_1))

#================================================================================
#print tiles used
aoi <- study_region

# Now, use getNASA to search for the data available for this region and time frame
mf <- luna::getNASA(product, start, end, aoi=aoi, download=FALSE)

# View the available MODIS data tiles for the specified AOI and time period
print(mf)

#================================================================================
# Define the directory to store the MODIS data
datadir <- "data/modis_data"  # Replace this with the path to your existing directory
dir.create(datadir, showWarnings = FALSE)  # Ensure the directory exists

#================================================================================
# EOSDIS credentials (make sure you have an account)
username <- "INPUT_USERNAME"
password <- "INPUT_PASSWORD" 
#===============================================================================
# Download the data to the specified directory
#Will run for ~5 mins
mf <- luna::getNASA(product, start, end, aoi=aoi, download=TRUE, overwrite=TRUE,
                    path=datadir, username=username, password=password)
# Check the names of the downloaded files
basename(mf)
#===============================================================================
library(terra)
library(stringr)

# Specify the directory where the MODIS data is stored
datadir <- "data/modis_data"  # Update this to your correct directory path

# Create directories for saving plots (Updated to your new directories)
dir.create("data/modis_2001_visuals", showWarnings = FALSE)
dir.create("data/modis_2022_visuals", showWarnings = FALSE)

# Extract the basename of the downloaded MODIS files
tile_files <- basename(mf)

# Filter files for the year 2001 and 2022
tile_files_2001 <- tile_files[grepl("A2001", tile_files)]  # Files for 2001
tile_files_2022 <- tile_files[grepl("A2022", tile_files)]  # Files for 2022

# Function to plot and save each tile as a separate file
plot_and_save_tiles <- function(tile_files_year, year, output_dir) {
  for (tile in tile_files_year) {
    # Load the raster tile (make sure to specify the full path)
    r <- rast(file.path(datadir, tile))
    
    # Extract the LC_Type2 layer (use the layer name you are interested in)
    r_type2 <- r[["LC_Type2"]]
    
    # Define the output file path for saving the plot
    output_file <- file.path(output_dir, paste0("tile_", gsub(".hdf", "", tile), ".png"))
    
    # Plot the raster layer (without geographical map and light blue of country shapes)
    plot(r_type2, main = paste("MODIS Landcover Type 2 -", year), col = viridis::viridis(17), legend = FALSE)
    
    # Save the plot to the specified folder as a PNG file
    png(output_file, width = 800, height = 600)  # Open the PNG device
    plot(r_type2, main = paste("MODIS Landcover Type 2 -", year), col = viridis::viridis(17), legend = FALSE)
    dev.off()  # Close the PNG device
    
    print(paste("Saved plot for", tile, "to", output_file))
  }
}

# Plot and save tiles for 2001 and 2022
plot_and_save_tiles(tile_files_2001, 2001, "data/modis_2001_visuals")
plot_and_save_tiles(tile_files_2022, 2022, "data/modis_2022_visuals")

print("Visualization for all tiles from 2001 and 2022 saved to respective directories.")

#===============================================================================
#Explore the downloaded file
# Load the necessary libraries
library(terra)

# Load the MODIS land cover raster file (adjust the path if needed)
landcover_raster <- rast("data/modis_data/MCD12Q1.A2001001.h26v06.061.2022146141813.hdf")

# Inspect the loaded data
print(landcover_raster)
#===============================================================================
# View the band names (layers)
names(landcover_raster)

#===============================================================================
# Plot the data for the first land cover type (LC_Type1)
plot(landcover_raster[["LC_Type2"]], 
     main = "MODIS Landcover Type 2 (2001-01-01, tile: h26v06)",
     axes = TRUE)

#================================================================================
# Load necessary libraries
library(terra)

# Specify the directory containing the HDF files (replace with your actual directory)
hdf_dir <- "data/modis_data"  # Adjust the path as necessary
output_dir <- "data/modis_tif_data"  # Specify where to save the TIF files

# Make sure the output directory exists, create if it doesn't
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

#================================================================================
# List all HDF files in the directory
hdf_files <- list.files(hdf_dir, pattern = "\\.hdf$", full.names = TRUE)

# Convert each HDF file to TIF
for (hdf_file in hdf_files) {
  
  # Read the HDF file
  raster_data <- rast(hdf_file)
  
  # Define the output TIF file path
  tif_file <- file.path(output_dir, paste0(basename(hdf_file), ".tif"))
  
  # Write the raster data to a TIF file
  writeRaster(raster_data, tif_file, overwrite = TRUE)
  
  # Check if the TIF file was created successfully
  if (file.exists(tif_file)) {
    message(paste("Successfully converted", basename(hdf_file), "to", basename(tif_file)))
  } else {
    warning(paste("Failed to convert", basename(hdf_file)))
  }
}
#================================================================================
# Optional: List all the newly created TIF files to confirm the conversion
tif_files <- list.files(output_dir, pattern = "\\.tif$", full.names = TRUE)
print(tif_files)
#================================================================================
# List all the .tif files
tif_files <- list.files(output_dir, pattern = "\\.tif$", full.names = TRUE)

# Extract tile numbers (e.g., h27v08) from filenames
extract_tile <- function(fname) {
  tile_match <- regmatches(fname, regexpr("h\\d{2}v\\d{2}", fname))
  return(tile_match)
}

# Create a named list to hold files by tile number
tile_map <- split(tif_files, sapply(tif_files, extract_tile))

# Print the result in readable format
for (tile in names(tile_map)) {
  cat("\n=== Tile", tile, "===\n")
  cat(paste0(basename(tile_map[[tile]]), collapse = "\n"), "\n")
}

#================================================================================
#Explore the tif files
library(terra)

# Specify the directory where your TIF files are stored
tif_dir <- "data/modis_tif_data"  # Adjust this path to your directory

# List all TIF files in the directory
tif_files <- list.files(tif_dir, pattern = "\\.tif$", full.names = TRUE)

# Load the first TIF file (you can change the index if you want to load a different file)
landcover_data <- rast(tif_files[1])

# Print the raster object to see its details
print(landcover_data)
#================================================================================
install.packages("future.apply")
#================================================================================
# BUG ############################################################################
# BUG ############################################################################
# BUG ############################################################################
# BUG ############################################################################
# BUG ############################################################################

#ChatGPT said it should run in 5-30 secs but it took very long (like 10 mins++) to run
# And that just 2 rows (I tried 2 rows--original file is 230238 rows)

# Generate circular buffers (3km diameter)
buffers <- checklists |>
  distinct(locality_id, year_lc, latitude, longitude) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) |>
  st_buffer(dist = set_units(1.5, "km"))

# =======================
# Reproject buffers to match MODIS
# =======================
buffers_proj <- st_transform(buffers, crs = crs(mosaics[[1]]))

# =======================
# Function to calculate landscape metrics
# =======================
get_metrics <- function(i) {
  buffer_i <- buffers_proj[i, ]
  year <- buffer_i$year_lc
  lc_raster <- mosaics[[year]]
  
  # Check overlap
  if (!terra::ext(buffer_i) %over% terra::ext(lc_raster)) {
    return(NULL)
  }
  
  # Crop + mask
  cropped <- terra::crop(lc_raster, buffer_i)
  masked <- terra::mask(cropped, buffer_i)
  
  # Landscape metrics
  lsm_i <- calculate_lsm(masked, level = "class", metric = c("pland", "ed"))
  lsm_i$locality_id <- buffer_i$locality_id
  lsm_i$year_lc <- year
  return(lsm_i)
}

# =======================
# Run in parallel
# =======================
start_time <- Sys.time()

lsm_list <- future_lapply(seq_len(nrow(buffers_proj)), get_metrics)
lsm <- bind_rows(lsm_list)

end_time <- Sys.time()
cat("Elapsed time:", end_time - start_time, "\n")

# =======================
# Preview results
# =======================
print(head(lsm, 2))


#Can you perform spatial subsampling following this? But since I have limited presence information,
#should I retain all presence records and subsample just the absence records? I also am not focusing on just any certain month,
#so should I ignore temporal subsampling?
#I want to subsample them before I extract the landscape metrics so it's not that slow like we've seen.  

#================================================================================
######################## I'm trying to reduce the tif files to only one band that I'll use
#not sure if it's going to make it faster

library(terra)

# Input/output directories
input_dir <- "data/modis_tif_data"
output_dir <- "data/modis_tif_lc_type2"
dir.create(output_dir, showWarnings = FALSE)

# List original MODIS .tif files
tif_files <- list.files(input_dir, pattern = "\\.tif$", full.names = TRUE)

# Process each file
for (f in tif_files) {
  message("Processing: ", basename(f))
  
  r <- rast(f)
  
  # Extract LC_Type2 layer only
  if (!"LC_Type2" %in% names(r)) {
    warning("Skipping file (LC_Type2 not found): ", basename(f))
    next
  }
  
  r2 <- r[["LC_Type2"]]
  
  # Create output path
  out_file <- file.path(output_dir, paste0(tools::file_path_sans_ext(basename(f)), "_LC_Type2.tif"))
  
  # Save the reduced raster
  writeRaster(r2, out_file, overwrite = TRUE)
}


#===============================================================================



