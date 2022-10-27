####################
# General
####################

build:
	docker build \
		--tag useparagon/aws-self-hosted \
		-f Dockerfile \
		.

tf-version:
	docker run \
		-it \
		--rm useparagon/aws-self-hosted:latest \
		bash -c "terraform --version"

####################
# Get Terraform state
####################

state-infra:
	docker run \
		-it \
		--mount source="$(shell pwd)",target=/usr/src/app,type=bind \
		--rm useparagon/aws-self-hosted:latest \
		ts-node "scripts/cli" state-infra

state-paragon:
	docker run \
		--mount source="$(shell pwd)",target=/usr/src/app,type=bind \
		--rm useparagon/aws-self-hosted:latest \
		ts-node "scripts/cli" state-paragon

####################
# Deploy
####################

deploy-infra:
	docker run \
		-it \
		--env initialize=$(initialize) \
		--env plan=$(plan) \
		--env apply=$(apply) \
		--env target=$(target) \
		--env args=$(args) \
		--mount source="$(shell pwd)",target=/usr/src/app,type=bind \
		--rm useparagon/aws-self-hosted:latest \
		ts-node "scripts/cli" deploy-infra

deploy-paragon:
	docker run \
		-it \
		--env initialize=$(initialize) \
		--env plan=$(plan) \
		--env apply=$(apply) \
		--env target=$(target) \
		--env args=$(args) \
		--mount source="$(shell pwd)",target=/usr/src/app,type=bind \
		--rm useparagon/aws-self-hosted:latest \
		ts-node "scripts/cli" deploy-paragon