# v2.0.0 -> v2.1.0
# Added support for overriding resource names with `organization` variable
moved {
  from = random_string.app
  to   = random_string.app[0]
}
