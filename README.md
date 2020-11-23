
<!-- README.md is generated from README.Rmd. Please edit that file -->

# schwartzGeohashPM

<!-- badges: start -->

[![R build
status](https://github.com/degauss-org/schwartzGeohashPM/workflows/R-CMD-check/badge.svg)](https://github.com/degauss-org/schwartzGeohashPM/actions)
<!-- badges: end -->

The goal of schwartzGeohashPM is to add PM2.5, NO2, and O3
concentrations to your data based on geohashed locations (usually output
from the [Schwartz Grid Lookup
Container](https://github.com/degauss-org/schwartz_grid_lookup))

## Installation

You can install addSchwartzGeohashPM from [GitHub](https://github.com/)
with:

``` r
# install.packages("remotes")
remotes::install_github("degauss-org/schwartzGeohashPM")
```

## Example

``` r
library(schwartzGeohashPM)

d <- tibble::tribble(
      ~id,         ~lat,    ~lon, ~site_index,      ~sitecode,  ~start_date,    ~end_date,
      '55000100280', 39.2, -84.6,   '9607238', 211050640897, '2008-09-09', '2008-09-11',
      '55000100281', 39.2, -84.6,   '9607238', 211050640897, '2007-08-05', '2007-08-08',
      '55000100282', 39.2, -84.6,   '9607238', 211050640897, '2015-08-31', '2015-09-02') %>%
    dplyr::mutate_at(dplyr::vars(start_date, end_date), as.Date)

add_schwartz_pollutants(d)
#> Matching sitecodes to geohashes...
#> ℹ 3 files totaling 197.90 MB will be downloaded to /Users/RASV5G/OneDrive - cchmc/schwartzGeohashPM/s3_downloads
#> ! User input requested, but session is not interactive.
#> ℹ Assuming this is okay.
#> → Downloading 3 files.
#> → Got 0 files, downloading 3
#> → Got 1 file, downloading 2
#> → Got 2 files, downloading 1
#> ✓ Downloaded 3 files in 41.9s.
#> Now reading in and joining pollutant data.
#> # A tibble: 10 x 15
#>    id      lat   lon site_index sitecode start_date end_date   date      
#>    <chr> <dbl> <dbl> <chr>         <dbl> <date>     <date>     <date>    
#>  1 5500…  39.2 -84.6 9607238     2.11e11 2007-08-05 2007-08-08 2007-08-05
#>  2 5500…  39.2 -84.6 9607238     2.11e11 2007-08-05 2007-08-08 2007-08-06
#>  3 5500…  39.2 -84.6 9607238     2.11e11 2007-08-05 2007-08-08 2007-08-07
#>  4 5500…  39.2 -84.6 9607238     2.11e11 2007-08-05 2007-08-08 2007-08-08
#>  5 5500…  39.2 -84.6 9607238     2.11e11 2008-09-09 2008-09-11 2008-09-09
#>  6 5500…  39.2 -84.6 9607238     2.11e11 2008-09-09 2008-09-11 2008-09-10
#>  7 5500…  39.2 -84.6 9607238     2.11e11 2008-09-09 2008-09-11 2008-09-11
#>  8 5500…  39.2 -84.6 9607238     2.11e11 2015-08-31 2015-09-02 2015-08-31
#>  9 5500…  39.2 -84.6 9607238     2.11e11 2015-08-31 2015-09-02 2015-09-01
#> 10 5500…  39.2 -84.6 9607238     2.11e11 2015-08-31 2015-09-02 2015-09-02
#> # … with 7 more variables: gh6 <chr>, gh3 <chr>, year <dbl>,
#> #   gh3_combined <chr>, PM25 <dbl>, NO2 <dbl>, O3 <dbl>
```
