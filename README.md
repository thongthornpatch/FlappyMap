##  Project Summary: FlappyMap - AI for Bird Discovery

My goal is to map the **encounter rate** and **relative abundance** of the **Bar-bellied Pitta** across **Thailand, Laos, Cambodia, and Vietnam**, using a combination of **eBird citizen science data** and **MODIS satellite land cover data**. Below is a step-by-step explanation of what I’ve done so far and how it ties into the overall objective.

---

##  Step-by-Step Summary (with Context and Terms Explained)

###  1. Installing Required R Packages

I started by installing all the necessary R packages for spatial and environmental data analysis (`auk`, `terra`, `sf`, `landscapemetrics`, etc.). These tools allow me to clean, visualize, and analyze bird occurrence data and satellite-derived environmental variables.

---

###  2. Preparing Geographic Boundaries for Southeast Asia

To focus my analysis on the Bar-bellied Pitta’s potential range, I downloaded vector GIS layers for **Thailand, Laos, Vietnam, and Cambodia**. I saved administrative boundaries (country, state), landmass shapes, and country lines into a single **GeoPackage** file. I also buffered the study area slightly to catch edge checklists and avoid clipping.

 *Terms*:

* **GeoPackage (.gpkg)**: a multi-layer spatial data file.
* **Buffer**: expands the boundary outward by a set distance (1 km in my case).

---

###  3. Loading and Combining eBird Sampling Event and Observation Data

I downloaded eBird Sampling Event Data (SED) for the four countries and combined them. Then, I loaded eBird Observational Data (EBD) specifically for the **Bar-bellied Pitta**. These datasets together provide complete information on:

* When and where a checklist occurred,
* How long it lasted and how far observers traveled,
* Whether the Pitta was detected or not.

---

###  4. Deduplicating Shared Checklists

Since multiple people can submit the same checklist during a birding trip, I removed duplicates using `auk_unique()` to prevent overcounting.

 *Group identifiers* in eBird indicate shared checklists between birders in the same party.

---

###  5. Filtering to the Study Region

I filtered all checklists to keep only those inside my defined Southeast Asia study region. I used spatial joins and projections to ensure the checklist coordinates aligned properly with the study area geometry.

---

###  6. Creating a Presence-Absence Dataset (Zero-Fill)

I ran `auk_zerofill()` to turn species observation data into a full presence-absence dataset, so that each checklist explicitly states whether the Bar-bellied Pitta was **observed (TRUE)** or **not observed (FALSE)**.

---

###  7. Feature Engineering: Effort and Time Variables

I cleaned up effort variables to account for detectability differences:

* Converted observation duration to **effort hours**,
* Computed **effort speed** (km/hr),
* Parsed start times into **decimal hours**,
* Extracted **year** and **day-of-year** for future filtering or modeling.

These help control for factors that affect whether a bird is likely to be detected.

---

###  8. Filtering Low-Quality Checklists

I filtered out checklists that had:

* Duration > 6 hours,
* Distance > 10 km,
* Speed > 100 km/h,
* More than 10 observers,
* Or didn’t report all species.

These quality filters ensure that my effort and species detection data are trustworthy.

---

###  9. Train/Test Split

I split the filtered dataset randomly into **80% training** and **20% test** sets to eventually validate predictive models.

---

###  10. Exploratory Data Analysis (EDA)

To understand the checklist distribution and detection behavior, I visualized:

* Time of day vs. detection frequency,
* Effort duration, distance, and number of observers,
* Presence locations of the Bar-bellied Pitta.

This helped me understand detection biases and observation patterns.

---

###  11. Downloading MODIS Land Cover Data

I used the **MODIS MCD12Q1** satellite product to get annual land cover data (2001–2022) across Southeast Asia. I downloaded all tiles that covered my study area, and focused on the **LC\_Type2** layer, which provides a more detailed vegetation classification.

 MODIS stores land cover in "tiles" (e.g., h26v06) that need to be mosaicked to cover large regions.

---

###  12. Visualizing MODIS Tiles

I created preview plots of MODIS tiles for 2001 and 2022 to confirm coverage and check for missing data or misalignment.

---

###  13. Converting MODIS HDF to TIF (and reducing size)

I converted `.hdf` satellite files to `.tif`, and then extracted only the **LC\_Type2** band from each tile to save space and speed up processing later. These simplified rasters will be used for extracting environmental data.

---

###  14. Buffering eBird Checklists

To analyze the habitat around each observation, I created **2 km buffers** around unique checklist locations (rather than 3 km to reduce computational load). This lets me extract land cover composition and structure from MODIS for each checklist location.

 Buffers represent the "local landscape context" sampled by the observer.

---

###  15. Calculating Landscape Metrics - PROBLEM

For each buffer, I:

* Extracted the corresponding year’s land cover raster,
* Cropped and masked it to the buffer,
* Calculated metrics like:

  * **PLAND**: % of area covered by each land cover class,
  * **ED**: edge density (how fragmented the habitat is).

These metrics summarize habitat structure and composition around each checklist.

 These features are used in habitat suitability modeling and encounter rate prediction.

---

###  16. Parallelizing to Speed Up Processing - PROBLEM

I parallelized the landscape metric extraction using `future.apply`, which helped, but performance was still slow on my machine. Extracting metrics for just 2 rows took several minutes, mostly due to disk I/O and raster cropping.

---

###  17. Planned Optimization: Subsampling - PROBLEM

To deal with this, I plan to:

* **Retain all presence records**, and
* **Subsample non-detections** spatially using a 3x3 km grid (as recommended in eBird best practices),
* **Skip temporal subsampling**, since I’m modeling over a broad time range.

This will reduce the dataset size, speed up processing, and help with class imbalance.

---

##  Summary of Technical Terms (for Clarity)

| Term                 | Meaning                                        |
| -------------------- | ---------------------------------------------- |
| **Checklist**        | A birdwatcher’s report from a single outing    |
| **Zero-fill**        | Creating FALSE values for species not observed |
| **MODIS**            | Satellite-based land cover product from NASA   |
| **LC\_Type2**        | MODIS layer classifying vegetation types       |
| **PLAND / ED**       | Landscape metrics for composition/structure    |
| **Buffer**           | Circular zone around a point for analysis      |
| **Mosaic**           | Stitching MODIS tiles into a continuous raster |
| **Raster vs Vector** | Grid-based vs shape-based spatial data         |
