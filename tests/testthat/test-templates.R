test_that("list_templates returns available templates", {
  templates <- suppressMessages(list_templates())

  expect_true(length(templates) > 0)
  expect_true("plumber2" %in% templates)
  expect_true("fiery" %in% templates)
})

test_that("create_template creates plumber2 template", {
  tmp <- tempfile()
  on.exit(unlink(tmp, recursive = TRUE))

  suppressMessages(
    create_template(tmp, engine = "plumber2")
  )

  expect_true(dir.exists(tmp))
  expect_true(file.exists(file.path(tmp, "_server.yml")))
  expect_true(file.exists(file.path(tmp, "api.R")))

  # Check that the _server.yml is valid
  config <- read_server_yml(tmp)
  expect_equal(config$engine, "plumber2")
})

test_that("create_template creates fiery template", {
  tmp <- tempfile()
  on.exit(unlink(tmp, recursive = TRUE))

  suppressMessages(
    create_template(tmp, engine = "fiery")
  )

  expect_true(dir.exists(tmp))
  expect_true(file.exists(file.path(tmp, "_server.yml")))
  expect_true(file.exists(file.path(tmp, "app.R")))

  config <- read_server_yml(tmp)
  expect_equal(config$engine, "fiery")
})

test_that("create_template errors on existing _server.yml without overwrite", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  # Create initial template
  suppressMessages(create_template(tmp, engine = "plumber2"))

  # Try to create again without overwrite
  expect_error(
    create_template(tmp, engine = "plumber2", overwrite = FALSE),
    "already exists"
  )
})

test_that("create_template overwrites with overwrite = TRUE", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  # Create initial template
  suppressMessages(create_template(tmp, engine = "plumber2"))

  # Modify the file
  writeLines("modified", file.path(tmp, "_server.yml"))

  # Overwrite
  suppressMessages(create_template(tmp, engine = "plumber2", overwrite = TRUE))

  # Check it was overwritten
  config <- read_server_yml(tmp)
  expect_equal(config$engine, "plumber2")
})
