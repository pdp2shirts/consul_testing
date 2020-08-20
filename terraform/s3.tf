 terraform {
  backend "s3" {
    bucket = "dgarrison-testing3-consul-sd"
    key    = "deploy-infrastructure"
    region = "us-east-1"
  }
}

