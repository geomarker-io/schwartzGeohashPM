expand_dates <- function(d) {
  d <- dplyr::mutate(d, date = purrr::map2(start_date, end_date, ~seq.Date(from = .x, to = .y, by = 'day')))
  tidyr::unnest(d, cols = c(date))
}

read_chunk_join <- function(d_split) {
  chunk <- qs::qread(paste0(fs::path_wd('s3_downloads'), '/', unique(d_split$gh3_combined),
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
add_schwartz_pollutants <- function(d) {
  if (!"sitecode" %in% colnames(d)) {
    stop("input dataframe must have a column called 'sitecode'")
  }
  if (!"start_date" %in% colnames(d)) {
    stop("input dataframe must have a column called 'start_date'")
  }
  if (!"end_date" %in% colnames(d)) {
    stop("input dataframe must have a column called 'end_date'")
  }

  d <-
    expand_dates(d) %>%
    dplyr::left_join(site_to_geohash, by = c('sitecode', 'site_index')) %>%
    dplyr::filter(!is.na(gh6)) %>%
    dplyr::mutate(gh3 = stringr::str_sub(gh6, 1, 3),
                  year = lubridate::year(date)) %>%
    dplyr::left_join(geohash_20k_pop, by = 'gh3')

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
              download_dir = fs::path_wd("s3_downloads"))


  d_split <- d %>%
    split(f = list(d$gh3_combined, d$year), drop = TRUE)

  d_split_pm <- mappp::mappp(d_split, read_chunk_join, parallel = FALSE)
  d_pm <- dplyr::bind_rows(d_split_pm)
  return(d_pm)
}

