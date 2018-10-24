provider "aws" {
  region  = "eu-west-2"
  version = "~> 1.41"
}

terraform {
  backend "s3" {
    bucket = "gds-re-run-sandbox-terraform-state"
    region = "eu-west-2"
    key    = "svcbroker.tfstate"
  }
}

module "prereqs" {
  source     = "../../modules/prereqs"
  table_name = "awssb"
  region     = "eu-west-2"
  account_id = "011571571136"
}

output "vpc_id" {
  value = "${module.prereqs.vpc_id}"
}

output "access_key_id" {
  value = "${module.prereqs.access_key_id}"
}

output "secret_key_id" {
  value = "${module.prereqs.secret_key_id}"
}
