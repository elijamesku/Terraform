# AWS Dev Environment with Terraform

Dev environment on AWS using Terraform and Git, split into independent stacks: network, app, and database. Each stack has its own remote S3 state and can be applied/destroyed independently.

## What’s included

* **Network (Stack 1):** VPC (10.0.0.0/16), two AZs, 6 subnets (2 public, 2 private-app, 2 private-db), IGW, single NAT GW, route tables, RDS subnet group.
* **App (Stack 2):** ALB > Target Group > ASG (EC2 with Launch Template and user-data). IAM role + instance profile. Policy to read DB creds from Secrets Manager.
* **Database (Stack 3):** RDS MySQL (dev). Credentials generated via `random_password` and stored in Secrets Manager.

## Repo layout

```
aws/dev/
  networks/    # VPC & subnets (outputs: vpc_id, subnet ids, db_subnet_group_name)
  app/         # ALB, ASG, IAM (outputs: alb_dns_name)
  data-stores/mysql/  # RDS + Secrets
```

Each folder contains `backend.tf`, `providers.tf`, `versions.tf` and stack-specific resources.

## Remote state

S3 keys per stack, for example:

* `aws/dev/networks/terraform.tfstate`
* `aws/dev/app/terraform.tfstate`
* `aws/dev/data-stores/mysql/terraform.tfstate`

Enable S3 versioning and use a DynamoDB table for locks.

## Deploy (dev)

```bash
# Stack 1
cd aws/dev/networks && terraform init && terraform apply

# Stack 2
cd ../app && terraform init && terraform apply

# Stack 3
cd ../data-stores/mysql && terraform init && terraform apply
```

Stacks may consume others via `terraform_remote_state`.

## Security and cost notes

* For production: `publicly_accessible = false` on RDS, enable backups, use deletion protection, require HTTPS on ALB.
* Restrict SGs: ALB open to the internet; app only from ALB; DB only from app.
* NAT Gateway and ALB incur costs; destroy when finished.

## Destroy (reverse order)

```bash
cd aws/dev/data-stores/mysql && terraform destroy
cd ../../app && terraform destroy
cd ../networks && terraform destroy
```

## Roadmap

Convert stacks to reusable modules, add tfvars per env, wire CI for fmt/validate/tflint/tfsec/plan, replace hardcoded AMIs with SSM, add logging and alarms.
