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
    ~id, ~lat,  ~lon, ~site_index,    ~sitecode,  ~start_date,    ~end_date,        ~date,     ~gh6,  ~gh3, ~year, ~gh3_combined, ~PM25, ~NO2,  ~O3,
    "55000100280", 39.2, -84.6,   "9607238", 211050640897, "2008-09-09", "2008-09-11", "2008-09-09", "dngz52", "dng",  2008,         "dng",   8.4, 27.7, 22.2,
    "55000100280", 39.2, -84.6,   "9607238", 211050640897, "2008-09-09", "2008-09-11", "2008-09-10", "dngz52", "dng",  2008,         "dng",  10.2, 22.8, 21.2,
    "55000100280", 39.2, -84.6,   "9607238", 211050640897, "2008-09-09", "2008-09-11", "2008-09-11", "dngz52", "dng",  2008,         "dng",  15.9, 27.8, 21.8,
    "55000100282", 39.2, -84.6,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-08-31", "dngz52", "dng",  2015,         "dng",  12.3, 32.7, 33.6,
    "55000100282", 39.2, -84.6,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-09-01", "dngz52", "dng",  2015,         "dng",  17.9, 34.8,   44,
    "55000100282", 39.2, -84.6,   "9607238", 211050640897, "2015-08-31", "2015-09-02", "2015-09-02", "dngz52", "dng",  2015,         "dng",  22.8, 34.2, 48.6
  ) %>%
    dplyr::mutate_at(dplyr::vars(start_date, end_date, date), as.Date)
}
