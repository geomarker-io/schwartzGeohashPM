delete_test_download_folder <- function() {
  download_folder <- getOption("s3.download_folder", fs::path_wd("s3_downloads"))
  if (fs::dir_exists(download_folder)) {
    fs::dir_delete(download_folder)
    cli::cli_alert_success("Deleted {download_folder}")
  }
}

example_input <- function() {
  tibble::tribble(
    ~id,         ~lat,    ~lon, ~site_index,      ~sitecode,  ~start_date,    ~end_date,
    '55000100280', 39.2, -84.6,   '9607238', 211050640897, '2008-09-09', '2008-09-11',
    '55000100282', 39.2, -84.6,   '9607238', 211050640897, '2015-08-31', '2015-09-02') %>%
    dplyr::mutate_at(dplyr::vars(start_date, end_date), as.Date)
}

example_output <- function() {
  tibble::tribble(
    ~id, ~lat,  ~lon, ~site_index,    ~sitecode,  ~start_date,    ~end_date,        ~date,  ~year,     ~gh6,  ~gh3, ~gh3_combined, ~PM25, ~NO2,  ~O3,
    "55000100280", 39.2, -84.6,   "9607238", 211050640897, "2008-09-09", "2008-09-11", "2008-09-09", 2008, "dngz52", "dng", "dng",   8.4, 27.7, 22.2,
    "55000100280", 39.2, -84.6,   "9607238", 211050640897, "2008-09-09", "2008-09-11", "2008-09-10", 2008, "dngz52", "dng", "dng",  10.2, 22.8, 21.2,
    "55000100280", 39.2, -84.6,   "9607238", 211050640897, "2008-09-09", "2008-09-11", "2008-09-11", 2008, "dngz52", "dng", "dng",  15.9, 27.8, 21.8,
    "55000100282", 39.2, -84.6,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-08-31", 2015, "dngz52", "dng", "dng",  12.3, 32.7, 33.6,
    "55000100282", 39.2, -84.6,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-09-01", 2015, "dngz52", "dng", "dng",  17.9, 34.8,   44,
    "55000100282", 39.2, -84.6,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-09-02", 2015, "dngz52", "dng", "dng",  22.8, 34.2, 48.6
  ) %>%
    dplyr::mutate_at(dplyr::vars(start_date, end_date, date), as.Date)
}

example_input_missing_sitecode <- function() {
  tibble::tribble(
    ~id,         ~lat,    ~lon, ~site_index,      ~sitecode,  ~start_date,    ~end_date,
    '55000100280', 39.2, -84.6,   NA, NA, '2008-09-09', '2008-09-11',
    '55000100282', 39.2, -84.6,   '9607238', 211050640897, '2015-08-31', '2015-09-02') %>%
    dplyr::mutate_at(dplyr::vars(start_date, end_date), as.Date)
}

example_output_missing_sitecode <- function() {
  tibble::tribble(
    ~id, ~lat,  ~lon, ~site_index,    ~sitecode,  ~start_date,    ~end_date,        ~date, ~year,     ~gh6,  ~gh3, ~gh3_combined, ~PM25, ~NO2,  ~O3,
    "55000100280", 39.2, -84.6,   NA, NA, "2008-09-09", "2008-09-11", "2008-09-09", NA, NA,  NA,         NA,   NA, NA, NA,
    "55000100280", 39.2, -84.6,   NA, NA, "2008-09-09", "2008-09-11", "2008-09-10", NA, NA,  NA,         NA,   NA, NA, NA,
    "55000100280", 39.2, -84.6,   NA, NA, "2008-09-09", "2008-09-11", "2008-09-11", NA, NA,  NA,         NA,   NA, NA, NA,
    "55000100282", 39.2, -84.6,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-08-31", 2015, "dngz52", "dng", "dng",  12.3, 32.7, 33.6,
    "55000100282", 39.2, -84.6,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-09-01", 2015, "dngz52", "dng", "dng",  17.9, 34.8,   44,
    "55000100282", 39.2, -84.6,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-09-02", 2015, "dngz52", "dng", "dng",  22.8, 34.2, 48.6
  ) %>%
    dplyr::mutate_at(dplyr::vars(start_date, end_date, date), as.Date)
}

