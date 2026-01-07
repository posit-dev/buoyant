#* @get /hello
function() {
  list(message = "Hello from plumber2!")
}

#* @get /echo
#* @param msg The message to echo
function(msg = "") {
  list(echo = msg)
}
