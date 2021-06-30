prep_data <- function(d) {
  dht::check_for_column(d, 'sitecode', d$sitecode)
  dht::check_for_column(d, 'start_date', d$start_date)
  dht::check_for_column(d, 'end_date', d$end_date)

  d$start_date <- dht::check_dates(d$start_date)
  d$end_date <- dht::check_dates(d$end_date)
  dht::check_end_after_start_date(d$start_date, d$end_date)

  if('index_date' %in% colnames(d)) {
    d$index_date <- dht::check_dates(d$index_date)
  }
  return(d)
}

read_chunk_join <- function(d_split, fl_path, verbose=FALSE) {
  if(verbose) message("processing ", stringr::str_split(fl_path, '/')[[1]][length(stringr::str_split(fl_path, '/')[[1]])], " ...")
  chunk <- qs::qread(fl_path) %>%
    dplyr::select(-site_index)

  d_split_pm <- dplyr::left_join(d_split, chunk, by = c('sitecode', 'date'))
  rm(chunk)
  return(d_split_pm)
}

#' add PM2.5, NO2, and O3 concentrations to data based on geohash
#'
#' @param d dataframe with columns called 'sitecode', 'start_date', and 'end_date'
#'          (most likely the output from the `schwartz_grid_lookup`` container)
#' @param verbose if TRUE a statement is printed to the console telling the user
#'                which chunk file is currently being processed. Defaults to FALSE.
#' @param ... arguments passed to \code{\link[s3]{s3_get_files}}
#'
#' @return the input dataframe, expanded to include one row per day between the given 'start_date'
#'         and 'end_date', with appended columns for geohash, PM2.5, NO2, and O3 concentrations.
#'
#' @examples
#' if (FALSE) {
#' d <- tibble::tribble(
#'      ~id,         ~lat,    ~lon, ~site_index,      ~sitecode,  ~start_date,    ~end_date,
#'      '55000100280', 39.2, -84.6,   '9607238', '211050640897', '2008-09-09', '2008-09-11',
#'      '55000100281', 39.2, -84.6,   '9607238', '211050640897', '2007-08-05', '2007-08-08',
#'      '55000100282', 39.2, -84.6,   '9607238', '211050640897', '2015-08-31', '2015-09-02') %>%
#'    dplyr::mutate_at(vars(start_date, end_date), as.Date)
#'
#'    add_schwartz_pollutants(d)
#' }
#' @export
add_schwartz_pollutants <- function(d, verbose = FALSE, ...) {
  d <- prep_data(d)

  # check for missing sitecodes
  d_missing_sitecode <- dplyr::filter(d, is.na(sitecode))
  if (nrow(d_missing_sitecode) > 0) {
    cli::cli_alert_warning('sitecode is missing for {nrow(d_missing_sitecode)} input row{?s}')
    d_missing_sitecode <- dht::expand_dates(d_missing_sitecode, by = 'day')
    d <- dplyr::filter(d, !is.na(sitecode))
    }

  # check for out of range dates
  d <- dht::expand_dates(d, by = 'day')
  d$year <- lubridate::year(d$date)
  out_of_range_year <- sum(d$year < 2000 | d$year > 2016)
  if (out_of_range_year > 0) {
    cli::cli_alert_warning("Data is available from 2000 through 2016.")
    cli::cli_alert_warning("PM estimates for {out_of_range_year} date{?s} will be NA due to unavailable data.")
    d_missing_date <- dplyr::filter(d, !year %in% 2000:2016)
    d <- dplyr::filter(d, year %in% 2000:2016)
  }

  message('Matching sitecodes to geohashes...')
  d <-
    d %>%
    dplyr::left_join(schwartz_grid_geohashed,
                     by = c('sitecode')) %>%
    dplyr::filter(!is.na(gh6)) %>%
    dplyr::mutate(gh3 = stringr::str_sub(gh6, 1, 3)) %>%
    dplyr::left_join(gh3_combined_lookup, by = 'gh3')

  unique_gh3_year <-
    d %>%
    dplyr::group_by(gh3_combined, year) %>%
    dplyr::tally() %>%
    dplyr::mutate(gh3_year = paste0(gh3_combined, "_", year)) %>%
    .$gh3_year

  files_to_dwnld <- paste0(unique_gh3_year, '_round1.qs')
  s3_files_to_dwnld <- paste0('s3://geomarker/schwartz/exp_estimates_1km/by_gh3_year/', files_to_dwnld)

  # download files from s3
  fl_path <- s3::s3_get_files(s3_files_to_dwnld, ...)

  # extract unique gh3 and year from file paths
  d_fl_path <- fl_path %>%
    tidyr::unnest(file_path) %>%
    dplyr::mutate(split_str = stringr::str_split(uri, '/')) %>%
    tidyr::unnest(split_str) %>%
    dplyr::group_by(uri) %>%
    dplyr::slice_tail() %>%
    dplyr::mutate(gh3_year = stringr::str_sub(split_str, 1,  -11))

  # split data by gh3 and year
  d_split <- d %>%
    split(f = list(d$gh3_combined, d$year), drop = TRUE)

  message('Now reading in and joining pollutant data.')

  xs <- 1:length(d_split)

  progressr::with_progress({
    p <- progressr::progressor(along = xs)
    d_split_pm <- purrr::map(xs, function(x) {
      p(sprintf("x=%g", x))
      read_chunk_join(d_split[[x]],
                      # ensure d_split chunk matches file path
                      d_fl_path[d_fl_path$gh3_year == paste0(unique(d_split[[x]]$gh3_combined), "_", unique(d_split[[x]]$year)),]$file_path,
                      verbose)
    })
  })

  d_pm <- dplyr::bind_rows(d_split_pm)

  if (nrow(d_missing_sitecode) > 0) d_pm <- dplyr::bind_rows(d_missing_sitecode, d_pm)
  if (out_of_range_year > 0) d_pm <- dplyr::bind_rows(d_missing_date, d_pm)

  if ("index_date" %in% colnames(d)) {
   d_pm <- d_pm %>%
     dplyr::mutate(days_from_index_date = as.numeric(date - index_date))
  }

  return(d_pm)
}
