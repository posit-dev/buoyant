# Example fiery application
# Note: This is a template. Actual fiery configuration may vary.

library(fiery)

app <- Fire$new()

app$on('start', function(server, ...) {
  message('Starting fiery server')
})

app$on('request', function(server, request, ...) {
  response <- request$respond()
  response$status <- 200L
  response$body <- 'Hello from fiery!'
  response$type <- 'text/plain'
})

app
