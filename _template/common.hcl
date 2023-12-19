locals {
  root_path = get_terragrunt_dir()
  site_regex = "infrastructure/live/([a-zA-Z0-9-.]+)"
  site   = try(regex(local.site_regex, "${local.root_path}"))[0]
  project = replace(local.site, ".", "-")
  debug = run_cmd("echo", "${jsonencode(local.site)}")
}

inputs = {
  under_attack = 1

  project = local.project

  vpc_cidr = "10.255.0.0/16"

  public_subnet_cidrs = [
    "10.255.1.0/24",
    "10.255.2.0/24",
  ]

  whitelist = [
    "1.1.1.1/32",
  ]


  user_data         = "${local.root_path}/../../../assets/${local.site}/user-data/INSTALL.sh"
  private_key       = "${local.root_path}/../../../assets/${local.site}/certs/TEMPLATE.privkey.pem"
  certificate_body  = "${local.root_path}/../../../assets/${local.site}/certs/TEMPLATE.cert.pem"
  certificate_chain = "${local.root_path}/../../../assets/${local.site}/certs/TEMPLATE.chain.pem"

}
