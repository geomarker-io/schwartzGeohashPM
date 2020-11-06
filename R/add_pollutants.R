expand_dates <- function(d) {
  d <- dplyr::mutate(d, date = purrr::map2(start_date, end_date, ~seq.Date(from = .x, to = .y, by = 'day')))
  tidyr::unnest(d, cols = c(date))
}

read_chunk_join <- function(d_split, download_dir) {
  chunk <- qs::qread(paste0(download_dir, '/', unique(d_split$gh3_combined),
                            "_", unique(d_split$year), "_round1.qs")) %>%
    dplyr::mutate(sitecode = as.character(sitecode)) %>%
    dplyr::select(-site_index)

  d_split_pm <- dplyr::left_join(d_split, chunk, by = c('sitecode', 'date'))
  rm(chunk)
  return(d_split_pm)
}

#' add PM2.5, NO2, and O3 concentrations to data based on geohash
#'
#' @param d dataframe with columns called 'sitecode', 'start_date', and 'end_date'
#'          (most likely the output from the `schwartz_grid_lookup`` container)
#' @param download_dir local path where files downloaded from s3 will be saved. Defaults to
#'                      a folder called 's3_downloads' in the current working directory.
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
add_schwartz_pollutants <- function(d, download_dir = fs::path_wd("s3_downloads")) {
  if (!"sitecode" %in% colnames(d)) {
    stop("input dataframe must have a column called 'sitecode'")
  }
  if (!"start_date" %in% colnames(d)) {
    stop("input dataframe must have a column called 'start_date'")
  }
  if (!"end_date" %in% colnames(d)) {
    stop("input dataframe must have a column called 'end_date'")
  }

  if (any(c(d$start_date < as.Date("2000-01-01"), d$start_date > as.Date("2016-12-31"),
      d$end_date < as.Date("2000-01-01"), d$end_date > as.Date("2016-12-31")))) {
    stop("one or more dates are out of range. data is available 2000-2016.")
  }

  message('Matching sitecodes to geohashes...')

  d <-
    expand_dates(d) %>%
    dplyr::left_join(schwartz_grid_geohashed %>% dplyr::select(-site_index),
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

  # if s3_downloads folder doesn't exist, create it
  ## add progress to downloads??
  download_s3(fl_names = files_to_dwnld,
              s3_folder_url = 's3://geomarker/schwartz/exp_estimates_1km/by_gh3_year/',
              download_dir = download_dir)

  d_split <- d %>%
    split(f = list(d$gh3_combined, d$year), drop = TRUE)

  message('Now reading in and joining pollutant data.')

  xs <- 1:length(d_split)

  progressr::with_progress({
    p <- progressr::progressor(along = xs)
    d_split_pm <- purrr::map(xs, function(x) {
      p(sprintf("x=%g", x))
      read_chunk_join(d_split[[x]], download_dir)
    })
  })

  d_pm <- dplyr::bind_rows(d_split_pm)
  return(d_pm)
}

