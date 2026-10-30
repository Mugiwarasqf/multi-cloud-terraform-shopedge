# Remote State Setup

Every Terraform configuration in this repository stores its state in one S3 bucket in AWS, whichever cloud it deploys to. State locking uses an S3 lockfile next to each state file (`use_lockfile = true`), so no DynamoDB table is needed. This needs Terraform 1.11 or later.

All four `backend.tf` files use the bucket `multicloud-terraform-state-bucket` in `eu-central-1`.

## Create the bucket

The `bootstrap/` configuration creates it. Run it once per AWS account, with AWS credentials that can create S3 buckets:

```bash
cd bootstrap
terraform init
terraform apply
```

It creates a versioned, encrypted bucket with public access blocked and a policy that refuses non-TLS requests. Its own state is local (`bootstrap/terraform.tfstate`, git-ignored) because the bucket does not exist yet. The bucket has `prevent_destroy`, so a stray `terraform destroy` cannot delete it.

Until the bucket exists, `terraform init` in any other folder fails with `S3 bucket ... does not exist`.

## Using a different bucket name

S3 bucket names are global. If `multicloud-terraform-state-bucket` is taken, or you want your own, pass `-var state_bucket_name=<name>` to the bootstrap, then change `bucket` in these files to match:

- `aws/backend.tf`
- `azure/backend.tf`
- `gcp/backend.tf`
- `shopedge/infra/backend.tf`

If you change the region, update `region` in the same files and `-var region=<region>` for the bootstrap.

## State file organization

| Configuration | State key |
|---|---|
| `aws/` | `aws/terraform.tfstate` |
| `azure/` | `azure/terraform.tfstate` |
| `gcp/` | `gcp/terraform.tfstate` |
| `shopedge/infra` (EKS, AKS and GKE together) | `shopedge/terraform.tfstate` |

## Credentials

Anyone running Terraform here needs AWS credentials with read and write access to the bucket, even for the Azure and GCP configurations:

```bash
aws configure
# or
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
```

The region of the bucket (`eu-central-1`) is set in each `backend.tf`, so it does not depend on `AWS_DEFAULT_REGION`.

## Cleanup

Terraform's `destroy` in the other folders does not touch the bucket. When you no longer need any of the state, empty the bucket (including all object versions), remove the `prevent_destroy` lifecycle block from `bootstrap/main.tf`, and run `terraform destroy` in `bootstrap/`.
