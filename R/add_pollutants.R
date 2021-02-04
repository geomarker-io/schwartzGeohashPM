expand_dates <- function(d) {
  d <- dplyr::mutate(d, date = purrr::map2(start_date, end_date, ~seq.Date(from = .x, to = .y, by = 'day')))
  tidyr::unnest(d, cols = c(date))
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
  if (!"sitecode" %in% colnames(d)) {
    cli::cli_alert_error("input dataframe must have a column called 'sitecode'")
    stop()
  }
  if (!"start_date" %in% colnames(d)) {
    cli::cli_alert_error("input dataframe must have a column called 'start_date'")
    stop()
  }
  if (!"end_date" %in% colnames(d)) {
    cli::cli_alert_error("input dataframe must have a column called 'end_date'")
    stop()
  }

  if (any(c(d$start_date < as.Date("2000-01-01"), d$start_date > as.Date("2016-12-31"),
      d$end_date < as.Date("2000-01-01"), d$end_date > as.Date("2016-12-31")))) {
    cli::cli_alert_warning("one or more dates are out of range. data is available 2000-2016.")
  }

  d_missing_sitecode <- dplyr::filter(d, is.na(sitecode))

  if (nrow(d_missing_sitecode) > 0) cli::cli_alert_warning('sitecode is missing for {nrow(d_missing_sitecode)} row{?s}')

  d_missing_sitecode <- expand_dates(d_missing_sitecode)

  message('Matching sitecodes to geohashes...')

  d <-
    d %>%
    dplyr::filter(!is.na(sitecode)) %>%
    expand_dates() %>%
    dplyr::left_join(schwartz_grid_geohashed,
                     by = c('sitecode')) %>%
    dplyr::filter(!is.na(gh6)) %>%
    dplyr::mutate(gh3 = stringr::str_sub(gh6, 1, 3),
                  year = lubridate::year(date)) %>%
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
    dplyr::mutate(split_str = stringr::str_split(s3_uri, '/')) %>%
    tidyr::unnest(split_str) %>%
    dplyr::group_by(s3_uri) %>%
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

  if ("index_date" %in% colnames(d)) {
   d_pm <- d_pm %>%
     dplyr::mutate(days_from_index_date = as.numeric(date - index_date))
  }

  return(d_pm)
}
