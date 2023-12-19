terraform {
  source = "../../../../../modules//anti-ddos-infra"
}

include "root" {
  path = find_in_parent_folders()
}

locals {
  # Load the data from common.hcl
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # regex to select region and profile from folders
  env_regex = "infrastructure/live/[a-zA-Z0-9-.]+/profiles/([a-zA-Z0-9-]+)/([a-zA-Z0-9-]+)"
  #debug = run_cmd("echo", "${jsonencode(local.env_regex)}")

  aws_profile = try(regex(local.env_regex, get_original_terragrunt_dir())[0])
  aws_account = run_cmd("sh", "-c", "aws sts get-caller-identity --query Account --output text --profile ${local.aws_profile}")
  aws_region  = try(regex(local.env_regex, get_original_terragrunt_dir())[1])
}

inputs = merge(
  local.common.inputs,
  {
    # additional inputs
  }
)

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
   profile = "${local.aws_profile}"
   region = "${local.aws_region}"
}
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    #shared_credentials_file = "~/.aws/credentials"
    profile        = "${local.aws_profile}"
    bucket         = "antiddos-${local.aws_account}-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "LockID"
  }
}