example_input_missing_coords <- function() {
  tibble::tribble(
    ~id,         ~lat,    ~lon, ~site_index,      ~sitecode,  ~start_date,    ~end_date,
    '55000100280', NA, NA,   NA, NA, '2008-09-09', '2008-09-11',
    '55000100282', 39.2, -84.6,   '9607238', 211050640897, '2015-08-31', '2015-09-02') %>%
    dplyr::mutate_at(dplyr::vars(start_date, end_date), as.Date)
}

example_output_missing_coords <- function() {
  tibble::tribble(
    ~id, ~lat,  ~lon, ~site_index,    ~sitecode,  ~start_date,    ~end_date,        ~date, ~year,    ~gh6,  ~gh3, ~gh3_combined, ~PM25, ~NO2,  ~O3,
    "55000100280", NA, NA,   NA, NA, "2008-09-09", "2008-09-11", "2008-09-09", NA, NA,  NA,         NA,   NA, NA, NA,
    "55000100280", NA, NA,   NA, NA, "2008-09-09", "2008-09-11", "2008-09-10", NA, NA,  NA,         NA,   NA, NA, NA,
    "55000100280", NA, NA,   NA, NA, "2008-09-09", "2008-09-11", "2008-09-11", NA, NA,  NA,         NA,   NA, NA, NA,
    "55000100282", 39.2, -84.6,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-08-31",  2015, "dngz52", "dng",         "dng",  12.3, 32.7, 33.6,
    "55000100282", 39.2, -84.6,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-09-01",  2015, "dngz52", "dng",         "dng",  17.9, 34.8,   44,
    "55000100282", 39.2, -84.6,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-09-02",  2015,"dngz52", "dng",         "dng",  22.8, 34.2, 48.6
  ) %>%
    dplyr::mutate_at(dplyr::vars(start_date, end_date, date), as.Date)
}


example_input_out_of_order_cols <- function() {
  tibble::tribble(
    ~id,         ~lon,    ~lat, ~site_index,      ~sitecode,  ~start_date,    ~end_date,
    '55000100280', -84.6, 39.2,   "9607238", 211050640897, '2008-09-09', '2008-09-11',
    '55000100282', -84.6, 39.2,   '9607238', 211050640897, '2015-08-31', '2015-09-02') %>%
    dplyr::mutate_at(dplyr::vars(start_date, end_date), as.Date)
}

example_output_out_of_order_cols <- function() {
  tibble::tribble(
    ~id, ~lon,  ~lat, ~site_index,    ~sitecode,  ~start_date,    ~end_date,        ~date, ~year,     ~gh6,  ~gh3, ~gh3_combined, ~PM25, ~NO2,  ~O3,
    "55000100280", -84.6, 39.2,    "9607238", 211050640897, "2008-09-09", "2008-09-11", "2008-09-09", 2008,  "dngz52", "dng", "dng",   8.4, 27.7, 22.2,
    "55000100280", -84.6, 39.2,   "9607238", 211050640897, "2008-09-09", "2008-09-11", "2008-09-10", 2008,  "dngz52", "dng",  "dng",  10.2, 22.8, 21.2,
    "55000100280", -84.6, 39.2,   "9607238", 211050640897, "2008-09-09", "2008-09-11", "2008-09-11", 2008,  "dngz52", "dng",  "dng",  15.9, 27.8, 21.8,
    "55000100282", -84.6, 39.2,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-08-31", 2015,  "dngz52", "dng",  "dng",  12.3, 32.7, 33.6,
    "55000100282", -84.6, 39.2,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-09-01", 2015,  "dngz52", "dng",  "dng",  17.9, 34.8,   44,
    "55000100282", -84.6, 39.2,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-09-02", 2015,  "dngz52", "dng",  "dng",  22.8, 34.2, 48.6
  ) %>%
    dplyr::mutate_at(dplyr::vars(start_date, end_date, date), as.Date)
}
