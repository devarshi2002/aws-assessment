# AWS Terraform DevOps Assessment

Cost-conscious assessment implementation for `ap-south-1`.

## Architecture
Internet -> public ALB -> EC2 Auto Scaling Group in private application subnets -> private RDS MySQL.
Two AZs are used for subnets and application instances. One NAT Gateway is used to reduce cost; this is a cost/availability trade-off.

## HTTPS limitation
A publicly trusted ACM certificate requires a domain name you control and DNS validation. Without a domain, this project defaults to HTTP for initial verification. Do not claim the public HTTPS requirement is complete until a domain and ACM certificate are configured.

## Prerequisites
- AWS CLI v2, Terraform >= 1.6, Git
- AWS identity with permissions to create VPC, EC2, ELB, RDS, S3, IAM, Secrets Manager and related resources
- GitHub repository for CI/CD
- Review all costs before applying. ALB, NAT Gateway and RDS incur ongoing charges.

## Local deployment
```bash
aws sts get-caller-identity
cd terraform
terraform fmt -recursive
terraform init
terraform validate
terraform plan
terraform apply
```
Review the plan carefully. Get outputs:
```bash
terraform output
terraform output -raw application_url
```
Test:
```bash
curl -i "$(terraform output -raw application_url)/health"
```

## GitHub Actions
1. Create an IAM OIDC provider and role as described in `docs/github-oidc.md`.
2. Set GitHub repository variable `AWS_ROLE_ARN` to the role ARN.
3. Push to `main`; the workflow validates and plans. Apply is manual via `workflow_dispatch` input `apply=true`.
4. Do not grant broad admin permissions in a production account. Scope permissions to the project and review the plan.

## Evidence checklist
- Terraform validate and plan
- VPC/subnets/route tables
- ALB target group with healthy targets
- EC2 instances in private subnets
- RDS public accessibility disabled
- S3 buckets with public access blocked and encryption enabled
- GitHub Actions run
- Application `/health` response
- HTTPS screenshot only after configuring a real domain and ACM certificate

## Cleanup
```bash
cd terraform
terraform destroy
```
Review resources before confirming. If destroy fails because of S3 objects or deletion protection, empty the project log/storage buckets and disable RDS deletion protection, then retry. Check the AWS console afterwards for leftovers.
