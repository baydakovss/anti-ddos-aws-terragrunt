# Import main config
cnf ?= config.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))
export PATH := ~/.local/bin:$(PATH)
export PROJECT_FOLDER = $(shell pwd)

# Setting USER = ansilbe if USER is unset in config.env
#USER ?= ansible

# HELP from https://gist.github.com/mpneuried/0594963ad38e68917ef189b4e6a269db
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

make-skeleton: ## Make project skeleton folders
	./helper.sh -a make_skeleton

fetch-certificates: ## Fetch SSL certificates
	./helper.sh -a fetch_certs

generate-userdata: ## Generate userdata for setup nginx on start proxy
	./helper.sh -a generate_userdata

terragrunting: ## Terraforming all project/sites
	cd infrastructure/live; terragrunt run-all apply; cd -

destroying: ## Destroying all project/sites
	cd infrastructure/live; terragrunt run-all destroy; cd -

make-iam: ## Make IAM role and EC2 instance profile
	cd infrastructure/live/global; terragrunt run-all apply; cd -

get-outputs: ## Get global accelerator ips
	cd infrastructure/live; terragrunt run-all output; cd -


