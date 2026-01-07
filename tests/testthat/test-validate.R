test_that("validate_server_yml detects missing file", {
  expect_error(
    validate_server_yml(tempdir()),
    "_server.yml file not found"
  )
})

test_that("validate_server_yml detects missing engine field", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  # Create invalid _server.yml without engine
  writeLines("foo: bar", file.path(tmp, "_server.yml"))

  expect_error(
    validate_server_yml(tmp),
    "must contain an 'engine' field"
  )
})

test_that("validate_server_yml accepts valid _server.yml", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  # Create valid _server.yml
  writeLines("engine: plumber2", file.path(tmp, "_server.yml"))

  expect_true(
    validate_server_yml(tmp, check_engine = FALSE, verbose = FALSE)
  )
})

test_that("read_server_yml reads configuration", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

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
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  yml_file <- file.path(tmp, "_server.yml")
  writeLines("engine: plumber2", yml_file)

  expect_true(
    validate_server_yml(yml_file, check_engine = FALSE, verbose = FALSE)
  )
})

test_that("validate_server_yml detects invalid YAML", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  # Create invalid YAML
  writeLines("engine: [invalid yaml", file.path(tmp, "_server.yml"))

  expect_error(
    validate_server_yml(tmp),
    "Failed to parse _server.yml"
  )
})
