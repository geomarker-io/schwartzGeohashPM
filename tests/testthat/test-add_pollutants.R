test_that("add_pollutants downloads chunks and joins to data", {
  delete_test_download_folder()
  withr::with_envvar(new = c(
    "AWS_ACCESS_KEY_ID" = NA,
    "AWS_SECRET_ACCESS_KEY" = NA
  ), {
    expect_identical(
      add_schwartz_pollutants(example_input(), confirm = FALSE),
      example_output()
    )
  })
  delete_test_download_folder()
})

test_that("add_pollutants downloads chunks and joins to data with missing sitecode", {
  delete_test_download_folder()
  withr::with_envvar(new = c(
    "AWS_ACCESS_KEY_ID" = NA,
    "AWS_SECRET_ACCESS_KEY" = NA
  ), {
    expect_identical(
      add_schwartz_pollutants(example_input_missing_sitecode(), confirm = FALSE),
      example_output_missing_sitecode()
    )
  })
  delete_test_download_folder()
})

