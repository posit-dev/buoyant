# Utility functions for buoyant

#' Retry a function call with exponential backoff
#' @noRd
with_retries <- function(expr, max_attempts = 5, initial_wait = 1) {
  attempt <- 1
  while (attempt <= max_attempts) {
    result <- tryCatch(
      expr,
      error = function(e) {
        if (attempt < max_attempts) {
          wait_time <- initial_wait * (2 ^ (attempt - 1))
          message("Attempt ", attempt, " failed. Retrying in ", wait_time, " seconds...")
          Sys.sleep(wait_time)
          NULL
        } else {
          stop("Failed after ", max_attempts, " attempts: ", e$message)
        }
      }
    )

    if (!is.null(result)) {
      return(result)
    }

    attempt <- attempt + 1
  }
}

#' Get droplet IP address (from analogsea internal function)
#' @noRd
droplet_ip <- function(droplet) {
  v4 <- droplet$network$v4
  if (length(v4) == 0) {
    stop("No network interface registered for this droplet\n  Try refreshing like: droplet(d$id)",
         call. = FALSE)
  }
  ips <- do.call("rbind", lapply(v4, as.data.frame))
  public_ip <- ips$type == "public"
  if (!any(public_ip)) {
    ip <- v4[[1]]$ip_address
  }
  else {
    ip <- ips$ip_address[public_ip][[1]]
  }
  ip
}

#' Safely get droplet IP address
#' @noRd
droplet_ip_safe <- function(droplet) {
  res <- tryCatch(droplet_ip(droplet), error = function(e) e)
  if (inherits(res, "simpleError"))
    "droplet likely not up yet"
  else res
}
