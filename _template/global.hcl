terraform {
  source = "../../../../modules//global"
}

locals {

  env_regex = "infrastructure/live/global/profiles/([a-zA-Z0-9-]+)"
  aws_profile   = try(regex(local.env_regex, get_original_terragrunt_dir())[0])
  aws_account = run_cmd("sh", "-c", "aws sts get-caller-identity --query Account --output text --profile ${local.aws_profile}")
 }

generate "provider" {
    path      = "provider.tf"
    if_exists = "overwrite"
    contents = <<EOF
provider "aws" {
   profile = "${local.aws_profile}"
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

