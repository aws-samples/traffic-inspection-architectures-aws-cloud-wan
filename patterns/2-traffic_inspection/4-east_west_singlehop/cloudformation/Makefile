.PHONY: deploy deploy-base-policy deploy-workloads update-cloudwan undeploy undeploy-workloads undeploy-cloudwan

deploy: deploy-base-policy deploy-workloads update-cloudwan

deploy-base-policy:
	aws cloudformation deploy --stack-name core-network-east-west --template-file base_policy.yaml --no-fail-on-empty-changeset --region us-east-1

deploy-workloads: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "core-network-east-west" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-east-1 )
deploy-workloads: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "core-network-east-west" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-east-1 )
deploy-workloads:
	aws cloudformation deploy --stack-name east-west-ireland --template-file east_west.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-west-1
	aws cloudformation deploy --stack-name east-west-nvirginia --template-file east_west.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-east-1
	aws cloudformation deploy --stack-name east-west-sydney --template-file east_west.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region ap-southeast-2
	aws cloudformation deploy --stack-name east-west-london --template-file east_west_noinspection.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-west-2

update-cloudwan:
	aws cloudformation update-stack --stack-name core-network-east-west --template-body file://core_network.yaml --region us-east-1
	aws cloudformation wait stack-update-complete --stack-name core-network-east-west --region us-east-1

undeploy: undeploy-workloads undeploy-cloudwan

undeploy-workloads:
	aws cloudformation delete-stack --stack-name east-west-ireland --region eu-west-1
	aws cloudformation delete-stack --stack-name east-west-nvirginia --region us-east-1
	aws cloudformation delete-stack --stack-name east-west-sydney --region ap-southeast-2
	aws cloudformation delete-stack --stack-name east-west-london --region eu-west-2
	aws cloudformation wait stack-delete-complete --stack-name east-west-ireland --region eu-west-1
	aws cloudformation wait stack-delete-complete --stack-name east-west-nvirginia --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name east-west-sydney --region ap-southeast-2
	aws cloudformation wait stack-delete-complete --stack-name east-west-london --region eu-west-2

undeploy-cloudwan:
	aws cloudformation delete-stack --stack-name core-network-east-west --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name core-network-east-west --region us-east-1