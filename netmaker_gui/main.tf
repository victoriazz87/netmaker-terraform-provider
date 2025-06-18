terraform {
  required_providers {
    netmaker = {
      source  = "local/netmaker"
      version = "1.0.0"
    }
  }
}

provider "netmaker" {
  api_url   = "https://api.sahko.site"
  api_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJSb2xlIjoiYWRtaW4iLCJVc2VyTmFtZSI6InRlcnJhZm9ybS10ZXN0aSIsIkFwaSI6ImFwaS5zYWhrby5zaXRlIiwiVG9rZW5UeXBlIjoiYWNjZXNzX3Rva2VuIiwiUmFjQXV0b0Rpc2FibGUiOmZhbHNlLCJpc3MiOiJOZXRtYWtlciIsInN1YiI6InVzZXJ8dGVycmFmb3JtLXRlc3RpIiwiZXhwIjoxNzUxMjk3NTA3LCJpYXQiOjE3NTAyNjA3MTIsImp0aSI6ImFmZDEzMmNlLTllNWEtNDU3Ny04NTE4LTYzZDUwNDU3ZmZlNyJ9.dizSpOHq62Wsfp4OYEdnM0rTAn1yugE1KbD4BIkzsR0"
}

resource "netmaker_network" "terraform_test" {
  name         = "terraform_test"
  addressrange = "10.100.0.0/24"
}
