test_that("validate_server_yml detects missing file", {
  expect_error(
    validate_server_yml(tempdir()),
    "_server.yml file not found"
  )
})

test_that("validate_server_yml detects missing engine field", {
  tmp <- withr::local_tempfile()
  dir.create(tmp)

  # Create invalid _server.yml without engine
  writeLines("foo: bar", file.path(tmp, "_server.yml"))

  expect_error(
    validate_server_yml(tmp),
    "must contain an 'engine' field"
  )
})

test_that("validate_server_yml accepts valid _server.yml", {
  tmp <- withr::local_tempfile()
  dir.create(tmp)

  # Create valid _server.yml
  writeLines("engine: plumber2", file.path(tmp, "_server.yml"))

  expect_true(
    validate_server_yml(tmp, check_engine = FALSE, verbose = FALSE)
  )
})

test_that("read_server_yml reads configuration", {
  tmp <- withr::local_tempfile()
  dir.create(tmp)

  # Create _server.yml
  writeLines(c(
    "engine: plumber2",
    "options:",
    "  port: 8000"
  ), file.path(tmp, "_server.yml"))

  config <- read_server_yml(tmp)

  expect_equal(config$engine, "plumber2")
  expect_equal(config$options$port, 8000)
})

test_that("validate_server_yml handles direct file path", {
  tmp <- withr::local_tempfile()
  dir.create(tmp)

  yml_file <- file.path(tmp, "_server.yml")
  writeLines("engine: plumber2", yml_file)

  expect_true(
    validate_server_yml(yml_file, check_engine = FALSE, verbose = FALSE)
  )
})

test_that("validate_server_yml detects invalid YAML", {
  tmp <- withr::local_tempfile()
  dir.create(tmp)

  # Create invalid YAML
  writeLines("engine: [invalid yaml", file.path(tmp, "_server.yml"))

  expect_error(
    validate_server_yml(tmp),
    "Failed to parse _server.yml"
  )
})
