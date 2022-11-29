# aws-sample-infra-resources-terraform

A sample infra resources code in Terraform that goes into a target workload account.  This code is pushed into the AWS CodeCommit repo for our sample.

## Table of contents

* [Sample Workload Infra](#sample-workload-infra)
* [Prerequisites](#prerequisites)
* [To push the infra repo code into AWS CodeCommit in the central tooling account](#to-push-the-infra-repo-code-into-aws-codecommit-in-the-central-tooling-account)
* [To deploy resources into the target workload accounts](#to-deploy-resources-into-the-target-workload-accounts)
* [To destroy the resources in the target workload accounts](#to-destroy-the-resources-in-the-target-workload-accounts)
* [Security](#security)
* [License](#license)

## Sample Workload Infra
* Regional resources: An external facing ALB all the way down to the VPC.
* Global resources: An IAM role.

Once all resources are deployed (see section on how to deploy resources) then go to EC2 -> Load Balancer (demo*) -> DNS Name -> Copy it and open it in the browser (make sure to use http:// and not https://).

## Prerequisites:
* Set up the central tooling account as per its README in the sister repo [aws-multi-region-cicd-with-terraform](https://github.com/aws-samples/aws-multi-region-cicd-with-terraform#instructions-to-deploy-the-cicd-pipeline) that will create the AWS CodeCommit repo.

## To push the infra repo code into AWS CodeCommit in the central tooling account:
* See instructions in the sister repo [aws-multi-region-cicd-with-terraform](https://github.com/aws-samples/aws-multi-region-cicd-with-terraform#step-3-push-the-infra-repo-code-into-aws-codecommit-in-the-central-tooling-account)

## To deploy resources into the target workload accounts:
* See instructions on how to kick off an infra pipeline (in the central tooling account) at the sister repo [aws-multi-region-cicd-with-terraform](https://github.com/aws-samples/aws-multi-region-cicd-with-terraform#kick-off-a-pipeline-to-deploy-to-a-target-workload-account-and-a-target-region)

## To destroy the resources in the target workload accounts:
* If not done already, use `aws configure` with your IAM user credentials for the central tooling account and then assume InfraBuildRole:
```shell
# You can use below one liner
# For details, see [this](https://aws.amazon.com/premiumsupport/knowledge-center/iam-assume-role-cli/
OUT=$(aws sts assume-role --role-arn arn:aws:iam::111122223333:role/InfraBuildRole --role-session-name INFRA_BUILD);export AWS_ACCESS_KEY_ID=$(echo $OUT | jq -r '.Credentials''.AccessKeyId');export AWS_SECRET_ACCESS_KEY=$(echo $OUT | jq -r '.Credentials''.SecretAccessKey');export AWS_SESSION_TOKEN=$(echo $OUT | jq -r '.Credentials''.SessionToken');

# Verify you assumed the role
aws sts get-caller-identity
{
    "UserId": "AAA:INFRA_BUILD",
    "Account": "111122223333",
    "Arn": "arn:aws:sts::111122223333:assumed-role/InfraBuildRole/INFRA_BUILD"
}
```
* Use the regional resources destroy shell script in this repo to generate the tf plan for the account and region.  Inspect the tf plan and then run `terraform apply "tfplan"`
```shell
./scripts/run-tf-regional-destroy.sh -t <tag> -b <tf_backend_config_prefix> -r <tf_state_region> -g <global_resource_deployment_region>
# Ex: ./scripts/run-tf-regional-destroy.sh -t dev_us-east-1/research/1.0 -g eu-central-1 -r eu-central-1 -b org-awesome-tf-state
```
* Then, use the global resources destroy shell script in this repo to generate the tf plan for the account.  Inspect the tf plan and then run `terraform apply "tfplan"`
```shell
./scripts/run-tf-global-destroy.sh -t <tag> -b <tf_backend_config_prefix> -r <tf_state_region> -g <global_resource_deployment_region>
# Ex: ./scripts/run-tf-global-destroy.sh -t dev_global/research/1.0 -g eu-central-1 -r eu-central-1 -b org-awesome-tf-state
```
## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.14 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.74 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.74.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_global"></a> [global](#module\_global) | ./modules/global | n/a |
| <a name="module_regional"></a> [regional](#module\_regional) | ./modules/regional | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account"></a> [account](#input\_account) | Target AWS account number | `number` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Environment name | `string` | n/a | yes |
| <a name="input_number_of_azs"></a> [number\_of\_azs](#input\_number\_of\_azs) | Number of azs to deploy to | `number` | `2` | no |
| <a name="input_region"></a> [region](#input\_region) | Target region | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | The effective account id in which Terraform is operating |
| <a name="output_caller_arn"></a> [caller\_arn](#output\_caller\_arn) | The effective user arn that Terraform is running as |
| <a name="output_caller_user"></a> [caller\_user](#output\_caller\_user) | The effective user id that Terraform is running as |
| <a name="output_region"></a> [region](#output\_region) | The region in which Terraform is operating |
<!-- END_TF_DOCS -->