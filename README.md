
<!-- README.md is generated from README.Rmd. Please edit that file -->

# schwartzGeohashPM

<!-- badges: start -->

[![R build
status](https://github.com/degauss-org/schwartzGeohashPM/workflows/R-CMD-check/badge.svg)](https://github.com/degauss-org/schwartzGeohashPM/actions)
<!-- badges: end -->

The goal of schwartzGeohashPM is to add PM2.5, NO2, and O3
concentrations to your data based on geohashed locations (usually output
from the (Schwartz Grid Lookup
Container)\[<https://github.com/degauss-org/schwartz_grid_lookup>\])

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
library(dplyr)
#> Warning: replacing previous import 'vctrs::data_frame' by
#> 'tibble::data_frame' when loading 'dplyr'
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

d <- tibble::tribble(
      ~id,         ~lat,    ~lon, ~site_index,      ~sitecode,  ~start_date,    ~end_date,
      '55000100280', 39.2, -84.6,   '9607238', '211050640897', '2008-09-09', '2008-09-11',
      '55000100281', 39.2, -84.6,   '9607238', '211050640897', '2007-08-05', '2007-08-08',
      '55000100282', 39.2, -84.6,   '9607238', '211050640897', '2015-08-31', '2015-09-02') %>%
    dplyr::mutate_at(vars(start_date, end_date), as.Date)

add_schwartz_pollutants(d)
#> All files are present in /Users/RASV5G/OneDrive - cchmc/schwartzGeohashPM/s3_downloads
#> 
... :what (  0%) [ ETA:  ?s | Elapsed:  0s ]
... processing 1 of 3 ( 33%) [ ETA:  0s | Elapsed:  0s ]
... processing 2 of 3 ( 67%) [ ETA:  9s | Elapsed: 18s ]
... processing 3 of 3 (100%) [ ETA:  0s | Elapsed: 27s ]
#> # A tibble: 10 x 15
#>    id      lat   lon site_index sitecode start_date end_date   date      
#>    <chr> <dbl> <dbl> <chr>      <chr>    <date>     <date>     <date>    
#>  1 5500…  39.2 -84.6 9607238    2110506… 2007-08-05 2007-08-08 2007-08-05
#>  2 5500…  39.2 -84.6 9607238    2110506… 2007-08-05 2007-08-08 2007-08-06
#>  3 5500…  39.2 -84.6 9607238    2110506… 2007-08-05 2007-08-08 2007-08-07
#>  4 5500…  39.2 -84.6 9607238    2110506… 2007-08-05 2007-08-08 2007-08-08
#>  5 5500…  39.2 -84.6 9607238    2110506… 2008-09-09 2008-09-11 2008-09-09
#>  6 5500…  39.2 -84.6 9607238    2110506… 2008-09-09 2008-09-11 2008-09-10
#>  7 5500…  39.2 -84.6 9607238    2110506… 2008-09-09 2008-09-11 2008-09-11
#>  8 5500…  39.2 -84.6 9607238    2110506… 2015-08-31 2015-09-02 2015-08-31
#>  9 5500…  39.2 -84.6 9607238    2110506… 2015-08-31 2015-09-02 2015-09-01
#> 10 5500…  39.2 -84.6 9607238    2110506… 2015-08-31 2015-09-02 2015-09-02
#> # … with 7 more variables: gh6 <chr>, gh3 <chr>, year <dbl>,
#> #   gh3_combined <chr>, PM25 <dbl>, NO2 <dbl>, O3 <dbl>
```
