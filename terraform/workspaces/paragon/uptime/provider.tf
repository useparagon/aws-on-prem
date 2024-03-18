terraform {
  required_providers {
    betteruptime = {
      source = "BetterStackHQ/better-uptime"
    }
  }
}

provider "betteruptime" {
  api_token = coalesce(var.uptime_api_token, "dummy-token")
}
