# One-time bootstrap: creates the S3 bucket that holds Terraform state for every
# other stack in this repository (aws, azure, gcp and shopedge/infra/*).
#
# This stack keeps its own state locally (bootstrap/terraform.tfstate, git-ignored),
# because the remote bucket does not exist yet. Run it once per AWS account.
# State locking uses an S3 lockfile (use_lockfile), so no DynamoDB table is needed.

terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.13.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "Region for the state bucket. Must match the region in every backend.tf."
  type        = string
  default     = "eu-central-1"
}

variable "state_bucket_name" {
  description = "Name of the state bucket. S3 names are global; if this one is taken, pick another and update bucket in every backend.tf."
  type        = string
  default     = "multicloud-terraform-state-bucket"
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  # Losing this bucket loses the record of every deployed resource
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project   = "multi-cloud-terraform"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "state" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}

output "state_bucket" {
  description = "Name of the state bucket"
  value       = aws_s3_bucket.state.id
}
