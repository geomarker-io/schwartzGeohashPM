# Call s3 and get object size for one file
get_fl_size <- function(s3_fl_url) {
  x <- aws.s3::head_object(s3_fl_url)
  size_mb <- round(as.numeric(attr(x = x, which = "content-length"))*0.000001, 1)
  return(tibble::tibble(file_name = s3_fl_url, size_mb = size_mb))
}

# sum file sizes for all requested downloads
get_total_fl_size <- function(fls) {
  purrr::map_dfr(fls, get_fl_size) %>%
    dplyr::summarize(total_size = sum(size_mb)) %>%
    dplyr::mutate(total_size = ifelse(total_size > 999,
                               paste0(total_size/1000, " GB"),
                               paste0(total_size, " MB"))) %>%
    .$total_size
}

# check if file is already present in specified local directory
check_local_fls_exist <- function(fl_names, s3_folder_url, download_dir) {
  t <- tibble::tibble(local_file_name = fl_names) %>%
    dplyr::mutate(exists = purrr::map_lgl(fl_names, ~file.exists(fs::path(download_dir, .x))))

  fls_to_download <- t %>%
    dplyr::filter(exists == FALSE) %>%
    .$local_file_name

  if (length(fls_to_download) < 1) {
    fls_to_download <- vector()
  }

  return(fls_to_download)
}

#' easily download files from s3
#'
#' @param fl_names vector of file names (not the entire file path) to be downloaded from s3 to your local files
#' @param s3_folder_url the file location within s3, e.g. 's3://bucket_name/folder_name/'
#' @param download_dir the local path where the downloaded files are saved
#'
#' @return files downloaded to the specified directory
#'
#' @examples
#' if (FALSE) {
#' download_s3(fl_names =  c('dng_2016_round1.qs', 'dng_2015_round2.qs'),
#'             s3_folder_url = 's3://geomarker/schwartz/exp_estimates_1km/by_gh3_year/',
#'             download_dir = getwd())
#' }
#' @export
download_s3 <- function(fl_names, s3_folder_url, download_dir) {
  # check if file exists in s3
  s3_exists <- purrr::map_lgl(paste0(s3_folder_url, fl_names), ~suppressMessages(aws.s3::head_object(.x)))
  if(length(s3_exists[s3_exists]) != length(s3_exists)) {
    stop("One or more requested files do not exist in the specified s3 folder.", call. = FALSE)
  }

  fls <- check_local_fls_exist(fl_names, s3_folder_url, download_dir)

  if(length(fls) > 0) {
    fls_s3 <- paste0(s3_folder_url, fls)
    total_size <- get_total_fl_size(fls_s3)
    message(length(fls_s3), " of ", length(fl_names), " file(s) were not found in ", download_dir)
    message("The total size of the download is ", total_size)
    ans <- readline("Do you want to download now (Y/n)? ")
    if (!ans %in% c("", "y", "Y")) stop("aborted", call. = FALSE)

    mappp::mappp(fls,
                 ~aws.s3::save_object(object = paste0(s3_folder_url, .x),
                                      file = paste0(download_dir, '/', .x)), parallel = FALSE)
    message('Download complete.')
  }

  if(length(fls) < 1) {
    message('All files are present in ', download_dir)
  }
}
